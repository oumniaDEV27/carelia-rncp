const express = require("express");
const router = express.Router();

const pool = require("../db");
const auth = require("../middleware/auth.middleware");
const audit = require("../utils/audit");

// helper
async function getReservationById(id) {
  const { rows } = await pool.query(
    `SELECT * FROM reservations WHERE id = $1`,
    [id]
  );
  return rows[0];
}

/**
 * 🔒 CONNECTÉ
 * ADMIN / EMPLOYEE : toutes les réservations
 * CLIENT : ses réservations uniquement
 */
router.get("/", auth(), async (req, res, next) => {
  try {
    // ADMIN / EMPLOYEE
    if (["ADMIN", "EMPLOYEE"].includes(req.user.role)) {
      const { rows } = await pool.query(`
        SELECT
          r.*,
          COALESCE(
            json_agg(
              json_build_object(
                'product_id', p.id,
                'name', p.name,
                'quantity', ri.quantity,
                'unit_price_snapshot', ri.unit_price_snapshot
              )
            ) FILTER (WHERE p.id IS NOT NULL),
            '[]'
          ) AS items
        FROM reservations r
        LEFT JOIN reservation_items ri ON ri.reservation_id = r.id
        LEFT JOIN products p ON p.id = ri.product_id
        GROUP BY r.id
        ORDER BY r.id DESC
      `);

      return res.json(rows);
    }

    // CLIENT
    const { rows } = await pool.query(
      `
      SELECT
        r.*,
        COALESCE(
          json_agg(
            json_build_object(
              'product_id', p.id,
              'name', p.name,
              'quantity', ri.quantity,
              'unit_price_snapshot', ri.unit_price_snapshot
            )
          ) FILTER (WHERE p.id IS NOT NULL),
          '[]'
        ) AS items
      FROM reservations r
      LEFT JOIN reservation_items ri ON ri.reservation_id = r.id
      LEFT JOIN products p ON p.id = ri.product_id
      WHERE r.user_id = $1
      GROUP BY r.id
      ORDER BY r.id DESC
      `,
      [req.user.id]
    );

    res.json(rows);
  } catch (e) {
    next(e);
  }
});

/**
 * 🔒 CLIENT
 * Créer une réservation avec des produits
 * Body attendu :
 * {
 *   "items": [
 *     { "product_id": 1, "quantity": 2 }
 *   ]
 * }
 */
router.post("/", auth(["CLIENT"]), async (req, res, next) => {
  try {
    const { items } = req.body;

    if (!Array.isArray(items) || !items.length) {
      return res.status(400).json({ message: "items requis" });
    }

    // ✅ Transaction (évite de créer une réservation si un item échoue)
    await pool.query("BEGIN");

    // 1️⃣ créer la réservation
    const reservationResult = await pool.query(
      `INSERT INTO reservations (user_id, status)
       VALUES ($1, 'EN_ATTENTE')
       RETURNING *`,
      [req.user.id]
    );

    const reservation = reservationResult.rows[0];

    // 2️⃣ ajouter les produits
    for (const item of items) {
      if (!item.product_id || !item.quantity || item.quantity <= 0) {
        await pool.query("ROLLBACK");
        return res.status(400).json({ message: "item invalide" });
      }

      const productResult = await pool.query(
        `SELECT * FROM products WHERE id = $1`,
        [item.product_id]
      );

      if (!productResult.rows.length) {
        await pool.query("ROLLBACK");
        return res.status(404).json({ message: "Produit introuvable" });
      }

      const product = productResult.rows[0];

      if (product.stock_quantity < item.quantity) {
        await pool.query("ROLLBACK");
        return res.status(400).json({ message: "Stock insuffisant" });
      }

      // ✅ snapshot prix obligatoire (colonne NOT NULL dans reservation_items)
      // ⚠️ adapte si ton champ prix s'appelle autrement
      const unitPrice =
        product.price ?? product.unit_price ?? product.unit_price_cents;

      if (unitPrice === undefined || unitPrice === null) {
        await pool.query("ROLLBACK");
        return res.status(500).json({
          message:
            "Prix produit manquant: impossible de remplir unit_price_snapshot",
        });
      }

      await pool.query(
        `INSERT INTO reservation_items (reservation_id, product_id, quantity, unit_price_snapshot)
         VALUES ($1, $2, $3, $4)`,
        [reservation.id, item.product_id, item.quantity, unitPrice]
      );

      await pool.query(
        `UPDATE products
         SET stock_quantity = stock_quantity - $1
         WHERE id = $2`,
        [item.quantity, item.product_id]
      );
    }

    await audit(pool, {
      actor_user_id: req.user.id,
      action: "RESERVATION_CREATE",
      entity: "reservations",
      entity_id: reservation.id,
      details: { items },
    });

    await pool.query("COMMIT");

    res.status(201).json(reservation);
  } catch (e) {
    try {
      await pool.query("ROLLBACK");
    } catch (_) {}
    next(e);
  }
});

/**
 * 🔒 EMPLOYEE / ADMIN
 * Modifier le statut
 * valeurs possibles : EN_ATTENTE, VALIDEE, REFUSEE, PRETE, RECUPEREE, ANNULEE
 */
router.patch("/:id/status", auth(["EMPLOYEE", "ADMIN"]), async (req, res, next) => {
  try {
    const { status } = req.body;
    if (!status) return res.status(400).json({ message: "status requis" });

    const { rows } = await pool.query(
      `UPDATE reservations
       SET status = $1,
           handled_by = $2
       WHERE id = $3
       RETURNING *`,
      [status, req.user.id, req.params.id]
    );

    if (!rows.length) {
      return res.status(404).json({ message: "Réservation introuvable" });
    }

    await audit(pool, {
      actor_user_id: req.user.id,
      action: "RESERVATION_STATUS_UPDATE",
      entity: "reservations",
      entity_id: rows[0].id,
      details: { status },
    });

    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

/**
 * 🔒 ADMIN
 * Supprimer une réservation
 */
router.delete("/:id", auth(["ADMIN"]), async (req, res, next) => {
  try {
    const existing = await getReservationById(req.params.id);
    if (!existing) {
      return res.status(404).json({ message: "Réservation introuvable" });
    }

    await pool.query(`DELETE FROM reservations WHERE id = $1`, [req.params.id]);

    await audit(pool, {
      actor_user_id: req.user.id,
      action: "RESERVATION_DELETE",
      entity: "reservations",
      entity_id: req.params.id,
      details: {},
    });

    res.json({ message: "Réservation supprimée" });
  } catch (e) {
    next(e);
  }
});

module.exports = router;

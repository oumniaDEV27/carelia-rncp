const express = require("express");
const router = express.Router();

const pool = require("../db");
const auth = require("../middleware/auth.middleware");

// ✅ Public: liste + détail
router.get("/", async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT * FROM products ORDER BY id DESC`
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT * FROM products WHERE id=$1`,
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ message: "Produit introuvable" });
    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

// 🔒 EMPLOYEE ou ADMIN: créer / modifier / supprimer
router.post("/", auth(["EMPLOYEE", "ADMIN"]), async (req, res, next) => {
  try {
    const { name, description, price, stock_quantity, category_id } = req.body;

    if (!name) return res.status(400).json({ message: "name requis" });

    const { rows } = await pool.query(
      `INSERT INTO products (name, description, price, stock_quantity, category_id)
       VALUES ($1,$2,$3,$4,$5)
       RETURNING *`,
      [name, description ?? null, price ?? null, stock_quantity ?? 0, category_id ?? null]
    );

    res.status(201).json(rows[0]);
  } catch (e) {
    next(e);
  }
});

router.put("/:id", auth(["EMPLOYEE", "ADMIN"]), async (req, res, next) => {
  try {
    const { name, description, price, stock_quantity, category_id } = req.body;

    const { rows } = await pool.query(
      `UPDATE products
       SET
         name = COALESCE($1, name),
         description = COALESCE($2, description),
         price = COALESCE($3, price),
         stock_quantity = COALESCE($4, stock_quantity),
         category_id = COALESCE($5, category_id)
       WHERE id=$6
       RETURNING *`,
      [name ?? null, description ?? null, price ?? null, stock_quantity ?? null, category_id ?? null, req.params.id]
    );

    if (!rows.length) return res.status(404).json({ message: "Produit introuvable" });
    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

router.delete("/:id", auth(["ADMIN"]), async (req, res, next) => {
  try {
    const { rowCount } = await pool.query(
      `DELETE FROM products WHERE id=$1`,
      [req.params.id]
    );

    if (!rowCount) return res.status(404).json({ message: "Produit introuvable" });
    res.json({ message: "Produit supprimé" });
  } catch (e) {
    next(e);
  }
});

module.exports = router;

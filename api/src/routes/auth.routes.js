const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const pool = require("../db");
const auth = require("../middleware/auth.middleware");

const router = express.Router();

// POST /auth/register
router.post("/register", async (req, res) => {
  try {
    const { first_name, last_name, email, password, role } = req.body;

    if (!first_name || !last_name || !email || !password) {
      return res.status(400).json({ message: "Champs manquants" });
    }

    const finalRole = role || "CLIENT"; // sinon CLIENT

    // Hash du mot de passe
    const password_hash = await bcrypt.hash(password, 10);

    const q = `
      INSERT INTO users (first_name, last_name, email, password_hash, role, is_active)
      VALUES ($1, $2, $3, $4, $5, true)
      RETURNING id, email, role
    `;

    const values = [first_name, last_name, email, password_hash, finalRole];

    const result = await pool.query(q, values);
    return res.status(201).json(result.rows[0]);
  } catch (err) {
    // Email déjà utilisé
    if (err.code === "23505") {
      return res.status(409).json({ message: "Email déjà utilisé" });
    }

    // Role invalide (check constraint)
    if (err.code === "23514") {
      return res.status(400).json({ message: "Role invalide (CLIENT/EMPLOYEE/ADMIN)" });
    }

    console.error("REGISTER ERROR:", err);
    return res.status(500).json({ message: "Erreur serveur" });
  }
});

// POST /auth/login
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email et mot de passe requis" });
    }

    const userRes = await pool.query(
      "SELECT id, email, password_hash, role, is_active FROM users WHERE email = $1",
      [email]
    );

    if (userRes.rows.length === 0) {
      return res.status(401).json({ message: "Identifiants invalides" });
    }

    const user = userRes.rows[0];

    if (!user.is_active) {
      return res.status(403).json({ message: "Compte désactivé" });
    }

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return res.status(401).json({ message: "Identifiants invalides" });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "2h" }
    );

    return res.json({ token });
  } catch (err) {
    console.error("LOGIN ERROR:", err);
    return res.status(500).json({ message: "Erreur serveur" });
  }
});

// GET /auth/me (protégé)
router.get("/me", auth(), async (req, res) => {
  try {
    const r = await pool.query(
      "SELECT id, first_name, last_name, email, role, is_active, created_at FROM users WHERE id = $1",
      [req.user.id]
    );

    if (r.rows.length === 0) return res.status(404).json({ message: "Utilisateur introuvable" });

    return res.json(r.rows[0]);
  } catch (err) {
    console.error("ME ERROR:", err);
    return res.status(500).json({ message: "Erreur serveur" });
  }
});

module.exports = router;

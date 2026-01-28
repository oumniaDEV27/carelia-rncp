const express = require("express");
const router = express.Router();

const pool = require("../db");
const auth = require("../middleware/auth.middleware");

router.get("/", auth(["ADMIN"]), async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT * FROM audit_logs ORDER BY id DESC LIMIT 200`
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

router.get("/:id", auth(["ADMIN"]), async (req, res, next) => {
  try {
    const { rows } = await pool.query(`SELECT * FROM audit_logs WHERE id=$1`, [req.params.id]);
    if (!rows.length) return res.status(404).json({ message: "Log introuvable" });
    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

module.exports = router;

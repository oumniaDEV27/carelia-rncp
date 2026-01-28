const jwt = require("jsonwebtoken");

module.exports = function auth(roles = []) {
  return (req, res, next) => {
    const header = req.headers.authorization;

    if (!header || !header.startsWith("Bearer ")) {
      return res.status(401).json({ message: "Token manquant" });
    }

    const token = header.split(" ")[1];

    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET);

      // payload attendu: { id, email, role }
      if (roles.length && !roles.includes(payload.role)) {
        return res.status(403).json({ message: "Accès refusé" });
      }

      req.user = payload;
      next();
    } catch (err) {
      return res.status(403).json({ message: "Token invalide" });
    }
  };
};

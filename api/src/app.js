require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

// Routes
const authRoutes = require("./routes/auth.routes");
const productsRoutes = require("./routes/products.routes");
const reservationsRoutes = require("./routes/reservations.routes");
const auditRoutes = require("./routes/audit.routes");

// Swagger (optionnel)
let swaggerUi, swaggerJSDoc;
try {
  swaggerUi = require("swagger-ui-express");
  swaggerJSDoc = require("swagger-jsdoc");
} catch (e) {
  // si pas installé, on ignore
}

const app = express();

// Middlewares globaux
app.use(helmet());
app.use(cors());
app.use(express.json()); // ✅ indispensable sinon req.body = undefined

// Healthcheck
app.get("/", (req, res) => {
  res.json({ message: "Carelia API OK" });
});

// Mount routes
app.use("/auth", authRoutes);
app.use("/products", productsRoutes);
app.use("/reservations", reservationsRoutes);
app.use("/audit", auditRoutes);

// Swagger
if (swaggerUi && swaggerJSDoc) {
  const swaggerSpec = swaggerJSDoc({
    definition: {
      openapi: "3.0.0",
      info: {
        title: "Carelia API",
        version: "1.0.0",
      },
      components: {
        securitySchemes: {
          bearerAuth: {
            type: "http",
            scheme: "bearer",
            bearerFormat: "JWT",
          },
        },
      },
      security: [{ bearerAuth: [] }],
    },
    apis: ["./src/routes/*.js"],
  });

  app.use("/docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));
}

// 404
app.use((req, res) => {
  res.status(404).json({ message: "Route non trouvée" });
});

// Error handler
app.use((err, req, res, next) => {
  console.error("❌ ERREUR:", err);
  res.status(500).json({ message: "Erreur serveur" });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`🚀 API Carelia running on http://localhost:${PORT}`);
  if (swaggerUi && swaggerJSDoc) {
    console.log(`📄 Swagger: http://localhost:${PORT}/docs`);
  }
});

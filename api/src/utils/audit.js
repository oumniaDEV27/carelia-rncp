// module.exports = async function audit(pool, { actor_user_id, action, entity, entity_id, details }) {
//   try {
//     await pool.query(
//       `INSERT INTO audit_logs (actor_user_id, action, entity, entity_id, details)
//        VALUES ($1,$2,$3,$4,$5)`,
//       [actor_user_id, action, entity, entity_id ?? null, details ? JSON.stringify(details) : "{}"]
//     );
//   } catch (e) {
//     // on ne casse pas l'API si l'audit échoue
//     console.error("AUDIT ERROR:", e.message);
//   }
// };

// api/src/utils/audit.js
module.exports = async function audit(pool, payload) {
  try {
    const {
      actor_user_id,
      action,
      entity,      // ex: "reservations"
      entity_id,   // ex: 3
      details = {}, // objet
    } = payload;

    // On remplit entity_type (NOT NULL) avec entity
    // Et on met les infos complémentaires dans meta/details
    await pool.query(
      `
      INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, meta, details, entity)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      `,
      [
        actor_user_id,
        action,
        entity,                 // entity_type
        entity_id ?? null,      // entity_id
        details ?? {},          // meta (on peut mettre pareil)
        details ?? {},          // details
        entity,                 // entity (varchar)
      ]
    );
  } catch (e) {
    // On ne bloque jamais l'API si l'audit échoue
    console.error("AUDIT ERROR:", e.message);
  }
};

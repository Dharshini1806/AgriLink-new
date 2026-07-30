const { Client } = require('pg');

const client = new Client({
  connectionString: "postgresql://agri_link_user:zF4Hn3lEisADM5Vvi4PJZbVajuPk970v@dpg-d9ke3upt0dsc739hg9ag-a.virginia-postgres.render.com/agri_link?sslmode=require"
});

async function main() {
  await client.connect();
  console.log("Connected to PostgreSQL successfully!");

  const sellerId = "053213a6-ef0e-40bf-89ab-e93e4c0301a5";
  const params = [sellerId, 20, 0];
  
  try {
    const res = await client.query(
      `SELECT o.*, u.name AS buyer_name, u.phone AS buyer_phone,
              json_agg(json_build_object(
                'id', oi.id, 'product_id', oi.product_id, 'name', p.name,
                'quantity', oi.quantity, 'unit_price', oi.unit_price,
                'image_url', p.image_urls[1]
              )) AS items
       FROM orders o
       JOIN users u ON u.id = o.buyer_id
       JOIN order_items oi ON oi.order_id = o.id
       JOIN products p ON p.id = oi.product_id
       WHERE o.seller_id = $1 
       GROUP BY o.id, u.id
       ORDER BY o.created_at DESC
       LIMIT $2 OFFSET $3`,
      params
    );
    console.log("Query succeeded!");
    console.log("Count of orders returned:", res.rows.length);
    console.log(JSON.stringify(res.rows, null, 2));
  } catch (err) {
    console.error("Query failed with error:", err.message);
    console.error(err);
  }

  await client.end();
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});

const { Client } = require('pg');

const client = new Client({
  connectionString: "postgresql://agri_link_user:zF4Hn3lEisADM5Vvi4PJZbVajuPk970v@dpg-d9ke3upt0dsc739hg9ag-a.virginia-postgres.render.com/agri_link?sslmode=require"
});

async function main() {
  await client.connect();
  console.log("Connected to PostgreSQL successfully!");
  
  // 1. Check orders table columns
  const colsRes = await client.query(`
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'orders'
  `);
  console.log("\n--- Orders Table Columns ---");
  console.log(colsRes.rows.map(r => `${r.column_name} (${r.data_type})`).join(', '));
  
  // 2. Fetch recent orders
  const ordersRes = await client.query(`
    SELECT o.*, u.name AS buyer_name
    FROM orders o
    JOIN users u ON u.id = o.buyer_id
    ORDER BY o.created_at DESC
    LIMIT 5
  `);
  console.log("\n--- Recent Orders ---");
  console.log(JSON.stringify(ordersRes.rows, null, 2));

  // 3. Fetch order items for those orders
  if (ordersRes.rows.length > 0) {
    const orderIds = ordersRes.rows.map(o => o.id);
    const itemsRes = await client.query(`
      SELECT oi.*, p.name AS product_name
      FROM order_items oi
      JOIN products p ON p.id = oi.product_id
      WHERE oi.order_id = ANY($1::uuid[])
    `, [orderIds]);
    console.log("\n--- Order Items ---");
    console.log(JSON.stringify(itemsRes.rows, null, 2));
  }

  await client.end();
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});

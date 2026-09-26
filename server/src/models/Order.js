const pool = require('../../config/database');
const Product = require('./Product');

async function createOrder({ restaurant_id, table_id, session_id, items }) {
  let totalPrice = 0;
  const itemsWithPrices = [];

  for (const item of items) {
    const product = await Product.findById(item.product_id);
    const unitPrice = product.price;
    totalPrice += unitPrice * item.quantity;

    itemsWithPrices.push({
      product_id: item.product_id,
      quantity: item.quantity,
      unit_price: unitPrice
    });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const orderResult = await client.query(
      'INSERT INTO orders (restaurant_id, table_id, session_id, total_price) VALUES ($1, $2, $3, $4) RETURNING *',
      [restaurant_id, table_id, session_id, totalPrice]
    );
    const order = orderResult.rows[0];

    for (const item of itemsWithPrices) {
      await client.query(
        'INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES ($1, $2, $3, $4)',
        [order.id, item.product_id, item.quantity, item.unit_price]
      );
    }

    await client.query('COMMIT');
    return order;

  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

module.exports = { createOrder };
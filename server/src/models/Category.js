const pool= require('../../config/database')

async function findAll() {
    const result= await pool.query('SELECT  * FROM categories ORDER BY sort_order');
    return result.rows
    
}

async function create({restaurant_id, name, sort_order=0}) {

    const result= await pool.query(
        'INSERT INTO categories (restaurant_id, name, sort_order) VALUES ($1, $2, $3) RETURNING *',
        [restaurant_id, name, sort_order]
    );
    return result.rows[0]
    
}
module.exports = { findAll, create}
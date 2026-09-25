const pool= require('../../config/database')

async function findAllTables() {
    const result= await pool.query('SELECT * FROM tables');
    return result.rows
    
}

async function create({restaurant_id, table_number, qr_code}) {
    const result= await pool.query(
        'INSERT INTO tables (restaurant_id, table_number, qr_code) VALUES ($1, $2, $3) RETURNING *',
        [restaurant_id, table_number, qr_code]
    );
    return result.rows[0]
    
}

module.exports={findAllTables, create};
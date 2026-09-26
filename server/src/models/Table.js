const pool= require('../../config/database')
const crypto = require('crypto');


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

async function findById(id){
    const result= await pool.query('SELECT * FROM tables WHERE id=$1', [id]);  
    return result.rows[0]

}

async function startSession(id) {
    const table= await findById(id);
    
    if(table.current_session_id){
        return table
    }
    const newSessionId = crypto.randomUUID();
    const result= await pool.query(
        'UPDATE tables SET current_session_id = $1 WHERE id= $2 RETURNING *', [newSessionId, id]
    );
    return result.rows[0];   
}

module.exports={findAllTables, create, findById, startSession};
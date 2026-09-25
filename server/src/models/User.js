 const pool = require('../../config/database'); 
 async function findByEmail(email) {
    const result = await pool.query(
        'SELECT * FROM users WHERE email = $1', 
        [email]); 
        return result.rows[0]; 
    } 
    async function createUser({ restaurant_id, role, full_name, email, password_hash }) 
    { 
        const result = await pool.query( 
            'INSERT INTO users (restaurant_id, role, full_name, email, password_hash) VALUES ($1, $2, $3, $4, $5) RETURNING id, restaurant_id, role, full_name, email', 
            [restaurant_id, role, full_name, email, password_hash] 
        ); 
        return result.rows[0]; 
    } 
    module.exports = 
    { 
        findByEmail, createUser 
    }
const Order = require('../models/Order');

async function createOrder(req, res) {
    try{
        const{restaurant_id, table_id, session_id, items} = req.body;
        const orders= await Order.createOrder({restaurant_id, table_id, session_id, items});
        res.status(201).json(orders)
    }
    catch(err){
        res.status(500).json({error: err.message})
    }
    
}

module.exports={createOrder}
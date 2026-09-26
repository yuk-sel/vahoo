const { json } = require('express');
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
async function getOrders(req, res) {
    try{
        const orders = await Order.findAll()
        res.status(200).json(orders)
    }
    catch(err){
        res.status(500).json({error: err.message})
    }
}

async function updateOrderStatus(req, res) {
    try{
        const id= req.params.id;
        const {status}= req.body;
        const order= await Order.updateStatus(status, id)
        res.status(200).json(order)

    }
    catch(err){
        res.status(500).json({error: err.message})
    }
    
}

module.exports={createOrder, getOrders, updateOrderStatus}
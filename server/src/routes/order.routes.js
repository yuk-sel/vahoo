const express= require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

router.post('/orders', orderController.createOrder);
router.get('/orders', orderController.getOrders)
router.patch('/orders/:id/status', orderController.updateOrderStatus)

module.exports= router;
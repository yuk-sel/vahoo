const express = require('express');
const router = express.Router();
const menuController = require('../controllers/menuController');

router.get('/categories/:category_id/products', menuController.getProductsByCategory);
router.get('/categories', menuController.getCategories);
router.post('/categories', menuController.createCategory);
router.post('/products', menuController.createProduct);

module.exports = router;
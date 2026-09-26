const express= require('express');
const router= express.Router();
const tableController =require('../controllers/tableController');

router.post('/tables/:id/start-session', tableController.startSession)
router.get('/tables', tableController.getTables);
router.post('/tables', tableController.createTable);

module.exports= router;
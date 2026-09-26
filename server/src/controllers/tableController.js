const Tables = require('../models/Table')

async function getTables(req, res) {
    try{
        const tables= await Tables.findAllTables();
        res.json(tables);
    }
    catch(err){
        res.status(500).json({error: err.message})
    }  
}

async function createTable(req, res) {
    try{
        const{restaurant_id, table_number, qr_code}= req.body;
        const table= await Tables.create({restaurant_id, table_number, qr_code});
        res.status(201).json(table);
    }
    catch(err){
        res.status(500).json({error: err.message})
    }
    
}

async function startSession(req, res) {
    try{
        const id = req.params.id;
        const session = await Tables.startSession(id);
        res.status(200).json(session)

    }
    catch(err){
        res.status(500).json({error: err.message})
    }
    
}

module.exports={getTables, createTable, startSession}
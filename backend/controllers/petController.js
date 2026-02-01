// Mock data for pets
const db = require('../config/db');

exports.getPets = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT * FROM pets 
            ORDER BY 
                CASE 
                    WHEN name = 'Max' THEN 1
                    WHEN name = 'Shasha' THEN 2
                    WHEN name = 'Tyson' THEN 3
                    ELSE 4
                END,
                id ASC
        `);
        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error("Error fetching pets:", error);
        res.status(500).json({ success: false, message: error.message });
    }
};

const db = require('../config/db');
const fs = require('fs');
const path = require('path');

exports.getVaccines = async (req, res) => {
    try {
        const { petId } = req.query;
        let query = 'SELECT id, pet_id as "petId", vaccine_name as "vaccineName", date_issued as "dateIssued", next_due_date as "nextDueDate", type, image_url as "imageUrl" FROM vaccines';
        let params = [];

        if (petId) {
            query += ' WHERE pet_id = $1';
            params.push(petId);
        }

        query += ' ORDER BY date_issued DESC';

        const result = await db.query(query, params);

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error("Error fetching vaccines:", error);
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.addVaccine = async (req, res) => {
    try {
        const { petId, vaccineName, dateIssued, nextDueDate, type } = req.body;

        if (!petId || !vaccineName) {
            return res.status(400).json({
                success: false,
                message: 'Pet ID and Vaccine Name are required'
            });
        }

        const imageUrl = req.file ? `/uploads/${req.file.filename}` : req.body.imageUrl;
        const vaccineType = type || 'Vaccination';

        // Helper to convert DD/MM/YYYY to YYYY-MM-DD and handle empty strings
        const formatForDb = (dateStr) => {
            if (!dateStr || dateStr.trim() === "") return null;
            if (dateStr.includes('/')) {
                const [d, m, y] = dateStr.split('/');
                if (d && m && y && y.length === 4) return `${y}-${m}-${d}`;
            }
            return dateStr;
        };

        const dbDateIssued = formatForDb(dateIssued);
        const dbNextDueDate = formatForDb(nextDueDate);

        const query = `
            INSERT INTO vaccines (pet_id, vaccine_name, date_issued, next_due_date, type, image_url)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id, pet_id as "petId", vaccine_name as "vaccineName", date_issued as "dateIssued", next_due_date as "nextDueDate", type, image_url as "imageUrl"
        `;
        const values = [petId, vaccineName, dbDateIssued, dbNextDueDate, vaccineType, imageUrl];

        const result = await db.query(query, values);

        res.status(201).json({
            success: true,
            message: 'Vaccine record added successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error("Error adding vaccine:", error);
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.analyzeVaccine = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'No image uploaded' });
        }

        const imagePath = req.file.path;
        console.log("Analyzing image at:", imagePath);

        const imageBuffer = fs.readFileSync(imagePath);
        const base64Image = imageBuffer.toString('base64');
        const mimeType = req.file.mimetype;

        // Use standard Google Gemini API key from .env
        const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
        // User confirmed gemini-2.5-flash works
        const MODEL = "gemini-2.5-flash";
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}`;

        console.log(`Sending request to Google Gemini API (${MODEL})...`);

        const response = await fetch(url, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                "contents": [
                    {
                        "parts": [
                            {
                                "text": "Extract details from this vaccine certificate image. Return strictly raw JSON (no markdown) with this schema: { \"vaccineName\": string, \"dateIssued\": \"DD/MM/YYYY\", \"nextDueDate\": \"DD/MM/YYYY\", \"category\": \"Vaccination\" | \"Deworming\" }. If a date is missing, use empty string. Identify the most recent or relevant vaccine if multiple are present. If unsure between Vaccination and Deworming, default to 'Vaccination'.",
                            },
                            {
                                "inline_data": {
                                    "mime_type": mimeType,
                                    "data": base64Image
                                }
                            }
                        ]
                    }
                ],
                "generationConfig": {
                    "response_mime_type": "application/json"
                }
            })
        });

        const data = await response.json();

        // NOTE: Commented out cleanup to persist image as per user request
        /*
        try {
            fs.unlinkSync(imagePath);
        } catch(e) {
            console.error("Error deleting temp file:", e);
        }
        */

        if (!response.ok) {
            console.error("Gemini API Error:", JSON.stringify(data, null, 2));
            throw new Error(data.error?.message || 'AI processing failed');
        }

        const content = data.candidates?.[0]?.content?.parts?.[0]?.text;

        if (!content) {
            throw new Error('No content received from AI');
        }

        console.log("AI Response:", content);

        let jsonResponse;
        try {
            const cleanContent = content.replace(/```json/g, '').replace(/```/g, '').trim();
            jsonResponse = JSON.parse(cleanContent);
        } catch (e) {
            console.error("Failed to parse AI JSON:", content);
            return res.status(500).json({ success: false, message: 'Failed to parse AI response' });
        }

        res.json({
            success: true,
            data: {
                vaccineName: jsonResponse.vaccineName || '',
                category: jsonResponse.category || 'Vaccination',
                dateIssued: jsonResponse.dateIssued || '',
                nextDueDate: jsonResponse.nextDueDate || '',
                imageUrl: `/uploads/${req.file.filename}` // Return saved path
            }
        });

    } catch (error) {
        console.error("Error analyzing vaccine:", error);
        res.status(500).json({ success: false, message: error.message });
    }
};

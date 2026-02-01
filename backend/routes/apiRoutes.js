const express = require('express');
const router = express.Router();
const petController = require('../controllers/petController');
const vaccineController = require('../controllers/vaccineController');
const multer = require('multer');
const path = require('path');

// Configure multer for file uploads
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        // Ideally create this folder if it doesn't exist, for now assume it exists or root
        // For simplicity, let's just use /tmp or current dir/uploads
        // We will create an 'uploads' folder in the root backend
        cb(null, 'uploads/')
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + path.extname(file.originalname))
    }
});

const upload = multer({ storage: storage });

// Pet Routes
router.get('/pets', petController.getPets);

// Vaccine Routes
router.get('/vaccines', vaccineController.getVaccines);
router.post('/vaccines/analyze', upload.single('image'), vaccineController.analyzeVaccine);
router.post('/vaccines', upload.single('certificate'), vaccineController.addVaccine);


module.exports = router;

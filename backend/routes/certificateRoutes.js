// routes/certificateRoutes.js
import express from 'express';
import multer from 'multer';
import path from 'path';
import crypto from 'crypto';
import { fileURLToPath } from 'url';

// Your JWT middleware
import { authenticate } from '../middleware/authMiddleware.js'; // Adjust path as needed

// Import your new controller functions
import { 
    uploadCertificate, 
    downloadCertificate,
    getAllCertificatesForUser // ✅ ADDED
} from '../controllers/certificateController.js'; // Adjust path

// --- ES Module setup for __dirname ---
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// --- Setup storage path (needed by multer) ---
const uploadDir = path.join(__dirname, '..', 'uploads', 'certificates');

// --- Configure Multer for file storage ---
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir); // Save files to our private 'uploads/certificates' folder
    },
    filename: (req, file, cb) => {
        // Generate a unique, secure filename
        const uniqueName = crypto.randomBytes(16).toString('hex') + path.extname(file.originalname);
        cb(null, uniqueName);
    }
});

const upload = multer({ storage: storage });
const router = express.Router();

// --- ROUTES ---

// POST /api/certificates/upload
router.post(
    '/upload',
    authenticate,
    upload.single('certificate'), // Multer middleware
    uploadCertificate // Controller function
);

// GET /api/certificates/download/:id
router.get(
    '/download/:id',
    authenticate,
    downloadCertificate // Controller function
);

// ✅ ADDED ROUTE
// GET /api/certificates/all
router.get(
    '/all',
    authenticate,
    getAllCertificatesForUser
);

export default router;
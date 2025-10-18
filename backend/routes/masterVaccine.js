// routes/masterVaccine.js
import express from 'express';
import { createVaccine } from '../controllers/vaccineController.js';
import { authenticate } from '../middleware/authMiddleware.js';

const router = express.Router();

// POST /api/master-vaccines/
// Creates a new vaccine. Requires admin authentication.
router.post('/', authenticate, createVaccine);

export default router;
// routes/auth.js
import express from 'express';
import { login, register, getProfile } from '../controllers/authController.js';
import { authenticate } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/login', login);
router.post('/register', register);
router.get('/profile', authenticate, getProfile);

// Export the router
export default router;
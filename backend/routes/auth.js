// routes/auth.js
import express from 'express';
import { login, register, getProfile, updateProfile, changePassword } from '../controllers/authController.js';
import { authenticate } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/login', login);
router.post('/register', register);
router.get('/profile', authenticate, getProfile);
router.put('/profile-update', authenticate, updateProfile); 
router.put('/change-password', authenticate, changePassword);

// Export the router
export default router;
import express from 'express';
import { authenticate } from '../middleware/authMiddleware.js';
import {
    addFamilyMember,
    getFamilyMembers,
    getFamilyMemberVaccines,
    getFamilyOverview,
    updateFamilyMember,
    removeFamilyMember
} from '../controllers/familyController.js';

const router = express.Router();

// All routes require authentication
router.use(authenticate);

// Add a new family member
router.post('/members', addFamilyMember);

// Get all family members
router.get('/members', getFamilyMembers);

// Get family overview (all members with vaccine stats)
router.get('/overview', getFamilyOverview);

// Get vaccines for a specific family member
router.get('/members/:memberId/vaccines', getFamilyMemberVaccines);

// Update family member details
router.put('/members/:memberId', updateFamilyMember);

// Remove a family member
router.delete('/members/:memberId', removeFamilyMember);

export default router;
import express from 'express';
import { 
    createEducationalContent,
    getAllEducationalContents,
    getContentsByAdmin,
    getEducationalContentById,
    updateEducationalContent,
    deleteEducationalContent 
} from '../controllers/educationalContent.js';
import { authenticate } from '../middleware/authMiddleware.js';

const router = express.Router();

// Routes are defined here
router.get('/', getAllEducationalContents);
router.get('/:id', getEducationalContentById);

router.post('/', authenticate, createEducationalContent);
router.put('/:id', authenticate, updateEducationalContent);
router.delete('/:id', authenticate, deleteEducationalContent);
router.get('/admin/:adminId', authenticate, getContentsByAdmin);

// Export the router
export default router;
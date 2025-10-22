import express from 'express';
import { findCenters } from '../controllers/finderController.js';

const router = express.Router();

// This route now just points to the 'findCenters' controller function
router.get('/find-centers', findCenters);

// You could add more routes here later, e.g.:
// router.get('/vaccine-details/:id', getVaccineDetails);

export default router;
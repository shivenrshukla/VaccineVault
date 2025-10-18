import express from "express";
import { 
    getRecommendedVaccines,
    updateVaccinationStatus 
} from "../controllers/vaccineController.js";
import { authenticate } from "../middleware/authMiddleware.js";

const router = express.Router();

// Route to get all recommended and pending vaccines for the user
router.get("/recommendations", authenticate, getRecommendedVaccines);

// Route to update the status of a vaccine (i.e., user ticks "yes")
router.put("/status/:userVaccineId", authenticate, updateVaccinationStatus);

export default router;
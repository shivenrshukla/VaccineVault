import express from "express";
import { 
    getRecommendedVaccines,
    updateVaccinationStatus,
    scheduleVaccine,
    getTravelVaccines,
    markVaccineAsTaken,
    selectVaccineBrand,
    getVaccineBrands
} from "../controllers/vaccineController.js";
import { authenticate } from "../middleware/authMiddleware.js";

const router = express.Router();

// Route to get all recommended and pending vaccines for the user
router.get("/recommendations", authenticate, getRecommendedVaccines);

// Route to update the status of a vaccine (i.e., user ticks "yes")
router.put("/status/:userVaccineId", authenticate, updateVaccinationStatus);

router.put('/schedule/:userVaccineId', authenticate, scheduleVaccine);

router.put('/mark-taken/:userVaccineId', authenticate, markVaccineAsTaken);

// ✅ UPDATED ROUTE: Changed param from :vaccineId to :userVaccineId
router.get('/brands/for-user-vaccine/:userVaccineId', authenticate, getVaccineBrands);

router.put('/brands/:userVaccineId', authenticate, selectVaccineBrand)

router.get("/travel",getTravelVaccines);
export default router;
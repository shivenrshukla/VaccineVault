import express from "express";
import { 
    addVaccinationRecord,
    getVaccinationRecords,
    updateVaccinationRecord,
    deleteVaccinationRecord
} from "../controllers/vaccineController.js";
import { authenticate } from "../middleware/authMiddleware.js";

const router = express.Router();

// Route to add a new vaccination record
router.post("/", authenticate, addVaccinationRecord);

// Route to get all vaccination records for the authenticated user
router.get("/", authenticate, getVaccinationRecords);

// Route to update a specific vaccination record by ID
router.put("/:id", authenticate, updateVaccinationRecord);

// Route to delete a specific vaccination record by ID
router.delete("/:id", authenticate, deleteVaccinationRecord);

export default router;
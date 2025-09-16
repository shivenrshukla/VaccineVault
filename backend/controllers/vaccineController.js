import VaccinationRecord from "../models/VaccinationRecord.js";

// Create a new vaccination record
export const addVaccinationRecord = async (req, res) => {
    try {
        const { vaccineName, doseNumber, vaccinationDate, healthcareProvider, location } = req.body;
        const userId = req.user.id;

        const newRecord = await VaccinationRecord.create({
            userId,
            vaccineName,
            doseNumber,
            vaccinationDate,
            healthcareProvider,
            location
        });

        res.status(201).json(newRecord);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

// Get all vaccination records for the authenticated user
export const getVaccinationRecords = async (req, res) => {
    try {
        const userId = req.user.id;
        const records = await VaccinationRecord.findAll({ where: { userId } });
        res.status.json(records);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

// Update a vaccination record by ID
export const updateVaccinationRecord = async (req, res) => {
    try {
        const recordId = req.params.id;
        const userId = req.user.id;
        const { vaccineName, doseNumber, vaccinationDate, healthcareProvider, location } = req.body;

        const record = await VaccinationRecord.findOne({ where: { id: recordId, userId } });
        if (!record) {
            return res.status(404).json({ message: "Record not found" });
        }

        record.vaccineName = vaccineName || record.vaccineName;
        record.doseNumber = doseNumber || record.doseNumber;
        record.vaccinationDate = vaccinationDate || record.vaccinationDate;
        record.healthcareProvider = healthcareProvider || record.healthcareProvider;
        record.location = location || record.location;

        await record.save();
        res.status(200).json(record);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

// Delete a vaccination record by ID
export const deleteVaccinationRecord = async (req, res) => {
    try {
        const recordId = req.params.id;
        const userId = req.user.id;

        const record = await VaccinationRecord.findOne({ where: { id: recordId, userId } });
        if (!record) {
            return res.status(404).json({ message: "Record not found" });
        }

        await record.destroy();
        res.status(200).json({ message: "Record deleted successfully" });
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
};
import User from "../models/User.js"
import Vaccine from "../models/Vaccine.js"
import {Op} from "sequelize";
import UserVaccine from "../models/userVaccine.js";

export const getRecommendedVaccines = async (req, res) => {
    try {
        const userId = req.user.id;
        const user = await User.findByPk(userId);

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        const dob = new Date(user.dateOfBirth);
        const today = new Date();

        // --- Age Calculation (This part is correct) ---
        let ageInMonths = (today.getFullYear() - dob.getFullYear()) * 12;
        ageInMonths += today.getMonth() - dob.getMonth();
        if (today.getDate() < dob.getDate()) {
            ageInMonths--;
        }

        const applicableVaccines = await Vaccine.findAll({
            where: {
                minAgeMonths: { [Op.lte]: ageInMonths },
                [Op.or]: [
                    { maxAgeMonths: { [Op.gte]: ageInMonths } },
                    { maxAgeMonths: null }
                ]
            }
        });

        for (const vaccine of applicableVaccines) {
            await UserVaccine.findOrCreate({
                where: {
                    userId: userId,
                    vaccineId: vaccine.id,
                },
                defaults: {
                    userId: userId,
                    vaccineId: vaccine.id,
                    status: 'pending',
                    
                    // --- THIS IS THE CORRECTED LOGIC ---
                    // Calculate the first due date by adding the minimum eligibility age (in months)
                    // to the user's date of birth.
                    nextDueDate: new Date(new Date(user.dateOfBirth).setMonth(new Date(user.dateOfBirth).getMonth() + vaccine.minAgeMonths))
                }
            });
        }

        const pendingVaccines = await UserVaccine.findAll({
            where: { userId, status: 'pending' },
            include: [{ model: Vaccine, attributes: ['name', 'diseaseProtectedAgainst'] }],
            order: [['nextDueDate', 'ASC']]
        });
        
        res.status(200).json(pendingVaccines);

    } catch (error) {
        console.error("Error fetching recommended vaccines:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

export const updateVaccinationStatus = async(req,res)=>{
    try{
        const {UserVaccineId} = req.params;
        const userId = req.user.id;
        const { hasTaken } = req.body;

        if (typeof hasTaken !== 'boolean' || !hasTaken) {
            return res.status(400).json({ message: "Invalid input: hasTaken must be true" });
        }

        const userVaccine = await UserVaccine.findOne({
            where : {id:userVaccineId,userId},
            include:[Vaccine]
        });

        if (!userVaccine) {
            return res.status(404).json({ message: "Vaccination record not found for this user." });
        }

        userVaccine.completedDoses += 1;
        userVaccine.lastDoseDate = new Date();

        const vaccineInfo = userVaccine.Vaccine;
        const totalDoses = vaccineInfo.schedule.doses.length;

        if (userVaccine.completedDoses >= totalDoses) {
            if (vaccineInfo.boosterIntervalYears) {
                const nextBoosterDate = new Date(userVaccine.lastDoseDate);
                nextBoosterDate.setFullYear(nextBoosterDate.getFullYear() + vaccineInfo.boosterIntervalYears);
                userVaccine.nextDueDate = nextBoosterDate;
                userVaccine.status = 'pending'; // Stays pending for the next booster
            } else {
                userVaccine.status = 'completed';
                userVaccine.nextDueDate = null;
            }
        } else {
            const intervalMonths = vaccineInfo.schedule.doses[userVaccine.completedDoses] - vaccineInfo.schedule.doses[userVaccine.completedDoses - 1];
            const nextDoseDate = new Date(userVaccine.lastDoseDate);
            nextDoseDate.setMonth(nextDoseDate.getMonth() + intervalMonths);
            userVaccine.nextDueDate = nextDoseDate;
        }

        await userVaccine.save();
        res.status(200).json(userVaccine);

    }catch(error){
        console.error("Error updating vaccination status:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
}
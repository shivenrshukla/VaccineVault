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

        // Age Calculation
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
                    completedDoses: 0, // ✅ Initialize completedDoses
                    nextDueDate: new Date(
                        new Date(user.dateOfBirth).setMonth(
                            new Date(user.dateOfBirth).getMonth() + vaccine.minAgeMonths
                        )
                    )
                }
            });
        }

        // ✅ FIXED: Return ALL vaccines, not just pending ones
        const allVaccines = await UserVaccine.findAll({
            where: { userId }, // Remove status filter
            include: [{ 
                model: Vaccine, 
                attributes: ['name', 'diseaseProtectedAgainst', 'schedule'] // ✅ Include schedule
            }],
            order: [
                ['status', 'ASC'], // Pending first
                ['nextDueDate', 'ASC'] // Then by date
            ]
        });

        console.log(`Returning ${allVaccines.length} vaccines for user ${userId}`);
        
        res.status(200).json(allVaccines);

    } catch (error) {
        console.error("Error fetching recommended vaccines:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
};

export const updateVaccinationStatus = async (req, res) => {
  try {
    const { userVaccineId } = req.params;
    const { hasTaken } = req.body;
    const userId = req.user.id;

    console.log('Update request received:', {
      userVaccineId,
      hasTaken,
      userId
    });

    // Validate required fields
    if (!userVaccineId) {
      return res.status(400).json({
        message: 'Vaccine record ID is required'
      });
    }

    if (hasTaken === undefined) {
      return res.status(400).json({
        message: 'hasTaken field is required'
      });
    }

    // Find the user's vaccine record
    const userVaccine = await UserVaccine.findOne({
      where: {
        id: userVaccineId,
        userId: userId
      },
      include: [{
        model: Vaccine,
        attributes: ['name', 'schedule', 'diseaseProtectedAgainst']
      }]
    });

    if (!userVaccine) {
      return res.status(404).json({
        message: 'Vaccine record not found or unauthorized'
      });
    }

    // ✅ FIXED: Only check if we're trying to mark as taken
    if (hasTaken && userVaccine.status === 'completed') {
      return res.status(400).json({
        message: 'This vaccine dose is already marked as completed'
      });
    }

    // Update the vaccination status
    if (hasTaken) {
      userVaccine.status = 'completed';
      userVaccine.completedDoses = (userVaccine.completedDoses || 0) + 1;
      userVaccine.lastDoseDate = new Date().toISOString().split('T')[0];
      
      // Handle multi-dose vaccines
      const vaccine = userVaccine.Vaccine;
      if (vaccine && vaccine.schedule && vaccine.schedule.doses) {
        const totalDoses = vaccine.schedule.doses.length;
        
        if (userVaccine.completedDoses < totalDoses) {
          // More doses needed - keep as pending and calculate next due date
          userVaccine.status = 'pending';
          const nextDose = vaccine.schedule.doses[userVaccine.completedDoses];
          
          if (nextDose && nextDose.ageInMonths) {
            // Get user's date of birth to calculate next due date
            const user = await User.findByPk(userId);
            if (user) {
              const dob = new Date(user.dateOfBirth);
              userVaccine.nextDueDate = new Date(
                dob.setMonth(dob.getMonth() + nextDose.ageInMonths)
              );
            }
          }
        } else {
          // All doses completed - mark as completed
          userVaccine.status = 'completed';
          userVaccine.nextDueDate = null;
        }
      } else {
        // Single dose vaccine - mark as completed
        userVaccine.status = 'completed';
        userVaccine.nextDueDate = null;
      }
      
      console.log('Updated vaccine:', {
        id: userVaccine.id,
        status: userVaccine.status,
        completedDoses: userVaccine.completedDoses,
        totalDoses: vaccine?.schedule?.doses?.length
      });
    }

    await userVaccine.save();

    // ✅ FIXED: Return the updated record with Vaccine info
    const updatedVaccine = await UserVaccine.findOne({
      where: { id: userVaccineId },
      include: [{
        model: Vaccine,
        attributes: ['name', 'schedule', 'diseaseProtectedAgainst']
      }]
    });

    return res.status(200).json({
      message: 'Vaccination status updated successfully',
       updatedVaccine
    });

  } catch (error) {
    console.error('Error updating vaccination status:', error);
    return res.status(500).json({
      message: 'Failed to update vaccination status',
      error: error.message
    });
  }
};

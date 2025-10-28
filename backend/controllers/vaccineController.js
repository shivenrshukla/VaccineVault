import User from "../models/User.js"
import Vaccine from "../models/Vaccine.js"
import {Op} from "sequelize";
import UserVaccine from "../models/userVaccine.js";

// --- HELPER FUNCTIONS ---
function addDaysToDateOnly(dateString, daysToAdd) {
    const [year, month, day] = dateString.split('-').map(Number);
    const date = new Date(Date.UTC(year, month - 1, day));
    date.setUTCDate(date.getUTCDate() + daysToAdd);
    return date.toISOString().split('T')[0];
}

function addMonthsToDateOnly(dateString, monthsToAdd) {
    const [year, month, day] = dateString.split('-').map(Number);
    const totalMonths = (month - 1) + monthsToAdd;
    const newYear = year + Math.floor(totalMonths / 12);
    const newMonthIndex = totalMonths % 12;
    const lastDayOfNewMonth = new Date(Date.UTC(newYear, newMonthIndex + 1, 0)).getUTCDate();
    const newDay = Math.min(day, lastDayOfNewMonth);
    const finalMonth = (newMonthIndex + 1).toString().padStart(2, '0');
    const finalDay = newDay.toString().padStart(2, '0');
    return `${newYear}-${finalMonth}-${finalDay}`;
}
// --- END HELPERS ---

export const getRecommendedVaccines = async (req, res) => {
    try {
        const userId = req.user.id;
        const user = await User.findByPk(userId);
        if (!user) { return res.status(404).json({ message: "User not found" }); }

        const dob = new Date(user.dateOfBirth);
        const today = new Date();
        let ageInMonths = (today.getFullYear() - dob.getFullYear()) * 12;
        ageInMonths += today.getMonth() - dob.getMonth();
        if (today.getDate() < dob.getDate()) ageInMonths--;

        const applicableVaccines = await Vaccine.findAll({
            where: {
                ageOfFirstDoseMonths: { [Op.lte]: ageInMonths },
            }
        });

        for (const vaccine of applicableVaccines) {
            // Calculate the *recommended* due date for the first dose
            const initialDueDate = addMonthsToDateOnly(user.dateOfBirth, vaccine.ageOfFirstDoseMonths);

            // Use findOrCreate
            await UserVaccine.findOrCreate({
                where: { userId: userId, vaccineId: vaccine.id },
                defaults: {
                    userId: userId,
                    vaccineId: vaccine.id,
                    status: 'pending',
                    completedDoses: 0,
                    // ✅ Set the recommended date ONLY when creating the record
                    nextDueDate: initialDueDate
                }
            });

            // ❌ REMOVED the problematic 'if (!created...)' block entirely.
            // We no longer automatically reset the date if it's null later.
        }

        // Return all of the user's vaccine records
        const allVaccines = await UserVaccine.findAll({
            where: { userId },
            include: [{ model: Vaccine }], // Include the full vaccine model
            order: [ ['status', 'ASC'], ['nextDueDate', 'ASC'] ]
        });

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

    if (hasTaken === undefined) { 
      return res.status(400).json({ message: 'hasTaken field is required' });
    }

    const userVaccine = await UserVaccine.findOne({
      where: { id: userVaccineId, userId: userId },
      include: [{ model: Vaccine }] // Include the full Vaccine model
    });

    if (!userVaccine) { 
      return res.status(404).json({ message: 'Vaccine record not found' });
    }

    if (hasTaken) {
      userVaccine.completedDoses += 1;
      userVaccine.lastDoseDate = new Date().toISOString().split('T')[0];
      
      const vaccine = userVaccine.Vaccine;
      const totalPrimaryDoses = vaccine.numberOfDoses || 1;

      // 1. Check if more PRIMARY doses are pending
      if (userVaccine.completedDoses < totalPrimaryDoses) {
        userVaccine.status = 'pending';
        
        const intervalDays = vaccine.doseIntervalsDays[userVaccine.completedDoses - 1];

        // Calculate next due date based on today's date
        const today = new Date();
        const nextDueDate = new Date(today);
        nextDueDate.setDate(today.getDate() + intervalDays);

        // Assign the calculated date
        userVaccine.nextDueDate = nextDueDate;

      
      // 2. Check for a RECURRING booster
      } else if (vaccine.isRecurringBooster && vaccine.boosterIntervalYears > 0) {
        userVaccine.status = 'pending';
        const nextDueDate = new Date();
        nextDueDate.setFullYear(nextDueDate.getFullYear() + vaccine.boosterIntervalYears);
        userVaccine.nextDueDate = nextDueDate.toISOString().split('T')[0];


      // 3. All doses are complete, NO recurring booster
      } else {
        userVaccine.status = 'completed';
        userVaccine.nextDueDate = null;
      }
    }

    await userVaccine.save();

    const updatedVaccine = await UserVaccine.findOne({
      where: { id: userVaccineId },
      include: [{ model: Vaccine }]
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

export const markVaccineAsTaken = async (req, res) => {
  try {
    const { userVaccineId } = req.params;
    const { dosesCompleted, dateTaken } = req.body;
    const userId = req.user.id;

    // Validation
    if (!dosesCompleted || !dateTaken) {
      return res.status(400).json({ message: 'dosesCompleted and dateTaken are required' });
    }

    const userVaccine = await UserVaccine.findOne({
      where: { id: userVaccineId, userId: userId },
      include: [{ model: Vaccine }]
    });

    if (!userVaccine) {
      return res.status(404).json({ message: 'Vaccine record not found' });
    }

    const vaccine = userVaccine.Vaccine;
    const totalDoses = vaccine.numberOfDoses || 1;

    // Validate doses completed
    if (dosesCompleted > totalDoses) {
      return res.status(400).json({ 
        message: `Cannot mark ${dosesCompleted} doses as completed. This vaccine only has ${totalDoses} doses.` 
      });
    }

    // Update the record
    userVaccine.completedDoses = dosesCompleted;
    userVaccine.lastDoseDate = dateTaken;

    // Determine next status
    if (dosesCompleted < totalDoses) {
      // More primary doses needed
      userVaccine.status = 'pending';
      
      // Calculate next due date based on the last completed dose
      const intervalDays = vaccine.doseIntervalsDays[dosesCompleted - 1];
      const nextDueDate = addDaysToDateOnly(dateTaken, intervalDays);
      userVaccine.nextDueDate = nextDueDate;
      
    } else if (vaccine.isRecurringBooster && vaccine.boosterIntervalYears > 0) {
      // All primary doses done, but booster needed
      userVaccine.status = 'pending';
      const [year, month, day] = dateTaken.split('-').map(Number);
      const nextYear = year + vaccine.boosterIntervalYears;
      userVaccine.nextDueDate = `${nextYear}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
      
    } else {
      // Fully complete
      userVaccine.status = 'completed';
      userVaccine.nextDueDate = null;
    }

    await userVaccine.save();

    const updatedVaccine = await UserVaccine.findOne({
      where: { id: userVaccineId },
      include: [{ model: Vaccine }]
    });

    return res.status(200).json({
      message: 'Vaccine marked as taken successfully',
      updatedVaccine
    });

  } catch (error) {
    console.error('Error marking vaccine as taken:', error);
    return res.status(500).json({
      message: 'Failed to mark vaccine as taken',
      error: error.message
    });
  }
};

export const scheduleVaccine = async (req, res) => {
  try {
    const { userVaccineId } = req.params;
    const { nextDueDate } = req.body;
    const userId = req.user.id; 

    if (!nextDueDate) { 
      return res.status(400).json({ message: 'nextDueDate is required' });
    }

    const userVaccine = await UserVaccine.findOne({
      where: { id: userVaccineId, userId: userId, status: 'pending' }
    });

    if (!userVaccine) { 
      return res.status(404).json({ message: 'Pending vaccine record not found' });
    }

    userVaccine.nextDueDate = nextDueDate;
    await userVaccine.save();

    res.status(200).json({
      message: 'Vaccine scheduled successfully',
      updatedVaccine: userVaccine,
    });
  } catch (error) {
    console.error('Error scheduling vaccine:', error);
    res.status(500).json({
      message: 'Failed to schedule vaccine',
      error: error.message,
    });
  }
};

export const getTravelVaccines = async (req, res) => {
  try {
    const { destination } = req.query; // e.g., ?destination=Africa

    const vaccines = await Vaccine.findAll({
      where: { isTravelVaccine: true }
    });

    const filtered = destination
      ? vaccines.filter(v =>
          v.travelRegions?.some(region =>
            region.toLowerCase().includes(destination.toLowerCase())
          )
        )
      : vaccines;

    res.status(200).json({ vaccines: filtered });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Error fetching travel vaccines" });
  }
};

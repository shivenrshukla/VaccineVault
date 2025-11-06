import User from "../models/User.js"
import Vaccine from "../models/Vaccine.js"
import {Op} from "sequelize";
import UserVaccine from "../models/UserVaccine.js"; // Corrected path

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
                // ✅ --- KEY CHANGE ---
                // Only find the "generic" vaccines for recommendation
                brandName: null
            }
        });

        for (const vaccine of applicableVaccines) {
            const initialDueDate = addMonthsToDateOnly(user.dateOfBirth, vaccine.ageOfFirstDoseMonths);
            await UserVaccine.findOrCreate({
                where: { userId: userId, vaccineId: vaccine.id },
                defaults: {
                    userId: userId,
                    vaccineId: vaccine.id,
                    status: 'pending',
                    completedDoses: 0,
                    nextDueDate: initialDueDate
                }
            });
        }

        const allVaccines = await UserVaccine.findAll({
            where: { userId },
            // ✅ Include the full Vaccine model, not just attributes
            include: [
              { model: Vaccine },
              { model: Vaccine, as: 'BrandTaken' }
            ], 
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
      include: [{ model: Vaccine }]
    });

    if (!userVaccine) { 
      return res.status(404).json({ message: 'Vaccine record not found' });
    }

    // Only process if they are marking it as "taken"
    if (!hasTaken) {
      // Logic for "not taken" (e.g., reset, snooze) could go here
      // For now, we just return
      return res.status(200).json({ message: 'No action taken', updatedVaccine: userVaccine });
    }

    // --- ✅ BRAND SELECTION LOGIC ---
    // Check if this is the FIRST dose AND the current vaccine is a GENERIC one
    if (userVaccine.completedDoses === 0 && userVaccine.Vaccine.brandName === null) {
      const genericVaccine = userVaccine.Vaccine;
      
      // Find all available brands for this generic vaccine
      const availableBrands = await Vaccine.findAll({
        where: {
          name: genericVaccine.name,
          brandName: { [Op.not]: null }
        }
      });

      // Update the record for the first dose
      userVaccine.completedDoses = 1;
      userVaccine.lastDoseDate = new Date().toISOString().split('T')[0];
      await userVaccine.save();

      // If brands exist, stop and ask the user to select one
      if (availableBrands && availableBrands.length > 0) {
        return res.status(200).json({
          message: 'First dose recorded. Please select the brand to continue.',
          action: 'SELECT_BRAND', // Signal to client app
          brands: availableBrands,
          updatedVaccine: userVaccine
        });
      }
      
      // If NO brands exist (e.g., BCG), proceed to schedule next dose
      // We fall through to the logic below...
    }
    // --- END BRAND SELECTION LOGIC ---

    // --- STANDARD DOSE SCHEDULING LOGIC ---
    // This logic now runs for:
    // 1. Generic vaccines with no brands (like BCG)
    // 2. All doses *after* a brand has been selected (e.g., dose 2, 3)

    // Increment dose if it wasn't the first dose of a generic (handled above)
    if (userVaccine.Vaccine.brandName !== null) {
        userVaccine.completedDoses += 1;
        userVaccine.lastDoseDate = new Date().toISOString().split('T')[0];
    }
    
    const vaccine = userVaccine.Vaccine; // Use the (potentially new) brand vaccine
    const totalPrimaryDoses = vaccine.numberOfDoses || 1;

    // 1. Check if more PRIMARY doses are pending
    if (userVaccine.completedDoses < totalPrimaryDoses) {
      userVaccine.status = 'pending';
      const intervalDays = vaccine.doseIntervalsDays[userVaccine.completedDoses - 1];
      userVaccine.nextDueDate = addDaysToDateOnly(userVaccine.lastDoseDate, intervalDays);

    // 2. Check for a RECURRING booster
    } else if (vaccine.isRecurringBooster && vaccine.boosterIntervalYears > 0) {
      userVaccine.status = 'pending';
      const nextDueDate = new Date(userVaccine.lastDoseDate);
      nextDueDate.setFullYear(nextDueDate.getFullYear() + vaccine.boosterIntervalYears);
      userVaccine.nextDueDate = nextDueDate.toISOString().split('T')[0];

    // 3. All doses are complete, NO recurring booster
    } else {
      userVaccine.status = 'completed';
      userVaccine.nextDueDate = null;
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

/**
 * NEW ENDPOINT
 * This is called *after* updateVaccinationStatus returns 'SELECT_BRAND'.
 * It links the UserVaccine record to the specific brand and schedules the next dose.
 */
export const selectVaccineBrand = async (req, res) => {
  try {
    const { userVaccineId } = req.params;
    const { brandId } = req.body;
    const userId = req.user.id;

    if (!brandId) {
      return res.status(400).json({ message: 'brandId is required' });
    }

    // 1. Find the UserVaccine record (which is still generic)
    const userVaccine = await UserVaccine.findOne({
      where: { id: userVaccineId, userId: userId },
      include: [{ model: Vaccine }]
    });

    if (!userVaccine) {
      return res.status(404).json({ message: 'Vaccine record not found' });
    }
    if (userVaccine.completedDoses !== 1 || userVaccine.Vaccine.brandName !== null) {
      return res.status(400).json({ message: 'Brand can only be selected after first dose of a generic vaccine' });
    }

    // 2. Find the selected Brand Vaccine
    const brandVaccine = await Vaccine.findByPk(brandId);
    if (!brandVaccine) {
      return res.status(404).json({ message: 'Brand not found' });
    }
    
    // 3. Validate that the brand matches the generic vaccine
    if (userVaccine.Vaccine.name !== brandVaccine.name) {
      return res.status(400).json({ message: 'Brand name mismatch.' });
    }

    // 4. ✅ Update the UserVaccine to point to the new brand
    userVaccine.vaccineId = brandId;

    // 5. Now, schedule the *next* dose based on this brand's rules
    const totalPrimaryDoses = brandVaccine.numberOfDoses || 1;

    if (userVaccine.completedDoses < totalPrimaryDoses) {
      // More primary doses needed
      userVaccine.status = 'pending';
      const intervalDays = brandVaccine.doseIntervalsDays[userVaccine.completedDoses - 1]; // e.g., interval after dose 1
      userVaccine.nextDueDate = addDaysToDateOnly(userVaccine.lastDoseDate, intervalDays);

    } else if (brandVaccine.isRecurringBooster && brandVaccine.boosterIntervalYears > 0) {
      // Brand is 1 dose + booster
      userVaccine.status = 'pending';
      const nextDueDate = new Date(userVaccine.lastDoseDate);
      nextDueDate.setFullYear(nextDueDate.getFullYear() + brandVaccine.boosterIntervalYears);
      userVaccine.nextDueDate = nextDueDate.toISOString().split('T')[0];
      
    } else {
      // Brand is fully complete after 1 dose
      userVaccine.status = 'completed';
      userVaccine.nextDueDate = null;
    }

    await userVaccine.save();
    
    const updatedVaccine = await UserVaccine.findOne({
      where: { id: userVaccineId },
      include: [{ model: Vaccine }]
    });

    res.status(200).json({
      message: 'Brand selected and next dose scheduled',
      updatedVaccine
    });

  } catch (error) {
    console.error('Error selecting vaccine brand:', error);
    res.status(500).json({
      message: 'Failed to select brand',
      error: error.message,
    });
  }
};

/**
 * ✅ FIXED ENDPOINT
 * This now correctly finds the UserVaccine, then its generic Vaccine,
 * then all brands associated with that generic name.
 */
export const getVaccineBrands = async (req, res) => {
  try {
    // ✅ Parameter is now userVaccineId
    const { userVaccineId } = req.params;
    const userId = req.user.id;

    const userVaccine = await UserVaccine.findOne({
      where: { id: userVaccineId, userId: userId },
      include: [{ model: Vaccine, attributes: ['name'] }]
    });

    if (!userVaccine) {
      return res.status(404).json({ message: "Vaccine record not found" });
    }

    // Find all brands matching the generic vaccine's name
    const brands = await Vaccine.findAll({
      where: {
        name: userVaccine.Vaccine.name,
        brandName: { [Op.not]: null }
      },
      // ✅ Return all fields, esp. id, brandName, and numberOfDoses
    });

    res.json({ brands: brands || [] });
  } catch (error) {
    console.error("Error fetching vaccine brands:", error);
    res.status(500).json({ message: "Server error" });
  }
};

/**
 * ✅ UPDATED ENDPOINT
 * Handles catch-up logging, including brand selection and
 * a new 'markAllAsCompleted' flag.
 */
export const markVaccineAsTaken = async (req, res) => {
  try {
    const { userVaccineId } = req.params;
    const { dosesCompleted, dateTaken, brandId, markAllAsCompleted } = req.body;
    const userId = req.user.id;

    if (!dateTaken) {
      return res.status(400).json({ message: 'dateTaken is required' });
    }
    if (!markAllAsCompleted && !dosesCompleted) {
      return res
        .status(400)
        .json({ message: 'dosesCompleted is required if not marking all as taken' });
    }

    let userVaccine = await UserVaccine.findOne({
      where: { id: userVaccineId, userId: userId },
      include: [{ model: Vaccine }],
    });

    if (!userVaccine) {
      return res.status(404).json({ message: 'Vaccine record not found' });
    }

    let vaccine = userVaccine.Vaccine;

    // --- BRAND SELECTION LOGIC for CATCH-UP ---
    // This logic is already correct
    if (vaccine.brandName === null) {
      const availableBrands = await Vaccine.findAll({
        where: { name: vaccine.name, brandName: { [Op.not]: null } },
      });

      if (availableBrands.length > 0) {
        if (!brandId) {
          return res.status(400).json({
            message: 'A brandId is required to log this vaccine.',
            action: 'SELECT_BRAND',
            brands: availableBrands,
          });
        }

        const newBrand = await Vaccine.findByPk(brandId);
        if (!newBrand || newBrand.name !== vaccine.name) {
          return res.status(400).json({ message: 'Invalid brandId provided.' });
        }

        userVaccine.brandTakenId = brandId;
        vaccine = newBrand; // Use the new brand for all calculations
      }
    }
    // --- END CATCH-UP BRAND LOGIC ---

    const totalDoses = vaccine.numberOfDoses || 1;
    let finalDosesCompleted;

    // This part is correct:
    if (markAllAsCompleted === true) {
      finalDosesCompleted = totalDoses;
    } else {
      finalDosesCompleted = parseInt(dosesCompleted, 10);
      if (finalDosesCompleted > totalDoses) {
        return res.status(400).json({
          message: `Cannot mark ${finalDosesCompleted} doses. This brand only has ${totalDoses} doses.`,
        });
      }
    }

    userVaccine.completedDoses = finalDosesCompleted;
    userVaccine.lastDoseDate = dateTaken;
    userVaccine.totalDoses = totalDoses;

    // --- ✅ CORRECTED Rescheduling Logic ---
    // We have REMOVED the 'if (markAllAsCompleted === true)' override.
    // This logic now runs correctly for all cases.

    if (finalDosesCompleted < totalDoses) {
      // Still pending doses (e.g., user logged 1 of 3)
      userVaccine.status = 'pending';
      const intervalDays = vaccine.doseIntervalsDays[finalDosesCompleted - 1];
      userVaccine.nextDueDate = addDaysToDateOnly(dateTaken, intervalDays);

    } else if (vaccine.isRecurringBooster && vaccine.boosterIntervalYears > 0) {
      // ✅ This is the logic you wanted!
      // Primary series is complete, AND this vaccine needs a booster.
      userVaccine.status = 'pending'; // Set to pending for the booster
      const nextDueDate = new Date(dateTaken);
      nextDueDate.setFullYear(
        nextDueDate.getFullYear() + vaccine.boosterIntervalYears
      );
      userVaccine.nextDueDate = nextDueDate.toISOString().split('T')[0];

    } else {
      // Primary series is complete, and NO booster is needed.
      userVaccine.status = 'completed';
      userVaccine.nextDueDate = null;
    }
    // --- END CORRECTED Logic ---

    await userVaccine.save();

    const updatedVaccine = await UserVaccine.findOne({
      where: { id: userVaccineId },
      include: [{ model: Vaccine }],
    });

    return res.status(200).json({
      message: 'Vaccine marked as taken successfully',
      updatedVaccine,
    });
  } catch (error) {
    console.error('Error marking vaccine as taken:', error);
    return res.status(500).json({
      message: 'Failed to mark vaccine as taken',
      error: error.message,
    });
  }
};

// This endpoint does not need to change
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

// This endpoint does not need to change
export const getTravelVaccines = async (req, res) => {
  try {
    const { destination } = req.query; // e.g., ?destination=Africa

    const vaccines = await Vaccine.findAll({
      where: { 
        isTravelVaccine: true,
        // Only show generic travel vaccines in the list
        brandName: null 
      }
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

export const createSituationalSchedule = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      exposureDate,
      isPreviouslyImmunized,
      exposureCategory, // 'catII' or 'catIII'
    } = req.body;

    if (!exposureDate) {
      return res.status(400).json({ message: 'exposureDate is required' });
    }

    // 1. Determine which Rabies schedule to use based on immunization status
    // This logic maps directly to your seeder file
    const brandName = isPreviouslyImmunized
      ? 'Previously Immunized Schedule'
      : 'Unimmunized Schedule (IM)';

    const vaccineTemplate = await Vaccine.findOne({
      where: {
        name: 'Rabies Vaccine (Post-exposure)',
        brandName: brandName,
      },
    });

    if (!vaccineTemplate) {
      console.error(`Missing Rabies template for: ${brandName}`);
      return res
        .status(500)
        .json({ message: 'Rabies schedule template not found on server.' });
    }

    // 2. Check if a pending schedule for this *exact* template already exists
    const existingSchedule = await UserVaccine.findOne({
      where: {
        userId: userId,
        vaccineId: vaccineTemplate.id,
        status: 'pending',
      },
    });

    if (existingSchedule) {
      return res
        .status(409) // 409 Conflict
        .json({ message: 'A pending post-exposure schedule already exists.' });
    }

    // 3. Create the new UserVaccine record
    // This record represents the *entire series* (e.g., all 5 doses)
    const newUserVaccine = await UserVaccine.create({
      userId: userId,
      vaccineId: vaccineTemplate.id, // Links directly to the brand/schedule
      status: 'pending',
      nextDueDate: exposureDate, // Day 0 is the first due date
      lastDoseDate: null,
      completedDoses: 0,
      totalDoses: vaccineTemplate.numberOfDoses, // Will be 2 or 5
      brandTakenId: null, // Not needed, vaccineId *is* the brand
    });

    // 4. Send back the newly created record
    // The frontend will call _fetchVaccines() and this will appear
    res.status(201).json(newUserVaccine);
  } catch (error) {
    console.error('Error creating situational schedule:', error);
    return res.status(500).json({
      message: 'Failed to create situational schedule',
      error: error.message,
    });
  }
};
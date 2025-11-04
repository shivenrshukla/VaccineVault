'use strict';
const { Op } = require('sequelize');

const moToDays = (months) => Math.round(parseFloat(months) * 30.44);
const allVaccines = [
  // --- GENERIC UIP Vaccines (for initial recommendation) ---
  {
    name: 'BCG (Bacillus Calmette-Guérin)',
    brandName: null,
    diseaseProtectedAgainst: 'Tuberculosis (severe forms)',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
  },
  {
    name: 'Hepatitis B Vaccine',
    brandName: null, // GENERIC
    diseaseProtectedAgainst: 'Hepatitis B',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 1, // Placeholder for "take 1st dose"
    doseIntervalsDays: null,
    isRecurringBooster: false, // <-- FIX
    boosterIntervalYears: null, // <-- FIX
    isUIP: true,
    isTravelVaccine: true,
  },
  {
    name: 'Oral Polio Vaccine (OPV)',
    brandName: null, // GENERIC
    diseaseProtectedAgainst: 'Poliomyelitis',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 1, // Placeholder
    doseIntervalsDays: null,
    isRecurringBooster: false, // <-- FIX
    boosterIntervalYears: null, // <-- FIX
    isUIP: true,
    isTravelVaccine: false,
  },
  {
    name: 'Pentavalent Vaccine (DTP-HepB-Hib)',
    brandName: null, // GENERIC
    diseaseProtectedAgainst: 'Diphtheria, Tetanus, Pertussis, Hepatitis B, Hib',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 1, // Placeholder
    doseIntervalsDays: null,
    isRecurringBooster: false, // <-- FIX
    boosterIntervalYears: null, // <-- FIX
    isUIP: true,
    isTravelVaccine: false,
  },
  {
    name: 'Rotavirus Vaccine',
    brandName: null, // GENERIC
    diseaseProtectedAgainst: 'Rotavirus Gastroenteritis',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 1, // Placeholder
    doseIntervalsDays: null,
    isRecurringBooster: false, // <-- FIX
    boosterIntervalYears: null, // <-- FIX
    isUIP: true,
    isTravelVaccine: false,
  },
  {
    name: 'Pneumococcal Conjugate Vaccine (PCV)',
    brandName: null, // GENERIC
    diseaseProtectedAgainst: 'Pneumococcal diseases',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 1, // Placeholder
    doseIntervalsDays: null,
    isRecurringBooster: false, // <-- FIX
    boosterIntervalYears: null, // <-- FIX
    isUIP: true,
    isTravelVaccine: false,
  },
  {
    name: 'MMR (Measles, Mumps, Rubella)',
    brandName: null, // GENERIC
    diseaseProtectedAgainst: 'Measles, Mumps, Rubella',
    ageOfFirstDoseMonths: 9,
    numberOfDoses: 1, // Placeholder
    doseIntervalsDays: null,
    isRecurringBooster: false, // <-- FIX
    boosterIntervalYears: null, // <-- FIX
    isUIP: true,
    isTravelVaccine: false,
  },

  // --- SPECIFIC BRANDS (for scheduling after dose 1) ---
  {
    name: 'Hepatitis B Vaccine',
    brandName: 'UIP-Default',
   diseaseProtectedAgainst: 'Hepatitis B',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([moToDays(1.5), moToDays(4.5)]), // Birth, 6 weeks, 6 months
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: true,
  },
  {
    name: 'Pentavalent Vaccine (DTP-HepB-Hib)',
    brandName: 'Pentavac (UIP)', 
   diseaseProtectedAgainst: 'Diphtheria, Tetanus, Pertussis, Hepatitis B, Hib',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 3,
  doseIntervalsDays: JSON.stringify([moToDays(1), moToDays(1)]), // 2, 3, 4 months
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
  },
  {
    name: 'Rotavirus Vaccine',
    brandName: 'Rotavac (UIP)',
    diseaseProtectedAgainst: 'Rotavirus Gastroenteritis',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 3, // 3 doses
    doseIntervalsDays: JSON.stringify([moToDays(1), moToDays(1)]), // 2, 3, 4 months
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
},
  {
    name: 'Rotavirus Vaccine',
    brandName: 'Rotarix',
    diseaseProtectedAgainst: 'Rotavirus Gastroenteritis',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 2, // 2 doses
    doseIntervalsDays: JSON.stringify([moToDays(2)]), // 2, 4 months
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: false,
    isTravelVaccine: false,
  },
  {
    name: 'MMR (Measles, Mumps, Rubella)',
    brandName: 'Tresivac (UIP)',
    diseaseProtectedAgainst: 'Measles, Mumps, Rubella',
    ageOfFirstDoseMonths: 9,
   numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([moToDays(7)]), // 9 months, 16-24 months
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
  },
  
  // --- GENERIC Travel/Optional (for recommendation) ---
  {
    name: 'COVID-19 Vaccine',
    brandName: null,
    diseaseProtectedAgainst: 'COVID-19',
    ageOfFirstDoseMonths: 18 * 12,
    numberOfDoses: 1, // Placeholder
    doseIntervalsDays: null,
    isRecurringBooster: false, // <-- FIX
    boosterIntervalYears: null, // <-- FIX
    isUIP: false,
    isTravelVaccine: false,
  },
  {
    name: 'Yellow Fever Vaccine',
    brandName: null,
   diseaseProtectedAgainst: 'Yellow Fever',
    ageOfFirstDoseMonths: 9,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: true,
    boosterIntervalYears: 10,
    isUIP: false,
    isTravelVaccine: true,
  },
  {
    name: 'Typhoid Conjugate Vaccine (TCV)',
    brandName: null,
    diseaseProtectedAgainst: 'Typhoid Fever',
    ageOfFirstDoseMonths: 6,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: true,
    boosterIntervalYears: 3,
    isUIP: false,
    isTravelVaccine: true,
  },
  // ... (Keep other travel vaccines, add brands if they exist)
  {
    name: 'Meningococcal Vaccine',
    brandName: null, // GENERIC
ageOfFirstDoseMonths: 2,
    diseaseProtectedAgainst: 'Meningococcal Meningitis',
    numberOfDoses: 1, 
    doseIntervalsDays: null,
    isRecurringBooster: true,
    boosterIntervalYears: 5,
    isUIP: false,
    isTravelVaccine: true,
  },
  {
    name: 'Rabies Vaccine (Pre-exposure)',
    brandName: null, // GENERIC
    diseaseProtectedAgainst: 'Rabies',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 1, // Placeholder
    doseIntervalsDays: null,
    isRecurringBooster: false, // <-- FIX
    boosterIntervalYears: null, // <-- FIX
    isUIP: false,
    isTravelVaccine: true,
  },
  {
    name: 'Japanese Encephalitis Vaccine',
    brandName: null, // GENERIC
ageOfFirstDoseMonths: 9,
    diseaseProtectedAgainst: 'Japanese Encephalitis',
    numberOfDoses: 1, // Placeholder
    doseIntervalsDays: null,
    isRecurringBooster: false, // <-- FIX
    boosterIntervalYears: null, // <-- FIX
    isUIP: false,
    isTravelVaccine: true,
  },

  // --- SPECIFIC BRANDS for Travel/Optional ---
  {
    name: 'COVID-19 Vaccine',
    brandName: 'Covishield',
    diseaseProtectedAgainst: 'COVID-19',
    ageOfFirstDoseMonths: 18 * 12,
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([84]), // 84 days
    isRecurringBooster: true,
    boosterIntervalYears: 1,
    isUIP: false,
    isTravelVaccine: false,
  },
    {
    name: 'COVID-19 Vaccine',
    brandName: 'Covaxin',
    diseaseProtectedAgainst: 'COVID-19',
    ageOfFirstDoseMonths: 18 * 12,
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([28]), // 28 days
    isRecurringBooster: true,
    boosterIntervalYears: 1,
    isUIP: false,
    isTravelVaccine: false,
  },
  {
    name: 'Meningococcal Vaccine',
    brandName: 'Menactra', // Example brand
    ageOfFirstDoseMonths: 2,
    diseaseProtectedAgainst: 'Meningococcal Meningitis',
    numberOfDoses: 1, // Note: This varies by age, 1 dose is for 2yrs+
    doseIntervalsDays: null,
    isRecurringBooster: true,
    boosterIntervalYears: 5,
    isUIP: false,
    isTravelVaccine: true,
  },
  {
    name: 'Rabies Vaccine (Pre-exposure)',
    brandName: 'Default Schedule',
    diseaseProtectedAgainst: 'Rabies',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([7, 14]), // Day 0, 7, 21 or 28
    isRecurringBooster: true,
    boosterIntervalYears: 3,
    isUIP: false,
    isTravelVaccine: true,
  },
  {
    name: 'Japanese Encephalitis Vaccine',
    brandName: 'JENVAC', // Example brand
    ageOfFirstDoseMonths: 9,
    diseaseProtectedAgainst: 'Japanese Encephalitis',
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([moToDays(1)]),
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: false,
    isTravelVaccine: true,
  },
];

// ... (The 'up' and 'down' functions are correct from the previous step)
// 
module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Find existing vaccines based on both name and brandName
    const existingVaccines = await queryInterface.sequelize.query(
      `SELECT name, "brandName" FROM "Vaccines" WHERE name IN (:names)`,
      {
        replacements: 
{ names: allVaccines.map(v => v.name) },
        type: Sequelize.QueryTypes.SELECT,
      }
    );

    // Filter out vaccines that already exist
    const newVaccines = allVaccines.filter(v_new => {
      // Find if an old vaccine matches the new one's composite key
      return !existingVaccines.some(v_old => 
        v_old.name === v_new.name && v_old.brandName === (v_new.brandName || null)
      );
    });

if (newVaccines.length > 0) {
      await queryInterface.bulkInsert('Vaccines', newVaccines, {});
}
  },

  down: async (queryInterface, Sequelize) => {
    // Delete all vaccines that match the composite key (name + brandName) from our list
    await queryInterface.bulkDelete('Vaccines', {
      [Op.or]: allVaccines.map(v => ({
        name: v.name,
        brandName: v.brandName || null
      }))
    }, {});
}
};
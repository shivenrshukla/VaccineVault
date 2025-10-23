'use strict';
const { Op } = require('sequelize');

/**
 * Helper to convert a float (months) to an integer (days)
 * e.g., 1.5 months -> 45 days
 */
const moToDays = (months) => Math.round(parseFloat(months) * 30.44);

// All vaccine data is now directly in the NEW schema
const allVaccines = [
  // --- Universal Immunization Programme (UIP) Vaccines ---
  {
    name: 'BCG (Bacillus Calmette-Guérin)',
    diseaseProtectedAgainst: 'Tuberculosis (severe forms)',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true
  },
  {
    name: 'Hepatitis B Vaccine (Birth Dose)',
    diseaseProtectedAgainst: 'Hepatitis B',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([moToDays(1.5), moToDays(4.5)]), // Gaps: [D1->D2], [D2->D3]
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true
  },
  {
    name: 'Oral Polio Vaccine (OPV)',
    diseaseProtectedAgainst: 'Poliomyelitis',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 4,
    doseIntervalsDays: JSON.stringify([moToDays(1.5), moToDays(1), moToDays(1)]), // Gaps: 1.5mo, 1mo, 1mo
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true
  },
  {
    name: 'Pentavalent Vaccine (DTP-HepB-Hib)',
    diseaseProtectedAgainst: 'Diphtheria, Tetanus, Pertussis, Hepatitis B, Hib',
    ageOfFirstDoseMonths: 2, // Rounded from 1.5
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([moToDays(1), moToDays(1)]), // Gaps: 1mo, 1mo
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true
  },
  {
    name: 'Rotavirus Vaccine',
    diseaseProtectedAgainst: 'Rotavirus Gastroenteritis',
    ageOfFirstDoseMonths: 2, // Rounded from 1.5
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([moToDays(1), moToDays(1)]), // Gaps: 1mo, 1mo
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true
  },
  {
    name: 'Pneumococcal Conjugate Vaccine (PCV)',
    diseaseProtectedAgainst: 'Pneumococcal diseases (like pneumonia, meningitis)',
    ageOfFirstDoseMonths: 2, // Rounded from 1.5
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([moToDays(2), moToDays(5.5)]), // Gaps: 2mo, 5.5mo
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true
  },
  {
    name: 'MMR (Measles, Mumps, and Rubella)',
    diseaseProtectedAgainst: 'Measles, Mumps, Rubella',
    ageOfFirstDoseMonths: 9,
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([moToDays(7)]), // Gap: 7mo
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true
  },
  {
    name: 'DTP Booster',
    diseaseProtectedAgainst: 'Diphtheria, Tetanus, Pertussis',
    ageOfFirstDoseMonths: 16,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true
  },
  {
    name: 'Td Vaccine (Tetanus, Diphtheria)',
    diseaseProtectedAgainst: 'Tetanus, Diphtheria',
    ageOfFirstDoseMonths: 120, // 10 years
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: true,
    boosterIntervalYears: 10,
    isUIP: true
  },

  // --- Optional / Private Market Vaccines ---
  {
    name: 'Varicella (Chickenpox) Vaccine',
    diseaseProtectedAgainst: 'Chickenpox',
    ageOfFirstDoseMonths: 12,
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([moToDays(3)]), // Gap: 3mo
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: false
  },
  {
    name: 'Hepatitis A Vaccine',
    diseaseProtectedAgainst: 'Hepatitis A',
    ageOfFirstDoseMonths: 12,
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([moToDays(6)]), // Gap: 6mo
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: false
  },
  {
    name: 'Typhoid Conjugate Vaccine (TCV)',
    diseaseProtectedAgainst: 'Typhoid Fever',
    ageOfFirstDoseMonths: 6,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: true,
    boosterIntervalYears: 3,
    isUIP: false
  },
  {
    name: 'Influenza (Flu) Vaccine',
    diseaseProtectedAgainst: 'Influenza',
    ageOfFirstDoseMonths: 6,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: true,
    boosterIntervalYears: 1,
    isUIP: false
  },
  {
    name: 'HPV (Human Papillomavirus) Vaccine',
    diseaseProtectedAgainst: 'Cervical Cancer(females), Genital warts(males)',
    ageOfFirstDoseMonths: 108, // 9 years
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([moToDays(6)]), // Gap: 6mo
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: false
  },
  {
    name: 'Meningococcal Vaccine',
    diseaseProtectedAgainst: 'Meningococcal Meningitis',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: true,
    boosterIntervalYears: 5,
    isUIP: false
  },

  // --- Travel / Special Purpose Vaccines ---
  {
    name: 'Japanese Encephalitis Vaccine',
    diseaseProtectedAgainst: 'Japanese Encephalitis',
    ageOfFirstDoseMonths: 9,
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([moToDays(1)]), // Gap: 1mo
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: false
  },
  {
    name: 'Yellow Fever Vaccine',
    diseaseProtectedAgainst: 'Yellow Fever',
    ageOfFirstDoseMonths: 9,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: false
  },
  {
    name: 'Rabies Vaccine (Pre-exposure)',
    diseaseProtectedAgainst: 'Rabies',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([7, 14]), // Gaps: D1->D2 is 7 days, D2->D3 is 14 days
    isRecurringBooster: true,
    boosterIntervalYears: 3,
    isUIP: false
  },
  {
    name: 'COVID-19 Vaccine',
    diseaseProtectedAgainst: 'COVID-19',
    ageOfFirstDoseMonths: 6,
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([moToDays(1)]), // Gap: 1mo
    isRecurringBooster: true,
    boosterIntervalYears: 1,
    isUIP: false
  },
];

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Find all existing vaccines by name
    const existingVaccines = await queryInterface.sequelize.query(
      `SELECT name FROM "Vaccines" WHERE name IN (:names)`,
      {
        replacements: { names: allVaccines.map(v => v.name) },
        type: Sequelize.QueryTypes.SELECT,
      }
    );
    const existingNames = existingVaccines.map(v => v.name);

    // Filter out the vaccines that already exist
    const newVaccines = allVaccines.filter(v => !existingNames.includes(v.name));

    // Insert only the new vaccines
    if (newVaccines.length > 0) {
      await queryInterface.bulkInsert('Vaccines', newVaccines, {});
    }
  },

  down: async (queryInterface, Sequelize) => {
    // This will remove all vaccines listed in the seeder
    await queryInterface.bulkDelete('Vaccines', {
      name: {
        [Op.in]: allVaccines.map(v => v.name)
      }
    }, {});
  }
};
'use strict';
const { Op } = require('sequelize');
// sequelize db:seed:all
// The single source of truth for all vaccine data
const allVaccines = [
  // --- Universal Immunization Programme (UIP) Vaccines ---
  { name: 'BCG (Bacillus Calmette-Guérin)', diseaseProtectedAgainst: 'Tuberculosis (severe forms)', minAgeMonths: 0, maxAgeMonths: 1, schedule: JSON.stringify({ "doses": [0] }), boosterIntervalYears: null, isUIP: true },
  { name: 'Hepatitis B Vaccine (Birth Dose)', diseaseProtectedAgainst: 'Hepatitis B', minAgeMonths: 0, maxAgeMonths: null, schedule: JSON.stringify({ "doses": [0, 1.5, 6] }), boosterIntervalYears: null, isUIP: true },
  { name: 'Oral Polio Vaccine (OPV)', diseaseProtectedAgainst: 'Poliomyelitis', minAgeMonths: 0, maxAgeMonths: 60, schedule: JSON.stringify({ "doses": [0, 1.5, 2.5, 3.5] }), boosterIntervalYears: null, isUIP: true },
  { name: 'Pentavalent Vaccine (DTP-HepB-Hib)', diseaseProtectedAgainst: 'Diphtheria, Tetanus, Pertussis, Hepatitis B, Hib', minAgeMonths: 1, maxAgeMonths: 12, schedule: JSON.stringify({ "doses": [1.5, 2.5, 3.5] }), boosterIntervalYears: null, isUIP: true },
  { name: 'Rotavirus Vaccine', diseaseProtectedAgainst: 'Rotavirus Gastroenteritis', minAgeMonths: 1, maxAgeMonths: 8, schedule: JSON.stringify({ "doses": [1.5, 2.5, 3.5] }), boosterIntervalYears: null, isUIP: true },
  { name: 'Pneumococcal Conjugate Vaccine (PCV)', diseaseProtectedAgainst: 'Pneumococcal diseases (like pneumonia, meningitis)', minAgeMonths: 1, maxAgeMonths: 9, schedule: JSON.stringify({ "doses": [1.5, 3.5, 9] }), boosterIntervalYears: null, isUIP: true },
  { name: 'MMR (Measles, Mumps, and Rubella)', diseaseProtectedAgainst: 'Measles, Mumps, Rubella', minAgeMonths: 9, maxAgeMonths: 60, schedule: JSON.stringify({ "doses": [0, 7] }), boosterIntervalYears: null, isUIP: true },
  { name: 'DTP Booster', diseaseProtectedAgainst: 'Diphtheria, Tetanus, Pertussis', minAgeMonths: 16, maxAgeMonths: 24, schedule: JSON.stringify({ "doses": [0] }), boosterIntervalYears: null, isUIP: true },
  { name: 'Td Vaccine (Tetanus, Diphtheria)', diseaseProtectedAgainst: 'Tetanus, Diphtheria', minAgeMonths: 120, maxAgeMonths: 192, schedule: JSON.stringify({ "doses": [0] }), boosterIntervalYears: 10, isUIP: true },
  // --- Optional / Private Market Vaccines ---
  { name: 'Varicella (Chickenpox) Vaccine', diseaseProtectedAgainst: 'Chickenpox', minAgeMonths: 12, maxAgeMonths: null, schedule: JSON.stringify({ "doses": [0, 3] }), boosterIntervalYears: null, isUIP: false },
  { name: 'Hepatitis A Vaccine', diseaseProtectedAgainst: 'Hepatitis A', minAgeMonths: 12, maxAgeMonths: null, schedule: JSON.stringify({ "doses": [0, 6] }), boosterIntervalYears: null, isUIP: false },
  { name: 'Typhoid Conjugate Vaccine (TCV)', diseaseProtectedAgainst: 'Typhoid Fever', minAgeMonths: 6, maxAgeMonths: null, schedule: JSON.stringify({ "doses": [0] }), boosterIntervalYears: 3, isUIP: false },
  { name: 'Influenza (Flu) Vaccine', diseaseProtectedAgainst: 'Influenza', minAgeMonths: 6, maxAgeMonths: null, schedule: JSON.stringify({ "doses": [0] }), boosterIntervalYears: 1, isUIP: false },
  { name: 'HPV (Human Papillomavirus) Vaccine', diseaseProtectedAgainst: 'Cervical Cancer', minAgeMonths: 108, maxAgeMonths: 540, schedule: JSON.stringify({ "doses": [0, 6] }), boosterIntervalYears: null, isUIP: false },
  { name: 'Meningococcal Vaccine', diseaseProtectedAgainst: 'Meningococcal Meningitis', minAgeMonths: 2, maxAgeMonths: null, schedule: JSON.stringify({ "doses": [0] }), boosterIntervalYears: 5, isUIP: false },
  // --- Travel / Special Purpose Vaccines ---
  { name: 'Japanese Encephalitis Vaccine', diseaseProtectedAgainst: 'Japanese Encephalitis', minAgeMonths: 9, maxAgeMonths: null, schedule: JSON.stringify({ "doses": [0, 1] }), boosterIntervalYears: null, isUIP: false },
  { name: 'Yellow Fever Vaccine', diseaseProtectedAgainst: 'Yellow Fever', minAgeMonths: 9, maxAgeMonths: null, schedule: JSON.stringify({ "doses": [0] }), boosterIntervalYears: null, isUIP: false },
  { name: 'Rabies Vaccine (Pre-exposure)', diseaseProtectedAgainst: 'Rabies', minAgeMonths: 0, maxAgeMonths: null, schedule: JSON.stringify({ "doses": [0, 7, 21] }), boosterIntervalYears: 3, isUIP: false },
  { name: 'COVID-19 Vaccine', diseaseProtectedAgainst: 'COVID-19', minAgeMonths: 6, maxAgeMonths: null, schedule: JSON.stringify({ "doses": [0, 1] }), boosterIntervalYears: 1, isUIP: false },
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
    // This will remove all vaccines listed in the seeder, which is useful for rollbacks
    await queryInterface.bulkDelete('Vaccines', {
      name: {
        [Op.in]: allVaccines.map(v => v.name)
      }
    }, {});
  }
};
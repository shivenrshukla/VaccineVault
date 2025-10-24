'use strict';
const { Op } = require('sequelize');

const moToDays = (months) => Math.round(parseFloat(months) * 30.44);

const allVaccines = [
  // --- UIP Vaccines ---
  {
    name: 'BCG (Bacillus Calmette-Guérin)',
    diseaseProtectedAgainst: 'Tuberculosis (severe forms)',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
    travelRegions: null,
    mandatoryFor: null,
    travelNotes: null
  },
  {
    name: 'Hepatitis B Vaccine (Birth Dose)',
    diseaseProtectedAgainst: 'Hepatitis B',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([moToDays(1.5), moToDays(4.5)]),
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
    travelRegions: ["Global", "Unsafe food/water areas"],
    mandatoryFor: null,
    travelNotes: "Recommended for travelers visiting areas with poor sanitation."
  },
  {
    name: 'Oral Polio Vaccine (OPV)',
    diseaseProtectedAgainst: 'Poliomyelitis',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 4,
    doseIntervalsDays: JSON.stringify([moToDays(1.5), moToDays(1), moToDays(1)]),
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
    travelRegions: null,
    mandatoryFor: null,
    travelNotes: null
  },
  {
    name: 'Pentavalent Vaccine (DTP-HepB-Hib)',
    diseaseProtectedAgainst: 'Diphtheria, Tetanus, Pertussis, Hepatitis B, Hib',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([moToDays(1), moToDays(1)]),
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
    travelRegions: null,
    mandatoryFor: null,
    travelNotes: null
  },
  {
    name: 'Rotavirus Vaccine',
    diseaseProtectedAgainst: 'Rotavirus Gastroenteritis',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([moToDays(1), moToDays(1)]),
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
    travelRegions: null,
    mandatoryFor: null,
    travelNotes: null
  },
  {
    name: 'Pneumococcal Conjugate Vaccine (PCV)',
    diseaseProtectedAgainst: 'Pneumococcal diseases',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([moToDays(2), moToDays(5.5)]),
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
    travelRegions: null,
    mandatoryFor: null,
    travelNotes: null
  },
  {
    name: 'MMR (Measles, Mumps, Rubella)',
    diseaseProtectedAgainst: 'Measles, Mumps, Rubella',
    ageOfFirstDoseMonths: 9,
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([moToDays(7)]),
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
    travelRegions: null,
    mandatoryFor: null,
    travelNotes: null
  },

  // --- Travel / Optional Vaccines ---
  {
    name: 'Yellow Fever Vaccine',
    diseaseProtectedAgainst: 'Yellow Fever',
    ageOfFirstDoseMonths: 9,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: true,
    boosterIntervalYears: 10,
    isUIP: false,
    isTravelVaccine: true,
    travelRegions: ["Africa", "South America"],
    mandatoryFor: ["Some African and South American countries"],
    travelNotes: "Certificate required for entry; only given at authorized centers in India."
  },
  {
    name: 'Typhoid Conjugate Vaccine (TCV)',
    diseaseProtectedAgainst: 'Typhoid Fever',
    ageOfFirstDoseMonths: 6,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: true,
    boosterIntervalYears: 3,
    isUIP: false,
    isTravelVaccine: true,
    travelRegions: ["Asia", "Africa"],
    mandatoryFor: null,
    travelNotes: "Recommended for areas with poor sanitation."
  },
  {
    name: 'Meningococcal Vaccine',
    diseaseProtectedAgainst: 'Meningococcal Meningitis',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: true,
    boosterIntervalYears: 5,
    isUIP: false,
    isTravelVaccine: true,
    travelRegions: ["Saudi Arabia", "US", "UK"],
    mandatoryFor: ["Hajj pilgrims", "Some students abroad"],
    travelNotes: "Mandatory for Hajj pilgrims; recommended for students in some countries."
  },
  {
    name: 'Rabies Vaccine (Pre-exposure)',
    diseaseProtectedAgainst: 'Rabies',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([7, 14]),
    isRecurringBooster: true,
    boosterIntervalYears: 3,
    isUIP: false,
    isTravelVaccine: true,
    travelRegions: ["High-risk rural areas"],
    mandatoryFor: null,
    travelNotes: "Recommended for travelers in high-risk areas."
  },
  {
    name: 'Japanese Encephalitis Vaccine',
    diseaseProtectedAgainst: 'Japanese Encephalitis',
    ageOfFirstDoseMonths: 9,
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([moToDays(1)]),
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: false,
    isTravelVaccine: true,
    travelRegions: ["Rural Asia"],
    mandatoryFor: null,
    travelNotes: "Recommended for long stays in rural Asia."
  },
];

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const existingVaccines = await queryInterface.sequelize.query(
      `SELECT name FROM "Vaccines" WHERE name IN (:names)`,
      {
        replacements: { names: allVaccines.map(v => v.name) },
        type: Sequelize.QueryTypes.SELECT,
      }
    );
    const existingNames = existingVaccines.map(v => v.name);

    const newVaccines = allVaccines.filter(v => !existingNames.includes(v.name));

    if (newVaccines.length > 0) {
      await queryInterface.bulkInsert('Vaccines', newVaccines, {});
    }
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.bulkDelete('Vaccines', {
      name: { [Op.in]: allVaccines.map(v => v.name) }
    }, {});
  }
};

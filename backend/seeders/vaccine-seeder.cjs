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
    brandName: null,
    diseaseProtectedAgainst: 'Hepatitis B',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: true,
  },
  {
    name: 'Oral Polio Vaccine (OPV)',
    brandName: null,
    diseaseProtectedAgainst: 'Poliomyelitis',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
  },
  {
    name: 'Pentavalent Vaccine (DTP-HepB-Hib)',
    brandName: null,
    diseaseProtectedAgainst: 'Diphtheria, Tetanus, Pertussis, Hepatitis B, Hib',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
  },
  {
    name: 'Rotavirus Vaccine',
    brandName: null,
    diseaseProtectedAgainst: 'Rotavirus Gastroenteritis',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
  },
  {
    name: 'Pneumococcal Conjugate Vaccine (PCV)',
    brandName: null,
    diseaseProtectedAgainst: 'Pneumococcal diseases',
    ageOfFirstDoseMonths: 2,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
  },
  {
    name: 'MMR (Measles, Mumps, Rubella)',
    brandName: null,
    diseaseProtectedAgainst: 'Measles, Mumps, Rubella',
    ageOfFirstDoseMonths: 9,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
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
    doseIntervalsDays: JSON.stringify([moToDays(1.5), moToDays(4.5)]),
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
    doseIntervalsDays: JSON.stringify([moToDays(1), moToDays(1)]),
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
    numberOfDoses: 3,
    doseIntervalsDays: JSON.stringify([moToDays(1), moToDays(1)]),
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
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([moToDays(2)]),
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
    doseIntervalsDays: JSON.stringify([moToDays(7)]),
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: true,
    isTravelVaccine: false,
  },

  // --- GENERIC Travel/Optional ---
  {
    name: 'COVID-19 Vaccine',
    brandName: null,
    diseaseProtectedAgainst: 'COVID-19',
    ageOfFirstDoseMonths: 18 * 12,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
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
  {
    name: 'Meningococcal Vaccine',
    brandName: null,
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
    brandName: null,
    diseaseProtectedAgainst: 'Rabies',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: false,
    isTravelVaccine: true,
  },
  {
    name: 'Japanese Encephalitis Vaccine',
    brandName: null,
    ageOfFirstDoseMonths: 9,
    diseaseProtectedAgainst: 'Japanese Encephalitis',
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: false,
    boosterIntervalYears: null,
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
    doseIntervalsDays: JSON.stringify([84]),
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
    doseIntervalsDays: JSON.stringify([28]),
    isRecurringBooster: true,
    boosterIntervalYears: 1,
    isUIP: false,
    isTravelVaccine: false,
  },
  {
    name: 'Meningococcal Vaccine',
    brandName: 'Menactra',
    ageOfFirstDoseMonths: 2,
    diseaseProtectedAgainst: 'Meningococcal Meningitis',
    numberOfDoses: 1,
    doseIntervalsDays: null,
    isRecurringBooster: true,
    boosterIntervalYears: 5,
    isUIP: false,
    isTravelVaccine: true,
  },

  // --- Rabies Post-exposure Schedules ---
  {
    name: 'Rabies Vaccine (Post-exposure)',
    brandName: 'Unimmunized Schedule (IM)',
    diseaseProtectedAgainst: 'Rabies',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 5,
    doseIntervalsDays: JSON.stringify([3, 4, 7, 14]), // Day 0,3,7,14,28
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: false,
    isTravelVaccine: false,
  },
  {
    name: 'Rabies Vaccine (Post-exposure)',
    brandName: 'Previously Immunized Schedule',
    diseaseProtectedAgainst: 'Rabies',
    ageOfFirstDoseMonths: 0,
    numberOfDoses: 2,
    doseIntervalsDays: JSON.stringify([3]), // Day 0,3
    isRecurringBooster: false,
    boosterIntervalYears: null,
    isUIP: false,
    isTravelVaccine: false,
  },

  {
    name: 'Japanese Encephalitis Vaccine',
    brandName: 'JENVAC',
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

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const existingVaccines = await queryInterface.sequelize.query(
      `SELECT name, "brandName" FROM "Vaccines" WHERE name IN (:names)`,
      {
        replacements: { names: allVaccines.map(v => v.name) },
        type: Sequelize.QueryTypes.SELECT,
      }
    );

    const newVaccines = allVaccines.filter(v_new => {
      return !existingVaccines.some(
        v_old =>
          v_old.name === v_new.name &&
          v_old.brandName === (v_new.brandName || null)
      );
    });

    if (newVaccines.length > 0) {
      await queryInterface.bulkInsert('Vaccines', newVaccines, {});
    }
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.bulkDelete(
      'Vaccines',
      {
        [Op.or]: allVaccines.map(v => ({
          name: v.name,
          brandName: v.brandName || null,
        })),
      },
      {}
    );
  },
};

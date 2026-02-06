'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('Vaccines', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      name: {
        type: Sequelize.STRING,
        allowNull: false
      },
      brandName: {
        type: Sequelize.STRING,
        allowNull: true
      },
      diseaseProtectedAgainst: {
        type: Sequelize.STRING,
        allowNull: false
      },
      ageOfFirstDoseMonths: {
        type: Sequelize.FLOAT,
        allowNull: false,
        defaultValue: 0
      },
      numberOfDoses: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 1
      },
      doseIntervalsDays: {
        type: Sequelize.TEXT, 
        allowNull: true
      },
      isRecurringBooster: {
        type: Sequelize.BOOLEAN,
        defaultValue: false
      },
      boosterIntervalYears: {
        type: Sequelize.INTEGER,
        allowNull: true
      },
      isUIP: {
        type: Sequelize.BOOLEAN,
        defaultValue: false
      },
      isTravelVaccine: {
        type: Sequelize.BOOLEAN,
        defaultValue: false
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
    });

    // Add unique constraint
    await queryInterface.addConstraint('Vaccines', {
      fields: ['name', 'brandName'],
      type: 'unique',
      name: 'unique_vaccine_brand'
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('Vaccines');
  }
};
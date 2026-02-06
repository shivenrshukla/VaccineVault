'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('Vaccines', 'travelRegions', {
      type: Sequelize.ARRAY(Sequelize.STRING),
      allowNull: true
    });
    await queryInterface.addColumn('Vaccines', 'mandatoryFor', {
      type: Sequelize.ARRAY(Sequelize.STRING),
      allowNull: true
    });
    await queryInterface.addColumn('Vaccines', 'travelNotes', {
      type: Sequelize.TEXT,
      allowNull: true
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('Vaccines', 'travelRegions');
    await queryInterface.removeColumn('Vaccines', 'mandatoryFor');
    await queryInterface.removeColumn('Vaccines', 'travelNotes');
  }
};
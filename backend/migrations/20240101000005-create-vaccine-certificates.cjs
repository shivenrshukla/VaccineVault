'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('VaccineCertificates', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      certificateFilename: {
        type: Sequelize.STRING,
        allowNull: false
      },
      originalFileName: {
        type: Sequelize.STRING,
        allowNull: true
      },
      fileMimeType: {
        type: Sequelize.STRING,
        allowNull: true
      },
      // Foreign Keys
      userId: {
        type: Sequelize.INTEGER,
        references: {
          model: 'Users',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      userVaccineId: {
        type: Sequelize.INTEGER,
        references: {
          model: 'UserVaccines',
          key: 'id'
        },
        onDelete: 'CASCADE'
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
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('VaccineCertificates');
  }
};
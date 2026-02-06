'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('UserVaccines', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      status: {
        type: Sequelize.ENUM('pending', 'completed'),
        allowNull: false,
        defaultValue: 'pending'
      },
      nextDueDate: {
        type: Sequelize.DATEONLY,
        allowNull: true
      },
      lastDoseDate: {
        type: Sequelize.DATEONLY,
        allowNull: true
      },
      completedDoses: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0
      },
      totalDoses: {
        type: Sequelize.INTEGER,
        allowNull: true
      },
      notes: {
        type: Sequelize.TEXT,
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
      vaccineId: {
        type: Sequelize.INTEGER,
        references: {
          model: 'Vaccines',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      brandTakenId: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'Vaccines',
          key: 'id'
        },
        onDelete: 'SET NULL'
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
    await queryInterface.dropTable('UserVaccines');
  }
};
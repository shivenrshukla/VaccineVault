'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('NotificationLogs', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      userId: {
        type: Sequelize.INTEGER,
        allowNull: false,
        // Typically this is a Foreign Key, but your model didn't strictly define it.
        // Adding FK here is safer for data integrity.
        references: {
          model: 'Users',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      vaccineId: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'Vaccines',
          key: 'id'
        },
        onDelete: 'CASCADE'
      },
      channel: {
        type: Sequelize.ENUM('email', 'push'),
        allowNull: false
      },
      status: {
        type: Sequelize.ENUM('pending', 'sent', 'failed'),
        defaultValue: 'pending'
      },
      retryCount: {
        type: Sequelize.INTEGER,
        defaultValue: 0
      },
      lastAttemptAt: {
        type: Sequelize.DATE
      },
      errorMessage: {
        type: Sequelize.TEXT
      },
      reminderDate: {
        type: Sequelize.DATEONLY,
        allowNull: false
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

    // Add Index
    await queryInterface.addIndex('NotificationLogs', {
      fields: ['userId', 'vaccineId', 'channel', 'reminderDate'],
      unique: true,
      name: 'unique_notification_log'
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('NotificationLogs');
  }
};
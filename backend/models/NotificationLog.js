import { DataTypes } from 'sequelize';
import sequelize from '../config/db.js';

const NotificationLog = sequelize.define('NotificationLog', {
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  vaccineId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  channel: {
    type: DataTypes.ENUM('email', 'push'),
    allowNull: false
  },
  status: {
    type: DataTypes.ENUM('pending', 'sent', 'failed'),
    defaultValue: 'pending'
  },
  retryCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  lastAttemptAt: {
    type: DataTypes.DATE
  },
  errorMessage: {
    type: DataTypes.TEXT
  },
  reminderDate: {
    type: DataTypes.DATEONLY,
    allowNull: false
  }
}, {
  indexes: [
    {
      unique: true,
      fields: ['userId', 'vaccineId', 'channel', 'reminderDate']
    }
  ]
});

export default NotificationLog;

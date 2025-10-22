import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const User = sequelize.define('User', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    username: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: false
    },
    password: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    email: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
            isEmail: true
        }
    },
    gender: {
        type: DataTypes.STRING,
        allowNull: false
    },
    role: {
        type: DataTypes.ENUM('admin', 'user'),
        defaultValue: 'user'
    },
    dateOfBirth: {
        type: DataTypes.DATEONLY,
        allowNull: false
    },
    addressPart1: {
        type: DataTypes.STRING,
        allowNull: false
    },
    addressPart2: {
        type: DataTypes.STRING,
        allowNull: true
    },
    city: {
        type: DataTypes.STRING,
        allowNull: false
    },
    state: {
        type: DataTypes.STRING,
        allowNull: false
    },
    pinCode: {
        type: DataTypes.STRING,
        allowNull: false,
        validate: {
            is: /^[0-9]{6}$/
        }
    },
    phoneNumber: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
            is: /^[0-9]{10}$/
        }
    },
    pushNotificationToken: {
        type: DataTypes.STRING,
        allowNull: true
    },
    // --- New Field for Medical Conditions ---
    medicalConditions: {
        type: DataTypes.JSON,
        allowNull: true, // Can be null if user has no conditions
        defaultValue: [] // Default empty array
    }
}, {
    timestamps: true
});

export default User;

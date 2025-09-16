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
        unique: true
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
            is: /^[0-9]{6}$/ // Validates a 6-digit pin code
        }
    },
    phoneNumber: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
        validate: {
            is: /^[0-9]{10}$/ // Validates a 10-digit phone number
        }
    }
}, {
    timestamps: true
});

export default User;
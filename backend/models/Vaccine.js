// models/Vaccine.js
import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const Vaccine = sequelize.define('Vaccine', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    name: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true
    },
    diseaseProtectedAgainst: {
        type: DataTypes.STRING,
        allowNull: false
    },
    // --- THESE ARE THE NEW, REQUIRED FIELDS ---
    minAgeMonths: {
        type: DataTypes.INTEGER,
        allowNull: false
    },
    maxAgeMonths: {
        type: DataTypes.INTEGER,
        allowNull: true
    },
    schedule: {
        type: DataTypes.JSON,
        allowNull: false
    },
    boosterIntervalYears: {
        type: DataTypes.INTEGER,
        allowNull: true
    },
    isUIP: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false
    }
}, {
    timestamps: false // It's better to disable timestamps for a static data table
});

export default Vaccine;
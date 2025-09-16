import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";
import User from "./User.js";

const VaccinationRecord = sequelize.define('VaccinationRecord', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    vaccineName: {
        type: DataTypes.STRING,
        allowNull: false
    },
    doseNumber: {
        type: DataTypes.INTEGER,
        allowNull: false
    },
    vaccinationDate: {
        type: DataTypes.DATEONLY,
        allowNull: false
    },
    healthcareProvider: {
        type: DataTypes.STRING,
        allowNull: false
    },
    location: {
        type: DataTypes.STRING,
        allowNull: false
    }
}, {
    timestamps: true
});

// Define associations
User.hasMany(VaccinationRecord, { foreignKey: 'userId', onDelete: 'CASCADE' });
VaccinationRecord.belongsTo(User, { foreignKey: 'userId' });

// Sync models with the database
(async () => {
    await sequelize.sync({ alter: true });
})();

export default VaccinationRecord;
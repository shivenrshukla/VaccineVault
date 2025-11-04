import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";
import User from "./User.js";
import Vaccine from "./Vaccine.js";
import VaccineCertificate from "./VaccineCertificate.js";

const UserVaccine = sequelize.define('UserVaccine', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    status: { type: DataTypes.ENUM('pending', 'completed'), allowNull: false, defaultValue: 'pending' },
    nextDueDate: { type: DataTypes.DATEONLY, allowNull: true },
    lastDoseDate: { type: DataTypes.DATEONLY, allowNull: true },
    completedDoses: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    
    // ✅ --- NEW FIELDS ---
    totalDoses: {
        type: DataTypes.INTEGER,
        allowNull: true,
        comment: 'The total doses for the *brand* the user took.'
    },
    brandTakenId: {
        type: DataTypes.INTEGER,
        allowNull: true,
        references: {
            model: 'Vaccines', // This must be the table name
            key: 'id'
        },
        comment: 'FK to the Vaccine (brand) that was administered.'
    }
    // ✅ --- END NEW FIELDS ---
}, {
    timestamps: true
});

User.hasMany(UserVaccine, { foreignKey: 'userId' });
UserVaccine.belongsTo(User, { foreignKey: 'userId' });

// This is the "disease" (generic vaccine)
Vaccine.hasMany(UserVaccine, { foreignKey: 'vaccineId' });
UserVaccine.belongsTo(Vaccine, { foreignKey: 'vaccineId' });

// ✅ --- NEW ASSOCIATION ---
// This is the specific "brand" that was taken
UserVaccine.belongsTo(Vaccine, { as: 'BrandTaken', foreignKey: 'brandTakenId' });
// ✅ --- END NEW ASSOCIATION ---

UserVaccine.hasMany(VaccineCertificate, { foreignKey: 'userVaccineId' });
VaccineCertificate.belongsTo(UserVaccine, { foreignKey: 'userVaccineId' });
export default UserVaccine;
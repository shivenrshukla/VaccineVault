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
    completedDoses: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 }
}, {
    timestamps: true
});

User.hasMany(UserVaccine, { foreignKey: 'userId' });
UserVaccine.belongsTo(User, { foreignKey: 'userId' });

Vaccine.hasMany(UserVaccine, { foreignKey: 'vaccineId' });
UserVaccine.belongsTo(Vaccine, { foreignKey: 'vaccineId' });

UserVaccine.hasMany(VaccineCertificate, { foreignKey: 'userVaccineId' });
VaccineCertificate.belongsTo(UserVaccine, { foreignKey: 'userVaccineId' });
export default UserVaccine;
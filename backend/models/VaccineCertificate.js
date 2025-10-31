// models/VaccineCertificate.js
import { DataTypes } from "sequelize";
import sequelize from "../config/db.js";

const VaccineCertificate = sequelize.define('VaccineCertificate', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    // The unique name we generate, e.g., "d9ad67f51c39446f8a0716781f2112c4.pdf"
    certificateFilename: {
        type: DataTypes.STRING,
        allowNull: false,
        comment: 'The unique, secured filename stored on the server.'
    },
    // The original name, e.g., "my_pfizer_card.pdf"
    originalFileName: {
        type: DataTypes.STRING,
        allowNull: true,
        comment: 'The original filename as uploaded by the user.'
    },
    // The file type, e.g., "application/pdf"
    fileMimeType: {
        type: DataTypes.STRING,
        allowNull: true
    },
    // We will get userId and userVaccineId from the associations in Part 2
}, {
    timestamps: true // Automatically adds createdAt and updatedAt
});

export default VaccineCertificate;
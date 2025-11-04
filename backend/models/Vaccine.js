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
        comment: 'The common name of the vaccine (e.g., Rotavirus Vaccine)'
    },
    brandName: {
        type: DataTypes.STRING,
        allowNull: true,
        comment: 'Brand name, if applicable (e.g., Covishield, Rotarix)'
    },
    diseaseProtectedAgainst: {
        type: DataTypes.STRING,
        allowNull: false
    },
    ageOfFirstDoseMonths: {
        type: DataTypes.INTEGER,
        allowNull: false,
        comment: 'Recommended age in months for the very first dose (e.g., 6 for Flu).'
    },
    numberOfDoses: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 1,
        comment: 'Total number of doses in the primary series (e.g., 3 for Hep B, 1 for Flu).'
    },
    doseIntervalsDays: {
        type: DataTypes.JSON,
        allowNull: true,
        comment: 'Array of days *between* doses. [0] is gap b/w Dose 1 & 2.'
    },
    isRecurringBooster: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false,
        comment: 'True if this vaccine requires boosters forever (e.g., Flu).'
    },
    boosterIntervalYears: {
        type: DataTypes.INTEGER,
        allowNull: true,
        comment: 'The number of years between boosters (e.g., 1 for Flu).'
    },
    isUIP: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false
    },
    isTravelVaccine:{
        type: DataTypes.BOOLEAN,
        allowNull:false,
        defaultValue:false,
        comment: "True if this vaccine is recommended for travel (e.g., Yellow Fever, Typhoid)"
    },
    travelRegions: {
        type: DataTypes.ARRAY(DataTypes.STRING),
        allowNull: true,
        comment: "Regions or countries where this vaccine is recommended (e.g., ['Africa', 'South America'])"
    },
    mandatoryFor: {
        type: DataTypes.ARRAY(DataTypes.STRING),
        allowNull: true,
        comment: "Countries/events where this vaccine is mandatory (e.g., ['Hajj (Saudi Arabia)'])"
    },
    travelNotes: {
        type: DataTypes.TEXT,
        allowNull: true,
        comment: "Additional information or certification requirements for travelers"
    }
    
}, {
    timestamps: false,
    indexes: [
        {
            unique: true,
            fields: ['name', 'brandName']
        }
    ]
});

export default Vaccine;
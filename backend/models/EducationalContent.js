import { DataTypes } from "sequelize";
import sequelize from "../config/database.js";
import User from "./User.js";

const EducationalContent = sequelize.define('EducationalContent', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    title: {
        type: DataTypes.STRING,
        allowNull: false
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: false
    },
    contentType: {
        type: DataTypes.ENUM('article', 'video', 'pdf'),
        allowNull: false
    },
    url: {
        type: DataTypes.STRING,        // for video/pdf links
        allowNull: true,
        validate: { 
            isUrl: true
        }
    },
    createdAt: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW
    },
    updatedAt: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW
    },
    adminId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: 'Users',
            key: 'id'
        },
        onDelete: 'CASCADE',
        onUpdate: 'CASCADE'
    }
}, {
    timeStamps: true
});

// Associations
User.hasMany(EducationalContent, { foreignKey: 'adminId', as: 'educationalContents' });
EducationalContent.belongsTo(User, { foreignKey: 'adminId', as: 'admin' });

export default EducationalContent;
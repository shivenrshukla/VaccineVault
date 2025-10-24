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
    medicalConditions: {
        type: DataTypes.JSON,
        allowNull: true,
        defaultValue: []
    },
    // NEW FIELD FOR FAMILY SUPPORT
    familyAdminId: {
        type: DataTypes.INTEGER,
        allowNull: true,
        references: {
            model: 'Users',
            key: 'id'
        },
        comment: 'If set, this user is a family member managed by the admin with this ID'
    },
    // Optional: Track relationship to admin
    relationshipToAdmin: {
        type: DataTypes.STRING,
        allowNull: true,
        comment: 'e.g., "spouse", "child", "parent", "sibling"'
    }
}, {
    timestamps: true
});

// Self-referencing association
User.hasMany(User, { as: 'FamilyMembers', foreignKey: 'familyAdminId' });
User.belongsTo(User, { as: 'FamilyAdmin', foreignKey: 'familyAdminId' });

export default User;
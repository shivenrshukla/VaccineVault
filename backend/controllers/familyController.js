import User from "../models/User.js";
import UserVaccine from "../models/userVaccine.js";
import Vaccine from "../models/Vaccine.js";
import { Op } from "sequelize";

// Add a family member
export const addFamilyMember = async (req, res) => {
    try {
        const adminId = req.user.id;
        const {
            username,
            email,
            gender,
            dateOfBirth,
            phoneNumber,
            relationshipToAdmin,
            medicalConditions
        } = req.body;

        // Validation
        if (!username || !email || !gender || !dateOfBirth || !phoneNumber) {
            return res.status(400).json({ message: "All required fields must be filled" });
        }

        // Validate phone number format
        if (!/^[0-9]{10}$/.test(phoneNumber)) {
            return res.status(400).json({ message: "Phone number must be 10 digits" });
        }

        // Check if email already exists
        const existingUser = await User.findOne({ where: { email } });
        if (existingUser) {
            return res.status(400).json({ message: "Email already in use" });
        }

        // Check if phone number already exists
        const existingPhone = await User.findOne({ where: { phoneNumber } });
        if (existingPhone) {
            return res.status(400).json({ message: "Phone number already in use" });
        }

        // Get admin's address info to use for family member
        const admin = await User.findByPk(adminId);
        if (!admin) {
            return res.status(404).json({ message: "Admin not found" });
        }

        // Generate a default password
        const defaultPassword = `Family@${Math.random().toString(36).slice(-8)}`;

        // Create family member
        const familyMember = await User.create({
            username,
            password: defaultPassword,
            email,
            gender,
            dateOfBirth,
            phoneNumber,
            addressPart1: admin.addressPart1,
            addressPart2: admin.addressPart2,
            city: admin.city,
            state: admin.state,
            pinCode: admin.pinCode,
            familyAdminId: adminId,
            relationshipToAdmin: relationshipToAdmin || null,
            role: 'user',
            medicalConditions: medicalConditions || null
        });

        // Return without password
        const memberData = await User.findByPk(familyMember.id, {
            attributes: { exclude: ['password'] }
        });

        res.status(201).json({
            message: "Family member added successfully",
            familyMember: memberData,
            temporaryPassword: defaultPassword // Send this once so they can login
        });
    } catch (error) {
        console.error("Error adding family member:", error);
        res.status(500).json({ message: "Internal server error", error: error.message });
    }
};

// Get all family members (for admin)
export const getFamilyMembers = async (req, res) => {
  try {
    console.log("Admin ID:", req.user.id);
    const adminId = req.user.id;

    const familyMembers = await User.findAll({
      where: {
        [Op.or]: [
          { id: adminId },               // ✅ Include the admin themselves
          { familyAdminId: adminId }     // ✅ Include their family members
        ]
      },
      attributes: { exclude: ["password"] },
      order: [["createdAt", "ASC"]]
    });

    res.status(200).json({
      count: familyMembers.length,
      familyMembers
    });
  } catch (error) {
    console.error("Error fetching family members:", error);
    res.status(500).json({ message: "Internal server error", error: error.message });
  }
};

// Get vaccine records for a specific family member
export const getFamilyMemberVaccines = async (req, res) => {
    try {
        const adminId = req.user.id;
        const { memberId } = req.params;

        // Verify the member belongs to this admin
        const member = await User.findOne({
            where: {
                id: memberId,
                familyAdminId: adminId
            },
            attributes: { exclude: ['password'] }
        });

        if (!member) {
            return res.status(404).json({ 
                message: "Family member not found or you don't have access" 
            });
        }

        // Get vaccine records for this member
        const vaccines = await UserVaccine.findAll({
            where: { userId: memberId },
            include: [{ model: Vaccine }],
            order: [['status', 'ASC'], ['nextDueDate', 'ASC']]
        });

        res.status(200).json({
            member: {
                id: member.id,
                username: member.username,
                email: member.email,
                gender: member.gender,
                dateOfBirth: member.dateOfBirth,
                relationshipToAdmin: member.relationshipToAdmin
            },
            vaccines
        });
    } catch (error) {
        console.error("Error fetching family member vaccines:", error);
        res.status(500).json({ message: "Internal server error", error: error.message });
    }
};

// Get all family overview (admin + all members with their vaccine counts)
export const getFamilyOverview = async (req, res) => {
    try {
        const adminId = req.user.id;

        // Get admin info
        const admin = await User.findByPk(adminId, {
            attributes: { exclude: ['password'] }
        });

        if (!admin) {
            return res.status(404).json({ message: "User not found" });
        }

        // Get all family members
        const familyMembers = await User.findAll({
            where: { familyAdminId: adminId },
            attributes: { exclude: ['password'] }
        });

        // Get vaccine stats for each person
        const allMembers = [admin, ...familyMembers];
        const overview = await Promise.all(
            allMembers.map(async (member) => {
                const totalVaccines = await UserVaccine.count({
                    where: { userId: member.id }
                });
                const pendingVaccines = await UserVaccine.count({
                    where: { userId: member.id, status: 'pending' }
                });
                const completedVaccines = await UserVaccine.count({
                    where: { userId: member.id, status: 'completed' }
                });

                // Get next upcoming vaccine
                const nextVaccine = await UserVaccine.findOne({
                    where: { 
                        userId: member.id, 
                        status: 'pending',
                        nextDueDate: { [Op.ne]: null }
                    },
                    include: [{ model: Vaccine }],
                    order: [['nextDueDate', 'ASC']]
                });

                return {
                    id: member.id,
                    username: member.username,
                    email: member.email,
                    gender: member.gender,
                    dateOfBirth: member.dateOfBirth,
                    relationshipToAdmin: member.familyAdminId ? member.relationshipToAdmin : 'self',
                    isAdmin: member.id === adminId,
                    vaccineStats: {
                        total: totalVaccines,
                        pending: pendingVaccines,
                        completed: completedVaccines
                    },
                    nextVaccine: nextVaccine ? {
                        name: nextVaccine.Vaccine.name,
                        dueDate: nextVaccine.nextDueDate
                    } : null
                };
            })
        );

        res.status(200).json({
            totalMembers: overview.length,
            overview
        });
    } catch (error) {
        console.error("Error fetching family overview:", error);
        res.status(500).json({ message: "Internal server error", error: error.message });
    }
};

// Update family member details
export const updateFamilyMember = async (req, res) => {
    try {
        const adminId = req.user.id;
        const { memberId } = req.params;
        const {
            username,
            email,
            gender,
            dateOfBirth,
            phoneNumber,
            relationshipToAdmin,
            addressPart1,
            addressPart2,
            city,
            state,
            pinCode
        } = req.body;

        // Find and verify member belongs to admin
        const member = await User.findOne({
            where: {
                id: memberId,
                familyAdminId: adminId
            }
        });

        if (!member) {
            return res.status(404).json({ 
                message: "Family member not found or you don't have access" 
            });
        }

        // Check if email is being changed and if it already exists
        if (email && email !== member.email) {
            const existingUser = await User.findOne({ where: { email } });
            if (existingUser) {
                return res.status(400).json({ message: "Email already in use" });
            }
        }

        // Check if phone number is being changed and if it already exists
        if (phoneNumber && phoneNumber !== member.phoneNumber) {
            if (!/^[0-9]{10}$/.test(phoneNumber)) {
                return res.status(400).json({ message: "Phone number must be 10 digits" });
            }
            const existingPhone = await User.findOne({ where: { phoneNumber } });
            if (existingPhone) {
                return res.status(400).json({ message: "Phone number already in use" });
            }
        }

        // Validate pinCode if provided
        if (pinCode && !/^[0-9]{6}$/.test(pinCode)) {
            return res.status(400).json({ message: "Pincode must be 6 digits" });
        }

        // Build update object
        const updateData = {};
        if (username) updateData.username = username;
        if (email) updateData.email = email;
        if (gender) updateData.gender = gender;
        if (dateOfBirth) updateData.dateOfBirth = dateOfBirth;
        if (phoneNumber) updateData.phoneNumber = phoneNumber;
        if (relationshipToAdmin !== undefined) updateData.relationshipToAdmin = relationshipToAdmin;
        if (addressPart1) updateData.addressPart1 = addressPart1;
        if (addressPart2 !== undefined) updateData.addressPart2 = addressPart2;
        if (city) updateData.city = city;
        if (state) updateData.state = state;
        if (pinCode) updateData.pinCode = pinCode;

        await member.update(updateData);

        const updatedMember = await User.findByPk(memberId, {
            attributes: { exclude: ['password'] }
        });

        res.status(200).json({
            message: "Family member updated successfully",
            familyMember: updatedMember
        });
    } catch (error) {
        console.error("Error updating family member:", error);
        res.status(500).json({ message: "Internal server error", error: error.message });
    }
};

// Remove family member
export const removeFamilyMember = async (req, res) => {
    try {
        const adminId = req.user.id;
        const { memberId } = req.params;

        // Find and verify member belongs to admin
        const member = await User.findOne({
            where: {
                id: memberId,
                familyAdminId: adminId
            }
        });

        if (!member) {
            return res.status(404).json({ 
                message: "Family member not found or you don't have access" 
            });
        }

        // Delete associated vaccine records first
        const deletedVaccines = await UserVaccine.destroy({ where: { userId: memberId } });

        // Delete the member
        await member.destroy();

        res.status(200).json({
            message: "Family member removed successfully",
            deletedVaccineRecords: deletedVaccines
        });
    } catch (error) {
        console.error("Error removing family member:", error);
        res.status(500).json({ message: "Internal server error", error: error.message });
    }
};
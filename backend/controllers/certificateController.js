// controllers/certificateController.js
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { Op } from "sequelize"; // ✅ ADDED

// Your Sequelize Models
import User from '../models/User.js';
import UserVaccine from '../models/UserVaccine.js';
import VaccineCertificate from '../models/VaccineCertificate.js';
import Vaccine from '../models/Vaccine.js'; // ✅ ADDED

// --- ES Module setup for __dirname ---
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// --- Setup storage paths ---
const uploadDir = path.join(__dirname, '..', 'uploads', 'certificates');

// Ensure the upload directory exists
fs.mkdirSync(uploadDir, { recursive: true });


/**
 * @desc    Upload a new vaccine certificate
 * @route   POST /api/certificates/upload
 * @access  Private (Requires JWT)
 */
export const uploadCertificate = async (req, res) => {
    try {
        const { userVaccineId } = req.body;
        const requesterId = req.user.id; // From authMiddleware

        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded.' });
        }

        // ✅ Find UserVaccine AND its related models
        const userVaccine = await UserVaccine.findByPk(userVaccineId, {
            include: [
                { model: Vaccine, attributes: ['name'] },
                { model: User, attributes: ['username', 'id', 'familyAdminId'] }
            ]
        });
        
        if (!userVaccine) {
             return res.status(404).json({ message: 'Vaccine record not found.' });
        }
        
        // Security check
        const fileOwner = userVaccine.User;
        if (fileOwner.id !== requesterId && fileOwner.familyAdminId !== requesterId) {
            return res.status(403).json({ message: 'You are not authorized to update this vaccine record.' });
        }

        // 3. Create the database record
        const newCertificate = await VaccineCertificate.create({
            certificateFilename: req.file.filename,
            originalFileName: req.file.originalname,
            fileMimeType: req.file.mimetype,
            userId: userVaccine.userId, // The user who *owns* the vaccine record
            userVaccineId: userVaccineId // The record it's for
        });

        // ✅ Format the response to be rich with data
        const formattedCertificate = {
            id: newCertificate.id,
            originalFileName: newCertificate.originalFileName,
            createdAt: newCertificate.createdAt,
            userVaccineId: newCertificate.userVaccineId,
            vaccineName: userVaccine.Vaccine?.name || 'Unknown Vaccine',
            userName: userVaccine.User?.username || 'Unknown User',
            isForFamilyMember: userVaccine.User?.id !== requesterId
        };

        res.status(201).json({
            message: 'Certificate uploaded successfully.',
            certificate: formattedCertificate // ✅ Send the formatted object
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error during upload.' });
    }
};


/**
 * @desc    Securely download a certificate by its database ID
 * @route   GET /api/certificates/download/:id
 * @access  Private (Requires JWT)
 */
export const downloadCertificate = async (req, res) => {
    try {
        const certificateId = req.params.id;
        const requesterId = req.user.id; // The person asking for the file

        const certificate = await VaccineCertificate.findByPk(certificateId);

        if (!certificate) {
            return res.status(404).json({ message: 'File not found.' });
        }
        
        const fileOwnerId = certificate.userId;
        let isAllowed = false;

        if (requesterId === fileOwnerId) {
            isAllowed = true;
        } else {
            const fileOwner = await User.findByPk(fileOwnerId);
            if (fileOwner && fileOwner.familyAdminId === requesterId) {
                isAllowed = true;
            }
        }

        if (!isAllowed) {
            return res.status(403).json({ message: 'Access forbidden.' });
        }

        const filePath = path.join(uploadDir, certificate.certificateFilename);

        if (fs.existsSync(filePath)) {
            res.sendFile(filePath, (err) => {
                if (err) {
                    console.error('Error sending file:', err);
                }
            });
            
        } else {
            console.error(`File not found on disk: ${certificate.certificateFilename}`);
            return res.status(404).json({ message: 'File not found on server.' });
        }

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error.' });
    }
};


/**
 * @desc    Get all certificates for a user and their family members
 * @route   GET /api/certificates/all
 * @access  Private (Requires JWT)
 */
export const getAllCertificatesForUser = async (req, res) => {
    try {
        const requesterId = req.user.id;

        // 1. Find all user IDs this requester manages (including themselves)
        const familyMemberIds = await User.findAll({
            where: {
                familyAdminId: requesterId
            },
            attributes: ['id']
        });

        const allowedUserIds = [
            requesterId,
            ...familyMemberIds.map(user => user.id)
        ];

        // 2. Find all certificates belonging to these users
        const certificates = await VaccineCertificate.findAll({
            where: {
                userId: { [Op.in]: allowedUserIds }
            },
            attributes: [
                'id',
                'originalFileName',
                'createdAt',
                'userVaccineId'
            ],
            include: [
                {
                    model: UserVaccine,
                    attributes: ['id', 'userId'], // Need userId for the check
                    include: [
                        {
                            model: Vaccine,
                            attributes: ['name']
                        },
                        {
                            model: User,
                            attributes: ['username', 'id']
                        }
                    ]
                }
            ],
            order: [['createdAt', 'DESC']] // Show newest first
        });
        
        // 3. Re-format the data to be more flat/useful for the frontend
        const formattedCertificates = certificates.map(cert => ({
             id: cert.id,
             originalFileName: cert.originalFileName,
             createdAt: cert.createdAt,
             userVaccineId: cert.userVaccineId,
             vaccineName: cert.UserVaccine?.Vaccine?.name || 'Unknown Vaccine',
             userName: cert.UserVaccine?.User?.username || 'Unknown User',
             isForFamilyMember: cert.UserVaccine?.User?.id !== requesterId
        }));

        res.status(200).json(formattedCertificates); // Send the array directly

    } catch (error) {
        console.error("Error fetching all certificates:", error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
};
import jwt from 'jsonwebtoken';
import User from '../models/User.js';

// Generate JWT Token
export const generateToken = (user) => {
    return jwt.sign(
        { id: user.id, username: user.username, email: user.email, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: '1h' }
    );
}

// Register a new user
export const register = async (req, res) => {
    try {
        const {
            username,
            password,
            email,
            gender,
            dateOfBirth,
            addressPart1,
            addressPart2,
            city,
            state,
            pinCode,
            phoneNumber,
            role,
            pushNotificationToken,
            familyAdminId,
            relationshipToAdmin, 
            medicalConditions
        } = req.body;

        console.log(username, email, familyAdminId, relationshipToAdmin);

        // Basic validation
        if (!username || !password || !email || !gender || !dateOfBirth || !addressPart1 || !city || !state || !pinCode || !phoneNumber) {
            return res.status(400).json({ message: "All required fields must be filled" });
        }

        // Check if email already exists
        const existingUserByEmail = await User.findOne({ where: { email } });
        if (existingUserByEmail) {
            return res.status(400).json({ message: "An account with this email already exists" });
        }

        // Check if username already exists
        const existingUserByUsername = await User.findOne({ where: { username } });
        if (existingUserByUsername) {
            return res.status(400).json({ message: "Username is already taken" });
        }

        // ✅ Create new user (now includes family fields)
        const newUser = await User.create({
            username,
            password,
            email,
            gender,
            dateOfBirth,
            addressPart1,
            addressPart2,
            city,
            state,
            pinCode,
            phoneNumber,
            role: role || 'user',
            pushNotificationToken,
            familyAdminId,
            relationshipToAdmin,
            medicalConditions: medicalConditions || null
        });

        const token = generateToken(newUser);
        res.status(201).json({
            message: "User registered successfully",
            token,
            userId: newUser.id,
            familyAdminId: newUser.familyAdminId
        });
    } catch (error) {
        console.error("Error during registration:", error);
        res.status(500).json({ message: "Internal server error", error: error.message });
    }
};

// Login an existing user using EMAIL
export const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Basic validation
        if (!email || !password) {
            return res.status(400).json({ message: "Email and password are required" });
        }

        // Find user by email
        const user = await User.findOne({ where: { email } });
        if (!user || user.password !== password) {
            return res.status(401).json({ message: "Invalid credentials" });
        }

        const token = generateToken(user);
        res.status(200).json({ 
            token,
            userId: user.id,
        });
    } catch (error) {
        console.error("Error during login:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};

// Get user profile (protected route)
export const getProfile = async (req, res) => {
    try {
        const user = await User.findByPk(req.user.id, {
            attributes: { exclude: ['password'] }
        });
        
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }
        
        res.status(200).json(user);
    } catch (error) {
        console.error("Error fetching profile:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};

export const updateProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const {
            username,
            email,
            gender,
            dateOfBirth,
            addressPart1,
            addressPart2,
            city,
            state,
            pinCode,
            phoneNumber
        } = req.body;

        // Find the user
        const user = await User.findByPk(userId);
        
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Check if email is being changed and if it already exists
        if (email && email !== user.email) {
            const existingUser = await User.findOne({ where: { email } });
            if (existingUser) {
                return res.status(400).json({ 
                    message: "Email already in use by another account" 
                });
            }
        }

        // Check if username is being changed and if it already exists
        if (username && username !== user.username) {
            const existingUsername = await User.findOne({ where: { username } });
            if (existingUsername) {
                return res.status(400).json({ 
                    message: "Username already taken" 
                });
            }
        }

        // Validate pinCode format if provided
        if (pinCode && !/^[0-9]{6}$/.test(pinCode)) {
            return res.status(400).json({ 
                message: "Invalid pincode format. Must be 6 digits" 
            });
        }

        // Validate phoneNumber format if provided
        if (phoneNumber && !/^[0-9]{10}$/.test(phoneNumber)) {
            return res.status(400).json({ 
                message: "Invalid phone number format. Must be 10 digits" 
            });
        }

        // Update user fields (only update fields that are provided)
        const updatedData = {};
        if (username) updatedData.username = username;
        if (email) updatedData.email = email;
        if (gender) updatedData.gender = gender;
        if (dateOfBirth) updatedData.dateOfBirth = dateOfBirth;
        if (addressPart1) updatedData.addressPart1 = addressPart1;
        if (addressPart2 !== undefined) updatedData.addressPart2 = addressPart2; // Allow empty string
        if (city) updatedData.city = city;
        if (state) updatedData.state = state;
        if (pinCode) updatedData.pinCode = pinCode;
        if (phoneNumber) updatedData.phoneNumber = phoneNumber;

        // Perform the update
        await user.update(updatedData);

        // Fetch updated user without password
        const updatedUser = await User.findByPk(userId, {
            attributes: { exclude: ['password'] }
        });

        res.status(200).json({
            message: "Profile updated successfully",
            user: updatedUser
        });

    } catch (error) {
        console.error("Error updating profile:", error);
        
        // Handle Sequelize validation errors
        if (error.name === 'SequelizeValidationError') {
            return res.status(400).json({ 
                message: "Validation error", 
                errors: error.errors.map(e => e.message) 
            });
        }
        
        res.status(500).json({ message: "Internal server error" });
    }
};

// --- NEW FUNCTION ---
// Change user password (protected route)
export const changePassword = async (req, res) => {
    try {
        const userId = req.user.id;
        const { currentPassword, newPassword } = req.body;

        // Basic validation
        if (!currentPassword || !newPassword) {
            return res.status(400).json({ message: "Both current and new passwords are required" });
        }

        if (newPassword.length < 6) {
             return res.status(400).json({ message: "New password must be at least 6 characters long" });
        }

        // Find the user (and select password, which is normally excluded)
        const user = await User.findByPk(userId);
        
        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Check if the current password is correct
        // Note: This assumes plaintext passwords. 
        // In a real app, you would use bcrypt.compare() here.
        if (user.password !== currentPassword) {
            return res.status(401).json({ message: "Incorrect current password" });
        }

        // Update the password
        await user.update({ password: newPassword });

        res.status(200).json({ message: "Password updated successfully" });

    } catch (error) {
        console.error("Error changing password:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};
// --- END OF NEW FUNCTION ---

export const logout = (req, res) => {
    try {
        res.status(200).json({ message: "Logged out successfully" });
    } catch (error) {
        console.error("Error during logout:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};
import jwt from 'jsonwebtoken';
import User from '../models/User.js';

// Generate JWT Token
export const generateToken = (user) => {
    // UPDATED: Include email in the token payload for consistency
    return jwt.sign(
        { id: user.id, username: user.username, email: user.email, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: '1h' }
    );
}

// Register a new user
export const register = async (req, res) => {
    try {
        const { username, password, email, dateOfBirth, addressPart1, addressPart2, city, state, pinCode, phoneNumber } = req.body;

        // Basic validation
        if (!username || !password || !email || !dateOfBirth || !addressPart1 || !city || !state || !pinCode || !phoneNumber) {
            return res.status(400).json({ message: "All required fields must be filled" });
        }

        // UPDATED: Check if email already exists
        const existingUserByEmail = await User.findOne({ where: { email } });
        if (existingUserByEmail) {
            return res.status(400).json({ message: "An account with this email already exists" });
        }

        // Check if username already exists
        const existingUserByUsername = await User.findOne({ where: { username } });
        if (existingUserByUsername) {
            return res.status(400).json({ message: "Username is already taken" });
        }

        // Create new user
        const newUser = await User.create({
            username,
            password, // In a real app, make sure to hash the password before storing
            email,
            dateOfBirth,
            addressPart1,
            addressPart2,
            city,
            state,
            pinCode,
            phoneNumber,
            role: 'user' // Default role
        });

        const token = generateToken(newUser);
        res.status(201).json({ token });
    } catch (error) {
        console.error("Error during registration:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};

// --- UPDATED: Login an existing user using EMAIL ---
export const login = async (req, res) => {
    try {
        // Now expecting 'email' instead of 'username'
        const { email, password } = req.body;

        // Basic validation
        if (!email || !password) {
            return res.status(400).json({ message: "Email and password are required" });
        }

        // Find user by email
        const user = await User.findOne({ where: { email } });
        if (!user || user.password !== password) { // In a real app, use hashed password comparison
            return res.status(401).json({ message: "Invalid credentials" });
        }

        const token = generateToken(user);
        res.status(200).json({ token });
    } catch (error) {
        console.error("Error during login:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};

// Example of a protected route
export const getProfile = async (req, res) => {
    try {
        const user = await User.findByPk(req.user.id, {
            attributes: { exclude: ['password'] } // Exclude password from the response
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

export const logout = (req, res) => {
    try {
        res.status(200).json({ message: "Logged out successfully" });
    } catch (error) {
        console.error("Error during logout:", error);
        res.status(500).json({ message: "Internal server error" });
    }
};
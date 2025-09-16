import jwt from 'jsonwebtoken';
import User from '../models/User.js';

// Generate JWT Token
export const generateToken = (user) => {
    return jwt.sign(
        { id: user.id, username: user.username, role: user.role },
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

        // Check if user already exists
        const existingUser = await User.findOne({ where: { username } });
        if (existingUser) {
            return res.status(400).json({ message: "Username already taken" });
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

// Login an existing user
export const login = async (req, res) => {
    try {
        const { username, password } = req.body;

        // Basic validation
        if (!username || !password) {
            return res.status(400).json({ message: "Username and password are required" });
        }

        // Find user
        const user = await User.findOne({ where: { username } });
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
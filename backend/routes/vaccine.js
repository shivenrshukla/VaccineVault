// routes/auth.js

const express = require('express');
const router = express.Router(); // Create a new router instance

// --- Define your routes here ---
// Example: POST /api/auth/login
router.post('/login', (req, res) => {
    // Your login logic here...
    res.status(200).json({ message: "Login successful" });
});

// Example: POST /api/auth/register
router.post('/register', (req, res) => {
    // Your registration logic here...
    res.status(201).json({ message: "User registered" });
});


// --- This is the most important line ---
// Make sure to export the router
module.exports = router;
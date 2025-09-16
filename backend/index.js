import dotenv from 'dotenv';
import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import authRoutes from './routes/auth.js';
import educationContentRoutes from './routes/educationalContent.js';
import vaccineRoutes from './routes/vaccine.js';
import sequelize from './config/db.js';

const app = express();
dotenv.config();

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/educational-content', educationContentRoutes);
app.use('/api/vaccines', vaccineRoutes);

const PORT = process.env.PORT || 5000;

// Connect to the database and start the server
const startServer = async () => {
    try {
        await sequelize.authenticate();
        console.log("Database connected successfully.");

        await sequelize.sync();
        console.log("Database synchronized.");

        app.listen(PORT, () => {
            console.log(`Server is running on port ${PORT}`);
        });
    } catch (error) {
        console.error("Unable to connect to the database:", error);
        process.exit(1);
    }
};

startServer();
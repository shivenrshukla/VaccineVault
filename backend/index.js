import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import authRoutes from './routes/auth.js';
import educationContentRoutes from './routes/educationalContent.js';
import vaccineRoutes from './routes/vaccine.js';
import sequelize from './config/db.js'; // Import sequelize instance
import testRoutes from './routes/testRoutes.js';

import {startReminderService} from './services/reminderService.js'
const app = express();

// --- ADD THIS DATABASE CONNECTION TEST ---
const testDbConnection = async () => {
    try {
        await sequelize.authenticate();
        console.log('✅ Connection to the database has been established successfully.');
    } catch (error) {
        console.error('❌ Unable to connect to the database:', error);
    }
};
testDbConnection();

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/educational-content', educationContentRoutes);
app.use('/api/vaccines', vaccineRoutes);
app.use('/api/test',testRoutes);

const PORT = process.env.PORT || 5000;
startReminderService();
// await sequelize.sync({ force: true });

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

// how to start db : psql -d vaccinevault


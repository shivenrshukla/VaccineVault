import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';

// Importing route handlers
import authRoutes from './routes/auth.js';
import educationContentRoutes from './routes/educationalContent.js';
import vaccineRoutes from './routes/vaccine.js';
import findRoutes from './routes/findRoutes.js';
import testRoutes from './routes/testRoutes.js';
import familyRoutes from './routes/familyRoutes.js';
import certificateRoutes from './routes/certificateRoutes.js';

// Config and Services
import sequelize from './config/db.js';
import {scheduleDailyReminderJob} from './services/reminderScheduler.js'
import {worker} from './workers/reminderWorker.js';

// Starting the Express app
const app = express();

// Testing DB connection
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
app.use(cors({
    origin: '*', // Adjust as needed for frontend
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    credentials: true
}));
app.use(bodyParser.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/educational-content', educationContentRoutes);
app.use('/api/vaccines', vaccineRoutes);
app.use('/api/test',testRoutes);
app.use('/api/find', findRoutes);
app.use('/api/family', familyRoutes);
app.use('/api/certificates', certificateRoutes);

const PORT = process.env.PORT || 5000;
scheduleDailyReminderJob();
// await sequelize.sync({ force: true }); // Use with caution: this will drop and recreate tables

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

// Graceful Shutdown
const shutdown = async () => {
    console.log('🛑 SIGTERM/SIGINT received. Shutting down gracefully...');

    // 1. Stop the server from accepting new HTTP requests
    server.close(() => {
        console.log('✅ HTTP Server closed.');
    });

    try {
        // 2. Tell the Worker to stop accepting new jobs and finish current ones
        await worker.close();
        console.log('✅ Background Worker closed.');

        // 3. Close Database Connection
        await sequelize.close();
        console.log('✅ Database connection closed.');

        // 4. Close Redis Connection
        await redisConnection.quit();
        console.log('✅ Redis connection closed.');

        process.exit(0);
    } catch (err) {
        console.error('❌ Error during shutdown:', err);
        process.exit(1);
    }
};

// Listen for termination signals
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

// how to start db : psql -d vaccinevault
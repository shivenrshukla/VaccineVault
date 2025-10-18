import express from 'express';
import { runReminderCheck } from '../services/reminderService.js';

const router = express.Router();

// This endpoint will trigger the reminder service logic on demand.
router.post('/trigger-reminders', (req, res) => {
    // We don't wait for it to finish, just kick it off in the background.
    runReminderCheck(); 
    res.status(202).json({ message: 'Reminder check has been triggered. Check server logs for details.' });
});

export default router;
import { reminderQueue } from '../queues/reminderQueue.js';

export const scheduleDailyReminderJob = async () => {
    await reminderQueue.add(
        'daily-reminder-check',
        {},
        {
            repeat: {
                cron: '0 8 * * *',
                tz: 'Asia/Kolkata'
            },
            jobId: 'daily-reminder-job'
        }
    );

    console.log('✅ Daily reminder job scheduled via BullMQ (08:00 AM IST)');
};
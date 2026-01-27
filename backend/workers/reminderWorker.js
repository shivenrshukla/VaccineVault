import { Worker } from 'bullmq';
import { redisConnection } from '../config/redis.js';
import { runReminderCheck } from '../services/reminderService.js';

export const worker = new Worker(
    'reminderQueue',
    async job => {
        console.log('🔔 Executing reminder job:', job.name);
        await runReminderCheck();
    },
    {
        connection: redisConnection,
        concurrency: 1
    }
);

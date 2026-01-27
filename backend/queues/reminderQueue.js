import { Queue } from 'bullmq';
import { redisConnection } from '../config/redis.js';

export const reminderQueue = new Queue('reminderQueue', {
    connection: redisConnection
});

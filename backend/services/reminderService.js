import { Op } from 'sequelize';
import UserVaccine from '../models/UserVaccine.js';
import User from '../models/User.js';
import Vaccine from '../models/Vaccine.js';
import transporter from '../config/mailer.js';
import admin from '../config/firebase.js';
import NotificationLog from '../models/NotificationLog.js';

/**
 * Guaranteed email delivery with persistence, idempotency, and retry metadata
 */
const sendGuaranteedEmail = async (user, vaccine, dueDate, isOverdue) => {
    const today = new Date().toISOString().split('T')[0];

    const [log] = await NotificationLog.findOrCreate({
        where: {
            userId: user.id,
            vaccineId: vaccine.id,
            channel: 'email',
            reminderDate: today
        }
    });

    // Idempotency: already sent today
    if (log.status === 'sent') return;

    const subject = isOverdue
        ? `Action Required: Your ${vaccine.name} dose is overdue!`
        : `Vaccination Reminder: Your ${vaccine.name} dose is due soon!`;

    const body = isOverdue
        ? `<p>This is a reminder that your dose for the <strong>${vaccine.name}</strong> vaccine was due on <strong>${dueDate}</strong> and is now overdue.</p>`
        : `<p>This is a friendly reminder that your next dose for the <strong>${vaccine.name}</strong> vaccine is due on <strong>${dueDate}</strong>.</p>`;

    const mailOptions = {
        from: `"VaccineVault" <${process.env.EMAIL_USER}>`,
        to: user.email,
        subject,
        html: `
            <p>Hello ${user.username},</p>
            ${body}
            <p>This vaccine helps protect against: ${vaccine.diseaseProtectedAgainst}.</p>
            <p>Please schedule an appointment with your healthcare provider as soon as possible.</p>
            <br />
            <p>Thank you,</p>
            <p>The VaccineVault Team</p>
        `
    };

    try {
        await transporter.sendMail(mailOptions);

        await log.update({
            status: 'sent',
            lastAttemptAt: new Date(),
            errorMessage: null
        });

        console.log(`✅ Email reminder sent to ${user.email} for ${vaccine.name}`);
    } catch (error) {
        await log.update({
            status: 'failed',
            retryCount: log.retryCount + 1,
            lastAttemptAt: new Date(),
            errorMessage: error.message
        });

        console.error(`❌ Failed to send email to ${user.email}:`, error.message);
    }
};

/**
 * Guaranteed push notification delivery with persistence and idempotency
 */
const sendGuaranteedPushNotification = async (user, vaccine, dueDate, isOverdue) => {
    if (!user.pushNotificationToken) {
        console.log(`ℹ️ User ${user.username} has no push token. Skipping push.`);
        return;
    }

    const today = new Date().toISOString().split('T')[0];

    const [log] = await NotificationLog.findOrCreate({
        where: {
            userId: user.id,
            vaccineId: vaccine.id,
            channel: 'push',
            reminderDate: today
        }
    });

    // Idempotency
    if (log.status === 'sent') return;

    const body = isOverdue
        ? `Your ${vaccine.name} dose was due on ${dueDate}!`
        : `Your ${vaccine.name} dose is due on ${dueDate}.`;

    const message = {
        token: user.pushNotificationToken,
        notification: {
            title: isOverdue ? 'Vaccine Overdue!' : 'Vaccine Reminder!',
            body
        }
    };

    try {
        await admin.messaging().send(message);

        await log.update({
            status: 'sent',
            lastAttemptAt: new Date(),
            errorMessage: null
        });

        console.log(`✅ Push notification sent to ${user.username}`);
    } catch (error) {
        await log.update({
            status: 'failed',
            retryCount: log.retryCount + 1,
            lastAttemptAt: new Date(),
            errorMessage: error.message
        });

        console.error(`❌ Failed to send push notification to ${user.username}:`, error.message);
    }
};

/**
 * Core reminder check logic
 */
export const runReminderCheck = async () => {
    console.log('--- 🔔 Triggered Reminder Check ---');

    const today = new Date().toISOString().split('T')[0];

    try {
        const dueAndOverdueVaccinations = await UserVaccine.findAll({
            where: {
                status: 'pending',
                nextDueDate: {
                    [Op.lte]: today
                }
            },
            include: [
                { model: User, attributes: ['id', 'email', 'username', 'pushNotificationToken'] },
                { model: Vaccine, attributes: ['id', 'name', 'diseaseProtectedAgainst'] }
            ]
        });

        console.log(`Found ${dueAndOverdueVaccinations.length} due or overdue vaccinations.`);

        for (const record of dueAndOverdueVaccinations) {
            const isOverdue = new Date(record.nextDueDate) < new Date(today);

            await sendGuaranteedEmail(
                record.User,
                record.Vaccine,
                record.nextDueDate,
                isOverdue
            );

            await sendGuaranteedPushNotification(
                record.User,
                record.Vaccine,
                record.nextDueDate,
                isOverdue
            );
        }
    } catch (error) {
        console.error('❌ Error during reminder check:', error);
    }
};

// Redis handled with start command, must be handled seperately in production
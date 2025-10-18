import cron from 'node-cron';
import { Op } from 'sequelize';
import UserVaccine from '../models/userVaccine.js';
import User from '../models/User.js';
import Vaccine from '../models/Vaccine.js';
import transporter from '../config/mailer.js';
import admin from '../config/firebase.js';

// --- Email & Push Notification functions ---

const sendReminderEmail = async (user, vaccine, dueDate, isOverdue) => {
    // Dynamically change the subject line if the vaccine is overdue
    const subject = isOverdue
        ? `Action Required: Your ${vaccine.name} dose is overdue!`
        : `Vaccination Reminder: Your ${vaccine.name} dose is due soon!`;
        
    const body = isOverdue
        ? `<p>This is a reminder that your dose for the <strong>${vaccine.name}</strong> vaccine was due on <strong>${dueDate}</strong> and is now overdue.</p>`
        : `<p>This is a friendly reminder that your next dose for the <strong>${vaccine.name}</strong> vaccine is due on <strong>${dueDate}</strong>.</p>`;

    const mailOptions = {
        from: `"VaccineVault" <${process.env.EMAIL_USER}>`,
        to: user.email,
        subject: subject,
        html: `
            <p>Hello ${user.username},</p>
            ${body}
            <p>This vaccine helps protect against: ${vaccine.diseaseProtectedAgainst}.</p>
            <p>Please schedule an appointment with your healthcare provider as soon as possible to stay on track.</p>
            <br>
            <p>Thank you,</p>
            <p>The VaccineVault Team</p>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`Reminder email sent to ${user.email} for ${vaccine.name}`);
    } catch (error) {
        console.error(`Failed to send email to ${user.email}:`, error);
    }
};

const sendPushNotification = async (user, vaccine, dueDate, isOverdue) => {
    if (!user.pushNotificationToken) {
        console.log(`User ${user.username} does not have a push token. Skipping.`);
        return;
    }

    // Dynamically change the push notification body
    const body = isOverdue
        ? `Your ${vaccine.name} dose was due on ${dueDate}!`
        : `Your ${vaccine.name} dose is due on ${dueDate}.`;

    const message = {
        notification: {
            title: isOverdue ? 'Vaccine Overdue!' : 'Vaccine Reminder!',
            body: body,
        },
        token: user.pushNotificationToken,
    };
    
    try {
        await admin.messaging().send(message);
        console.log(`Push notification sent to ${user.username}`);
    } catch (error) {
        console.error(`Failed to send push notification to ${user.username}:`, error);
    }
};

// --- This is the core logic function with the updated query ---
export const runReminderCheck = async () => {
    console.log('--- Triggered Reminder Check ---');
    const today = new Date().toISOString().split('T')[0]; // Get today's date in 'YYYY-MM-DD' format

    try {
        // Find all "pending" vaccines where the due date is today or any day in the past.
        const dueAndOverdueVaccinations = await UserVaccine.findAll({
            where: {
                status: 'pending',
                nextDueDate: {
                    [Op.lte]: today // "lte" means "Less Than or Equal To"
                }
            },
            include: [
                { model: User, attributes: ['email', 'username', 'pushNotificationToken'] },
                { model: Vaccine, attributes: ['name', 'diseaseProtectedAgainst'] }
            ]
        });

        console.log(`Found ${dueAndOverdueVaccinations.length} due or overdue vaccinations to remind.`);
        for (const record of dueAndOverdueVaccinations) {
            // We now know any vaccine found by this query is overdue or due today.
            const isOverdue = new Date(record.nextDueDate) < new Date(today);
            await sendReminderEmail(record.User, record.Vaccine, record.nextDueDate, isOverdue);
            await sendPushNotification(record.User, record.Vaccine, record.nextDueDate, isOverdue);
        }
    } catch (error) {
        console.error('Error during reminder check:', error);
    }
};

// The cron job remains the same, it just calls our updated logic function.
export const startReminderService = () => {
    cron.schedule('0 8 * * *', async () => {
        await runReminderCheck();
    }, {
        scheduled: true,
        timezone: "Asia/Kolkata"
    });
    console.log('✅ Reminder service has been scheduled to run daily at 8:00 AM.');
};
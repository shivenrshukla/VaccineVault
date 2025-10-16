import admin from 'firebase-admin';
import fs from 'fs'; // 1. Import the 'fs' module
import path from 'path'; // 2. Import the 'path' module for robust file paths
import { fileURLToPath } from 'url';

// 3. Construct a reliable path to your JSON key
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');

// 4. Read the file and parse it into a JavaScript object
const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

// Use the key to initialize the Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log('✅ Firebase Admin SDK initialized.');

// Export the initialized 'admin' object
export default admin;
// controllers/mapMyIndiaAuth.js
import axios from 'axios';

const MAPMYINDIA_CLIENT_ID = process.env.MAPMYINDIA_CLIENT_ID;
const MAPMYINDIA_CLIENT_SECRET = process.env.MAPMYINDIA_CLIENT_SECRET;
const MAPMYINDIA_TOKEN_URL = 'https://outpost.mapmyindia.com/api/security/oauth/token';

let cachedToken = null;
let tokenExpiryTime = null;

/**
 * Get a valid MapMyIndia access token (cached or fresh)
 */
export async function getMapMyIndiaToken() {
  // Return cached token if still valid (with 5-minute buffer)
  if (cachedToken && tokenExpiryTime && Date.now() < tokenExpiryTime) {
    console.log('[DEBUG] ✅ Using cached MapMyIndia token');
    return cachedToken;
  }

  console.log('[DEBUG] 🔄 Fetching new MapMyIndia access token...');

  if (!MAPMYINDIA_CLIENT_ID || !MAPMYINDIA_CLIENT_SECRET) {
    throw new Error('MapMyIndia CLIENT_ID and CLIENT_SECRET must be configured in .env file');
  }

  try {
    const response = await axios.post(
      MAPMYINDIA_TOKEN_URL,
      new URLSearchParams({
        grant_type: 'client_credentials',
        client_id: MAPMYINDIA_CLIENT_ID,
        client_secret: MAPMYINDIA_CLIENT_SECRET,
      }),
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      }
    );

    cachedToken = response.data.access_token;
    const expiresIn = response.data.expires_in || 86400; // Default 24 hours
    tokenExpiryTime = Date.now() + (expiresIn * 1000) - 300000; // Refresh 5 min early

    console.log(`[DEBUG] ✅ New MapMyIndia token obtained (expires in ${expiresIn}s)`);
    console.log(`[DEBUG] Token preview: ${cachedToken.substring(0, 10)}...`);
    
    return cachedToken;
  } catch (error) {
    console.error('[DEBUG] ❌ Failed to get MapMyIndia token:', error.message);
    if (error.response) {
      console.error('[DEBUG] Token Error Response:', JSON.stringify(error.response.data, null, 2));
    }
    throw new Error('Failed to authenticate with MapMyIndia API. Check your credentials.');
  }
}

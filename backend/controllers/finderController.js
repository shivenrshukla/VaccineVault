import axios from 'axios';
import https from 'https';
import { GoogleGenerativeAI } from "@google/generative-ai";

// --- (API Keys, URLs, httpsAgent remain the same) ---
const MAPMYINDIA_TOKEN = process.env.MAPMYINDIA_ACCESS_TOKEN;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const MAPMYINDIA_BASE_URL = 'https://atlas.mapmyindia.com/api/places';
const MAPMYINDIA_SEARCH_URL = `${MAPMYINDIA_BASE_URL}/search/json`;
const httpsAgent = new https.Agent({ family: 4 });

// --- (Gemini Configuration remains the same) ---
let genAI;
let geminiModel;
if (GEMINI_API_KEY) {
  try {
    genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
    geminiModel = genAI.getGenerativeModel({ model: "gemini-2.5-flash"});
     console.log('✅ Gemini AI SDK initialized.');
  } catch (error) {
     console.error('❌ Failed to initialize Gemini AI SDK:', error.message);
  }
} else {
  console.warn('⚠️ GEMINI_API_KEY not found. Coordinate lookup will fail.');
}

// --- (getCoordinatesFromGemini function remains the same) ---
async function getCoordinatesFromGemini(pinCode) {
    if (!geminiModel) {
      console.error('[DEBUG] Gemini model not initialized.');
      return null;
  }
  console.log(`[DEBUG] Asking Gemini for coordinates for pincode: ${pinCode}`);
  try {
    const prompt = `Provide the approximate latitude and longitude coordinates for the center of the area covered by Indian pincode ${pinCode}. Respond ONLY with the latitude, a comma, and the longitude (e.g., "19.22, 72.97"). Do not include any other text, units like degrees, or explanations.`;
    const result = await geminiModel.generateContent(prompt);
    const response = await result.response;
    const text = response.text().trim();
    console.log(`[DEBUG] Gemini Raw Response: "${text}"`);
    const parts = text.split(',');
    if (parts.length === 2) {
      const lat = parseFloat(parts[0].trim());
      const lng = parseFloat(parts[1].trim());
      if (!isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        console.log(`[DEBUG] Gemini returned valid coordinates: ${lat}, ${lng}`);
        return { lat, lng };
      } else {
         console.error(`[DEBUG] Gemini response coordinates out of range or invalid: ${text}`);
      }
    } else {
      console.error(`[DEBUG] Gemini response format incorrect (expected 'lat,lng'): ${text}`);
    }
    return null;
  } catch (error) {
    console.error('[DEBUG] Error calling Gemini API:', error.message);
    if (error.response?.data) {
        console.error('[DEBUG] Gemini API Error Details:', JSON.stringify(error.response.data));
    }
    return null;
  }
}

/**
 * @desc    Find healthcare facilities near a pincode using Gemini for coords
 * @route   GET /api/find-centers
 * @access  Public
 */
export const findCenters = async (req, res) => {
  const { pinCode } = req.query;

  // --- Input Validation ---
  if (!pinCode) { return res.status(400).json({ error: 'A pinCode is required.' }); }
  if (!MAPMYINDIA_TOKEN) { return res.status(500).json({ error: 'MapmyIndia API key is missing.' }); }
  if (!GEMINI_API_KEY || !geminiModel) { return res.status(500).json({ error: 'Gemini API is not configured or initialized.' }); }

  console.log(`[DEBUG] Using MapmyIndia Token: ${MAPMYINDIA_TOKEN ? MAPMYINDIA_TOKEN.substring(0, 10) + '...' : 'MISSING!'}`);

  // --- API Logic ---
  try {
    console.log('--- [DEBUG] New Request Received ---');

    // --------------------------------------------------------------------
    // STEP 1A: Get Pincode Details (City/State) from MapmyIndia Search
    // --------------------------------------------------------------------
    console.log(`[DEBUG] Step 1A: Getting City/State for pincode: ${pinCode}`);
    let targetCity = '';
    let targetState = '';

    const pincodeDetailsResponse = await axios.get(MAPMYINDIA_SEARCH_URL, {
        params: { query: pinCode, itemcount: 1 },
        headers: { 'Authorization': `Bearer ${MAPMYINDIA_TOKEN}` },
        httpsAgent: httpsAgent
    });

    console.log('[DEBUG] Step 1A (Pincode Details) Raw Response:', JSON.stringify(pincodeDetailsResponse.data, null, 2));

    const pincodeLocationInfo = pincodeDetailsResponse.data?.suggestedLocations?.find(loc => loc.type === 'PINCODE');

    if (pincodeLocationInfo && pincodeLocationInfo.placeAddress) {
        const addressParts = pincodeLocationInfo.placeAddress.split(',').map(part => part.trim());
         if (addressParts.length >= 2) {
             targetState = addressParts[addressParts.length - 1]; // State is usually last
             targetCity = addressParts[addressParts.length - 2]; // City is usually second last
             // Basic validation for common Indian state names
             if (targetState.length < 3 || targetState.toLowerCase() === 'india') {
                console.warn(`[DEBUG] Step 1A: Extracted state "${targetState}" seems invalid. Resetting.`);
                targetState = ''; // Reset if it looks wrong
                if (addressParts.length >= 3) { // Try third last as state if last looked wrong
                    const potentialState = addressParts[addressParts.length - 2];
                    if (potentialState.length >= 3 && potentialState.toLowerCase() !== 'india'){
                         targetState = potentialState;
                         targetCity = addressParts[addressParts.length - 3];
                    }
                }
             }
              console.log(`[DEBUG] Step 1A: Using Target City: "${targetCity}", State: "${targetState}" for filtering.`);
         }
    }
    if (!targetState) { // We at least need the state for the fallback
         console.warn(`[DEBUG] Step 1A: Could not reliably extract State for pincode ${pinCode}. Filtering might be inaccurate.`);
    }


    // --------------------------------------------------------------------
    // STEP 1B: Get Lat/Lng from PinCode using Gemini
    // --------------------------------------------------------------------
    console.log(`[DEBUG] Step 1B: Getting coordinates for pincode: ${pinCode} via Gemini`);
    const coordinates = await getCoordinatesFromGemini(pinCode);

    if (!coordinates || typeof coordinates.lat !== 'number' || typeof coordinates.lng !== 'number') {
      return res.status(404).json({ error: 'Could not retrieve valid coordinates from Gemini for that pincode.' });
    }
    const { lat, lng } = coordinates;
    console.log(`Step 1B: Found coordinates via Gemini: ${lat}, ${lng} for pincode ${pinCode}`);


    // --------------------------------------------------------------------
    // STEP 2: Use MapmyIndia Search API with Coordinates and Radius
    // --------------------------------------------------------------------
    const searchQuery = "hospital vaccination center clinic healthcare";
    console.log(`[DEBUG] Step 2: Searching MapmyIndia for "${searchQuery}" near ${lat},${lng} within 10km`);

    const nearbyResponse = await axios.get(MAPMYINDIA_SEARCH_URL, {
      params: {
        query: searchQuery,
        location: `${lat},${lng}`,
        radius: 10000,
      },
      headers: { 'Authorization': `Bearer ${MAPMYINDIA_TOKEN}` },
      httpsAgent: httpsAgent
    });

    console.log('[DEBUG] Step 2 (MapmyIndia Search) Raw Response:', JSON.stringify(nearbyResponse.data, null, 2));

    const allCentersRaw = nearbyResponse.data.suggestedLocations;

    if (!allCentersRaw || allCentersRaw.length === 0) {
      return res.status(404).json({
        error: 'No healthcare facilities found within 10km using the MapmyIndia Search API.',
        location: { lat, lng }
      });
    }

    // --------------------------------------------------------------------
    // STEP 3: Filter Results by TARGET City/State (with improved fallback)
    // --------------------------------------------------------------------
    let filteredCenters = allCentersRaw; // Start with all results

    // Only attempt strict filtering if we have both city and state
    if (targetCity && targetState) {
        console.log(`[DEBUG] Attempting strict filtering using Target City: "${targetCity}", State: "${targetState}"`);
        const strictlyFiltered = allCentersRaw.filter(center => {
            const addressLower = center.placeAddress?.toLowerCase() || "";
            const cityMatch = addressLower.includes(targetCity.toLowerCase());
            const stateMatch = addressLower.includes(targetState.toLowerCase());
            return cityMatch && stateMatch;
        });

        // Check if strict filtering removed everything
        if (strictlyFiltered.length > 0) {
            filteredCenters = strictlyFiltered;
            console.log(`[DEBUG] Strict filtering successful: ${allCentersRaw.length} -> ${filteredCenters.length} results.`);
        } else if (allCentersRaw.length > 0) {
             // ** IMPROVED FALLBACK: Filter by State ONLY **
             console.warn('[DEBUG] Strict city+state filtering removed all results. Falling back to state-only filtering.');
             filteredCenters = allCentersRaw.filter(center => {
                 const addressLower = center.placeAddress?.toLowerCase() || "";
                 return addressLower.includes(targetState.toLowerCase());
             });
             console.log(`[DEBUG] State-only fallback filtering: ${allCentersRaw.length} -> ${filteredCenters.length} results.`);

             // Final fallback: If even state-only filtering removes everything, use original list
             if (filteredCenters.length === 0) {
                 console.warn('[DEBUG] State-only filtering also removed all results. Reverting to unfiltered list.');
                 filteredCenters = allCentersRaw;
             }
        }
    }
    // If we only have state (or neither), we skip strict filtering and rely on MapmyIndia's ranking
    else if (targetState) {
         console.warn('[DEBUG] Target city unknown. Attempting state-only filtering.');
         const stateFiltered = allCentersRaw.filter(center => {
             const addressLower = center.placeAddress?.toLowerCase() || "";
             return addressLower.includes(targetState.toLowerCase());
         });
          if (stateFiltered.length > 0) {
             filteredCenters = stateFiltered;
             console.log(`[DEBUG] State-only filtering successful: ${allCentersRaw.length} -> ${filteredCenters.length} results.`);
          } else {
              console.warn('[DEBUG] State-only filtering removed all results. Using unfiltered list.');
              filteredCenters = allCentersRaw; // Fallback if state filter is too aggressive
          }
    }
     else {
         console.warn('[DEBUG] Skipping filtering as target City/State could not be determined reliably.');
    }


    // --------------------------------------------------------------------
    // STEP 4: Format the Filtered Results
    // --------------------------------------------------------------------
    const centers = filteredCenters.map(center => ({
      name: center.placeName,
      address: center.placeAddress,
      contact: center.contactNumber || 'Not Available',
      distance: center.distance ? `${center.distance} meters` : 'Distance unknown'
    }));

    // Send the successful response
    res.json({
      searchLocation: { lat, lng, pinCode, source: "Gemini Coordinates" },
      foundCenters: centers, // Send the potentially filtered array
    });

  } catch (error) {
     handleApiError(error, res); // Use the helper function
  }
};

// --- (handleApiError function remains the same) ---
function handleApiError(error, res) {
    if (error.message.includes('Gemini')) {
         console.error('[DEBUG] CAUGHT A GEMINI API ERROR:', error.message);
         return res.status(500).json({ error: 'Failed to get coordinates via Gemini.' });
    }
    console.error('[DEBUG] CAUGHT AN ERROR:', error.code || 'Unknown Error');
    if (error.response) {
      console.error('API Error Status:', error.response.status);
      console.error('API Error Data:', JSON.stringify(error.response.data));
    } else {
      console.error('API Error Message:', error.message);
    }
    const errorMessage = error.response?.data?.error_description || error.response?.data?.message || error.response?.data?.error || 'An error occurred while fetching data.';
    const statusCode = error.response?.status || 500;
     if (statusCode === 401 && error.response?.data?.error_code === 'ASSET_ACCESS_DENIED') {
         return res.status(401).json({ error: `MapmyIndia API Access Denied (${error.response.data.error_code}). Please contact MapmyIndia support.` });
     }
     if (statusCode === 401) {
        return res.status(401).json({ error: `Authentication failed or API Access Denied: ${errorMessage}` });
     }
    res.status(statusCode).json({ error: errorMessage });
}
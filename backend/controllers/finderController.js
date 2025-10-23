// controllers/finderController.js
import axios from 'axios';
import https from 'https';
import { GoogleGenerativeAI } from "@google/generative-ai";
import { getMapMyIndiaToken } from './mapMyIndiaAuth.js';

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const MAPMYINDIA_BASE_URL = 'https://atlas.mapmyindia.com/api/places';
const MAPMYINDIA_SEARCH_URL = `${MAPMYINDIA_BASE_URL}/search/json`;
const httpsAgent = new https.Agent({ family: 4 });

// Pin code coordinate cache for fallback
const PINCODE_COORDINATES_CACHE = {
  '401105': { lat: 19.2403, lng: 72.8517 }, // Mira Road, Mumbai
  '400001': { lat: 18.9388, lng: 72.8354 }, // Mumbai Fort
  '110001': { lat: 28.6139, lng: 77.2090 }, // New Delhi
  '560001': { lat: 12.9716, lng: 77.5946 }, // Bangalore
  '700001': { lat: 22.5726, lng: 88.3639 }, // Kolkata
  '600001': { lat: 13.0827, lng: 80.2707 }, // Chennai
};

// Gemini Configuration
let genAI;
let geminiModel;
if (GEMINI_API_KEY) {
  try {
    genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
    // ✅ Use stable model instead of experimental one
    geminiModel = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
    console.log('✅ Gemini AI SDK initialized with gemini-2.5-flash');
  } catch (error) {
    console.error('❌ Failed to initialize Gemini AI SDK:', error.message);
  }
} else {
  console.warn('⚠️ GEMINI_API_KEY not found. Will use fallback coordinates.');
}

/**
 * Get coordinates from Gemini with retry logic and fallback
 */
async function getCoordinatesFromGemini(pinCode, retries = 2) {
  // Check cache first
  if (PINCODE_COORDINATES_CACHE[pinCode]) {
    console.log(`[DEBUG] ✅ Using cached coordinates for pincode: ${pinCode}`);
    return PINCODE_COORDINATES_CACHE[pinCode];
  }

  if (!geminiModel) {
    console.error('[DEBUG] Gemini model not initialized, using fallback.');
    return null;
  }

  console.log(`[DEBUG] Asking Gemini for coordinates for pincode: ${pinCode}`);

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const prompt = `Provide the approximate latitude and longitude coordinates for the center of the area covered by Indian pincode ${pinCode}. Respond ONLY with the latitude, a comma, and the longitude (e.g., "19.22, 72.97"). Do not include any other text, units, or explanations.`;
      
      const result = await geminiModel.generateContent(prompt);
      const response = await result.response;
      const text = response.text().trim();
      
      console.log(`[DEBUG] Gemini response (attempt ${attempt}): "${text}"`);
      
      const parts = text.split(',');
      if (parts.length === 2) {
        const lat = parseFloat(parts[0].trim());
        const lng = parseFloat(parts[1].trim());
        
        if (!isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
          console.log(`[DEBUG] ✅ Gemini returned valid coordinates: ${lat}, ${lng}`);
          
          // Cache the result for future use
          PINCODE_COORDINATES_CACHE[pinCode] = { lat, lng };
          
          return { lat, lng };
        } else {
          console.error(`[DEBUG] Coordinates out of range: ${text}`);
        }
      } else {
        console.error(`[DEBUG] Invalid format (expected 'lat,lng'): ${text}`);
      }
      
    } catch (error) {
      console.error(`[DEBUG] ❌ Gemini error (attempt ${attempt}/${retries}):`, error.message);
      
      // Check for 503 (overloaded) error
      if (error.message.includes('503') || error.message.includes('overloaded')) {
        if (attempt < retries) {
          const waitTime = 1000 * attempt; // 1s, 2s
          console.log(`[DEBUG] ⏳ Model overloaded, waiting ${waitTime}ms before retry...`);
          await new Promise(resolve => setTimeout(resolve, waitTime));
          continue;
        } else {
          console.warn('[DEBUG] ⚠️ Gemini model still overloaded after retries');
        }
      }
    }
  }

  console.warn(`[DEBUG] ⚠️ Gemini failed for pincode ${pinCode}`);
  return null;
}

/**
 * @desc    Find healthcare facilities near a pincode
 * @route   GET /api/find/find-centers
 * @access  Public
 */
export const findCenters = async (req, res) => {
  const { pinCode } = req.query;

  // Input Validation
  if (!pinCode) {
    return res.status(400).json({ error: 'A pinCode is required.' });
  }

  console.log('=== [DEBUG] New Find Centers Request ===');
  console.log(`[DEBUG] Pin Code: ${pinCode}`);

  try {
    // ✅ Get fresh MapMyIndia token
    const MAPMYINDIA_TOKEN = await getMapMyIndiaToken();

    // STEP 1A: Get City/State from pincode
    console.log(`[DEBUG] Step 1A: Getting location details for pincode: ${pinCode}`);
    let targetCity = '';
    let targetState = '';

    try {
      const pincodeDetailsResponse = await axios.get(MAPMYINDIA_SEARCH_URL, {
        params: { query: pinCode, itemcount: 1 },
        headers: { 'Authorization': `Bearer ${MAPMYINDIA_TOKEN}` },
        httpsAgent: httpsAgent,
        timeout: 10000,
      });

      const pincodeLocationInfo = pincodeDetailsResponse.data?.suggestedLocations?.find(
        loc => loc.type === 'PINCODE'
      );

      if (pincodeLocationInfo && pincodeLocationInfo.placeAddress) {
        const addressParts = pincodeLocationInfo.placeAddress.split(',').map(part => part.trim());
        if (addressParts.length >= 2) {
          targetState = addressParts[addressParts.length - 1];
          targetCity = addressParts[addressParts.length - 2];

          if (targetState.length < 3 || targetState.toLowerCase() === 'india') {
            targetState = '';
            if (addressParts.length >= 3) {
              const potentialState = addressParts[addressParts.length - 2];
              if (potentialState.length >= 3 && potentialState.toLowerCase() !== 'india') {
                targetState = potentialState;
                targetCity = addressParts[addressParts.length - 3];
              }
            }
          }
          console.log(`[DEBUG] Target City: "${targetCity}", State: "${targetState}"`);
        }
      }
    } catch (error) {
      console.warn('[DEBUG] ⚠️ Failed to get city/state, will skip filtering:', error.message);
    }

    // STEP 1B: Get coordinates
    console.log(`[DEBUG] Step 1B: Getting coordinates for pincode: ${pinCode}`);
    const coordinates = await getCoordinatesFromGemini(pinCode);

    if (!coordinates || typeof coordinates.lat !== 'number' || typeof coordinates.lng !== 'number') {
      return res.status(404).json({
        error: 'Could not retrieve coordinates for that pincode. Please check the pincode and try again.'
      });
    }

    const { lat, lng } = coordinates;
    console.log(`[DEBUG] ✅ Using coordinates: ${lat}, ${lng}`);

    // STEP 2: Search for nearby healthcare facilities
    const searchQuery = "hospital vaccination clinic healthcare";
    console.log(`[DEBUG] Step 2: Searching for facilities near ${lat},${lng}`);

    const nearbyResponse = await axios.get(MAPMYINDIA_SEARCH_URL, {
      params: {
        query: searchQuery,
        location: `${lat},${lng}`,
        radius: 10000, // 10km
      },
      headers: { 'Authorization': `Bearer ${MAPMYINDIA_TOKEN}` },
      httpsAgent: httpsAgent,
      timeout: 15000,
    });

    const allCentersRaw = nearbyResponse.data.suggestedLocations;

    if (!allCentersRaw || allCentersRaw.length === 0) {
      return res.status(404).json({
        error: 'No healthcare facilities found within 10km of this location.',
        location: { lat, lng, pinCode }
      });
    }

    console.log(`[DEBUG] Found ${allCentersRaw.length} facilities`);

    // STEP 3: Filter by city/state if available
    let filteredCenters = allCentersRaw;

    if (targetCity && targetState) {
      const strictlyFiltered = allCentersRaw.filter(center => {
        const addressLower = center.placeAddress?.toLowerCase() || "";
        return addressLower.includes(targetCity.toLowerCase()) &&
               addressLower.includes(targetState.toLowerCase());
      });

      if (strictlyFiltered.length > 0) {
        filteredCenters = strictlyFiltered;
        console.log(`[DEBUG] Filtered to ${filteredCenters.length} centers (city+state match)`);
      } else if (targetState) {
        const stateFiltered = allCentersRaw.filter(center => {
          const addressLower = center.placeAddress?.toLowerCase() || "";
          return addressLower.includes(targetState.toLowerCase());
        });
        if (stateFiltered.length > 0) {
          filteredCenters = stateFiltered;
          console.log(`[DEBUG] Filtered to ${filteredCenters.length} centers (state match only)`);
        }
      }
    }

    // STEP 4: Format results
    const centers = filteredCenters.map(center => ({
      name: center.placeName,
      address: center.placeAddress,
      contact: center.contactNumber || 'Not Available',
      distance: center.distance ? `${Math.round(center.distance / 1000)} km` : 'Distance unknown'
    }));

    console.log(`[DEBUG] ✅ Returning ${centers.length} centers`);

    res.json({
      searchLocation: { lat, lng, pinCode, source: "Gemini Coordinates" },
      foundCenters: centers,
    });

  } catch (error) {
    handleApiError(error, res);
  }
};

function handleApiError(error, res) {
  console.error('[DEBUG] ❌ ERROR:', error.message);

  if (error.message.includes('Gemini')) {
    return res.status(500).json({
      error: 'Failed to get coordinates. Please try again in a moment.'
    });
  }

  if (error.response) {
    console.error('[DEBUG] API Error Status:', error.response.status);
    console.error('[DEBUG] API Error Data:', JSON.stringify(error.response.data, null, 2));

    const statusCode = error.response.status;
    const errorMessage = error.response.data?.error_description ||
                        error.response.data?.message ||
                        error.response.data?.error ||
                        'An error occurred';

    if (statusCode === 401) {
      return res.status(401).json({
        error: `Authentication failed with MapMyIndia API: ${errorMessage}`
      });
    }

    return res.status(statusCode).json({ error: errorMessage });
  }

  res.status(500).json({
    error: 'An unexpected error occurred. Please try again.'
  });
}

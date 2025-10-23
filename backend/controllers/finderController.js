// controllers/finderController.js
import axios from 'axios';
import https from 'https';
import { GoogleGenerativeAI } from "@google/generative-ai";
import { getMapMyIndiaToken } from './mapMyIndiaAuth.js';

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const MAPMYINDIA_BASE_URL = 'https://atlas.mapmyindia.com/api/places';
const MAPMYINDIA_SEARCH_URL = `${MAPMYINDIA_BASE_URL}/search/json`;
const MAPMYINDIA_GEOCODE_URL = `${MAPMYINDIA_BASE_URL}/geocode`; // Geocoding endpoint
const httpsAgent = new https.Agent({ family: 4 });

// Pin code coordinate cache for fallback
const PINCODE_COORDINATES_CACHE = {
  '401105': { lat: 19.2403, lng: 72.8517 },
  '400001': { lat: 18.9388, lng: 72.8354 },
  '110001': { lat: 28.6139, lng: 77.2090 },
  '560001': { lat: 12.9716, lng: 77.5946 },
  '700001': { lat: 22.5726, lng: 88.3639 },
  '600001': { lat: 13.0827, lng: 80.2707 },
};

// Gemini Configuration
let genAI;
let geminiModel;
if (GEMINI_API_KEY) {
  try {
    genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
    geminiModel = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
    console.log('✅ Gemini AI SDK initialized with gemini-2.5-flash');
  } catch (error) {
    console.error('❌ Failed to initialize Gemini AI SDK:', error.message);
  }
} else {
  console.warn('⚠️ GEMINI_API_KEY not found. Will use fallback coordinates.');
}

/**
 * Haversine formula to calculate distance between two coordinates
 * @param {number} lat1 - Latitude of first point
 * @param {number} lon1 - Longitude of first point
 * @param {number} lat2 - Latitude of second point
 * @param {number} lon2 - Longitude of second point
 * @returns {number} Distance in kilometers
 */
function calculateHaversineDistance(lat1, lon1, lat2, lon2) {
  const toRadians = (degree) => (degree * Math.PI) / 180;

  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const lat1Rad = toRadians(lat1);
  const lat2Rad = toRadians(lat2);

  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1Rad) * Math.cos(lat2Rad) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  const earthRadiusKm = 6371;

  return earthRadiusKm * c;
}

/**
 * Geocode an address using MapMyIndia Geocoding API
 * @param {string} address - Full address to geocode
 * @param {string} token - MapMyIndia access token
 * @returns {Object|null} { lat, lng } or null if failed
 */
async function geocodeAddressWithMapMyIndia(address, token) {
  if (!token) {
    console.error('[DEBUG] ❌ MapMyIndia token not provided for geocoding');
    return null;
  }

  if (!address || address.trim() === '') {
    console.error('[DEBUG] ❌ Invalid address provided for geocoding');
    return null;
  }

  try {
    console.log(`[DEBUG] 🗺️ Geocoding address with MapMyIndia: "${address}"`);

    const response = await axios.get(MAPMYINDIA_GEOCODE_URL, {
      params: {
        address: address,
        itemCount: 1, // We only need the best match
      },
      headers: {
        'Authorization': `Bearer ${token}`
      },
      httpsAgent: httpsAgent,
      timeout: 10000,
    });

    console.log('[DEBUG] MapMyIndia Geocode Response:', JSON.stringify(response.data, null, 2));

    // MapMyIndia geocode response structure
    if (response.data && response.data.copResults) {
      const results = response.data.copResults;
      
      // Try different possible result structures
      let lat = null;
      let lng = null;

      // Check if it's an array or object
      if (Array.isArray(results) && results.length > 0) {
        const firstResult = results[0];
        lat = firstResult.latitude || firstResult.lat;
        lng = firstResult.longitude || firstResult.lng || firstResult.lon;
      } else if (typeof results === 'object') {
        lat = results.latitude || results.lat;
        lng = results.longitude || results.lng || results.lon;
      }

      if (lat && lng) {
        const parsedLat = parseFloat(lat);
        const parsedLng = parseFloat(lng);
        
        if (!isNaN(parsedLat) && !isNaN(parsedLng)) {
          console.log(`[DEBUG] ✅ MapMyIndia geocoded address to: ${parsedLat}, ${parsedLng}`);
          return { lat: parsedLat, lng: parsedLng };
        }
      }
    }

    console.warn('[DEBUG] ⚠️ No valid results from MapMyIndia geocoding');
    return null;
  } catch (error) {
    if (error.response?.status === 401) {
      console.error('[DEBUG] ❌ MapMyIndia 401 Unauthorized - Token may be expired');
    } else if (error.response?.status === 403) {
      console.error('[DEBUG] ❌ MapMyIndia 403 Forbidden - Check API permissions');
    } else {
      console.error('[DEBUG] ❌ MapMyIndia geocoding error:', error.message);
      if (error.response) {
        console.error('[DEBUG] Response data:', error.response.data);
      }
    }
    return null;
  }
}

/**
 * Get coordinates from Gemini with retry logic and fallback
 */
async function getCoordinatesFromGemini(pinCode, retries = 2) {
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
      
      if (error.message.includes('503') || error.message.includes('overloaded')) {
        if (attempt < retries) {
          const waitTime = 1000 * attempt;
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
 * @desc    Find healthcare facilities near a pincode with distance calculation
 * @route   GET /api/find/find-centers
 * @access  Public
 * @query   {string} pinCode - Pincode to search near
 * @query   {string} userAddress - (Optional) User's full address for accurate distance calculation
 */
export const findCenters = async (req, res) => {
  const { pinCode, userAddress } = req.query;

  // Input Validation
  if (!pinCode) {
    return res.status(400).json({ error: 'A pinCode is required.' });
  }

  console.log('=== [DEBUG] New Find Centers Request ===');
  console.log(`[DEBUG] Pin Code: ${pinCode}`);
  console.log(`[DEBUG] User Address: ${userAddress || 'Not provided'}`);

  try {
    // ✅ Get fresh MapMyIndia token
    const MAPMYINDIA_TOKEN = await getMapMyIndiaToken();

    // STEP 0: Geocode user's address if provided
    let userCoordinates = null;
    if (userAddress) {
      userCoordinates = await geocodeAddressWithMapMyIndia(userAddress, MAPMYINDIA_TOKEN);
      if (userCoordinates) {
        console.log(`[DEBUG] ✅ User location: ${userCoordinates.lat}, ${userCoordinates.lng}`);
      } else {
        console.warn('[DEBUG] ⚠️ Failed to geocode user address');
      }
    }

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
    console.log('[DEBUG] 📊 Sample center structure:', JSON.stringify(allCentersRaw[0], null, 2));

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

    // STEP 4: Geocode center addresses and calculate distances
    console.log('[DEBUG] Step 4: Processing centers and calculating distances...');
    
    const centersWithDistances = await Promise.all(
      filteredCenters.map(async (center, index) => {
        console.log(`[DEBUG] --- Processing Center ${index + 1}: ${center.placeName} ---`);
        
        let calculatedDistance = null;
        let distanceSource = 'MapMyIndia API';
        let centerLat = null;
        let centerLng = null;
        let coordinateSource = null;

        // Try to extract center coordinates from ALL possible MapMyIndia fields
        const possibleLatFields = ['latitude', 'lat', 'eLat'];
        const possibleLngFields = ['longitude', 'lng', 'lon', 'eLong'];

        for (const field of possibleLatFields) {
          if (center[field] && !isNaN(parseFloat(center[field]))) {
            centerLat = parseFloat(center[field]);
            break;
          }
        }

        for (const field of possibleLngFields) {
          if (center[field] && !isNaN(parseFloat(center[field]))) {
            centerLng = parseFloat(center[field]);
            break;
          }
        }

        if (centerLat && centerLng) {
          coordinateSource = 'MapMyIndia';
          console.log(`[DEBUG] ✅ MapMyIndia coords: ${centerLat}, ${centerLng}`);
        } else {
          console.log(`[DEBUG] ❌ No coordinates in MapMyIndia response`);
        }

        // Try to extract MapMyIndia distance
        let mapMyIndiaDistance = null;
        if (center.distance && !isNaN(parseFloat(center.distance))) {
          mapMyIndiaDistance = parseFloat(center.distance);
          console.log(`[DEBUG] MapMyIndia distance field: ${mapMyIndiaDistance} (meters)`);
        } else {
          console.log(`[DEBUG] No distance field in MapMyIndia response`);
        }

        // If user address was provided and geocoded successfully
        if (userCoordinates) {
          console.log(`[DEBUG] User coordinates available: ${userCoordinates.lat}, ${userCoordinates.lng}`);
          
          // If MapMyIndia doesn't provide center coordinates, geocode the center address
          if (!centerLat || !centerLng) {
            console.log(`[DEBUG] 🔍 Geocoding center address: ${center.placeAddress}`);
            
            const centerCoords = await geocodeAddressWithMapMyIndia(center.placeAddress, MAPMYINDIA_TOKEN);
            if (centerCoords) {
              centerLat = centerCoords.lat;
              centerLng = centerCoords.lng;
              coordinateSource = 'MapMyIndia Geocode';
              console.log(`[DEBUG] ✅ Center geocoded to: ${centerLat}, ${centerLng}`);
            } else {
              console.warn(`[DEBUG] ❌ Geocoding failed for center`);
            }
          }

          // Calculate distance if we have both user and center coordinates
          if (centerLat && centerLng && !isNaN(centerLat) && !isNaN(centerLng)) {
            calculatedDistance = calculateHaversineDistance(
              userCoordinates.lat,
              userCoordinates.lng,
              centerLat,
              centerLng
            );
            
            distanceSource = coordinateSource === 'MapMyIndia Geocode' 
              ? 'MapMyIndia Geocode + Haversine'
              : 'MapMyIndia Coords + Haversine';
            
            console.log(`[DEBUG] ✅ Calculated distance: ${calculatedDistance.toFixed(2)} km (via ${distanceSource})`);
          } else {
            console.warn(`[DEBUG] ⚠️ Cannot calculate Haversine distance - missing valid coordinates`);
          }
        } else {
          console.log(`[DEBUG] ⚠️ No user coordinates available (geocoding failed or not provided)`);
        }

        // Determine final distance display and value
        let displayDistance = 'Distance unknown';
        let distanceValue = null;
        let finalDistanceSource = 'Unknown';

        if (calculatedDistance !== null) {
          // Priority 1: Use our precise Haversine calculation
          displayDistance = `${calculatedDistance.toFixed(2)} km`;
          distanceValue = calculatedDistance;
          finalDistanceSource = distanceSource;
          console.log(`[DEBUG] 🎯 Using Haversine: ${displayDistance}`);
        } else if (mapMyIndiaDistance !== null) {
          // Priority 2: Use MapMyIndia distance (assumed to be in meters)
          const distanceInKm = mapMyIndiaDistance / 1000;
          displayDistance = `${distanceInKm.toFixed(2)} km`;
          distanceValue = distanceInKm;
          finalDistanceSource = 'MapMyIndia API';
          console.log(`[DEBUG] 🎯 Using MapMyIndia distance: ${displayDistance}`);
        } else if (centerLat && centerLng) {
          // Priority 3: Calculate from pincode center if we have center coords but no user coords
          const distanceFromPincode = calculateHaversineDistance(
            lat, lng, // pincode coordinates
            centerLat, centerLng
          );
          displayDistance = `~${distanceFromPincode.toFixed(2)} km`;
          distanceValue = distanceFromPincode;
          finalDistanceSource = 'Pincode Center Estimate';
          console.log(`[DEBUG] 🎯 Using pincode-based estimate: ${displayDistance}`);
        } else {
          console.log(`[DEBUG] ❌ No distance available from any source`);
        }

        console.log(`[DEBUG] Final distance: ${displayDistance} (source: ${finalDistanceSource})`);

        return {
          name: center.placeName || 'Unknown Center',
          address: center.placeAddress || 'Address not available',
          contact: center.contactNumber || 'Not Available',
          distance: displayDistance,
          distanceValue: distanceValue,
          distanceSource: finalDistanceSource,
          coordinates: {
            lat: centerLat,
            lng: centerLng
          }
        };
      })
    );

    // STEP 5: Sort by distance (centers with null distance go to end)
    const sortedCenters = centersWithDistances.sort((a, b) => {
      if (a.distanceValue === null && b.distanceValue === null) return 0;
      if (a.distanceValue === null) return 1;
      if (b.distanceValue === null) return -1;
      return a.distanceValue - b.distanceValue;
    });

    console.log(`[DEBUG] ✅ Returning ${sortedCenters.length} centers sorted by distance`);
    const sources = [...new Set(sortedCenters.map(c => c.distanceSource))];
    console.log(`[DEBUG] Distance sources used: ${sources.join(', ')}`);
    if (sortedCenters.length > 0 && sortedCenters[0].distanceValue !== null) {
      console.log(`[DEBUG] Distance range: ${sortedCenters[0].distanceValue.toFixed(2)} km to ${sortedCenters[sortedCenters.length-1]?.distanceValue?.toFixed(2)} km`);
    }

    res.json({
      searchLocation: { 
        lat, 
        lng, 
        pinCode, 
        source: "Gemini Coordinates" 
      },
      userLocation: userCoordinates ? {
        lat: userCoordinates.lat,
        lng: userCoordinates.lng,
        address: userAddress,
        source: "MapMyIndia Geocode"
      } : null,
      foundCenters: sortedCenters,
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

  if (error.message.includes('MapMyIndia')) {
    return res.status(500).json({
      error: 'Geocoding service temporarily unavailable. Please try again.'
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
        error: `Authentication failed: ${errorMessage}`
      });
    }

    return res.status(statusCode).json({ error: errorMessage });
  }

  res.status(500).json({
    error: 'An unexpected error occurred. Please try again.'
  });
}
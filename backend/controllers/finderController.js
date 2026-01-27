// controllers/finderController.js
import axios from 'axios';
import https from 'https';
import { getMapMyIndiaToken } from './mapMyIndiaAuth.js';

const httpsAgent = new https.Agent({ family: 4 });

// --- HELPERS ---

/**
 * Calculates straight-line distance (Haversine)
 */
function calculateHaversineDistance(lat1, lon1, lat2, lon2) {
  const toRad = (d) => (d * Math.PI) / 180;
  const R = 6371; // Earth radius in km

  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;

  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * 1. Get Coordinates for Pincode (Critical for OSM search)
 * Uses MapMyIndia first (User has keys), falls back to OpenStreetMap Nominatim
 */
async function getCoordinatesForPincode(pinCode) {
  try {
    // Try MapMyIndia first (Best for India)
    const token = await getMapMyIndiaToken();
    const mmiRes = await axios.get(
      "https://atlas.mapmyindia.com/api/places/geocode",
      {
        params: { address: pinCode, itemCount: 1 },
        headers: { Authorization: `Bearer ${token}` },
        httpsAgent,
        timeout: 5000
      }
    );
    
    if (mmiRes.data?.copResults?.[0]) {
      const res = mmiRes.data.copResults[0];
      return { 
        lat: parseFloat(res.latitude || res.lat), 
        lng: parseFloat(res.longitude || res.lng),
        source: 'MapMyIndia'
      };
    }
  } catch (e) {
    console.warn("MMI Geocode failed, trying Nominatim...");
  }

  try {
    // Fallback: OSM Nominatim (Free, no key)
    const nomRes = await axios.get('https://nominatim.openstreetmap.org/search', {
      params: {
        postalcode: pinCode,
        country: 'India',
        format: 'json',
        limit: 1
      },
      headers: { 'User-Agent': 'VaccineApp/1.0' }, // Required by OSM
      timeout: 5000
    });

    if (nomRes.data?.[0]) {
      return { 
        lat: parseFloat(nomRes.data[0].lat), 
        lng: parseFloat(nomRes.data[0].lon),
        source: 'OSM Nominatim'
      };
    }
  } catch (e) {
    console.error("Geocoding failed completely:", e.message);
  }

  return null;
}

/**
 * 2. Fetch Hospitals from OpenStreetMap (Overpass API)
 * Queries for hospitals and vaccination centers around a point
 */
async function fetchFromOpenStreetMap(lat, lng, radius = 5000) {
  console.log(`[DEBUG] 🌍 Querying OpenStreetMap around ${lat}, ${lng}...`);
  
  // Overpass QL Query: Find nodes/ways with amenity=hospital OR healthcare=vaccination_centre
  const query = `
    [out:json][timeout:50];
    (
      node["amenity"="hospital"](around:${radius},${lat},${lng});
      way["amenity"="hospital"](around:${radius},${lat},${lng});
      node["healthcare"="vaccination_centre"](around:${radius},${lat},${lng});
      node["medical_specialty"="vaccination"](around:${radius},${lat},${lng});
    );
    out center body;
  >;
    out skel qt;
  `;

  try {
    const response = await axios.post(
      'https://overpass-api.de/api/interpreter',
      query, // Send raw query string in body
      { headers: { 'Content-Type': 'text/plain' }, timeout: 10000 }
    );

    const elements = response.data.elements || [];
    
    // Filter and normalize
    return elements
      .filter(el => el.tags && (el.tags.name || el.tags['name:en'])) // Only keep places with names
      .map(el => {
        // Extract useful tags
        const name = el.tags.name || el.tags['name:en'];
        const street = el.tags['addr:street'] || el.tags['addr:full'] || '';
        const city = el.tags['addr:city'] || '';
        const phone = el.tags['contact:phone'] || el.tags.phone || '';
        
        // Coordinates (use center for 'ways' which are buildings)
        const elLat = el.lat || el.center?.lat;
        const elLng = el.lon || el.center?.lon;

        return {
          name: name,
          address: `${street} ${city}`.trim() || "Address available on map",
          contact: phone,
          // OSM doesn't give slots, so we return generic info
          vaccine: "N/A",
          minAge: 0,
          feeType: "Walk-in Inquiry",
          availableCapacity: 0,
          lat: elLat,
          lng: elLng,
          source: "OpenStreetMap"
        };
      });
  } catch (error) {
    console.error("OSM Overpass Error:", error.message);
    return [];
  }
}

// --- MAIN CONTROLLER ---

export const findCenters = async (req, res) => {
  const { pinCode, date, userAddress } = req.query;

  if (!pinCode) {
    return res.status(400).json({ error: "pinCode is required" });
  }

  const queryDate = date || new Date().toLocaleDateString("en-GB").split("/").join("-");
  let results = [];
  let locationData = null;
  let userCoords = null; // For exact distance calculation if address provided

  try {
    // ---------------------------------------------------------
    // STEP 1: RESOLVE LOCATION (Crucial for OSM Fallback)
    // ---------------------------------------------------------
    locationData = await getCoordinatesForPincode(pinCode);
    
    // If user provided a specific address string, try to geocode that too for better distance
    if (userAddress) {
       // Reuse the existing helper or token for this specific user address
       // (Simplifying here to just use the pincode center to save API calls)
       userCoords = locationData; 
    }

    // ---------------------------------------------------------
    // STEP 2: TRY COWIN (Primary Source)
    // ---------------------------------------------------------
    try {
      console.log(`[DEBUG] 🏥 Trying CoWIN for ${pinCode}...`);
      const cowinRes = await axios.get(
        "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/findByPin",
        {
          params: { pincode: pinCode, date: queryDate },
          headers: {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36"
          },
          httpsAgent,
          timeout: 4000 // Fast fail
        }
      );

      const sessions = cowinRes.data?.sessions || [];
      if (sessions.length > 0) {
        results = sessions.map(s => ({
          name: s.name,
          address: `${s.address}, ${s.district_name}`,
          contact: "CoWIN Portal",
          vaccine: s.vaccine,
          feeType: s.fee_type,
          availableCapacity: s.available_capacity,
          // CoWIN doesn't give lat/lng in findByPin, so we can't calc exact distance
          distance: "Approx. (Pincode match)",
          distanceValue: null,
          source: "CoWIN"
        }));
      }
    } catch (e) {
      console.warn("CoWIN failed or blocked:", e.message);
    }

    // ---------------------------------------------------------
    // STEP 3: OSM FALLBACK (If CoWIN empty)
    // ---------------------------------------------------------
    if (results.length === 0 && locationData) {
      console.log(`[DEBUG] ⚠️ CoWIN empty. Switching to OpenStreetMap...`);
      const osmHospitals = await fetchFromOpenStreetMap(locationData.lat, locationData.lng);
      
      // Calculate distances for OSM results
      results = osmHospitals.map(h => {
        let distStr = "Near Pincode Center";
        let distVal = null;

        if (locationData && h.lat && h.lng) {
          distVal = calculateHaversineDistance(locationData.lat, locationData.lng, h.lat, h.lng);
          distStr = `${distVal.toFixed(2)} km`;
        }

        return {
          name: h.name,
          address: h.address,
          contact: h.contact || "Check local listing",
          vaccine: "Check Availability",
          feeType: "Contact Hospital",
          availableCapacity: 0,
          distance: distStr,
          distanceValue: distVal,
          source: "OpenStreetMap",
          coordinates: { lat: h.lat, lng: h.lng }
        };
      });
      
      // Sort by distance
      results.sort((a, b) => (a.distanceValue || 999) - (b.distanceValue || 999));
    }

    // ---------------------------------------------------------
    // RESPONSE
    // ---------------------------------------------------------
    if (results.length === 0) {
      return res.status(200).json({
        message: "No centers found via CoWIN or OpenStreetMap.",
        search: { pinCode, date: queryDate },
        centers: []
      });
    }

    return res.json({
      search: { pinCode, date: queryDate },
      userLocation: locationData ? { coordinates: locationData, source: locationData.source } : null,
      centers: results
    });

  } catch (error) {
    console.error("Critical Finder Error:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
};
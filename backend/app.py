"""
AgriSmartAI Backend API — Complete implementation
Flask HTTP server: detection, notifications, weather, analytics, farmer management
No FastAPI. No external LLM APIs.
"""
import io
import json
import os
import random
import uuid
from datetime import datetime, timedelta

import requests as http_requests
from dotenv import load_dotenv
from flask import Flask, jsonify, request, Response
from flask_cors import CORS

load_dotenv()

app = Flask(__name__)
CORS(app, origins='*')

# ── In-memory stores ──────────────────────────────────────────────────────────
# These can be replaced by PostgreSQL calls (psycopg2) without changing the API.
_farmers: list[dict] = []
_scans: list[dict] = []
_notifications: list[dict] = []      # Farmer notifications
_admin_notifications: list[dict] = []  # Admin notifications
_weather_cache: dict = {'data': None, 'expires': datetime.min}

# ── Disease metadata ──────────────────────────────────────────────────────────
DISEASE_INFO: dict[str, dict] = {
    'Bacterial Leaf Blight': {
        'severity': 'High', 'color': '#E53935',
        'treatment': ('Apply copper-based bactericides (e.g., Copper Hydroxide). '
                      'Remove infected plants. Improve field drainage.'),
        'prevention': ('Use resistant varieties (IR64, PSB Rc18). '
                       'Avoid excessive nitrogen. Ensure proper plant spacing.'),
    },
    'Brown Spot': {
        'severity': 'Medium', 'color': '#795548',
        'treatment': ('Apply Mancozeb or Propiconazole fungicide. '
                      'Improve soil nutrition with balanced NPK.'),
        'prevention': ('Balanced fertilizer especially potassium. '
                       'Proper water management — avoid drought stress.'),
    },
    'Leaf Blast': {
        'severity': 'High', 'color': '#FF6F00',
        'treatment': ('Apply tricyclazole or isoprothiolane fungicide immediately. '
                      'Avoid excessive nitrogen fertilizer.'),
        'prevention': ('Use blast-resistant varieties (NSIC Rc222). '
                       'Monitor during tillering and panicle initiation.'),
    },
    'Sheath Blight': {
        'severity': 'Medium', 'color': '#7B1FA2',
        'treatment': ('Apply validamycin or hexaconazole fungicide. '
                      'Reduce plant density. Drain field periodically.'),
        'prevention': ('Wider plant spacing for air circulation. '
                       'Remove crop debris after harvest.'),
    },
    'Tungro Virus': {
        'severity': 'High', 'color': '#F57F17',
        'treatment': ('No direct cure. Remove infected plants immediately. '
                      'Control green leafhopper using imidacloprid.'),
        'prevention': ('Plant tungro-resistant varieties (IR36, NSIC Rc222). '
                       'Synchronize planting to break vector cycle.'),
    },
    'Healthy': {
        'severity': 'None', 'color': '#2E7D32',
        'treatment': 'No treatment needed. Continue regular field monitoring.',
        'prevention': ('Maintain proper irrigation, balanced fertilization, '
                       'and integrated pest management.'),
    },
}

# Weather code → condition description (WMO codes)
_WMO_CONDITIONS = {
    0: 'Clear Sky', 1: 'Mainly Clear', 2: 'Partly Cloudy', 3: 'Overcast',
    45: 'Foggy', 48: 'Icy Fog',
    51: 'Light Drizzle', 53: 'Drizzle', 55: 'Heavy Drizzle',
    61: 'Slight Rain', 63: 'Moderate Rain', 65: 'Heavy Rain',
    71: 'Slight Snow', 73: 'Moderate Snow', 75: 'Heavy Snow',
    77: 'Snow Grains',
    80: 'Slight Showers', 81: 'Moderate Showers', 82: 'Heavy Showers',
    85: 'Slight Snow Showers', 86: 'Heavy Snow Showers',
    95: 'Thunderstorm', 96: 'Thunderstorm with Hail', 99: 'Heavy Thunderstorm',
}

WEATHER_CACHE_TTL = 900   # 15 minutes
NEW_BATAAN_LAT = 7.49
NEW_BATAAN_LON = 126.18


# ── Helpers ───────────────────────────────────────────────────────────────────

def _now_iso() -> str:
    return datetime.now().isoformat()


def _parse_dt(value) -> datetime:
    try:
        return datetime.fromisoformat(str(value))
    except (ValueError, TypeError):
        return datetime.min


def _paginate(items: list, page: int, per_page: int) -> dict:
    total = len(items)
    start = (page - 1) * per_page
    end = start + per_page
    return {
        'items': items[start:end],
        'total': total,
        'page': page,
        'per_page': per_page,
        'pages': max(1, (total + per_page - 1) // per_page),
    }


def _make_admin_notif(title: str, body: str, ntype: str, data: dict = None) -> dict:
    n = {
        'id': str(uuid.uuid4()),
        'title': title,
        'body': body,
        'type': ntype,
        'created_at': _now_iso(),
        'is_read': False,
        'data': data or {},
    }
    _admin_notifications.insert(0, n)
    # Keep latest 200 admin notifications
    if len(_admin_notifications) > 200:
        _admin_notifications.pop()
    return n


def _get_farmer_by_id(farmer_id: str) -> dict | None:
    return next((f for f in _farmers if f['id'] == farmer_id), None)


# ── Weather service ───────────────────────────────────────────────────────────

def fetch_weather() -> dict:
    """Fetch current weather for New Bataan. Cached for 15 minutes."""
    now = datetime.now()
    if _weather_cache['data'] and now < _weather_cache['expires']:
        return _weather_cache['data']

    url = (
        f'https://api.open-meteo.com/v1/forecast'
        f'?latitude={NEW_BATAAN_LAT}&longitude={NEW_BATAAN_LON}'
        f'&current=temperature_2m,relative_humidity_2m,'
        f'precipitation_probability,wind_speed_10m,weather_code'
        f'&timezone=Asia%2FManila'
    )
    try:
        resp = http_requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        cur = data.get('current', {})
        code = int(cur.get('weather_code', 0))
        weather = {
            'temperature': round(cur.get('temperature_2m', 29.0), 1),
            'humidity': int(cur.get('relative_humidity_2m', 75)),
            'precipitation_probability': int(cur.get('precipitation_probability', 30)),
            'wind_speed': round(cur.get('wind_speed_10m', 10.0), 1),
            'weather_code': code,
            'condition': _WMO_CONDITIONS.get(code, 'Variable'),
            'location': 'New Bataan, Davao de Oro',
            'updated_at': now.isoformat(),
            'source': 'open-meteo',
        }
        _weather_cache['data'] = weather
        _weather_cache['expires'] = now + timedelta(seconds=WEATHER_CACHE_TTL)

        # Auto-create weather alert if severe conditions
        if cur.get('precipitation_probability', 0) > 80 or code in [65, 82, 95, 96, 99]:
            _make_admin_notif(
                '⛈ Severe Weather Alert',
                f"Heavy rain or thunderstorm predicted for New Bataan ({weather['condition']}). "
                f'Rainfall probability: {weather["precipitation_probability"]}%. '
                'Advise farmers to protect crops and delay spraying.',
                'weatherAlert',
                {'weather': weather},
            )
        return weather
    except Exception:
        # Fallback / previously cached
        if _weather_cache['data']:
            return _weather_cache['data']
        fallback = {
            'temperature': 29.5, 'humidity': 78, 'precipitation_probability': 35,
            'wind_speed': 12.0, 'weather_code': 2, 'condition': 'Partly Cloudy',
            'location': 'New Bataan, Davao de Oro',
            'updated_at': now.isoformat(), 'source': 'fallback',
        }
        _weather_cache['data'] = fallback
        _weather_cache['expires'] = now + timedelta(seconds=60)
        return fallback


# ── Demo data seed ────────────────────────────────────────────────────────────

def _seed_demo_data():
    diseases = list(DISEASE_INFO.keys())
    weights = [0.30, 0.16, 0.18, 0.12, 0.06, 0.18]  # Healthy last
    barangays = ['Binuangan', 'Cabaywa', 'Mabuhay', 'Poblacion', 'Tandaw',
                 'Andap', 'Camanlangan', 'Cawag', 'Mahayahay', 'Malinao']
    conditions = ['Clear Sky', 'Partly Cloudy', 'Moderate Rain', 'Overcast', 'Drizzle']

    sample_farmers = [
        {'id': str(uuid.uuid4()), 'name': 'Juan Santos',
         'email': 'juan.santos@example.com', 'phone': '09171234567',
         'barangay': 'Binuangan', 'address': 'Purok 2, Binuangan, New Bataan',
         'registration_date': (datetime.now() - timedelta(days=120)).isoformat()},
        {'id': str(uuid.uuid4()), 'name': 'Maria Reyes',
         'email': 'maria.reyes@example.com', 'phone': '09181234567',
         'barangay': 'Cabaywa', 'address': 'Purok 1, Cabaywa, New Bataan',
         'registration_date': (datetime.now() - timedelta(days=90)).isoformat()},
        {'id': str(uuid.uuid4()), 'name': 'Pedro Dela Cruz',
         'email': 'pedro.delacruz@example.com', 'phone': '09191234567',
         'barangay': 'Mabuhay', 'address': 'Purok 3, Mabuhay, New Bataan',
         'registration_date': (datetime.now() - timedelta(days=60)).isoformat()},
        {'id': str(uuid.uuid4()), 'name': 'Rosa Lim',
         'email': 'rosa.lim@example.com', 'phone': '09201234567',
         'barangay': 'Poblacion', 'address': 'Purok 5, Poblacion, New Bataan',
         'registration_date': (datetime.now() - timedelta(days=45)).isoformat()},
        {'id': str(uuid.uuid4()), 'name': 'Carlos Gutierrez',
         'email': 'carlos.gutierrez@example.com', 'phone': '09211234567',
         'barangay': 'Tandaw', 'address': 'Purok 4, Tandaw, New Bataan',
         'registration_date': (datetime.now() - timedelta(days=30)).isoformat()},
        {'id': str(uuid.uuid4()), 'name': 'Ana Villanueva',
         'email': 'ana.villanueva@example.com', 'phone': '09221234567',
         'barangay': 'Andap', 'address': 'Purok 1, Andap, New Bataan',
         'registration_date': (datetime.now() - timedelta(days=20)).isoformat()},
        {'id': str(uuid.uuid4()), 'name': 'Roberto Cruz',
         'email': 'roberto.cruz@example.com', 'phone': '09231234567',
         'barangay': 'Camanlangan', 'address': 'Purok 2, Camanlangan, New Bataan',
         'registration_date': (datetime.now() - timedelta(days=15)).isoformat()},
    ]
    _farmers.extend(sample_farmers)

    for i in range(80):
        farmer = random.choice(sample_farmers)
        disease = random.choices(diseases, weights=weights)[0]
        info = DISEASE_INFO[disease]
        scan_time = datetime.now() - timedelta(
            days=random.randint(0, 29), hours=random.randint(0, 23),
            minutes=random.randint(0, 59))
        scan = {
            'id': str(uuid.uuid4()),
            'farmer_id': farmer['id'],
            'farmer_name': farmer['name'],
            'farmer_barangay': farmer['barangay'],
            'disease': disease,
            'confidence': round(random.uniform(75, 97), 1),
            'severity': info['severity'],
            'color': info['color'],
            'treatment': info['treatment'],
            'prevention': info['prevention'],
            'status': 'reviewed' if random.random() > 0.35 else 'pending',
            'created_at': scan_time.isoformat(),
            'weather_temp': round(random.uniform(24, 35), 1),
            'weather_humidity': random.randint(60, 96),
            'weather_precip': random.randint(0, 85),
            'weather_condition': random.choice(conditions),
        }
        _scans.append(scan)

    _scans.sort(key=lambda x: x['created_at'], reverse=True)

    # Seed admin notifications from scans
    for scan in _scans[:15]:
        is_disease = scan['disease'] != 'Healthy'
        _admin_notifications.append({
            'id': str(uuid.uuid4()),
            'title': f"New Scan: {scan['disease']}" if is_disease else 'New Healthy Scan Submitted',
            'body': (f"{scan['farmer_name']} ({scan['farmer_barangay']}) scanned a leaf. "
                     f"Disease: {scan['disease']} with {scan['confidence']}% confidence."),
            'type': 'diseaseAlert' if is_disease else 'newScan',
            'created_at': scan['created_at'],
            'is_read': random.random() > 0.5,
            'data': {'scan_id': scan['id'], 'farmer_id': scan['farmer_id']},
        })
    _admin_notifications.sort(key=lambda x: x['created_at'], reverse=True)

    # Seed a weather alert
    _admin_notifications.insert(0, {
        'id': str(uuid.uuid4()),
        'title': '🌧 Weather Advisory',
        'body': 'Moderate to heavy rain expected in New Bataan area this week. '
                'High Leaf Blast risk. Advise farmers to apply preventive fungicide.',
        'type': 'weatherAlert',
        'created_at': _now_iso(),
        'is_read': False,
        'data': {},
    })


_seed_demo_data()


# ═══════════════════════════════════════════════════════════════════════════════
# API ROUTES
# ═══════════════════════════════════════════════════════════════════════════════

# ── Health ────────────────────────────────────────────────────────────────────

@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'timestamp': _now_iso()})


# ── Weather ───────────────────────────────────────────────────────────────────

@app.route('/api/weather', methods=['GET'])
def get_weather():
    """
    Returns current weather for New Bataan, Davao de Oro.
    Cached for 15 minutes. Source: Open-Meteo (free, no API key required).
    """
    weather = fetch_weather()
    return jsonify(weather)


# ── Disease detection ─────────────────────────────────────────────────────────

@app.route('/api/detect', methods=['POST'])
def detect():
    """
    POST multipart/form-data with field 'image' (JPEG/PNG).
    Optional fields: farmer_id, weather_temp, weather_humidity,
                     weather_precip, weather_condition
    Returns DiseaseResult with id, disease, confidence, severity, treatment, etc.
    """
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided (field name: image)'}), 400
    image_bytes = request.files['image'].read()
    if not image_bytes:
        return jsonify({'error': 'Empty image file'}), 400

    from ai_model.simulate_detection import detect_disease
    disease, confidence = detect_disease(image_bytes)
    info = DISEASE_INFO.get(disease, DISEASE_INFO['Healthy'])

    # Attach weather context if provided by mobile app
    weather_temp = request.form.get('weather_temp', type=float)
    weather_humidity = request.form.get('weather_humidity', type=int)
    weather_precip = request.form.get('weather_precip', type=int)
    weather_condition = request.form.get('weather_condition', 'Unknown')

    # Fall back to cached weather if not provided
    if weather_temp is None:
        cached = _weather_cache.get('data') or {}
        weather_temp = cached.get('temperature', 29.0)
        weather_humidity = cached.get('humidity', 75)
        weather_precip = cached.get('precipitation_probability', 30)
        weather_condition = cached.get('condition', 'Unknown')

    farmer_id = request.form.get('farmer_id', '')
    farmer = _get_farmer_by_id(farmer_id) if farmer_id else None

    result_id = str(uuid.uuid4())
    result = {
        'id': result_id,
        'farmer_id': farmer_id,
        'farmer_name': farmer['name'] if farmer else 'Unknown Farmer',
        'farmer_barangay': farmer['barangay'] if farmer else '',
        'disease': disease,
        'confidence': round(confidence * 100, 1),
        'severity': info['severity'],
        'color': info['color'],
        'treatment': info['treatment'],
        'prevention': info['prevention'],
        'status': 'pending',
        'created_at': _now_iso(),
        'weather_temp': weather_temp,
        'weather_humidity': weather_humidity,
        'weather_precip': weather_precip,
        'weather_condition': weather_condition,
    }
    _scans.insert(0, result)

    is_disease = disease != 'Healthy'
    farmer_name = farmer['name'] if farmer else 'A farmer'

    # Farmer notification
    farmer_notif = {
        'id': str(uuid.uuid4()),
        'title': 'Disease Detected!' if is_disease else 'Scan Complete — Healthy',
        'body': (f"{disease} detected with {result['confidence']}% confidence. "
                 f"Severity: {info['severity']}. See treatment recommendations."
                 if is_disease else
                 'Your rice crop appears healthy. Keep up the good work!'),
        'type': 'diseaseAlert' if is_disease else 'system',
        'createdAt': _now_iso(), 'isRead': False,
        'data': {'resultId': result_id, 'disease': disease},
    }
    _notifications.insert(0, farmer_notif)

    # Admin notification for every new scan
    _make_admin_notif(
        f"New Scan: {disease}",
        (f"{farmer_name} submitted a scan. "
         f"Disease: {disease} ({result['confidence']}% confidence). "
         f"Weather: {weather_condition}, {weather_temp}°C."),
        'diseaseAlert' if is_disease else 'newScan',
        {'scan_id': result_id, 'farmer_id': farmer_id},
    )

    # Weather-based risk auto-alert for admin
    if is_disease and weather_humidity and weather_humidity > 88:
        _make_admin_notif(
            '⚠ High-Risk Disease Detected',
            (f"{disease} detected under high-humidity conditions ({weather_humidity}%). "
             f"Risk of rapid spread. Immediate action recommended in "
             f"{farmer['barangay'] if farmer else 'New Bataan'}."),
            'highRisk',
            {'scan_id': result_id, 'disease': disease},
        )

    return jsonify(result)


@app.route('/api/scans', methods=['GET'])
def get_scans():
    """
    GET /api/scans?page=1&per_page=20&disease=<name>&farmer_id=<id>
                   &date_from=<ISO>&date_to=<ISO>&sort=newest
    """
    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 20, type=int), 100)
    disease_filter = request.args.get('disease', '')
    farmer_filter = request.args.get('farmer_id', '')
    date_from = request.args.get('date_from', '')
    date_to = request.args.get('date_to', '')
    sort = request.args.get('sort', 'newest')
    search = request.args.get('search', '').lower()

    filtered = list(_scans)
    if disease_filter:
        filtered = [s for s in filtered if s['disease'] == disease_filter]
    if farmer_filter:
        filtered = [s for s in filtered if s.get('farmer_id') == farmer_filter]
    if date_from:
        filtered = [s for s in filtered if _parse_dt(s['created_at']) >= _parse_dt(date_from)]
    if date_to:
        filtered = [s for s in filtered if _parse_dt(s['created_at']) <= _parse_dt(date_to)]
    if search:
        filtered = [s for s in filtered if
                    search in s.get('farmer_name', '').lower() or
                    search in s.get('disease', '').lower() or
                    search in s.get('farmer_barangay', '').lower()]

    if sort == 'oldest':
        filtered.sort(key=lambda x: x['created_at'])
    else:
        filtered.sort(key=lambda x: x['created_at'], reverse=True)

    return jsonify(_paginate(filtered, page, per_page))


@app.route('/api/scans/<scan_id>', methods=['GET'])
def get_scan(scan_id: str):
    scan = next((s for s in _scans if s['id'] == scan_id), None)
    if not scan:
        return jsonify({'error': 'Scan not found'}), 404
    return jsonify(scan)


# ── Farmers ───────────────────────────────────────────────────────────────────

@app.route('/api/farmers', methods=['GET'])
def get_farmers():
    """
    GET /api/farmers?page=1&per_page=10&search=<name>&barangay=<name>
    """
    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 10, type=int), 50)
    search = request.args.get('search', '').lower()
    barangay = request.args.get('barangay', '')

    filtered = list(_farmers)
    if search:
        filtered = [f for f in filtered if
                    search in f['name'].lower() or
                    search in f.get('email', '').lower() or
                    search in f.get('barangay', '').lower()]
    if barangay:
        filtered = [f for f in filtered if f.get('barangay') == barangay]

    # Enrich with scan stats
    enriched = []
    for farmer in filtered:
        farmer_scans = [s for s in _scans if s.get('farmer_id') == farmer['id']]
        diseased = [s for s in farmer_scans if s['disease'] != 'Healthy']
        enriched.append({
            **farmer,
            'total_scans': len(farmer_scans),
            'diseased_scans': len(diseased),
            'last_scan': farmer_scans[0]['created_at'] if farmer_scans else None,
            'last_disease': farmer_scans[0]['disease'] if farmer_scans else None,
        })

    return jsonify(_paginate(enriched, page, per_page))


@app.route('/api/farmers', methods=['POST'])
def create_farmer():
    data = request.get_json(silent=True) or {}
    # Validate required fields
    for field in ['name', 'email']:
        if not data.get(field, '').strip():
            return jsonify({'error': f'{field} is required'}), 400
    if any(f['email'] == data['email'] for f in _farmers):
        return jsonify({'error': 'Email already registered'}), 409

    farmer = {
        'id': str(uuid.uuid4()),
        'name': data['name'].strip(),
        'email': data['email'].strip().lower(),
        'phone': data.get('phone', '').strip(),
        'barangay': data.get('barangay', '').strip(),
        'address': data.get('address', '').strip(),
        'registration_date': _now_iso(),
    }
    _farmers.insert(0, farmer)
    _make_admin_notif(
        'New Farmer Registered',
        f"{farmer['name']} from {farmer.get('barangay', 'New Bataan')} registered.",
        'system', {'farmer_id': farmer['id']},
    )
    return jsonify(farmer), 201


@app.route('/api/farmers/<farmer_id>', methods=['GET'])
def get_farmer(farmer_id: str):
    farmer = _get_farmer_by_id(farmer_id)
    if not farmer:
        return jsonify({'error': 'Farmer not found'}), 404
    farmer_scans = [s for s in _scans if s.get('farmer_id') == farmer_id]
    diseased = [s for s in farmer_scans if s['disease'] != 'Healthy']
    return jsonify({
        **farmer,
        'total_scans': len(farmer_scans),
        'diseased_scans': len(diseased),
        'healthy_scans': len(farmer_scans) - len(diseased),
        'last_scan': farmer_scans[0]['created_at'] if farmer_scans else None,
    })


@app.route('/api/farmers/<farmer_id>', methods=['PUT'])
def update_farmer(farmer_id: str):
    farmer = _get_farmer_by_id(farmer_id)
    if not farmer:
        return jsonify({'error': 'Farmer not found'}), 404
    data = request.get_json(silent=True) or {}
    for field in ['name', 'email', 'phone', 'barangay', 'address']:
        if field in data:
            farmer[field] = str(data[field]).strip()
    return jsonify(farmer)


@app.route('/api/farmers/<farmer_id>', methods=['DELETE'])
def delete_farmer(farmer_id: str):
    global _farmers
    if not _get_farmer_by_id(farmer_id):
        return jsonify({'error': 'Farmer not found'}), 404
    _farmers = [f for f in _farmers if f['id'] != farmer_id]
    return jsonify({'deleted': farmer_id})


@app.route('/api/farmers/<farmer_id>/scans', methods=['GET'])
def get_farmer_scans(farmer_id: str):
    """
    GET /api/farmers/<id>/scans?page=1&per_page=10&disease=<name>
                                &date_from=<ISO>&date_to=<ISO>&sort=newest&search=<q>
    """
    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 10, type=int), 50)
    disease_filter = request.args.get('disease', '')
    date_from = request.args.get('date_from', '')
    date_to = request.args.get('date_to', '')
    sort = request.args.get('sort', 'newest')
    search = request.args.get('search', '').lower()

    filtered = [s for s in _scans if s.get('farmer_id') == farmer_id]
    if disease_filter:
        filtered = [s for s in filtered if s['disease'] == disease_filter]
    if date_from:
        filtered = [s for s in filtered if _parse_dt(s['created_at']) >= _parse_dt(date_from)]
    if date_to:
        filtered = [s for s in filtered if _parse_dt(s['created_at']) <= _parse_dt(date_to)]
    if search:
        filtered = [s for s in filtered if
                    search in s.get('disease', '').lower() or
                    search in s.get('weather_condition', '').lower()]
    if sort == 'oldest':
        filtered.sort(key=lambda x: x['created_at'])
    else:
        filtered.sort(key=lambda x: x['created_at'], reverse=True)

    return jsonify(_paginate(filtered, page, per_page))


# ── Analytics ─────────────────────────────────────────────────────────────────

@app.route('/api/analytics/overview', methods=['GET'])
def analytics_overview():
    """Dashboard stats: total scans, farmers, active scans, disease breakdown."""
    total = len(_scans)
    diseased = sum(1 for s in _scans if s['disease'] != 'Healthy')
    now = datetime.now()
    active = sum(1 for s in _scans if (now - _parse_dt(s['created_at'])).total_seconds() < 86400)

    disease_breakdown: dict[str, int] = {}
    for s in _scans:
        d = s['disease']
        disease_breakdown[d] = disease_breakdown.get(d, 0) + 1

    most_common = sorted(disease_breakdown.items(), key=lambda x: x[1], reverse=True)

    return jsonify({
        'total_scans': total,
        'total_farmers': len(_farmers),
        'active_scans_24h': active,
        'diseased_scans': diseased,
        'healthy_scans': total - diseased,
        'detection_rate': round(diseased / total * 100, 1) if total else 0,
        'disease_breakdown': disease_breakdown,
        'most_common_disease': most_common[0][0] if most_common else 'N/A',
        'most_common_count': most_common[0][1] if most_common else 0,
        'admin_unread': sum(1 for n in _admin_notifications if not n['is_read']),
    })


@app.route('/api/analytics/trends', methods=['GET'])
def analytics_trends():
    """Daily scan counts by disease for the last 30 days."""
    days = request.args.get('days', 30, type=int)
    cutoff = datetime.now() - timedelta(days=days)
    relevant = [s for s in _scans if _parse_dt(s['created_at']) >= cutoff]

    daily: dict[str, dict] = {}
    for scan in relevant:
        date_key = _parse_dt(scan['created_at']).date().isoformat()
        if date_key not in daily:
            daily[date_key] = {'date': date_key, 'total': 0}
        daily[date_key]['total'] += 1
        d = scan['disease']
        daily[date_key][d] = daily[date_key].get(d, 0) + 1

    # Fill missing dates with zeroes
    result = []
    for i in range(days):
        date_key = (datetime.now() - timedelta(days=days - 1 - i)).date().isoformat()
        result.append(daily.get(date_key, {'date': date_key, 'total': 0}))

    return jsonify(result)


@app.route('/api/analytics/monthly', methods=['GET'])
def analytics_monthly():
    """Monthly scan totals and disease breakdown for the last 6 months."""
    months = 6
    result = []
    for i in range(months - 1, -1, -1):
        ref = datetime.now().replace(day=1) - timedelta(days=i * 30)
        label = ref.strftime('%b %Y')
        month_scans = [
            s for s in _scans
            if _parse_dt(s['created_at']).month == ref.month
            and _parse_dt(s['created_at']).year == ref.year
        ]
        breakdown: dict[str, int] = {}
        for s in month_scans:
            d = s['disease']
            breakdown[d] = breakdown.get(d, 0) + 1
        result.append({
            'label': label,
            'year': ref.year,
            'month': ref.month,
            'total': len(month_scans),
            'diseased': sum(1 for s in month_scans if s['disease'] != 'Healthy'),
            'healthy': sum(1 for s in month_scans if s['disease'] == 'Healthy'),
            'breakdown': breakdown,
        })
    return jsonify(result)


@app.route('/api/analytics/predictions', methods=['GET'])
def analytics_predictions():
    """Disease outbreak risk predictions based on weather and recent scan history."""
    weather = fetch_weather()
    from ai_model.predict import predict_disease_risk
    predictions = predict_disease_risk(weather, _scans)
    return jsonify({
        'predictions': predictions,
        'weather': weather,
        'generated_at': _now_iso(),
    })


@app.route('/api/analytics/most-common', methods=['GET'])
def analytics_most_common():
    """Top diseases by detection count."""
    limit = request.args.get('limit', 5, type=int)
    counts: dict[str, int] = {}
    for s in _scans:
        d = s['disease']
        counts[d] = counts.get(d, 0) + 1
    sorted_counts = sorted(counts.items(), key=lambda x: x[1], reverse=True)
    total = sum(counts.values()) or 1
    return jsonify([
        {
            'disease': name,
            'count': count,
            'percentage': round(count / total * 100, 1),
            'color': DISEASE_INFO.get(name, {}).get('color', '#2E7D32'),
        }
        for name, count in sorted_counts[:limit]
    ])


# ── Farmer notifications (mobile app) ─────────────────────────────────────────

@app.route('/api/notifications', methods=['GET'])
def get_notifications():
    farmer_id = request.args.get('farmer_id', '')
    items = [n for n in _notifications if
             not farmer_id or n.get('data', {}).get('farmerId') == farmer_id]
    return jsonify(items)


@app.route('/api/notifications', methods=['POST'])
def create_notification():
    data = request.get_json(silent=True) or {}
    notif = {
        'id': str(uuid.uuid4()), 'title': data.get('title', ''),
        'body': data.get('body', ''), 'type': data.get('type', 'system'),
        'createdAt': _now_iso(), 'isRead': False, 'data': data.get('data', {}),
    }
    _notifications.insert(0, notif)
    return jsonify(notif), 201


@app.route('/api/notifications/<notif_id>/read', methods=['PUT'])
def mark_farmer_notif_read(notif_id: str):
    for n in _notifications:
        if n['id'] == notif_id:
            n['isRead'] = True
            return jsonify(n)
    return jsonify({'error': 'Not found'}), 404


@app.route('/api/notifications/read-all', methods=['PUT'])
def mark_all_farmer_notifs_read():
    for n in _notifications:
        n['isRead'] = True
    return jsonify({'updated': len(_notifications)})


@app.route('/api/notifications/<notif_id>', methods=['DELETE'])
def delete_farmer_notif(notif_id: str):
    global _notifications
    _notifications = [n for n in _notifications if n['id'] != notif_id]
    return jsonify({'deleted': notif_id})


@app.route('/api/notifications', methods=['DELETE'])
def clear_farmer_notifications():
    _notifications.clear()
    return jsonify({'cleared': True})


# ── Admin notifications ────────────────────────────────────────────────────────

@app.route('/api/admin/notifications', methods=['GET'])
def get_admin_notifications():
    """
    GET /api/admin/notifications?page=1&per_page=20&type=<type>&unread=true
    Supports real-time polling — returns latest 200 notifications.
    """
    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 20, type=int), 100)
    ntype = request.args.get('type', '')
    unread_only = request.args.get('unread', 'false').lower() == 'true'
    since = request.args.get('since', '')  # ISO datetime — returns only newer items

    filtered = list(_admin_notifications)
    if ntype:
        filtered = [n for n in filtered if n['type'] == ntype]
    if unread_only:
        filtered = [n for n in filtered if not n['is_read']]
    if since:
        since_dt = _parse_dt(since)
        filtered = [n for n in filtered if _parse_dt(n['created_at']) > since_dt]

    unread_count = sum(1 for n in _admin_notifications if not n['is_read'])
    result = _paginate(filtered, page, per_page)
    result['unread_count'] = unread_count
    return jsonify(result)


@app.route('/api/admin/notifications/unread-count', methods=['GET'])
def admin_notif_unread_count():
    count = sum(1 for n in _admin_notifications if not n['is_read'])
    return jsonify({'count': count})


@app.route('/api/admin/notifications/<notif_id>/read', methods=['PUT'])
def mark_admin_notif_read(notif_id: str):
    for n in _admin_notifications:
        if n['id'] == notif_id:
            n['is_read'] = True
            return jsonify(n)
    return jsonify({'error': 'Not found'}), 404


@app.route('/api/admin/notifications/read-all', methods=['PUT'])
def mark_all_admin_read():
    for n in _admin_notifications:
        n['is_read'] = True
    return jsonify({'updated': len(_admin_notifications)})


@app.route('/api/admin/notifications/<notif_id>', methods=['DELETE'])
def delete_admin_notif(notif_id: str):
    global _admin_notifications
    _admin_notifications = [n for n in _admin_notifications if n['id'] != notif_id]
    return jsonify({'deleted': notif_id})


@app.route('/api/admin/notifications', methods=['DELETE'])
def clear_admin_notifications():
    _admin_notifications.clear()
    return jsonify({'cleared': True})


# ── Chat ──────────────────────────────────────────────────────────────────────

@app.route('/api/chat', methods=['POST'])
def chat():
    data = request.get_json(silent=True) or {}
    message = str(data.get('message', '')).strip()
    if not message:
        return jsonify({'error': 'message is required'}), 400
    from ai_model.agrismart_chat import get_response
    return jsonify({'response': get_response(message), 'timestamp': _now_iso()})


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8000))
    debug = os.getenv('DEBUG', 'True').lower() == 'true'
    print(f'\n  AgriSmartAI API  →  http://localhost:{port}\n')
    app.run(host='0.0.0.0', port=port, debug=debug)

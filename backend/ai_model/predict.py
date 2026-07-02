"""
Disease outbreak prediction engine.
Combines real-time weather data with 7-day scan history to score risk per disease.
"""
from datetime import datetime, timedelta


def predict_disease_risk(weather: dict, scan_history: list) -> list[dict]:
    """
    Return a list of predictions sorted by confidence (highest first).
    Each prediction: {disease, risk, confidence, factors, recommendation}
    """
    temp = weather.get('temperature', 28.0)
    humidity = weather.get('humidity', 75)
    precip = weather.get('precipitation_probability', 30)

    # Count recent disease detections in the last 7 days
    cutoff = datetime.now() - timedelta(days=7)
    recent = [
        s for s in scan_history
        if _parse_dt(s.get('created_at')) >= cutoff and s.get('disease') != 'Healthy'
    ]
    counts: dict[str, int] = {}
    for s in recent:
        d = s['disease']
        counts[d] = counts.get(d, 0) + 1

    predictions = [
        _predict_blast(temp, humidity, precip, counts),
        _predict_blb(temp, humidity, precip, counts),
        _predict_brown_spot(temp, humidity, counts),
        _predict_sheath_blight(temp, humidity, counts),
        _predict_tungro(temp, counts),
    ]
    return sorted(predictions, key=lambda x: x['confidence'], reverse=True)


def _parse_dt(value: str | None) -> datetime:
    try:
        return datetime.fromisoformat(value or '')
    except (ValueError, TypeError):
        return datetime.min


def _risk(score: int) -> str:
    if score >= 65:
        return 'High'
    if score >= 35:
        return 'Medium'
    return 'Low'


def _predict_blast(temp, humidity, precip, counts):
    score, factors = 0, []
    if 22 <= temp <= 30:
        score += 25; factors.append(f'Optimal temperature ({temp}°C)')
    if humidity > 85:
        score += 35; factors.append(f'Very high humidity ({humidity}%)')
    elif humidity > 75:
        score += 18; factors.append(f'High humidity ({humidity}%)')
    if precip > 55:
        score += 20; factors.append(f'High rainfall probability ({precip}%)')
    n = counts.get('Leaf Blast', 0)
    if n >= 3:
        score += 20; factors.append(f'{n} recent detections (last 7 days)')
    elif n:
        score += 10; factors.append(f'{n} recent detection')
    return {
        'disease': 'Leaf Blast',
        'risk': _risk(score),
        'confidence': min(score, 95),
        'factors': factors or ['Low environmental risk currently'],
        'recommendation': (
            'Apply tricyclazole or isoprothiolane fungicide preventively. '
            'Monitor fields daily during tillering. Avoid excessive nitrogen.'
        ),
    }


def _predict_blb(temp, humidity, precip, counts):
    score, factors = 0, []
    if temp > 30:
        score += 30; factors.append(f'High temperature ({temp}°C)')
    elif temp > 27:
        score += 14
    if humidity > 82:
        score += 25; factors.append(f'High humidity ({humidity}%)')
    if precip > 65:
        score += 22; factors.append(f'Heavy rain probability ({precip}%)')
    elif precip > 40:
        score += 10
    n = counts.get('Bacterial Leaf Blight', 0)
    if n >= 2:
        score += 20; factors.append(f'{n} recent detections')
    elif n:
        score += 8
    return {
        'disease': 'Bacterial Leaf Blight',
        'risk': _risk(score),
        'confidence': min(score, 95),
        'factors': factors or ['Low environmental risk currently'],
        'recommendation': (
            'Improve field drainage. Apply copper-based bactericides. '
            'Remove infected plants. Avoid flooding.'
        ),
    }


def _predict_brown_spot(temp, humidity, counts):
    score, factors = 0, []
    if humidity < 65:
        score += 35; factors.append(f'Drought stress risk (humidity {humidity}%)')
    if 25 <= temp <= 35:
        score += 15; factors.append(f'Warm temperature ({temp}°C)')
    n = counts.get('Brown Spot', 0)
    if n >= 2:
        score += 25; factors.append(f'{n} recent detections')
    elif n:
        score += 10
    return {
        'disease': 'Brown Spot',
        'risk': _risk(score),
        'confidence': min(score, 90),
        'factors': factors or ['Low environmental risk currently'],
        'recommendation': (
            'Apply balanced NPK fertilizer (especially potassium). '
            'Ensure consistent irrigation. Apply Mancozeb fungicide if symptoms appear.'
        ),
    }


def _predict_sheath_blight(temp, humidity, counts):
    score, factors = 0, []
    if temp > 28:
        score += 28; factors.append(f'High temperature ({temp}°C)')
    if humidity > 80:
        score += 28; factors.append(f'High humidity ({humidity}%)')
    n = counts.get('Sheath Blight', 0)
    if n >= 2:
        score += 22; factors.append(f'{n} recent detections')
    elif n:
        score += 10
    return {
        'disease': 'Sheath Blight',
        'risk': _risk(score),
        'confidence': min(score, 92),
        'factors': factors or ['Low environmental risk currently'],
        'recommendation': (
            'Reduce plant density to improve air circulation. '
            'Apply validamycin or hexaconazole fungicide. Drain field periodically.'
        ),
    }


def _predict_tungro(temp, counts):
    score, factors = 0, []
    month = datetime.now().month
    if 5 <= month <= 10:
        score += 28; factors.append('Peak leafhopper migration season (May–Oct)')
    if 25 <= temp <= 35:
        score += 18; factors.append(f'Temperature favorable for leafhoppers ({temp}°C)')
    n = counts.get('Tungro Virus', 0)
    if n >= 1:
        score += 30; factors.append(f'{n} recent Tungro detection(s)')
    return {
        'disease': 'Tungro Virus',
        'risk': _risk(score),
        'confidence': min(score, 90),
        'factors': factors or ['Low seasonal risk currently'],
        'recommendation': (
            'Control green leafhopper with imidacloprid. '
            'Plant tungro-resistant varieties (IR36, NSIC Rc222). '
            'Coordinate planting dates with neighboring farmers.'
        ),
    }

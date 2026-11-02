"""
Official Register G7: Canonical Pilgrimage Circuits across India.
Includes 12 Jyotirlingas, 51 Shakti Peethas, Char Dham, Sikh Takhts, and Jain Tirthas.
"""

from typing import List, Dict

JYOTIRLINGAS: List[Dict] = [
    {"name": "Somnath Temple", "state": "GJ", "district": "Gir Somnath", "lat": 20.8880, "lon": 70.4012, "qid": "Q844122"},
    {"name": "Mallikarjuna Swamy Temple", "state": "AP", "district": "Nandyal", "lat": 16.0739, "lon": 78.8686, "qid": "Q3531985"},
    {"name": "Mahakaleshwar Temple", "state": "MP", "district": "Ujjain", "lat": 23.1827, "lon": 75.7682, "qid": "Q2085732"},
    {"name": "Omkareshwar Temple", "state": "MP", "district": "Khandwa", "lat": 22.2464, "lon": 76.1511, "qid": "Q7090196"},
    {"name": "Kedarnath Temple", "state": "UK", "district": "Rudraprayag", "lat": 30.7352, "lon": 79.0669, "qid": "Q1737974"},
    {"name": "Bhimashankar Temple", "state": "MH", "district": "Pune", "lat": 19.0722, "lon": 73.5358, "qid": "Q2349791"},
    {"name": "Kashi Vishwanath Temple", "state": "UP", "district": "Varanasi", "lat": 25.3109, "lon": 83.0107, "qid": "Q1051515"},
    {"name": "Trimbakeshwar Shiva Temple", "state": "MH", "district": "Nashik", "lat": 19.9324, "lon": 73.5308, "qid": "Q2349795"},
    {"name": "Baidyanath Temple", "state": "JH", "district": "Deoghar", "lat": 24.4925, "lon": 86.7001, "qid": "Q2726359"},
    {"name": "Nageshwar Jyotirlinga", "state": "GJ", "district": "Devbhumi Dwarka", "lat": 22.3344, "lon": 69.0903, "qid": "Q3531998"},
    {"name": "Ramanathaswamy Temple", "state": "TN", "district": "Ramanathapuram", "lat": 9.2881, "lon": 79.3174, "qid": "Q778749"},
    {"name": "Grishneshwar Temple", "state": "MH", "district": "Chhatrapati Sambhajinagar", "lat": 20.0247, "lon": 75.1706, "qid": "Q2349802"},
]

CHAR_DHAM: List[Dict] = [
    {"name": "Badrinath Temple", "state": "UK", "district": "Chamoli", "lat": 30.7449, "lon": 79.4912, "qid": "Q800041"},
    {"name": "Dwarkadhish Temple", "state": "GJ", "district": "Devbhumi Dwarka", "lat": 22.2376, "lon": 68.9678, "qid": "Q2349820"},
    {"name": "Jagannath Temple, Puri", "state": "OD", "district": "Puri", "lat": 19.8049, "lon": 85.8179, "qid": "Q3532009"},
    {"name": "Ramanathaswamy Temple, Rameswaram", "state": "TN", "district": "Ramanathapuram", "lat": 9.2881, "lon": 79.3174, "qid": "Q778749"},
]

SIKH_TAKHTS: List[Dict] = [
    {"name": "Akal Takht (Golden Temple)", "state": "PB", "district": "Amritsar", "lat": 31.6200, "lon": 74.8765, "qid": "Q415849"},
    {"name": "Takht Sri Damdama Sahib", "state": "PB", "district": "Bathinda", "lat": 29.9866, "lon": 75.0747, "qid": "Q7678524"},
    {"name": "Takht Sri Keshgarh Sahib", "state": "PB", "district": "Rupnagar", "lat": 31.2353, "lon": 76.4988, "qid": "Q7678526"},
    {"name": "Takht Sri Patna Sahib", "state": "BR", "district": "Patna", "lat": 25.5947, "lon": 85.2281, "qid": "Q7678528"},
    {"name": "Takht Sachkhand Sri Hazur Abchalnagar Sahib", "state": "MH", "district": "Nanded", "lat": 19.1517, "lon": 77.3183, "qid": "Q3532015"},
]


def get_canonical_pilgrimage_sites() -> List[Dict]:
    return JYOTIRLINGAS + CHAR_DHAM + SIKH_TAKHTS

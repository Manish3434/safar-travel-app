"""
Indic script transliteration and phonetic normalization for cross-lingual entity resolution.
"""

import re
import unicodedata

# Common Indic vowel and consonant phonetic mappings
DEVANAGARI_MAP = {
    'अ': 'a', 'आ': 'aa', 'इ': 'i', 'ई': 'ee', 'उ': 'u', 'ऊ': 'oo', 'ऋ': 'ri',
    'ए': 'e', 'ऐ': 'ai', 'ओ': 'o', 'औ': 'au', 'क': 'k', 'ख': 'kh', 'ग': 'g',
    'घ': 'gh', 'ङ': 'ng', 'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh', 'ञ': 'ny',
    'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n', 'त': 't', 'थ': 'th',
    'द': 'd', 'ध': 'dh', 'न': 'n', 'प': 'p', 'फ': 'ph', 'ब': 'b', 'भ': 'bh',
    'म': 'm', 'य': 'y', 'र': 'r', 'ल': 'l', 'व': 'v', 'श': 'sh', 'ष': 'sh',
    'स': 's', 'ह': 'h', 'ा': 'a', 'ि': 'i', 'ी': 'ee', 'ु': 'u', 'ू': 'oo',
    'ृ': 'ri', 'े': 'e', 'ै': 'ai', 'ो': 'o', 'ौ': 'au', '्': '', 'ं': 'n',
    'ः': 'h', 'ँ': 'n'
}

TAMIL_MAP = {
    'அ': 'a', 'ஆ': 'aa', 'இ': 'i', 'ஈ': 'ee', 'உ': 'u', 'ஊ': 'oo',
    'எ': 'e', 'ஏ': 'e', 'ஐ': 'ai', 'ஒ': 'o', 'ஓ': 'o', 'ஔ': 'au',
    'க': 'k', 'ங': 'ng', 'ச': 's', 'ஞ': 'ny', 'ட': 't', 'ண': 'n',
    'த': 't', 'ந': 'n', 'ப': 'p', 'ம': 'm', 'ய': 'y', 'ர': 'r',
    'ல': 'l', 'வ': 'v', 'ழ': 'zh', 'ள': 'l', 'ற': 'r', 'ன': 'n',
    'ா': 'a', 'ி': 'i', 'ீ': 'ee', 'ு': 'u', 'ூ': 'oo', 'ெ': 'e',
    'ே': 'e', 'ை': 'ai', 'ொ': 'o', 'ோ': 'o', 'ௌ': 'au', '்': ''
}

# Generic English translations for common entity terms
TERM_EQUIVALENTS = {
    "mandir": "temple",
    "kovil": "temple",
    "devasthanam": "temple",
    "gudi": "temple",
    "kila": "fort",
    "kotai": "fort",
    "durga": "fort",
    "gad": "fort",
    "jharna": "waterfall",
    "aruvai": "waterfall",
    "falls": "waterfall",
    "fall": "waterfall",
    "jheel": "lake",
    "kulam": "lake",
    "samudra": "beach",
    "kadarkarai": "beach",
}


def normalize_indic_name(name: str) -> str:
    """
    Translates Devanagari or Tamil strings into phonetic Roman characters,
    translates common place nouns (mandir -> temple, kila -> fort),
    and standardizes whitespace.
    """
    if not name:
        return ""

    text = name.strip()

    # Transliterate character by character if in Indic unicode blocks
    chars = []
    for ch in text:
        if ch in DEVANAGARI_MAP:
            chars.append(DEVANAGARI_MAP[ch])
        elif ch in TAMIL_MAP:
            chars.append(TAMIL_MAP[ch])
        else:
            chars.append(ch)

    romanized = "".join(chars).lower()

    # Normalize accents
    norm = unicodedata.normalize("NFKD", romanized)
    norm = "".join(c for c in norm if not unicodedata.combining(c))

    # Standardize common nouns
    tokens = re.split(r"[\s_,-]+", norm)
    std_tokens = []
    for t in tokens:
        if not t:
            continue
        cleaned = re.sub(r"[^\w]", "", t)
        if cleaned in TERM_EQUIVALENTS:
            std_tokens.append(TERM_EQUIVALENTS[cleaned])
        else:
            std_tokens.append(cleaned)

    return " ".join(std_tokens)

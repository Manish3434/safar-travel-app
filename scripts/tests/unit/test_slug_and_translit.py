"""
Unit Tests for Slug Generator, License Checker, and Indic Transliteration.
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))

from lib.slugger import generate_slug
from lib.translit import normalize_indic_name
from lib.license_check import is_license_clean, normalize_license


def test_slug_generator():
    assert generate_slug("Fort Aguada & Lighthouse") == "fort-aguada-lighthouse"
    assert generate_slug("Taj Mahal", "UP") == "taj-mahal-up"
    assert generate_slug("Dudhsagar Falls / Mandovi") == "dudhsagar-falls-mandovi"


def test_indic_transliteration():
    norm = normalize_indic_name("विरुपाक्ष मंदिर")
    assert "virupaksha" in norm or "temple" in norm


def test_license_checker():
    assert is_license_clean("CC-BY-SA 4.0") is True
    assert is_license_clean("CC0 1.0") is True
    assert is_license_clean("Public Domain") is True
    assert is_license_clean("CC-BY-NC 4.0") is False  # Non-commercial rejected
    assert is_license_clean("CC-BY-ND 3.0") is False  # No-derivatives rejected
    assert is_license_clean("All Rights Reserved") is False


if __name__ == "__main__":
    test_slug_generator()
    test_indic_transliteration()
    test_license_checker()
    print("ALL UNIT TESTS PASSED.")

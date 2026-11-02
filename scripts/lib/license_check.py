"""
License validation engine enforcing strict CC-BY / CC-BY-SA / CC0 / Public Domain compliance.
"""

from typing import Tuple

VALID_LICENSES = {
    "cc0": "CC0",
    "public domain": "PD",
    "pd": "PD",
    "cc-by": "CC-BY",
    "cc-by 1.0": "CC-BY",
    "cc-by 2.0": "CC-BY",
    "cc-by 2.5": "CC-BY",
    "cc-by 3.0": "CC-BY",
    "cc-by 4.0": "CC-BY",
    "cc-by-sa": "CC-BY-SA",
    "cc-by-sa 1.0": "CC-BY-SA",
    "cc-by-sa 2.0": "CC-BY-SA",
    "cc-by-sa 2.5": "CC-BY-SA",
    "cc-by-sa 3.0": "CC-BY-SA",
    "cc-by-sa 4.0": "CC-BY-SA",
}


def validate_license(raw_license: str) -> Tuple[bool, str]:
    """
    Checks if raw_license matches allowed licenses.
    Returns: (is_valid, standardized_enum_code)
    """
    if not raw_license:
        return False, ""

    clean = raw_license.strip().lower().replace("_", " ").replace("-", " ")

    # Direct substring matching
    for key, code in VALID_LICENSES.items():
        clean_key = key.replace("-", " ")
        if clean_key in clean:
            # Disallow NC (non-commercial) or ND (no-derivatives)
            if "nc" in clean or "noncommercial" in clean or "nd" in clean or "noderivs" in clean:
                return False, ""
            return True, code

    return False, ""

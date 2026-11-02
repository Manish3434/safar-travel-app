"""
Slug generator with NFKD normalization, mark stripping, and deterministic collision hashing.
"""

import re
import unicodedata
import hashlib


def generate_slug(text: str, context_seed: str = "") -> str:
    """
    Generates a URL-friendly, language-agnostic slug.
    If context_seed is provided, appends short sha1 to avoid collisions.
    """
    if not text:
        return "unnamed-spot"

    # NFKD decompose and remove combining characters (accents, diacritics)
    normalized = unicodedata.normalize("NFKD", text)
    stripped = "".join(c for c in normalized if not unicodedata.combining(c))

    # Lowercase and convert non-alphanumeric to hyphen
    slug = re.sub(r"[^\w\s-]", "", stripped.lower()).strip()
    slug = re.sub(r"[-\s]+", "-", slug)

    if not slug:
        slug = "spot"

    if context_seed:
        h = hashlib.sha1(f"{text}::{context_seed}".encode("utf-8")).hexdigest()[:6]
        slug = f"{slug}-{h}"

    return slug

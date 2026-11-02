"""
Fast photo downloader utility for Goa dry run.
Downloads real Wikimedia Commons photos in parallel with rate limit safety.
"""

import os
import csv
import urllib.request
import time

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SPOTS_CSV = os.path.join(BASE_DIR, "download", "spots.csv")
USER_AGENT = "SafarTravelExplorer/1.0 (contact: admin@safar.internal)"

def download_all_dry_run_photos():
    if not os.path.exists(SPOTS_CSV):
        print("spots.csv not found!")
        return

    with open(SPOTS_CSV, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Checking {len(rows)} spots for photo downloads...")
    downloaded = 0
    for r in rows:
        fn = r.get("image_filename")
        src = r.get("image_source")
        if not fn or not src:
            continue

        target_path = os.path.join(BASE_DIR, "download", fn)
        os.makedirs(os.path.dirname(target_path), exist_ok=True)

        if not os.path.exists(target_path) or os.path.getsize(target_path) < 100:
            print(f"Downloading {fn} from {src}...")
            try:
                req = urllib.request.Request(src, headers={"User-Agent": USER_AGENT})
                with urllib.request.urlopen(req, timeout=20) as resp:
                    with open(target_path, "wb") as out:
                        out.write(resp.read())
                downloaded += 1
                time.sleep(0.3)
            except Exception as e:
                print(f"  Failed: {e}")

    print(f"Done! Downloaded {downloaded} photos.")

if __name__ == "__main__":
    download_all_dry_run_photos()

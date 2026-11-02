import shutil
import os

dest_dir = 'apps/web/images/categories'
os.makedirs(dest_dir, exist_ok=True)

files = {
    'beach.jpg': r'C:\Users\Manish\.gemini\antigravity-ide\brain\cfd12634-220c-4fb6-9153-5c183a10130f\cat_beach_1793366585188.jpg',
    'forest.jpg': r'C:\Users\Manish\.gemini\antigravity-ide\brain\cfd12634-220c-4fb6-9153-5c183a10130f\cat_forest_1793366619178.jpg',
    'bird_sanctuary.jpg': r'C:\Users\Manish\.gemini\antigravity-ide\brain\cfd12634-220c-4fb6-9153-5c183a10130f\cat_birds_1793366667157.jpg',
    'wildlife.jpg': r'C:\Users\Manish\.gemini\antigravity-ide\brain\cfd12634-220c-4fb6-9153-5c183a10130f\cat_wildlife_1793366706766.jpg',
    'heritage.jpg': r'C:\Users\Manish\.gemini\antigravity-ide\brain\cfd12634-220c-4fb6-9153-5c183a10130f\cat_heritage_1793366756496.jpg',
    'museum.jpg': r'C:\Users\Manish\.gemini\antigravity-ide\brain\cfd12634-220c-4fb6-9153-5c183a10130f\cat_museum_1793366801234.jpg',
    'waterfall.jpg': r'C:\Users\Manish\.gemini\antigravity-ide\brain\cfd12634-220c-4fb6-9153-5c183a10130f\cat_waterfall_1793366868241.jpg',
    'hill_station.jpg': r'C:\Users\Manish\.gemini\antigravity-ide\brain\cfd12634-220c-4fb6-9153-5c183a10130f\cat_hillstation_1793366931373.jpg'
}

for name, src in files.items():
    if os.path.exists(src):
        dst = os.path.join(dest_dir, name)
        shutil.copy2(src, dst)
        print(f"Copied {name} ({os.path.getsize(dst)} bytes)")
    else:
        print(f"Source not found: {src}")

print("All category images deployed successfully!")

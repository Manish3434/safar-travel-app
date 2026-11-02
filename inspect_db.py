import sqlite3

conn = sqlite3.connect('download/pipeline_local.db')
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
print('Tables:', cursor.fetchall())

cursor.execute("SELECT count(*) FROM local_spots;")
print('local_spots count:', cursor.fetchone()[0])
cursor.execute("SELECT name, category, district_id FROM local_spots LIMIT 10;")
for row in cursor.fetchall():
    print('  Spot:', row)

cursor.execute("SELECT count(*) FROM spot_images;")
print('spot_images count:', cursor.fetchone()[0])
cursor.execute("SELECT spot_id, url_regular, license, source FROM spot_images LIMIT 10;")
for row in cursor.fetchall():
    print('  Spot image:', row)


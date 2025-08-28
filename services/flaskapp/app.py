from flask import Flask, request
import psycopg2
import socket
import os


app = Flask(__name__)
hostname = os.getenv("SERVER_NAME", "unknown")

def get_connection():
    return psycopg2.connect(
        host="127.0.0.1",
        database="locationdb",
        user="hauser",
        password="hapassword"
    )

@app.route('/', methods=['GET', 'POST'])
def index():
    message = ""
    if request.method == 'POST':
        name = request.form['name']
        lat_input = request.form['lat']
        lon_input = request.form['lon']

        try:
            # Validasi apakah lat dan lon bisa dikonversi ke float
            lat = float(lat_input)
            lon = float(lon_input)

            # Simpan ke database
            conn = get_connection()
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO location_logs (server_name, location_name, latitude, longitude) VALUES (%s, %s, %s, %s)",
                (hostname, name, lat, lon)
            )
            conn.commit()
            cur.close()
            conn.close()
            message = "<p style='color:green;'>Data berhasil disimpan!</p>"
        except ValueError:
            message = "<p style='color:red;'>Latitude dan Longitude harus berupa angka!</p>"
        except Exception as e:
            message = f"<p style='color:red;'>Gagal menyimpan data: {e}</p>"

    # Ambil isi tabel
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM location_logs ORDER BY timestamp DESC")
    rows = cur.fetchall()
    cur.close()
    conn.close()

    table_rows = "<tr><th>ID</th><th>Server</th><th>Nama Lokasi</th><th>Latitude</th><th>Longitude</th><th>Waktu</th></tr>"
    for row in rows:
        table_rows += "<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>"

    return f'''
        <h2>Input Lokasi dari serverA</h2>
        {message}
        <form method="post">
            Nama Lokasi: <input type="text" name="name" required><br>
            Latitude: <input type="number" step="any" name="lat" required><br>
            Longitude: <input type="number" step="any" name="lon" required><br>
            <input type="submit" value="Simpan">
        </form>
        <h2>Data Lokasi Tersimpan</h2>
        <table border="1" cellpadding="5" cellspacing="0">
            {table_rows}
        </table>
    '''

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)

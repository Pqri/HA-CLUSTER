from flask import Flask, request, render_template
import psycopg2
import os
from urllib.parse import urlparse

app = Flask(__name__)

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://hauser:hapassword@127.0.0.1:5432/locationdb")

def get_conn():
    return psycopg2.connect(DATABASE_URL)

@app.route("/", methods=["GET", "POST"])
def index():
    msg = ""
    if request.method == "POST":
        name = request.form.get("name", "").strip()
        lat_s = request.form.get("lat", "").strip()
        lon_s = request.form.get("lon", "").strip()
        try:
            lat = float(lat_s)
            lon = float(lon_s)
            with get_conn() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        "CREATE TABLE IF NOT EXISTS location_logs (id bigserial PRIMARY KEY, server_name text, location_name text, latitude double precision, longitude double precision, timestamp timestamptz DEFAULT now())"
                    )
                    cur.execute(
                        "INSERT INTO location_logs (server_name, location_name, latitude, longitude) VALUES (%s, %s, %s, %s)",
                        (os.getenv("SERVER_NAME", "unknown"), name, lat, lon),
                    )
                    conn.commit()
            msg = "Saved!"
        except Exception as e:
            msg = f"Error: {e}"
    # fetch last 5
    rows = []
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id, server_name, location_name, latitude, longitude, timestamp FROM location_logs ORDER BY id DESC LIMIT 5")
                rows = cur.fetchall()
    except Exception as e:
        msg = msg or f"DB not ready: {e}"
    return render_template("index.html", message=msg, rows=rows)

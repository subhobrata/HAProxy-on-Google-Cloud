import os, psycopg2, time
DB_HOST = os.getenv("DB_HOST", "localhost")
conn = psycopg2.connect(host=DB_HOST, port=5432, user="postgres",
                        password=os.getenv("PGPASSWORD", "example"),
                        dbname="appdb")
cur = conn.cursor()
cur.execute("select now()")
print("Server time is:", cur.fetchone()[0])
cur.close()
conn.close()

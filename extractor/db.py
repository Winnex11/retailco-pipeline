import psycopg2
import psycopg2.extras
import json
import logging
from config import LAKE_DB

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_connection():
    """Create and return a database connection to the lake"""
    return psycopg2.connect(**LAKE_DB)


def create_schema(conn):
    """Create the raw schema if it doesn't exist"""
    with conn.cursor() as cur:
        cur.execute("CREATE SCHEMA IF NOT EXISTS raw;")
    conn.commit()


def create_watermark_table(conn):
    """
    Create a table to store watermarks (last successful extract time)
    This is how we know what data to fetch on the next run
    """
    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS raw.watermarks (
                entity_name VARCHAR(100) PRIMARY KEY,
                last_updated_at TIMESTAMP,
                last_run_at TIMESTAMP DEFAULT NOW()
            );
        """)
    conn.commit()


def get_watermark(conn, entity_name):
    """
    Get the last successful extract timestamp for an entity
    Returns None if this is the first run (full extract needed)
    """
    with conn.cursor() as cur:
        cur.execute("""
            SELECT last_updated_at 
            FROM raw.watermarks 
            WHERE entity_name = %s;
        """, (entity_name,))
        result = cur.fetchone()
        return result[0] if result else None


def set_watermark(conn, entity_name, last_updated_at):
    """
    Save the watermark after a successful extract
    Next run will only fetch data newer than this timestamp
    """
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO raw.watermarks (entity_name, last_updated_at, last_run_at)
            VALUES (%s, %s, NOW())
            ON CONFLICT (entity_name) 
            DO UPDATE SET 
                last_updated_at = EXCLUDED.last_updated_at,
                last_run_at = NOW();
        """, (entity_name, last_updated_at))
    conn.commit()


def create_raw_table(conn, entity_name):
    """
    Create a raw table for an entity if it doesn't exist
    We store the full row as JSON plus key metadata columns
    """
    with conn.cursor() as cur:
        cur.execute(f"""
            CREATE TABLE IF NOT EXISTS raw.{entity_name} (
                id VARCHAR(255) PRIMARY KEY,
                data JSONB NOT NULL,
                extracted_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP
            );
        """)
    conn.commit()


def upsert_records(conn, entity_name, records):
    """
    Insert or update records in the raw table
    If a record with the same id already exists we update it
    This is what makes the pipeline idempotent
    """
    if not records:
        return 0

    with conn.cursor() as cur:
        for record in records:
            record_id = str(record.get("id", ""))
            updated_at = record.get("updated_at")

            cur.execute(f"""
                INSERT INTO raw.{entity_name} (id, data, extracted_at, updated_at)
                VALUES (%s, %s, NOW(), %s)
                ON CONFLICT (id)
                DO UPDATE SET
                    data = EXCLUDED.data,
                    extracted_at = NOW(),
                    updated_at = EXCLUDED.updated_at;
            """, (record_id, json.dumps(record), updated_at))

    conn.commit()
    logger.info(f"Upserted {len(records)} records into raw.{entity_name}")
    return len(records)
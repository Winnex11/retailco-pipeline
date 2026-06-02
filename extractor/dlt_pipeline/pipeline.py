import dlt
import psycopg2
import psycopg2.extras
import logging
import os
from datetime import datetime, timezone
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Lake database connection settings (where we READ from)
LAKE_CONFIG = {
    "host": os.getenv("LAKE_HOST", "localhost"),
    "port": int(os.getenv("LAKE_PORT", "5433")),
    "dbname": os.getenv("LAKE_DB", "lake"),
    "user": os.getenv("LAKE_USER", "lake_user"),
    "password": os.getenv("LAKE_PASSWORD", "lake_pass"),
}

# Warehouse database connection settings (where we WRITE to)
WAREHOUSE_CONFIG = {
    "host": os.getenv("WAREHOUSE_HOST", "localhost"),
    "port": int(os.getenv("WAREHOUSE_PORT", "5434")),
    "database": os.getenv("WAREHOUSE_DB", "warehouse"),
    "username": os.getenv("WAREHOUSE_USER", "warehouse_user"),
    "password": os.getenv("WAREHOUSE_PASSWORD", "warehouse_pass"),
}

# All 9 entities we need to move
ENTITIES = [
    "customers",
    "products",
    "stores",
    "employees",
    "orders",
    "order_items",
    "payments",
    "inventory_movements",
    "payment_methods",
]


def get_lake_connection():
    """Connect to the lake database"""
    return psycopg2.connect(**LAKE_CONFIG)


def get_last_loaded_at(conn, entity_name):
    """
    Check when we last loaded this entity into the warehouse.
    This is how dlt does incremental loading - only move new records.
    Returns None if this is the first time we are loading this entity.
    """
    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS raw.dlt_watermarks (
                entity_name VARCHAR(100) PRIMARY KEY,
                last_loaded_at TIMESTAMP,
                last_run_at TIMESTAMP DEFAULT NOW()
            );
        """)
        conn.commit()

        cur.execute("""
            SELECT last_loaded_at 
            FROM raw.dlt_watermarks 
            WHERE entity_name = %s;
        """, (entity_name,))
        result = cur.fetchone()
        return result[0] if result else None


def set_last_loaded_at(conn, entity_name, last_loaded_at):
    """Save the watermark after successfully loading an entity"""
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO raw.dlt_watermarks (entity_name, last_loaded_at, last_run_at)
            VALUES (%s, %s, NOW())
            ON CONFLICT (entity_name)
            DO UPDATE SET
                last_loaded_at = EXCLUDED.last_loaded_at,
                last_run_at = NOW();
        """, (entity_name, last_loaded_at))
    conn.commit()


def read_from_lake(conn, entity_name, last_loaded_at=None):
    """
    Read records from the lake database.
    If last_loaded_at is provided, only read records newer than that.
    This is incremental loading - we don't move everything every time.
    """
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        if last_loaded_at:
            # Incremental - only get new or updated records
            logger.info(f"{entity_name}: incremental load from {last_loaded_at}")
            cur.execute(f"""
                SELECT id, data, extracted_at, updated_at
                FROM raw.{entity_name}
                WHERE extracted_at > %s
                ORDER BY extracted_at ASC;
            """, (last_loaded_at,))
        else:
            # Full load - get everything
            logger.info(f"{entity_name}: full load (first time)")
            cur.execute(f"""
                SELECT id, data, extracted_at, updated_at
                FROM raw.{entity_name}
                ORDER BY extracted_at ASC;
            """)

        records = cur.fetchall()
        logger.info(f"{entity_name}: found {len(records)} records to load")
        return [dict(r) for r in records]


def flatten_record(record):
    """
    The lake stores data as JSON inside a 'data' column.
    This function pulls all fields out of JSON into flat columns.
    This is type coercion - making sure all fields are the right type.
    Example:
        Before: {id: '123', data: {name: 'John', age: '25'}, extracted_at: ...}
        After:  {id: '123', name: 'John', age: '25', extracted_at: ...}
    """
    import json

    flattened = {}

    # Add the metadata columns
    flattened["_lake_id"] = str(record.get("id", ""))
    flattened["_extracted_at"] = record.get("extracted_at")
    flattened["_updated_at"] = record.get("updated_at")

    # Pull out all fields from the JSON data column
    data = record.get("data", {})
    if isinstance(data, str):
        data = json.loads(data)

    for key, value in data.items():
        # Clean up the key name to snake_case
        clean_key = key.lower().replace("-", "_").replace(" ", "_")
        flattened[clean_key] = value

    return flattened


def load_entity_to_warehouse(entity_name, records):
    """
    Use dlt to load records into the warehouse database.
    dlt handles:
    - Creating the table automatically
    - Type coercion (converting strings to proper types)
    - Upserts (updating existing records, inserting new ones)
    """
    if not records:
        logger.info(f"{entity_name}: no records to load, skipping")
        return 0

    # Flatten all records
    flattened_records = [flatten_record(r) for r in records]

    # Create dlt pipeline pointing to warehouse database
    pipeline = dlt.pipeline(
        pipeline_name=f"retailco_{entity_name}",
        destination=dlt.destinations.postgres(
            f"postgresql://{WAREHOUSE_CONFIG['username']}:"
            f"{WAREHOUSE_CONFIG['password']}@"
            f"{WAREHOUSE_CONFIG['host']}:"
            f"{WAREHOUSE_CONFIG['port']}/"
            f"{WAREHOUSE_CONFIG['database']}"
        ),
        dataset_name="raw",
    )

    # Run the pipeline - dlt does all the heavy lifting here
    load_info = pipeline.run(
        flattened_records,
        table_name=entity_name,
        write_disposition="merge",
        primary_key="_lake_id",
    )

    logger.info(f"{entity_name}: dlt load complete - {load_info}")
    return len(flattened_records)


def run_pipeline():
    """
    Main function that runs the full dlt pipeline.
    For each entity:
    1. Check when we last loaded it (watermark)
    2. Read only new records from the lake
    3. Load them into the warehouse using dlt
    4. Save the new watermark
    """
    logger.info("=" * 50)
    logger.info("Starting RetailCo dlt pipeline")
    logger.info(f"Run time: {datetime.now()}")
    logger.info("=" * 50)

    # Connect to lake database
    lake_conn = get_lake_connection()

    results = {}

    try:
        for entity in ENTITIES:
            logger.info(f"\nProcessing: {entity}")

            try:
                # Check watermark - when did we last load this?
                last_loaded_at = get_last_loaded_at(lake_conn, entity)

                # Read from lake (only new records if watermark exists)
                records = read_from_lake(lake_conn, entity, last_loaded_at)

                if records:
                    # Load into warehouse using dlt
                    count = load_entity_to_warehouse(entity, records)
                    results[entity] = count

                    # Save new watermark
                    set_last_loaded_at(
                        lake_conn,
                        entity,
                        datetime.now(timezone.utc)
                    )
                else:
                    logger.info(f"{entity}: no new records to load")
                    results[entity] = 0

            except Exception as e:
                logger.error(f"Error loading {entity}: {str(e)}")
                results[entity] = f"ERROR: {str(e)}"
                continue

    finally:
        lake_conn.close()

    # Print summary
    logger.info("\n" + "=" * 50)
    logger.info("DLT PIPELINE SUMMARY")
    logger.info("=" * 50)
    for entity, count in results.items():
        logger.info(f"{entity}: {count} records loaded to warehouse")
    logger.info("=" * 50)


if __name__ == "__main__":
    run_pipeline()
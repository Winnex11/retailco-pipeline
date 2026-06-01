import logging
from datetime import datetime
from config import ENTITIES
from db import (
    get_connection,
    create_schema,
    create_watermark_table,
    create_raw_table,
    get_watermark,
    set_watermark,
    upsert_records
)
from extractor import extract_entity

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def run_extraction():
    """
    Main function that runs the full extraction pipeline
    1. Connects to the lake database
    2. For each entity:
       a. Checks the watermark (last successful extract time)
       b. Fetches only new/updated records from the API
       c. Saves them to the lake database
       d. Updates the watermark
    """
    logger.info("=" * 50)
    logger.info("Starting RetailCo ERP extraction")
    logger.info(f"Run time: {datetime.now()}")
    logger.info("=" * 50)

    # Connect to lake database
    conn = get_connection()

    try:
        # Set up schema and watermark table if first run
        create_schema(conn)
        create_watermark_table(conn)

        # Track overall results
        results = {}

        # Loop through every entity and extract it
        for entity in ENTITIES:
            logger.info(f"\nProcessing entity: {entity}")

            try:
                # Create the raw table if it doesn't exist
                create_raw_table(conn, entity)

                # Get watermark - tells us when we last extracted this entity
                watermark = get_watermark(conn, entity)

                if watermark:
                    logger.info(f"{entity}: incremental extract from {watermark}")
                else:
                    logger.info(f"{entity}: no watermark found, doing full extract")

                # Extract data from API
                records, latest_updated_at = extract_entity(
                    entity,
                    updated_after=watermark.isoformat() if watermark else None
                )

                # Save records to lake database
                if records:
                    count = upsert_records(conn, entity, records)
                    results[entity] = count

                    # Update watermark so next run only fetches newer data
                    if latest_updated_at:
                        set_watermark(conn, entity, latest_updated_at)
                        logger.info(f"{entity}: watermark updated to {latest_updated_at}")
                else:
                    logger.info(f"{entity}: no new records found")
                    results[entity] = 0

            except Exception as e:
                logger.error(f"Error extracting {entity}: {str(e)}")
                results[entity] = f"ERROR: {str(e)}"
                continue

        # Print summary
        logger.info("\n" + "=" * 50)
        logger.info("EXTRACTION SUMMARY")
        logger.info("=" * 50)
        for entity, count in results.items():
            logger.info(f"{entity}: {count} records")
        logger.info("=" * 50)

    finally:
        conn.close()
        logger.info("Database connection closed")


if __name__ == "__main__":
    run_extraction()
import requests
import time
import logging
from config import API_KEY, API_BASE_URL, PAGE_LIMIT, MAX_RETRIES

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

HEADERS = {
    "X-API-Key": API_KEY,
    "Content-Type": "application/json"
}


def fetch_page(entity, cursor=None, updated_after=None):
    """
    Fetch one page of data from the API
    Handles retries and rate limiting
    """
    url = f"{API_BASE_URL}/{entity}"

    params = {"limit": PAGE_LIMIT}
    if cursor:
        params["cursor"] = cursor
    if updated_after:
        params["updated_after"] = updated_after

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = requests.get(
                url, headers=HEADERS, params=params, timeout=30
            )

            # Rate limited - wait exactly as long as API says
            if response.status_code == 429:
                wait_time = int(response.headers.get("Retry-After", 60))
                logger.warning(f"Rate limited on {entity}. Waiting {wait_time}s...")
                time.sleep(wait_time)
                continue

            # Server error - exponential backoff
            if response.status_code == 500:
                wait_time = 2 ** attempt
                logger.warning(f"Server error on {entity}. Waiting {wait_time}s...")
                time.sleep(wait_time)
                continue

            # Bad API key
            if response.status_code == 401:
                raise Exception("Invalid API key. Check your .env file.")

            # Success
            if response.status_code == 200:
                return response.json()

            response.raise_for_status()

        except requests.exceptions.Timeout:
            wait_time = 2 ** attempt
            logger.warning(f"Timeout on {entity}. Waiting {wait_time}s...")
            time.sleep(wait_time)

        except requests.exceptions.ConnectionError:
            wait_time = 2 ** attempt
            logger.warning(f"Connection error on {entity}. Waiting {wait_time}s...")
            time.sleep(wait_time)

    raise Exception(f"Failed to fetch {entity} after {MAX_RETRIES} attempts")


def extract_entity(entity, updated_after=None):
    """
    Extract ALL pages for one entity
    Pagination info is inside response['meta']
    """
    all_records = []
    cursor = None
    latest_updated_at = None
    page_number = 0

    logger.info(f"{'='*40}")
    logger.info(f"Starting: {entity}" +
                (f" from {updated_after}" if updated_after else " (full extract)"))

    while True:
        # Fetch one page
        response = fetch_page(entity, cursor=cursor, updated_after=updated_after)

        # Records are in response['data']
        records = response.get("data", [])

        # Pagination info is in response['meta']
        meta = response.get("meta", {})
        has_more = meta.get("has_more", False)
        next_cursor = meta.get("cursor", None)

        if records:
            page_number += 1
            all_records.extend(records)

            # Track latest updated_at for watermark
            for record in records:
                record_updated_at = record.get("updated_at")
                if record_updated_at:
                    if latest_updated_at is None or record_updated_at > latest_updated_at:
                        latest_updated_at = record_updated_at

            logger.info(
                f"{entity}: page {page_number} — "
                f"{len(records)} this page — "
                f"{len(all_records)} total — "
                f"has_more={has_more}"
            )

        # Stop if no more pages
        if not has_more:
            logger.info(f"{entity}: DONE. Total records: {len(all_records)}")
            break

        # Stop if no cursor found
        if not next_cursor:
            logger.warning(f"{entity}: has_more=True but no cursor. Stopping.")
            break

        # Move to next page
        cursor = next_cursor

    return all_records, latest_updated_at
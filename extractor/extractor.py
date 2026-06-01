import requests
import time
import logging
from datetime import datetime
from config import API_KEY, API_BASE_URL, PAGE_LIMIT, MAX_RETRIES

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Headers sent with every API request
HEADERS = {
    "X-API-Key": API_KEY,
    "Content-Type": "application/json"
}


def fetch_page(entity, cursor=None, updated_after=None):
    """
    Fetch one page of data from the API for a given entity
    Handles retries and rate limiting automatically
    """
    url = f"{API_BASE_URL}/{entity}"

    # Build query parameters
    params = {"limit": PAGE_LIMIT}
    if cursor:
        params["cursor"] = cursor
    if updated_after:
        params["updated_after"] = updated_after

    # Try up to MAX_RETRIES times
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            logger.info(f"Fetching {entity} page (attempt {attempt})")
            response = requests.get(url, headers=HEADERS, params=params, timeout=30)

            # Rate limited - wait and retry
            if response.status_code == 429:
                wait_time = int(response.headers.get("Retry-After", 60))
                logger.warning(f"Rate limited. Waiting {wait_time} seconds...")
                time.sleep(wait_time)
                continue

            # Server error - retry with exponential backoff
            if response.status_code == 500:
                wait_time = 2 ** attempt
                logger.warning(f"Server error. Waiting {wait_time} seconds...")
                time.sleep(wait_time)
                continue

            # Unauthorized - stop immediately
            if response.status_code == 401:
                raise Exception("Invalid API key. Check your .env file.")

            # Success
            if response.status_code == 200:
                return response.json()

            # Any other error
            response.raise_for_status()

        except requests.exceptions.Timeout:
            wait_time = 2 ** attempt
            logger.warning(f"Request timed out. Waiting {wait_time} seconds...")
            time.sleep(wait_time)

        except requests.exceptions.ConnectionError:
            wait_time = 2 ** attempt
            logger.warning(f"Connection error. Waiting {wait_time} seconds...")
            time.sleep(wait_time)

    raise Exception(f"Failed to fetch {entity} after {MAX_RETRIES} attempts")


def extract_entity(entity, updated_after=None):
    """
    Extract ALL pages of data for one entity
    Follows cursors until has_more is False
    Returns a list of all records and the latest updated_at timestamp
    """
    all_records = []
    cursor = None
    latest_updated_at = None
    page_count = 0

    logger.info(f"Starting extract for {entity}" + 
                (f" (incremental from {updated_after})" if updated_after else " (full extract)"))

    while True:
        # Fetch one page
        response = fetch_page(entity, cursor=cursor, updated_after=updated_after)

        # Get records from response
        records = response.get("data", response.get("items", []))

        if records:
            all_records.extend(records)
            page_count += 1

            # Track the latest updated_at across all records
            for record in records:
                record_updated_at = record.get("updated_at")
                if record_updated_at:
                    if latest_updated_at is None or record_updated_at > latest_updated_at:
                        latest_updated_at = record_updated_at

            logger.info(f"{entity}: fetched page {page_count}, total records so far: {len(all_records)}")

        # Check if there are more pages
        has_more = response.get("has_more", False)
        cursor = response.get("next_cursor", response.get("cursor", None))

        if not has_more or not cursor:
            logger.info(f"{entity}: extraction complete. Total records: {len(all_records)}")
            break

    return all_records, latest_updated_at
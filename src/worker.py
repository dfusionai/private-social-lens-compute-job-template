from pathlib import Path
import sqlite3
import json
import sys
from typing import Dict, Any
from query_engine_client import QueryEngineClient
from container_params import ContainerParams, ContainerParamError

def get_data(db_path: Path) -> Dict[str, Dict[str, Any]]:
    """Fetch all rows from the 'results' table in the SQLite database.

    Each row is returned as a dictionary with column names as keys.

    Args:
        db_path: Path to the SQLite database file.

    Returns:
        A list of dictionaries, each representing a row from the 'results' table.

    Raises:
        sqlite3.Error: If a database error occurs.
        Exception: For other unexpected errors.
    """
    try:
        with sqlite3.connect(db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM results')
            return [dict(row) for row in cursor.fetchall()]

    except sqlite3.Error as e:
        print(f"SQLite error: {e}")
        raise
    except Exception as e:
        print(f"Error querying database: {e}")
        raise


def save_stats_to_json(data: Dict[str, Any], output_path: Path) -> None:
    """Save data to a JSON file.

    Args:
        data: Data to save (dictionary that can be JSON serialized)
        output_path: Path where the JSON file will be saved

    Raises:
        Exception: If there's an error creating the output directory or saving the file
    """
    try:
        # Ensure the output directory exists
        output_dir = output_path.parent
        output_dir.mkdir(parents=True, exist_ok=True)

        # Save to JSON
        with open(output_path, "w") as f:
            json.dump(data, f, indent=4)

        print(f"Stats saved to {output_path}")
    except Exception as e:
        print(f"Error saving JSON: {e}")
        raise

def execute_query(params: ContainerParams) -> bool:
    """Execute the query using the query engine client.

    Args:
        params: Container parameters with query details

    Returns:
        True if query execution was successful, False otherwise
    """
    if not params.validate_production_mode():
        return False

    # Initialize query engine client
    query_engine_client = QueryEngineClient(
        params.query,
        params.query_signature,
        str(params.db_path)
    )

    # Execute query
    print(f"Executing query: {params.query}")
    query_result = query_engine_client.execute_query(
        params.compute_job_id,
        params.data_refiner_id,
        params.query_params
    )

    if not query_result.success:
        error_msg = f"Error executing query: {query_result.error}"
        if query_result.status_code:
            error_msg += f" (Status code: {query_result.status_code})"
        if query_result.data:
            error_msg += f"\nResponse data: {json.dumps(query_result.data, indent=2)}"
        print(error_msg)
        return False

    print(f"Query executed successfully, processing results from {params.db_path}")
    return True

def process_results(params: ContainerParams) -> None:
    """Process query results and generate stats file."""
    messages = get_data(params.db_path)

    if messages:
        print(f"Found {len(messages)} chat messages in the database!")
        save_stats_to_json(messages, params.stats_path)
    else:
        print("No chat messages found in the database!")
        save_stats_to_json({}, params.stats_path)

def main() -> None:
    """Main entry point for the worker."""
    try:
        # Load parameters from environment variables
        try:
            params = ContainerParams.from_env()
            print(f"params: ${params}")
        except ContainerParamError as e:
            print(f"Error in container parameters: {e}")
            sys.exit(1)

        # Handle development vs production mode
        if params.dev_mode:
            print("Running in DEVELOPMENT MODE - using local database file")
            print(f"Processing query results from {params.db_path}")
        else:
            # In production mode, execute the query first
            if not execute_query(params):
                sys.exit(2)
        # Process results (whether from dev mode or query execution)
        process_results(params)

    except Exception as e:
        print(f"Error in worker execution: {e}")
        sys.exit(3)

if __name__ == "__main__":
    main()
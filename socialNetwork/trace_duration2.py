import json
import os
import sys
import re

def get_trace_duration(trace_json):
    spans = trace_json["data"][0]["spans"] 

    start_times = [span["startTime"] for span in spans]
    end_times = [span["startTime"] + span["duration"] for span in spans]

    trace_start = min(start_times)
    trace_end = max(end_times)

    return trace_end - trace_start 

def load_trace_from_file(file_path):
    try:
        with open(file_path, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: File not found: {file_path}")
        return None
    except json.JSONDecodeError:
        print(f"Error: Failed to parse JSON: {file_path}. Skipping.")
        return None

def process_json_files(directory):
    # Dictionary to store file paths grouped by filename
    files_by_name = {}
    
    # First, collect all JSON files and group them by filename
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".json"):
                if file not in files_by_name:
                    files_by_name[file] = []
                files_by_name[file].append(os.path.join(root, file))
    
    # Sort filenames alphabetically
    sorted_filenames = sorted(files_by_name.keys())
    
    # Process files by name order
    for filename in sorted_filenames:
        for file_path in sorted(files_by_name[filename]):
            trace_data = load_trace_from_file(file_path)
            if trace_data:
                # Extract service name from directory path
                dir_match = re.search(r'limit_socnetapp_([^/]+)', file_path)
                service_name = dir_match.group(1) if dir_match else "unknown-service"
                
                # Extract service name from filename for the second line
                service_name_from_file = re.search(r'traces_([^_]+(?:-[^_]+)*)_\d+\.\d+\.json$', filename)
                service_name_for_output = service_name_from_file.group(1) if service_name_from_file else "unknown-service"
                
                # Extract the decimal version
                version_match = re.search(r'_(\d+\.\d+)\.json$', filename)
                version = version_match.group(1) if version_match else "unknown-version"
                
                duration_ms = get_trace_duration(trace_data) / 1_000 
                
                # Print in the requested format
                print(f"{service_name}")
                print(f"{service_name_for_output}")
                print(f"{version}")
                print(f"{duration_ms:.3f}")
                print()  # Empty line between entries

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python trace_duration.py <directory_path>")
        sys.exit(1)

    directory_path = sys.argv[1] 

    if not os.path.isdir(directory_path):
        print(f"Error: '{directory_path}' is not a valid directory.")
        sys.exit(1)

    process_json_files(directory_path)

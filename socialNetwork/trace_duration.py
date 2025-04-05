import json
import os
import sys

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
        print(f"\nProcessing all instances of: {filename}")
        for file_path in sorted(files_by_name[filename]):
            print(f"Processing: {file_path}")
            
            trace_data = load_trace_from_file(file_path)
            if trace_data:
                duration_ms = get_trace_duration(trace_data) / 1_000 
                print(f"File: {file_path}\nEnd-to-end duration: {duration_ms:.3f} ms\n")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python trace_duration.py <directory_path>")
        sys.exit(1)

    directory_path = sys.argv[1] 

    if not os.path.isdir(directory_path):
        print(f"Error: '{directory_path}' is not a valid directory.")
        sys.exit(1)

    process_json_files(directory_path)

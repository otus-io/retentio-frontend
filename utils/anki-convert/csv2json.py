#!/usr/bin/env python3
import csv
import json
import sys
import os

def csv_to_json(csv_file_path, json_file_path):
    """
    Convert CSV file to JSON format with structure:
    {
      "facts": [
        ["string"]
      ]
    }
    """
    facts = []
    
    try:
        with open(csv_file_path, 'r', encoding='utf-8') as csv_file:
            # Read CSV file
            csv_reader = csv.reader(csv_file)
            
            # Skip header row
            headers = next(csv_reader)
            print(f"Headers found: {headers}")
            
            # Process each row
            for row_num, row in enumerate(csv_reader, start=2):
                # Filter out empty strings and None values, strip whitespace
                row_data = [cell.strip() for cell in row if cell and cell.strip()]
                
                # Only add non-empty rows
                if row_data:
                    facts.append(row_data)
                    
            print(f"Processed {len(facts)} rows with data")
            
        # Create the JSON structure
        json_data = {
            "facts": facts
        }
        
        # Write to JSON file
        with open(json_file_path, 'w', encoding='utf-8') as json_file:
            json.dump(json_data, json_file, ensure_ascii=False, indent=2)
            
        print(f"Successfully converted {csv_file_path} to {json_file_path}")
        
        # Show first few entries as preview
        if facts:
            print(f"\nFirst 3 entries preview:")
            for i, fact in enumerate(facts[:3]):
                print(f"  {i+1}: {fact}")
        
        return len(facts)  # Return number of facts for the main function
                
    except FileNotFoundError:
        print(f"Error: File '{csv_file_path}' not found.")
        return None
    except Exception as e:
        print(f"Error processing file: {str(e)}")
        return None

# Usage example
if __name__ == "__main__":
    # Check command line arguments
    if len(sys.argv) < 2:
        print("Usage: ./csv2json <csv_file> [output_file]")
        print("Example: ./csv2json jp.csv")
        print("Example: ./csv2json jp.csv output.json")
        sys.exit(1)
    
    # Get input file from command line
    csv_file = sys.argv[1]
    
    # Check if input file exists
    if not os.path.exists(csv_file):
        print(f"Error: File '{csv_file}' not found.")
        sys.exit(1)
    
    # Generate output filename
    if len(sys.argv) >= 3:
        json_file = sys.argv[2]
    else:
        # Create output filename by replacing .csv with .json
        base_name = os.path.splitext(csv_file)[0]
        json_file = f"{base_name}.json"
    
    print(f"Converting '{csv_file}' to '{json_file}'...")
    
    # Convert the file
    num_facts = csv_to_json(csv_file, json_file)
    
    if num_facts is not None:
        print(f"✓ Conversion completed: {num_facts} facts converted")

# This script will break the name of a item (food) into tokens to allow for a
# more dynamic search and is not required to upload data
import json

def main():
    input_file = './sample.json'  # Replace with your input file name
    output_file = './output.json'  # Replace with your desired output file name
    process_json(input_file, output_file)

def process_json(input_file, output_file):
    try:
        # Read the input JSON file
        with open(input_file, 'r') as infile:
            data = json.load(infile)

        # Process each entry
        for entry in data:
            if 'name' in entry:
                # Split the name field into individual words
                entry['name_tokens'] = entry['name'].split()

        # Write the updated JSON to the output file
        with open(output_file, 'w') as outfile:
            json.dump(data, outfile, indent=4)

        print(f"Processed JSON saved to {output_file}")

    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    main()
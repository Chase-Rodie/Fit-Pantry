import firebase_admin
from firebase_admin import credentials, firestore
import json

'''
WARNING:
This code will write directly to the firestore database with admin privleges. This code can 
and WILL destroy the backend if used incorectly. If you have any question please contact 
Zach Greenhill, zgreenhill@unr.edu
'''
def main():
    path = "./output.json"
    collection = "test2"
    upload_data(path, collection, mode='skip')
    

# Modes:
### duplicate = will add all data even if it has a duplicate entry with a random docID
### overwrite = will replace items if they have a duplicate ID value
### skip = will skip items if they have a duplicate ID value
def upload_data(path, collection, mode='skip'):
    # Counter variable to show how many documents were effected
    counter = 0

    # Get credentials and validate
    cred = credentials.Certificate("./fit-pantry-firebase-adminsdk-d8kbr-7098ae644b.json")
    firebase_admin.initialize_app(cred)

    # Create client object
    db = firestore.client()

    #Open json file
    with open(path, "r") as f:
        data = json.load(f)

    #
    if mode == 'skip':
        # Retrieve existing document IDs from the collection
        existing_entries = db.collection(collection).stream()
        existing_ids = {doc.id for doc in existing_entries}  # Collect existing document IDs

        # Loop through each item in the json
        for item in data:
            item_id = str(item.get("ID")) # Get ID from entry

            # If entry already exsists then skip it
            if item_id in existing_ids:
                #print(f"Skipping entry with ID {item_id}, already exists.")
                continue  

            # Use the ID as the document ID when adding to Firestore
            db.collection(collection).document(item_id).set(item)
            #print(f"Uploaded entry with ID {item_id}.")
            counter += 1
    
    elif mode == 'overwrite':
        for item in data:
            item_id = str(item.get("ID")) # Get ID from entry

            # Use the ID as the document ID when adding to Firestore
            db.collection(collection).document(item_id).set(item)
            #print(f"Uploaded entry with ID {item_id}.")
            counter += 1

    # Add data regaurdless if it is a duplicate
    elif mode == 'duplicate':# Retrieve existing document IDs from the collection
        existing_entries = db.collection(collection).stream()
        existing_ids = {doc.id for doc in existing_entries}  # Collect existing document IDs

        # Loop through each item in the json
        for item in data:
            item_id = str(item.get("ID")) # Get ID from entry

            # If entry already exsists then upload with random ID
            if item_id in existing_ids:
                #print(f"Skipping entry with ID {item_id}, already exists.")
                db.collection(collection).add(item) 

            # Use the ID as the document ID when adding to Firestore
            else:
                db.collection(collection).document(item_id).set(item)
                #print(f"Uploaded entry with ID {item_id}.")
            counter += 1

    else:
        print("Invalid mode selected. Upload incomplete")
        return

    print(f"Upload successful. {counter} documents effected")

if __name__ == "__main__":
    main()
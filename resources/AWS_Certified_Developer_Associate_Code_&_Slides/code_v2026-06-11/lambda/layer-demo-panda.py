import pandas as pd

def lambda_handler(event, context):
    # Sample Data
    data = {
        "Name": ["Alice", "Bob", "Charlie", "David"],
        "Age": [25, 30, 35, 40],
        "City": ["New York", "Los Angeles", "Chicago", "Houston"]
    }
    
    # Create a DataFrame
    df = pd.DataFrame(data)
    
    # Filter Data (Example: People older than 30)
    filtered_df = df[df["Age"] > 30]
    
    # Convert to JSON
    result = filtered_df.to_dict(orient="records")
    
    return result
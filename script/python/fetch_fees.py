import requests
import json

url = "https://api.studio.thegraph.com/proxy/53925/swap-subgraph/v0.0.4"

query = """
query highestNewRv($first: Int, $skip: Int) {
  volatilityUpdateds(first: $first, skip: $skip, orderBy: blockTimestamp, orderDirection: asc, subgraphError: allow) {
    id
    newRv
    blockNumber
    blockTimestamp
  }
}
"""

def fetch_all_volatility_updates():
    all_volatility_updates = []
    skip = 0
    first = 500

    while True:
        variables = {
            "first": first,
            "skip": skip
        }

        response = requests.post(url, json={'query': query, 'variables': variables})
        data = response.json()

        if 'errors' in data:
            print("Error fetching data:", data['errors'])
            break

        entries = data['data']['volatilityUpdateds']
        
        for entry in entries:
            # Collecting newRv and blockTimestamp as an object
            all_volatility_updates.append({
                "newRv": int(entry['newRv']),
                "blockTimestamp": int(entry['blockTimestamp'])
            })

        if len(entries) < first:
            break

        skip += first

    # Optionally sort again by blockTimestamp (if not already sorted by the GraphQL query)
    all_volatility_updates.sort(key=lambda x: x['blockTimestamp'])

    return all_volatility_updates

volatility_updates = fetch_all_volatility_updates()

output_data = {
    "volatilityUpdates": volatility_updates
}

with open('volatility_updates.json', 'w') as f:
    json.dump(output_data, f, indent=4)

print(f"Saved {len(volatility_updates)} volatility updates to volatility_updates.json")

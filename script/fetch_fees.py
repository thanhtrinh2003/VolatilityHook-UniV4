import requests
import json

url = "https://api.studio.thegraph.com/proxy/53925/swap-subgraph/v0.0.4"

query = """
query highestNewRv($first: Int, $skip: Int) {
  volatilityUpdateds(first: $first, skip: $skip, orderBy: newRv, orderDirection: asc, subgraphError: allow) {
    id
    newRv
    blockNumber
    blockTimestamp
  }
}
"""

def fetch_all_volatility_updates():
    all_new_rv_values = []
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
            all_new_rv_values.append(int(entry['newRv']))

        if len(entries) < first:
            break

        skip += first

    return all_new_rv_values

new_rv_values = fetch_all_volatility_updates()

output_data = {
    "newRvValues": new_rv_values
}

with open('volatility_updates.json', 'w') as f:
    json.dump(output_data, f, indent=4)

print(f"Saved {len(new_rv_values)} newRv values to volatility_updates.json")

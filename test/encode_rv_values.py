import json
from eth_abi import encode

with open('./notes/volatility_updates.json', 'r') as file:
    data = json.load(file)

new_rv_values = [int(update["newRv"]) for update in data["volatilityUpdates"]]

encoded_data = encode(['uint256[]'], [new_rv_values])

print(encoded_data.hex())

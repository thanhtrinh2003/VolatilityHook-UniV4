import json
from eth_abi import encode

with open('./test/volatility_updates.json', 'r') as file:
    data = json.load(file)

new_rv_values = [int(value) for value in data["newRvValues"]]

encoded_data = encode(['uint256[]'], [new_rv_values])

print(encoded_data.hex())

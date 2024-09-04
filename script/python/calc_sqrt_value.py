import math
def sqrt_price_x96_to_price(sqrt_price_x96):
    # Step 1: Convert to a floating-point number by dividing by 2^96
    sqrt_price = sqrt_price_x96 / (2 ** 96)
    
    # Step 2: Square the result to get the normal price
    price = sqrt_price ** 2
    
    return price

# Example SqrtPriceX96 value


def price_to_sqrt_price_x96(price):
    # Step 1: Take the square root of the price
    sqrt_price = math.sqrt(price)
    
    # Step 2: Convert to SqrtPriceX96 by multiplying by 2^96
    sqrt_price_x96 = int(sqrt_price * (2 ** 96))
    
    return sqrt_price_x96

sqrt_price_x96 = 4687201305027700855787468357632  

price = sqrt_price_x96_to_price(sqrt_price_x96)
print(f"The price is: {price}")

sqrt_price = price_to_sqrt_price_x96(3700)
print(f"The sqrt_price is: {sqrt_price}")
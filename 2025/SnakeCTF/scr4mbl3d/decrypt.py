#!/usr/bin/env python3

from hashlib import sha256

# Constants from the source file
P = 112100829556962061444927618073086278041158621998950683631735636667566868795947
EXPONENT = 3
CIPHERTEXT = 0xcb8c5149e59450f1dfaa58a2587acdb11793ef2ab50379e0986a383e69f7c6d3591e9b71fc789a82d65b64f9277008f32580240a6dd7e8c7b9a5d5b25803a73f

# Re-implement the necessary functions from the source
def split(x):
    return x // P, x % P

def merge(chunk1, chunk2):
    return chunk1 * P + chunk2

def ff(x):
    return ((x * EXPONENT) * 0x5DEECE66D) % P

def gg(x):
    digest = sha256(int(x).to_bytes(256, 'big')).digest()
    return int.from_bytes(digest, 'big') % P

# The main decryption logic
def decrypt(ciphertext, rounds):
    # Generate the same constants used for encryption
    constants = [(44 * i ^ 3 + 98 * i ^ 2 + 172 * i + 491) % P for i in range(rounds)]
    
    chunk1, chunk2 = split(ciphertext)

    # Run the rounds in reverse order (from rounds-1 down to 0)
    for i in range(rounds - 1, -1, -1):
        # Determine which function was used in this round
        if i % 11 == 0:
            f = ff
        else:
            f = gg

        # Reverse the Feistel network step
        if i % 5 == 0:
            # Original: chunk1, chunk2 = transform(chunk1, chunk2, i)
            # new_c1 = old_c2 + f(old_c1) + C
            # new_c2 = old_c1
            # Reverse:
            old_c1 = chunk2
            old_c2 = (chunk1 - f(old_c1) - constants[i]) % P
            chunk1, chunk2 = old_c1, old_c2
        else:
            # Original: chunk2, chunk1 = transform(chunk2, chunk1, i)
            # new_c2 = old_c1 + f(old_c2) + C
            # new_c1 = old_c2
            # Reverse:
            old_c2 = chunk1
            old_c1 = (chunk2 - f(old_c2) - constants[i]) % P
            chunk1, chunk2 = old_c1, old_c2
            
    return merge(chunk1, chunk2)

# Brute-force the number of rounds
print("[*] Starting brute-force attack on the number of rounds...")
for r in range(26, 54): # Range is 26 to 53 inclusive
    try:
        decrypted_int = decrypt(CIPHERTEXT, r)
        
        # Convert the resulting integer back to bytes
        decrypted_bytes = decrypted_int.to_bytes(256, 'big').strip(b'\x00')

        # Check if the result is a printable ASCII string (a good sign for a flag)
        if decrypted_bytes.isascii() and all(c in range(32, 127) for c in decrypted_bytes):
             print(f"\n[+] Success! Found potential flag with {r} rounds:")
             print(f"    Flag: {decrypted_bytes.decode()}")
             break
    except Exception:
        # Ignore errors if the byte conversion fails
        continue
else:
    print("\n[-] Failed to find the flag in the given range of rounds.")

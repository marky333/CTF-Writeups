#!/usr/bin/env sage

from Crypto.Hash import SHAKE256
from Crypto.Util.Padding import unpad
from Crypto.Util.number import long_to_bytes
import ast

def solve():
    """
    Recovers the flag by reversing the custom hash function.
    """
    # 1. Re-initialize parameters from the source file
    p = 65537
    nbytes = p.bit_length() // 8
    state_size = 24
    rounds = 3
    F = GF(p)

    # 2. Regenerate the round constants
    shake = SHAKE256.new()
    shake.update(b"SNAKECTF")
    constants = [F(int.from_bytes(shake.read(nbytes), 'big')) for _ in range(rounds)]
    c0, c1, c2 = constants[0], constants[1], constants[2]

    # 3. Read the digest and IV from the output file
    try:
        with open("out.txt", "r") as f:
            lines = f.readlines()
            if len(lines) < 2:
                print("Error: out.txt is missing data.")
                return
            # Use ast.literal_eval to safely parse the string representation of the list
            digest_list = ast.literal_eval(lines[0].strip())
            IV_list = ast.literal_eval(lines[1].strip())
            digest = vector(F, digest_list)
            IV = vector(F, IV_list)
    except FileNotFoundError:
        print("Error: out.txt not found.")
        return
    except (ValueError, SyntaxError):
        print("Error: Could not parse out.txt. Check file format.")
        return

    # 4. Define the core permutation function, g(z) = P(z)
    def g(z):
        state = z^3 + c0
        state = state^3 + c1
        state = state^3 + c2
        return state

    # 5. Solve for the input state by solving systems of polynomial equations
    input_state = [0] * state_size
    is_fully_solved = True

    # Define a polynomial ring in two variables over the finite field F
    P.<x, y> = PolynomialRing(F, 2)

    print("Solving for input state pairs using algebraic method...")
    for i in range(0, state_size, 2):
        d_x, d_y = digest[i], digest[i+1]
        iv_x, iv_y = IV[i], IV[i+1]

        # Define the system of equations for the current pair
        eq1 = g(x + iv_x) + y - d_x
        eq2 = g(y + iv_y) + x - d_y

        # Create an ideal and compute its variety (the set of solutions)
        I = ideal(eq1, eq2)
        solutions = I.variety()
        
        selected_solution = None
        if len(solutions) == 1:
            selected_solution = solutions[0]
            print(f"  [+] Found unique solution for pair {i//2} (indices {i}, {i+1}).")
        elif len(solutions) > 1:
            plausible_solutions = []
            for sol in solutions:
                try:
                    # Heuristic: the flag is printable ASCII. Filter solutions based on this.
                    x_bytes = long_to_bytes(int(sol[x]), nbytes)
                    y_bytes = long_to_bytes(int(sol[y]), nbytes)
                    
                    # All non-null bytes in a chunk must be printable ASCII
                    is_plausible_x = all(32 <= b <= 126 for b in x_bytes if b != 0)
                    is_plausible_y = all(32 <= b <= 126 for b in y_bytes if b != 0)

                    if is_plausible_x and is_plausible_y:
                        plausible_solutions.append(sol)
                except Exception:
                    continue
            
            if len(plausible_solutions) == 1:
                selected_solution = plausible_solutions[0]
                print(f"  [+] Filtered to a unique plausible solution for pair {i//2}.")
            elif len(plausible_solutions) > 1:
                selected_solution = plausible_solutions[0]
                print(f"  [!] Ambiguity: Found {len(plausible_solutions)} plausible solutions for pair {i//2}. Using the first.")
            else:
                # Fallback to the original first solution if no plausible one is found
                selected_solution = solutions[0]
                print(f"  [!] Warning: No plausible ASCII solution found for pair {i//2}. Using first raw solution.")

        if selected_solution:
            input_state[i] = selected_solution[x]
            input_state[i+1] = selected_solution[y]
        else: # No solutions found
            print(f"  [-] No solution found for pair {i//2}. Aborting.")
            is_fully_solved = False
            break

    if not is_fully_solved:
        return

    # 6. Reconstruct the padded message from the solved state
    padded_message_bytes = b"".join([long_to_bytes(int(val), nbytes) for val in input_state])

    # 7. Unpad the message to reveal the original flag
    try:
        # The block size for padding is the total size of the state in bytes
        block_size = state_size * nbytes
        message = unpad(padded_message_bytes, block_size)
        print("\n[+] Successfully recovered the flag!")
        print(f"    Flag: {message.decode()}")
    except ValueError as e:
        print(f"\n[-] Error unpadding the recovered message: {e}")
        print(f"    Padded message (hex): {padded_message_bytes.hex()}")

if __name__ == "__main__":
    solve()


CTF Write-up: Reversing the Babylon Hash Function
1. Introduction
The "unf33dme" challenge requires reversing a custom hash function, implemented in SageMath, to recover the original input flag. The core of the challenge lies in understanding the structure of the hash algorithm, identifying a critical weakness in its mixing layer, and leveraging that weakness to reconstruct the input state piece by piece. The provided outputs are the final digest and the random IV (Initialization Vector) used in the process.

2. Analysis of the Hash Function
The hashing algorithm, named Babylon, operates on a state of 24 elements within the finite field GF(p), where p=65537. The input message (the flag) is first padded to fill this 24-element state.

The hashing process can be summarized as follows:

Initialization: The padded input message (input) is added element-wise to a random IV. Let's call this initial state s_0=input+IV.

Permutation (P): The state s_0 is passed through a 3-round permutation function. Each round consists of:

S-Box: A non-linear cubing operation (state→state 
3
 ).

AddConstant: A round-specific constant is added to each element of the state.
The output of this permutation is output=P(s_0)=P(input+IV).

Finalization: The final digest is computed by adding the permuted state (output) to a shuffled version of the original input:
digest=output+shuffle(input)

3. The Vulnerability: Decoupling the System
The critical vulnerability lies in the shuffle function and its interaction with the final addition. The shuffle operation is very simple: it just swaps adjacent elements.

Python

def shuffle(self, state):
    for i in range(0, self.state_size, 2):
        t = state[i]
        state[i] = state[i + 1]
        state[i + 1] = t
    return state
This means that for any even index i, shuffle(input)[i] is input[i+1] and shuffle(input)[i+1] is input[i].

Because the permutation P is also applied element-wise (i.e., output[i] only depends on input[i] and IV[i]), the calculation for each pair of elements (digest[i], digest[i+1]) is completely independent of all other pairs in the state.

This allows us to break the problem of solving for 24 unknown variables simultaneously into 12 independent problems of solving for just 2 variables. For each even index i, we get the following system of two equations:

digest[i]=P(input[i]+IV[i])+input[i+1]

digest[i+1]=P(input[i+1]+IV[i+1])+input[i]

Since digest and IV are known, this is a solvable system for the two unknowns, input[i] and input[i+1].

4. The Exploit: Algebraic Solution
While an iterative approach to solving this system is possible, it proved to be unstable. A more robust method is to solve it algebraically.

Let x=input[i] and y=input[i+1]. We can define a polynomial ring over the finite field F and express our system as:

P(x+iv_i)+y−digest_i=0

P(y+iv_i+1)+x−digest_i+1=0

SageMath's algebraic machinery can find all solutions (the "variety") to this system of polynomial equations.

5. Handling Ambiguity with a Heuristic
A complication arises: for some pairs, the algebraic solver returns multiple mathematically valid solutions. To find the correct one, we apply a powerful heuristic: the flag consists of printable ASCII characters.

The exploit script iterates through the solutions for each pair and filters them:

For a given solution (x, y), convert the integer values of x and y back into their byte representations.

Check if all non-null bytes fall within the printable ASCII range (32-126).

If only one solution for a pair satisfies this condition, it is selected as the correct one.

This heuristic proved extremely effective, successfully disambiguating the multiple solutions and allowing for the reconstruction of the correct pre-image.

6. Flag Recovery
Once the correct (x, y) pair is found for each of the 12 systems, the full input_state is reassembled. This state represents the original flag with PKCS7 padding. The final step is to convert the state vector to bytes and apply the unpad function, which reveals the final flag.
<img width="719" height="517" alt="image" src="https://github.com/user-attachments/assets/c729e739-1171-40fe-b876-af54497837c2" />

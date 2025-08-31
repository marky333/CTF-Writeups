You are given two files. The first is a Python script that encrypts a flag, and the second is the output of that script. Your task is to reverse the encryption and find the flag.

Provided Files
Here is the context and content of the files you were given:

[source.py](https://github.com/marky333/CTF-Writeups/blob/main/2025/SnakeCTF/scr4mbl3d/source.py)

[Output](https://github.com/marky333/CTF-Writeups/blob/main/2025/SnakeCTF/scr4mbl3d/out.txt)

This was a fun cryptography challenge that involved analyzing a Python script to reverse an encryption scheme. The core of the challenge was identifying a classic cipher structure and dealing with a small, unknown parameter.

🔎 Analysis
We were given a Python script, source.py, and the encrypted output, out.txt. The goal was to reverse the encryption to find the flag.

The script's encryption logic had a few key components:

A random number of ROUNDS between 26 and 53. This was the first major unknown.

A reversible function, ff(x).

A one-way hash function, gg(x), which used SHA256. This seemed to make the cipher irreversible.

The breakthrough came from analyzing the encryption loop and the transform function. The structure of the operation was:

new_chunk1 = old_chunk2 + F(old_chunk1)
new_chunk2 = old_chunk1

This is a classic Feistel Network. 💡

The most important property of a Feistel cipher is that the round function (F, which was either ff or gg in this case) does not need to be invertible for the entire cipher to be decryptable. This meant the one-way gg() function wasn't an obstacle after all.

🎯 The Decryption Strategy
With the Feistel structure identified, the path to the solution was clear:

Brute-force ROUNDS: Since the range of possible rounds was small (26 to 53), we could simply try every value.

Implement Reverse Rounds: For each guess, we run the encryption process in reverse. We start with the final ciphertext chunks and iterate backward from the last round to the first.

Reverse the transform: In each round, we apply the reverse Feistel logic. Instead of adding the output of the round function, we subtract it.

Check the Output: After running all rounds in reverse, we merge the chunks back into a single number and convert it to bytes. If our guess for ROUNDS was correct, the output would be a printable ASCII string containing the flag.

👨‍💻 Solution Script
The following Python script implements this decryption strategy.

[Decrypt Code](https://github.com/marky333/CTF-Writeups/blob/main/2025/SnakeCTF/scr4mbl3d/decrypt.py)

On running the code i got the flag

<img width="785" height="236" alt="image" src="https://github.com/user-attachments/assets/d71a2ad7-9c6f-41e4-be1f-63b93c5a0bf8" />

snakeCTF{Ev3ry7hing_1s_34s13r_w1th_F3is7el_f150d1bcd4f05a7e}

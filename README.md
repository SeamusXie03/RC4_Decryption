# RC4 Decryption Implementation on FPGA

## Overview

This project implements an RC4 Decryption circuit on an FPGA, supporting up to four cores operating simultaneously. RC4 is a stream cipher used for decrypting messages encrypted with the RC4 algorithm. The FPGA is configured to take a secret key from hardware switches and decrypt an encrypted message stored in on-chip memory.

The original software code:
'''c
// initialize s array. Accelerated in hardware
for i = 0 to 255 {
    s[i] = i;
}

// shuffle the array based on the secret key. Accelerated in hardware
j = 0
for i = 0 to 255 {
    j = (j + s[i] + secret_key[i mod keylength] ) //keylength is 3 in our impl. swap values of s[i] and s[j]
}

// compute one byte per character in the encrypted message. Accelerated in hardware
i = 0, j = 0
for k = 0 to message_length-1 { // message_length is 32 in our implementation
    i = i + 1
    j = j + s[i]
    swap values of s[i] and s[j]
    f = s[ (s[i] + s[j]) ]
    decrypted_output[k] = f xor encrypted_input[k]
    // 8 bit wide XOR function
}
'''
## Features

- **Multi-Core Support:** The implementation supports up to four decryption cores running simultaneously, enhancing the efficiency of the key search process.

- **On-Chip Memory:** Utilizes on-chip memories for storing the initial secret key, encrypted message, and the results of the decryption.

- **LED Indicators:** LEDs are used to indicate the status of the key search process. One LED turns on when a correct message is found, and another LED turns on if the search completes without finding a correct message.

- **Hexadecimal Display:** Displays the currently considered key on a 6-digit hexadecimal display.

## Getting Started

### Prerequisites

- FPGA board (DE1-SoC)
- Quartus Prime software
- USB Blaster or another programming method for FPGA

### Installation

1. Clone the repository to your local machine.

```bash
git clone https://github.com/yourusername/rc4-fpga.git
```

2. Open the Quartus project file in the Quartus Prime software.

3. Configure the FPGA with the provided bitstream.

4. Connect the FPGA board to your computer.

5. Run the implementation on the FPGA.

## Usage

1. Set the secret key using the hardware switches on the FPGA board.

2. Load the encrypted message into the on-chip ROM.

3. Run the decryption process.

4. Observe LED indicators:
   - One LED indicates a correct message is found.
   - Another LED indicates the search is complete without finding a correct message.

5. Monitor the Hexadecimal Display to view the currently considered key.

## Demo

For a demonstration, the project includes sample encrypted messages in the `secret_messages` folder. Follow the Usage instructions to decrypt these messages.

## Multi-Core Cracking

This implementation supports a challenge task that involves accelerating the key search by using multiple decryption cores. For details on the challenge task, refer to the project documentation.

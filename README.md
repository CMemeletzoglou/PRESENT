# PRESENT
Synthesizable implementation of a Cryptographic Coprocessor of the PRESENT Lightweight Block Cipher (supporting encryption and decryption, and both 80-bit and 128-bit keys), and some Hardware Trojans, using VHDL.

Simulation, Synthesis & Implementation was done using Xilinx's Vivado suite, targeting a Spartan 7 FPGA.

## Hardware Trojans
9 Functional Hardware Trojans were designed with various Triggering conditions and Payloads ranging from fault injection attacks, to disrupting the system's expected behaviour to DoS attacks.

|               |                                 **Trigger**                                 |                    **Payload**                    |
|:-------------:|:---------------------------------------------------------------------------:|:-------------------------------------------------:|
| **Trojan #1** |                        data_in = 0x1234ABBA5678DEED                         |            Flip each Round Key's LSBit            |
| **Trojan #2** |                         data_in(47:44) = K_13(17:14)                        |            Disable Encryption Datapath            |
| **Trojan #3** |                             data_in(3:0) = 1011                             |           Flip output mux select signal           |
| **Trojan #4** |                           key(7:0) = data_in(7:0)                           |           Disable *ready* output signal           |
| **Trojan #5** |                      key(7:0) = 0x1A && mode_sel(1) = 0                     |       Replace input key with predefined key       |
| **Trojan #6** |                   Timebomb: Completion of 2^10 operations                   | Disallow computed data from appearing on data_out |
| **Trojan #7** |                         Timebomb: 2^10 mode changes                         |                 Flip data_in LSBit                |
| **Trojan #8** | Timebomb: data_in(59:56) = ciphertext(43:40) && <br> mode_sel(0) = 0, 2^12 times |                    Leak data_in                   |
| **Trojan #9** |                 Timebomb: ciphertext(63) = 0 for 2^15 times                 |       DoS attack : raise system reset signal      |

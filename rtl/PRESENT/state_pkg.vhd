package state_pkg is
        -- type STATE is (RESET, INIT, KEY_GEN, KEYS_READY, OP_ENC, OP_DEC, DONE, INVALID);
        -- removed : RESET, KEYS_READY as redundant states, but can we remove the DONE state?
        -- to do that, we would probably need another "if" inside the OP_ENC/OP_DEC states, to 
        -- make the changes that the DONE state does.. However, we can keep the DONE state, and
        -- while there, we can maybe load the next plaintext/ciphertext, to mask the one cycle delay
        -- of the state register at the input of the encryption/decryption datapaths.
        type STATE is (INIT, KEY_GEN, OP_ENC, OP_DEC, DONE, INVALID);
         
--        type STATE is (RESET, INIT, COUNTING, DONE, INVALID);
end package;
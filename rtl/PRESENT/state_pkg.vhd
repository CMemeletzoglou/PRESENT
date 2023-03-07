package state_pkg is
        type STATE is (RESET, INIT, KEY_GEN, KEYS_READY, OP_ENC, OP_DEC, DONE, INVALID);
         
--        type STATE is (RESET, INIT, COUNTING, DONE, INVALID);
end package;
create_clock -period 5.200 -name clk -waveform {0.000 2.600} [get_ports -filter { NAME =~  "*clk*" && DIRECTION == "IN" }]






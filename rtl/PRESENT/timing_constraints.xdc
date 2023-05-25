create_clock -period 3.4 -name clk -waveform {0.000 1.7} [get_ports -filter { NAME =~  "*clk*" && DIRECTION == "IN" }]












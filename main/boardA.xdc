#set_property PACKAGE_PIN A18 [get_ports tx]
#set_property PACKAGE_PIN B18 [get_ports rx]

#set_property PACKAGE_PIN T18 [get_ports start_btn]
#set_property PACKAGE_PIN U18 [get_ports reset]
#set_property PACKAGE_PIN W5 [get_ports clk]
#set_property IOSTANDARD LVCMOS33 [get_ports clk]
#set_property IOSTANDARD LVCMOS33 [get_ports reset]
#set_property IOSTANDARD LVCMOS33 [get_ports start_btn]
#set_property IOSTANDARD LVCMOS33 [get_ports tx]
#set_property IOSTANDARD LVCMOS33 [get_ports rx]


# Constraints for Board A (Basys3 rev C)

# System clock & reset
set_property PACKAGE_PIN W5  [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports  clk]
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# USB-UART RX (FTDI TXD) ? rx port
set_property PACKAGE_PIN B18 [get_ports ftdi_rx]
set_property IOSTANDARD LVCMOS33 [get_ports ftdi_rx]

# PMOD JA1 ? tx port
set_property PACKAGE_PIN J1  [get_ports ja_tx]
set_property IOSTANDARD LVCMOS33 [get_ports ja_tx]

#set_property PACKAGE_PIN W13 [get_ports {data_in[7]}]
#set_property PACKAGE_PIN W14 [get_ports {data_in[6]}]
#set_property PACKAGE_PIN V15 [get_ports {data_in[5]}]
#set_property PACKAGE_PIN W15 [get_ports {data_in[4]}]
#set_property PACKAGE_PIN W17 [get_ports {data_in[3]}]
#set_property PACKAGE_PIN W16 [get_ports {data_in[2]}]
#set_property PACKAGE_PIN V16 [get_ports {data_in[1]}]
#set_property PACKAGE_PIN V17 [get_ports {data_in[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {data_in[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {data_in[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {data_in[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {data_in[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {data_in[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {data_in[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {data_in[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {data_in[0]}]

## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## SPI configuration mode options for QSPI boot, can be used for all designs
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
# Timing Constraint
create_clock -period 6.666 -name s_px_clk -waveform {0.000 3.333} -add [get_ports SYS_CLK_I]

# Clock Source - Bank 13
set_property PACKAGE_PIN Y9 [get_ports {SYS_CLK_I}];  # "GCLK"

# User LEDs - Bank 33
# set_property PACKAGE_PIN T22 [get_ports {led_o[0]}];  # "LD0"
# set_property PACKAGE_PIN T21 [get_ports {led_o[1]}];  # "LD1"
# set_property PACKAGE_PIN U22 [get_ports {led_o[2]}];  # "LD2"
# set_property PACKAGE_PIN U21 [get_ports {led_o[3]}];  # "LD3"
# set_property PACKAGE_PIN V22 [get_ports {led_o[4]}];  # "LD4"
# set_property PACKAGE_PIN W22 [get_ports {led_o[5]}];  # "LD5"
# set_property PACKAGE_PIN U19 [get_ports {led_o[6]}];  # "LD6"
# set_property PACKAGE_PIN U14 [get_ports {led_o[7]}];  # "LD7"

# VGA Output - Bank 33

set_property PACKAGE_PIN V20  [get_ports {VGA_R_O[0]}];  # "VGA-R1"
set_property PACKAGE_PIN U20  [get_ports {VGA_R_O[1]}];  # "VGA-R2"
set_property PACKAGE_PIN V19  [get_ports {VGA_R_O[2]}];  # "VGA-R3"
set_property PACKAGE_PIN V18  [get_ports {VGA_R_O[3]}];  # "VGA-R4"
set_property PACKAGE_PIN AB22 [get_ports {VGA_G_O[0]}];  # "VGA-G1"
set_property PACKAGE_PIN AA22 [get_ports {VGA_G_O[1]}];  # "VGA-G2"
set_property PACKAGE_PIN AB21 [get_ports {VGA_G_O[2]}];  # "VGA-G3"
set_property PACKAGE_PIN AA21 [get_ports {VGA_G_O[3]}];  # "VGA-G4"
set_property PACKAGE_PIN Y21  [get_ports {VGA_B_O[0]}];  # "VGA-B1"
set_property PACKAGE_PIN Y20  [get_ports {VGA_B_O[1]}];  # "VGA-B2"
set_property PACKAGE_PIN AB20 [get_ports {VGA_B_O[2]}];  # "VGA-B3"
set_property PACKAGE_PIN AB19 [get_ports {VGA_B_O[3]}];  # "VGA-B4"
set_property PACKAGE_PIN AA19 [get_ports {VGA_HSYNC_O}];  # "VGA-HS"
set_property PACKAGE_PIN Y19  [get_ports {VGA_VSYNC_O}];  # "VGA-VS"

# User Push Buttons - Bank 34
set_property PACKAGE_PIN P16 [get_ports {RST_I}];  # "BTNC" -- pullups?
# set_property PACKAGE_PIN R16 [get_ports {btnd_i}];  # "BTND" -- pullups?
# set_property PACKAGE_PIN N15 [get_ports {btnl_i}];  # "BTNL" -- pullups?
# set_property PACKAGE_PIN R18 [get_ports {btnr_i}];  # "BTNR" -- pullups?
# set_property PACKAGE_PIN T18 [get_ports {btnu_i}];  # "BTNU" -- pullups?

## User DIP Switches - Bank 35
set_property PACKAGE_PIN F22 [get_ports {FONT_SEL_I[0]}];  # "SW0"
set_property PACKAGE_PIN G22 [get_ports {FONT_SEL_I[1]}];  # "SW1"
# set_property PACKAGE_PIN H22 [get_ports {sw_i[2]}];  # "SW2"
# set_property PACKAGE_PIN F21 [get_ports {sw_i[3]}];  # "SW3"
# set_property PACKAGE_PIN H19 [get_ports {sw_i[4]}];  # "SW4"
set_property PACKAGE_PIN H18 [get_ports {RES_SEL_I[0]}];  # "SW5"
set_property PACKAGE_PIN H17 [get_ports {RES_SEL_I[1]}];  # "SW6"
set_property PACKAGE_PIN M15 [get_ports {RES_SEL_I[2]}];  # "SW7"

# Note that the bank voltage for IO Bank 33 is fixed to 3.3V on ZedBoard. 
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];

# Set the bank voltage for IO Bank 34 to 1.8V by default.
# set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 34]];
# set_property IOSTANDARD LVCMOS25 [get_ports -of_objects [get_iobanks 34]];
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];

# Set the bank voltage for IO Bank 35 to 1.8V by default.
# set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 35]];
# set_property IOSTANDARD LVCMOS25 [get_ports -of_objects [get_iobanks 35]];
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];

# Note that the bank voltage for IO Bank 13 is fixed to 3.3V on ZedBoard. 
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];

set_property PACKAGE_PIN Y21 [get_ports {blue[0]}]; # "VGA-B0"
set_property PACKAGE_PIN Y20 [get_ports {blue[1]}]; # "VGA-B1"
set_property PACKAGE_PIN AB20 [get_ports {blue[2]}]; # "VGA-B2"
set_property PACKAGE_PIN AB19 [get_ports {blue[3]}]; # "VGA-B3"
set_property PACKAGE_PIN AB22 [get_ports {green[0]}]; # "VGA-G0"
set_property PACKAGE_PIN AA22 [get_ports {green[1]}]; # "VGA-G1"
set_property PACKAGE_PIN AB21 [get_ports {green[2]}]; # "VGA-G2"
set_property PACKAGE_PIN AA21 [get_ports {green[3]}]; # "VGA-G3"
set_property PACKAGE_PIN V20 [get_ports {red[0]}]; # "VGA-R0"
set_property PACKAGE_PIN U20 [get_ports {red[1]}]; # "VGA-R1"
set_property PACKAGE_PIN V19 [get_ports {red[2]}]; # "VGA-R2"
set_property PACKAGE_PIN V18 [get_ports {red[3]}]; # "VGA-R3"
set_property PACKAGE_PIN AA19 [get_ports {hsync}]; # "VGA-HS"
set_property PACKAGE_PIN Y19 [get_ports {vsync}]; # "VGA-VS"
# All VGA pins are connected by bank 33, so specified 3.3V together.
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];
set_property PACKAGE_PIN Y9 [get_ports {clk}]; # "clk"
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];


set_property PACKAGE_PIN T18 [get_ports {BTNU}];  # "BTNU"
    set_property IOSTANDARD LVCMOS25 [get_ports {BTNU}];
set_property PACKAGE_PIN R16 [get_ports {BTND}];  # "BTND"
    set_property IOSTANDARD LVCMOS25 [get_ports {BTND}];
set_property PACKAGE_PIN N15 [get_ports {BTNL}];  # "BTNL"
    set_property IOSTANDARD LVCMOS25 [get_ports {BTNL}];
set_property PACKAGE_PIN R18 [get_ports {BTNR}];  # "BTNR"
    set_property IOSTANDARD LVCMOS25 [get_ports {BTNR}];
    
#set_property PACKAGE_PIN U14 [get_ports {debug[0]}];  # "LD7"
#    set_property IOSTANDARD LVCMOS33 [get_ports {debug[0]}];
#set_property PACKAGE_PIN U19 [get_ports {debug[1]}];  # "LD7"
#    set_property IOSTANDARD LVCMOS33 [get_ports {debug[1]}];
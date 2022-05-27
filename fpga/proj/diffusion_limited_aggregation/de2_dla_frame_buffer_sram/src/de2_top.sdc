

##
## DEVICE  "EP2C35F672C7"
##


#**************************************************************
# Time Information
#**************************************************************




#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLOCK_50} -period 20.000 [get_ports {CLOCK_50}]


#**************************************************************
# Create Generated Clock
#**************************************************************

derive_pll_clocks -create_base_clocks

set sys_clk "u_altpllvga|altpll_component|pll|clk[0]"
set VGA_CLK "u_altpllvga|altpll_component|pll|clk[1]"

#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -clock sys_clk 10 [get_ports SRAM_DQ[*]]

#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -clock sys_clk 10 [get_ports SRAM_DQ[*] ]
set_output_delay -clock sys_clk 10 [get_ports SRAM_ADDR[*] ]
set_output_delay -clock sys_clk 10 [get_ports SRAM_UB_N ]
set_output_delay -clock sys_clk 10 [get_ports SRAM_LB_N ]
set_output_delay -clock sys_clk 10 [get_ports SRAM_WE_N ]
set_output_delay -clock sys_clk 10 [get_ports SRAM_CE_N ]
set_output_delay -clock sys_clk 10 [get_ports SRAM_OE_N ]

#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {sys_clk}]
set_clock_groups -asynchronous -group [get_clocks {VGA_CLK}]
set_clock_groups -asynchronous -group [get_clocks {CLOCK_50}]

#**************************************************************
# Set False Path
#**************************************************************


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************


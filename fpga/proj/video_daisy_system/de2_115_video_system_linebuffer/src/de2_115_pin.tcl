
#============================================================
# CLOCK
#============================================================
set_location_assignment PIN_Y2 -to CLOCK_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK_50

#============================================================
# KEY
#============================================================
set_location_assignment PIN_M23 -to KEY[0]
set_location_assignment PIN_M21 -to KEY[1]
set_location_assignment PIN_N21 -to KEY[2]
set_location_assignment PIN_R24 -to KEY[3]
set_instance_assignment -name IO_STANDARD "2.5 V" -to KEY[0]
set_instance_assignment -name IO_STANDARD "2.5 V" -to KEY[1]
set_instance_assignment -name IO_STANDARD "2.5 V" -to KEY[2]
set_instance_assignment -name IO_STANDARD "2.5 V" -to KEY[3]

#============================================================
# SW
#============================================================
set_location_assignment PIN_AB28 -to SW[0]
set_location_assignment PIN_AC28 -to SW[1]
set_location_assignment PIN_AC27 -to SW[2]
set_location_assignment PIN_AD27 -to SW[3]
set_location_assignment PIN_AB27 -to SW[4]
set_location_assignment PIN_AC26 -to SW[5]
set_location_assignment PIN_AD26 -to SW[6]
set_location_assignment PIN_AB26 -to SW[7]
set_location_assignment PIN_AC25 -to SW[8]
set_location_assignment PIN_AB25 -to SW[9]
set_location_assignment PIN_AC24 -to SW[10]
set_location_assignment PIN_AB24 -to SW[11]
set_location_assignment PIN_AB23 -to SW[12]
set_location_assignment PIN_AA24 -to SW[13]
set_location_assignment PIN_AA23 -to SW[14]
set_location_assignment PIN_AA22 -to SW[15]
set_location_assignment PIN_Y24 -to SW[16]
set_location_assignment PIN_Y23 -to SW[17]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[0]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[1]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[2]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[3]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[4]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[5]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[6]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[7]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[8]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[9]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[10]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[11]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[12]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[13]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[14]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[15]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[16]
set_instance_assignment -name IO_STANDARD "2.5 V" -to SW[17]

#============================================================
# VGA
#============================================================
set_location_assignment PIN_D12 -to VGA_B[7]
set_location_assignment PIN_D11 -to VGA_B[6]
set_location_assignment PIN_C12 -to VGA_B[5]
set_location_assignment PIN_A11 -to VGA_B[4]
set_location_assignment PIN_B11 -to VGA_B[3]
set_location_assignment PIN_C11 -to VGA_B[2]
set_location_assignment PIN_A10 -to VGA_B[1]
set_location_assignment PIN_B10 -to VGA_B[0]
set_location_assignment PIN_C9 -to VGA_G[7]
set_location_assignment PIN_F10 -to VGA_G[6]
set_location_assignment PIN_B8 -to VGA_G[5]
set_location_assignment PIN_C8 -to VGA_G[4]
set_location_assignment PIN_H12 -to VGA_G[3]
set_location_assignment PIN_F8 -to VGA_G[2]
set_location_assignment PIN_G11 -to VGA_G[1]
set_location_assignment PIN_G8 -to VGA_G[0]
set_location_assignment PIN_H10 -to VGA_R[7]
set_location_assignment PIN_H8 -to VGA_R[6]
set_location_assignment PIN_J12 -to VGA_R[5]
set_location_assignment PIN_G10 -to VGA_R[4]
set_location_assignment PIN_F12 -to VGA_R[3]
set_location_assignment PIN_D10 -to VGA_R[2]
set_location_assignment PIN_E11 -to VGA_R[1]
set_location_assignment PIN_E12 -to VGA_R[0]
set_location_assignment PIN_A12 -to VGA_CLK
set_location_assignment PIN_F11 -to VGA_BLANK_N
set_location_assignment PIN_C10 -to VGA_SYNC_N
set_location_assignment PIN_G13 -to VGA_HS
set_location_assignment PIN_C13 -to VGA_VS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_HS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_VS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_SYNC_N
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_CLK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_BLANK_N
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_G[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_B[7]

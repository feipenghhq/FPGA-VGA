# ---------------------------------------------------------------
# Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
# Author: Heqing Huang
# Date Created: 04/19/2022
# ---------------------------------------------------------------
# Tcl Script for Quartus
# ---------------------------------------------------------------

# ------------------------------------------
# Create project and read in rtl files
# ------------------------------------------

set QUARTUS_PART        $::env(QUARTUS_PART)
set QUARTUS_FAMILY      $::env(QUARTUS_FAMILY)
set QUARTUS_PRJ         $::env(QUARTUS_PRJ)
set QUARTUS_TOP         $::env(QUARTUS_TOP)
set QUARTUS_VERILOG     $::env(QUARTUS_VERILOG)
set QUARTUS_SEARCH      $::env(QUARTUS_SEARCH)
set QUARTUS_SDC         $::env(QUARTUS_SDC)
set QUARTUS_QIP         $::env(QUARTUS_QIP)
set QUARTUS_PIN         $::env(QUARTUS_PIN)


# Load Quartus II Tcl Project package
package require ::quartus::project
project_new $QUARTUS_PRJ -overwrite -part $QUARTUS_PART -family $QUARTUS_FAMILY

# Porject Assignment
set_global_assignment -name VERILOG_MACRO "SYNTHESIS=1"
set_global_assignment -name TOP_LEVEL_ENTITY $QUARTUS_TOP

# Read in RTL SEARCH file
foreach vlog $QUARTUS_SEARCH {
    set pre "Reading RTL SEARCH path: "
    puts [append pre $vlog]
    set_global_assignment -name SEARCH_PATH $vlog
}


# Read in RTL
foreach vlog $QUARTUS_VERILOG {
    set pre "Reading RTL file: "
    puts [append pre $vlog]
    set_global_assignment -name SYSTEMVERILOG_FILE $vlog
}

# Read in QIP
if { [llength $QUARTUS_QIP] > 0 } {
    foreach qip $QUARTUS_QIP {
        set_global_assignment -name QIP_FILE $qip
    }
}

# Read in SDC
if { [llength $QUARTUS_SDC] > 0 } {
    foreach sdc $QUARTUS_SDC {
        set_global_assignment -name SDC_FILE $sdc
    }
}

set_global_assignment -name TOP_LEVEL_ENTITY $QUARTUS_TOP

# source pin assignment
source $QUARTUS_PIN

# additional assignment for CYCLONE II
if { $QUARTUS_FAMILY eq "Cyclone II" } {
set_global_assignment -name CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_ASDO_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name USE_CONFIGURATION_DEVICE ON
}

export_assignments

# ------------------------------------------
# Synthesis(map), Implementation(fit), and assemble
# ------------------------------------------

package require ::quartus::flow
execute_module -tool map
execute_module -tool fit
execute_module -tool asm

# ------------------------------------------
# Report Utilization
# ------------------------------------------
package require ::quartus::report
load_report

# Saving Report Data in csv Format
# This is the name of the report panel to save as a CSV file
set panel_name "Analysis & Synthesis||Analysis & Synthesis Resource Utilization by Entity"
set csv_file "synthesis_resource_utilization_by_entity.csv"
set fh [open $csv_file w]
set num_rows [get_number_of_rows -name $panel_name]
# Go through all the rows in the report file, including the
# row with headings, and write out the comma-separated data
for { set i 0 } { $i < $num_rows } { incr i } {
	set row_data [get_report_panel_row -name $panel_name \
		-row $i]
	puts $fh [join $row_data ","]
}
close $fh
unload_report

project_close

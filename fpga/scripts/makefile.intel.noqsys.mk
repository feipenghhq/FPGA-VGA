#########################################################
# Makefile for quartus flow
#########################################################

#########################################################
# Common variable
#########################################################

GIT_ROOT 	?= $(shell git rev-parse --show-toplevel)
SCRIPT_DIR 	?= $(GIT_ROOT)/fpga/scripts
OUT_DIR 	?= quartus

PART    	?= EP2C35F672C7
FAMILY  	?= Cyclone II
PROJECT	 	?=
TOP			?=
VERILOG 	?=
SDC 		?=
PIN			?=
DEFINE		?=


export QUARTUS_PART 	= $(PART)
export QUARTUS_FAMILY 	= $(FAMILY)
export QUARTUS_PRJ 		= $(PROJECT)
export QUARTUS_TOP    	= $(TOP)
export QUARTUS_VERILOG  = $(VERILOG)
export QUARTUS_SEARCH   = $(SEARCH)
export QUARTUS_SDC		= $(SDC)
export QUARTUS_QIP		= $(QIP)
export QUARTUS_PIN		= $(PIN)
export QUARTUS_DEFINE	= $(DEFINE)


SOF = $(OUT_DIR)/$(PROJECT).sof

#########################################################
# Build process
#########################################################

all: sof

build: sof
sof : $(SOF)

#########################################################


$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(SOF): $(VERILOG) $(OUT_DIR) pre
	cd $(OUT_DIR) && quartus_sh --64bit -t $(SCRIPT_DIR)/intel.build.tcl

pgm: $(SOF)
	quartus_pgm --mode JTAG -o "p;$(SOF)"

pgmonly:
	quartus_pgm --mode JTAG -o "p;$(SOF)"

clean: clean_qsys
	rm -rf $(OUT_DIR)

clean_qsys:
	rm -rf $(QSYS_DIR)/$(QSYS)*.rpt $(QSYS_DIR)/$(QSYS).cmp $(QSYS_DIR)/$(QSYS).html $(QSYS_DIR)/$(QSYS).sopcinfo

clean_qip:
	rm -rf $(QIP)
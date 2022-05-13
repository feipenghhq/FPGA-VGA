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
SEARCH		?=
SDC 		?=
PIN			?=

QSYS            ?=
QSYS_DIR        ?=
QSYS_SYN_LANG   ?= verilog
QSYS_SEARCH 	+= ,$


export QUARTUS_PART 	= $(PART)
export QUARTUS_FAMILY 	= $(FAMILY)
export QUARTUS_PRJ 		= $(PROJECT)
export QUARTUS_TOP    	= $(TOP)
export QUARTUS_VERILOG  = $(VERILOG)
export QUARTUS_SEARCH   = $(SEARCH)
export QUARTUS_SDC		= $(SDC)
export QUARTUS_QIP		= $(QIP)
export QUARTUS_PIN		= $(PIN)

QIP	= $(OUT_DIR)/$(QSYS)/synthesis/$(QSYS).qip
SOF = $(OUT_DIR)/$(PROJECT).sof

#########################################################
# Build process
#########################################################

all: sof

build: sof
sof: $(SOF)

#########################################################


$(QIP): $(QSYS_DIR)/$(QSYS).qsys
	qsys-generate $(QSYS_DIR)/$(QSYS).qsys --search_path="$(QSYS_SEARCH)"  --family=$(FAMILY)  --part=$(PART) --synthesis=$(QSYS_SYN_LANG) --output-directory=$(OUT_DIR)/$(QSYS) --clear-output-directory

$(SOF): $(QIP) $(VERILOG)
	cd $(OUT_DIR) && quartus_sh --64bit -t $(SCRIPT_DIR)/intel.build.tcl

pgm: $(SOF)
	quartus_pgm --mode JTAG -o "p;$(SOF)"

qsys: $(QIP)

qsys-edit:
	qsys-edit $(QSYS_DIR)/$(QSYS).qsys

clean: clean_qsys
	rm -rf $(OUT_DIR)

clean_qsys:
	rm -rf $(QSYS_DIR)/$(QSYS)*.rpt $(QSYS_DIR)/$(QSYS).cmp $(QSYS_DIR)/$(QSYS).html $(QSYS_DIR)/$(QSYS).sopcinfo

clean_qip:
	rm -rf $(QIP)
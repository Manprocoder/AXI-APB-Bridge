#===========================================================================
#--Project: AXI to APB IP
#--File: Makefile 
#--Author: Nguyen Ngoc Man
#--Description: 
#===========================================================================
# Example run string: make TESTNAME={name_of_testcase} {optional}
#                     make run TESTNAME=base_test
##
#
TB_NAME     ?=tb
TESTNAME    ?=
VERBOSITY   ?=
RUNARG      ?=
SEED        ?=1
COVERAGE    ?=
#
#----------------INFORMATION FOR DEBUG
#
PRINT_AXI_WREQ_EN ?= 
PRINT_AXI_RREQ_EN ?= 
PRINT_AXI_WDATA_EN ?= 
PRINT_APB_TRANS_EN ?= 
# =============================================================
# Directory Variables 
# =============================================================
LOG_DIR     ?= log
COV_DIR     ?= coverage
HTML_DIR    ?= html_cov 
#
#
#
ifeq ($(strip $(SEED)),random)
  SEED = $(shell /bin/date +%s)
endif

#====================ASSISTANT VLOG, VSIM COMMAND===========================
#--1: coverage
ifeq ($(COVERAGE),1)
VCOVER = +cover

VSIM_COV_OPT = \
    -coverage \
    -coveranalysis \
    -cvgperinstance
#----------------------------------------------------------------------------
#--------read data fifo depth is 256, max length is 256 => full never occurs
#----------------------------------------------------------------------------
DO_CMD = "log -r /*; onfinish stop; run -all; \
coverage exclude -srcfile ../rtl/sfifordata.sv -line 110 -code e; \
coverage exclude -srcfile ../rtl/sfifordata.sv -line 167 -code e; \
coverage exclude -srcfile ../rtl/sfifordata.sv -line 167 -code t; \
coverage exclude -srcfile ../rtl/sfifordata.sv -line 169 -code e; \
coverage exclude -srcfile ../rtl/sfifordata.sv -line 245 -code e; \
coverage exclude -srcfile ../rtl/sfifordata.sv -line 245 -code t; \
coverage save $(TESTNAME)_$(SEED).ucdb; quit -f;" 

else
VCOVER =
 
VSIM_COV_OPT =

DO_CMD = "log -r /*; run -all;"

endif
#--2: print information for debug 
#--2.1
ifeq ($(PRINT_AXI_WREQ_EN),1)
DO_PRINT_WREQ = +define+PRINT_AXI_WREQ
else 
DO_PRINT_WREQ = 
endif

#--2.2
ifeq ($(PRINT_AXI_RREQ_EN),1)
DO_PRINT_RREQ = +define+PRINT_AXI_RREQ
else 
DO_PRINT_RREQ = 
endif

#--2.3
ifeq ($(PRINT_AXI_WDATA_EN),1)
DO_PRINT_WDATA = +define+PRINT_AXI_WDATA
else 
DO_PRINT_WDATA = 
endif
#--2.4
ifeq ($(PRINT_APB_TRANS_EN),1)
DO_PRINT_APB = +define+PRINT_APB_TRANS
else 
DO_PRINT_APB = 
endif
##=========================================================================

VLOG = vlog \
       -timescale "1ns/1ns" \
       +define+UVM_NO_DPI \
       +define+SLAVE_CNT=$(NO_SLAVE) \
       +define+CLK_CYCLE=20 \
       $(DO_PRINT_WREQ) \
       $(DO_PRINT_RREQ) \
       $(DO_PRINT_WDATA) \
       $(DO_PRINT_APB) \
       -mfcu \
       -suppress 2181,2186\
       +acc=rmb \
       +incdir+$(UVM_HOME)/src \
       $(VCOVER) \
       $(UVM_HOME)/src/uvm.sv \
       -l $(TESTNAME)_$(SEED)_vlog.log

#====================OFFICIAL VSIM===========================
VSIM = vsim \
       -sv_seed ${SEED} \
       -voptargs=+acc \
       -assertdebug \
       -debugDB \
       $(VSIM_COV_OPT) \
       -c $(TB_NAME) \
       -do $(DO_CMD) \
       -l $(TESTNAME)_$(SEED).log
##=============================================================================

all: build run




build: vlib
	$(VLOG) -f compile.f \
	+define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR


run:
	$(VSIM) +UVM_TESTNAME=$(TESTNAME) \
	+UVM_VERBOSITY=$(VERBOSITY) \
	${RUNARG}
	mv ${TESTNAME}_${SEED}.log ./$(LOG_DIR)
	ln -sf ./$(LOG_DIR)/${TESTNAME}_${SEED}.log run.log
	mv ${TESTNAME}_${SEED}_vlog.log ./$(LOG_DIR)
	ln -sf ./$(LOG_DIR)/${TESTNAME}_${SEED}_vlog.log vlog.log

cov_report: 
	vcover report \
	-html \
	-htmldir $(HTML_DIR) \
	-verbose \
	-assert \
	-cvg \
	-code bcesftx \
	-source \
	-details=abcdefgst \
	-binrhs \
	-testhitdataAll \
	-stmtaltflow \
	-testdetails ${TESTNAME}_${SEED}.ucdb \
    -l $(TESTNAME)_$(SEED)_cov.log
	
vlib:
	mkdir -p $(LOG_DIR)
	mkdir -p $(COV_DIR)
	mkdir -p $(HTML_DIR)
	vlib work
	vmap work work

wave:
#	vsim -i -view vsim.wlf -do "add wave vsim:/$(TB_NAME)/*;" &
	vsim -i -view vsim.wlf -do "add_wave.do" 

clean:
	rm -rf work
	rm -rf $(LOG_DIR)
	rm -rf $(COV_DIR)
	rm -rf $(HTML_DIR)
	rm -rf *.ini
	rm -rf *.log
	rm -rf *.trace
	rm -rf *.wlf
	rm -rf transcript
	rm -rf *.ucdb
	rm -rf vsim.dbg

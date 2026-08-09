**DESIGN and VERIFICATION AXI-APB bridge **
- 
**Design**


![AXI_2_APB Block Diagram](/IMAGE/AXI_APB_BD.png)


AXI4 protocol
+ address bus width = 32 bits, data bus width = 32 bits
+ support all burst: FIXED, INCR, WRAP
+ ONLY support 4 bytes in each transfer --- ARSIZE/AWSIZE = 3'b010
+ support unaligned address
+ support OKAY, PSLVERR, DECERR response

APB4 protocol
+ address bus width = 32 bits, data bus width = 32 bits

Details: 5 synchronous FIRST-WORD-FALL-THROUGH fifos: write address channel, read address channel, write data channel, read data channel, write response channel

**Verification**

Building UVM testbench to verify DESIGN


![UVM_TB](/IMAGE/AXI_APB_TB.png)


Main Components

2 Agents: AXI master agent and APB slave agent

Scoreboard:

![AXI_APB_SCB](/IMAGE/AXI_APB_SCB.png)

**SIMULATION RESULT**

Pass/Fail


![SIM_RESULT](/IMAGE/sim_result.png)


Code Coverage


![Code Coverage](/IMAGE/code_coverage.png)


Functional Coverage

![Funtional Coverage](/IMAGE/func_coverage.png)


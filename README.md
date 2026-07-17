**DESIGN and VERIFICATION AXI-APB bridge **
- 
**Design**


![image alt](https://github.com/Manprocoder/AXI-APB-Bridge/blob/ce9f853cb32245b22182c995c7dcecba1dfcabf0/IMAGE/design.png)


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


![image alt](https://github.com/Manprocoder/AXI-APB-Bridge/blob/ce9f853cb32245b22182c995c7dcecba1dfcabf0/IMAGE/tb.png)


Main Components

2 Agents: AXI master agent and APB slave agent

Scoreboard:

Base_scoreboard(parent) class:
+ Main Attributes: total_pass, total_fail, and others (queues and associate arrays to store req, data and Simulation result report)
+ Main Methods(function/task): calculate_next_address, calculate_and_store_address, store_simulation_result, ....

Scoreboard (derived/child) class:
+ Main Attributes: axi_content object(contain axi data channel (WR/RD)), apb_content object, common object (store shared signals between 2 protocol to COMPARE---axi_transfer, apb_transfer), ...
+ Main Methods: wait_apb_transfer, fetch_valid_req(valid WR/RD request),
  convert_axi_to_compare(axi_content-->axi_transfer), convert_apb_to_compare(apb_content-->apb_transfer), compare_transfer, ...

**SIMULATION RESULT**

Pass/Fail


![image alt](https://github.com/Manprocoder/AXI-APB-Bridge/blob/208b60109e18c5902f13565287fbbddf519daead/IMAGE/sim_res.png)


Code Coverage


![image alt](https://github.com/Manprocoder/AXI-APB-Bridge/blob/1f67d3b01c1cda1de318bc92e9a4e92ea9956cc8/IMAGE/code_cov.png)


Functional Coverage


![image alt](https://github.com/Manprocoder/AXI-APB-Bridge/blob/1f67d3b01c1cda1de318bc92e9a4e92ea9956cc8/IMAGE/func_cov.png)

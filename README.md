**DESIGN and VERIFICATION AXI-APB bridge **
- 
**Design**
![image alt](https://github.com/Manprocoder/AXI-APB-Bridge/blob/81ede17224364421cac17f2e1c3eab0eb8cf6080/IMAGE/AXI_APB_BLOCK_DIAGRAM.drawio.svg)

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

2 Agents: AXI master agent and APB slave agent

Scoreboard:

Base_scoreboard(parent) class:
+ Main Attributes: total_pass, total_fail, and others (queues and associate arrays to store req, data and Simulation result report)
+ Main Methods(function/task): calculate_next_address, calculate_and_store_address, store_simulation_result, ....

Scoreboard (derived/child) class:
+ Main Attributes: axi_content object(contain axi data channel (WR/RD)), apb_content object, common object (store shared signals between 2 protocol to COMPARE---axi_transfer, apb_transfer), ...
+ Main Methods: wait_apb_transfer, fetch_valid_req(valid WR/RD request), convert_axi_to_compare(axi_content-->axi_transfer),
  convert_apb_to_compare(apb_content-->apb_transfer),...

    

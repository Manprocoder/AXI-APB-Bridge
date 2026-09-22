package axi_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "axi_param.sv"
  `include "axi_cfg.sv"
  `include "axi_ready_signal_item.sv"
  `include "axi_brsp_item.sv"
  `include "axi_data_item.sv"
  `include "axi_req_item.sv"
  `include "axi_seq_item.sv"
  `include "axi_sequencer.sv"
  `include "axi_driver.sv"
  `include "axi_addr_first_wdata_then_driver.sv"
  `include "axi_addr_wdata_parallel_driver.sv"
  `include "axi_wdata_first_addr_then_driver.sv"
  `include "axi_monitor.sv"
  `include "axi_agent.sv"
    typedef axi_transaction#(DW1,AW1) axi_item;

endpackage : axi_pkg

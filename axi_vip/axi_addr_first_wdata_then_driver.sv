//================================================================================
//--Project: AXI to APB IP
//--File: axi_addr_first_wdata_then_driver.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//================================================================================
class axi_addr_first_wdata_then_driver extends AxiMasterDriver;// uvm_driver#(axi_transaction#(DW1, AW1));
  //register UVM factory
  `uvm_component_utils(axi_addr_first_wdata_then_driver)
  //================================================================
  //--------------------DATA members
  //================================================================

  //================================================================
  //-------------------- METHODS
  //================================================================
  extern function new(string name = "axi_addr_first_wdata_then_driver", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern task Master_Write();
endclass

  //================================================================
  //-------------------- IMPLEMENTATION of METHODS
  //================================================================

  function axi_addr_first_wdata_then_driver::new(string name = "axi_addr_first_wdata_then_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  //
  function void axi_addr_first_wdata_then_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  //
  function void axi_addr_first_wdata_then_driver::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  //

  function void axi_addr_first_wdata_then_driver::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
  endfunction
//
  task axi_addr_first_wdata_then_driver::run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask
  //
  task axi_addr_first_wdata_then_driver::Master_Write();
    super.Master_Write();
  endtask

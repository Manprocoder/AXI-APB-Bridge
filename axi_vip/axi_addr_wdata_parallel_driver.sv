//================================================================================
//--Project: AXI to APB IP
//--File: axi_addr_wdata_parallel_driver.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//================================================================================
class axi_addr_wdata_parallel_driver extends AxiMasterDriver;//axi_addr_first_wdata_then_driver;
  //register UVM factory
  `uvm_component_utils(axi_addr_wdata_parallel_driver)
  //================================================================
  //-------------------- METHODS
  //================================================================
  //
  //---pure method from vir_axi_driver
  //
  extern function new(string name = "axi_addr_wdata_parallel_driver", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  //pure method from vir_axi_driver
  extern task run_phase(uvm_phase phase);
  extern task Master_Write();
//
//---inside class
//
endclass
  //================================================================
  //-------------------- IMPLEMENTATION of METHODS
  //================================================================
function axi_addr_wdata_parallel_driver::new(string name = "axi_addr_wdata_parallel_driver", uvm_component parent = null);
    super.new(name, parent);
    //reset_attribute(); 
  endfunction

  // build_phase: get virtual interface
  function void axi_addr_wdata_parallel_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  //
  function void axi_addr_wdata_parallel_driver::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  //
  function void axi_addr_wdata_parallel_driver::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
  endfunction
  //
  task axi_addr_wdata_parallel_driver::run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask
  //

  // ------------------------------------------------------------------------
  // Master_Write_Driver
  //-- here, we MUST use fork-join_none to initialize two independent thread
  // ------------------------------------------------------------------------
  task axi_addr_wdata_parallel_driver::Master_Write();
      fork
        forever begin: WADDR_WDATA_PARALLEL
          drv_cfg.vif.wait_RisingEdge_reset();
          //#(`CLK_CYCLE);
          while(drv_cfg.vif.aresetn_value() == 1'b1) begin: Master_Write_Driver_Run
            `uvm_info(get_type_name(), $sformatf("[Drive Write Request] START!!!"), UVM_MEDIUM);
            seq_item_port.get_next_item(wtx0);
                //
                fork
                send_write_address(wtx0);
                send_write_data(wtx0);
                join
                //
            seq_item_port.item_done();
            `uvm_info(get_type_name(), $sformatf("[Drive Write Request] done!!!"), UVM_MEDIUM);
          end //end of while
        end//end of WADDR_WDATA_PARALLEL
        //
        forever begin: GET_BRESP
          drv_cfg.vif.wait_RisingEdge_reset();
         //#(`CLK_CYCLE);
          while(drv_cfg.vif.aresetn_value() == 1'b1) begin
            get_bresp();
          end
        end//end of GET_BRESP
      join_none
  endtask


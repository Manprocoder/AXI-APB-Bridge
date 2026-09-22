//================================================================================
//--Project: AXI to APB IP
//--File: axi_wdata_first_addr_then_driver.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//================================================================================
class axi_wdata_first_addr_then_driver extends AxiMasterDriver;//axi_addr_first_wdata_then_driver;
  //register UVM factory
  `uvm_component_utils(axi_wdata_first_addr_then_driver)
  //================================================================
  //-------------------- METHODS
  //================================================================
  //
  //---pure method from vir_axi_driver
  //
  extern function new(string name = "axi_wdata_first_addr_then_driver", uvm_component parent = null);
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
function axi_wdata_first_addr_then_driver::new(string name = "axi_wdata_first_addr_then_driver", uvm_component parent = null);
    super.new(name, parent);
    //reset_attribute(); 
  endfunction

  // build_phase: get virtual interface
  function void axi_wdata_first_addr_then_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  //
  function void axi_wdata_first_addr_then_driver::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  //
  function void axi_wdata_first_addr_then_driver::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
  endfunction
  //
  task axi_wdata_first_addr_then_driver::run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask
  //

  // ------------------------------------------------------------------------
  // Master_Write_Driver
  //-- here, we MUST use fork-join_none to initialize two independent thread
  // ------------------------------------------------------------------------
  task axi_wdata_first_addr_then_driver::Master_Write();
      fork
        forever begin: SEND_WDATA
          drv_cfg.vif.wait_RisingEdge_reset();
          //#(`CLK_CYCLE);
          while(drv_cfg.vif.aresetn_value() == 1'b1) begin: Master_Write_Driver_Run
            `uvm_info(get_type_name(), "[Drive Write Data] START!!!", UVM_MEDIUM);
                seq_item_port.get_next_item(wtx0);
                //put transaction into mailbox for later usage of wdata chnnel
                send_write_data(wtx0);
            //
            `uvm_info(get_type_name(), "[START]Wait availability of wr_trans_tlm_fifo!!!", UVM_LOW)
            wait(w_trans_fifo.is_full() == 1'b0); 
            put_port.put(wtx0);
            `uvm_info(get_type_name(), "[DONE_]Wait availability of wr_trans_tlm_fifo!!!", UVM_LOW)
                //
            seq_item_port.item_done();
            `uvm_info(get_type_name(), "[Drive Write Data] DONE!!!", UVM_MEDIUM);
          end //end of while
        end//end of SEND_WDATA
        //
        forever begin: GET_WR_REQUEST
          `uvm_info(get_type_name(), "WAIT RISI_EDGE_of_ARESETN---SendWriteRequest!!!", UVM_MEDIUM);
          drv_cfg.vif.wait_RisingEdge_reset();
          while(drv_cfg.vif.aresetn_value() == 1'b1) begin
            get_port.get(wtx1);
            send_write_address(wtx1);
          end
        end//end of GET_WR_REQUEST
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


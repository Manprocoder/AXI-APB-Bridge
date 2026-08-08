//===========================================================================
//--Project: AXI_TO_APB IP
//--File: apb_driver.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//===========================================================================
class apb_driver extends uvm_driver#(apb_seq_item#(DW2,AW2));
  `uvm_component_utils(apb_driver)
  //===================================================
  //--------------DATA members
  //===================================================
  REQ item;
  apb_agent_config drv_cfg; //config object
  int counter; //counter of pready
  bit actual_pready; //final pready is driven onto interface
  bit done; //final pready is completely driven if done = 1
  //===================================================
  //--------------Methods
  //===================================================
function new (string name ="APB Driver", uvm_component parent);
    super.new(name, parent);
    init_attribute();
endfunction:new
      
    //---------------------------------------
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task reset_all();
  extern virtual task drive();
  extern virtual task slave_task();
  extern virtual function void init_attribute();
  
endclass
//**************************************************************************************
//***********************************MAIN TASKS*****************************************
//**************************************************************************************
function void apb_driver::build_phase(uvm_phase phase);
    //super.build_phase(phase);
    if(drv_cfg == null) begin
      `uvm_fatal (get_type_name (), "APB_AGENT_CONFIG OBJECT is NULL!!!")
    end
endfunction:build_phase
  //
task apb_driver::run_phase(uvm_phase phase);
// super.run_phase(phase);
  fork
      forever begin: DETECT_RST
          reset_all();
      end: DETECT_RST
      //
      forever begin: APB_SIM
            `uvm_info(get_name(), "wait high level of presetn", UVM_HIGH)
            wait(drv_cfg.vif.presetn == 1'b1);
            //if(drv_cfg.vif.presetn == 1'b1) begin
                while(drv_cfg.vif.presetn == 1'b1) begin
                    seq_item_port.get_next_item(item);
                    drive();
                    seq_item_port.item_done();
                end
            //end
      end: APB_SIM
  join_none
endtask
//
//
task apb_driver::reset_all();
  wait(drv_cfg.vif.presetn == 1'b0); 
  //begin
      if(drv_cfg.active == UVM_PASSIVE) begin
        drv_cfg.vif.s_drv_cb.pready <= 1'b0; //{`SLAVE_CNT{1'b0}};
        drv_cfg.vif.s_drv_cb.pslverr <= 1'b0; //{`SLAVE_CNT{1'b0}};
      end
  //end

  while (1) begin
    @(negedge drv_cfg.vif.presetn);
	@(drv_cfg.vif.s_drv_cb iff ~drv_cfg.vif.presetn); //Reset of DUT is synchronize reset
      if(drv_cfg.active == UVM_PASSIVE) begin
        drv_cfg.vif.s_drv_cb.pready <= 1'b0; //{`SLAVE_CNT{1'b0}};
        drv_cfg.vif.s_drv_cb.pslverr <= 1'b0; //{`SLAVE_CNT{1'b0}};
      end
  end

endtask: reset_all
//
//definition of drive task
//
task apb_driver::drive();
    if(drv_cfg.active == UVM_ACTIVE) begin

    end
    else begin
        slave_task();
    end
endtask
//
//
//
task apb_driver::slave_task();
init_attribute();
//
fork: SLAVE_TASK
begin: DETECT_PRESETN
    @(negedge drv_cfg.vif.presetn);
    `uvm_info(get_type_name(), "PRESET_N is ACTIVE!!!", UVM_LOW);
end: DETECT_PRESETN
//
begin: DRIVE_RESPONSE
    fork
    begin: DRIVE_RDATA 
        @(drv_cfg.vif.s_drv_cb iff drv_cfg.vif.s_drv_cb.psel);
        if(~drv_cfg.vif.s_drv_cb.pwrite && ~drv_cfg.vif.s_drv_cb.penable) begin
            drv_cfg.vif.s_drv_cb.prdata <= $urandom;
            `uvm_info(get_type_name(), $sformatf("[APB READ_TRANSFER]: paddr=0x%0h",
            drv_cfg.vif.s_drv_cb.paddr), UVM_HIGH);
        end
    end: DRIVE_RDATA
    //
    forever begin: DRIVE_PREADY 
        @(drv_cfg.vif.s_drv_cb);// iff drv_cfg.vif.s_drv_cb.psel);
        //item.print();
        `uvm_info(get_type_name(), $sformatf("counter = %0d", counter), UVM_HIGH);
        `uvm_info(get_type_name(), $sformatf("preadyDelay = %0d", item.preadyDelay), UVM_HIGH);
        if(drv_cfg.vif.s_drv_cb.psel == 1'b1) begin //PSEL
            if(item.pready == 1'b1) begin
                actual_pready = item.pready;
                done = 1'b1;
            end
            else if(counter == item.preadyDelay)begin
                actual_pready = 1'b1;
                done = 1'b1;
            end
            else begin
                actual_pready = item.pready;
                done = 1'b0;
            end
            //
            drv_cfg.vif.s_drv_cb.pready <= actual_pready;
            // usually 1 (ready)
            drv_cfg.vif.s_drv_cb.pslverr <= item.pslverr; // usually 0 (no error)
            //
            if((item.pready == 1'b0) && (drv_cfg.vif.s_drv_cb.penable == 1'b1)) begin
                counter++;
            end
        end//end of PSEL
        if(done == 1'b1) begin
            break;
        end
    end: DRIVE_PREADY 
    join
end: DRIVE_RESPONSE 
join_any
disable SLAVE_TASK;
endtask
//
//
function void apb_driver::init_attribute();
    actual_pready = 1'b0;
    done = 1'b0;
    counter = 0;
endfunction

//===========================================================================
//--Project: AXI_TO_APB IP
//--File: apb_monitor.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//===========================================================================
class apb_monitor extends uvm_monitor;
  typedef apb_seq_item#(DW2, AW2) apb_item;
  `uvm_component_utils(apb_monitor)
  //
  apb_item apb_trans_h;
  apb_agent_config mon_cfg;
  uvm_analysis_port #(logic) presetn_toScoreboard;  //to connect scoreboard (reset)
  uvm_analysis_port #(logic [`SLAVE_CNT-1:0]) pseltb_toScoreboard;  //to connect scoreboard (psel)
  uvm_analysis_port #(apb_item) ApbContent_toScoreboard;  //to connect scoreboard (APB Packet)
  //------------------------------------------
  //data members
  //------------------------------------------
  logic preset_n;
  logic [`SLAVE_CNT-1:0] psel_tb;
  //
  function new(string name="APB Monitor", uvm_component parent);
    super.new(name, parent);
  endfunction:new

  extern function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task detect_rst();
  extern virtual task collect_data();
  extern virtual task detect_psel();

endclass
//
//
function void apb_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);
  //
  ApbContent_toScoreboard = new("ApbContent_toScoreboard", this);
  presetn_toScoreboard = new("presetn_toScoreboard", this);
  pseltb_toScoreboard = new("pseltb_toScoreboard", this);
endfunction
//
task apb_monitor::run_phase(uvm_phase phase);
    super.run_phase(phase);
    //all task run with while(1)
    //here, we must use fork-join_none or fork-join_any
    //jork-join will block this task, while(1) never stops
    fork
        collect_data();
        detect_rst();
        detect_psel();
    join_none
endtask
//
//---collect data of multiple slaves
//
task apb_monitor::collect_data();
  while(1) begin
    @(mon_cfg.vif.s_mon_cb iff |mon_cfg.vif.s_mon_cb.psel) begin
      foreach(mon_cfg.vif.s_mon_cb.psel[i]) begin
        if(mon_cfg.vif.s_mon_cb.psel[i] && mon_cfg.vif.s_mon_cb.penable && mon_cfg.vif.s_mon_cb.pready[i]) begin
            // `uvm_info(get_type_name(), $sformatf("PENABLE: %0b -- PREADY: %0b",
            // mon_cfg.vif.s_mon_cb.penable, mon_cfg.vif.s_mon_cb.pready[i]), UVM_LOW);
            //
            apb_trans_h = apb_item::type_id::create("apb_trans_h"); //(*)
            //--(*) MUST be used to create NEW OBJECT--DYNAMIC to avoid override mechanism because of STATIC
            //--because we are using foreach loop
            //
            apb_trans_h.paddr[31:0] = mon_cfg.vif.s_mon_cb.paddr[31:0];
            apb_trans_h.pstrb[3:0] = mon_cfg.vif.s_mon_cb.pstrb[3:0];
            apb_trans_h.pwrite = mon_cfg.vif.s_mon_cb.pwrite;
            apb_trans_h.pwdata = mon_cfg.vif.s_mon_cb.pwdata;
	    apb_trans_h.prdata = mon_cfg.vif.s_mon_cb.prdata[i];
            apb_trans_h.pslverr = mon_cfg.vif.s_mon_cb.pslverr[i]; 
            //`uvm_info(get_type_name(), $sformatf("BUS_ADDRESS_: 0x%08h", mon_cfg.vif.s_mon_cb.paddr), UVM_LOW);
            //`uvm_info(get_type_name(), $sformatf("ITEM_ADDRESS: 0x%08h", apb_trans_h.addr), UVM_LOW);
            //if(mon_cfg.vif.s_mon_cb.pwrite) begin
              //`uvm_info(get_type_name(), $sformatf("WRITEDATA: 0x%08h", apb_trans_h.data), UVM_LOW);
            //end
            //else begin
              //`uvm_info(get_type_name(), $sformatf("READDATA: 0x%08h", apb_trans_h.data), UVM_LOW);
            //end
            //Send the transaction to analysis port which is connected to Scoreboard
            ApbContent_toScoreboard.write(apb_trans_h);
          // end //end of if penable
        end //end of if psel && pready
      end //end of foreach
    end //end of posedge clk
  end//end of while(1)
endtask
//On each clock, send the reset status to Scoreboard
//via analysis port preset_toScoreboard
task apb_monitor::detect_rst();
  while(1) begin
    @(mon_cfg.vif.s_mon_cb);
    this.preset_n = mon_cfg.vif.presetn;
    presetn_toScoreboard.write(this.preset_n);
  end
endtask
//
task apb_monitor::detect_psel();
  while(1) begin
    @(mon_cfg.vif.s_mon_cb iff mon_cfg.vif.presetn);
    this.psel_tb = mon_cfg.vif.s_mon_cb.psel;
    pseltb_toScoreboard.write(this.psel_tb);
  end
endtask

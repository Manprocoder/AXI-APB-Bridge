//======================================================
//UVM component
//======================================================
import type_package::*; //axi_req_item
class AxiMasterMonitor extends uvm_monitor;
  `uvm_component_utils(AxiMasterMonitor)
  //--------------------------------------------------
  //virtual interface
  //--------------------------------------------------
  virtual interface axi_intf #(DW,AW1) m_mon_vif;
  //--------------------------------------------------
  //Data members
  //--------------------------------------------------
  //config object
  env_config mon_cfg;
  //FUNCTIONAL COVERAGE
  axi_req_item axi_req_item_cov;
  //
  mailbox #(axi_req_item) WrReqCovMbox, RdReqCovMbox;
  mailbox #(axi_data_item) RdDataCovMbox;
  mailbox #(axi_data_item) WrDataCovMbox;
  mailbox #(axi_brsp_item) BChannelCovMbox;
  //
  string sim_result_path;
  int chk_error_file;
  string INST_NAME;
  //SCOREBOARD
  logic axi_mon_resetn;
  //axi_brsp_item brsp_h;
  //axi_data_item wdata_h, rdata_h;    //new object only contains needed details to compare
  axi_req_item wreq_h, rreq_h;
  axi_data_item wdata_h, rdata_h;
  axi_brsp_item brsp_h;
  //-- port to connect sb and fc
  uvm_analysis_port #(logic) AxiResetn_toScoreBoard;
  //uvm_analysis_port #(axi_req_item) AxiRdAddr_toScoreBoard;
  //uvm_analysis_port #(axi_data_item) AxiRData_toScoreBoard;
  //uvm_analysis_port #(axi_req_item) AxiWrAddr_toScoreBoard;
  //uvm_analysis_port #(axi_data_item) AxiWData_toScoreBoard;
  //uvm_analysis_port #(axi_brsp_item) AxiBresp_toScoreBoard;
  uvm_analysis_port #(axi_req_item) AxiRdAddr_toScoreBoard;
  uvm_analysis_port #(axi_data_item) AxiRData_toScoreBoard;
  uvm_analysis_port #(axi_req_item) AxiWrAddr_toScoreBoard;
  uvm_analysis_port #(axi_data_item) AxiWData_toScoreBoard;
  uvm_analysis_port #(axi_brsp_item) AxiBresp_toScoreBoard;
  //
  function new(string name = "AxiMasterMonitor", uvm_component parent);
    super.new(name, parent);
  endfunction
  //
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern task detect_rst();
  extern task collect_RdRequest();
  extern task collect_ReadData();
  extern task collect_WrRequest();
  extern task collect_WriteData();
  extern task collect_WriteResp();
  extern task Reset_All_Queue();
  //extern task check_protocol();
  //extern virtual function void report_phase(uvm_phase phase);
  //
  //
endclass

function void AxiMasterMonitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    AxiResetn_toScoreBoard = new("AxiResetn_toScoreBoard", this);
    AxiRdAddr_toScoreBoard = new("AxiRdAddr_toScoreBoard", this);
    AxiRData_toScoreBoard = new("AxiRData_toScoreBoard", this);
    AxiWrAddr_toScoreBoard = new("AxiWrAddr_toScoreBoard", this);
    AxiWData_toScoreBoard = new("AxiWData_toScoreBoard", this);
    AxiBresp_toScoreBoard = new("AxiBresp_toScoreBoard", this);
    //
    //
    WrReqCovMbox = new();
    RdReqCovMbox = new();
    WrDataCovMbox = new();
    RdDataCovMbox = new();
    BChannelCovMbox = new();
    //if (!uvm_config_db#(string)::get(this, "", "axi_chk_inst_name", INST_NAME)) begin
      //`uvm_fatal(get_type_name(), "axi_chk_inst_name NOT found in config DB!!!")
    //end
    ////
    ////get actual simulation path
    ////
    //if (!uvm_config_db#(string)::get(this, "", "sim_result_path", sim_result_path)) begin
      //`uvm_fatal(get_type_name(), "No sim_result_path found in config DB!!!")
    //end
    //`uvm_info(get_type_name(), $sformatf("Results will be stored at: %s", sim_result_path), UVM_LOW)

endfunction

task AxiMasterMonitor::run_phase(uvm_phase phase);
  super.run_phase(phase);
  //
  fork
      detect_rst();
      collect_RdRequest();
      collect_ReadData();
      collect_WrRequest();
      collect_WriteData();
      collect_WriteResp();
      Reset_All_Queue();
      //
      //if(mon_cfg.axi_agt_cfg.active == UVM_ACTIVE) begin
        //check_protocol();
      //end
    //
  join_none
endtask
//
task AxiMasterMonitor::Reset_All_Queue();
  wait(m_mon_vif.aresetn==1'b0) begin
    WrReqCovMbox = new();
    RdReqCovMbox = new();
    WrDataCovMbox = new();
    RdDataCovMbox = new();
    BChannelCovMbox = new();
    //
  end
  //
  while(1) begin
  @(negedge m_mon_vif.aresetn) begin
    WrReqCovMbox = new();
    RdReqCovMbox = new();
    WrDataCovMbox = new();
    RdDataCovMbox = new();
    BChannelCovMbox = new();
    //
  end
  end
endtask
//On each clock, send the reset status to Scoreboard
//via analysis port AxiResetn_toScoreboard
task AxiMasterMonitor::detect_rst();
  while(1) begin
    @(m_mon_vif.m_mon_cb);
    this.axi_mon_resetn = m_mon_vif.aresetn;
    AxiResetn_toScoreBoard.write(this.axi_mon_resetn);
  end
endtask
//
//--collect Read Request
task AxiMasterMonitor::collect_RdRequest();
  //
  while(1) begin
    @(m_mon_vif.m_mon_cb);
    if(m_mon_vif.m_mon_cb.arvalid && m_mon_vif.m_mon_cb.arready) begin
      //
      rreq_h = axi_req_item::type_id::create("rreq_h");
      rreq_h.wr_or_rd = 1'b0;
      rreq_h.id = m_mon_vif.m_mon_cb.arid;
      rreq_h.addr = m_mon_vif.m_mon_cb.araddr;
      rreq_h.len = m_mon_vif.m_mon_cb.arlen;
      rreq_h.size = m_mon_vif.m_mon_cb.arsize;
      rreq_h.burst = burst_name'(m_mon_vif.m_mon_cb.arburst);
      //send to ScoreBoarreq_h
      AxiRdAddr_toScoreBoard.write(rreq_h);
  end
  end
endtask
//
//
task AxiMasterMonitor::collect_ReadData();
  while(1) begin
    @(m_mon_vif.m_mon_cb iff (m_mon_vif.m_mon_cb.rvalid && m_mon_vif.m_mon_cb.rready));
    //scoreboard
    rdata_h = axi_data_item::type_id::create("rdata_h");
    rdata_h.data = m_mon_vif.m_mon_cb.rdata;
    rdata_h.wr_or_rd = ~m_mon_vif.m_mon_cb.rvalid;
    rdata_h.be = 4'h0;
    rdata_h.last = m_mon_vif.m_mon_cb.rlast;
    rdata_h.resp = resp_name'(m_mon_vif.m_mon_cb.rresp);
    rdata_h.id = m_mon_vif.m_mon_cb.rid;
    //write item on scoreboard
    AxiRData_toScoreBoard.write(rdata_h);
  end
endtask
//
//--collect Write Request
task AxiMasterMonitor::collect_WrRequest();
  while(1) begin
    @(m_mon_vif.m_mon_cb);
    if(m_mon_vif.m_mon_cb.awvalid && m_mon_vif.m_mon_cb.awready) begin
      wreq_h = axi_req_item::type_id::create("wreq_h");
      wreq_h.wr_or_rd = 1'b1;
      wreq_h.id = m_mon_vif.m_mon_cb.awid;
      wreq_h.addr = m_mon_vif.m_mon_cb.awaddr;
      wreq_h.len = m_mon_vif.m_mon_cb.awlen;
      wreq_h.size = m_mon_vif.m_mon_cb.awsize;
      wreq_h.burst = burst_name'(m_mon_vif.m_mon_cb.awburst);
      //send to ScoreBoard
      AxiWrAddr_toScoreBoard.write(wreq_h);
      //
  end
  end
endtask
//main task
//
//----collect Write Data
task AxiMasterMonitor::collect_WriteData();
  `uvm_info(get_full_name(), "collect_WriteData starts!!!", UVM_HIGH);
    
    while(1) begin  
      @(m_mon_vif.m_mon_cb iff (m_mon_vif.m_mon_cb.wvalid && m_mon_vif.m_mon_cb.wready));
      //
      wdata_h = axi_data_item::type_id::create("wdata_h");//(**)
      //-- create item in build_phase() (*)
      //-- AXI wdata generated (randomize) is array (multiple beats) once 
      //-- this monitor only sends one beat to Scoreboard in turn
      //-- (*) causes DATA LOSS (data override) (***) 
      //-- therefore create new item (**) to avoid (***)
      wdata_h.id = 'hz;
      wdata_h.data = m_mon_vif.m_mon_cb.wdata;
      wdata_h.be = m_mon_vif.m_mon_cb.wstrb;
      wdata_h.wr_or_rd = m_mon_vif.m_mon_cb.wvalid;
      wdata_h.last = m_mon_vif.m_mon_cb.wlast;
      wdata_h.resp = resp_name'(2'b01); 
      //
      //scoreboard
      AxiWData_toScoreBoard.write(wdata_h);
      //functional coverage
      //if(mon_cfg.functional_coverage) begin
        //// WrDataCovQueue.push_back(wdata_h);
        //WrDataCovMbox.put(wdata_h);
      //end
      //
    end //end of while(1)
    //
endtask
//
task AxiMasterMonitor::collect_WriteResp();
  while(1) begin
    @(m_mon_vif.m_mon_cb iff m_mon_vif.m_mon_cb.bvalid && m_mon_vif.m_mon_cb.bready);
    brsp_h = axi_brsp_item::type_id::create("brsp_h");
    brsp_h.resp = resp_name'(m_mon_vif.m_mon_cb.bresp);
    brsp_h.id = m_mon_vif.m_mon_cb.bid;
    //
    AxiBresp_toScoreBoard.write(brsp_h);
    //if(mon_cfg.functional_coverage) begin
      //// BrespCovQueue.push_back(brsp_h);
      //BChannelCovMbox.put(brsp_h);
    //end
    //
  end
endtask
//
//------------------------------------CHECK INTERFACE--------------------------------------------
//
//task AxiMasterMonitor::check_protocol();
  //chk_error_file = $fopen($sformatf("%s/CHECKER_ERROR/chk_error.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
  //if(chk_error_file == 0) begin
    //`uvm_warning(get_type_name(), $sformatf("Failed to open chk_error.log file"))
  //end
  ////
  //fork
    //forever begin
      //@(m_mon_vif.m_mon_cb);
      //if(m_mon_vif.m_mon_cb.awvalid && m_mon_vif.aresetn) begin
        //case (|m_mon_vif.m_mon_cb.awaddr)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWADDR is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWADDR is z\n", INST_NAME, $time);
        //endcase 
        ////check 2
        //case (|m_mon_vif.m_mon_cb.awlen)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWLEN is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWLEN is z\n", INST_NAME, $time);
        //endcase 
        ////check 3
        //case (|m_mon_vif.m_mon_cb.awsize)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWSIZE is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWSIZE is z\n", INST_NAME, $time);
        //endcase 
        ////check 4
        //case (|m_mon_vif.m_mon_cb.awburst)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWBURST is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWBURST is z\n", INST_NAME, $time);
        //endcase 
        ////check 5
        //case (|m_mon_vif.m_mon_cb.awid)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWID is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWID is z\n", INST_NAME, $time);
        //endcase
      //end
    //end
    ////WDATA CHANNEL
    //forever begin
      //@(m_mon_vif.m_mon_cb);
      //if(m_mon_vif.m_mon_cb.wvalid && m_mon_vif.aresetn) begin
      //case (|m_mon_vif.m_mon_cb.wdata)
      //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] WDATA is x\n", INST_NAME, $time);
      //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] WDATA is z\n", INST_NAME, $time);
      //endcase 
      ////check2
      //case (|m_mon_vif.m_mon_cb.wstrb)
      //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] WSTRB is x\n", INST_NAME, $time);
      //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] WSTRB is z\n", INST_NAME, $time);
      //endcase 
      ////check3
      //case (m_mon_vif.m_mon_cb.wready)
      //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] WREADY is x\n", INST_NAME, $time);
      //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] WREADY is z\n", INST_NAME, $time);
      //endcase
      //end
    //end
    ////
    //forever begin
      //@(m_mon_vif.m_mon_cb);
      //if(m_mon_vif.m_mon_cb.bvalid && m_mon_vif.aresetn) begin
          ////check1
          //case (m_mon_vif.m_mon_cb.bid)
          //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] BID is x\n", INST_NAME, $time);
          //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] BID is z\n", INST_NAME, $time);
          //endcase 
          ////check2
          //case (m_mon_vif.m_mon_cb.bresp)
          //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] BRESP is x\n", INST_NAME, $time);
          //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] BRESP is z\n", INST_NAME, $time);
          //endcase 
          ////check3
          //case (m_mon_vif.m_mon_cb.bready)
          //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] BREADY is x\n", INST_NAME, $time);
          //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] BREADY is z\n", INST_NAME, $time);
          //endcase 
      //end
    //end
    ////RD ADDR CHANNEL
      //forever begin
      //@(m_mon_vif.m_mon_cb);
      //if(m_mon_vif.m_mon_cb.arvalid && m_mon_vif.aresetn) begin
        //case (|m_mon_vif.m_mon_cb.araddr)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARADDR is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARADDR is z\n", INST_NAME, $time);
        //endcase 
        ////check 2
        //case (|m_mon_vif.m_mon_cb.arlen)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARLEN is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARLEN is z\n", INST_NAME, $time);
        //endcase 
        ////check 3
        //case (|m_mon_vif.m_mon_cb.arsize)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARSIZE is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARSIZE is z\n", INST_NAME, $time);
        //endcase 
        ////check 4
        //case (|m_mon_vif.m_mon_cb.arburst)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARBURST is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARBURST is z\n", INST_NAME, $time);
        //endcase 
        ////check 5
        //case (|m_mon_vif.m_mon_cb.arid)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARID is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARID is z\n", INST_NAME, $time);
        //endcase
      //end
    //end
    ////
    ////RDATA CHANNEL
    //forever begin
      //@(m_mon_vif.m_mon_cb);
      //if(m_mon_vif.m_mon_cb.rvalid && m_mon_vif.aresetn) begin
        ////check1
        //case (|m_mon_vif.m_mon_cb.rdata)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RDATA is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RDATA is z\n", INST_NAME, $time);
        //endcase 
        ////check2
        //case (m_mon_vif.m_mon_cb.rready)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RREADY is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RREADY is z\n", INST_NAME, $time);
        //endcase 
        ////check3
        //case (|m_mon_vif.m_mon_cb.rid)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RID is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RID is z\n", INST_NAME, $time);
        //endcase 
        ////check4
        //case (|m_mon_vif.m_mon_cb.rresp)
        //1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RRESP is x\n", INST_NAME, $time);
        //1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RRESP is z\n", INST_NAME, $time);
        //endcase 
      //end
    //end
  //join_none
//endtask
////
//function void AxiMasterMonitor::report_phase(uvm_phase phase);
  //`uvm_info(get_type_name(), $sformatf("preparing for closing checker file!!!"), UVM_LOW)
  //if(chk_error_file == 1) begin
    //$fclose(chk_error_file);
  //end
//endfunction
//

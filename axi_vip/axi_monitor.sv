//===========================================================================
//--Project: AXI_TO_APB IP
//--File: axi_monitor.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//===========================================================================
class AxiMasterMonitor extends uvm_monitor;
  `uvm_component_utils(AxiMasterMonitor)
  //--------------------------------------------------
  //Data members
  //--------------------------------------------------
  //config object
  axi_agent_config mon_cfg;
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
  join_none
endtask
//
task AxiMasterMonitor::Reset_All_Queue();
  wait(mon_cfg.vif.aresetn==1'b0) begin
    WrReqCovMbox = new();
    RdReqCovMbox = new();
    WrDataCovMbox = new();
    RdDataCovMbox = new();
    BChannelCovMbox = new();
    //
  end
  //
  while(1) begin
  @(negedge mon_cfg.vif.aresetn) begin
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
    @(mon_cfg.vif.m_mon_cb);
    this.axi_mon_resetn = mon_cfg.vif.aresetn;
    AxiResetn_toScoreBoard.write(this.axi_mon_resetn);
  end
endtask
//
//--collect Read Request
task AxiMasterMonitor::collect_RdRequest();
  //
  while(1) begin
    @(mon_cfg.vif.m_mon_cb);
    if(mon_cfg.vif.m_mon_cb.arvalid && mon_cfg.vif.m_mon_cb.arready) begin
      //
      rreq_h = axi_req_item::type_id::create("rreq_h");
      rreq_h.wr_or_rd = 1'b0;
      rreq_h.slv_idx = mon_cfg.vif.m_mon_cb.arid[31:16];
      rreq_h.id = mon_cfg.vif.m_mon_cb.arid[7:0];
      rreq_h.addr = mon_cfg.vif.m_mon_cb.araddr;
      rreq_h.len = mon_cfg.vif.m_mon_cb.arlen;
      rreq_h.size = mon_cfg.vif.m_mon_cb.arsize;
      rreq_h.burst = burst_name'(mon_cfg.vif.m_mon_cb.arburst);
      //send to ScoreBoarreq_h
      AxiRdAddr_toScoreBoard.write(rreq_h);
      `ifdef PRINT_AXI_RREQ
      `uvm_info(get_name(), "Send AXI RREQ to scb", UVM_LOW)
      rreq_h.print();
      `endif
  end
  end
endtask
//
//
task AxiMasterMonitor::collect_ReadData();
  while(1) begin
    @(mon_cfg.vif.m_mon_cb iff (mon_cfg.vif.m_mon_cb.rvalid && mon_cfg.vif.m_mon_cb.rready));
    //scoreboard
    rdata_h = axi_data_item::type_id::create("rdata_h");
    rdata_h.data = mon_cfg.vif.m_mon_cb.rdata;
    rdata_h.wr_or_rd = ~mon_cfg.vif.m_mon_cb.rvalid;
    rdata_h.be = 4'h0;
    rdata_h.last = mon_cfg.vif.m_mon_cb.rlast;
    rdata_h.resp = resp_name'(mon_cfg.vif.m_mon_cb.rresp);
    rdata_h.id = mon_cfg.vif.m_mon_cb.rid;
    //write item on scoreboard
    AxiRData_toScoreBoard.write(rdata_h);
  end
endtask
//
//--collect Write Request
task AxiMasterMonitor::collect_WrRequest();
  while(1) begin
    @(mon_cfg.vif.m_mon_cb);
    if(mon_cfg.vif.m_mon_cb.awvalid && mon_cfg.vif.m_mon_cb.awready) begin
      wreq_h = axi_req_item::type_id::create("wreq_h");
      wreq_h.wr_or_rd = 1'b1;
      wreq_h.slv_idx = mon_cfg.vif.m_mon_cb.awid[31:16];
      wreq_h.id = mon_cfg.vif.m_mon_cb.awid[7:0];
      wreq_h.addr = mon_cfg.vif.m_mon_cb.awaddr;
      wreq_h.len = mon_cfg.vif.m_mon_cb.awlen;
      wreq_h.size = mon_cfg.vif.m_mon_cb.awsize;
      wreq_h.burst = burst_name'(mon_cfg.vif.m_mon_cb.awburst);
      //send to ScoreBoard
      AxiWrAddr_toScoreBoard.write(wreq_h);
      `ifdef PRINT_AXI_WREQ
      `uvm_info(get_name(), "Send AXI WREQ to scb", UVM_LOW)
      wreq_h.print();
      `endif
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
      @(mon_cfg.vif.m_mon_cb iff (mon_cfg.vif.m_mon_cb.wvalid && mon_cfg.vif.m_mon_cb.wready));
      //
      wdata_h = axi_data_item::type_id::create("wdata_h");//(**)
      //-- create item in build_phase() (*)
      //-- AXI wdata generated (randomize) is array (multiple beats) once 
      //-- this monitor only sends one beat to Scoreboard in turn
      //-- (*) causes DATA LOSS (data override) (***) 
      //-- therefore create new item (**) to avoid (***)
      wdata_h.id = 'hz;
      wdata_h.data = mon_cfg.vif.m_mon_cb.wdata;
      wdata_h.be = mon_cfg.vif.m_mon_cb.wstrb;
      wdata_h.wr_or_rd = mon_cfg.vif.m_mon_cb.wvalid;
      wdata_h.last = mon_cfg.vif.m_mon_cb.wlast;
      wdata_h.resp = resp_name'(2'b01); 
      //
      //scoreboard
      AxiWData_toScoreBoard.write(wdata_h);
      `ifdef PRINT_AXI_WDATA
      `uvm_info(get_name(), "Send AXI WDATA to scb", UVM_LOW)
      wdata_h.print();
      `endif
      //
    end //end of while(1)
    //
endtask
//
task AxiMasterMonitor::collect_WriteResp();
  while(1) begin
    @(mon_cfg.vif.m_mon_cb iff mon_cfg.vif.m_mon_cb.bvalid && mon_cfg.vif.m_mon_cb.bready);
    brsp_h = axi_brsp_item::type_id::create("brsp_h");
    brsp_h.resp = resp_name'(mon_cfg.vif.m_mon_cb.bresp);
    brsp_h.id = mon_cfg.vif.m_mon_cb.bid;
    //
    AxiBresp_toScoreBoard.write(brsp_h);
    //
  end
endtask
//

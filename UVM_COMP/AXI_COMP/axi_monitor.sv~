//======================================================
//UVM component
//======================================================
import type_package::*; //req_info
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
  req_info req_info_cov;
  //
  mailbox #(req_info) WrReqCovMbox, RdReqCovMbox;
  mailbox #(shared_item) RdDataCovMbox;
  mailbox #(shared_item) WrDataCovMbox;
  mailbox #(b_channel_info) BChannelCovMbox;
  //
  string sim_result_path;
  int chk_error_file;
  string INST_NAME;
  //SCOREBOARD
  logic axi_mon_resetn;
  b_channel_info b_channel_info_sb;
  //axi_transaction #(DW, AW1) w_trans, r_trans;   //sequence item
  shared_item whole_wtrans, whole_rtrans;    //new object only contains needed details to compare
  //-- port to connect sb and fc
  uvm_analysis_port #(logic) AxiResetn_toScoreBoard;
  uvm_analysis_port #(req_info) AxiRdAddr_toScoreBoard;
  uvm_analysis_port #(shared_item) AxiRData_toScoreBoard;
  uvm_analysis_port #(req_info) AxiWrAddr_toScoreBoard;
  uvm_analysis_port #(shared_item) AxiWData_toScoreBoard;
  uvm_analysis_port #(b_channel_info) AxiBresp_toScoreBoard;
  //
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
  extern task check_protocol();
  extern virtual function void report_phase(uvm_phase phase);
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
    if (!uvm_config_db#(string)::get(this, "", "axi_chk_inst_name", INST_NAME)) begin
      `uvm_fatal(get_type_name(), "axi_chk_inst_name NOT found in config DB!!!")
    end
    //
    //get actual simulation path
    //
    if (!uvm_config_db#(string)::get(this, "", "sim_result_path", sim_result_path)) begin
      `uvm_fatal(get_type_name(), "No sim_result_path found in config DB!!!")
    end
    `uvm_info(get_type_name(), $sformatf("Results will be stored at: %s", sim_result_path), UVM_LOW)

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
      if(mon_cfg.axi_agt_cfg.active == UVM_ACTIVE) begin
        check_protocol();
      end
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
  req_info rd;
  //
  while(1) begin
    @(m_mon_vif.m_mon_cb);
    if(m_mon_vif.m_mon_cb.arvalid && m_mon_vif.m_mon_cb.arready) begin
      //
      rd.id = {1'b0, m_mon_vif.m_mon_cb.arid};
      rd.address = m_mon_vif.m_mon_cb.araddr;
      rd.len = m_mon_vif.m_mon_cb.arlen;
      rd.size = m_mon_vif.m_mon_cb.arsize;
      rd.burst = burst_name'(m_mon_vif.m_mon_cb.arburst);
      //send to ScoreBoard
      AxiRdAddr_toScoreBoard.write(rd);
    end
  end
endtask
//
//
task AxiMasterMonitor::collect_ReadData();
  //
  //
  while(1) begin
    @(m_mon_vif.m_mon_cb iff (m_mon_vif.m_mon_cb.rvalid && m_mon_vif.m_mon_cb.rready));
    //scoreboard
    whole_rtrans = shared_item::type_id::create("whole_rtrans");
    whole_rtrans.data = m_mon_vif.m_mon_cb.rdata;
    whole_rtrans.write = ~m_mon_vif.m_mon_cb.rvalid;
    whole_rtrans.wstrb = m_mon_vif.m_mon_cb.wstrb;
    whole_rtrans.last = m_mon_vif.m_mon_cb.rlast;
    whole_rtrans.resp = resp_name'(m_mon_vif.m_mon_cb.rresp);
    whole_rtrans.id = m_mon_vif.m_mon_cb.rid;
    //write item on scoreboard
    AxiRData_toScoreBoard.write(whole_rtrans);
    // end
  end
endtask
//
//--collect Write Request
task AxiMasterMonitor::collect_WrRequest();
  req_info wr;
  //
  while(1) begin
    @(m_mon_vif.m_mon_cb);
    if(m_mon_vif.m_mon_cb.awvalid && m_mon_vif.m_mon_cb.awready) begin
      //
      wr.id = {1'b1, m_mon_vif.m_mon_cb.awid};
      wr.address = m_mon_vif.m_mon_cb.awaddr;
      wr.len = m_mon_vif.m_mon_cb.awlen;
      wr.size = m_mon_vif.m_mon_cb.awsize;
      wr.burst = burst_name'(m_mon_vif.m_mon_cb.awburst);
      //send to ScoreBoard
      AxiWrAddr_toScoreBoard.write(wr);
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
      whole_wtrans = shared_item::type_id::create("whole_wtrans");//(**)
      //-- create item in build_phase() (*)
      //-- AXI wdata generated (randomize) is array (multiple beats) once 
      //-- this monitor only sends one beat to Scoreboard in turn
      //-- (*) causes DATA LOSS (data override) (***) 
      //-- therefore create new item (**) to avoid (***)
      whole_wtrans.data = m_mon_vif.m_mon_cb.wdata;
      whole_wtrans.wstrb = m_mon_vif.m_mon_cb.wstrb;
      whole_wtrans.write = m_mon_vif.m_mon_cb.wvalid;
      whole_wtrans.last = m_mon_vif.m_mon_cb.wlast;
      whole_wtrans.resp = resp_name'(2'b01); 
      //
      //scoreboard
      AxiWData_toScoreBoard.write(whole_wtrans);
      //functional coverage
      //if(mon_cfg.functional_coverage) begin
        //// WrDataCovQueue.push_back(whole_wtrans);
        //WrDataCovMbox.put(whole_wtrans);
      //end
      //
    end //end of while(1)
    //
endtask
//
task AxiMasterMonitor::collect_WriteResp();
  while(1) begin
    @(m_mon_vif.m_mon_cb iff m_mon_vif.m_mon_cb.bvalid && m_mon_vif.m_mon_cb.bready);
    b_channel_info_sb.bresp = resp_name'(m_mon_vif.m_mon_cb.bresp);
    b_channel_info_sb.bid = m_mon_vif.m_mon_cb.bid;
    //
    AxiBresp_toScoreBoard.write(b_channel_info_sb);
    //if(mon_cfg.functional_coverage) begin
      //// BrespCovQueue.push_back(b_channel_info_sb);
      //BChannelCovMbox.put(b_channel_info_sb);
    //end
    //
  end
endtask
//
//------------------------------------CHECK INTERFACE--------------------------------------------
//
task AxiMasterMonitor::check_protocol();
  chk_error_file = $fopen($sformatf("%s/CHECKER_ERROR/chk_error.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
  if(chk_error_file == 0) begin
    `uvm_warning(get_type_name(), $sformatf("Failed to open chk_error.log file"))
  end
  //
  fork
    forever begin
      @(m_mon_vif.m_mon_cb);
      if(m_mon_vif.m_mon_cb.awvalid && m_mon_vif.aresetn) begin
        case (|m_mon_vif.m_mon_cb.awaddr)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWADDR is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWADDR is z\n", INST_NAME, $time);
        endcase 
        //check 2
        case (|m_mon_vif.m_mon_cb.awlen)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWLEN is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWLEN is z\n", INST_NAME, $time);
        endcase 
        //check 3
        case (|m_mon_vif.m_mon_cb.awsize)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWSIZE is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWSIZE is z\n", INST_NAME, $time);
        endcase 
        //check 4
        case (|m_mon_vif.m_mon_cb.awburst)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWBURST is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWBURST is z\n", INST_NAME, $time);
        endcase 
        //check 5
        case (|m_mon_vif.m_mon_cb.awid)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWID is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] AWID is z\n", INST_NAME, $time);
        endcase
      end
    end
    //WDATA CHANNEL
    forever begin
      @(m_mon_vif.m_mon_cb);
      if(m_mon_vif.m_mon_cb.wvalid && m_mon_vif.aresetn) begin
      case (|m_mon_vif.m_mon_cb.wdata)
      1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] WDATA is x\n", INST_NAME, $time);
      1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] WDATA is z\n", INST_NAME, $time);
      endcase 
      //check2
      case (|m_mon_vif.m_mon_cb.wstrb)
      1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] WSTRB is x\n", INST_NAME, $time);
      1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] WSTRB is z\n", INST_NAME, $time);
      endcase 
      //check3
      case (m_mon_vif.m_mon_cb.wready)
      1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] WREADY is x\n", INST_NAME, $time);
      1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] WREADY is z\n", INST_NAME, $time);
      endcase
      end
    end
    //
    forever begin
      @(m_mon_vif.m_mon_cb);
      if(m_mon_vif.m_mon_cb.bvalid && m_mon_vif.aresetn) begin
          //check1
          case (m_mon_vif.m_mon_cb.bid)
          1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] BID is x\n", INST_NAME, $time);
          1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] BID is z\n", INST_NAME, $time);
          endcase 
          //check2
          case (m_mon_vif.m_mon_cb.bresp)
          1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] BRESP is x\n", INST_NAME, $time);
          1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] BRESP is z\n", INST_NAME, $time);
          endcase 
          //check3
          case (m_mon_vif.m_mon_cb.bready)
          1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] BREADY is x\n", INST_NAME, $time);
          1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] BREADY is z\n", INST_NAME, $time);
          endcase 
      end
    end
    //RD ADDR CHANNEL
      forever begin
      @(m_mon_vif.m_mon_cb);
      if(m_mon_vif.m_mon_cb.arvalid && m_mon_vif.aresetn) begin
        case (|m_mon_vif.m_mon_cb.araddr)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARADDR is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARADDR is z\n", INST_NAME, $time);
        endcase 
        //check 2
        case (|m_mon_vif.m_mon_cb.arlen)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARLEN is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARLEN is z\n", INST_NAME, $time);
        endcase 
        //check 3
        case (|m_mon_vif.m_mon_cb.arsize)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARSIZE is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARSIZE is z\n", INST_NAME, $time);
        endcase 
        //check 4
        case (|m_mon_vif.m_mon_cb.arburst)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARBURST is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARBURST is z\n", INST_NAME, $time);
        endcase 
        //check 5
        case (|m_mon_vif.m_mon_cb.arid)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARID is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] ARID is z\n", INST_NAME, $time);
        endcase
      end
    end
    //
    //RDATA CHANNEL
    forever begin
      @(m_mon_vif.m_mon_cb);
      if(m_mon_vif.m_mon_cb.rvalid && m_mon_vif.aresetn) begin
        //check1
        case (|m_mon_vif.m_mon_cb.rdata)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RDATA is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RDATA is z\n", INST_NAME, $time);
        endcase 
        //check2
        case (m_mon_vif.m_mon_cb.rready)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RREADY is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RREADY is z\n", INST_NAME, $time);
        endcase 
        //check3
        case (|m_mon_vif.m_mon_cb.rid)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RID is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RID is z\n", INST_NAME, $time);
        endcase 
        //check4
        case (|m_mon_vif.m_mon_cb.rresp)
        1'bx: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RRESP is x\n", INST_NAME, $time);
        1'bz: $fdisplay(chk_error_file, "[AXI_WARNING][%s][%0t ns] RRESP is z\n", INST_NAME, $time);
        endcase 
      end
    end
  join_none
endtask
//
function void AxiMasterMonitor::report_phase(uvm_phase phase);
  `uvm_info(get_type_name(), $sformatf("preparing for closing checker file!!!"), UVM_LOW)
  if(chk_error_file == 1) begin
    $fclose(chk_error_file);
  end
endfunction
//

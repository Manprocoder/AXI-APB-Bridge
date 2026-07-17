//
//
//
interface axi_intf(input logic aclk);
  parameter DW = 32;
  parameter AW1 = 32;
  //axi address channel
  logic aresetn;
  logic awvalid;
  logic [7:0] awid;
  logic [7:0] awlen;
  logic [1:0] awburst;
  logic [2:0] awsize;
  logic [AW1-1:0] awaddr;
  logic awready;
  logic [2:0] awprot;

  //axi write data channel
  logic [DW-1:0] wdata;
  logic [3:0] wstrb;
  logic wvalid;
  logic wlast;
  logic wready;

  //axi write response channel
  logic [7:0] bid;
  logic [1:0] bresp;
  logic bvalid;
  logic bready;

  //axi read address channel
  logic arvalid;
  logic [7:0] arid;
  logic [7:0] arlen;
  logic [1:0] arburst;
  logic [2:0] arsize;
  logic [AW1-1:0] araddr;
  logic arready;
  logic [2:0] arprot;

  //axi read data channel
  logic [7:0] rid;
  logic [DW-1:0] rdata;
  logic rvalid;
  logic rlast;
  logic rready;
  logic [1:0] rresp;
//AXI driver
clocking m_drv_cb @(posedge aclk);
 // default input #1 output #1;
  input awready, wready, bid, bresp, bvalid, arready, rdata, rid, rvalid, rlast, rresp;
  output awvalid, awid, awlen, awburst, awsize, awaddr, awprot, wdata, wstrb, wvalid, wlast,bready, 
          arvalid, arid, arlen, arburst, arsize, araddr, arprot, rready;
endclocking

  //AXI monitor
clocking m_mon_cb @(posedge aclk);
  //default input #1;
  input awready, wready, bid, bresp, bvalid, arready, rdata, rid, rvalid, rlast, rresp,
        awvalid, awid, awlen, awburst, awsize, awaddr, wdata, wvalid, wstrb, wlast,bready, 
        arvalid, arid, arlen, arburst, arsize, araddr, rready;
endclocking
  //
  //open file
  `ifdef PRINT_TO_VIF_SVA_FILE
	  string test_case;
  string sim_result_path;
  int axi_log_file;
  //
  initial begin
    //
    if (!$value$plusargs("UVM_TESTNAME=%s", test_case)) begin
      test_case = "DEFAULT";
    end
    $sformat(sim_result_path, "../SIM_RESULT/%0dSLAVE/%s", `SLAVE_CNT, test_case);
    axi_log_file = $fopen($sformatf("%s/VIF_SVA/axi_error.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
    if(axi_log_file == 0) begin
      $display("ERROR: Could not open axi_error.log");
    end
  end
  `endif
  //
  task wait_for_reset();
    wait(aresetn == 1'b0);
  endtask
  //
  task wait_RisingEdge_reset();
    @(posedge aresetn);
  endtask
  //
  task wait_FallingEdge_reset();
    @(negedge aresetn);
  endtask
  //
  function logic aresetn_value();
    return aresetn;
  endfunction
  //
  //CRITICAL NOTE: as using @(m_mon_cb), we must use m_mon_cb."signal" otherwise missed signal will occur
  //--obviously bvalid && bready -> false
  //
  task one_write_req_done();
    // @(posedge aclk iff bvalid && bready);
    @(m_mon_cb iff m_mon_cb.bvalid && m_mon_cb.bready);
  endtask
  //
  task one_read_req_done();
    // @(posedge aclk iff (rvalid & rlast & rready));
    @(m_mon_cb iff (m_mon_cb.rvalid && m_mon_cb.rlast && m_mon_cb.rready)); 
  endtask
  //****************************************************************************************************
  //-------------------------------------AXI PROTOCOL SVA
  //****************************************************************************************************

  //(0.1) REQ RESET ASSERTION
  //DEFINE
  property reset_all_reqsignal;
	//@(posedge aclk)
	@(negedge aresetn)
	1 |=> (awvalid == 0 && arvalid == 0);
  endproperty
  //DO
  assert property (reset_all_reqsignal)
  else begin
    `ifdef PRINT_TO_VIF_SVA_FILE
    $fdisplay(axi_log_file, "[RESET_REQSIGNAL][%0t ns]: All req signals are not properly reset!!!", $time);
    `else
    $error("[RESET_REQSIGNAL]: AWVALID and ARVALID are NOT properly reset!!!");
    `endif
  end
  //(0.2) DATA RESET ASSERTION
  //DEFINE
  property reset_all_datasignal;
	//@(posedge aclk)
	//(!aresetn) |=> (wvalid == 0 && rvalid == 0);
	@(negedge aresetn)
	1 |=> (wvalid == 0 && rvalid == 0);
  endproperty
  //DO
  assert property (reset_all_datasignal)
  else begin
    `ifdef PRINT_TO_VIF_SVA_FILE
    $fdisplay(axi_log_file, "[RESET_DATASIGNAL][%0t ns]: All data signals are not properly reset!!!", $time);
    `else 
    $error("[RESET_DATASIGNAL]: All data signals are not properly reset!!!");
    `endif
  end
  //(0.3) RESP RESET ASSERTION
  //DEFINE
  property reset_all_respsignal;
	//@(posedge aclk)
	//(!aresetn) |=> (bvalid == 0);
	@(negedge aresetn)
	1 |=> (bvalid == 0);
  endproperty
  //DO
  assert property (reset_all_respsignal)
  else begin
    `ifdef PRINT_TO_VIF_SVA_FILE
    $fdisplay(axi_log_file, "[RESET_RESPSIGNAL][%0t ns]: All resp signals are not properly reset!!!", $time);
    `else
    $error("[RESET_RESPSIGNAL]: BVALID is not properly reset!!!");
    `endif 
  end

  //**************************************************************************************************
  //*************************************ASSERTION WITH RESET = 1*************************************
  //(1)
  //DEFINE
  property aw_handshake;
    @(posedge aclk) disable iff (!aresetn)
      awvalid |-> strong(awvalid[*1:$] intersect awready[->1]);
  endproperty
  //DO
  assert property (aw_handshake)
  else begin
    `ifdef PRINT_TO_VIF_SVA_FILE
    $fdisplay(axi_log_file, "[AW_HANDSHAKE][%0t ns]: There is no handshake in AW channel!!!", $time);
    `else
    $error("[AW_HANDSHAKE]: There is no handshake in AW channel!!!");
    `endif
  end

  //***************************************REUSABLE ASSERTION*************************************
  //define start_of_burst sequence for future reusability
  //
//sequence start_of_burst(valid, ready, last);
   //$rose(valid && ready && !last);
//endsequence
  //***************************************W CHANNEL ASSERTION*************************************
  //(2)
  //2.1
  //DEFINE
  property w_handshake;
    @(posedge aclk) disable iff (!aresetn)
      wvalid |-> strong(wvalid[*1:$] intersect wready[->1]);
  endproperty
  //DO
  assert property (w_handshake)
  else begin
    `ifdef PRINT_TO_VIF_SVA_FILE
    $fdisplay(axi_log_file, "[W_HANDSHAKE][%0t ns]: There is no handshake in W channel!!!", $time);
    `else
    $error("[W_HANDSHAKE]: There is no handshake in W channel!!!");
    `endif
  end
  //(3)
  //DEFINE
  property b_handshake;
    @(posedge aclk) disable iff (!aresetn)
     bvalid |-> strong(bvalid[*1:$] intersect bready[->1]);
  endproperty
  //DO
  assert property (b_handshake)
  else begin
    `ifdef PRINT_TO_VIF_SVA_FILE
    $fdisplay(axi_log_file, "[B_HANDSHAKE][%0t ns]: There is no handshake in B channel!!!", $time);
    `else
    $error("[B_HANDSHAKE]: There is no handshake in B channel!!!");
    `endif
  end
//(4)
  //DEFINE
  property b_stable;
    @(posedge aclk) disable iff (!aresetn)
    	bvalid && !bready |=> ((bid == $past(bid, 1, bvalid)) && (bresp == $past(bresp, 1, bvalid)));
  endproperty
  //DO
  assert property (b_stable)
  else begin
    `ifdef PRINT_TO_VIF_SVA_FILE
    $fdisplay(axi_log_file, "[B_STABLE][%0t ns]: BRESP and BID changed before BREADY is HIGH in B channel!!!", $time);
    `else
    $error("[B_STABLE]: BRESP and BID changed before BREADY is HIGH in B channel!!!");
    `endif
  end

  //**************************************************************************************
  //----------------------------READ SVA HANDLE
  //**************************************************************************************
  //(1)
  //DEFINE
  property ar_handshake;
    @(posedge aclk) disable iff (!aresetn)
  	arvalid |-> strong(arvalid[*1:$] intersect arready[->1]);
  endproperty
  //DO
  assert property (ar_handshake)
  else begin
    `ifdef PRINT_TO_VIF_SVA_FILE
    $fdisplay(axi_log_file, "[AR_HANDSHAKE][%0t ns]: There is no handshake in AR channel!!!", $time);
    `else
    $error("[AR_HANDSHAKE]: There is no handshake in AR channel!!!");
    `endif
  end
  //2
  //***************************************R CHANNEL ASSERTION*************************************
  //(2.1)
  //DEFINE
  property r_handshake;
    @(posedge aclk) disable iff (!aresetn)
      rvalid |-> strong(rvalid[*1:$] intersect rready[->1]);
  endproperty
  //DO
  assert property (r_handshake)
  else begin
    `ifdef PRINT_TO_VIF_SVA_FILE
    $fdisplay(axi_log_file, "[R_HANDSHAKE][%0t ns]: There is no handshake in R channel!!!", $time);
    `else
    $error("[R_HANDSHAKE]: There is no handshake in R channel!!!");
    `endif
  end
    //
  //close file
  //
  `ifdef PRINT_TO_VIF_SVA_FILE
  final begin
    if(axi_log_file == 1) begin
     $fclose(axi_log_file);
    end
  end
  `endif
endinterface




//======================================================
//--Project: Design and Verify AXI_to_APB bridge
//--File: axi_if.sv
//--Author: Nguyen Ngoc Man
//--Description: AXI4 virtual interface
//======================================================
interface axi_intf(input logic aclk);
  parameter AXI_DW = 32;
  parameter AXI_AW = 32;
  //axi address channel
  logic aresetn;
  logic awvalid;
  logic [AXI_DW-1:0] awid;
  logic [7:0] awlen;
  logic [1:0] awburst;
  logic [2:0] awsize;
  logic [AXI_AW-1:0] awaddr;
  logic awready;
  logic [2:0] awprot;

  //axi write data channel
  logic [AXI_DW-1:0] wdata;
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
  logic [AXI_DW-1:0] arid;
  logic [7:0] arlen;
  logic [1:0] arburst;
  logic [2:0] arsize;
  logic [AXI_AW-1:0] araddr;
  logic arready;
  logic [2:0] arprot;

  //axi read data channel
  logic [7:0] rid;
  logic [AXI_DW-1:0] rdata;
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
  //
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
    $error("[RESET_REQSIGNAL]: AWVALID and ARVALID are NOT properly reset!!!");
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
    $error("[RESET_DATASIGNAL]: All data signals are not properly reset!!!");
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
    $error("[RESET_RESPSIGNAL]: BVALID is not properly reset!!!");
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
    $error("[AW_HANDSHAKE]: There is no handshake in AW channel!!!");
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
    $error("[W_HANDSHAKE]: There is no handshake in W channel!!!");
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
    $error("[B_HANDSHAKE]: There is no handshake in B channel!!!");
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
    $error("[B_STABLE]: BRESP and BID changed before BREADY is HIGH in B channel!!!");
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
    $error("[AR_HANDSHAKE]: There is no handshake in AR channel!!!");
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
    $error("[R_HANDSHAKE]: There is no handshake in R channel!!!");
  end
endinterface




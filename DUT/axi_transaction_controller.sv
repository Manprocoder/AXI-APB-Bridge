//===================================================================================
// File name: x2p_core.sv
// Project  : X2P
// Function : IP core design of AXI to APB bridge
//===================================================================================
module axi_transaction_controller (// AXI protocol
    aclk,
    aresetn,
// Address write channel
	awvalid,
	awready,
	awaddr,
	awsize,
	awlen,
	awburst,
	awid,
	awprot,
	// Address read channel
	arvalid,
	arready,
	araddr,
	arsize,
	arlen,
	arburst,
	arid,
	arprot,
	// Write data channel
	wvalid,
	wready,
	wdata,
	wstrb,
	wlast,
	// Read data channel
	rvalid,
	rready,
	rlast,
	rresp,
	rid,
	rdata,
	// Write respond channel
	bvalid,
	bready,
	bresp,
	bid,
	//arbiter input
	rd_trans_done_i,
	wr_trans_done_i,
	//apb master input
	prdata_i,
	pslverr_i,
	write_to_rd_sfifo_i,
	read_from_wd_sfifo_i,
	dec_error_i,
	latch_resp_i,
	//req
	sfifo_aw_empty_o,
	sfifo_ar_empty_o,
	//data
	sfifo_wd_almost_empty_o,
	sfifo_rd_almost_full_o,
	//
	  write_burst_addr_o,
	  write_burst_len_o,
	  write_burst_size_o,
	  write_burst_name_o,
	  write_burst_prot_o,
		//	
	  read_burst_addr_o,
	  read_burst_len_o,
	  read_burst_size_o,
	  read_burst_name_o,
	  read_burst_prot_o,
	  //
	  wdata_to_apb_o,
	  wstrb_to_apb_o
	  //
);
  //iclude parameter file
  import parameter_pkg::*; 
  //******************************************************
  //ports declaration
  //******************************************************
  input logic                     aclk;
  input logic                     aresetn;
  // Address write channel
  input  logic                    awvalid;
  input  logic [31:0]             awaddr;
  input  logic [2:0]              awsize;
  input  logic [7:0]              awlen;
  input  logic [1:0]              awburst;
  input  logic [7:0]              awid;
  input  logic [2:0]              awprot;
  output logic                    awready;
  // address read channel
  input  logic                    arvalid;
  input  logic [31:0]             araddr;
  input  logic [2:0]              arsize;
  input  logic [7:0]              arlen;
  input  logic [1:0]              arburst;
  input  logic [7:0]              arid;
  input  logic [2:0]              arprot;
  output logic                    arready;
  //write data channel
  input  logic                    wvalid;
  input  logic [31:0]             wdata;
  input  logic [3:0]              wstrb;
  input  logic                    wlast;
  output logic                    wready;
  //read data channel
  input  logic                    rready;
  output logic                    rvalid;
  output logic [1:0]              rresp;
  output logic                    rlast;
  output logic [7:0]              rid;
  output logic [31:0]             rdata;
  //write respond channel
  input  logic                    bready;
  output logic                    bvalid;
  output logic [1:0]              bresp;
  output logic [7:0]              bid;
//arbiter inputs
input logic rd_trans_done_i;
input logic wr_trans_done_i;
input logic [31:0] prdata_i;
input logic pslverr_i;
input logic write_to_rd_sfifo_i;
input logic read_from_wd_sfifo_i;
input logic dec_error_i;
input logic latch_resp_i;
	//req
output logic sfifo_aw_empty_o;
output logic sfifo_ar_empty_o;
	//data
output logic sfifo_wd_almost_empty_o;
output logic sfifo_rd_almost_full_o;
//	
output logic [31:0] write_burst_addr_o;
output logic [7:0]  write_burst_len_o;
output logic [2:0]  write_burst_size_o;
output logic [1:0]  write_burst_name_o;
output logic [2:0]  write_burst_prot_o;
//
output logic [31:0] read_burst_addr_o;
output logic [7:0]  read_burst_len_o;
output logic [2:0]  read_burst_size_o;
output logic [1:0]  read_burst_name_o;
output logic [2:0]  read_burst_prot_o;
//
output logic [31:0] wdata_to_apb_o;
output logic [3:0] wstrb_to_apb_o;
  //******************************************************
  //internal signals
  //******************************************************
  //SFIFO_AW
  logic                           sfifo_aw_full;
  logic                           sfifo_aw_we;
  logic                           sfifo_aw_re;
  logic [7:0]                     sfifo_aw_id;
  //SFIFO_AR
  logic                           sfifo_ar_full;
  logic                           sfifo_ar_we;
  logic                           sfifo_ar_re;
  logic [7:0]                     sfifo_ar_id;
  //SFIFO_WD
  logic                           sfifo_wd_full;
  logic                           sfifo_wd_we;
  logic                           sfifo_wd_re;
  logic [31:0]                    sfifo_wd_wdata;
  logic [3:0]                     sfifo_wd_wstrb;
  logic 			  sfifo_wd_last;
  logic	 			  wlast_flag;
  //SFIFO_RD
  logic                           sfifo_rd_empty;
  logic                           sfifo_rd_we;
  logic                           sfifo_rd_re;
  //RD_CH
  logic[1:0]                      resp_of_rdata;
  logic 			  rdata_last;
  //WRITE RESPONSE
  logic bresp_register;
  //
  parameter logic [POINTER_WIDTH:0] ALMOST_FULL_VALUE = 2**POINTER_WIDTH - 1'b1;
  parameter logic [POINTER_WIDTH:0] ALMOST_EMPTY_VALUE = 2**POINTER_WIDTH - 4'd14;
//*******************************************************************
//X2P_SFIFO_AR
//*******************************************************************
  sfiforeq #(
	.DATA_WIDTH(X2P_SFIFO_AR_DATA_WIDTH),
       	.POINTER_WIDTH(POINTER_WIDTH)
  ) ar_sfifo (
  .clk(aclk),
  .rst_n(aresetn),
  .wr(sfifo_ar_we),
  .rd(sfifo_ar_re),
  .data_in({araddr[31:0], arid[7:0], arlen[7:0], arsize[2:0], arburst[1:0], arprot[2:0]}),
  .sfifo_empty(sfifo_ar_empty_o),
  .sfifo_full(sfifo_ar_full),
  .data_out({read_burst_addr_o[31:0], sfifo_ar_id[7:0], read_burst_len_o[7:0], 
	  read_burst_size_o[2:0], read_burst_name_o[1:0], read_burst_prot_o[2:0]})
  //
  //
  );
  //Logic
  assign arready  	= ~sfifo_ar_full;
  assign sfifo_ar_we 	= arready & arvalid;
  assign sfifo_ar_re 	= rd_trans_done_i;
  //*******************************************************************
  //X2P_SFIFO_RD
  //*******************************************************************
  sfifordata #(
	.DATA_WIDTH(X2P_SFIFO_RD_DATA_WIDTH), .POINTER_WIDTH(POINTER_WIDTH),
	.ALMOST_FULL_VALUE(ALMOST_FULL_VALUE), .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE)
) rd_sfifo(
  .clk(aclk),
  .rst_n(aresetn),
  .wr(sfifo_rd_we),
  .rd(sfifo_rd_re),
  .data_in({rd_trans_done_i, prdata_i[31:0], resp_of_rdata[1:0], sfifo_ar_id[7:0]}),
  .sfifo_empty(sfifo_rd_empty),
  .sfifo_almost_full(sfifo_rd_almost_full_o),
  .data_out({rdata_last, rdata[31:0], rresp[1:0], rid[7:0]})
  );
  //Logic
  assign rvalid      = ~sfifo_rd_empty;
  assign sfifo_rd_re = rvalid & rready;
  assign sfifo_rd_we = write_to_rd_sfifo_i;
  //RD_CH
  //resp_of_rdata
  always_comb begin
    if(~pslverr_i)
	  resp_of_rdata = OKAY;
	else if(dec_error_i)
	  resp_of_rdata = DECERR;
	else
	  resp_of_rdata = PSLVERR;
  end
  //rlast
  always_comb begin
	if(rvalid & rdata_last)
	  rlast = 1'b1;
	else
	  rlast = 1'b0;	
  end
  //*******************************************************************
  //X2P_SFIFO_AW
  //*******************************************************************
  sfiforeq #(
	  .DATA_WIDTH(X2P_SFIFO_AW_DATA_WIDTH),
	  .POINTER_WIDTH(POINTER_WIDTH)
) aw_sfifo(
  .clk(aclk),
  .rst_n(aresetn),
  .wr(sfifo_aw_we),
  .rd(sfifo_aw_re),
  .data_in({awaddr[31:0], awid[7:0], awlen[7:0], awsize[2:0], awburst[1:0], awprot[2:0]}),
  .sfifo_empty(sfifo_aw_empty_o),
  .sfifo_full(sfifo_aw_full),
  .data_out({write_burst_addr_o[31:0], sfifo_aw_id[7:0], write_burst_len_o[7:0], 
	  write_burst_size_o[2:0], write_burst_name_o[1:0], write_burst_prot_o[2:0]})
  );
  //Logic
  assign awready 	= ~sfifo_aw_full;
  assign sfifo_aw_we    = awready & awvalid;
  assign sfifo_aw_re    = wr_trans_done_i;
  //*******************************************************************
  //X2P_SFIFO_WD
  //*******************************************************************
  sfifowdata #(
	.DATA_WIDTH(X2P_SFIFO_WD_DATA_WIDTH), .POINTER_WIDTH(POINTER_WIDTH),
	.ALMOST_FULL_VALUE(ALMOST_FULL_VALUE), .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE)
  ) wd_sfifo(
  .clk(aclk),
  .rst_n(aresetn),
  .wr(sfifo_wd_we),
  .rd(sfifo_wd_re),
  .data_in({wdata[31:0], wstrb[3:0], wlast}),
  .sfifo_almost_empty(sfifo_wd_almost_empty_o),
  .sfifo_full(sfifo_wd_full),
  .data_out({wdata_to_apb_o[31:0], wstrb_to_apb_o[3:0], wlast_flag})
  );
//logic
assign wready      = ~sfifo_wd_full;
assign sfifo_wd_we = wvalid & wready;
assign sfifo_wd_re = read_from_wd_sfifo_i;
//
//B CHANNEL
//
//bresp register
//
always_ff@(posedge aclk, negedge aresetn) begin
  if(~aresetn) bresp_register <= 1'b0;
  else if(wr_trans_done_i) bresp_register <= 1'b0; 
  else if(latch_resp_i) bresp_register <= pslverr_i;
end
//
//INFO
//
always_ff @(posedge aclk, negedge aresetn) begin
	if(~aresetn) begin
	  bresp[1:0] <= OKAY;
	  bid[7:0] <= 8'd0;
	  bvalid <= 1'b0;
  	end
	else if(wr_trans_done_i) begin
		  bid[7:0] <= sfifo_aw_id[7:0];
		  bvalid <= 1'b1;
		  //
		  if(~bresp_register | ~pslverr_i)
		    bresp[1:0] <= OKAY | ~{2{wlast_flag}};
		  else if(dec_error_i)
		    bresp[1:0] <= DECERR;
		  else
		    bresp[1:0] <= PSLVERR;
	end
	else if(bready) begin
	  bresp[1:0] <= OKAY;
	  bid[7:0] <= 8'd0;
	  bvalid <= 1'b0;
	end
end
//
//
//
endmodule: axi_transaction_controller 

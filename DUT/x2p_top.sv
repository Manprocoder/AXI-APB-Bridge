//========================================================================
//Project Name: AXI4-APB4 Bridge
//File name: x2p_top.sv
//Description: AXI-APB Bridge Design complied to AXI4 and APB4 protocol
//Design Engineer: Nguyen Ngoc Man
//========================================================================
module x2p_top(aclk,
	       aresetn,
	   awvalid,
	   awaddr,
	   awsize,
	   awlen,
	   awburst,
	   awid,
	   awprot,
	   awready,
	   arvalid,
	   araddr,
	   arsize,
	   arlen,
	   arburst,
	   arid,
	   arprot,
	   arready,
	   wvalid,
	   wdata,
	   wstrb,
	   wlast,
	   wready,
	   rready,
	   rvalid,
	   rresp,
	   rlast,
	   rid,
	   rdata,
	   bready,
	   bvalid,
	   bresp,
	   bid,
	   pclk,
	   preset_n,
	   pready,
	   prdata,
	   pslverr,
	   paddr,
	   pwdata,
	   psel,
	   penable,
	   pprot,
	   pstrb,
	   pwrite
);
  //***************************************************************
  //declare ports 
  //***************************************************************
  input logic aclk;
  input logic aresetn;
  //ports declaration
  // Address write chanel
  input logic                    awvalid;
  input logic [31:0]             awaddr;
  input logic [2:0]              awsize;
  input logic [7:0]              awlen;
  input logic [1:0]              awburst;
  input logic [7:0]              awid;
  input logic [2:0]              awprot;
  output logic                   awready;
  // address read chanel
  input logic                    arvalid;
  input logic [31:0]             araddr;
  input logic [2:0]              arsize;
  input logic [7:0]              arlen;
  input logic [1:0]              arburst;
  input logic [7:0]              arid;
  input logic [2:0]              arprot;
  output logic                   arready;
  //write data chanel
  input logic                    wvalid;
  input logic [31:0]             wdata;
  input logic [3:0]              wstrb;
  input logic                    wlast;
  output logic                   wready;
  //read data chanel
  input logic                     rready;
  output logic                    rvalid;
  output logic [1:0]              rresp;
  output logic                    rlast;
  output logic [7:0]              rid;
  output logic [31:0]             rdata;
  //write data chanel
  input logic                     bready;
  output logic                    bvalid;
  output logic [1:0]              bresp;
  output logic [7:0]              bid;
  //APB interface 
  input logic pclk;
  input logic preset_n;
  input logic [`SLAVE_CNT-1:0]       pready;
  input logic [`SLAVE_CNT-1:0][31:0] prdata;
  input logic [`SLAVE_CNT-1:0]       pslverr;
  output logic [31:0]               paddr;
  output logic [31:0]               pwdata;
  output logic [`SLAVE_CNT-1:0]      psel;
  output logic                      penable;
  output logic [2:0]                pprot;
  output logic [3:0]                pstrb;
  output logic                      pwrite;
//***************************************************************
//WIRE VARIABLES
//***************************************************************
//AXI TRANSACTION CONTROLLER outputs
logic sfifo_ar_empty;
logic sfifo_aw_empty;
logic sfifo_rd_almost_full;
logic sfifo_wd_almost_empty;
logic [31:0] wdata_to_apb;
logic [3:0] wstrb_to_apb;
logic [31:0] write_burst_addr;
logic [7:0] write_burst_len;
logic [2:0] write_burst_size;
logic [1:0] write_burst_name;
logic [2:0] write_burst_prot;
	//	
logic [31:0] read_burst_addr;
logic [7:0] read_burst_len;
logic [2:0] read_burst_size;
logic [1:0] read_burst_name;
logic [2:0] read_burst_prot;
//ARBITER output 
logic [31:0] selected_addr;
logic [7:0] selected_len;
logic [2:0] selected_size;
logic [1:0] selected_burst;
logic [2:0] selected_prot;
logic wr_trans_done;
logic rd_trans_done;
logic transfer;
logic [31:0] transfer_addr;
logic write_enable;
//COUNTER outputs
logic burst_almost_done;
logic burst_done;
//DECODER outputs
logic dec_error;
logic nonexist_transfer
logic [`SLAVE_CNT-1:0] true_psel;
//APB MASTER outputs
//---send to AXI transaction controller
logic [31:0] prdataX;
logic pslverrX;
logic [4:0] master_ctrl;

  //***************************************************************
  //SUB_MODULES
  //***************************************************************
  axi_transaction_controller axi_slv_inst (
	//global signals
	.aclk(aclk),
	.aresetn(aresetn),
	//addres write channel
   .awvalid(awvalid),
   .awaddr(awaddr),
   .awsize(awsize),
   .awlen(awlen),
   .awburst(awburst),
   .awid(awid),
   .awprot(awprot),
   .awready(awready),
   //address read chanel
   .arvalid(arvalid),
   .araddr(araddr),
   .arsize(arsize),
   .arlen(arlen),
   .arburst(arburst),
   .arid(arid),
   .arprot(arprot),
   .arready(arready),
   //write data chanel
   .wvalid(wvalid),
   .wdata(wdata),
   .wstrb(wstrb),
   .wlast(wlast),
   .wready(wready),
   //read data chanel
   .rready(rready),
   .rvalid(rvalid),
   .rresp(rresp),
   .rlast(rlast),
   .rid(rid),
   .rdata(rdata),
   //write response chanel
   .bready(bready),
   .bvalid(bvalid),
   .bresp(bresp),
   .bid(bid),
	//arbiter input
	.rd_trans_done_i(rd_trans_done),
	.wr_trans_done_i(wr_trans_done),
	//apb master input
	.prdata_i(prdataX),
	.pslverr_i(pslverrX),
	.write_to_rd_sfifo_i(master_ctrl[4]),
	.read_from_wd_sfifo_i(master_ctrl[3]),
	.dec_error_i(dec_error),
	.latch_resp_i(master_ctrl[2]),
	//	
	//req
	.sfifo_aw_empty_o(sfifo_aw_empty),
	.sfifo_ar_empty_o(sfifo_ar_empty),
	//data
	.sfifo_wd_almost_empty_o(sfifo_wd_almost_empty),
	.sfifo_rd_almost_full_o(sfifo_rd_almost_full),
	//
  .write_burst_addr_o(write_burst_addr),
  .write_burst_len_o(write_burst_len),
  .write_burst_size_o(write_burst_size),
  .write_burst_name_o(write_burst_name),
  .write_burst_prot_o(write_burst_prot),
	//	
  .read_burst_addr_o(read_burst_addr),
  .read_burst_len_o(read_burst_len),
  .read_burst_size_o(read_burst_size),
  .read_burst_name_o(read_burst_name),
  .read_burst_prot_o(read_burst_prot),
//WDATA 
  .wdata_to_apb_o(wdata_to_apb),
  .wstrb_to_apb_o(wstrb_to_apb)
   //
   //
);
//
//ARBITER 
//
arbiter arbiter_inst(
	.aclk(aclk),
	.aresetn(aresetn),
	.pclk(pclk),
	.preset_n(preset_n),
	//available status of axi request
	.sfifo_ar_empty_i(sfifo_ar_empty),
	.sfifo_aw_empty_i(sfifo_aw_empty),
	//available status of axi data
	.sfifo_rd_almost_full_i(sfifo_rd_almost_full),
	.sfifo_wd_almost_empty_i(sfifo_wd_almost_empty),
	//axi request info
	//write	
  .write_burst_addr_i(write_burst_addr),
  .write_burst_len_i(write_burst_len),
  .write_burst_size_i(write_burst_size),
  .write_burst_name_i(write_burst_name),
  .write_burst_prot_i(write_burst_prot),
	//read	
  .read_burst_addr_i(read_burst_addr),
  .read_burst_len_i(read_burst_len),
  .read_burst_size_i(read_burst_size),
  .read_burst_name_i(read_burst_name),
  .read_burst_prot_i(read_burst_prot),
  	//
	.addr_incr_en_i(master_ctrl[0]),
  	//signals of burst completion
	.burst_almost_done_i(burst_almost_done),
	.burst_done_i(burst_done),
	//
	//
	.transfer_addr_o(transfer_addr),
	.selected_addr_o(selected_addr),
	.selected_len_o(selected_len),
	.selected_size_o(selected_size),
	.selected_burst_o(selected_burst),
	.selected_prot_o(selected_prot),
	.next_transfer_rdy_o(transfer),
	.wr_trans_done_o(wr_trans_done),
	.rd_trans_done_o(rd_trans_done),
	.write_enable_o(write_enable)
	//
);
//
//COUNTER
//
counter cnt_inst(
	.pclk(pclk),
	.preset_n(preset_n),
	.len_of_burst_i(selected_len),
	.set_up_phase_i(master_ctrl[1]),
	.beat_cnt_incr_i(master_ctrl[0]),
	//
	.burst_almost_done_o(burst_almost_done),
	.burst_done_o(burst_done)
	//
);
//
//DECODER
//
decoder decoder_inst(
	.start_addr_i(selected_addr),
	.size_of_transfer_i(selected_size),
	.burst_type_i(selected_burst),
	//
 	.dec_error_o(dec_error),
	.nonexist_transfer_o(nonexist_transfer),
	.true_psel_o(true_psel)
	//
);
//
//APB MASTER 
//
apb_master apb_mst_inst(
	.pclk(pclk),
	.preset_n(preset_n),
	//
	//control signal
	//
	.transfer_i(transfer),
	.enable_i(true_psel), //psel_in
	.nonexist_transfer_i(nonexist_transfer),
	.addr_i(transfer_addr),
	.prot_i(selected_prot),
	.grant_to_write_i(write_enable),
	.wstrb_to_apb_i(wstrb_to_apb),	
	.wdata_to_apb_i(wdata_to_apb),	
	//APB interface
	.paddr(paddr),
	.pprot(pprot),
	.psel(psel),
	.penable(penable),
	.pwrite(pwrite),
	.pwdata(pwdata),
	.pstrb(pstrb),
	.pready(pready),
	.prdata(prdata),
	.pslverr(pslverr),
//send to AXI transaction controller
	.prdataX_o(prdataX),
	.pslverrX_o(pslverrX),
	.master_ctrl_o(master_ctrl)
//psel for error case
	//
	//

);
//
//
//
endmodule: x2p_top

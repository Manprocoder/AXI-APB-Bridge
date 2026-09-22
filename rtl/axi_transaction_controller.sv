//===================================================================================
//--Project  : Design and Verify AXI_APB baxi_if.ridge 
//===================================================================================
//--File name: x2p_core.sv
//--Author: Nguyen Ngoc Man
//===================================================================================
//--Description : axi_slave sub module 
//+ This module communicates to AXI master
//===================================================================================
module axi_transaction_controller (// AXI protocol
    axi_if,
    //axi_if.aclk,
    //axi_if.aresetn,
//// Address write channel
	//axi_if.awvalid,
	//axi_if.awready,
	//axi_if.awaddr,
	//axi_if.awsize,
	//axi_if.awlen,
	//axi_if.awburst,
	//axi_if.awid,
	//axi_if.awprot,
	//// Address read channel
	//axi_if.rvalid,
	//axi_if.rready,
	//axi_if.araddr,
	//axi_if.arsize,
	//axi_if.arlen,
	//axi_if.arburst,
	//axi_if.rid,
	//axi_if.arprot,
	//// Write data channel
	//wvalid,
	//wready,
	//wdata,
	//wstrb,
	//wlast,
	//// Read data channel
	//axi_if.rvalid,
	//axi_if.rready,
	//axi_if.rlast,
	//axi_if.rresp,
	//axi_if.rid,
	//rdata,
	//// Write respond channel
	//bvalid,
	//bready,
	//bresp,
	//bid,
	//axi_if.arbiter input
	rd_trans_done_i,
	wr_trans_done_i,
	//apb master input
	prdata_i,
	err_of_transfer_i,
	write_to_rd_sfifo_i,
	read_from_wd_sfifo_i,
	dec_error_i,
	partly_brsp_vld_i,
	final_brsp_vld_i,
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
	  bchannel_rdy_o,
	  wdata_to_apb_o,
	  wstrb_to_apb_o
	  //
);
  //iclude parameter file
  import parameter_pkg::*; 
  //******************************************************
  //ports declaration
  //******************************************************
  //input logic                     axi_if.aclk;
  //input logic                     axi_if.aresetn;
  //// Address write channel
  //input  logic                    axi_if.awvalid;
  //input  logic [31:0]             axi_if.awaddr;
  //input  logic [2:0]              axi_if.awsize;
  //input  logic [7:0]              axi_if.awlen;
  //input  logic [1:0]              axi_if.awburst;
  //input  logic [7:0]              axi_if.awid;
  //input  logic [2:0]              axi_if.awprot;
  //output logic                    axi_if.awready;
  //// address read channel
  //input  logic                    axi_if.rvalid;
  //input  logic [31:0]             axi_if.araddr;
  //input  logic [2:0]              axi_if.arsize;
  //input  logic [7:0]              axi_if.arlen;
  //input  logic [1:0]              axi_if.arburst;
  //input  logic [7:0]              axi_if.rid;
  //input  logic [2:0]              axi_if.arprot;
  //output logic                    axi_if.rready;
  ////write data channel
  //input  logic                    wvalid;
  //input  logic [31:0]             wdata;
  //input  logic [3:0]              wstrb;
  //input  logic                    wlast;
  //output logic                    wready;
  ////read data channel
  //input  logic                    axi_if.rready;
  //output logic                    axi_if.rvalid;
  //output logic [1:0]              axi_if.rresp;
  //output logic                    axi_if.rlast;
  //output logic [7:0]              axi_if.rid;
  //output logic [31:0]             rdata;
  ////write respond channel
  //input  logic                    bready;
  //output logic                    bvalid;
  //output logic [1:0]              bresp;
  //output logic [7:0]              bid;
axi_intf axi_if;
//axi_if.arbiter inputs
input logic rd_trans_done_i;
input logic wr_trans_done_i;
input logic [31:0] prdata_i;
input logic err_of_transfer_i;
input logic write_to_rd_sfifo_i;
input logic read_from_wd_sfifo_i;
input logic dec_error_i;
input logic partly_brsp_vld_i;
input logic final_brsp_vld_i;
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
output logic 	    bchannel_rdy_o;
output logic [31:0] wdata_to_apb_o;
output logic [3:0] wstrb_to_apb_o;
  //******************************************************
  //internal signals
  //******************************************************
  //SFIFO_AW
  logic       sfifo_aw_full;
  logic       sfifo_aw_we;
  logic       sfifo_aw_re;
  logic [7:0] sfifo_aw_id;
  //SFIFO_AR
  logic sfifo_ar_full;
  logic sfifo_ar_we;
  logic sfifo_ar_re;
  logic [7:0] sfifo_ar_id;
  //SFIFO_WD
  logic sfifo_wd_full;
  logic sfifo_wd_we;
  logic sfifo_wd_re;
  //SFIFO_RD
  logic sfifo_rd_empty;
  logic sfifo_rd_we;
  logic sfifo_rd_re;
  //RD_CH
  logic[1:0] resp_of_rdata;
  logic   rdata_last;
//bchannel_sfifo
  logic sfifo_brsp_we;
  logic sfifo_brsp_re;
  logic sfifo_brsp_empty;
  logic sfifo_brsp_full;
  //WRITE RESPONSE
  logic wdata_last;
  logic status;
  logic [1:0] bresp_reg;
  logic [7:0] bid_reg;
  logic new_brsp_vld;
  //
  parameter logic [DATA_POINTER_WIDTH:0] ALMOST_FULL_VALUE = 2**DATA_POINTER_WIDTH - 1'b1;
  parameter logic [DATA_POINTER_WIDTH:0] ALMOST_EMPTY_VALUE = 1;
//*******************************************************************
//X2P_SFIFO_AR
//*******************************************************************
  sfiforeq #(
        .DATA_WIDTH(X2P_SFIFO_AR_DATA_WIDTH),
       	.POINTER_WIDTH(REQ_POINTER_WIDTH)
  ) ar_sfifo (
  .clk(axi_if.aclk),
  .rst_n(axi_if.aresetn),
  .wr(sfifo_ar_we),
  .rd(sfifo_ar_re),
  .data_in({axi_if.araddr[31:0], axi_if.arid[7:0], axi_if.arlen[7:0], axi_if.arsize[2:0], axi_if.arburst[1:0], axi_if.arprot[2:0]}),
  .sfifo_empty(sfifo_ar_empty_o),
  .sfifo_full(sfifo_ar_full),
  .data_out({read_burst_addr_o[31:0], sfifo_ar_id[7:0], read_burst_len_o[7:0], 
	  read_burst_size_o[2:0], read_burst_name_o[1:0], read_burst_prot_o[2:0]})
  //
  );
  //Logic
  assign axi_if.arready  = ~sfifo_ar_full;
  assign sfifo_ar_we 	= axi_if.arready & axi_if.arvalid;
  assign sfifo_ar_re 	= rd_trans_done_i;
  //*******************************************************************
  //X2P_SFIFO_RD
  //*******************************************************************
  sfifordata #(
	.DATA_WIDTH(X2P_SFIFO_RD_DATA_WIDTH), .POINTER_WIDTH(DATA_POINTER_WIDTH),
	.ALMOST_FULL_VALUE(ALMOST_FULL_VALUE), .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE)
) rd_sfifo(
  .clk(axi_if.aclk),
  .rst_n(axi_if.aresetn),
  .wr(sfifo_rd_we),
  .rd(sfifo_rd_re),
  .data_in({rd_trans_done_i, resp_of_rdata[1:0], sfifo_ar_id[7:0], prdata_i[31:0]}),
  .sfifo_empty(sfifo_rd_empty),
  .sfifo_almost_full(sfifo_rd_almost_full_o),
  .data_out({axi_if.rlast, axi_if.rresp[1:0], axi_if.rid[7:0], axi_if.rdata[31:0]})
  //.data_out({rdata_last, axi_if.rresp[1:0], axi_if.rid[7:0], axi_if.rdata[31:0]})
  );
  //Logic
  assign axi_if.rvalid      = ~sfifo_rd_empty;
  assign sfifo_rd_re = axi_if.rvalid & axi_if.rready;
  assign sfifo_rd_we = write_to_rd_sfifo_i;
  //RD_CH
  //resp_of_rdata
  always_comb begin
    if(~err_of_transfer_i) begin
	  resp_of_rdata = OKAY;
    end
	else if(dec_error_i) begin
	  resp_of_rdata = DECERR;
    end
	else begin
	  resp_of_rdata = PSLVERR;
    end
  end
  //axi_if.rlast
  //always_comb begin
	//if(axi_if.rvalid & rdata_last) begin
	  //axi_if.rlast = 1'b1;
    //end
	//else begin
	  //axi_if.rlast = 1'b0;	
    //end
  //end
  //*******************************************************************
  //X2P_SFIFO_AW
  //*******************************************************************
  sfiforeq #(
	  .DATA_WIDTH(X2P_SFIFO_AW_DATA_WIDTH),
	  .POINTER_WIDTH(REQ_POINTER_WIDTH)
) aw_sfifo(
  .clk(axi_if.aclk),
  .rst_n(axi_if.aresetn),
  .wr(sfifo_aw_we),
  .rd(sfifo_aw_re),
  .data_in({axi_if.awaddr[31:0], axi_if.awid[7:0], axi_if.awlen[7:0], axi_if.awsize[2:0], axi_if.awburst[1:0], axi_if.awprot[2:0]}),
  .sfifo_empty(sfifo_aw_empty_o),
  .sfifo_full(sfifo_aw_full),
  .data_out({write_burst_addr_o[31:0], sfifo_aw_id[7:0], write_burst_len_o[7:0], 
	  write_burst_size_o[2:0], write_burst_name_o[1:0], write_burst_prot_o[2:0]})
  );
  //Logic
  assign axi_if.awready 	= ~sfifo_aw_full;
  assign sfifo_aw_we    = axi_if.awready & axi_if.awvalid;
  assign sfifo_aw_re    = wr_trans_done_i;
  //*******************************************************************
  //X2P_SFIFO_WD
  //*******************************************************************
  sfifowdata #(
	.DATA_WIDTH(X2P_SFIFO_WD_DATA_WIDTH), .POINTER_WIDTH(DATA_POINTER_WIDTH),
	.ALMOST_FULL_VALUE(ALMOST_FULL_VALUE), .ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE)
  ) wd_sfifo(
  .clk(axi_if.aclk),
  .rst_n(axi_if.aresetn),
  .wr(sfifo_wd_we),
  .rd(sfifo_wd_re),
  .data_in({axi_if.wlast, axi_if.wstrb[3:0], axi_if.wdata[31:0]}),
  .sfifo_almost_empty(sfifo_wd_almost_empty_o),
  .sfifo_full(sfifo_wd_full),
  .data_out({wdata_last, wstrb_to_apb_o[3:0], wdata_to_apb_o[31:0]})
  );
//
assign axi_if.wready      = ~sfifo_wd_full;
assign sfifo_wd_we = axi_if.wvalid & axi_if.wready;
assign sfifo_wd_re = read_from_wd_sfifo_i;
//
//B CHANNEL
//
//*******************************************************************
//X2P_SFIFO_BRSP
//*******************************************************************
  sfifobresp #(
	.DATA_WIDTH(X2P_SFIFO_BCHANNEL_WIDTH), 
	.POINTER_WIDTH(REQ_POINTER_WIDTH),
	.ALMOST_FULL_VALUE(ALMOST_FULL_VALUE), 
	.ALMOST_EMPTY_VALUE(ALMOST_EMPTY_VALUE)
  ) bchannel_sfifo(
  .clk(axi_if.aclk),
  .rst_n(axi_if.aresetn),
  .wr(sfifo_brsp_we),
  .rd(sfifo_brsp_re),
  .data_in({bresp_reg[1:0], bid_reg[7:0]}),
  .sfifo_empty(sfifo_brsp_empty),
  .sfifo_full(sfifo_brsp_full),
  .data_out({axi_if.bresp[1:0], axi_if.bid[7:0]})
  );
  //
assign axi_if.bvalid = ~sfifo_brsp_empty;
assign sfifo_brsp_re = axi_if.bvalid & axi_if.bready;
assign sfifo_brsp_we = new_brsp_vld;
assign bchannel_rdy_o = ~sfifo_brsp_full; 
//
//bresp register
//
always_ff@(posedge axi_if.aclk, negedge axi_if.aresetn) begin
  if(~axi_if.aresetn) begin
      status <= 1'b0;
  end
  else if(final_brsp_vld_i) begin
      status <= 1'b0; //wr_trans_done_i
  end
  else if(partly_brsp_vld_i) begin
      status <= (status | err_of_transfer_i);
  end
end
//
//INFO
//
always_ff @(posedge axi_if.aclk, negedge axi_if.aresetn) begin
	if(~axi_if.aresetn) begin
	  bresp_reg[1:0] <= OKAY;
	  bid_reg[7:0] <= 8'd0;
	  new_brsp_vld <= 1'b0;
  	end
	else if(final_brsp_vld_i) begin
	  	  bid_reg[7:0] <= sfifo_aw_id[7:0];
		  new_brsp_vld <= 1'b1;
		  if(dec_error_i) begin
		    bresp_reg[1:0] <= DECERR;
          end
		  else if(~status) begin
		    bresp_reg[1:0] <= OKAY | {err_of_transfer_i, 1'b0};
          end
		  else begin
		    bresp_reg[1:0] <= PSLVERR;
          end
	end
	else if(bchannel_rdy_o)begin
	  bresp_reg[1:0] <= OKAY;
	  bid_reg[7:0] <= 8'd0;
	  new_brsp_vld <= 1'b0;
	end
end
//
endmodule: axi_transaction_controller 

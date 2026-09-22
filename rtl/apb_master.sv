//========================================================
//--Project: Design and Verify AXI_APB bridge
//========================================================
//--File name: apb_master.sv
//--Author: Nguyen Ngoc Man
//========================================================
//--Description: 
//========================================================
//
`define PSEL_REGISTER
//
module apb_master(
	//apb_if.pclk,
	//apb_if.presetn,
    apb_if,
	//
	//control signal
	//
	transfer_i,
	enable_i,
	disallowed_trans_i,
	addr_i,
	prot_i,
	grant_to_write_i,
	wstrb_to_apb_i,	
	wdata_to_apb_i,	
	////APB interface
	//apb_if.paddr,
	//apb_if.pprot,
	//apb_if.psel,
	//apb_if.penable,
	//apb_if.pwrite,
	//apb_if.pwdata,
	//apb_if.pstrb,
	//apb_if.pready,
	//apb_if.prdata,
	//apb_if.pslverr,
//send to AXI transaction controller
	prdataX_o,
	pslverrX_o,
	master_ctrl_o
	//
	//
);
//*********************************************************
//PORTS
//*********************************************************
//input logic                    apb_if.pclk;
//input logic                    apb_if.presetn;
apb_intf apb_if;
//
input logic 			transfer_i;
input logic [`SLAVE_CNT-1:0]    enable_i;
input logic 			disallowed_trans_i;
input logic [31:0]		addr_i;
input logic [2:0]		prot_i;
input logic 			grant_to_write_i;
input logic [3:0]		wstrb_to_apb_i;
input logic [31:0]		wdata_to_apb_i;	
//
//output logic [31:0]             apb_if.paddr;
//output logic [2:0]              apb_if.pprot;
//output logic [`SLAVE_CNT-1:0]   apb_if.psel;
//output logic                    apb_if.penable;
//output logic                    apb_if.pwrite;
//output logic [31:0]             apb_if.pwdata;
//output logic [3:0]              apb_if.pstrb;
//input  logic [`SLAVE_CNT-1:0][31:0] apb_if.prdata;
//input  logic [`SLAVE_CNT-1:0]   apb_if.pready;
//input  logic [`SLAVE_CNT-1:0]   apb_if.pslverr;
//send to AXI transaction controller
output logic [31:0] prdataX_o;
output logic pslverrX_o;
output logic [4:0] master_ctrl_o;
//*********************************************************
//INTERNAL VARIABLES
//*********************************************************
//APB state machine
typedef enum logic [1:0] {P_IDLE, SETUP, ACCESS} apb_st;
apb_st apb_cs, apb_ns;
//
logic [`SLAVE_CNT-1:0] out_pready;
logic [`SLAVE_CNT-1:0] out_pslverr;
logic [`SLAVE_CNT-1:0][31:0] out_prdata;
logic [`SLAVE_CNT-1:0] preadyX;
logic invalid_psel;
logic store_rdata, fetch_wdata, latch_resp, set_up_phase, addr_incr_en;
//
assign master_ctrl_o = {store_rdata, fetch_wdata, latch_resp, set_up_phase, addr_incr_en};
//
  `ifdef PSEL_REGISTER
	  logic [`SLAVE_CNT-1:0] true_psel_reg;
	  logic false_psel_reg;
	  //
	  always_ff@(posedge apb_if.pclk, negedge apb_if.presetn) begin
		  if(~apb_if.presetn) begin
			  true_psel_reg <= {`SLAVE_CNT{1'b0}};
			  false_psel_reg <= 1'b0;
		  end
		  else begin
			  true_psel_reg <= enable_i;
			  false_psel_reg <= (|enable_i) ? 1'b0 : 1'b1;
		  end
	  end
  `endif
  //
  //APB state regs
  //
  always_ff @(posedge apb_if.pclk, negedge apb_if.presetn) begin
    if(~apb_if.presetn)
	  apb_cs[1:0] <= P_IDLE;
	else
	  apb_cs[1:0] <= apb_ns[1:0];
  end
//
//
//
  always_comb begin
	apb_ns = apb_cs;
	apb_if.pprot = 0;
	apb_if.psel = 0;
	invalid_psel = 0;
	apb_if.penable = 0;
	apb_if.paddr = 0;
	apb_if.pwrite = 0;
	apb_if.pwdata = 0;
	apb_if.pstrb = 0;
	store_rdata = 0;
	fetch_wdata = 0;
	latch_resp = 0;
	set_up_phase = 0;
	addr_incr_en = 0;
	//apb_if.prev_burst = 1'b0;
	//
    case(apb_cs[1:0])
		P_IDLE: begin
			if(transfer_i) begin
				//if(apb_if.prev_burst) addr_incr_en = 1'b1;
				//else addr_incr_en = 1'b0;
				//
				apb_ns[1:0] = SETUP;
			end
			else begin
				//addr_incr_en = 1'b0;
				apb_ns[1:0] = P_IDLE;
			end
		end
		SETUP: begin
			apb_ns[1:0] = ACCESS;
			`ifdef PSEL_REGISTER
			apb_if.psel = true_psel_reg;
			invalid_psel = false_psel_reg;
			`elsif
			apb_if.psel = enable_i;
			invalid_psel = (|enable_i) ? 1'b0 : 1'b1;
			`endif
			apb_if.penable = 1'b0;
			apb_if.pprot[2:0] = prot_i;
			apb_if.paddr = addr_i;
			apb_if.pwrite = (grant_to_write_i) ? 1'b1: 1'b0;
			apb_if.pwdata = (grant_to_write_i) ? wdata_to_apb_i[31:0] : 32'd0;
		    apb_if.pstrb[3:0] = (grant_to_write_i) ? wstrb_to_apb_i[3:0] : 4'h0;
		    //
			store_rdata = 0;
			fetch_wdata = 0;
			latch_resp = 0;
            set_up_phase = 1'b1;
			addr_incr_en = 0;
		end
		ACCESS: begin
			if(preadyX) begin
				//
				latch_resp = (grant_to_write_i) ? 1'b1 : 1'b0;
				store_rdata = (grant_to_write_i) ? 1'b0 : 1'b1;
				fetch_wdata = (grant_to_write_i) ? 1'b1 : 1'b0;
				addr_incr_en = 1'b1;
				//
				if(transfer_i) begin
					apb_ns[1:0] = SETUP;
				end
				else begin
					apb_ns[1:0] = P_IDLE;
				end
			end //end of apb_if.preadyX
			else begin
				apb_ns[1:0] = ACCESS;
			end
			`ifdef PSEL_REGISTER
			apb_if.psel = true_psel_reg;
			invalid_psel = false_psel_reg;
			`elsif
			apb_if.psel = enable_i;
			invalid_psel = (|enable_i) ? 1'b0 : 1'b1;
			`endif
			apb_if.penable = 1'b1;
			apb_if.pprot[2:0] = prot_i;
			apb_if.paddr = addr_i;
			apb_if.pwrite = (grant_to_write_i) ? 1'b1: 1'b0;
			apb_if.pwdata = (grant_to_write_i) ? wdata_to_apb_i[31:0] : 32'd0;
		    apb_if.pstrb[3:0] = (grant_to_write_i) ? wstrb_to_apb_i[3:0] : 4'h0;
			//
		end
		default: begin
			apb_ns[1:0] = P_IDLE;
			apb_if.pprot = 0;
			apb_if.psel = 0;
			invalid_psel = 0;
			apb_if.penable = 0;
			apb_if.paddr = 0;
			apb_if.pwrite = 0;
			apb_if.pwdata = 0;
			apb_if.pstrb = 0;
			store_rdata = 0;
			fetch_wdata = 0;
			latch_resp = 0;
			set_up_phase = 0;
			addr_incr_en = 0;
			//prev_burst = 1'b0;
		end
	endcase
end
//pslverrX, preadyX
  assign preadyX  = |out_pready[`SLAVE_CNT-1:0] | invalid_psel | disallowed_trans_i; 
  assign pslverrX_o = |out_pslverr[`SLAVE_CNT-1:0] | disallowed_trans_i;// invalid_psel | disallowed_trans_i; 
  generate
    genvar i;
	for (i = 0; i <= `SLAVE_CNT-1; i = i + 1) begin: decPreadyAndPslverr
	  assign out_pready[i]  = apb_if.psel[i] & apb_if.pready[i];
	  assign out_pslverr[i] = apb_if.psel[i] & apb_if.pslverr[i];
	end
  endgenerate
  //apb_if.prdataX
  assign prdataX_o = out_prdata[`SLAVE_CNT-1];
  assign out_prdata[0] = apb_if.psel[0] ? apb_if.prdata[0] : 32'd0;
  //
  generate
    genvar j;
	for(j = 1; j <= `SLAVE_CNT-1; j = j + 1) begin: decPrdata
	  assign out_prdata[j] = apb_if.psel[j] ? apb_if.prdata[j] : out_prdata[j-1];
	end
  endgenerate
//
//
endmodule

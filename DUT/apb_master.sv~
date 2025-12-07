//
//
`define PSEL_REGISTER
//
module apb_master(
	pclk,
	preset_n,
	//
	//control signal
	//
	transfer_i,
	enable_i,
	nonexist_transfer_i,
	addr_i,
	prot_i,
	grant_to_write_i,
	wstrb_to_apb_i,	
	wdata_to_apb_i,	
	//APB interface
	paddr,
	pprot,
	psel,
	penable,
	pwrite,
	pwdata,
	pstrb,
	pready,
	prdata,
	pslverr,
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
input logic                    pclk;
input logic                    preset_n;
//
input logic 			transfer_i;
input logic [`SLAVE_CNT-1:0]    enable_i;
input logic 			nonexist_transfer_i;
input logic [31:0]		addr_i;
input logic [2:0]		prot_i;
input logic 			grant_to_write_i;
input logic [3:0]		wstrb_to_apb_i;
input logic [31:0]		wdata_to_apb_i;	
//
output logic [31:0]             paddr;
output logic [2:0]              pprot;
output logic [`SLAVE_CNT-1:0]   psel;
output logic                    penable;
output logic                    pwrite;
output logic [31:0]             pwdata;
output logic [3:0]              pstrb;
input  logic [`SLAVE_CNT-1:0][31:0] prdata;
input  logic [`SLAVE_CNT-1:0]   pready;
input  logic [`SLAVE_CNT-1:0]   pslverr;
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
//
assign master_ctrl_o = {store_rdata, fetch_wdata, latch_resp, set_up_phase, addr_incr_en};
//
  `ifdef PSEL_REGISTER
	  logic [`SLAVE_CNT-1:0] true_psel_reg;
	  logic false_psel_reg;
	  //
	  always_ff@(posedge pclk, negedge preset_n) begin
		  if(~preset_n) begin
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
  always_ff @(posedge pclk, negedge preset_n) begin
    if(~preset_n)
	  apb_cs[1:0] <= P_IDLE;
	else
	  apb_cs[1:0] <= apb_ns[1:0];
  end
//
//
//
  always_comb begin
	apb_ns = apb_cs;
	pprot = 0;
	psel = 0;
	invalid_psel = 0;
	penable = 0;
	paddr = 0;
	pwrite = 0;
	pwdata = 0;
	pstrb = 0;
	store_rdata = 0;
	fetch_wdata = 0;
	latch_resp = 0;
	set_up_phase = 0;
	addr_incr_en = 0;
	//
    case(apb_cs[1:0])
		P_IDLE: begin
			if(transfer_i) begin
				apb_ns[1:0] = SETUP;
				fetch_wdata = (grant_to_write_i) ? 1'b1 : 1'b0;
			end
			else
			apb_ns[1:0] = P_IDLE;
		end
		SETUP: begin
			apb_ns[1:0] = ACCESS;
			`ifdef PSEL_REGISTER
			psel = true_psel_reg;
			invalid_psel = false_psel_reg;
			`elsif
			psel = enable_i;
			invalid_psel = (|enable_i) ? 1'b0 : 1'b1;
			`endif
			penable = 1'b0;
			pprot[2:0] = prot_i;
			paddr = addr_i;
			pwrite = (grant_to_write_i) ? 1'b1: 1'b0;
			pwdata = (grant_to_write_i) ? wdata_to_apb_i[31:0] : 32'd0;
		    pstrb[3:0] = (grant_to_write_i) ? wstrb_to_apb_i[3:0] : 4'h0;
		        set_up_phase = 1'b1;
		end
		ACCESS: begin
			if(preadyX) begin
				//
				latch_resp = 1'b1;
				addr_incr_en = 1'b1;
				store_rdata = (grant_to_write_i) ? 1'b0 : 1'b1;
				//
				if(transfer_i) begin
					apb_ns[1:0] = SETUP;
					fetch_wdata = (grant_to_write_i) ? 1'b1 : 1'b0;
				end
				else begin
					apb_ns[1:0] = P_IDLE;
				end
			end //end of preadyX
			else begin
				apb_ns[1:0] = ACCESS;
			end
			`ifdef PSEL_REGISTER
			psel = true_psel_reg;
			invalid_psel = false_psel_reg;
			`elsif
			psel = enable_i;
			invalid_psel = (|enable_i) ? 1'b0 : 1'b1;
			`endif
			penable = 1'b1;
			pprot[2:0] = prot_i;
			paddr = addr_i;
			pwrite = (grant_to_write_i) ? 1'b1: 1'b0;
			pwdata = (grant_to_write_i) ? wdata_to_apb_i[31:0] : 32'd0;
		    pstrb[3:0] = (grant_to_write_i) ? wstrb_to_apb_i[3:0] : 4'h0;
			//
		end
		default: begin
			apb_ns[1:0] = P_IDLE;
			pprot = 0;
			psel = 0;
			invalid_psel = 0;
			penable = 0;
			paddr = 0;
			pwrite = 0;
			pwdata = 0;
			pstrb = 0;
			store_rdata = 0;
			fetch_wdata = 0;
			latch_resp = 0;
			set_up_phase = 0;
			addr_incr_en = 0;
		end
	endcase
end
//pslverrX, preadyX
  assign preadyX  = |out_pready[`SLAVE_CNT-1:0] | invalid_psel | nonexist_transfer_i; 
  assign pslverrX_o = |out_pslverr[`SLAVE_CNT-1:0]| invalid_psel | nonexist_transfer_i; 
  generate
    genvar i;
	for (i = 0; i <= `SLAVE_CNT-1; i = i + 1) begin: decPreadyAndPslverr
	  assign out_pready[i]  = psel[i] & pready[i];
	  assign out_pslverr[i] = psel[i] & pslverr[i];
	end
  endgenerate
  //prdataX
  assign prdataX_o = out_prdata[`SLAVE_CNT-1];
  assign out_prdata[0] = psel[0] ? prdata[0] : 32'd0;
  //
  generate
    genvar j;
	for(j = 1; j <= `SLAVE_CNT-1; j = j + 1) begin: decPrdata
	  assign out_prdata[j] = psel[j] ? prdata[j] : out_prdata[j-1];
	end
  endgenerate
//
//
endmodule

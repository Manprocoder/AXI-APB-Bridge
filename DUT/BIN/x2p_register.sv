//======================================================
//File name: x2p_register.sv
//Function : store base and end address of all APB slaves 
//=======================================================
module x2p_register(pclk,
                    preset_n,
					psel,
					penable,
					paddr,
					pwrite,
					pwdata,
					pstrb,
					pslverr,
					pprot,
					prdata
);
  //port declaration
  input  logic        pclk;
  input  logic        preset_n;
  input  logic        psel;
  input  logic        penable;
  input  logic [31:0] paddr;
  input  logic       pwrite;
  input  logic [31:0] pwdata;
  input  logic [3:0]  pstrb;
  output logic        pslverr;
  input  logic [2:0]  pprot;
  output logic [31:0] prdata;
  //signal declaration
  logic [31:0]        x2pRegPrdata;
  logic               errorCondition;
//X2P_REGISTER
  import parameter_pkg::*; //`include "x2p_parameter.h"
  //prdata
  always_ff @(posedge pclk, negedge preset_n) begin:prdata_reg_block
    if(~preset_n)
	  prdata[31:0] <= 32'd0;
	else if(psel & ~penable)
	  prdata[31:0] <= x2pRegPrdata[31:0];	  
  end
  //prdata  
  always_comb begin
    if(`SLAVE_CNT == 1) begin: REG0
	  case(paddr[7:0])
		8'h00: x2pRegPrdata[31:0] = A_START_SLAVE0;
		8'h04: x2pRegPrdata[31:0] = A_END_SLAVE0;
		default: x2pRegPrdata[31:0] = 32'hFFFF_E000;
	  endcase
	end
	else if(`SLAVE_CNT == 2) begin: REG1
	  case(paddr[7:0])
		8'h00: x2pRegPrdata[31:0] = A_START_SLAVE0;
		8'h04: x2pRegPrdata[31:0] = A_END_SLAVE0;
		8'h08: x2pRegPrdata[31:0] = A_START_SLAVE1;
		8'h0C: x2pRegPrdata[31:0] = A_END_SLAVE1;
		default: x2pRegPrdata[31:0] = 32'hFFFF_E000;
	  endcase
	end
	else if(`SLAVE_CNT == 3) begin: REG2
	  case(paddr[7:0])
		8'h00: x2pRegPrdata[31:0] = A_START_SLAVE0;
		8'h04: x2pRegPrdata[31:0] = A_END_SLAVE0;
		8'h08: x2pRegPrdata[31:0] = A_START_SLAVE1;
		8'h0C: x2pRegPrdata[31:0] = A_END_SLAVE1;
		8'h10: x2pRegPrdata[31:0] = A_START_SLAVE2;
		8'h14: x2pRegPrdata[31:0] = A_END_SLAVE2;
		default: x2pRegPrdata[31:0] = 32'hFFFF_E000;
      endcase
	end	
	else if(`SLAVE_CNT == 4) begin: REG3
	    case(paddr[7:0])
          8'h00: x2pRegPrdata[31:0] = A_START_SLAVE0;
		  8'h04: x2pRegPrdata[31:0] = A_END_SLAVE0;
		  8'h08: x2pRegPrdata[31:0] = A_START_SLAVE1;
		  8'h0C: x2pRegPrdata[31:0] = A_END_SLAVE1;
		  8'h10: x2pRegPrdata[31:0] = A_START_SLAVE2;
		  8'h14: x2pRegPrdata[31:0] = A_END_SLAVE2;
		  8'h18: x2pRegPrdata[31:0] = A_START_SLAVE3;
		  8'h1C: x2pRegPrdata[31:0] = A_END_SLAVE3;
		  default: x2pRegPrdata[31:0] = 32'hFFFF_E000;
		endcase
	end
	else
	  x2pRegPrdata[31:0] = 32'hFFFF_E000;
  end 
  //pslverr
  always_ff @(posedge pclk, negedge preset_n) begin:pslverr_reg_block
    if(~preset_n)
	  pslverr <= 1'b0;
	else if(psel & ~penable) begin
	  if(errorCondition)
	    pslverr <= 1'b1;
      else
	    pslverr <= 1'b0;
	end
	else pslverr <= 1'b0;
  end
  //
  generate
    if(`SLAVE_CNT == 1)
	  assign errorCondition = (psel & pwrite) | (paddr[1:0] != 2'b00) | (paddr[31:0] > 32'h0000_0004);
	else if(`SLAVE_CNT == 2)
	  assign errorCondition = (psel & pwrite) | (paddr[1:0] != 2'b00) | (paddr[31:0] > 32'h0000_000C);
    else if(`SLAVE_CNT == 3)
	  assign errorCondition = (psel & pwrite) | (paddr[1:0] != 2'b00) | (paddr[31:0] > 32'h0000_0014);
	else if(`SLAVE_CNT == 4)
	  assign errorCondition = (psel & pwrite) | (paddr[1:0] != 2'b00) | (paddr[31:0] > 32'h0000_001C);
    
  endgenerate
endmodule: x2p_register

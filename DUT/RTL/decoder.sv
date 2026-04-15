//
//
//
module decoder(
	start_addr_i,
	disallowed_trans_i,
 	dec_error_o,
	true_psel_o
	//
);
//iclude parameter file
import parameter_pkg::*; 
//PORTS
input logic [31:0] start_addr_i;
input logic disallowed_trans_i;
//input logic [2:0] size_of_transfer_i;
//
output logic dec_error_o;
//output logic disallowed_trans_i;
output logic [`SLAVE_CNT-1:0] true_psel_o;
//
//psel for APB slave 
//
generate
if(`SLAVE_CNT >= 1) 
  assign true_psel_o[0] = disallowed_trans_i ? 1'b0 : (start_addr_i[31:0] <= A_END_SLAVE0);
if(`SLAVE_CNT >= 2)
  assign true_psel_o[1] = disallowed_trans_i ? 1'b0 : ((start_addr_i[31:0] >= A_START_SLAVE1) & (start_addr_i[31:0] <= A_END_SLAVE1));
if(`SLAVE_CNT >= 3)
  assign true_psel_o[2] = disallowed_trans_i ? 1'b0 : ((start_addr_i[31:0] >= A_START_SLAVE2) & (start_addr_i[31:0] <= A_END_SLAVE2));
if(`SLAVE_CNT >= 4)
  assign true_psel_o[3] = disallowed_trans_i ? 1'b0 : ((start_addr_i[31:0] >= A_START_SLAVE3) & (start_addr_i[31:0] <= A_END_SLAVE3));
endgenerate
 //
 //
 //
generate
	if(`SLAVE_CNT == 1)
	  assign dec_error_o = (start_addr_i[31:0] > A_END_SLAVE0);
	else if(`SLAVE_CNT == 2)
	  assign dec_error_o = (start_addr_i[31:0] > A_END_SLAVE1);
	else if(`SLAVE_CNT == 3)
	  assign dec_error_o = (start_addr_i[31:0] > A_END_SLAVE2);
	else if(`SLAVE_CNT == 4)
	  assign dec_error_o = (start_addr_i[31:0] > A_END_SLAVE3);
endgenerate
  //
  //
endmodule

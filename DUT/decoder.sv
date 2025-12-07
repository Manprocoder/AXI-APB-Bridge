//
//
//
module decoder(
	start_addr_i,
	size_of_transfer_i,
	burst_type_i,
	//
	//
 	dec_error_o,
	nonexist_transfer_o,
	true_psel_o
	//
);
//iclude parameter file
import parameter_pkg::*; 
//PORTS
input logic [31:0] start_addr_i;
input logic [2:0] size_of_transfer_i;
input logic [1:0] burst_type_i;
//
output logic dec_error_o;
output logic nonexist_transfer_o;
output logic [`SLAVE_CNT-1:0] true_psel_o;
//
//output assigment
//
assign nonexist_transfer_o = (burst_type_i[1:0] == 2'b11) | (size_of_transfer_i != 3'd2); 
//
//psel for APB slave 
//
generate
if(`SLAVE_CNT >= 1) 
  assign true_psel_o[0] = nonexist_transfer_o ? 1'b0 : ((start_addr_i[31:0] >= A_START_SLAVE0) & (start_addr_i[31:0] <= A_END_SLAVE0));
if(`SLAVE_CNT >= 2)
  assign true_psel_o[1] = nonexist_transfer_o ? 1'b0 : ((start_addr_i[31:0] >= A_START_SLAVE1) & (start_addr_i[31:0] <= A_END_SLAVE1));
if(`SLAVE_CNT >= 3)
  assign true_psel_o[2] = nonexist_transfer_o ? 1'b0 : ((start_addr_i[31:0] >= A_START_SLAVE2) & (start_addr_i[31:0] <= A_END_SLAVE2));
if(`SLAVE_CNT >= 4)
  assign true_psel_o[3] = nonexist_transfer_o ? 1'b0 : ((start_addr_i[31:0] >= A_START_SLAVE3) & (start_addr_i[31:0] <= A_END_SLAVE3));
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

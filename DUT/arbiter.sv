//
//
//
  //overall operation mechanism
  //(R1) granting read --write waits -> grant write for next time
  //(R2) granting read --ONLY read waits OR no request -> ... read ...
  //(W1) granting write --read waits -> ... read ...
  //(W2) granting write--ONLY write waits OR no request -> ... write ...
module arbiter(
	aclk,
	aresetn,
	pclk,
	preset_n,
	sfifo_ar_empty_i,
	sfifo_aw_empty_i,
	sfifo_rd_almost_full_i,
	sfifo_wd_almost_empty_i,
	//AXI REQ INFO
	//WRITE
	  write_burst_addr_i,
	  write_burst_len_i,
	  write_burst_size_i,
	  write_burst_name_i,
	  write_burst_prot_i,
	//READ	
	  read_burst_addr_i,
	  read_burst_len_i,
	  read_burst_size_i,
	  read_burst_name_i,
	  read_burst_prot_i,
	//apb master input
	addr_incr_en_i,
	//counter input
	burst_almost_done_i,
	burst_done_i,
	//
	transfer_addr_o,
	selected_addr_o,
	selected_len_o,
	selected_size_o,
	selected_burst_o,
	selected_prot_o,
	next_transfer_rdy_o,
	wr_trans_done_o,
	rd_trans_done_o,
	write_enable_o
);

//iclude parameter file
import parameter_pkg::*; 
//*****************************************************************
//ports
//*****************************************************************
input logic aclk;
input logic aresetn;
input logic pclk;
input logic preset_n;
//req
input logic sfifo_ar_empty_i;
input logic sfifo_aw_empty_i;
//data
input logic sfifo_rd_almost_full_i;
input logic sfifo_wd_almost_empty_i;
	//AXI REQ INFO
	//WRITE
input logic [31:0] write_burst_addr_i;
input logic [7:0] write_burst_len_i;
input logic [2:0] write_burst_size_i;
input logic [1:0] write_burst_name_i;
input logic [2:0] write_burst_prot_i;
	//READ	
input logic [31:0] read_burst_addr_i;
input logic [7:0] read_burst_len_i;
input logic [2:0] read_burst_size_i;
input logic [1:0] read_burst_name_i;
input logic [2:0] read_burst_prot_i;
//apb master input
input logic addr_incr_en_i;
//counter input
input logic burst_almost_done_i;
input logic burst_done_i;
//
output logic [31:0] transfer_addr_o;
output logic [31:0] selected_addr_o;
output logic [7:0] selected_len_o;
output logic [2:0] selected_size_o;
output logic [1:0] selected_burst_o;
output logic [2:0] selected_prot_o;
output logic next_transfer_rdy_o;
output logic wr_trans_done_o;
output logic rd_trans_done_o;
output logic write_enable_o;
//*****************************************************************
//variables
//*****************************************************************
//ABT state machine
typedef enum logic [1:0] {A_IDLE, ABT_GO, ABT_DONE} abt_st;
  abt_st abt_cs, abt_ns;
  //
  logic [1:0] nextSel;
  logic [1:0] nextGrant;
  logic [1:0] current_grant;
  logic rd_req_avail, wr_req_avail;
  logic update;
  logic begin_transfer;
  logic burst_go;
  logic burst_en;
  logic new_req_rdy;
  logic [1:0] control;
  //addr variables
  logic addr_incr_active;
  logic [31:0] addr_reg;
  logic [31:0] next_addr_for_incr;
  logic [31:0] next_addr_for_wrap;
  logic [2:0] bit_num;
  logic [2:0] bit2Addr;
  logic [3:0] bit3Addr;
  logic [4:0] bit4Addr;
  logic [5:0] bit5Addr;
  //***************************************************
  //output assignment
  //***************************************************
assign transfer_addr_o = addr_reg;
assign next_transfer_rdy_o = burst_go ? (current_grant[0] ? ~sfifo_rd_almost_full_i : ~sfifo_wd_almost_empty_i) : 1'b0;
assign selected_prot_o = current_grant[0] ? read_burst_prot_i : write_burst_prot_i;
assign selected_addr_o = current_grant[0] ? read_burst_addr_i : write_burst_addr_i;
assign selected_len_o = current_grant[0] ? read_burst_len_i : write_burst_len_i;
assign selected_burst_o = current_grant[0] ? read_burst_name_i : write_burst_name_i;
assign selected_size_o = current_grant[0] ? read_burst_size_i : write_burst_size_i;
assign wr_trans_done_o = current_grant[1] & control[1];
assign rd_trans_done_o = current_grant[0] & control[1];
assign write_enable_o = current_grant[1];
  //***************************************************
  //internal assignment
  //***************************************************
assign rd_req_avail = ~sfifo_ar_empty_i;
assign wr_req_avail = ~sfifo_aw_empty_i;
assign burst_en = new_req_rdy ? (current_grant[0] ? ~sfifo_ar_empty_i : ~sfifo_aw_empty_i) : 1'b0;
//
//ready to run new request
//
  always_ff@(posedge aclk, negedge aresetn) begin
    if(~aresetn) new_req_rdy <= 1'b1;
    else if(control[0]) begin
      new_req_rdy <= 1'b0;
    end
    else if(control[1]) begin
      new_req_rdy <= 1'b1;
    end 
  end
//
//state reg
//
always_ff@(posedge aclk, negedge aresetn) begin
	if(~aresetn) abt_cs <= A_IDLE;
	else abt_cs <= abt_ns;
end
  //
always_comb begin
  abt_ns = abt_cs;
  burst_go = 1'b0;
  control = 2'b0;
  //
  case(abt_cs)
  A_IDLE: begin
	  if(burst_en) begin
		  abt_ns = ABT_GO;
		  control = 2'b01;
	  end
	  else begin
		  abt_ns = A_IDLE;
		  control = 2'b00;
	  end
  end
  ABT_GO: begin
	if(burst_almost_done_i) abt_ns = ABT_DONE;
	else abt_ns = ABT_GO;
	//
	burst_go = 1'b1;
  end
  ABT_DONE: begin
	  if(burst_done_i) begin
		  abt_ns = A_IDLE;
		  control = 2'b10;
	  end
	  else abt_ns = ABT_DONE;
  end
  default: begin
	  abt_ns = abt_cs;
	  burst_go = 1'b0;
	  control = 2'b00;
  end
  endcase
end

  //
  //nextSel0
  always_comb begin
    if(current_grant[0])
	  nextSel[0] = 1'b1;
	else if(rd_req_avail)
	  nextSel[0] = 1'b0;
	else
	  nextSel[0] = 1'b1;
  end
  //nextSel1
  always_comb begin
    if(current_grant[1])
	  nextSel[1] = 1'b1;
	else if(wr_req_avail)
	  nextSel[1] = 1'b0;
	else
	  nextSel[1] = 1'b1;
  end
  //nextGrant[1]
  always_comb begin
    if(~nextSel[0])
	  nextGrant[1] = 1'b0;
	else if(wr_req_avail) //	R1
	  nextGrant[1] = 1'b1;
	else
	  nextGrant[1] = current_grant[1]; //R2
  end
  //nextGrant[0]
  always_comb begin
    if(~nextSel[1])
	  nextGrant[0] = 1'b0;
	else if(rd_req_avail) //W1
	  nextGrant[0] = 1'b1;
	else
	  nextGrant[0] = current_grant[0]; //W2
  end
//
//current_grant
//
assign update = (burst_go ? 1'b0 : (current_grant[0] ? (wr_req_avail & sfifo_ar_empty_i) : (rd_req_avail & sfifo_aw_empty_i)))
| control[1];
//
always_ff @(posedge aclk, negedge aresetn) begin
	if(~aresetn)
		current_grant[1:0] <= 2'b01;
	else if(update)
		current_grant[1:0] <= nextGrant[1:0];
	else
		current_grant[1:0] <= current_grant[1:0];	  
end
//
//address register
assign addr_incr_active = control[1] ? addr_incr_en_i : 1'b0;
//
always_ff@(posedge pclk, negedge preset_n) begin
	if(~preset_n) addr_reg <= 32'd0;
	else if(begin_transfer) begin
		addr_reg <= {selected_addr_o[31:2], 2'b00};
	end
	else if(addr_incr_active) begin
		case(selected_burst_o) 
			2'b00: addr_reg <= addr_reg;
			2'b01: addr_reg <= next_addr_for_incr;
			2'b10: addr_reg <= next_addr_for_wrap;
			2'b11: addr_reg <= 32'bx;
		endcase
	end
end
//
//calculate address
//
assign next_addr_for_incr[31:0] = addr_reg[31:0] + 3'd4;
//
//bit_num
//
always_comb begin
case(selected_len_o[7:0])
  8'd1:  bit_num[2:0] = 3'b011;
  8'd3:  bit_num[2:0] = 3'b100;
  8'd7:  bit_num[2:0] = 3'b101;
  8'd15: bit_num[2:0] = 3'b110;
  default: bit_num[2:0] = 3'bx;
endcase
end
//bit3Addr, bit4Addr, bit5Addr, bit6Addr
always_comb begin
if(bit_num[2:0] == 3'b011)
  bit3Addr[2:0] = addr_reg[2:0] + 3'd4;
else
  bit3Addr[2:0] = 3'd0;
end
always_comb begin
if(bit_num[2:0] == 3'b100)
  bit4Addr[3:0] = addr_reg[3:0] + 3'd4;
else
  bit4Addr[3:0] = 4'd0;
end
always_comb begin
if(bit_num[2:0] == 3'b101)
  bit5Addr[4:0] = addr_reg[4:0] + 3'd4;
else
  bit5Addr[4:0] = 5'd0;
end
always_comb begin
if(bit_num[2:0] == 3'b110)
  bit6Addr[5:0] = addr_reg[5:0] + 3'd4;
else
  bit6Addr[5:0] = 6'd0;
end
//next_addr_for_wrap
always_comb begin
case(bit_num[2:0])
  3'b011: next_addr_for_wrap[31:0] = {addr_reg[31:3], bit3Addr[2:0]};
  3'b100: next_addr_for_wrap[31:0] = {addr_reg[31:4], bit4Addr[3:0]};
  3'b101: next_addr_for_wrap[31:0] = {addr_reg[31:5], bit5Addr[4:0]};
  3'b110: next_addr_for_wrap[31:0] = {addr_reg[31:6], bit6Addr[5:0]};
  default: next_addr_for_wrap[31:0] = 32'bx;
endcase
end
//
//
//
RiSiEdgeDetector RiSiEdgeDetector_burst_go(
  .clk_i(pclk),
  .rstn_i(preset_n),
  .sign_i(burst_go),
  .red_o(begin_transfer)  
  //
);

//
endmodule

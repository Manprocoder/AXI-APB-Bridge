//
//
//
module counter(
	pclk,
	preset_n,
	len_of_burst_i,
	set_up_phase_i,
	beat_cnt_incr_i,
	//
	burst_almost_done_o,
	burst_done_o
	//	
);
//************************************************
//ports
//************************************************
input logic pclk;
input logic preset_n;
input logic [7:0] len_of_burst_i;
input logic set_up_phase_i;
input logic beat_cnt_incr_i;
output logic burst_almost_done_o;
output logic burst_done_o;
//************************************************
//variables
//************************************************
logic [7:0] transfer_cnt;
//
//output
assign burst_almost_done_o = set_up_phase_i ? ((transfer_cnt == len_of_burst_i) ? 1'b1 : 1'b0) : 1'b0;
assign burst_done_o = beat_cnt_incr_i ? ((transfer_cnt == len_of_burst_i) ? 1'b1 : 1'b0) : 1'b0;
//
//
//
always_ff @(posedge pclk, negedge preset_n) begin
if(~preset_n)
  transfer_cnt[7:0] <= 8'd0;
else begin
	if(burst_done_o) transfer_cnt <= 8'd0;
	else if(beat_cnt_incr_i) begin
		 transfer_cnt <= transfer_cnt + 1'b1;
	 end
end
end
  //
  //
  //
endmodule

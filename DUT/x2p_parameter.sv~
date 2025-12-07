//parameter declaration
package parameter_pkg;
    
parameter X2P_SFIFO_AW_DATA_WIDTH = 56;
parameter X2P_SFIFO_AR_DATA_WIDTH = 56;
parameter X2P_SFIFO_WD_DATA_WIDTH = 37;
parameter X2P_SFIFO_RD_DATA_WIDTH = 43;
parameter POINTER_WIDTH           = 4;
//Error
parameter OKAY                    = 2'b00;
parameter DECERR                  = 2'b11;
parameter PSLVERR                 = 2'b10;
//address of Register block
parameter A_START_SLAVE0  = 32'h0000_0000;
parameter A_END_SLAVE0    = 32'h0000_0FFF;
parameter A_START_SLAVE1  = 32'h0000_1000;
parameter A_END_SLAVE1    = 32'h0000_1FFF;
parameter A_START_SLAVE2  = 32'h0000_2000;
parameter A_END_SLAVE2    = 32'h0000_2FFF;
parameter A_START_SLAVE3  = 32'h0000_3000;
parameter A_END_SLAVE3    = 32'h0000_3FFF;
//calculate bytes in transfer
function logic [7:0] bytes_in_transfer;
	input logic [2:0] size;
begin
	case(size)
		3'd0:bytes_in_transfer = 1;
		3'd1:bytes_in_transfer = 2;
		3'd2:bytes_in_transfer = 4;
		3'd3:bytes_in_transfer = 8;
		3'd4:bytes_in_transfer = 16;
		3'd5:bytes_in_transfer = 32;
		3'd6:bytes_in_transfer = 64;
		3'd7:bytes_in_transfer = 128;
	endcase
end
endfunction	
//
endpackage

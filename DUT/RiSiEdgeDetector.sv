//
//rising edge detect
//
module RiSiEdgeDetector(
    input logic clk_i,
    input logic rstn_i,
    input logic sign_i,
    output logic red_o  //
);

    //internal reg
    //
    logic prev_sign_i;
    //
    //output assignment
    assign red_o = ~prev_sign_i & sign_i;
    //
    always_ff @(posedge clk_i, negedge rstn_i) begin
        if(~rstn_i) prev_sign_i <= 1'b0;
        else prev_sign_i <= sign_i;
    end

endmodule
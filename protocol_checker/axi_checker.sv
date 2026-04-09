module axi_checker();
    logic aclk;
    logic aresetn;
    logic awvalid;
    logic awready;
    logic [7:0] awid;
    logic [31:0] awaddr;
    logic [7:0] awlen;
    logic [2:0] awsize;
    logic [1:0] awburst;
    logic wvalid;
    logic wready;
    logic [31:0] wdata;
    logic [3:0] wstrb;
    logic wlast;
    logic bvalid;
    logic [1:0] bresp;
    logic [7:0] bid;
    logic bready;
    //
    logic arvalid;
    logic arready;
    logic [7:0] arid;
    logic [31:0] araddr;
    logic [7:0] arlen;
    logic [2:0] arsize;
    logic [1:0] arburst;
    logic rvalid;
    logic rready;
    logic [31:0] rdata;
    logic rlast;
    logic [1:0] rresp;
    logic [7:0] rid;
    //
    parameter INST_NAME = "AXI_PROTOCOL_CHECKER";
    //
    always@(posedge aclk) begin
      if(awvalid && aresetn) begin
        case (|awaddr)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] AWADDR is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] AWADDR is z\n", INST_NAME, $time);
        endcase 
        //check 2
        case (|awlen)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] AWLEN is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] AWLEN is z\n", INST_NAME, $time);
        endcase 
        //check 3
        case (|awsize)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] AWSIZE is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] AWSIZE is z\n", INST_NAME, $time);
        endcase 
        //check 4
        case (|awburst)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] AWBURST is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] AWBURST is z\n", INST_NAME, $time);
        endcase 
        //check 5
        case (|awid)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] AWID is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] AWID is z\n", INST_NAME, $time);
        endcase
      end
    end
    //WDATA CHANNEL
    always@(posedge aclk) begin
      if(wvalid && aresetn) begin
      case (|wdata)
      1'bx: $display("[AXI_WARNING][%s][%0t ns] WDATA is x\n", INST_NAME, $time);
      1'bz: $display("[AXI_WARNING][%s][%0t ns] WDATA is z\n", INST_NAME, $time);
      endcase 
      //check2
      case (|wstrb)
      1'bx: $display("[AXI_WARNING][%s][%0t ns] WSTRB is x\n", INST_NAME, $time);
      1'bz: $display("[AXI_WARNING][%s][%0t ns] WSTRB is z\n", INST_NAME, $time);
      endcase 
      //check3
      case (wready)
      1'bx: $display("[AXI_WARNING][%s][%0t ns] WREADY is x\n", INST_NAME, $time);
      1'bz: $display("[AXI_WARNING][%s][%0t ns] WREADY is z\n", INST_NAME, $time);
      endcase
      end
    end
    //
    always@(posedge aclk) begin
      if(bvalid && aresetn) begin
          //check1
          case (bid)
          1'bx: $display("[AXI_WARNING][%s][%0t ns] BID is x\n", INST_NAME, $time);
          1'bz: $display("[AXI_WARNING][%s][%0t ns] BID is z\n", INST_NAME, $time);
          endcase 
          //check2
          case (bresp)
          1'bx: $display("[AXI_WARNING][%s][%0t ns] BRESP is x\n", INST_NAME, $time);
          1'bz: $display("[AXI_WARNING][%s][%0t ns] BRESP is z\n", INST_NAME, $time);
          endcase 
          //check3
          case (bready)
          1'bx: $display("[AXI_WARNING][%s][%0t ns] BREADY is x\n", INST_NAME, $time);
          1'bz: $display("[AXI_WARNING][%s][%0t ns] BREADY is z\n", INST_NAME, $time);
          endcase 
      end
    end
    //RD ADDR CHANNEL
    always@(posedge aclk) begin
      if(arvalid && aresetn) begin
        case (|araddr)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] ARADDR is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] ARADDR is z\n", INST_NAME, $time);
        endcase 
        //check 2
        case (|arlen)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] ARLEN is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] ARLEN is z\n", INST_NAME, $time);
        endcase 
        //check 3
        case (|arsize)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] ARSIZE is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] ARSIZE is z\n", INST_NAME, $time);
        endcase 
        //check 4
        case (|arburst)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] ARBURST is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] ARBURST is z\n", INST_NAME, $time);
        endcase 
        //check 5
        case (|arid)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] ARID is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] ARID is z\n", INST_NAME, $time);
        endcase
      end
    end
    //
    //RDATA CHANNEL
    always@(posedge aclk) begin
      if(rvalid && aresetn) begin
        //check1
        case (|rdata)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] RDATA is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] RDATA is z\n", INST_NAME, $time);
        endcase 
        //check2
        case (rready)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] RREADY is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] RREADY is z\n", INST_NAME, $time);
        endcase 
        //check3
        case (|rid)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] RID is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] RID is z\n", INST_NAME, $time);
        endcase 
        //check4
        case (|rresp)
        1'bx: $display("[AXI_WARNING][%s][%0t ns] RRESP is x\n", INST_NAME, $time);
        1'bz: $display("[AXI_WARNING][%s][%0t ns] RRESP is z\n", INST_NAME, $time);
        endcase 
      end
    end
    //
    //
    //logic [7:0] bid_tmp;
    //logic [1:0] bresp_tmp;
    //logic stable;
    ////
    //always@(posedge aclk) begin
	    //if(~aresetn) begin
		    //bid_tmp <= '0;
		    //bresp_tmp <= 2'b0;
		    //stable <= 1'b0;
	    //end
	    //else if(bvalid) begin
		    //if(bready) begin
			    //bid_tmp <= '0;
			    //bresp_tmp <= 2'b0;
			    //stable <= 1'b0;
	    	    //end
		    //else begin
			    //bid_tmp <= bid;
			    //bresp_tmp <= bresp;
			    //stable <= 1'b1;
	    	    //end
	    //end   
    //end
    ////
    //always@(posedge aclk) begin
	    //if(stable) begin
		    //if((bid !== bid_tmp) || (bresp !== bresp_tmp)) begin
			//$display("[AXI_ERROR][%s][%0t ns] BID or BRESP changed before BREADY is HIGH\n", INST_NAME, $time);
		    //end
	    //end
    //end
    //
endmodule

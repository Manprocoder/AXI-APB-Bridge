module axi_cov();
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
    // parameter INST_NAME0   = "AXI_FUNCTIONAL_COVERAGE_PART";
    // parameter INST_NAME1   = "AXI_FUNCTIONAL_COVERAGE_TOTAL";
    //
    //main covergroup
    //
    //--1: aw channel cg
    covergroup axi_wreq_cg @(posedge aclk iff aresetn);
        option.per_instance = 1;
        //
        awvalid_cp: coverpoint awvalid {
            bins value_0 = {1'b0};
            bins value_1 = {1'b1};
        }
        awready_cp: coverpoint awready {
            bins value_0 = {1'b0};
            bins value_1 = {1'b1};
        }
        awid_cp: coverpoint awid iff awvalid && awready;//{
            //bins very_low = {[0:15]};
            //bins mid0_low = {[16:31]};
            //bins mid1_low = {[32:45]};
            //bins low  = {[46:63]};
            //bins mid  = {[64:127]};
            //bins high = {[128:191]};
            //bins top  = {[192:255]};
        //}
        awaddr_cp: coverpoint awaddr iff awvalid && awready{
            wildcard bins aligned_addr = {32'b00000000_0000000?_????????_??????00};
            wildcard bins unaligned_addr0 = {32'b00000000_0000000?_????????_???????1};
            wildcard bins unaligned_addr1 = {32'b00000000_0000000?_????????_??????10};
            //
        }
        len_cp : coverpoint awlen iff awvalid && awready{
            bins wrap   = {1,3,7,15}; // spec-defined
            bins rest   = {[0:255]};
        }

        awburst_cp : coverpoint awburst iff awvalid && awready{
            bins fixed = {2'b00};
            bins incr  = {2'b01};
            bins wrap  = {2'b10};
            ignore_bins reserved = {2'b11};
        }
        //
        //cross coverage
        //
        burst_x_len: cross awburst_cp, len_cp {
            bins xy1 = binsof(awburst_cp.wrap) && binsof(len_cp.wrap);
            bins xy2 = binsof(awburst_cp.fixed) && binsof(len_cp.rest);
            bins xy3 = binsof(awburst_cp.incr) && binsof(len_cp.rest);
        }
        //
        burst_x_addr: cross awburst_cp, awaddr_cp {
            bins xy1 = binsof(awburst_cp.incr);
            bins xy2 = binsof(awburst_cp.fixed) && binsof(awaddr_cp.aligned_addr);
            bins xy3 = binsof(awburst_cp.wrap) && binsof(awaddr_cp.aligned_addr);
            ignore_bins others = (binsof(awburst_cp.fixed) || binsof(awburst_cp.wrap)) && !binsof(awaddr_cp.aligned_addr);
        }
    endgroup
    //--2: wdata channel cg
    covergroup axi_wdata_cg @(posedge aclk iff aresetn);
        option.per_instance = 1;
        //
        wvalid_cp: coverpoint wvalid {
            bins value_0 = {1'b0};
            bins value_1 = {1'b1};
        }
        wready_cp: coverpoint wready {
            bins value_0 = {1'b0};
            bins value_1 = {1'b1};
        }
        wstrb_cp: coverpoint wstrb iff wvalid && wready{
            bins single = {4'h1, 4'h2, 4'h4, 4'h8};
            bins half = {4'h3, 4'hC};
            bins third = {4'h7, 4'hE};
            bins full = {4'hf};
            ignore_bins empty = {4'h0};
        }
        wlast_cp: coverpoint wlast iff wvalid && wready{
            bins value_0 = {1'b0};
            bins value_1 = {1'b1};
        }
    endgroup
    //--3: bresp channel cg
    covergroup axi_bresp_cg @(posedge aclk iff aresetn);
        option.per_instance = 1;
        //
        bvalid_cp: coverpoint bvalid {
            bins value_0 = {1'b0};
            bins value_1 = {1'b1};
        }
        bready_cp: coverpoint bready {
            bins value_0 = {1'b0};
            bins value_1 = {1'b1};
        }
        bid_cp: coverpoint bid iff bvalid && bready; //{
            //bins low  = {[0:63]};
            //bins mid  = {[64:127]};
            //bins high = {[128:191]};
            //bins top  = {[192:255]};
        //}
        bresp_cp: coverpoint bresp iff bvalid && bready{
            bins okay = {2'b00};  // OKAY response
            ignore_bins exokay = {2'b01}; // EXOKAY response
            bins slverr = {2'b10}; // SLVERR response
            bins decerr = {2'b11}; // DECERR response
        }
    endgroup

    //--4: ar channel cg
    covergroup axi_rreq_cg @(posedge aclk iff aresetn);
        option.per_instance = 1;
        //
        arvalid_cp: coverpoint arvalid {
            bins value_0 = {1'b0};
            bins value_1 = {1'b1};
        }
        arready_cp: coverpoint arready {
            bins value_0 = {1'b0};
            bins value_1 = {1'b1};
        }
        arid_cp: coverpoint arid iff arvalid && arready;//{
            //bins low  = {[0:63]};
            //bins mid  = {[64:127]};
            //bins high = {[128:191]};
            //bins top  = {[192:255]};
        //}
        araddr_cp: coverpoint araddr iff arvalid && arready{
            wildcard bins aligned_addr = {32'b00000000_0000000?_????????_??????00};
            wildcard bins unaligned_addr0 = {32'b00000000_0000000?_????????_???????1};
            wildcard bins unaligned_addr1 = {32'b00000000_0000000?_????????_??????10};
        }
        len_cp : coverpoint arlen iff arvalid && arready{
            bins wrap   = {1,3,7,15}; // spec-defined
            bins rest   = {[0:255]};
        }

        arburst_cp : coverpoint arburst iff arvalid && arready{
            bins fixed = {2'b00};
            bins incr  = {2'b01};
            bins wrap  = {2'b10};
            ignore_bins reserved = {2'b11};
        }
        //
        //cross coverage
        //
	//--to adopt binsof to define expected coverage and use ignore_bins to
	//remove unnecessary or unwanted coverage 
        burst_x_len: cross arburst_cp, len_cp {
            bins xy1 = binsof(arburst_cp.wrap) && binsof(len_cp.wrap);
            bins xy2 = binsof(arburst_cp.fixed) && binsof(len_cp.rest);
            bins xy3 = binsof(arburst_cp.incr) && binsof(len_cp.rest);
        }
        //
        burst_x_addr: cross arburst_cp, araddr_cp {
            bins xy1 = binsof(arburst_cp.incr);
            bins xy2 = binsof(arburst_cp.fixed) && binsof(araddr_cp.aligned_addr);
            bins xy3 = binsof(arburst_cp.wrap) && binsof(araddr_cp.aligned_addr);
            ignore_bins others = (binsof(arburst_cp.fixed) || binsof(arburst_cp.wrap)) && !binsof(araddr_cp.aligned_addr);
        }
    endgroup
    
    //--5: rdata channel cg
    covergroup axi_rdata_cg @(posedge aclk iff aresetn);
        option.per_instance = 1;
        //
        rvalid_cp: coverpoint rvalid {
            bins value_0 = {1'b0};
            bins value_1 = {1'b1};
        }
        rready_cp: coverpoint rready {
            bins value_0 = {1'b0};
            bins value_1 = {1'b1};
        }
        rlast_cp: coverpoint rlast iff(rvalid && rready){
            bins value_0 = {1'b0};
            bins value_1 = {1'b1};
        }
        rresp_cp: coverpoint rresp iff(rvalid && rready){
            bins okay = {2'b00};  // OKAY response
            ignore_bins exokay = {2'b01}; // EXOKAY response
            bins slverr = {2'b10}; // SLVERR response
            bins decerr = {2'b11}; // DECERR response
        }
        rid_cp: coverpoint rid iff(rvalid && rready);//{
            //bins low  = {[0:63]};
            //bins mid  = {[64:127]};
            //bins high = {[128:191]};
            //bins top  = {[192:255]};
        //}
    endgroup
    // ------------------------------------------------------
    // Instances
    // ------------------------------------------------------
    axi_wreq_cg   wreq_cov  = new();
    axi_wdata_cg  wdata_cov = new();
    axi_bresp_cg  bresp_cov = new();
    axi_rreq_cg   rreq_cov  = new();
    axi_rdata_cg  rdata_cov = new();

    //initial begin
        //$display("[%s][%0t ns]", INST_NAME0, $time);
        //$display("wreq_cov   = %0.2f",  wreq_cov.get_coverage());
        //$display("wdata_cov  = %0.2f",  wdata_cov.get_coverage());
        //$display("bresp_cov  = %0.2f",  bresp_cov.get_coverage());
        //$display("rreq_cov   = %0.2f",  rreq_cov.get_coverage());
        //$display("rdata_cov  = %0.2f",  rdata_cov.get_coverage());
    //end
    //// ------------------------------------------------------
    //// Coverage printing (simulation end)
    //// ------------------------------------------------------
    //final begin
        //$display("[%s][%0t ns]", INST_NAME1, $time);
        //$display("wreq_cov   = %0.2f",  wreq_cov.get_coverage());
        //$display("wdata_cov  = %0.2f",  wdata_cov.get_coverage());
        //$display("bresp_cov  = %0.2f",  bresp_cov.get_coverage());
        //$display("rreq_cov   = %0.2f",  rreq_cov.get_coverage());
        //$display("rdata_cov  = %0.2f",  rdata_cov.get_coverage());
    //end
endmodule
    

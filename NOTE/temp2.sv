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
burst_x_addr: cross awburst_cp, awaddr_cp {
            bins xy1 = binsof(awburst_cp.incr);
            bins xy2 = binsof(awburst_cp.fixed) && binsof(awaddr_cp.aligned_addr);
            bins xy3 = binsof(awburst_cp.wrap) && binsof(awaddr_cp.aligned_addr);
        }
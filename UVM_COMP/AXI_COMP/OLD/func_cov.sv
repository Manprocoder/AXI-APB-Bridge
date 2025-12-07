class axi_transaction_cov extends uvm_subscriber #(axi_transaction#());
  `uvm_component_utils(axi_transaction_cov)

  covergroup cg_axi;
    option.name = "axi_transaction_cg";
    option.per_instance = 1;  // per subscriber instance
    option.goal = 100;        // target 100% coverage for closure

    // Burst type
    coverpoint tr.burst {
      bins FIXED = {FIXED};
      bins INCR  = {INCR};
      bins WRAP  = {WRAP};
    }

    // Address alignment
    coverpoint tr.addr[1:0] {
      bins aligned   = {2'b00};
      bins unaligned = {2'b01, 2'b10, 2'b11};
    }
    // cover id distribution
        id_cp : coverpoint id {
            bins low   = {[0:15]};
            bins mid   = {[16:127]};
            bins high  = {[128:255]};
        }

        // cover aligned vs unaligned address
        addr_align_cp : coverpoint addr[1:0] {
            bins aligned   = {2'b00};
            bins unaligned = {[2'b01:2'b11]};
        }

        // cover burst types
        burst_cp : coverpoint burst {
            bins fixed = {FIXED};
            bins incr  = {INCR};
            bins wrap  = {WRAP};
        }

        // cover len values
        len_cp : coverpoint len {
            bins single  = {0};
            bins short   = {[1:3]};
            bins average = {[4:15]};
            bins long    = {[16:255]};
        }

        // cover rready toggle
        rready_cp : coverpoint rready {
            bins ready = {1};
            bins not_ready = {0};
        }

        // WSTRB coverage (first-beat strobe only, to avoid exploding bins)
        wstrb_cp : coverpoint (wstrb.size() > 0 ? wstrb[0] : 4'h0) {
            bins single = {4'h1, 4'h2, 4'h4, 4'h8};
            bins half   = {4'h3, 4'hC};
            bins third  = {4'hE, 4'h7};
            bins full   = {4'hF};
            bins others = {4'h5, 4'h9, 4'hA, 4'hB, 4'hD};
            ignore_bins empty = {4'h0}; // filtered out case
        }
        // BRESP  
        bresp_cp : coverpoint bresp {
            bins ok    = {2'b00};
            bins exok  = {2'b01};
            bins slverr= {2'b10};
            bins decerr= {2'b11};
        }
        // RRESP
        rresp_cp : coverpoint rresp {
            bins ok    = {2'b00};
            bins exok  = {2'b01};
            bins slverr= {2'b10};
            bins decerr= {2'b11};
        }
        // cross coverage
        burst_len_cross : cross burst_cp, len_cp;
        align_burst_cross : cross addr_align_cp, burst_cp;
        align_wstrb_cross : cross addr_align_cp, wstrb_cp;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_axi = new();
  endfunction

  virtual function void write(axi_transaction t);
    cg_axi.sample(t);
  endfunction

endclass

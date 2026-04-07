//----------------------------------------------------------------------------------
//---page 122/ uvm cookbook
//---this class implement 3 covergroups: axi_coverage, wstrb array and rresp array
//----------------------------------------------------------------------------------
class func_cov extends uvm_subscriber #(axi_transaction #(DW,AW1));
  `uvm_component_utils(func_cov)
  axi_transaction#(DW,AW1) transaction;
  logic [3:0] wstrb_element;
  logic [1:0] rresp_element;
  // Coverage Groups
  covergroup axi_coverage;
    option.per_instance = 1;
    //
    //REQUEST
    //
    id_cp : coverpoint transaction.id[7:0]{
      bins low  = {[0:63]};
      bins mid  = {[64:127]};
      bins high = {[128:191]};
      bins top  = {[192:255]};
      // option.auto_bin_max = 16; // finer if needed
    }
    //
    burst_type_cp : coverpoint transaction.burst{
      bins fixed = {2'b00};
      bins incr  = {2'b01};
      bins wrap  = {2'b10};
    }
    //
    addr_cp : coverpoint transaction.addr {
      bins addr_reg_block  = { [32'h0000_0000:32'h0000_0FFF] };  // Valid range
      bins valid_addr0  = { [32'h0000_1000:32'h0000_1FFF] };  // Valid range
      bins valid_addr1  = { [32'h0000_2000:32'h0001_FFFF] };  // Valid range
      bins valid_addr2  = { [32'h0002_0000:32'h0002_0FFF] };  // Valid range
      bins invalid_addr = { [32'h0002_1000:32'h0003_0FFF] };  // Out-of-range addresses
    }
    // alignment coverage
    addr_align_cp: coverpoint transaction.addr[1:0] {
      bins aligned  = {2'b00};
      bins misaligned[] = {2'b01, 2'b10, 2'b11};
    }
    size_cp: coverpoint transaction.size {
      bins bytes_4 = {3'b010};
    } 
        
    len_cp : coverpoint transaction.len{
      bins single = {0};
      bins short  = {[1:7]};
      bins long   = {[8:15]};
      bins max    = {255};
      bins wrap   = {1,3,7,15}; // spec-defined
    }
    //
    //DATA
    // 
    sizeof_data_array_cp : coverpoint transaction.data.size() {
      bins small_size = {[1:4]};
      bins med_size   = {[5:32]};
      bins big_size   = {[33:256]};
    }
    //
    sizeof_wstrb_array_cp : coverpoint transaction.wstrb.size() {
      bins small_size = {[1:4]};
      bins med_size   = {[5:32]};
      bins big_size   = {[33:256]};
    }
    //
    bresp_cp : coverpoint transaction.bresp {
      bins okay = {2'b00};  // OKAY response
      ignore_bins exokay = {2'b01}; // EXOKAY response
      bins slverr = {2'b10}; // SLVERR response
      bins decerr = {2'b11}; // DECERR response
    }
    bid_cp : coverpoint transaction.bid[7:0]{
      bins low  = {[0:63]};
      bins mid  = {[64:127]};
      bins high = {[128:191]};
      bins top  = {[192:255]};
      // option.auto_bin_max = 16; // finer if needed
    }
    //
    sizeof_rid_array_cp : coverpoint transaction.rid.size() {
      bins small_size = {[1:4]};
      bins med_size   = {[5:32]};
      bins big_size   = {[33:256]};
    }
    //
    //	
    //last_cp: coverpoint transaction.last{
      //bins last_0 = {0};
      //bins last_1 = {1};
    //}
    //----------------------------------------
    // Cross coverage
    //----------------------------------------
    burst_len_x : cross burst_type_cp, len_cp;
    size_addr_x : cross size_cp, addr_cp;
    // Cross coverage to ensure "addr_c" constraint are exercised
    burst_addr_align_x: cross burst_type_cp, addr_align_cp {
      // Only care about FIXED/WRAP vs alignment
      ignore_bins incr_misaligned = binsof(burst_type_cp.incr) && binsof(addr_align_cp.misaligned);
    }
    //
  endgroup
  //
  //wstrb array coverage group
  covergroup axi_wstrb_cov with function sample (input logic [3:0] wstrb_ele);
    option.per_instance = 1;
    //
    wstrb_cp : coverpoint wstrb_ele {
      bins single = {4'h1, 4'h2, 4'h4, 4'h8};
      bins half   = {4'h3, 4'hC};
      bins third  = {4'hE, 4'h7};
      bins full   = {4'hF};
      // bins others = {4'h5, 4'h9, 4'hA, 4'hB, 4'hD};
      ignore_bins empty = {4'h0}; // filtered out case
    }
  endgroup
  //
  //rresp covergroup
  covergroup axi_rresp_cov with function sample (input logic [1:0] rresp_ele);
    option.per_instance = 1;
    //
    rresp_cp : coverpoint rresp_ele {
      bins okay   = {2'b00};
      bins slverr = {2'b10};
      bins decerr = {2'b11};
      ignore_bins exokay = {2'b01};
    }
  endgroup
  
    // Constructor
  function new(string name = "axi_cov", uvm_component parent);
    super.new(name, parent);
    //
    axi_coverage = new();
    axi_wstrb_cov = new();
    axi_rresp_cov = new();
  endfunction
  // Sample the transaction for coverage
  function void write(axi_transaction#(DW,AW1) t);
    this.transaction = t;
    //sample complete transaction
    axi_coverage.sample();
    //sample wstrb array 
    foreach (t.wstrb[i]) begin
      wstrb_element = t.wstrb[i];
      axi_wstrb_cov.sample(wstrb_element); // dedicated covergroup for wstrb
    end
    // Loop through rresp array
    foreach (t.rresp[i]) begin
      rresp_element = t.rresp[i];
      axi_rresp_cov.sample(rresp_element); // dedicated covergroup for rresp
    end
    //
    `uvm_info(get_type_name(), $sformatf("axi_cov = %.2f", axi_coverage.get_coverage()), UVM_NONE);
    `uvm_info(get_type_name(), $sformatf("wstrb_cov = %.2f", axi_wstrb_cov.get_coverage()), UVM_NONE);
    `uvm_info(get_type_name(), $sformatf("rresp = %.2f", axi_rresp_cov.get_coverage()), UVM_NONE);
    //
  endfunction
      
endclass
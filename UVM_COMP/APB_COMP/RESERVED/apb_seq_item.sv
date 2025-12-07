//===================================================================
//-- file: apb_mst_seq_item.sv
//-- apb_mst sequence item (master/slave mode)
//===================================================================
class apb_seq_item #(int DW = 32, int AW = 32, int SLAVE_NUM = 1) extends uvm_sequence_item;
    typedef apb_seq_item #(DW, AW, SLAVE_NUM) this_type_t;
    `uvm_object_param_utils(apb_seq_item(DW, AW, SLAVE_NUM))

    //===================================
    // SLAVE MODE
    //===================================
    `ifdef APB_SLAVE_MODE
        rand bit [`SLAVE_NUM-1:0]        pready;
        rand bit [`SLAVE_NUM-1:0][31:0]  prdata;
        rand bit [`SLAVE_NUM-1:0]        pslverr;
        rand bit [7:0]                 preadyDelay;

        logic [31:0] paddr;
        logic [31:0] pwdata;
        logic [`SLAVE_NUM-1:0] psel;
        logic [3:0]  pstrb;
        logic        pwrite;

    //===================================
    // MASTER MODE
    //===================================
    `else
        logic       [AW-1:0]   apb_mst_addr;
        logic       [DW/4-1:0] apb_mst_wdata[];
        rand  logic [DW/4-1:0] apb_mst_rdata[];
        rand  logic            apb_mst_error;
        rand  logic            apb_mst_ready;
        logic                  apb_mst_write;

        // sequence control parameters
        rand logic apb_mst_SeqEn;
        rand logic apb_mst_ConEn;
        rand int   apb_mst_Delay;

        // Constraints
        constraint delay_time { apb_mst_Delay inside {[0:15]}; }
        constraint apb_mst_error_limit { apb_mst_error dist {0 := 90, 1 := 10}; }
        constraint apb_mst_ready_limit { apb_mst_ready dist {0 := 90, 1 := 10}; }
    `endif

    //===================================
    // Constructor
    //===================================
    function new(string name = "apb_mst_seq_item");
        super.new(name);
    endfunction

    //===================================
    // UVM built-in overrides
    //===================================
    extern function void do_print(uvm_printer printer);
    extern function string convert2string();
    extern function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    extern function void do_copy(uvm_object rhs);

endclass

//=======================================
// do_print
//=======================================
function void apb_mst_seq_item::do_print(uvm_printer printer);
    super.do_print(printer);

`ifndef apb_mst_SLAVE_MODE
    printer.print_field("ERROR",   apb_mst_error, $bits(apb_mst_error), UVM_HEX);
    printer.print_field("READY",   apb_mst_ready, $bits(apb_mst_ready), UVM_HEX);
    printer.print_field("ADDRESS", apb_mst_addr,  $bits(apb_mst_addr),  UVM_HEX);

    if(apb_mst_write) begin
        foreach (apb_mst_wdata[i]) begin
            printer.print_field($sformatf("W_DATA[%0d]", i), apb_mst_wdata[i], $bits(apb_mst_wdata[i]), UVM_HEX);
        end
    end else begin
        foreach (apb_mst_rdata[i]) begin
            printer.print_field($sformatf("R_DATA[%0d]", i), apb_mst_rdata[i], $bits(apb_mst_rdata[i]), UVM_HEX);
        end
    end
`else
    printer.print_field("PADDR",  paddr, 32, UVM_HEX);
    printer.print_field("PWDATA", pwdata, 32, UVM_HEX);
    printer.print_field("PWRITE", pwrite, 1, UVM_BIN);
    printer.print_field("PREADY_DELAY", preadyDelay, 8, UVM_DEC);
`endif
endfunction

//=======================================
// convert2string
//=======================================
function string apb_mst_seq_item::convert2string();
    string s;
    super.convert2string();

`ifndef apb_mst_SLAVE_MODE
    s = {s, $sformatf("READY          : %0d\n", apb_mst_ready)};
    s = {s, $sformatf("ERROR          : %0d\n", apb_mst_error)};
    s = {s, $sformatf("ADDRESS        : 0x%0h\n", apb_mst_addr)};

    if(apb_mst_write) begin
        foreach (apb_mst_wdata[i]) begin
            s = {s, $sformatf("WRITE DATA[%0d] : 0x%0h\n", i, apb_mst_wdata[i])};
        end
    end else begin
        foreach (apb_mst_rdata[i]) begin
            s = {s, $sformatf("READ DATA[%0d]  : 0x%0h\n", i, apb_mst_rdata[i])};
        end
    end
`else
    s = {s, $sformatf("ADDR    : 0x%0h\n", paddr)};
    s = {s, $sformatf("WDATA   : 0x%0h\n", pwdata)};
    s = {s, $sformatf("PWRITE  : %0b\n", pwrite)};
    s = {s, $sformatf("DELAY   : %0d\n", preadyDelay)};
`endif

    return s;
endfunction

//=======================================
// do_compare
//=======================================
function bit apb_mst_seq_item::do_compare(uvm_object rhs, uvm_comparer comparer);
    this_type_t rhs_;
    bit ok;

    if(!$cast(rhs_, rhs)) begin
        `uvm_fatal("apb_mst_SEQ_ITEM", "Object is not of type apb_mst_seq_item")
        return 0;
    end 

    ok = super.do_compare(rhs, comparer);

`ifndef apb_mst_SLAVE_MODE
    ok &= (this.apb_mst_error == rhs_.apb_mst_error);
    ok &= (this.apb_mst_ready == rhs_.apb_mst_ready);
    ok &= (this.apb_mst_addr  == rhs_.apb_mst_addr);

    if(apb_mst_write) begin
        if(this.apb_mst_wdata.size() != rhs_.apb_mst_wdata.size()) return 0;
        foreach(this.apb_mst_wdata[i]) ok &= (this.apb_mst_wdata[i] == rhs_.apb_mst_wdata[i]);
    end else begin
        if(this.apb_mst_rdata.size() != rhs_.apb_mst_rdata.size()) return 0;
        foreach(this.apb_mst_rdata[i]) ok &= (this.apb_mst_rdata[i] == rhs_.apb_mst_rdata[i]);
    end
`else
    ok &= (this.paddr  == rhs_.paddr);
    ok &= (this.pwdata == rhs_.pwdata);
    ok &= (this.pwrite == rhs_.pwrite);
`endif

    return ok;
endfunction

//=======================================
// do_copy
//=======================================
function void apb_mst_seq_item::do_copy(uvm_object rhs);
    this_type_t rhs_;

    if(!$cast(rhs_, rhs)) begin
        `uvm_fatal("apb_mst_SEQ_ITEM", "Object is not of type apb_mst_seq_item")
        return;
    end

    super.do_copy(rhs);

`ifndef APB_SLAVE_MODE
    this.apb_mst_error = rhs_.apb_mst_error;
    this.apb_mst_ready = rhs_.apb_mst_ready;
    this.apb_mst_addr  = rhs_.apb_mst_addr;

    if(apb_mst_write) begin
        this.apb_mst_wdata.delete();
        this.apb_mst_wdata = new[rhs_.apb_mst_wdata.size()];
        foreach(rhs_.apb_mst_wdata[i]) this.apb_mst_wdata[i] = rhs_.apb_mst_wdata[i];
    end else begin
        this.apb_mst_rdata.delete();
        this.apb_mst_rdata = new[rhs_.apb_mst_rdata.size()];
        foreach(rhs_.apb_mst_rdata[i]) this.apb_mst_rdata[i] = rhs_.apb_mst_rdata[i];
    end
`else
    this.paddr       = rhs_.paddr;
    this.pwdata      = rhs_.pwdata;
    this.pwrite      = rhs_.pwrite;
    this.preadyDelay = rhs_.preadyDelay;
`endif
endfunction

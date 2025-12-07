//
//
//
class apb_seq_item #(DW = 32, AW = 32) extends uvm_sequence_item;
//
    typedef apb_seq_item#(DW, AW) this_type_t;
    `uvm_object_param_utils(apb_seq_item#(DW, AW))

    //===================================
    // Randomized Slave Response Fields
    //===================================
    rand bit [`SLAVE_CNT-1:0] pready;
    rand bit [`SLAVE_CNT-1:0] pslverr;
    rand int preadyDelay;
    rand logic [`SLAVE_CNT-1:0][DW-1:0] prdata;
    //===================================
    // Transaction Request Fields
    //===================================
    logic [AW-1:0]  paddr;
    logic [DW-1:0]  pwdata;
    logic [`SLAVE_CNT-1:0] psel;
    logic [DW/8-1:0] pstrb;
    logic           pwrite;
    logic           penable;
    //constraint to pready and pslverr
    //constraint for 7:3 ratio
    constraint c_pready {
        foreach (pready[i]) {
            pready[i] dist {1 := 8, 0 := 2};
            // pready[i] == 1;
        }
    }
    //
    constraint c_pslverr {
        foreach (pslverr[i]) {
            pslverr[i] dist {0 := 7, 1 := 3};
            // pslverr[i] == 0;
        }
    }
    //
    constraint c_preadyDelay {
	    preadyDelay inside {[1:4]};

	}
    //===================================
    // Constructor
    //===================================
    function new(string name = "apb_seq_item");
        super.new(name);
    endfunction

    //===================================
    // UVM built-in overrides
    //===================================
    extern function void   do_print(uvm_printer printer);
    extern function string convert2string();
    extern function bit    do_compare(uvm_object rhs, uvm_comparer comparer);
    extern function void   do_copy(uvm_object rhs);

endclass : apb_seq_item

//=======================================
// do_print
//=======================================
function void apb_seq_item::do_print(uvm_printer printer);
    super.do_print(printer);

    printer.print_field("ADDR",       paddr,       $bits(paddr),       UVM_HEX);
    printer.print_field("PWRITE",     pwrite,      $bits(pwrite),      UVM_BIN);
    printer.print_field("PWDATA",     pwdata,      $bits(pwdata),      UVM_HEX);
    printer.print_field("PSEL",       psel,        $bits(psel),        UVM_HEX);
    printer.print_field("PSTRB",      pstrb,       $bits(pstrb),       UVM_HEX);
    printer.print_field("PREADY",     pready,      $bits(pready),      UVM_BIN);
    printer.print_field("PSLVERR",    pslverr,     $bits(pslverr),     UVM_BIN);
    printer.print_field("PREADY_DELAY", preadyDelay, $bits(preadyDelay), UVM_DEC);
    foreach (prdata[i]) begin
        printer.print_field($sformatf("PRDATA[%0d]", i), prdata[i], $bits(prdata[i]), UVM_HEX);
    end
endfunction

//=======================================
// convert2string
//=======================================
function string apb_seq_item::convert2string();
    string s;
    s = super.convert2string();

    s = {s, $sformatf("ADDR    : 0x%0h\n", paddr)};
    s = {s, $sformatf("WDATA   : 0x%0h\n", pwdata)};
    s = {s, $sformatf("PWRITE  : %0b\n", pwrite)};
    s = {s, $sformatf("PSEL    : 0x%0h\n", psel)};
    s = {s, $sformatf("PREADY  : 0x%0h\n", pready)};
    s = {s, $sformatf("PSLVERR : 0x%0h\n", pslverr)};
    s = {s, $sformatf("DELAY   : %0d\n", preadyDelay)};
    foreach (prdata[i]) begin
        //printer.print_field($sformatf("PRDATA[%0d]", i), prdata[i], $bits(prdata[i]), UVM_HEX);
        s = {s, $sformatf("PRDATA  : 0x%0h\n", prdata)}; // prints packed array nicely
    end

    return s;
endfunction

//=======================================
// do_compare
//=======================================
function bit apb_seq_item::do_compare(uvm_object rhs, uvm_comparer comparer);
    this_type_t rhs_;
    bit match;

    if(!$cast(rhs_, rhs)) begin
        `uvm_fatal("APB_SEQ_ITEM", "Object is not of type apb_seq_item")
        return 0;
    end

    match = super.do_compare(rhs, comparer);

    match &= (this.paddr       == rhs_.paddr);
    match &= (this.pwdata      == rhs_.pwdata);
    match &= (this.pwrite      == rhs_.pwrite);
    match &= (this.psel        == rhs_.psel);
    match &= (this.pstrb       == rhs_.pstrb);
    match &= (this.pready      == rhs_.pready);
    foreach (prdata[i]) begin
        match &= (this.prdata[i] = rhs_.prdata); // prints packed array nicely
    end
    //match &= (this.prdata      == rhs_.prdata);
    match &= (this.pslverr     == rhs_.pslverr);
   // match &= (this.preadyDelay == rhs_.preadyDelay);

    return match;
endfunction

//=======================================
// do_copy
//=======================================
function void apb_seq_item::do_copy(uvm_object rhs);
    this_type_t rhs_;

    if(!$cast(rhs_, rhs)) begin
        `uvm_fatal("apb_SEQ_ITEM", "Object is not of type apb_seq_item")
        return;
    end

    super.do_copy(rhs);

    this.paddr       = rhs_.paddr;
    this.pwdata      = rhs_.pwdata;
    this.pwrite      = rhs_.pwrite;
    this.psel        = rhs_.psel;
    this.pstrb       = rhs_.pstrb;
    this.pready      = rhs_.pready;

    foreach (prdata[i]) begin
        this.prdata[i] = rhs_.prdata; // prints packed array nicely
    end
    this.pslverr     = rhs_.pslverr;
    //this.preadyDelay = rhs_.preadyDelay;
endfunction

//===========================================================================
//--Project: AXI_TO_APB IP
//--File: axi_req_item.sv
//--Author: Nguyen Ngoc Man
//--Description: axi request channel 
//===========================================================================
class axi_req_item extends axi_data_item;
    typedef axi_req_item this_item;
    `uvm_object_utils(axi_req_item);
    //-------------------------------
    //Data Members
    //------------------------------
    rand logic [31:0] addr;
    rand logic [7:0] len;
    rand logic [2:0] size;
    rand burst_name burst;
    //constructor
    function new(string name = "axi_req_item");
      super.new(name);
    endfunction
    //----------------------------------------------------------------------
    //do_copy()
    //----------------------------------------------------------------------
    virtual function void do_copy(uvm_object rhs);
        this_item item;
        if(!$cast(item, rhs)) begin
          `uvm_error(get_type_name(), $sformatf("assign obj to item is failed!!!"))
            return;
        end
        //
        super.do_copy(item);
        this.addr = item.addr;
        this.len = item.len;
        this.size = item.size;
        this.burst = item.burst;
    endfunction
    //--------------------------------------------------------------
    //do_compare()
    //--------------------------------------------------------------
    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        this_item item;
        if(!$cast(item, rhs)) begin
          `uvm_error(get_type_name(), $sformatf("assign obj to item is failed!!!"))
            return 0;
        end
        
        do_compare = super.do_compare(item, comparer);
        do_compare &= {(item.addr == this.addr)
                        && (item.len == this.len) && (item.size == this.size) && (item.burst == this.burst)} ;
        //
        return do_compare;
    endfunction

    //-----------------------------------------------------------
    //convert2string()
    //-----------------------------------------------------------
    virtual function string convert2string();
        string s;
        s = super.convert2string();
        //
        s = {s, $sformatf("addr: 0x%08h -- len: %0d -- size: %0d -- burst: %s -- \n", addr, len, size, burst.name())};
        //
        return s;
    endfunction
        //
virtual function void do_print(uvm_printer printer);
	super.do_print(printer);
	printer.print_field("ADDR", addr, $bits(addr), UVM_HEX);
	printer.print_field("LEN", len, $bits(len), UVM_HEX);
	printer.print_field("SIZE", size, $bits(size), UVM_HEX);
	printer.print_generic("BURST", "BURST_NAME", $bits(burst), burst.name()); 
endfunction
//
virtual function void clear();
    super.clear();
	this.addr = 0;
	this.len = 0;
	this.size = 0;
	this.burst = burst_name'(2'b11);
endfunction

endclass

//-----------------------------------------------------
//-- needed information to compare
//-- shared signals between axi and apb
//----------------------------------------------------
import type_package::*;
class shared_item extends uvm_object;
    typedef shared_item this_type_item;
    `uvm_object_utils(shared_item);
    //-------------------------------
    //Data Members
    //------------------------------
    bit write;
    logic [31:0] addr;
    logic [31:0] data;
    bit [3:0] wstrb;
    resp_name resp;
    bit last;
    logic [7:0] id;
    //constructor
    function new(string name = "shared_item");
      super.new(name);
    endfunction
    //----------------------------------------------------------------------
    //do_copy()
    //----------------------------------------------------------------------
    virtual function void do_copy(uvm_object rhs);
        this_type_item item;
        if(!$cast(item, rhs)) begin
          `uvm_error(get_type_name(), $sformatf("assign obj to item is failed!!!"))
            return;
        end
        //
        super.do_copy(rhs);
        this.write = item.write;
        this.addr = item.addr;
        this.data = item.data;
        this.wstrb = item.wstrb;
        this.resp = item.resp;
        this.last = item.last;
    endfunction
    //--------------------------------------------------------------
    //do_compare()
    //--------------------------------------------------------------
    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        this_type_item item;
        if(!$cast(item, rhs)) begin
          `uvm_error(get_type_name(), $sformatf("assign obj to item is failed!!!"))
            return 0;
        end
        
        do_compare = super.do_compare(rhs, comparer);
        do_compare &= {(item.write == this.write) && (item.data == this.data) && (item.addr == this.addr)
                        && (item.wstrb == this.wstrb)};
        //do_compare &= {(rhs.write == this.write) && (rhs.data == this.data) && (rhs.addr == this.addr)
          //              && (rhs.wstrb == this.wstrb)};
                //
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
        s = {s, $sformatf("wr(1)_rd(0): %0b -- addr: 0x%08h -- data: %08h\n", write, addr, data)}; 
        s = {s, $sformatf("byteenable: %04b-- resp: %s -- last: %0b%s\n", wstrb, resp.name(), last,
                  (write == 0) ? $sformatf(" -- id = %0d", id) : "")};
        //
        return s;
    endfunction
        //
virtual function void do_print(uvm_printer printer);
	super.do_print(printer);
	printer.print_field("WR(1)_RD(0)", write, $bits(write), UVM_BIN);
	printer.print_field("ADDR", addr, $bits(addr), UVM_HEX);
	//
	printer.print_field("WSTRB", wstrb, $bits(wstrb), UVM_HEX);
	printer.print_field("DATA", data, $bits(data), UVM_HEX);
	printer.print_generic("RESP", "RESP_NAME", $bits(resp), resp.name()); 
	printer.print_field("LAST", last, $bits(last), UVM_BIN);
endfunction
//
function void clear();
	this.write = 0;
	this.addr = 0;
	this.data = 0;
	this.wstrb = 0;
	this.last = 0;
	this.id = 0;
	this.resp = resp_name'(2'b00);
endfunction

endclass

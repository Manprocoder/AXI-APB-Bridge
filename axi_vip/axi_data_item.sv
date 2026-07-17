//===========================================================================
//--Project: AXI_TO_APB IP
//--File: axi_data_item.sv
//--Author: Nguyen Ngoc Man
//--Description: AXI data channel 
//===========================================================================
class axi_data_item extends axi_brsp_item;
    typedef axi_data_item this_type_item;
    `uvm_object_utils(axi_data_item);
    //-------------------------------
    //Data Members
    //------------------------------
    rand logic wr_or_rd;
    rand logic [31:0] data;
    rand bit [3:0] be;
    rand bit last;
    //constructor
    function new(string name = "axi_data_item");
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
        super.do_copy(item);
        this.wr_or_rd = item.wr_or_rd;
        this.data = item.data;
        this.be = item.be;
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
        
        do_compare = super.do_compare(item, comparer);
        do_compare &= {(item.wr_or_rd == this.wr_or_rd) && (item.data == this.data) 
                        && (item.be == this.be) && (item.last == this.last)} ;
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
        s = {s, $sformatf("wr(1)_rd(0): %0b -- data: %08h\n", wr_or_rd, data)}; 
        s = {s, $sformatf("byteenable: %04b-- last: %0b\n", be, last)};
        //
        return s;
    endfunction
        //
virtual function void do_print(uvm_printer printer);
	super.do_print(printer);
	printer.print_field("WR(1)_RD(0)", wr_or_rd, $bits(wr_or_rd), UVM_BIN);
	//
	printer.print_field("DATA", data, $bits(data), UVM_HEX);
	printer.print_field("BYTE_EN", be, $bits(be), UVM_HEX);
	printer.print_field("LAST", last, $bits(last), UVM_BIN);
endfunction
//
virtual function void clear();
    super.clear();
	this.wr_or_rd = 0;
	this.data = 0;
	this.be = 0;
	this.last = 0;
endfunction

endclass

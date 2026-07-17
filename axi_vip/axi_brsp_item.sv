//===========================================================================
//--Project: AXI_TO_APB IP
//--File: axi_brsp_item.sv
//--Author: Nguyen Ngoc Man
//--Description: Write Response channel 
//===========================================================================
class axi_brsp_item extends uvm_sequence_item;
    typedef axi_brsp_item this_item;
    `uvm_object_utils(axi_brsp_item);
    //-------------------------------
    //Data Members
    //------------------------------
    rand logic [7:0] id;
    rand resp_name resp;
    //constructor
    function new(string name = "axi_brsp_item");
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
        //super.do_copy(rhs);
        this.id = item.id;
        this.resp = item.resp;
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
        
        do_compare = 1'b1;//super.do_compare(rhs, comparer);
        do_compare &= {(item.id == this.id) && (item.resp == this.resp)};
        //
        return do_compare;
    endfunction

    //-----------------------------------------------------------
    //convert2string()
    //-----------------------------------------------------------
    virtual function string convert2string();
        string s;
        //s = super.convert2string();
        s = {s, $sformatf("ID: %0d -- RESP: %s\n", id, resp.name())}; 
        return s;
    endfunction
        //
virtual function void do_print(uvm_printer printer);
//	super.do_print(printer);
	printer.print_field("ID", id, $bits(id), UVM_HEX);
	printer.print_generic("RESP", "RESP_NAME", $bits(resp), resp.name()); 
endfunction
//
virtual function void clear();
	this.id = 0;
	this.resp = resp_name'(2'b00);
endfunction

endclass

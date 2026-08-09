//===========================================================================
//--Project: AXI_TO_APB IP
//--File: axi_seq_item.sv
//--Author: Nguyen Ngoc Man
//--Description:  
//===========================================================================
class axi_transaction #(DW = 32, AW= 32) extends axi_req_item;
    typedef axi_transaction#(DW, AW) this_item;
    `uvm_object_param_utils(this_item)
    //
    rand bit is_valid;
    //
    rand bit rst_run_time_enable;
    rand bit reset;
    rand bit [2:0] rst_low_delay;
    rand bit [7:0] rst_high_delay;
    //
    rand bit [2:0] prot;
    rand bit [DW-1:0] data_arr [];
    rand bit [3:0] wstrb [];
    //
    //
    //---------RESET CONSTRAINT-----------
    //
    constraint reset_c {
        reset dist {1:= 9, 0:=1};
    }
    constraint rst_low_delay_c {
        rst_low_delay inside {[1:$]};
    }
    //
    constraint rst_high_delay_c {
        rst_high_delay inside {[200:$]};
    }
    //
    //--------THE REST OF SIGNALS CONSTRAINT
    //
    constraint is_valid_c {
        is_valid dist {1:=7, 0:=3};
    }
    //
    constraint burst_type {
        if(long_low_rready == 1'b1) {
            burst == INCR;
        }
        else {
            burst inside {FIXED, INCR, WRAP};
        }
    }
    //
    constraint data_arr_array {
        //solve order constraints
        solve len before data_arr;
        //  rand variable constraints
        data_arr.size() == len+1;
        // unique{data_arr};  //be careful to use, specially len is large and DW = 32 bits 
        //---=> randomization fails because there are too much possibilities
        //
    }
    //
    constraint wstrb_array {
        //solve order constraints
        //--size
        solve len before wstrb;
        //--unaligned addr
        //(1)
        solve addr before wstrb;
        //(2)
        solve burst before wstrb;

        //rand variable constraints
        wstrb.size() == len+1;
        //
        foreach (wstrb[i]) {
                if((burst == INCR) && (addr[1:0] != 2'b00)) {
                    if(i==0)
                        wstrb[i] inside {(4'hf << addr[1:0]) & 4'hf};
                    else {
                        wstrb[i] != 4'h0;
                    }
                }
                else {
                   wstrb[i] != 4'h0; 
                }
        }//end of foreach
    }
    //
    constraint len_c{
    //
        solve burst before len;
            //
        if (burst == WRAP || burst == FIXED)
            len inside {1,3,7,15};
        else { 
            if(long_low_rready == 1'b1) {
                len == 255;
            }
            else {
                len inside {[0:255]};
            }
        }//end of WRAP || FIXED
    }//end of len_c

    //
    constraint addr_c{
        solve is_valid before addr;
        solve size, len before addr;
        solve burst before addr;
        // constrain addr into valid slave ranges
        if(is_valid) {
            //supported valid range of address
            addr inside { [32'h0000_0000 : 32'h0000_0000 + `SLAVE_CNT*4096] };
            //
            if(burst == FIXED || burst == WRAP) {
                addr[1:0] dist {2'b00:=7, 2'b01:=1, 2'b10:=1, 2'b11:=1};
            }
            else {
                addr[1:0] dist {2'b00:=1, 2'b01:=1, 2'b10:=1, 2'b11:=1};
            }
        }
        else {
            !(addr inside { [32'h0000_0000 : 32'h0000_0000 + `SLAVE_CNT*4096] });// 
        }
        //
    }
    //
    constraint long_low_rready_c{
        long_low_rready dist {1'b0:=8, 1'b1:=2};
    }
    //
    //constraint slv_idx_c{
        //solve addr before slv_idx;
        ////
        //slv_idx == {(addr>>12) & 32'h0000_000f};
    //}
    //

    //
    //Group(1)
    extern function void set_id(bit [7:0] actual_id);
    extern function void set_aligned_addr();
    extern function void set_bytes_in_beat(logic [2:0] number);
    //
    //Group(2)
    extern function void do_print(uvm_printer printer);
    extern function string convert2string();
    extern function void do_copy(uvm_object rhs);
    extern function bit do_compare(uvm_object rhs, uvm_comparer comparer);

    function new(string name = "axi transaction");
        super.new(name);
    endfunction 

endclass 

/*----------------------------------------------------------------------------*/
/*  Functions                                                                 */
/*----------------------------------------------------------------------------*/
//Group(1)
function void axi_transaction::set_id(bit [7:0] actual_id);
	this.id = actual_id;
endfunction
//
function void axi_transaction::set_aligned_addr();
	this.addr[1:0] = 2'b00;
endfunction
//
function void axi_transaction::set_bytes_in_beat(logic [2:0] number);
begin
this.size = number; //only support 4_bytes_in_transfer
end
endfunction
//
//
//Group(2)
function void axi_transaction::do_print(uvm_printer printer);
    //super.do_print(printer);
//    printer.print_field("SLV_IDX", slv_idx, $bits(slv_idx), UVM_UNSIGNED);
    printer.print_field("ID", id, $bits(id), UVM_UNSIGNED);
    printer.print_field("Addr", addr, $bits(addr), UVM_HEX);
    //
    printer.print_generic("Burst Length", "BEATS IN TOTAL", $bits(len), $sformatf("%0d beat", len+1));
    printer.print_generic("Burst Size", "SIZE IN BEAT", $bits(size), $sformatf("%0d byte", 2**size));
    printer.print_field("LOW_RREADY_EN", long_low_rready, $bits(long_low_rready), UVM_BIN);    printer.print_generic("Burst Name", "BURST NAME", $bits(burst), burst.name()); 
    for (int i = 0; i < len+1; i++) begin : DATA_PRINT
        printer.print_generic("Data-Wstrb", "", "-1", $sformatf("Data[%0d] = %0h --- wstrb[%0d] = %0b", i, data_arr[i], i, wstrb[i]));
    end

  //
endfunction: do_print

function string axi_transaction::convert2string();
    string s;
    s = {s, $sformatf("SLV_IDX        :   %0d\n", slv_idx)};
    s = {s, $sformatf("ID             :   %0d\n", id)};
    s = {s, $sformatf("Addr           : 0x%0h\n", addr)};
    for (int i =0; i< len+1; i++) begin
        s = {s, $sformatf("DATA[%0d]: %0h --- wstrb[%0d]: %0b\n", i, data_arr[i], i, wstrb[i])};
    end
    s = {s, $sformatf("Busrt Type     :   %s\n", burst.name())};
    s = {s, $sformatf("Burst Size     :   %0d\n", size)};
    s = {s, $sformatf("Busrt Length   :   %0d\n", len+1)};
    return s;
endfunction: convert2string

function void axi_transaction::do_copy(uvm_object rhs);
    this_item rhs_;
    //
    if (!$cast(rhs_, rhs)) begin
        `uvm_error({this.get_name(), ".do_copy()"}, "Cast failed!");
        return;
    end
    //chain the copy with parent classes
    //super.do_copy(rhs);
    //list of local properties to be copied
    this.slv_idx = rhs_.slv_idx;
    this.id     = rhs_.id;
    this.addr   = rhs_.addr;
    this.len    = rhs_.len;
    this.size   = rhs_.size;
    this.burst  = rhs_.burst;
    this.prot  = rhs_.prot;
    foreach(data_arr[i]) begin
        this.data_arr[i]   = rhs_.data_arr[i];
        this.wstrb[i]  = rhs_.wstrb[i];
    end
endfunction: do_copy

function bit axi_transaction::do_compare(uvm_object rhs, uvm_comparer comparer);
    this_item rhs_;

    if (!$cast(rhs_, rhs)) begin
        `uvm_error({this.get_name(), ".do_compare()"}, "Cast failed!");
        return 0;
    end

    do_compare = 1'b1; // super.do_compare(rhs, comparer);

    do_compare &= (
        this.id  == rhs_.id &&
        this.addr == rhs_.addr &&
        this.burst == rhs_.burst &&
        this.size  == rhs_.size &&
        this.len   == rhs_.len
    );

    foreach(data_arr[i]) begin
        do_compare &= this.data_arr[i] == rhs_.data_arr[i];
    end

    foreach(wstrb[i]) begin
        do_compare &= this.wstrb[i] == rhs_.wstrb[i];
    end
endfunction: do_compare

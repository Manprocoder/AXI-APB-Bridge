import type_package::*;
//uvm object
class axi_transaction #(DW = 32, AW= 32) extends uvm_sequence_item;
    typedef axi_transaction#(DW, AW) this_type_t;
    `uvm_object_param_utils(axi_transaction#(DW, AW))
    //
    rand bit is_valid;
    //
    rand bit rst_run_time_enable;
    rand bit reset;
    rand bit [2:0] rst_low_delay;
    rand bit [7:0] rst_high_delay;
    //
    rand logic [7:0] id; //
    rand logic [AW-1:0] addr;
    rand bit [7:0] len;
    rand bit [2:0] size;// = 3'b010; //word
    rand bit [2:0] prot;
    rand burst_name burst;
    rand bit [DW-1:0] data [];
    rand bit [3:0] wstrb [];
    bit last [];
    resp_name bresp;
    bit [7:0] bid;
    resp_name rresp [];
    bit [7:0] rid [];
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
        is_valid dist {1:=8, 0:=2};
    }
    //
    //
    constraint data_array {
        //solve order constraints
        solve len before data;
        //  rand variable constraints
        data.size() == len+1;
        // unique{data};  //be careful to use, specially len is large and DW = 32 bits 
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
            if(addr[1:0] == 2'b00) //aligned address
                wstrb[i] == 4'hf;
            else { //unaligned address
                if(burst == INCR) {
                    if(i==0)
                        wstrb[i] inside {(4'hf << addr[1:0]) & 4'hf};
                    else {
                        wstrb[i] == 4'hf;
                    }
                }
                else {
                   wstrb[i] == 4'hf; 
                }
            } //end of else of if(addr[1:0] == 2'b00)
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
		len inside {[0:255]};
        }
    }

    //
    constraint addr_c{
        solve is_valid before addr;
        solve size, len before addr;
        solve burst before addr;
        // constrain addr into valid slave ranges
        if(is_valid) {
            //supported valid range of address
            addr inside { [32'h0000_0000 : 32'h0000_0000 + `SLAVE_CNT*4096] } && 
            ((addr % 32'd4096) + ((2**size)*(len+1)) <= 32'd4096); //4kb boundary
            //must-aligned address
            if(burst == FIXED || burst == WRAP) {
                addr[1:0] == 2'b00;
            }
            else {
                addr[1:0] dist {2'b00:=1, 2'b01:=1, 2'b10:=1, 2'b11:=1};
            }
        }
        else {
            !(addr inside { [32'h0000_0000 : 32'h0000_0000 + `SLAVE_CNT*4096] });// && addr <= 32'h0001_2000);
        }
        //
    }
    //
    //
    //Group(1)
    extern function void set_id(bit [7:0] actual_id);
    extern function void set_aligned_addr();
    extern function void set_bytes_in_beat();
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
function void axi_transaction::set_bytes_in_beat();
begin
this.size = 3'b010; //only support 4_bytes_in_transfer
end
endfunction
//
//
//Group(2)
function void axi_transaction::do_print(uvm_printer printer);
    super.do_print(printer);
    /*  list of local properties to be printed:  */
    printer.print_field("ID", id, $bits(id), UVM_UNSIGNED);
    printer.print_field("Addr", addr, $bits(addr), UVM_HEX);
  //
  printer.print_generic("Burst Length", "BEATS IN TOTAL", $bits(len), $sformatf("%0d beat", len+1));
  printer.print_generic("Burst Size", "SIZE IN BEAT", $bits(size), $sformatf("%0d byte", 2**size));
  printer.print_generic("Burst Name", "BURST NAME", $bits(burst), burst.name()); 
  for (int i = 0; i < len+1; i++) begin : DATA_PRINT
    printer.print_generic("Data-Wstrb", "", "-1", $sformatf("Data[%0d] = %0h --- wstrb[%0d] = %0b", i, data[i], i, wstrb[i]));
end
  //
endfunction: do_print

function string axi_transaction::convert2string();
    string s;

    /*  chain the convert2string with parent classes  */
    s = super.convert2string();

    /*  list of local properties to be printed:  */
    //  guide             0---4---8--12--16--20--24--28--32--36--40--44--48--
    s = {s, $sformatf("ID             :   %0d\n", id)};
    s = {s, $sformatf("Addr           : 0x%0h\n", addr)};
    for (int i =0; i< len+1; i++) begin
        s = {s, $sformatf("DATA[%0d]: %0h --- wstrb[%0d]: %0b\n", i, data[i], i, wstrb[i])};
    end
    s = {s, $sformatf("Busrt Type     :   %s\n", burst.name())};
    s = {s, $sformatf("Burst Size     :   %0d\n", size)};
    s = {s, $sformatf("Busrt Length   :   %0d\n", len+1)};
    // s = {s, $sformatf("Busrt Bresp     :   %0b\n", bresp)};
    // s = {s, $sformatf("Read resp      :   %0b\n", rresp)};
    return s;
endfunction: convert2string

function void axi_transaction::do_copy(uvm_object rhs);
    this_type_t rhs_;
    //
    if (!$cast(rhs_, rhs)) begin
        `uvm_error({this.get_name(), ".do_copy()"}, "Cast failed!");
        return;
    end
    //chain the copy with parent classes
    super.do_copy(rhs);
    //list of local properties to be copied
    this.id     = rhs_.id;
    this.addr   = rhs_.addr;
    this.len    = rhs_.len;
    this.size   = rhs_.size;
    this.burst  = rhs_.burst;
    this.prot  = rhs_.prot;
    foreach(data[i]) begin
        this.data[i]   = rhs_.data[i];
        this.wstrb[i]  = rhs_.wstrb[i];
        // this.rresp[i]  = rhs_.rresp[i];
    end
    // this.bresp  = rhs_.bresp;
endfunction: do_copy

function bit axi_transaction::do_compare(uvm_object rhs, uvm_comparer comparer);
    this_type_t rhs_;

    if (!$cast(rhs_, rhs)) begin
        `uvm_error({this.get_name(), ".do_compare()"}, "Cast failed!");
        return 0;
    end

    /*  chain the compare with parent classes  */
    do_compare = super.do_compare(rhs, comparer);

    /*  list of local properties to be compared:  */
    do_compare &= (
        this.id  == rhs_.id &&
        this.addr == rhs_.addr &&
        this.burst           == rhs_.burst &&
        this.size            == rhs_.size &&
        this.len             == rhs_.len
        // this.bresp           == rhs_.bresp 
    );

    foreach(data[i]) begin
        do_compare &= this.data[i] == rhs_.data[i];
    end

    foreach(wstrb[i]) begin
        do_compare &= this.wstrb[i] == rhs_.wstrb[i];
    end
    //
    // foreach ( rresp[i] ) begin
        // do_compare &= this.rresp[i] == rhs_.rresp[i];
    // end
    
endfunction: do_compare

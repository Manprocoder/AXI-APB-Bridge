//===========================================================================
//--Project: AXI_TO_APB IP
//--File: axi_ready_signal_item.sv
//--Author: Nguyen Ngoc Man
//--Description:  
//===========================================================================
class axi_ready_signal_item extends uvm_sequence_item;
    `uvm_object_utils(axi_ready_signal_item)
    //
    rand bit rdy;
    rand int counter;
    rand bit [1:0] case_of_cnt;
    //
    constraint rdy_c {rdy dist {1:= 80, 0:= 20};}
    //
    constraint case_of_cnt_c {case_of_cnt dist {2'd0:= 20, 2'd1:= 20, 2'd2:= 60, 2'd3:= 0};}
    //
    constraint cnt_c {
        solve case_of_cnt before counter;
        //
        if(case_of_cnt == 2'd0) {
            counter inside {[0:15]};
        }
        else if(case_of_cnt == 2'd1) {
            counter inside {[0:255]};
        }
        else {
            counter inside {[256:512]};//fifo of read_data channel has 256 locations
        }
    }//end of cnt_c
    //
    function new(string name = "axi_ready_signal_item");
        super.new(name);
    endfunction
    //
    function void do_print(uvm_printer printer);
        printer.print_field("READY", rdy, $bits(rdy), UVM_BIN);
        printer.print_field("case of counter", case_of_cnt, $bits(case_of_cnt), UVM_BIN);
        printer.print_generic("Counter", "", $bits(counter), $sformatf("%0d", counter));
    endfunction: do_print
endclass

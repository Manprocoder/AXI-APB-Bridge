//************************************************************
//--Project: AXI APB IP 
//************************************************************
//--file: common_sequence.sv
//--Author: Nguyen Ngoc Man
//************************************************************
//--Description: test normal write/read transaction 
//***********************************************************
import axi_pkg::*;
//
//--------------------------------AXI MASTER WRITE----------------------------------
//
class AxiMasterWriteSeq #(DW1, AW1) extends stimulus_generator;
    //register UVM factory
    `uvm_object_param_utils(AxiMasterWriteSeq#(DW1, AW1))
    // Constructor
    function new (string name = "AxiMasterWriteSeq");
        super.new(name);
    endfunction
    extern function void gen_item(); 
    extern task body();

endclass
  
//main tasks in sequence
function void AxiMasterWriteSeq::gen_item();
    mb = new(no_test);
    repeat(no_test) begin
        trans_h = axi_item::type_id::create("axi_item");
        //
        assert(trans_h.randomize())
        else `uvm_error(get_type_name(), "[WRITE]randomize axi_item FAILED")
        if(!mb.try_put(trans_h)) `uvm_error(get_type_name, "try_put item into mb FAIL!!!");
    end
endfunction
//-- body()
//
task AxiMasterWriteSeq::body();
`uvm_info(get_name(), $sformatf("WRITE no_test = %0d", no_test), UVM_LOW);
    repeat(no_test) begin
      // wait_for_grant();
      //send_request(trans_h); //must pair wait_for_grant()
          trans_h = axi_item::type_id::create("axi_w_trans");

       if(mb.try_get(trans_h)) begin
	      //send item to sequencer
	      start_item(trans_h); //block until wait_for_grant from sequencer 
	      trans_h.set_bytes_in_beat(3'b010);
	      finish_item(trans_h);
      end
      else begin
		`uvm_fatal(get_name(), $sformatf("wr_stimulus not available!!!"))
      end
    end
endtask

//--------------AXI MASTER READ-------------------------
//
class AxiMasterReadSeq#(DW1,AW1) extends stimulus_generator;
  `uvm_object_param_utils(AxiMasterReadSeq#(DW1,AW1))
  //
    logic [7:0] r_id;
    //
    function new(string name = "read transaction");
        super.new(name);
    endfunction 
    //
    extern function void gen_item();
    extern task body();
endclass
//

function void AxiMasterReadSeq::gen_item();
    mb = new(no_test);
    repeat(no_test) begin
        trans_h = axi_item::type_id::create("axi_item");
        //
        trans_h.data_arr_c.constraint_mode(0);
        trans_h.wstrb_arr_c.constraint_mode(0);
        //
        assert(trans_h.randomize())
        else `uvm_error(get_type_name(), "[READ_]randomize axi_item FAILED")
        if(!mb.try_put(trans_h)) `uvm_error(get_type_name, "try_put item into mb FAIL!!!");
    end
endfunction
//
task AxiMasterReadSeq::body();
	r_id = 0;
	`uvm_info(get_name(), $sformatf("RD no_test = %0d", no_test), UVM_LOW);
	repeat(no_test) begin:RD_RPT
	      //r_mb.get(tmp);
	      //trans_h.copy(tmp); 
	      //start_item does not recognize mailbox's element; therefore, we use copy() method to create new object
	      //
	      trans_h = axi_item::type_id::create("axi_r_trans");
	      if(mb.try_get(trans_h)) begin
		      //send item to sequencer
			`uvm_info(get_type_name(), $sformatf("[START]trans_h!!!"), UVM_HIGH);
		      start_item(trans_h);
		      trans_h.set_bytes_in_beat(3'b010);
		      if(reconfigure_id) begin
			      trans_h.set_id(r_id);
		      end
		      trans_h.set_aligned_addr();
		      //item sent to driver done
		      finish_item(trans_h);
			`uvm_info(get_type_name(), $sformatf("[DONE]trans_h!!!"), UVM_HIGH);
		      r_id++;
      	      end
	      else begin
		`uvm_fatal(get_name(), $sformatf("rd_stimulus unavailable!!!"))
	      end
	end: RD_RPT
endtask

//************************************************************
//--Project: AXI APB IP 
//************************************************************
//--file: dec_err_seq.sv
//--Author: Nguyen Ngoc Man
//************************************************************
//--Description: test decode err response of AXI4  
//***********************************************************
import axi_pkg::*;
class dec_err_seq extends stimulus_generator;
	`uvm_object_utils(dec_err_seq)
	//
	function new (string name = "dec_err_seq");
		super.new(name);
	endfunction
	//
 	function void gen_item();
		mb = new();
		//
		repeat(no_test) begin
			trans_h = axi_item::type_id::create("axi_item");
			assert(trans_h.randomize() with {
				trans_h.size == 3'b010;
				trans_h.is_valid == 1'b0;
				})
			else `uvm_error(get_type_name(), "randomize axi_item FAILED")
			//mb.put(trans_h);
			if(!mb.try_put(trans_h)) `uvm_error(get_type_name, "try_put item into mb FAIL!!!");
		end
	endfunction
	//
	task body();
		repeat(no_test) begin
		      trans_h = axi_item::type_id::create("axi_trans");
		      if(mb.try_get(trans_h)) begin
			      //send item to sequencer
				`uvm_info(get_type_name(), $sformatf("[START]trans_h!!!"), UVM_HIGH);
			      start_item(trans_h);
			      trans_h.set_aligned_addr();
			      //item sent to driver done
			      finish_item(trans_h);
				`uvm_info(get_type_name(), $sformatf("[DONE]trans_h!!!"), UVM_HIGH);
			end
			else begin
				`uvm_fatal(get_type_name(), "transaction is UNAVAILABLE")
			end
      		end
	endtask
endclass

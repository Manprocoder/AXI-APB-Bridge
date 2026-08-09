//==========================================================
//--Project: Design and Verify AXI_APB bridge
//==========================================================
//--file: rdata_almost_full_seq.sv
//--Author: Nguyen Ngoc Man
//==========================================================
//--Description: 
//==========================================================
class rdata_almost_full_seq extends stimulus_generator;
	`uvm_object_utils(rdata_almost_full_seq)
	//members
	function new(string name = "rdata_almost_full_seq");
		super.new(name);
	endfunction
	//
	function void gen_item();
		mb = new(no_test);
		//
		repeat(no_test) begin
			trans_h = axi_item::type_id::create("axi_item");
			assert(trans_h.randomize() with {
				trans_h.size == 3'b010;
				trans_h.is_valid == 1'b1;
                trans_h.long_low_rready == 1'b1;
				})
			else `uvm_error(get_type_name(), "randomize axi_item FAILED")
			if(!mb.try_put(trans_h)) `uvm_error(get_type_name, "try_put item into mb FAIL!!!");
            //
            `uvm_info(get_name(), "PRINT RDATA_ALMOST_FULL transaction", UVM_LOW)
            trans_h.print();
		end
	endfunction
	//
	virtual task body();
		repeat(no_test) begin
		      trans_h = axi_item::type_id::create("axi_trans");
		      if(mb.try_get(trans_h)) begin
			      //send item to sequencer
				`uvm_info(get_type_name(), $sformatf("[START]trans_h!!!"), UVM_HIGH);
			      start_item(trans_h);
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
//
//


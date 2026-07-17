//************************************************************
//--file: common_sequence.sv
//--function: AXI UVM sequence
//--Author: Nguyen Ngoc Man
//--Description: that includes 3 types of sequence
//--+: Base sequence: burst, addr, id are setup by user
//--+: Random sequence
//--+: Random sequence with user-defined length
//***********************************************************
//**********************************************************
//--------------------BASE SEQUENCE---------------
//**********************************************************
//
import axi_pkg::*;
//this class takes responsibility for generating stimulus
typedef axi_transaction#(DW1,AW1) axi_item;
//
class stimulus_generator extends uvm_sequence#(axi_item); 
	`uvm_object_utils(stimulus_generator)
	//
	mailbox #(axi_item) mb;
	axi_item trans_h;
	int total_no_test;
        bit reconfigure_id;
	//
	function new(string name = "stimulus_generator");
		super.new(name);
	endfunction
	//
	virtual function void gen_item();
		mb = new(total_no_test);
		//mb = new();
		repeat(total_no_test) begin
			trans_h = axi_item::type_id::create("axi_item");
			assert(trans_h.randomize())
			else `uvm_error(get_type_name(), "randomize axi_item FAILED")
			if(!mb.try_put(trans_h)) `uvm_error(get_type_name, "try_put item into mb FAIL!!!");
		end
	endfunction
	//
endclass
//**********************************************************************************
//
//**********************************************************************************
//
//--------------------------------AXI MASTER WRITE----------------------------------
//
//class AxiMasterWriteSeq #(DW1, AW1) extends uvm_sequence#(axi_transaction #(DW1,AW1));
class AxiMasterWriteSeq #(DW1, AW1) extends stimulus_generator;
    //register UVM factory
    `uvm_object_param_utils(AxiMasterWriteSeq#(DW1, AW1))
    int no_test;
    // Constructor
    function new (string name = "AxiMasterWriteSeq");
        super.new(name);
    endfunction

    extern virtual task body();

endclass
  
//main tasks in sequence
    
//-- body()
//
task AxiMasterWriteSeq::body();
`uvm_info(get_type_name(), $sformatf("WRITE no_test = %0d", no_test), UVM_LOW);
    repeat(no_test) begin
      // wait_for_grant();
      //send_request(trans_h); //must pair wait_for_grant()
              trans_h = axi_item::type_id::create("axi_w_trans");

       if(mb.try_get(trans_h)) begin
	      //send item to sequencer
	      start_item(trans_h); //block until get_next_item() from driver
	      trans_h.set_bytes_in_beat(3'b010);
	      finish_item(trans_h);
      end
      else begin
		`uvm_fatal(get_type_name(), $sformatf("wr_stimulus not available!!!"))
      end
    end
endtask

//--------------AXI MASTER READ-------------------------
//
class AxiMasterReadSeq#(DW1,AW1) extends stimulus_generator;
  `uvm_object_param_utils(AxiMasterReadSeq#(DW1,AW1))
  //
    logic [7:0] r_id;
    int no_test;
    //
    function new(string name = "read transaction");
        super.new(name);
    endfunction 
    //
    extern virtual task body();
endclass
//
//
task AxiMasterReadSeq::body();
	r_id = 0;
	`uvm_info(get_type_name(), $sformatf("RD no_test = %0d", no_test), UVM_LOW);
	repeat(no_test) begin
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
		`uvm_fatal(get_type_name(), $sformatf("rd_stimulus unavailable!!!"))
	      end
	end
endtask
//
//Test_Response Sequence
//
class rsp_seq extends stimulus_generator;
	`uvm_object_utils(rsp_seq)
	//
	int no_test_slverr1;	
	int no_test_slverr2;	
	int no_test_decerr;	
	//
	function new (string name = "response seq");
		super.new(name);
	endfunction
	//
 	function void gen_item();
		mb = new();
		//disallowed size
		repeat(no_test_slverr1) begin
			trans_h = axi_item::type_id::create("axi_item");
			assert(trans_h.randomize() with {
				trans_h.size != 3'b010;
				trans_h.is_valid == 1'b1;
				})
			else `uvm_error(get_type_name(), "randomize axi_item FAILED")
			//mb.put(trans_h);
			if(!mb.try_put(trans_h)) `uvm_error(get_type_name, "try_put item into mb FAIL!!!");
		end
		//unaligned addr for WRAP, FIXED 
		repeat(no_test_slverr2) begin
			trans_h = axi_item::type_id::create("axi_item");
			assert(trans_h.randomize() with {
				trans_h.size == 3'b010;
				trans_h.is_valid == 1'b1;
				trans_h.burst != INCR;
				trans_h.addr[1:0] != 2'b00;
				})
			else `uvm_error(get_type_name(), "randomize axi_item FAILED")
			//mb.put(trans_h);
			if(!mb.try_put(trans_h)) `uvm_error(get_type_name, "try_put item into mb FAIL!!!");
		end

		//
		repeat(no_test_decerr) begin
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
	virtual task body();
		repeat(no_test_slverr1 + no_test_slverr2 + no_test_decerr) begin
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
//test unaligned address 
class unaligned_addr_seq extends stimulus_generator;
	`uvm_object_utils(unaligned_addr_seq)
	//members
	function new(string name = "unaligned addr");
		super.new(name);
	endfunction
	//
	function void gen_item();
		mb = new(total_no_test);
		//
		repeat(total_no_test) begin
			trans_h = axi_item::type_id::create("axi_item");
			assert(trans_h.randomize() with {
				trans_h.size == 3'b010;
				trans_h.is_valid == 1'b1;
				trans_h.burst == INCR;
				trans_h.addr[1:0] != 2'b00;
				})
			else `uvm_error(get_type_name(), "randomize axi_item FAILED")
			if(!mb.try_put(trans_h)) `uvm_error(get_type_name, "try_put item into mb FAIL!!!");
		end
	endfunction
	//
	virtual task body();
		repeat(total_no_test) begin
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


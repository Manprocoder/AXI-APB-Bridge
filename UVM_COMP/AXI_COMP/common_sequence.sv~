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
import type_package::*;
//
//this class takes responsibility for generating stimulus
//
class stimulus_generator extends uvm_object; 
	`uvm_object_utils(stimulus_generator)
	//
	axi_transaction #(DW,AW1) w_trans_q [$];
	axi_transaction #(DW,AW1) r_trans_q [$];
	//mailbox #(axi_transaction #(DW,AW1)) r_mb;
	axi_transaction#(DW,AW1) w_trans, r_trans, tmp;
	int w_test_nums, r_test_nums;
	int idx;
	logic [7:0] start_id;
	//test_plot test_plot_h;
	//
	//
	function new(string name = "stimulus_generator");
		super.new(name);
	endfunction
	//
	//
	virtual task generate_wr_item();
		`uvm_info(get_type_name(), $sformatf("w_test_nums = %0d", w_test_nums), UVM_LOW);
		start_id = 0;
	 	repeat(w_test_nums) begin
		      w_trans = axi_transaction#(DW,AW1)::type_id::create("axi_wr_stimulus");
		      assert(w_trans.randomize()with{
				w_trans.burst inside {FIXED, INCR, WRAP};
				w_trans.id == start_id;
			})else 
		      $error("[WRITE]Randomization failed for Stimulus_Generator object!!! [addr=0x%08h burst=%s id=%0d]",
		      w_trans.addr, burst_name'(w_trans.burst), start_id);
		      //put generated item into queue
			w_trans_q.push_back(w_trans);
			//
			start_id++;
		end
	endtask
	//
	//
	virtual task generate_rd_item();
		`uvm_info(get_type_name(), $sformatf("r_test_nums = %0d", r_test_nums), UVM_LOW);
		start_id = 0;
	 	repeat(r_test_nums) begin
		      r_trans = axi_transaction#(DW,AW1)::type_id::create("axi_rd_stimulus");
		      assert(r_trans.randomize()with{
				r_trans.burst inside {FIXED, INCR, WRAP};
				r_trans.id == start_id;
			})else 
		      $error("[READ]Randomization failed for Stimulus_Generator object!!! [addr=0x%08h burst=%s id=%0d]",
		      r_trans.addr, burst_name'(r_trans.burst), start_id);
		      //put generated item into queue
			r_trans_q.push_back(r_trans);
			//
			start_id++;
		end
	endtask
	//
	//
	virtual task clone_wr_into_rd();
		idx = 0;
		`uvm_info(get_type_name(), $sformatf("r_test_nums = %0d", r_test_nums), UVM_LOW);
	 	repeat(r_test_nums) begin
		      tmp = axi_transaction#(DW,AW1)::type_id::create("tmp_stimulus");
			if(w_trans_q.size() == 0) begin
				if(idx == 0) begin
					`uvm_warning(get_type_name(), $sformatf("[CLONE_WR_INTO_RD]: EMPTY w_trans_q!!!"))
				end
				break;
			end
			//
			tmp = w_trans_q[idx];//access item without removing it from queue 
			$cast(r_trans, tmp.clone());
			r_trans_q.push_back(r_trans);
			idx++;
		end
	endtask	
	//
	//
	//virtual task make_plot();
		//idx = 0;
		//`uvm_info(get_type_name(), $sformatf("r_test_nums = %0d", r_test_nums), UVM_LOW);
	 	//repeat(r_test_nums) begin
		      //tmp = axi_transaction#(DW,AW1)::type_id::create("tmp_stimulus");
		      ////r_trans = axi_transaction#(DW,AW1)::type_id::create("axi_rd_stimulus");
		      ////
		      //case(test_plot_h)
		      //R_W_PARALLEL: begin
			      //if(w_trans_q.size() > 0) begin 
					//tmp = w_trans_q[idx];//access item without removing it from queue 
					////
					////CRITICAL NOTE: Not having used clone() leads to no operation of read sequence  
					//if(!$cast(r_trans, tmp.clone())) begin
					////if(!$cast(r_trans, tmp)) begin
						//`uvm_error(get_type_name(), "r_trans NULL");
					//end 
					////here: we use clone() method to
					////-- create independent object r_trans
					////--called "DEEP COPY"
					////other way to implement is: using
					////copy method
					////r_trans.copy(tmp); 
					////use copy() method to create independent object "r_trans"
					////--and avoid the risk of object overlapping
					////
					//repeat(2) begin
						//r_trans_q.push_back(r_trans);
					////	`uvm_info(get_type_name(), $sformatf("succeed to create rd stimulus!!!"), UVM_LOW);
					//end
					//idx++;
					//if(idx == w_trans_q.size()) break;
					////`uvm_info(get_type_name(), $sformatf("succeed to create rd stimulus!!!"), UVM_LOW);
				//end
				//else begin
					//`uvm_warning(get_type_name(), $sformatf("write transaction queue is EMPTY!!!"))
				//end
			//end
			//NON_PARALLEL: begin 
			      //if(w_trans_q.size() > 0) begin 
					//tmp = w_trans_q[idx];//access item without removing it from queue 
					//$cast(r_trans, tmp.clone());
					//r_trans_q.push_back(r_trans);
					//idx++;
				//end
			//end	
			//endcase
		//end//end of repeat
	//endtask
	//
	//randomize write data again
	//
	virtual task re_randomize_data();
		if(w_trans_q.size() == 0) begin
			`uvm_warning(get_type_name(), "UNAVAILABLE W_TRANS in enable_data_randomize mode!!!");
			return;
		end
		else begin
			foreach(w_trans_q[idx]) begin
				`uvm_info(get_type_name(), "BEFORE RE_RANDOMIZE", UVM_LOW);
				//w_trans_q[idx].print();
				//
				w_trans_q[idx].id = w_trans_q.size() + 1'd1;
				foreach(w_trans_q[idx].data[i]) begin
					w_trans_q[idx].data[i] = $urandom();
					//using solver to randomize can lead
					//--to failed randomization in case of
					//--large data array (>200 elements) 
					//--therefore, we should use $urandom()
				end
				`uvm_info(get_type_name(), "AFTER RE_RANDOMIZE", UVM_LOW);
				//w_trans_q[idx].print();
			end	
			`uvm_info(get_type_name(), $sformatf("succeed to re_randomize wdata!!!HAHAHA"), UVM_LOW);
		end
	endtask
endclass
//**********************************************************************************
//
//**********************************************************************************
//
//--------------------------------AXI MASTER WRITE----------------------------------
//
class AxiMasterWriteSeq #(DW, AW1) extends uvm_sequence#(axi_transaction #(DW,AW1));
    //register UVM factory
    `uvm_object_param_utils(AxiMasterWriteSeq#(DW, AW1))
  
    // Variables
    logic [7:0] start_id;
    int idx;
    //
    axi_transaction #(DW, AW1) axi_wr_trans;
    //
    stimulus_generator stimulus_gen_ref;

    // Constructor
    function new (string name = "AxiMasterWriteSeq");
        super.new(name);
      axi_wr_trans = axi_transaction#(DW,AW1)::type_id::create("axi_wr_trans");
    endfunction

    extern virtual task body();

endclass
  
//main tasks in sequence
    
//-- body()
task AxiMasterWriteSeq::body();
`uvm_info(get_type_name(), $sformatf("w_test_nums = %0d", stimulus_gen_ref.w_test_nums), UVM_LOW);
	idx = 0;
    repeat(stimulus_gen_ref.w_test_nums) begin
      // wait_for_grant();
      //send_request(axi_wr_trans); //must pair wait_for_grant()
      if(stimulus_gen_ref.w_trans_q.size() > 0) begin
		//`uvm_info(get_type_name(), $sformatf("[before] reading queue!!!"), UVM_LOW);
	      axi_wr_trans = stimulus_gen_ref.w_trans_q[idx];
		//`uvm_info(get_type_name(), $sformatf("[after] awid = %0d", axi_wr_trans.id), UVM_LOW);
	      //send item to sequencer
	      start_item(axi_wr_trans); //block until get_next_item() from driver
	      axi_wr_trans.set_bytes_in_beat();
	      finish_item(axi_wr_trans);
	      idx++;
      end
      else begin
		`uvm_fatal(get_type_name(), $sformatf("wr_stimulus not available!!!"))
      end
      //#(`CLK_CYCLE);
    end
endtask
//
//--------------AXI MASTER READ-------------------------
//
class AxiMasterReadSeq#(DW,AW1) extends uvm_sequence#(axi_transaction #(DW,AW1));
  `uvm_object_param_utils(AxiMasterReadSeq#(DW,AW1))
  //
    bit reconfigure_id;
    logic [7:0] start_id; 
    logic [7:0] r_id;
    int idx_q;
    //
    axi_transaction #(DW,AW1) axi_rd_trans;
    stimulus_generator stimulus_gen_ref;

    function new(string name = "read transaction");
        super.new(name);
	      axi_rd_trans = axi_transaction#(DW,AW1)::type_id::create("axi_rd_trans");
    endfunction 
    //
    extern virtual task body();
endclass
task AxiMasterReadSeq::body();
	r_id = 0;
	idx_q = 0;
	`uvm_info(get_type_name(), $sformatf("r_test_nums = %0d", stimulus_gen_ref.r_test_nums), UVM_LOW);
	repeat(stimulus_gen_ref.r_test_nums) begin
	      //stimulus_gen_ref.r_mb.get(tmp);
	      //axi_rd_trans.copy(tmp); 
	      //start_item does not recognize mailbox's element; therefore, we use copy() method to create new object
	      //
	      axi_rd_trans = stimulus_gen_ref.r_trans_q[idx_q];
	      //send item to sequencer
		`uvm_info(get_type_name(), $sformatf("[START]axi_rd_trans!!!"), UVM_HIGH);
	      start_item(axi_rd_trans);
	      axi_rd_trans.set_bytes_in_beat();
	      if(reconfigure_id) begin
		      axi_rd_trans.set_id(r_id);
	      end
	      axi_rd_trans.set_aligned_addr();
	      //item sent to driver done
	      finish_item(axi_rd_trans);
		`uvm_info(get_type_name(), $sformatf("[DONE]axi_rd_trans!!!"), UVM_HIGH);
	      r_id++;
	      idx_q++;
	end
endtask
//

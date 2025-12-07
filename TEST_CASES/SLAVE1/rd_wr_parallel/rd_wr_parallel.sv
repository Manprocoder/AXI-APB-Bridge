//-----------------------------------------------------------------------
//--virtual sequence (Reset Sequence, Axi Master Read, Axi Master Write, Apb Slave)
//--file: rd_wr_parallel.sv
//--description: rd_wr_parallel test 
//----------------------------------------------------------------
import type_package::*;
class rd_wr_parallel_vseq extends base_vseq;
	//stimulus handles
	stimulus_generator stimulus_gen_h;
	//sequences handles
    AxiResetSeq ResetSeq;
    AxiMasterWriteSeq#(DW,AW1) WriteSeq;
    AxiMasterReadSeq#(DW,AW1) ReadSeq;
    apb_seq #(DW,AW2) ApbSeq;
    //register to factory
    `uvm_object_utils(rd_wr_parallel_vseq)
    //
    function new(string name = "rd_wr_parallel_vseq");
        super.new(name);
    endfunction
    //main task
    task body();
        ResetSeq = AxiResetSeq::type_id::create("ResetSeq");
        ReadSeq = AxiMasterReadSeq#(DW,AW1)::type_id::create("ReadSeq");
        WriteSeq = AxiMasterWriteSeq#(DW,AW1)::type_id::create("WriteSeq");
        ApbSeq = apb_seq#(DW,AW2)::type_id::create("ApbSeq");
	//
	//configure stimulus_gen_h
	//
	stimulus_gen_h = stimulus_generator::type_id::create("stimulus_gen_h");
		stimulus_gen_h.w_test_nums = 20;
		stimulus_gen_h.r_test_nums = 20;
        //
	//assign handles
	//
	ReadSeq.stimulus_gen_ref = stimulus_gen_h;
	WriteSeq.stimulus_gen_ref = stimulus_gen_h;
	//configure id
	ReadSeq.reconfigure_id = 0;
	//
        ResetSeq.rst_value_q = {1'b0, 1'b1};//, 1'b0, 1'b1, 1'b0, 1'b1};
        ResetSeq.rst_run_time_en = 1'b0; //enable run-time rst
	//
	//generates item
	//
	stimulus_gen_h.generate_wr_item();
	stimulus_gen_h.clone_wr_into_rd();
	//
	`uvm_info(get_type_name(), $sformatf("Actual size of r_trans_q: %0d", stimulus_gen_h.r_trans_q.size()), UVM_LOW);
        //
	//ready to run
	//
        fork
            //begin
                `uvm_info(get_type_name(), $sformatf("rd_wr_parallel_vseq start!!!"), UVM_LOW);
                //fork
		ResetSeq.start(R);
                    WriteSeq.start(A1);
                    ReadSeq.start(A2);  
                //join
            //end
                //
            begin
                ApbSeq.start(B);
            end
            //
        join
	stimulus_gen_h.w_trans_q.delete();
	stimulus_gen_h.r_trans_q.delete();
        //
        `uvm_info(get_type_name(), $sformatf("rd_wr_parallel_vseq done!!!"), UVM_LOW);
        //
    endtask
endclass

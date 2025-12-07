//----------------------------------------------------------------------------------
//--virtual sequence (Reset Sequence, Axi Master Read, Axi Master Write, Apb Slave)
//--description:
//-- + All Rd done, pass write -> All write done (with resp) -> pass read 
//-- + No rst-runtime 
//--PURPOSE: check ip arbiter with only read request and only write request
//---------------------------------------------------------------------------------
import type_package::*;
class rd_wr_rd_vseq extends base_vseq;
	//stimulus handles
	stimulus_generator stimulus_gen_h;
	//sequences handles
    AxiResetSeq ResetSeq;
    AxiMasterWriteSeq#(DW,AW1) WriteSeq;
    AxiMasterReadSeq#(DW,AW1) ReadSeq1, ReadSeq2;
    apb_seq #(DW,AW2) ApbSeq;

    //register to factory
    `uvm_object_utils(rd_wr_rd_vseq)
    // `uvm_declare_p_sequencer(vsequencer)
    //
    parameter REQ_NUM = 3;
    int req_cnt = 0;
    //
    function new(string name = "rd_wr_rd_vseq");
        super.new(name);
    endfunction
    //main task
    //
    task body();
	ResetSeq = AxiResetSeq::type_id::create("ResetSeq");
        ReadSeq1 = AxiMasterReadSeq#(DW,AW1)::type_id::create("ReadSeq1");
        ReadSeq2 = AxiMasterReadSeq#(DW,AW1)::type_id::create("ReadSeq2");
        WriteSeq = AxiMasterWriteSeq#(DW,AW1)::type_id::create("WriteSeq");
        ApbSeq = apb_seq#(DW,AW2)::type_id::create("ApbSeq");
	//
	//configure stimulus_gen_h
	//
	stimulus_gen_h = stimulus_generator::type_id::create("stimulus_gen_h");
		stimulus_gen_h.w_test_nums = REQ_NUM;
		stimulus_gen_h.r_test_nums = REQ_NUM;
        //
	//assign handles
	//
	ReadSeq1.stimulus_gen_ref = stimulus_gen_h;
	ReadSeq2.stimulus_gen_ref = stimulus_gen_h;
	WriteSeq.stimulus_gen_ref = stimulus_gen_h;
	//configure id
	ReadSeq1.reconfigure_id = 0;
	ReadSeq2.reconfigure_id = 0;
	//
        ResetSeq.rst_value_q = {1'b0, 1'b1};
        ResetSeq.rst_run_time_en = 1'b0; //enable run-time rst
	//
	//generates item
	//
	stimulus_gen_h.generate_wr_item();
	stimulus_gen_h.clone_wr_into_rd();
        //
	//ready to run
	//
        fork
            begin
                ResetSeq.start(R);
            end
            begin
                `uvm_info(get_type_name(), $sformatf("rd_wr_rd_vseq start!!!"), UVM_LOW);
                fork
                    ReadSeq1.start(A2);  

                    forever begin
                        A2.axi_vif.one_read_req_done();
                        req_cnt++;
                        //`uvm_info(get_type_name(), $sformatf("rd_req_done_total = %0d", req_cnt), UVM_LOW)
                        if(req_cnt == REQ_NUM) begin
                            `uvm_info(get_type_name(), $sformatf("ALL READ DONE!!!"), UVM_LOW)
                            req_cnt = 0;
                            break;
                        end
                    end
                join
                //
                fork
                    WriteSeq.start(A1);
                    //
                    forever begin
                        A1.axi_vif.one_write_req_done();
                        req_cnt++;
                        //`uvm_info(get_type_name(), $sformatf("wr_req_done_total = %0d", req_cnt), UVM_LOW)
                        if(req_cnt == REQ_NUM) begin
                            `uvm_info(get_type_name(), $sformatf("ALL WRITE DONE!!!"), UVM_LOW)
                            req_cnt = 0;
                            break;
                        end
                    end
                join
                //
                ReadSeq2.start(A2);  
                //
            end
            begin
                ApbSeq.start(B);
            end
            //
        join
        //
	stimulus_gen_h.w_trans_q.delete();
	stimulus_gen_h.r_trans_q.delete();
        `uvm_info(get_type_name(), $sformatf("rd_wr_rd_vseq done!!!"), UVM_LOW);
        //
    endtask
endclass


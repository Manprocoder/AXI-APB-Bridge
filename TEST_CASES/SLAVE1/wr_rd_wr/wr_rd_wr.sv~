//-----------------------------------------------------------------------
//--virtual sequence (Reset Sequence, Axi Master Read, Axi Master Write, Apb Slave)
//--DESCRIPTION: All write first, after all write done, continue pass all read
//-- all read one, pass all write, finally is read transaction 
//--PURPOSE: check ip arbiter with only write or only read
//------------order: wr -> rd -> wr - rd
//----------------------------------------------------------------
import type_package::*;
class wr_rd_wr_vseq extends base_vseq;
	//stimulus handles
	stimulus_generator stimulus_gen_h_1;// stimulus_gen_h_2;
	//sequences handles
    AxiResetSeq ResetSeq;
    AxiMasterWriteSeq#(DW,AW1) WriteSeq1, WriteSeq2;
    AxiMasterReadSeq#(DW,AW1) ReadSeq1, ReadSeq2;
    apb_seq #(DW,AW2) ApbSeq;
    //register to factory
    `uvm_object_utils(wr_rd_wr_vseq)
    //
    parameter REQ_NUM = 10;
    int req_cnt = 0;
    //
    function new(string name = "wr_rd_wr_vseq");
        super.new(name);
    endfunction
    //main task
    //
    task body();
     ResetSeq = AxiResetSeq::type_id::create("ResetSeq");
        ReadSeq1 = AxiMasterReadSeq#(DW,AW1)::type_id::create("ReadSeq1");
        ReadSeq2 = AxiMasterReadSeq#(DW,AW1)::type_id::create("ReadSeq2");
        WriteSeq1 = AxiMasterWriteSeq#(DW,AW1)::type_id::create("WriteSeq1");
        WriteSeq2 = AxiMasterWriteSeq#(DW,AW1)::type_id::create("WriteSeq2");
        ApbSeq = apb_seq#(DW,AW2)::type_id::create("ApbSeq");
	//
	//configure stimulus_gen_h_1
	//
	stimulus_gen_h_1 = stimulus_generator::type_id::create("stimulus_gen_h_1");
		stimulus_gen_h_1.w_test_nums = REQ_NUM;
		stimulus_gen_h_1.r_test_nums = REQ_NUM;
	//	stimulus_gen_h_1.test_plot_h = test_plot'(2'b01); //NON_PARALLEL
        //
	//assign handles
	//
	ReadSeq1.stimulus_gen_ref = stimulus_gen_h_1;
	WriteSeq1.stimulus_gen_ref = stimulus_gen_h_1;
	ReadSeq2.stimulus_gen_ref = stimulus_gen_h_1;
	WriteSeq2.stimulus_gen_ref = stimulus_gen_h_1;
	//
        ResetSeq.rst_value_q = {1'b0, 1'b1};
        ResetSeq.rst_run_time_en = 1'b0; //enable run-time rst
	//
	//generates item
	//
	stimulus_gen_h_1.generate_wr_item();
	stimulus_gen_h_1.clone_wr_into_rd();
        //
	//ready to run
	//
        fork
            begin
                ResetSeq.start(R);
            end
            begin
                `uvm_info(get_type_name(), $sformatf("wr_rd_wr_vseq start!!!"), UVM_LOW);
                fork
                    WriteSeq1.start(A1);
                    //
                    forever begin
                        A1.axi_vif.one_write_req_done();
                        req_cnt++;
      //                  `uvm_info(get_type_name(), $sformatf("wr_req_done_total[1] = %0d", req_cnt), UVM_LOW)
                        if(req_cnt == REQ_NUM) begin
                            req_cnt = 0;
                            `uvm_info(get_type_name(), $sformatf("ALL WRITE[1] DONE!!!"), UVM_LOW)
                            break;
                        end
                    end
                join
                //
                fork
                    ReadSeq1.start(A2);  
                    //
                    forever begin
                        A2.axi_vif.one_read_req_done();
                        req_cnt++;
                       // `uvm_info(get_type_name(), $sformatf("rd_req_done_total = %0d", req_cnt), UVM_LOW)
                        if(req_cnt == REQ_NUM) begin
                            req_cnt = 0;
                            `uvm_info(get_type_name(), $sformatf("ALL READ DONE!!!"), UVM_LOW)
                            break;
                        end
                    end
                join
		//
		//call re_randomize write data task
                //
		stimulus_gen_h_1.re_randomize_data();
		//empty queue
		stimulus_gen_h_1.r_trans_q.delete();
		//full queue again with new transaction
		stimulus_gen_h_1.clone_wr_into_rd();
		#(`CLK_CYCLE*REQ_NUM);
		//
		fork
                    WriteSeq2.start(A1);
                    //
                    forever begin
                        A1.axi_vif.one_write_req_done();
                        req_cnt++;
                        //`uvm_info(get_type_name(), $sformatf("wr_req_done_total[2] = %0d", req_cnt), UVM_LOW)
                        if(req_cnt == REQ_NUM) begin
                            req_cnt = 0;
                            `uvm_info(get_type_name(), $sformatf("ALL WRITE[2] DONE!!!"), UVM_LOW)
                            break;
                        end
                    end
                join
		//
                    ReadSeq2.start(A2);  
            end
            begin
                ApbSeq.start(B);
            end
            //
        join
        //
	stimulus_gen_h_1.w_trans_q.delete();
	stimulus_gen_h_1.r_trans_q.delete();
        `uvm_info(get_type_name(), $sformatf("wr_rd_wr_vseq done!!!"), UVM_LOW);
        //
    endtask
endclass

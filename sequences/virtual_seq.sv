//==================================================================================
//--Project: Design and Verify AXI-APB 
//==================================================================================
//--filename: virtual_seq.sv
//--Author: Nguyen Ngoc Man
//==================================================================================
//--Description:
//virtual sequence (Reset Sequence, Axi Master Read, Axi Master Write, Apb Slave)
//+ test reset
//+ test main operation of IP with 3 cases: (1)wr_rd parallel, (2)wr->rd->wr, (3)rd->
//wr->rd
//+ test SLVERR, DECERR response
//==================================================================================
import axi_pkg::*;
import apb_pkg::*;
class virtual_seq extends base_vseq;
    typedef apb_seq #(DW2,AW2) apb_seq;
    //=======================================================
    //-----------------DATA members
    //=======================================================
	//--1: AXI sequences' handles
    //
    AxiResetSeq ResetSeq;
    AxiMasterWriteSeq#(DW1,AW1) WriteSeq;
    AxiMasterReadSeq#(DW1,AW1) ReadSeq;
    rsp_seq test_rd_rsp_seq;
    rsp_seq test_wr_rsp_seq;
    unaligned_addr_seq unaligned_wseq, unaligned_rseq;
    rdata_almost_full_seq rd_af_seq_h;
    //
	//--2: APB sequences' handles
    apb_seq apb_seq_h[];
    //
    int req_cnt = 0;
    //--4:
    //--4.1: total transaction
    int no_rd_wr_para;
    int no_rd_wr_rd;
    int no_wr_rd_wr;
    int no_unsupported_size;
    int no_disallowed_addr;
    int no_dec_err;
    int no_unaligned_addr;
    int no_rdata_almost_full;

    //register to factory
    `uvm_object_utils(virtual_seq)
    //
    //=======================================================
    //-----------------IMPLEMENTATION of all METHODs
    //=======================================================
    function new(string name = "virtual_seq");
        super.new(name);
    endfunction
    //
    function bit count(int no_req, string hdr);
	if(req_cnt == no_req) begin
	    `uvm_info(get_name(), $sformatf("%s", hdr), UVM_LOW)
	    req_cnt = 0;
	    return 1;
	end
    endfunction
    //main task
    //
    virtual task body();
        `uvm_info(get_name(), "virtual sequence set up", UVM_LOW)
        //----get env handle
        get_env_handle();
        //
        ResetSeq = AxiResetSeq::type_id::create("ResetSeq");
        ReadSeq = AxiMasterReadSeq#(DW1,AW1)::type_id::create("ReadSeq");
        WriteSeq = AxiMasterWriteSeq#(DW1,AW1)::type_id::create("WriteSeq");
        test_rd_rsp_seq = rsp_seq::type_id::create("test_rd_rsp_seq");
        test_wr_rsp_seq = rsp_seq::type_id::create("test_wr_rsp_seq");
        unaligned_wseq = unaligned_addr_seq::type_id::create("unaligned_wseq");
        unaligned_rseq = unaligned_addr_seq::type_id::create("unaligned_rseq");
        rd_af_seq_h = rdata_almost_full_seq::type_id::create("rd_af_seq_h");
        `uvm_info(get_name(), "virtual sequence start", UVM_LOW)
        //
        if(env_h == null) begin
            `uvm_fatal(get_name(), "env_handle is NULL");
        end
	//---------------------------------------------------
    //--------------APB sequences
	//---------------------------------------------------
        apb_seq_h = new[env_h.env_cfg_h.no_apb_agt];
        foreach(apb_seq_h[i]) begin
            apb_seq_h[i] = apb_seq::type_id::create($sformatf("apb_seq_h[%0d]", i));
        end
	//
	//generates item
	ReadSeq.no_test = no_rd_wr_para/2;
	WriteSeq.no_test = no_rd_wr_para/2;
	ReadSeq.gen_item();
	WriteSeq.gen_item();
	//configure id
	ReadSeq.reconfigure_id = 0;
	//
    ResetSeq.rst_value_q = {1'b0, 1'b1, 1'b0, 1'b1};//, 1'b0, 1'b1, 1'b0, 1'b1};
    ResetSeq.rst_run_time_en = 1'b0; //enable run-time rst
	//
	//--first attempt
    //
	`uvm_info(get_name(), "[CHECK_POINT]wr_rd_parallel_seq start!!!", UVM_LOW);
	ResetSeq.start(R);
	//
    fork: START_SIM
	    begin:AXI_RUN 
		//
		//6th ATTEMPT --- test rdata almost full signal 
		//
		//generates item
		rd_af_seq_h.no_test = no_rdata_almost_full;
		rd_af_seq_h.gen_item();
		//
		`uvm_info(get_name(), "[CHECK_POINT]rdata_almost_full_seq start!!!", UVM_LOW);
        rd_af_seq_h.start(A2);
		`uvm_info(get_name(), "[CHECK_POINT]rdata_almost_full_seq done!!!", UVM_LOW);
        //
	    fork: ATTEMPT_1ST
		    WriteSeq.start(A1);
		    ReadSeq.start(A2);  
        join
        `uvm_info(get_name(), "[CHECK_POINT]wr_rd_parallel_req done!!!", UVM_LOW);
	//
	//--second attempt
    //
        ReadSeq.no_test = no_rd_wr_rd/3;
        WriteSeq.no_test = no_rd_wr_rd/3;
        ReadSeq.gen_item();
        WriteSeq.gen_item();
        //
        `uvm_info(get_name(), "[CHECK_POINT]rd_wr_rd_vseq start!!!", UVM_LOW);
                fork: RD_ATTEMPT_2ND
                    ReadSeq.start(A2);  
                //
                    forever begin
                        A2.axi_vif.one_read_req_done();
                        req_cnt++;
                        //`uvm_info(get_name(), $sformatf("rd_req_done_total = %0d", req_cnt), UVM_LOW)
                        if(count(ReadSeq.no_test, "[SECOND_ATTEMP]: read1_done!")) break;
                    end
                join: RD_ATTEMPT_2ND
                //
                fork: WR_ATTEMPT_2ND
                    WriteSeq.start(A1);
                    //
                    forever begin
                        A1.axi_vif.one_write_req_done();
                        req_cnt++;
                        //`uvm_info(get_name(), $sformatf("[SECOND_ATTEMP]wr_req = %0d", req_cnt), UVM_LOW)
                    if(count(WriteSeq.no_test, "[SECOND_ATTEMP]: write_done!")) break;
                    end
                join: WR_ATTEMPT_2ND
                //
                ReadSeq.no_test = no_rd_wr_rd/3;
                ReadSeq.gen_item();
                ReadSeq.start(A2);  
        `uvm_info(get_name(), "[CHECK_POINT]rd_wr_rd_vseq done!!!", UVM_LOW);
	    //
	    //---3rd attempt
	    //
            ReadSeq.no_test = no_wr_rd_wr/3;
            WriteSeq.no_test = no_wr_rd_wr/3;
            ReadSeq.gen_item();
            WriteSeq.gen_item();
            //
        `uvm_info(get_name(), "[CHECK_POINT]wr_rd_wr_vseq start!!!", UVM_LOW);
                fork: WR_ATTEMPT_3RD_0
                    WriteSeq.start(A1);
                    //
                    forever begin
                        A1.axi_vif.one_write_req_done();
                        req_cnt++;
//`uvm_info(get_name(), $sformatf("[THIRD_ATTEMP]wr_req[1] = %0d", req_cnt), UVM_LOW)
                        if(count(WriteSeq.no_test, "[THIRD_ATTEMP]: write1_done!")) break;
                    end
                join: WR_ATTEMPT_3RD_0
                //
                fork: RD_ATTEMPT_3RD
                    ReadSeq.start(A2);  
                    //
                    forever begin
                        A2.axi_vif.one_read_req_done();
                        req_cnt++;
 		//`uvm_info(get_name(), $sformatf("[THIRD_ATTEMP]rd_req = %0d", req_cnt), UVM_LOW)
                        if(count(ReadSeq.no_test, "[THIRD_ATTEMP]: read_done!")) break;
                    end
                join: RD_ATTEMPT_3RD
		//
            WriteSeq.no_test = no_wr_rd_wr/3;
            WriteSeq.gen_item();
            //
                fork: WR_ATTEMPT_3RD_1
                    WriteSeq.start(A1);
                    //
                    forever begin
                        A1.axi_vif.one_write_req_done();
                        req_cnt++;
                        //`uvm_info(get_name(), $sformatf("[THIRD_ATTEMP]wr_req[2] = %0d", req_cnt), UVM_LOW)
                        if(count(WriteSeq.no_test, "[THIRD_ATTEMP]: write2_done!")) break;
                    end
                join: WR_ATTEMPT_3RD_1
        `uvm_info(get_name(), "[CHECK_POINT]wr_rd_wr_vseq done!!!", UVM_LOW);
		//
		//4th ATTEMPT --- test PSLVERR, DECERR response
		//
		//generates item
			test_wr_rsp_seq.no_test_unsupported_size = no_unsupported_size/2;
			test_wr_rsp_seq.no_test_disallowed_addr = no_disallowed_addr/2;
			test_wr_rsp_seq.no_test_decerr = no_dec_err/2;
			test_rd_rsp_seq.no_test_unsupported_size = no_unsupported_size/2;
			test_rd_rsp_seq.no_test_disallowed_addr = no_disallowed_addr/2;
			test_rd_rsp_seq.no_test_decerr = no_dec_err/2;
			test_wr_rsp_seq.gen_item();
			test_rd_rsp_seq.gen_item();
		//
		`uvm_info(get_name(), "[CHECK_POINT]test_response_seq start!!!", UVM_LOW);
		fork
			test_wr_rsp_seq.start(A1);
			test_rd_rsp_seq.start(A2);
		join
		`uvm_info(get_name(), "[CHECK_POINT]test_response_seq done!!!", UVM_LOW);
		//
		//5th ATTEMPT --- test unaligned address
		//
		//generates item
		unaligned_wseq.no_test = no_unaligned_addr/2;
		unaligned_wseq.gen_item();
		unaligned_rseq.no_test = no_unaligned_addr/2;
		unaligned_rseq.gen_item();
		//
		`uvm_info(get_name(), "[CHECK_POINT]unaligned_addr_seq start!!!", UVM_LOW);
		fork
			unaligned_wseq.start(A1);
			unaligned_rseq.start(A2);
            //forever begin
                //A2.axi_vif.one_read_req_done();
                //req_cnt++;
                //if(count(unaligned_rseq.no_test, "[DONE]Read_Sequence for unaligned address")) begin
                    //break;
                //end
            //end
		join
		`uvm_info(get_name(), "[CHECK_POINT]unaligned_addr_seq done!!!", UVM_LOW);
	end: AXI_RUN
    //
    //
    begin: APB_RUN
        foreach (apb_seq_h[i]) begin
            automatic int idx = i;
            fork
                apb_seq_h[idx].start(B[idx]);
            join_none
        end
    end: APB_RUN
	join: START_SIM
    endtask
endclass

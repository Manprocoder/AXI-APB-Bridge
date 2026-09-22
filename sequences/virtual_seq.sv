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
import env_pkg::*;
class virtual_seq extends base_vseq;
    typedef apb_seq #(DW2,AW2) apb_seq;
    typedef AxiMasterWriteSeq#(DW1,AW1) w_normal_seq;
    typedef AxiMasterReadSeq#(DW1,AW1) r_normal_seq;
//    `uvm_declare_p_sequencer(virtual_sequencer) //$cast available attribute m_sequencer to p_sequencer
    //=======================================================
    //-----------------DATA members
    //=======================================================
    parameter ARR_SIZE = 5;
	//--1: AXI sequences' handles
    //
    stimulus_generator w_stm_gen_h, r_stm_gen_h;
    AxiResetSeq ResetSeq;
    w_normal_seq WriteSeq;
    r_normal_seq ReadSeq;
    rdata_almost_full_seq rd_af_seq_h;
    //
	//--2: APB sequences' handles
    apb_seq apb_seq_h[];
    //--3: 
    stimulus_generator w_seq_arr [];// = '{w_normal_seq, unsupported_size_seq, disallowed_addr_seq, dec_err_seq, unaligned_addr_seq};
    stimulus_generator r_seq_arr [];// = '{r_normal_seq, unsupported_size_seq, disallowed_addr_seq, dec_err_seq, unaligned_addr_seq};
    //
    //
    int req_cnt = 0;
    int wr_cp_cnt, rd_cp_cnt;
    //--4:
    //--4.1: total transaction
    int no_rd_wr_para;
    int no_rd_wr_rd;
    int no_wr_rd_wr;
    //int no_unsupported_size;
    //int no_disallowed_addr;
    //int no_dec_err;
    //int no_unaligned_addr;
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
    function bit count(inout int counter, input int no_req, input string hdr);
	if(counter == no_req) begin
	    `uvm_info(get_name(), $sformatf("%s", hdr), UVM_LOW)
	    counter = 0;
	    return 1;
	end
    endfunction
    //
    function void init_arr();
        //
        w_seq_arr = new[ARR_SIZE];
        r_seq_arr = new[ARR_SIZE];

        w_seq_arr[0] = w_normal_seq::type_id::create("w_normal_seq");
        w_seq_arr[1] = unsupported_size_seq::type_id::create("w_unsupported_size_seq");
        w_seq_arr[2] = disallowed_addr_seq::type_id::create("w_disallowed_addr_seq");
        w_seq_arr[3] = dec_err_seq::type_id::create("w_dec_err_seq");
        w_seq_arr[4] = unaligned_addr_seq::type_id::create("w_unaligned_addr_seq");

        r_seq_arr[0] = r_normal_seq::type_id::create("r_normal_seq");
        r_seq_arr[1] = unsupported_size_seq::type_id::create("r_unsupported_size_seq");
        r_seq_arr[2] = disallowed_addr_seq::type_id::create("r_disallowed_addr_seq");
        r_seq_arr[3] = dec_err_seq::type_id::create("r_dec_err_seq");
        r_seq_arr[4] = unaligned_addr_seq::type_id::create("r_unaligned_addr_seq");
    endfunction
    //main task
    //
    virtual task body();
        `uvm_info(get_name(), "virtual sequence set up", UVM_LOW)
        //----get env handle
        get_env_handle();
        //==============================================================
        //-------------initialization for w_seq_arr and r_seq_arr
        //==============================================================
        init_arr();
        //
        ResetSeq = AxiResetSeq::type_id::create("ResetSeq");
       // r_stm_gen_h = rdata_almost_full_seq::type_id::create("rd_af_seq_h");
        ReadSeq = r_normal_seq::type_id::create("ReadSeq");
        WriteSeq = w_normal_seq::type_id::create("WriteSeq");
        //test_rd_rsp_seq = rsp_seq::type_id::create("test_rd_rsp_seq");
        //test_wr_rsp_seq = rsp_seq::type_id::create("test_wr_rsp_seq");
        //unaligned_wseq = unaligned_addr_seq::type_id::create("unaligned_wseq");
        //unaligned_rseq = unaligned_addr_seq::type_id::create("unaligned_rseq");
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
	//ReadSeq.no_test = no_rd_wr_para/2;
	//WriteSeq.no_test = no_rd_wr_para/2;
	//ReadSeq.gen_item();
	//WriteSeq.gen_item();
	////configure id
	//ReadSeq.reconfigure_id = 0;
	//
    ResetSeq.rst_value_q = {1'b0, 1'b1, 1'b0, 1'b1};//, 1'b0, 1'b1, 1'b0, 1'b1};
    ResetSeq.rst_run_time_en = 1'b0; //enable run-time rst
	`uvm_info(get_name(), "[CHECK_POINT]wr_rd_parallel_seq start!!!", UVM_LOW);
	ResetSeq.start(p_sequencer.R);
	//
    fork: START_SIM
	    begin:AXI_RUN 
		//
		//special ATTEMPT --- test rdata almost full signal 
		//
		//generates item
		//r_stm_gen_h.no_test = no_rdata_almost_full;
		//r_stm_gen_h.gen_item();
		////
		//`uvm_info(get_name(), "[CHECK_POINT]rdata_almost_full_seq start!!!", UVM_LOW);
        //r_stm_gen_h.start(p_sequencer.A2);
		//`uvm_info(get_name(), "[CHECK_POINT]rdata_almost_full_seq done!!!", UVM_LOW);
	//
	//--first attempt
    //
        //
        fork: RD_WR_PARALLEL
        for(int i = 0; i < ARR_SIZE; i++) begin 
            w_stm_gen_h = w_seq_arr[i];//::type_id::create($sformatf("%0s", w_seq_arr[i]));
            r_stm_gen_h = r_seq_arr[i];//::type_id::create($sformatf("%0s", r_seq_arr[i]));
            //
            w_stm_gen_h.no_test = (no_rd_wr_para/ARR_SIZE)/2;
            r_stm_gen_h.no_test = (no_rd_wr_para/ARR_SIZE)/2;
            //
            w_stm_gen_h.gen_item();
            r_stm_gen_h.gen_item();
            //
            `uvm_info(get_name(), $sformatf("[CHECK_POINT]%0s start!!!", w_seq_arr[i].get_type_name()), UVM_LOW);
            fork: ATTEMPT_1ST
                w_stm_gen_h.start(p_sequencer.A1);
                r_stm_gen_h.start(p_sequencer.A2);  
                //WriteSeq.start(p_sequencer.A1);
                //ReadSeq.start(p_sequencer.A2);  
            join
            `uvm_info(get_name(), $sformatf("[CHECK_POINT]%0s done!!!", w_seq_arr[i].get_type_name()), UVM_LOW);
        end
        //
        forever begin: WRITE_CHK_POINT
            p_sequencer.A1.axi_vif.one_write_req_done();
            wr_cp_cnt++;
                //`uvm_info(get_name(), $sformatf("[SECOND_ATTEMP]wr_req = %0d", req_cnt), UVM_LOW)
            if(count(wr_cp_cnt, no_rd_wr_para/2, "[RD_WR_PARALLEL]: write_done!")) begin
                break;
            end
        end: WRITE_CHK_POINT
        //
        forever begin: READ_CHK_POINT
            p_sequencer.A2.axi_vif.one_read_req_done();
            rd_cp_cnt++;
            //
            `uvm_info(get_name(), $sformatf("[RD_WR_PARALLEL]rd_cp_cnt = %0d", rd_cp_cnt), UVM_LOW)
            if(count(rd_cp_cnt, no_rd_wr_para/2, "[RD_WR_PARALLEL]: read_done!")) begin
                break;
            end
        end: READ_CHK_POINT
        join: RD_WR_PARALLEL
        `uvm_info(get_name(), "[CHECK_POINT]wr_rd_parallel_req done!!!", UVM_LOW);
	//
	//--second attempt
    //
        ReadSeq.no_test = no_rd_wr_rd/3;
        WriteSeq.no_test = no_rd_wr_rd/3;
        ReadSeq.gen_item();
        WriteSeq.gen_item();
        ////
        `uvm_info(get_name(), "[CHECK_POINT]rd_wr_rd_vseq start!!!", UVM_LOW);
                fork: RD1_ATTEMPT_2ND
                    ReadSeq.start(p_sequencer.A2);  
                //
                    forever begin
                        p_sequencer.A2.axi_vif.one_read_req_done();
                        req_cnt++;
                        //`uvm_info(get_name(), $sformatf("rd_req_done_total = %0d", req_cnt), UVM_LOW)
                        if(count(req_cnt, ReadSeq.no_test, "[SECOND_ATTEMP]: read1_done!")) break;
                    end
                join: RD1_ATTEMPT_2ND
                //
                fork: WR_ATTEMPT_2ND
                    WriteSeq.start(p_sequencer.A1);
                    //
                    forever begin
                        p_sequencer.A1.axi_vif.one_write_req_done();
                        req_cnt++;
                        //`uvm_info(get_name(), $sformatf("[SECOND_ATTEMP]wr_req = %0d", req_cnt), UVM_LOW)
                    if(count(req_cnt, WriteSeq.no_test, "[SECOND_ATTEMP]: write_done!")) break;
                    end
                join: WR_ATTEMPT_2ND
                //
                ReadSeq.no_test = no_rd_wr_rd/3;
                ReadSeq.gen_item();
                fork: RD2_ATTEMPT_2ND
                    ReadSeq.start(p_sequencer.A2);  
                //
                    forever begin
                        p_sequencer.A2.axi_vif.one_read_req_done();
                        req_cnt++;
                        //`uvm_info(get_name(), $sformatf("rd_req_done_total = %0d", req_cnt), UVM_LOW)
                        if(count(req_cnt, ReadSeq.no_test, "[SECOND_ATTEMP]: read2_done!")) break;
                    end
                join: RD2_ATTEMPT_2ND
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
                fork: WR1_ATTEMPT_3RD
                    WriteSeq.start(p_sequencer.A1);
                    //
                    forever begin
                        p_sequencer.A1.axi_vif.one_write_req_done();
                        req_cnt++;
//`uvm_info(get_name(), $sformatf("[THIRD_ATTEMP]wr_req[1] = %0d", req_cnt), UVM_LOW)
                        if(count(req_cnt, WriteSeq.no_test, "[THIRD_ATTEMP]: write1_done!")) break;
                    end
                join: WR1_ATTEMPT_3RD
                //
                fork: RD_ATTEMPT_3RD
                    ReadSeq.start(p_sequencer.A2);  
                    //
                    forever begin
                        p_sequencer.A2.axi_vif.one_read_req_done();
                        req_cnt++;
 		//`uvm_info(get_name(), $sformatf("[THIRD_ATTEMP]rd_req = %0d", req_cnt), UVM_LOW)
                        if(count(req_cnt, ReadSeq.no_test, "[THIRD_ATTEMP]: read_done!")) break;
                    end
                join: RD_ATTEMPT_3RD
		//
            WriteSeq.no_test = no_wr_rd_wr/3;
            WriteSeq.gen_item();
            //
                fork: WR2_ATTEMPT_3RD
                    WriteSeq.start(p_sequencer.A1);
                    //
                    forever begin
                        p_sequencer.A1.axi_vif.one_write_req_done();
                        req_cnt++;
                        //`uvm_info(get_name(), $sformatf("[THIRD_ATTEMP]wr_req[2] = %0d", req_cnt), UVM_LOW)
                        if(count(req_cnt, WriteSeq.no_test, "[THIRD_ATTEMP]: write2_done!")) break;
                    end
                join: WR2_ATTEMPT_3RD
        `uvm_info(get_name(), "[CHECK_POINT]wr_rd_wr_vseq done!!!", UVM_LOW);
		////
		////4th ATTEMPT --- test PSLVERR, DECERR response
		////
		////generates item
			//test_wr_rsp_seq.no_test_unsupported_size = no_unsupported_size/2;
			//test_wr_rsp_seq.no_test_disallowed_addr = no_disallowed_addr/2;
			//test_wr_rsp_seq.no_test_decerr = no_dec_err/2;
			//test_rd_rsp_seq.no_test_unsupported_size = no_unsupported_size/2;
			//test_rd_rsp_seq.no_test_disallowed_addr = no_disallowed_addr/2;
			//test_rd_rsp_seq.no_test_decerr = no_dec_err/2;
			//test_wr_rsp_seq.gen_item();
			//test_rd_rsp_seq.gen_item();
		////
		//`uvm_info(get_name(), "[CHECK_POINT]test_response_seq start!!!", UVM_LOW);
		//fork
			//test_wr_rsp_seq.start(p_sequencer.A1);
			//test_rd_rsp_seq.start(p_sequencer.A2);
		//join
		//`uvm_info(get_name(), "[CHECK_POINT]test_response_seq done!!!", UVM_LOW);
		////
		////5th ATTEMPT --- test unaligned address
		////
		////generates item
		//unaligned_wseq.no_test = no_unaligned_addr/2;
		//unaligned_wseq.gen_item();
		//unaligned_rseq.no_test = no_unaligned_addr/2;
		//unaligned_rseq.gen_item();
		////
		//`uvm_info(get_name(), "[CHECK_POINT]unaligned_addr_seq start!!!", UVM_LOW);
		//fork
			//unaligned_wseq.start(p_sequencer.A1);
			//unaligned_rseq.start(p_sequencer.A2);
            ////forever begin
                ////p_sequencer.A2.axi_vif.one_read_req_done();
                ////req_cnt++;
                ////if(count(unaligned_rseq.no_test, "[DONE]Read_Sequence for unaligned address")) begin
                    ////break;
                ////end
            ////end
		//join
		//`uvm_info(get_name(), "[CHECK_POINT]unaligned_addr_seq done!!!", UVM_LOW);
	end: AXI_RUN
    //
    //
    begin: APB_RUN
        foreach (apb_seq_h[i]) begin
            automatic int idx = i;
            fork
                apb_seq_h[idx].start(p_sequencer.B[idx]);
            join_none
        end
    end: APB_RUN
	join: START_SIM
    endtask
endclass

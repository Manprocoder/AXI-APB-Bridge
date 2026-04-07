//-----------------------------------------------------------------------
//--virtual sequence (Reset Sequence, Axi Master Read, Axi Master Write, Apb Slave)
//--file: virtual_seq.sv
//--description:
//+ test reset
//+ test main operation of IP with 3 cases: (1)wr_rd parallel, (2)wr->rd->wr, (3)rd->
//wr->rd
//+ test SLVERR, DECERR response
//----------------------------------------------------------------
import type_package::*;
class virtual_seq extends base_vseq;
	//sequences handles
    AxiResetSeq ResetSeq;
    AxiMasterWriteSeq#(DW,AW1) WriteSeq;
    AxiMasterReadSeq#(DW,AW1) ReadSeq;
    rsp_seq test_rd_rsp_seq;
    rsp_seq test_wr_rsp_seq;
    apb_seq #(DW,AW2) ApbSeq;
    //
    int req_cnt = 0;
    int no_trans;
    //register to factory
    `uvm_object_utils(virtual_seq)
    //
    function new(string name = "virtual_seq");
        super.new(name);
    endfunction
    //
    function bit count(int no_req, string hdr);
	if(req_cnt == no_req) begin
	    `uvm_info(get_type_name(), $sformatf("%s", hdr), UVM_LOW)
	    req_cnt = 0;
	    return 1;
	end
    endfunction
    //main task
    //
    virtual task body();
	//
        ResetSeq = AxiResetSeq::type_id::create("ResetSeq");
        ReadSeq = AxiMasterReadSeq#(DW,AW1)::type_id::create("ReadSeq");
        WriteSeq = AxiMasterWriteSeq#(DW,AW1)::type_id::create("WriteSeq");
	test_rd_rsp_seq = rsp_seq::type_id::create("test_rd_rsp_seq");
	test_wr_rsp_seq = rsp_seq::type_id::create("test_wr_rsp_seq");
	//
        ApbSeq = apb_seq#(DW,AW2)::type_id::create("ApbSeq");
	//
	//generates item
	ReadSeq.total_no_test = no_trans;
	WriteSeq.total_no_test = no_trans;
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
	ReadSeq.no_test = 100;
	WriteSeq.no_test = 100;
	`uvm_info(get_type_name(), $sformatf("wr_rd_parallel start!!!"), UVM_LOW);
	ResetSeq.start(R);
	//
        fork
	    begin//run
	    fork
		    WriteSeq.start(A1);
		    ReadSeq.start(A2);  
    	    join
	`uvm_info(get_type_name(), $sformatf("wr_rd_parallel done!!!"), UVM_LOW);
	//
	//--second attempt
        //
	ReadSeq.no_test = 50;
	WriteSeq.no_test = 100;
	`uvm_info(get_type_name(), $sformatf("rd_wr_rd_vseq start!!!"), UVM_LOW);
                fork
                    ReadSeq.start(A2);  
		    //
                    forever begin
                        A2.axi_vif.one_read_req_done();
                        req_cnt++;
                        //`uvm_info(get_type_name(), $sformatf("rd_req_done_total = %0d", req_cnt), UVM_LOW)
			if(count(ReadSeq.no_test, "[SECOND_ATTEMP]: read1_done!")) break;
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
			if(count(WriteSeq.no_test, "[SECOND_ATTEMP]: write_done!")) break;
                    end
                join
                //
                ReadSeq.start(A2);  
	    //
	    //---3rd attempt
	    //
	ReadSeq.no_test = 100;
	WriteSeq.no_test = 50;
	`uvm_info(get_type_name(), $sformatf("wr_rd_wr_vseq start!!!"), UVM_LOW);
                fork
                    WriteSeq.start(A1);
                    //
                    forever begin
                        A1.axi_vif.one_write_req_done();
                        req_cnt++;
//      			`uvm_info(get_type_name(), $sformatf("[THIRD_ATTEMP]wr_req[1] = %0d", req_cnt), UVM_LOW)
			if(count(WriteSeq.no_test, "[THIRD_ATTEMP]: write1_done!")) break;
                    end
                join
                //
                fork
                    ReadSeq.start(A2);  
                    //
                    forever begin
                        A2.axi_vif.one_read_req_done();
                        req_cnt++;
 //                      `uvm_info(get_type_name(), $sformatf("[THIRD_ATTEMP]rd_req = %0d", req_cnt), UVM_LOW)
  			if(count(ReadSeq.no_test, "[THIRD_ATTEMP]: read_done!")) break;
                    end
                join
		//
		fork
                    WriteSeq.start(A1);
                    //
                    forever begin
                        A1.axi_vif.one_write_req_done();
                        req_cnt++;
                        //`uvm_info(get_type_name(), $sformatf("[THIRD_ATTEMP]wr_req[2] = %0d", req_cnt), UVM_LOW)
			if(count(WriteSeq.no_test, "[THIRD_ATTEMP]: write2_done!")) break;
                    end
                join
		`uvm_info(get_type_name(), $sformatf("wr_rd_wr_vseq done!!!"), UVM_LOW);
		//
		//4th ATTEMPT --- test PSLVERR, DECERR reponse
		//
		//generates item
			test_wr_rsp_seq.no_test_slverr = 2;
			test_wr_rsp_seq.no_test_decerr = 2;
			test_rd_rsp_seq.no_test_slverr = 2;
			test_rd_rsp_seq.no_test_decerr = 2;
			test_wr_rsp_seq.gen_item();
			test_rd_rsp_seq.gen_item();
		//
		fork
			test_wr_rsp_seq.start(A1);
			test_rd_rsp_seq.start(A2);
		join
		`uvm_info(get_type_name(), $sformatf("test_response_seq done!!!"), UVM_LOW);
	end//run
	begin
		ApbSeq.start(B);
	end
	join
    endtask
endclass

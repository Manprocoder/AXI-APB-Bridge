//-----------------------------------------------------------------------
//--virtual sequence (Reset, Axi Master Read, Axi Master Write, Apb Slave)
//--description:  ALL WRITE -> ON READ -> ON READ -> ON WRITE
//--AIM: 
//--check ip core operation after run-time reset, and only read OR only write
//----------------------------------------------------------------
import type_package::*;
class wr_rd_rd_wr_vseq extends base_vseq;
    AxiResetSeq ResetSeq;
    AxiMasterWriteSeq#(DW,AW1) WriteSeq1, WriteSeq2;
    AxiMasterReadSeq#(DW,AW1) ReadSeq1, ReadSeq2;
    apb_seq #(DW,AW2) ApbSeq;
    //register to factory
    `uvm_object_utils(wr_rd_rd_wr_vseq)
    // `uvm_declare_p_sequencer(vsequencer)
    parameter BASE_ADDR = 32'h0000_0000;
    parameter BASE_ADDR1 = 32'h0000_1000;
    parameter REQ_NUM = 100;
    //
    function new(string name = "wr_rd_rd_wr_vseq");
        super.new(name);
    endfunction
    //main task
    task body();
        ResetSeq = AxiResetSeq::type_id::create("ResetSeq");
        ReadSeq1 = AxiMasterReadSeq#(DW,AW1)::type_id::create("ReadSeq1");
        ReadSeq2 = AxiMasterReadSeq#(DW,AW1)::type_id::create("ReadSeq2");
        WriteSeq1 = AxiMasterWriteSeq#(DW,AW1)::type_id::create("WriteSeq1");
        WriteSeq2 = AxiMasterWriteSeq#(DW,AW1)::type_id::create("WriteSeq2");
        ApbSeq = apb_seq#(DW,AW2)::type_id::create("ApbSeq");
        //
        for(int i = 0; i < REQ_NUM; i++) begin
            if(i==0) begin
                ReadSeq1.raddr_q.push_back(BASE_ADDR);
                ReadSeq2.raddr_q.push_back(BASE_ADDR);
            end
            else begin
                ReadSeq1.raddr_q.push_back(BASE_ADDR1 + i*4);
                ReadSeq2.raddr_q.push_back(BASE_ADDR1 + i*4);
            end
            //
            WriteSeq1.waddr_q.push_back(BASE_ADDR1 + i*4); 
            WriteSeq2.waddr_q.push_back(BASE_ADDR1 + i*4); 
            //
            ReadSeq1.rburst_q.push_back(burst_pattern[i % 3]);
            WriteSeq1.wburst_q.push_back(burst_pattern[i % 3]);
            //
            ReadSeq2.rburst_q.push_back(burst_pattern[i % 3]);
            WriteSeq2.wburst_q.push_back(burst_pattern[i % 3]);
        end
        //
        ReadSeq1.start_id = 100;
        WriteSeq1.start_id = 100;
        ReadSeq2.start_id = 0;
        WriteSeq2.start_id = 0;
        //
        ResetSeq.rst_value_q = {1'b0, 1'b1};
        ResetSeq.rst_run_time_en = 1'b0;
        //
        fork
            begin
                `uvm_info(get_type_name(), $sformatf("reset_case_vseq start!!!"), UVM_LOW);
                fork
					begin
						ResetSeq.start(R);
					end
					//
					begin
                        WriteSeq1.start(A1);	
						ReadSeq1.start(A2); 
						ReadSeq2.start(A2); 
                        WriteSeq2.start(A1);	
					end
                join
                //
            end
            begin
                ApbSeq.start(B);
            end
            //
        join
        //
        `uvm_info(get_type_name(), $sformatf("reset_case_vseq done!!!"), UVM_LOW);
        //
    endtask
endclass

//-----------------------------------------------------------------------------
//class description
//-----------------------------------------------------------------------------
//declare all functions that relate to ports of Monitor
`uvm_analysis_imp_decl(_Aresetn)
`uvm_analysis_imp_decl(_AxiRdRequest)
`uvm_analysis_imp_decl(_AxiRData)
`uvm_analysis_imp_decl(_AxiWrRequest)
`uvm_analysis_imp_decl(_AxiWData) 
`uvm_analysis_imp_decl(_AxiBresp) 
`uvm_analysis_imp_decl(_Presetn)    
`uvm_analysis_imp_decl(_Pseltb)    
`uvm_analysis_imp_decl(_ApbContent)  
import type_package::*; 
//
class scoreboard extends uvm_scoreboard;
    //register UVM factory
    `uvm_component_utils(scoreboard)
    //AXI Monitor imp ports
    uvm_analysis_imp_Aresetn #(logic, scoreboard) aimp_Aresetn;
    uvm_analysis_imp_AxiRdRequest #(req_info, scoreboard) aimp_AxiRdRequest;
    uvm_analysis_imp_AxiRData #(shared_item, scoreboard) aimp_AxiRData;
    uvm_analysis_imp_AxiWrRequest #(req_info, scoreboard) aimp_AxiWrRequest;
    uvm_analysis_imp_AxiWData #(shared_item, scoreboard) aimp_AxiWData;
    uvm_analysis_imp_AxiBresp #(b_channel_info, scoreboard) aimp_AxiBresp;
    //APB Monitor imp ports
    uvm_analysis_imp_Presetn #(logic, scoreboard) aimp_Presetn;
    uvm_analysis_imp_Pseltb #(logic [`SLAVE_CNT-1:0], scoreboard) aimp_Pseltb;
    uvm_analysis_imp_ApbContent #(shared_item, scoreboard) aimp_ApbContent;
    //--------------------------------------
    //data members
    //---------------------------------------
    //(1.a) queues
    req_info rd_req_q [$];
    req_info wr_req_q [$];
    shared_item axi_rdata_q [$];
    shared_item axi_wdata_q [$];
    b_channel_info actual_bchannel_q [$];
    b_channel_info expected_bchannel_q [$];
    shared_item apb_content_q [$];
    //
    logic [31:0] apb_base_end_addr_q [$];
    logic [31:0] base_addr, end_addr;
    //(1.b) struct types
    //
    req_info raw_req;
    parsed_req_info parsed_req;
    resp_name latch_resp;
    //(2) checkers
    int match, mismatch;
    //(3) reset
    bit axi_rst_flg;
    bit apb_rst_flg;
    //
    bit axi_transaction_valid;
    bit vld_addr = 0;
    //(4) arbiter
    bit [1:0] arbiter; //[1]: write, [0] read
    bit trans_completed = 0; //transaction comparison done
    //(5)
    bit slv_addr_blk_sel = 0;
    int apb_base_end_addr; //temporarily contains apb slave's BASE or END address to compare 
    bit last_transfer = 0;
    int addr_q_idx = 0;//access APB_SLAVE_ADDR queue
    int transfer_index = 0; //serve to calculate axi transfer address OR 
    bit exit_req_while_loop = 0;
    bit exit_data_while_loop = 0;
    //handle in long wait (hang infinite loop)
    int axi_req_wait_cnt = 0;//avoid waiting infinite loop with empty status of rd_req_q OR wr_req_q
    int axi_data_wait_cnt = 0; //avoid waiting infinite loop with empty status of axi_rdata_q OR axi_wdata_q
    int apb_data_wait_cnt = 0;
    int bresp_wait_cnt = 0;//
    shared_item axi_content, apb_content; //common content of two protocol (wr_rd enable, data, wstrb, resp, last)
    //
    //store simulation comparison result and print all in report_phase task
    //
    result_info sim_result_q [$];
    result_info Transaction_result;
	//file variable
	int sim_summary_file;
    int compare_file;
    string sim_result_path;
    //
    //constructor
    //
    function new(string name ="scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction
    //-------------------------------------------------
    //-- build_phase() function
    //---------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        //AXI
        aimp_Aresetn = new ("aimp_Aresetn", this);
        aimp_AxiRdRequest = new ("aimp_AxiRdRequest", this);
        aimp_AxiRData = new ("aimp_AxiRData", this);
        aimp_AxiWrRequest = new ("aimp_AxiWrRequest", this);
        aimp_AxiWData = new ("aimp_AxiWData", this);
        aimp_AxiBresp = new ("aimp_AxiBresp", this);
        //APB
        aimp_Presetn = new ("aimp_Presetn", this);
        aimp_ApbContent = new ("aimp_ApbContent", this);
        aimp_Pseltb = new ("aimp_Pseltb", this);
        //initialize new sequence item to avoid "BAD handles" error
        axi_content = shared_item::type_id::create("axi_item");
        apb_content = shared_item::type_id::create("apb_item");
        //
        //queue to store base and end address of supported APB SLAVES
        for (int i = 0; i < APB_BASE_END_ADDR_QUEUE_WIDTH; i++) begin
            base_addr = 32'h0000_1000 * (i+1);
            end_addr  = base_addr + 32'h0000_0FFF;
            apb_base_end_addr_q.push_back(base_addr);
            apb_base_end_addr_q.push_back(end_addr);
        end
        //
        if (!uvm_config_db#(string)::get(this, "", "sim_result_path", sim_result_path)) begin
         `uvm_fatal(get_type_name(), "No sim_result_path found in config DB!!!")
        end

        `uvm_info(get_type_name(), $sformatf("Results will be stored at: %s", sim_result_path), UVM_LOW)
    endfunction

    //-------------------------------------------------------------------------------
    //---------------------PUSH DATA FROM MONITOR INTO EACH QUEUE
    //-------------------------------------------------------------------------------
    //----AXI Protocol
    //(1)
    virtual function void write_Aresetn(logic arst_n);
        if (~arst_n) begin
            axi_rst_flg = 1'b1;
            sim_result_q.delete();
            rd_req_q.delete();
            axi_rdata_q.delete();
            wr_req_q.delete();
            axi_wdata_q.delete();
            actual_bchannel_q.delete();
            expected_bchannel_q.delete();
            apb_content_q.delete();
            //
            match = 0;
            mismatch = 0;
		   `uvm_info(get_type_name(), $sformatf("[%0t ns] areset_n signal is acting", $time), UVM_LOW)
		end
        else begin
		   axi_rst_flg = 1'b0;
        end
    endfunction
    //(2)
    virtual function void write_AxiRdRequest(req_info rd_req);
        rd_req_q.push_back(rd_req);
    endfunction
    //(3)
    virtual function void write_AxiRData(shared_item RdContent);
        axi_rdata_q.push_back(RdContent);
        //
    endfunction
    //(4)
    virtual function void write_AxiWrRequest(req_info wr_req);
        wr_req_q.push_back(wr_req);
    endfunction
    //(5)
    virtual function void write_AxiWData(shared_item WrContent);
        axi_wdata_q.push_back(WrContent);
    endfunction
    //(6)
    virtual function void write_AxiBresp(b_channel_info B_Channel);
        actual_bchannel_q.push_back(B_Channel);
    endfunction
    //
    //----APB Protocol
    //(1)
    virtual function void write_Presetn(logic preset_n);
        if(~preset_n) begin
		   apb_rst_flg = 1'b1;
		   `uvm_info(get_type_name(), $sformatf("[%0t ns] preset_n signal is acting", $time), UVM_LOW)
		end
        else begin
		   apb_rst_flg = 1'b0;
        end
    endfunction
    //
    //(2)
    virtual function void write_ApbContent(shared_item ApbContent);
        apb_content_q.push_back(ApbContent);
    endfunction
    //
    //(3)
    virtual function void write_Pseltb(logic [`SLAVE_CNT-1:0] psel_tb);
        if ($countones(psel_tb) > 1) begin
		   `uvm_error(get_type_name(),
            $sformatf("[PSEL_ACTIVE_ERROR][%0t ns] multiple APB psel are active at the same time!!!", $time))
        end
    endfunction
    //-------------------------------------------------------------------------------
    //---------------------HANDLE WR_RD ARBITER
    //-------------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        //
        forever begin
            grant_request();
            #(`CLK_CYCLE);  //commenting out this line causes UVM_TB collapse---CRITICAL WARNING 
            //--because grant_request() grant process_data to run via "arbiter" variable
            //--arbiter needs DELAY to update new value
            process_data();
        end
        //
    endtask
    //**************************************************************************************************
    //----------------------------------------MAIN TASKS----------------------------------------------
    //**************************************************************************************************
    task grant_request();
        if(axi_rst_flg == 1'b1) begin
            `uvm_info(get_type_name(), $sformatf("ARBITER ON RESET!!!"), UVM_LOW)
            arbiter = 2'b01;
        end
        else begin
            if(trans_completed == 1'b1) begin //transaction_comparison_done
                if(arbiter[0] == 1'b1) begin
                    if(wr_req_q.size() > 0) begin
                        arbiter = 2'b10;
                    end
                    else arbiter = arbiter;
                end
                else if(arbiter[1] == 1'b1) begin
                    if(rd_req_q.size() > 0) begin
                        arbiter = 2'b01;
                    end
                    else arbiter = arbiter;
                end
                else arbiter = arbiter;
                //
            end //end of if transaction_comparison_done
            else begin
                arbiter = arbiter;
            end
        end
    endtask
    //-------------------------------------------------
    //-- COMPARISON TASK WITH REFERENCE MODEL
    //--------------------------------------------------
task process_data();
    if(axi_rst_flg == 1'b1) begin
        `uvm_info(get_type_name(), $sformatf("HIGH-LEVEL AXI_RST_FLAG!!!"), UVM_LOW);
    end
    else begin
        fork 
            begin //FIRST THREAD
                @(posedge axi_rst_flg);
                `uvm_info(get_type_name(), $sformatf("RISING EDGE AXI_RST_FLAG!!!"), UVM_LOW);
            end
            begin //SECOND_THREAD
                axi_transaction_valid = 1'b0;
                vld_addr = 1'b0;
                trans_completed = 1'b0;
                match = 0;
                mismatch = 0;
                last_transfer = 1'b0;
                axi_data_wait_cnt = 0;
                apb_data_wait_cnt = 0;
                axi_req_wait_cnt = 0;
                latch_resp = resp_name'(2'b00);
                transfer_index = 0;
                addr_q_idx = 0;
                clr_req(raw_req);
                clr_req(parsed_req);
                case(arbiter) 
                    //MASTER_READ
                    2'b01: begin
                        //Fetch valid request to parse and compare
                        Fetch_Vld_Req(1'b0, axi_transaction_valid);
                        if(axi_transaction_valid) begin
				`uvm_info(get_type_name(), $sformatf("[READ] VALID"), UVM_LOW);
                            slv_addr_blk_sel = check_slv_addr_blk_selected(raw_req.address);
                            Do_Comparison(slv_addr_blk_sel, 1'b0);
                            Check_Trans_Completion(raw_req.id, 1'b0, 1'b1, 1'b0); 
                        end
                    end //end of MASTER_READ
		//MASTER_WRITE
                    2'b10: begin
                        Fetch_Vld_Req(1'b1, axi_transaction_valid);
                        if(axi_transaction_valid) begin
				`uvm_info(get_type_name(), $sformatf("[WRITE] VALID"), UVM_LOW);
                            Store_ExpectedWriteResp(raw_req.id[7:0], resp_name'(2'b00));
                            Do_Comparison(1'b0, 1'b1);
// [8:0] id,
// timeout_req,
// timeout_data,
// pop_unvalid_data_done
                            Check_Trans_Completion(raw_req.id, 1'b0, 1'b1, 1'b0); 
                        end
                    end //end of MASTER_WRITE
                endcase
            end //end of SECOND_THREAD
        join_any
        disable fork;
    end //end of else if(axi_rst_flag = 1)
endtask
    //**************************************************************************************************
    //-------------------------------------SUB TASKS
    //**************************************************************************************************
//
//Operation Order:
//--1: check unvalid req -> pop unvalid data
//--2: check slave addr block selected -> if read, task return 1 otherwise task return 0
//--3: return valid req and do compare     
virtual task Fetch_Vld_Req
(
    input bit wr_en,
    output bit req_valid
);
    //
    bit queue_not_empty;
    bit slv_addr_blk_en;
    bit valid_type_order;
    bit error_case;
    req_info temp_req;
    //
    begin
        while (1) begin
            queue_not_empty = (wr_en) ? (wr_req_q.size() > 0) : (rd_req_q.size() > 0);
            if(queue_not_empty) begin
		clr_req(temp_req); //refresh struct before receving new request
                //addr_tmp = wr_en ? (wr_req_q[0].address) : (rd_req_q[0].address);
		temp_req = wr_en ? wr_req_q[0] : rd_req_q[0];
		error_case = (temp_req.size != 3'b010) | (temp_req.burst == 2'b11);
                //
                if(!Check_Valid_Addr(temp_req.address) || (error_case)) begin
                    raw_req = (wr_en) ? (wr_req_q.pop_front()) : (rd_req_q.pop_front());
                    if(wr_en) begin
			if(error_case) 
                        Store_ExpectedWriteResp(raw_req.id[7:0], resp_name'(2'b10));
			else 
                        Store_ExpectedWriteResp(raw_req.id[7:0], resp_name'(2'b11));
                    end
                    Pop_unvalid_data(wr_en, raw_req);
// [8:0] id,
// timeout_req,
// timeout_data,
// pop_unvalid_data_done
                    Check_Trans_Completion(raw_req.id, 1'b0, 1'b0, 1'b1); 
                    req_valid = 1'b0;
                end
                else begin
                    slv_addr_blk_en = check_slv_addr_blk_selected(temp_req.address);
                    // `uvm_info(get_type_name(), $sformatf("[VALID_ADDR]address = %08h", addr_tmp), UVM_LOW)
                    // `uvm_info(get_type_name(), $sformatf("[VALID_ADDR]slv_addr_blk_en = %0b", slv_addr_blk_en), UVM_LOW)
                    if(slv_addr_blk_en) begin
                        raw_req = (wr_en) ? wr_req_q.pop_front() : rd_req_q.pop_front();
                        if(wr_en) begin
                            Store_ExpectedWriteResp(raw_req.id[7:0], resp_name'(2'b10));
                            Pop_unvalid_data(1'b1, raw_req);
                            Check_Trans_Completion(raw_req.id, 1'b0, 1'b0, 1'b1); 
                            req_valid = 1'b0;
                        end
                        else begin
                            req_valid = 1'b1;
                        end
                    end
                    else begin
                        Check_Apb_Transfer_Type(wr_en, valid_type_order);
                        if(valid_type_order) begin
                            raw_req = (wr_en) ? wr_req_q.pop_front() : rd_req_q.pop_front();
                            req_valid = 1'b1;
                        end
                        else req_valid = 1'b0;
                    end
                end
                //
                break; //exit while(1)
            end //end of if queue_not_empty
            else begin
                axi_req_wait_cnt++;
                #(`CLK_CYCLE);
                //wr enable, bresp en
                handle_wait_req(wr_en, axi_req_wait_cnt, exit_req_while_loop);
                if(exit_req_while_loop==1) begin
                    req_valid = 1'b0;
                    #(`CLK_CYCLE);
                    break;//exit while(1) 
                end
            end
        end
    end
endtask
    //
    virtual function bit Check_Valid_Addr(
        input logic [31:0] start_address
    );
        begin
            if((start_address >= A_START_REG) && (start_address <= apb_base_end_addr_q[`SLAVE_CNT*2-1])) begin
                return 1;
            end
            else begin
                return 0;
            end
        end
    endfunction
    //
    //
    virtual function bit check_slv_addr_blk_selected(
        input logic [31:0] address
    );
        begin
            // `uvm_info(get_type_name(), $sformatf("A_END_REG = 0x%08h", A_END_REG), UVM_LOW)
            if((address >= A_START_REG) && (address <= A_END_REG)) begin 
                return 1;
            end
            else begin
                return 0;
            end
        end
    endfunction
    //
    virtual task Check_Apb_Transfer_Type(
        input bit wr_en,
        output bit valid_order
    );
        //
        bit apb_trans_ready;
        shared_item apb_temp;
        //
        case(arbiter)
            //READ
            2'b01: begin
                Wait_Apb_Transfer(1'b0, 1'b0, apb_trans_ready);
                //
                if(apb_trans_ready) begin
                    // `uvm_info(get_type_name(), $sformatf("[READ]apb_content_q.size = %0d", apb_content_q.size()), UVM_LOW)
                    apb_temp = apb_content_q[0];
                    if(apb_temp.write == 1'b1) begin
                        post_grant_request();//regrant request
                        valid_order = 1'b0;//not ready to compare
                    end
                    else begin
                        valid_order = 1'b1;//ready to compare
                    end
                    // `uvm_info(get_type_name(), $sformatf("[READ]apb_content_q.size = %0d", apb_content_q.size()), UVM_LOW)
                end
                else begin
                    valid_order = 1'b0; //not ready to compare
                    `uvm_info(get_type_name(), $sformatf("[CHECK_APB_TRANSFER_TYPE]: UNAVAILABLE APB TRANSFER"), UVM_LOW)
                end
            end
            //WRITE
            2'b10: begin
                Wait_Apb_Transfer(1'b1, 1'b0, apb_trans_ready);
                //
                if(apb_trans_ready) begin
                    // `uvm_info(get_type_name(), $sformatf("[WRITE]apb_content_q.size = %0d", apb_content_q.size()), UVM_LOW)
                    apb_temp = apb_content_q[0];
                    if(apb_temp.write == 1'b0) begin
                        post_grant_request(); //regrant request
                        valid_order = 1'b0; //not ready to compare
                    end
                    else begin
                        valid_order = 1'b1; //ready to compare
                    end
                    // `uvm_info(get_type_name(), $sformatf("[WRITE]apb_content_q.size = %0d", apb_content_q.size()), UVM_LOW)
                end
                else begin
                    valid_order = 1'b0; //not ready to compare
                    `uvm_info(get_type_name(), $sformatf("[CHECK_APB_TRANSFER_TYPE]: UNAVAILABLE APB TRANSFER"), UVM_LOW)
                end
            end
        endcase
    endtask
    //
    //regrant arbiter value as unproper order 
    //
    virtual function void post_grant_request();
        //
        if(arbiter[0] == 1'b1) begin
            arbiter = 2'b10;
            `uvm_info(get_type_name(), $sformatf("[POST_GRANT_REQUEST]: FROM-READ-TO-WRITE!!!"), UVM_LOW)
        end
        else if(arbiter[1] == 1'b1) begin
            arbiter = 2'b01;
            `uvm_info(get_type_name(), $sformatf("[POST_GRANT_REQUEST]: FROM-WRITE-TO-READ!!!"), UVM_LOW)
        end
    endfunction
    //
    //
    virtual task Do_Comparison(
        input bit read_slave_addr_enable,
        input bit wr_en
    );
        //
        bit queue_not_empty;
        bit apb_trans_exist;
        bit valid_access;
        //
        begin
            //at first, program parses request
            parsed_req = parse_request(raw_req);
            if(read_slave_addr_enable) begin //READ_SLV_ADDR_BLOCK
                while(1) begin //READ2
                    if(axi_rdata_q.size() > 0) begin
                        clr_content();
                        axi_content = axi_rdata_q.pop_front();
                        axi_content.addr = calculate_next_addr(transfer_index, parsed_req); 
                        //
                        //handle k index and access(not pop_front) apb_base_end_addr_q to compare actual x2p_register block output
                        //
                        addr_q_idx = axi_content.addr[7:0] / 3'd4;
                        valid_access = ((axi_content.addr[7:0] % 3'd4) == 0) && (addr_q_idx <= `SLAVE_CNT*2-1);
                        apb_base_end_addr = (valid_access) ? apb_base_end_addr_q[addr_q_idx] : 32'hFFFF_E000;
                        //
                        compare_transfer(1'b1, raw_req.id, axi_content, apb_content, transfer_index, apb_base_end_addr);
                        transfer_index++;
                        axi_data_wait_cnt = 0; //reset counter as valid data exists
                        //
                        last_transfer = axi_content.last;
                        latch_resp = resp_name'(latch_resp | axi_content.resp);
                        //
                        if(last_transfer==1'b1) begin
                            handle_last_transfer(raw_req, latch_resp, match, mismatch);
                            #(`CLK_CYCLE);
                            break; //exit while(1) READ2
                        end
                        //
                    end//end of if axi_rdata_q.size() > 0
                    else begin //fastidiously handle to avoid waiting infinite loop
                        axi_data_wait_cnt++;
                        #(`CLK_CYCLE);
        //slv_addr_blk_en;
        //wr_en
        //axi_or_apb;
        //data_wait_cnt;
        //raw_req;
        //match_cnt;
        //mismatch_cnt;
        //output bit break_enable;
                        handle_wait_data(1'b1, wr_en, 1'b0, axi_data_wait_cnt, raw_req, match, mismatch, exit_data_while_loop);
                        if(exit_data_while_loop==1) begin
                            #(`CLK_CYCLE);
                            break;//exit while(1) READ2
                        end
                    end
                end //end of while(1)
            end //end of READ_SLV_ADDR_BLOCK
            //**************************************************************
            //--------------------AXI - APB
            //**************************************************************
            else begin //Do compare officially between AXI and APB
                // parsed_req = parse_request(raw_req);
                // `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: APB_QUEUE_SIZE = %0d", apb_content_q.size()), UVM_LOW)
                while(1) begin
                    queue_not_empty = (wr_en) ? (axi_wdata_q.size() > 0) : (axi_rdata_q.size() > 0);
                    if (queue_not_empty) begin
                        clr_content();
                        /*-------check emergence of apb transfer---------*/
                        get_apb_data(wr_en, apb_trans_exist);
                        // `uvm_info(get_type_name(),
                        // $sformatf("[DO_COMPARE]: APB_QUEUE_SIZE = %0d", apb_content_q.size()), UVM_LOW)
                        /*-----------------------------------------------*/
                        if(apb_trans_exist) begin
                            axi_content = (wr_en) ? (axi_wdata_q.pop_front()) : (axi_rdata_q.pop_front());
                            axi_content.addr = calculate_next_addr(transfer_index, parsed_req); 
                            //
                            compare_transfer(1'b0, raw_req.id, axi_content, apb_content, transfer_index, 0);
                            transfer_index++;
                            axi_data_wait_cnt = 0; //reset counter as valid data exists
                            //
                            last_transfer = axi_content.last;
                            //
                            if(last_transfer == 1'b1) begin
                                handle_last_transfer(raw_req, axi_content.resp, match, mismatch);
                                break; //exit while(1) 
                            end
                        end //end of if apb_trans_exist
                        else begin
                            `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: APB TRANSFER NOT EXIST!!!"), UVM_LOW)
                            break;//exit while(1)
                        end
                    end //end of if queue_not_empty
                    else begin
                        axi_data_wait_cnt++;
                        #(`CLK_CYCLE);
        //slv_addr_blk_en;
        //wr_en
        //axi_or_apb;
        //data_wait_cnt;
        //raw_req;
        //match_cnt;
        //mismatch_cnt;
        //output bit break_enable;
                        handle_wait_data(1'b0, wr_en, 1'b1, apb_data_wait_cnt, raw_req, match, mismatch, exit_data_while_loop);
                        if(exit_data_while_loop==1) begin
                            #(`CLK_CYCLE);
                            break;//exit while(1) 
                        end
                    end
                end//end of while(1)
                // `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: APB_QUEUE_SIZE = %0d", apb_content_q.size()), UVM_LOW)
            end
        end
    endtask
    //
    //
    virtual task get_apb_data(
        input bit wr_en,
        output bit apb_trans_exist
    );
        //
        bit apb_trans_ready;
        //
        begin
            Wait_Apb_Transfer(wr_en, 1'b1, apb_trans_ready);
            if(apb_trans_ready) begin
                apb_content = apb_content_q.pop_front();
                apb_trans_exist = 1'b1;
            end
            else begin
                apb_trans_exist = 1'b0;
            end
        end
    endtask
    //
    //
    virtual task Wait_Apb_Transfer(
        input bit wr_en,
        input bit cmp_running,
        output bit apb_trans_rdy
    );
        begin //begin_end block
            while(1) begin //
                if(apb_content_q.size() > 0) begin
                    apb_trans_rdy = 1'b1;
                    apb_data_wait_cnt = 0;
                    break;
                end //end of if apb_content_q.size() > 0
                else begin //unavailable_apb
                    apb_data_wait_cnt++;
                    #(`CLK_CYCLE);
        //slv_addr_blk_en;
        //wr_en
        //axi_or_apb;
        //data_wait_cnt;
        //raw_req;
        //match_cnt;
        //mismatch_cnt;
        //output: exit_data_while_loop
                    if(cmp_running) begin
                        handle_wait_data(1'b0, wr_en, 1'b0, apb_data_wait_cnt, raw_req, match, mismatch, exit_data_while_loop);
                        if(exit_data_while_loop==1) begin
                            apb_trans_rdy = 1'b0;
                            #(`CLK_CYCLE);
                            break;//exit while(1) 
                        end
                    end
                    else begin
                        if(apb_data_wait_cnt > TIME_OUT_BOUNDARY) begin
                            apb_trans_rdy = 1'b0;
                            `uvm_warning(get_type_name(), $sformatf("TIMEOUT TIMEOUT TIMEOUT: Wait APB Transfer"))
                            #(`CLK_CYCLE);
                            break;
                        end
                    end
                end//unavailable_apb
            end//end of while(1) 
        end//begin_end block
    endtask
    //
    //
    virtual task Pop_unvalid_data(
        input bit wr_en,
        input req_info req
    );
        //
        bit queue_not_empty;
        begin
            //
            while(1) begin
                queue_not_empty = (wr_en) ? (axi_wdata_q.size() > 0) : (axi_rdata_q.size() > 0);
                if (queue_not_empty) begin
                    clr_content();
                    axi_content = (wr_en) ? (axi_wdata_q.pop_front()) : (axi_rdata_q.pop_front());
                    last_transfer = axi_content.last;
                    axi_data_wait_cnt = 0;
                    //
                    if(last_transfer == 1'b1) begin
                        handle_last_transfer(req, axi_content.resp, match, mismatch);
                        break; //exit while(1) 
                    end
                end else begin
                    axi_data_wait_cnt++;
                    #(`CLK_CYCLE);
    //slv_addr_blk_en;
    //wr_en
    //axi_or_apb;
    //data_wait_cnt;
    //raw_req;
    //match_cnt;
    //mismatch_cnt;
    //output bit break_enable;
                    handle_wait_data(1'b0, wr_en, 1'b1, axi_data_wait_cnt, raw_req, match, mismatch, exit_data_while_loop);
                    if(exit_data_while_loop==1) begin
                        #(`CLK_CYCLE);
                        break;//exit while(1) 
                    end
                end
            end
            //
        end
    endtask
    //
    //
    virtual task Store_ExpectedWriteResp;
        input logic [7:0] id;
        input resp_name rsp;
        //
        b_channel_info b_handle;
        begin
            b_handle.bid = id;
            b_handle.bresp = resp_name'(rsp);
            expected_bchannel_q.push_back(b_handle);
        end
    endtask

//***********************************************************************************
//--------------------------VITAL FUNCTION---------------------
//***********************************************************************************
function parsed_req_info parse_request(
    input req_info raw_req
);
    //inter-function variables
    //
    int req_file;
    string header;
    logic [2:0] applied_size;
    parsed_req_info req; 
  //
  begin
    //declare
    //
    // req_file = $fopen($sformatf("../SIM_RESULT/SLAVE%0d/REQ_INFO/req_detail.log", `SLAVE_CNT), "a"); // "w" = overwrite, "a" = append
    req_file = $fopen($sformatf("%s/REQ_INFO/req_detail.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
	if(req_file == 0) begin
		`uvm_warning(get_type_name(), $sformatf("Failed to open req_detail.log"))
	end
	req.id = raw_req.id;
    req.start_address = raw_req.address;
    req.size = raw_req.size;
    req.len = raw_req.len + 1;
    req.burst = raw_req.burst;
    //refresh size value
    // applied_size = (raw_req.size != 3'b010) ? 3'b010 : raw_req.size; 
    //---------------------------------------------------
    // pre-calculate address details
    //---------------------------------------------------
    req.bytes_in_transfer = 2**raw_req.size;
    //incr addr
    req.total_bytes = req.bytes_in_transfer * req.len;    
    req.aligned_address = (req.bytes_in_transfer!=0) 
    ? (int'(req.start_address/req.bytes_in_transfer)) * req.bytes_in_transfer : 'hz;
    //wrap addr
    req.wrap_boundary = (int'(req.start_address/req.total_bytes)) * req.total_bytes;
	req.wrap_highest_address = req.wrap_boundary + req.total_bytes; 
	//
	if(raw_req.burst == 2'b10) begin
	header = (raw_req.id[8] == 1'b1) ? "WRITE" : "READ";
	$fdisplay(req_file, $sformatf("ALIGNED_ADDR[%s][%0d]: 0x%08h", header, raw_req.id, req.aligned_address));
    $fdisplay(req_file, $sformatf("WRAP_BOUNDARY[%s][%0d]: 0x%08h", header, raw_req.id, req.wrap_boundary));
    $fdisplay(req_file, $sformatf("TOTAL_BYTES: %0d", req.total_bytes));

    $fdisplay(req_file, $sformatf("WRAP_HIGHEST_ADDR: 0x%08h", req.wrap_highest_address));
	$fdisplay(req_file, "*********************************************************************************");
	end
  end
  //
  $fclose(req_file);
  //
  return req;
  //
endfunction
//
//function to calculate address
//
virtual function logic [31:0] calculate_next_addr(
    input int i,
    input parsed_req_info req
);
	//
	string header;
    logic [31:0] next_address;
	//
    begin
		header = (req.id[8] == 1) ? "WRITE" : "READ";
        //
        if(req.burst == 2'b00)begin  //fixed
            next_address = req.start_address;
        end
        else if (req.burst == 2'b01) begin //incr
            if(i==0) begin
                next_address = req.start_address;
            end
            else 
                next_address = req.aligned_address + i * req.bytes_in_transfer;
        end
        else if (req.burst == 2'b10) begin //wrap
            next_address = req.aligned_address + i * req.bytes_in_transfer;
            if(next_address == req.wrap_highest_address) begin
                next_address = req.wrap_boundary;
            end
            else if(next_address > req.wrap_highest_address) begin
            //`uvm_info(get_type_name(), $sformatf("[%s][id: %0d][%0d]: next_wrap_address = 0x%08h", header, req.id[7:0], i, next_address),UVM_LOW);
                next_address = req.wrap_boundary + (next_address - req.wrap_highest_address); 
            end
            else begin
                next_address = next_address;
            end   
        end //end of  "else if (m_mon_vif.awburst == 2'b10)""
        else begin //RESERVED burst
            if(i==0) next_address = req.start_address;
            else next_address = 32'd0;
        end
        //recalculate address, only supports 4-byte transfer 
        //next_address = (req.size != 3'b010) ? 32'd0 : next_address;
        //
        return next_address;
    end
endfunction
//
//compare task
//
virtual task compare_transfer(
    input bit slv_addr_blk_en,
    input logic [8:0] id,
    input shared_item axi_transfer,
    input shared_item apb_transfer,
    input int i,
    input logic [31:0] apb_slv_addr_blk_data
);
    //
    string header;
    bit rid_match;
    string rid_header;
    //
    begin
		//open file
        `ifdef PRINT_TO_SUM_FILE
        //
        compare_file = $fopen($sformatf("%s/COMPARE/cmp.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
		if(compare_file == 0) begin
			`uvm_warning(get_type_name(), $sformatf("Failed to open cmp.log"))
		end
        `endif
        //
        header = (id[8] == 1'b1) ? "wr_transfer" : "rd_transfer";
        rid_match = (id[8] == 1'b1) ? 1'b1 : (id[7:0] == axi_transfer.id);
        //
        if(slv_addr_blk_en) begin
            $sformat(rid_header, "--RID=%0d--RRESP=%s", axi_transfer.id, axi_transfer.resp.name());
            //
            if((axi_transfer.data == apb_slv_addr_blk_data) && rid_match) begin
                `ifdef PRINT_TO_SUM_FILE
                    $fdisplay(compare_file,
                    $sformatf("%s[%0d][%0d][%0t ns] match:\n AXI_RDATA: 0x%08h---SLV_ADDR_BLOCK: 0x%08h-%s",
                    header, id[7:0], (i+1), $time, axi_transfer.data, apb_slv_addr_blk_data, rid_header));
                `else
                    `uvm_info(get_type_name(),
                    $sformatf("%s[%0d][%0d][%0t ns] match:\n AXI_RDATA: 0x%08h---SLV_ADDR_BLOCK: 0x%08h-%s",
                    header, id[7:0], (i+1), $time, axi_transfer.data, apb_slv_addr_blk_data, rid_header), UVM_LOW)
                `endif
                match++;
            end
            else begin
                `ifdef PRINT_TO_SUM_FILE
                    $fdisplay(compare_file,
                    $sformatf("%s[%0d][%0d][%0t ns] mismatch:\n AXI_RDATA: 0x%08h---SLV_ADDR_BLOCK: 0x%08h-%s",
                    header, id[7:0], (i+1), $time, axi_transfer.data, apb_slv_addr_blk_data, rid_header));
                `else
                    `uvm_info(get_type_name(),
                    $sformatf("%s[%0d][%0d][%0t ns] mismatch:\n AXI_RDATA: 0x%08h---SLV_ADDR_BLOCK: 0x%08h-%s",
                    header, id[7:0], (i+1), $time, axi_transfer.data, apb_slv_addr_blk_data, rid_header), UVM_LOW)
                `endif
                mismatch++;
            end
        end //end of if(slv_addr_blk_en)
        else begin
            if(axi_transfer.compare(apb_transfer) && rid_match) begin 
                `ifdef PRINT_TO_SUM_FILE
                $fdisplay(compare_file, 
                        $sformatf("%s[%0d][%0d][%0t ns] is matched:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, id[7:0], (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()));
                `else
                `uvm_info("COMPARE_TRANSFER" 
                        $sformatf("%s[%0d][%0d][%0t ns] is matched:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, id[7:0], (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()), UVM_LOW)
                `endif
                match++;
            end
            else begin
                `ifdef PRINT_TO_SUM_FILE
                $fdisplay(compare_file, 
                        $sformatf("%s[%0d][%0d][%0t ns] is mismatched:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, id[7:0], (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()));
                `else
                `uvm_info("COMPARE_TRANSFER", 
                        $sformatf("%s[%0d][%0d][%0t ns] is mismatched:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, id[7:0], (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()), UVM_LOW)
                `endif
                mismatch++;
            end
        end
        //
        `ifdef PRINT_TO_SUM_FILE
        $fclose(compare_file);
        `endif
        //
    end
endtask
//
//
virtual task clr_req(
	input req_info req
);
	begin
		req.id = 0;
		req.address = 0;
		req.len = 0;
		req.size = 0;
		req.burst = burst_name'(2'b11);
		#(`CLK_CYCLE);
	end
endtask
//
virtual task clr_content;
    //clear old values
    axi_content.clear();
    apb_content.clear();
endtask
//
//
//
virtual task handle_last_transfer(
    input req_info raw_req,
    input resp_name transfer_resp,
    input int match_cnt,
    input int mismatch_cnt
);
    //
    begin
        //store result
        store_comparison_result(raw_req, transfer_resp, match_cnt, mismatch_cnt);
        trans_completed = 1'b1;
        #(`CLK_CYCLE);
    end
endtask
//
virtual task store_comparison_result(
    input req_info req,
    input resp_name actual_status,
    input int match_cnt,
    input int mismatch_cnt
);
    //
    begin
        Transaction_result.id = req.id;
        Transaction_result.address = req.address;
        Transaction_result.len = req.len;
        Transaction_result.size = req.size;
        Transaction_result.burst = req.burst;
        Transaction_result.resp = resp_name'(actual_status);
        Transaction_result.case_matches = match_cnt;
        Transaction_result.case_mismatches = mismatch_cnt;
        //
        sim_result_q.push_back(Transaction_result);
    end
    //
endtask
//
virtual task handle_wait_data(
    input bit slv_addr_blk_en,
    input bit write_enable,
    input bit axi_or_apb,
    input int data_wait_cnt,
    input req_info raw_req,
    input int match_cnt,
    input int mismatch_cnt,
    output bit break_enable
);
    //
    resp_name wait_resp;
    string header;
    //
    begin
        //
        if (data_wait_cnt > TIME_OUT_BOUNDARY) begin
            wait_resp = resp_name'(2'b01);
            store_comparison_result(raw_req, wait_resp, match_cnt, mismatch_cnt);
            trans_completed = 1'b1;
            if(slv_addr_blk_en == 1'b1) begin
                `uvm_info(get_type_name(),
                $sformatf("TRANS[%0d]: Timeout Timeout Timeout--axi_rdata_q([SLV_ADDR_BLOCK]) is EMPTY", raw_req.id[7:0]), UVM_LOW);
            end
            else if(axi_or_apb == 1) begin
                if((write_enable==1'b0) && (axi_rdata_q.size() == 0)) begin
                    `uvm_info(get_type_name(),
                    $sformatf("TRANS[READ][%0d]:Timeout Timeout Timeout--axi_rdata_q is EMPTY", raw_req.id[7:0]), UVM_LOW);
                end
                //
                if((write_enable==1'b1) && (axi_wdata_q.size() == 0)) begin
                    `uvm_info(get_type_name(), 
                    $sformatf("TRANS[WRITE][%0d]:Timeout Timeout Timeout--axi_wdata_q is EMPTY", raw_req.id[7:0]), UVM_LOW);
                end
            end
            else begin
                if(apb_content_q.size() == 0) begin
                    header = write_enable ? "WRITE" : "READ";
                    `uvm_info(get_type_name(),
                    $sformatf("Timeout Timeout Timeout--[%s]apb_content_q is EMPTY", header), UVM_LOW);
                end
            end
            //
            #(`CLK_CYCLE);// delay one cycle to update trans_completed
            break_enable = 1'b1;
        end
        else begin
            break_enable = 1'b0;
        end
    end
endtask
//
//
virtual task handle_wait_req(
    input bit write_enable,
    input int wait_cnt_in,
    output bit break_req
);
    //
    begin
        if (wait_cnt_in > TIME_OUT_BOUNDARY) begin
            trans_completed = 1'b1;
            if(write_enable == 1'b0) begin
                `uvm_warning(get_type_name(),
                $sformatf("Timeout Timeout Timeout: AXI Read Request!!!!"))
                #(`CLK_CYCLE);
                // return;
            end
            else begin
                `uvm_warning(get_type_name(),
                $sformatf("Timeout Timeout Timeout: AXI Write Request!!!!"))
                #(`CLK_CYCLE);
                // return;
            end
            //
            break_req = 1'b1;
        end
        else begin
            break_req = 1'b0;
        end
    end
endtask
//
virtual task Check_Trans_Completion(
    input logic [8:0] id,
    input bit timeout_req,
    input bit timeout_data,
    input bit pop_unvalid_data_done
);
    //
    string header;
    string header2;
    begin
        `ifdef PRINT_TO_SVA1_FILE
        integer sva_file;
        sva_file = $fopen($sformatf("%s/SVA/sva_sb.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
        if(sva_file == 0) begin
            $display("Failed to open sva_sb.log file");
        end
        `endif
        header2 = (id[8] == 1'b1) ? "WRITE" : "READ";
        //
        case({timeout_req, timeout_data, pop_unvalid_data_done})
            3'b100: header = "TIMEOUT_REQUEST";
            3'b010: header = "TIMEOUT_DATA";
            3'b001: header = "TIMEOUT_POP_UNVALID_DATA";
        endcase
        //
        assert(trans_completed)
        else begin
            `ifdef PRINT_TO_SVA1_FILE
            $fdisplay(sva_file, $sformatf("%s[%0d][%s]: trans_completed NO high!!!", header2, id[7:0], header));
            $fclose(sva_file);
            `else
            $error($sformatf("%s[%0d][%s]: trans_completed NO high!!!", header2, id[7:0], header));
            `endif
        end
    end
endtask
//******************************************************************************************************************
//------------------------- report_phase() and final_phase() function
//******************************************************************************************************************
virtual function void report_phase(uvm_phase phase);
    //declare needed variables
    string rw_type;
    string burst_str;
    string resp_str;
    // file variable
    `ifdef PRINT_TO_SUM_FILE
        sim_summary_file = $fopen($sformatf("%s/SIM_SUMMARY/summary.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
		if(sim_summary_file == 0) begin
			`uvm_warning(get_type_name(), $sformatf("Failed to open summary.log file"))
		end
		$fdisplay(sim_summary_file,"================== REPORT SUMMARY =================");
	`else
		`uvm_info(get_type_name(),"================== REPORT SUMMARY =================", UVM_LOW)
	`endif
	
    if (sim_result_q.size() > 0) begin
        foreach (sim_result_q[i]) begin
            rw_type   = (sim_result_q[i].id[8]) ? "WRITE" : "READ_";
            burst_str = sim_result_q[i].burst.name(); // assuming enum has .name()
            resp_str = sim_result_q[i].resp.name(); // assuming enum has .name()
            // print transaction detail
			`ifdef PRINT_TO_SUM_FILE
            $fdisplay(sim_summary_file,
            $sformatf("TRANS[%0d] %s: Addr=0x%04h_%04h Len_1=%0d Size=%0d(bytes_in_beat) Burst=%s Resp=%s | Matches=%0d, MisMatches=%0d",
                sim_result_q[i].id[7:0],
                rw_type,
                sim_result_q[i].address[31:16],
                sim_result_q[i].address[15:0],
                sim_result_q[i].len + 1,
                2**sim_result_q[i].size,
                burst_str,
                resp_str,
                sim_result_q[i].case_matches,
                sim_result_q[i].case_mismatches));
			`else
            `uvm_info(get_type_name(),
            $sformatf("TRANS[%0d] %s: Addr=0x%04h_%04h Len_1=%0d Size=%0d(bytes_in_beat) Burst=%s Resp=%s | Matches=%0d, MisMatches=%0d",
                sim_result_q[i].id[7:0],
                rw_type,
                sim_result_q[i].address[31:16],
                sim_result_q[i].address[15:0],
                sim_result_q[i].len + 1,
                2**sim_result_q[i].size,
                burst_str,
                resp_str,
                sim_result_q[i].case_matches,
                sim_result_q[i].case_mismatches), UVM_LOW);
			`endif
        end
    end
    else begin
        `ifdef PRINT_TO_SUM_FILE
		$fdisplay(sim_summary_file,"======== Simulation Result Queue is EMPTY =========");
        `else 
        `uvm_info(get_type_name(),"======== Simulation Result Queue is EMPTY =========",UVM_LOW);
        `endif
    end
    //empty all queues
    apb_base_end_addr_q.delete();
    sim_result_q.delete();
    //
    `ifdef PRINT_TO_SUM_FILE
	$fdisplay(sim_summary_file,"===================================================");
    `else
    `uvm_info(get_type_name(),"===================================================",UVM_LOW);
    `endif
endfunction
//-------------------------------------------------
//-- final_phase() function
//---------------------------------------------------
virtual function void final_phase(uvm_phase phase);
    logic [7:0] expected_bid;
    logic [7:0] actual_bid;
    resp_name expected_bresp, actual_bresp;
    // b_channel_info expected_b_channel, actual_b_channel;
    `ifdef PRINT_TO_SUM_FILE
	$fdisplay(sim_summary_file,"================== BCHANNEL REPORT =================");
    `else 
    `uvm_info(get_type_name(),"================== BCHANNEL REPORT =================", UVM_LOW);
    `endif 
    if(expected_bchannel_q.size() > 0 && actual_bchannel_q.size() > 0) begin
        foreach(expected_bchannel_q[i]) begin
            if(i > actual_bchannel_q.size()) begin
                `ifdef PRINT_TO_SUM_FILE
                $fdisplay(sim_summary_file, $sformatf("AWIDs = %0d vs BIDs = %0d",
                expected_bchannel_q.size(), actual_bchannel_q.size()));
                `else
                `uvm_warning(get_type_name(),
                $sformatf("AWIDs = %0d vs BIDs = %0d", expected_bchannel_q.size(), actual_bchannel_q.size()))
                `endif 
                break;
            end
            expected_bid = 0;
            actual_bid = 0;
            //
            expected_bid = expected_bchannel_q[i].bid;
            actual_bid = actual_bchannel_q[i].bid;
            expected_bresp = expected_bchannel_q[i].bresp;
            actual_bresp = actual_bchannel_q[i].bresp;
            //
            if(expected_bid == actual_bid) begin
                `ifdef PRINT_TO_SUM_FILE
				$fdisplay(sim_summary_file,
                $sformatf("[COMPARE_BCHANNEL]: expected_bid=%0d MATCH actual_bid=%0d", expected_bid, actual_bid));
                //
				$fdisplay(sim_summary_file,
                $sformatf("[----------------]: expected_bresp=%s VS actual_bresp=%s",
                expected_bresp.name(), actual_bresp.name()));
                `else
                `uvm_info(get_type_name(),
                $sformatf("[COMPARE_BCHANNEL]: expected_bid=%0d MATCH actual_bid=%0d", expected_bid, actual_bid), UVM_LOW);
                //
				`uvm_info(get_type_name(),
                $sformatf("[----------------]: expected_bresp=%s VS actual_bresp=%s",
                expected_bresp.name(), actual_bresp.name()), UVM_LOW);
                `endif
            end
            else begin
                `ifdef PRINT_TO_SUM_FILE
                $fdisplay(sim_summary_file,
                $sformatf("[COMPARE_BCHANNEL]: expected_bid=%0d misMATCH actual_bid=%0d", expected_bid, actual_bid));
                //
				$fdisplay(sim_summary_file,
                $sformatf("[----------------]: expected_bresp=%s VS actual_bresp=%s",
                expected_bresp.name(), actual_bresp.name()));
                `else
                `uvm_info(get_type_name(),
                $sformatf("[COMPARE_BCHANNEL]: expected_bid=%0d misMATCH actual_bid=%0d", expected_bid, actual_bid), UVM_LOW)
                //
				`uvm_info(get_type_name(),
                $sformatf("[----------------]: expected_bresp=%s VS actual_bresp=%s",
                expected_bresp.name(), actual_bresp.name()), UVM_LOW);
                `endif
            end
            //
        end
    end
    else begin
        if(expected_bchannel_q.size() == 0) begin
            `ifdef PRINT_TO_SUM_FILE
            $fdisplay(sim_summary_file, "AxiWrReqIDQueue is EMPTY");
            `else
            `uvm_warning(get_type_name(), "AxiWrReqIDQueue is EMPTY");
            `endif
        end
        //
        if(actual_bchannel_q.size() == 0) begin
            `ifdef PRINT_TO_SUM_FILE
            $fdisplay(sim_summary_file, "AxiWrRspIDQueue is EMPTY");
            `else
            `uvm_warning(get_type_name(), "AxiWrRspIDQueue is EMPTY");
            `endif
        end
    end
    //
    expected_bchannel_q.delete();
    actual_bchannel_q.delete();
    //
    `ifdef PRINT_TO_SUM_FILE
    $fdisplay(sim_summary_file,"=======================================================");
	$fclose(sim_summary_file);
    `else
    `uvm_info(get_type_name(),"=======================================================", UVM_LOW);
    `endif 
endfunction
//
endclass

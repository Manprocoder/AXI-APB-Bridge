//===========================================================================
//--Project: AXI_TO_APB IP
//--File: axi_apb_scoreboard.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//===========================================================================
//declare all functions that relate to ports of Monitor
`include "axi_scoreboard.sv"
//
`uvm_analysis_imp_decl(_Aresetn)
`uvm_analysis_imp_decl(_AxiRdRequest)
`uvm_analysis_imp_decl(_AxiRData)
`uvm_analysis_imp_decl(_AxiWrRequest)
`uvm_analysis_imp_decl(_AxiWData) 
`uvm_analysis_imp_decl(_AxiBresp) 
//`uvm_analysis_imp_decl(_Presetn)    
//`uvm_analysis_imp_decl(_Pseltb)    
//`uvm_analysis_imp_decl(_ApbContent)  
typedef apb_seq_item#(DW2, AW2) apb_item;
//
class axi_apb_scoreboard extends axi_scoreboard;
    //register UVM factory
    `uvm_component_utils(axi_apb_scoreboard)

    //AXI Monitor imp ports
    uvm_analysis_imp_Aresetn #(logic, axi_apb_scoreboard) aimp_Aresetn;
    uvm_analysis_imp_AxiRdRequest #(axi_req_item, axi_apb_scoreboard) aimp_AxiRdRequest;
    uvm_analysis_imp_AxiRData #(axi_data_item, axi_apb_scoreboard) aimp_AxiRData;
    uvm_analysis_imp_AxiWrRequest #(axi_req_item, axi_apb_scoreboard) aimp_AxiWrRequest;
    uvm_analysis_imp_AxiWData #(axi_data_item, axi_apb_scoreboard) aimp_AxiWData;
    uvm_analysis_imp_AxiBresp #(axi_brsp_item, axi_apb_scoreboard) aimp_AxiBresp;
    //APB Monitor imp ports
    //uvm_analysis_imp_Presetn #(logic, axi_apb_scoreboard) aimp_Presetn;
    //uvm_analysis_imp_Pseltb #(logic [`SLAVE_CNT-1:0], axi_apb_scoreboard) aimp_Pseltb;
    //uvm_analysis_imp_ApbContent #(apb_item, axi_apb_scoreboard) aimp_ApbContent;
    //--------------------------------------
    //data members
    //---------------------------------------
    //--1: env config handle
    env_config env_cfg_h;
    //--2: APB TLM FIFOs
    uvm_tlm_analysis_fifo#(apb_item) apb_trans_fifo[];
    uvm_tlm_analysis_fifo#(logic) presetn_fifo[];
    //--3:
    apb_item apb_tmp_h; //used in peek() method to check either READ or WRITE transfer
    //
    //(4) reset
    bit axi_rst_flg;
    bit apb_rst_flag;
    //
    //(5) member 
    bit compare_start; //compare flag signals APB transfer is available
    resp_name cur_rsp; //store resp to compare resp channel
    //--6: collect transfer 
    axi_data_item axi_content;
    apb_item apb_content; 
    //--7: final objects used for comparing
    shared_item axi_transfer, apb_transfer;//common content of two protocol (wr_rd enable, data, wstrb, resp, last)
    //
    //constructor
    //
    function new(string name ="axi_apb_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction
    //-------------------------------------------------
    //-- build_phase() function
    //---------------------------------------------------
    function void build_phase(uvm_phase phase);
       // super.build_phase(phase); 
        //
        if (!uvm_config_db#(env_config)::get(this, "", "env_cfg", env_cfg_h)) begin
          `uvm_fatal(get_name(), "Didn't get ENV config handle!!!")
        end
        else begin
            apb_trans_fifo = new[env_cfg_h.no_apb_agt];
            presetn_fifo = new[env_cfg_h.no_apb_agt];
            //
            foreach(apb_trans_fifo[i]) begin
                apb_trans_fifo[i] = new ($sformatf("apb_trans_fifo[%0d]", i), this);
                presetn_fifo[i] = new ($sformatf("presetn_fifo[%0d]", i), this);
            end
        end
        //
        //AXI
        aimp_Aresetn = new ("aimp_Aresetn", this);
        aimp_AxiRdRequest = new ("aimp_AxiRdRequest", this);
        aimp_AxiRData = new ("aimp_AxiRData", this);
        aimp_AxiWrRequest = new ("aimp_AxiWrRequest", this);
        aimp_AxiWData = new ("aimp_AxiWData", this);
        aimp_AxiBresp = new ("aimp_AxiBresp", this);
        //APB
        //aimp_Presetn = new ("aimp_Presetn", this);
        //aimp_ApbContent = new ("aimp_ApbContent", this);
        //aimp_Pseltb = new ("aimp_Pseltb", this);
        //
        apb_tmp_h = apb_item::type_id::create("apb_scb_tmp");
        clr_member();
        init_slave_addr(APB_BASE_END_ADDR_QUEUE_WIDTH, 32'h0000_0000, 32'h0000_0FFF);
        display_slv_base_end_addr_q();
    endfunction
//
virtual task run_phase(uvm_phase phase);
	//
	init_total_checker();
    init_type_of_trans_checker();
	forever begin
	    wait_apb_transfer();
        `uvm_info(get_name(), "EXIT WAIT_APB_TRANSFER", UVM_HIGH)
	    #(`CLK_CYCLE);
        display_member(); //check logic of compare_start signal
        display_slv_index(); //check selected APB agent
        //
	    if(compare_start == 1'b1) begin
            apb_trans_fifo[apb_slv_idx].peek(apb_tmp_h);
            //
		    if(apb_tmp_h.pwrite == 1'b1) begin
                `uvm_info(get_type_name(), $sformatf("[WRITE] COMPARE TRANSACTION START"), UVM_LOW);
                compare_transaction(1'b1);
		    end
		    else begin
                wait(axi_rdata_arr.num() > 0);
                `uvm_info(get_type_name(), $sformatf("[READ] COMPARE TRANSACTION START"), UVM_LOW);
                compare_transaction(1'b0);
		    end
	    end
	end
endtask
//******************************************************************************************************************
//------------------------- report_phase() and final_phase() function
//******************************************************************************************************************
virtual function void report_phase(uvm_phase phase);
    check_missing_transaction();
    display_sim_res(); //print sim result of each ID in detail
    display_rsp_report();  //write response report 
    display_total_checker(); //total pass and fail 
    display_type_of_trans_checker(); //valid trans, dec_err, slv_err and missed trans, which is missed in simulation time.  
endfunction
//-------------------------------------------------
//-- final_phase() function
//---------------------------------------------------
virtual function void final_phase(uvm_phase phase);
    flush_slave_addr();
    flush_sim_result();
    flush_resp();
endfunction
//=========================================================================
//-----------------------------OTHER METHODs
//=========================================================================
extern virtual function void write_Aresetn(logic arst_n);
extern virtual function void write_AxiRdRequest(axi_req_item rd_req);
extern virtual function void write_AxiRData(axi_data_item rd_content);
extern virtual function void write_AxiWrRequest(axi_req_item wr_req);
extern virtual function void write_AxiWData(axi_data_item wr_content);
extern virtual function void write_AxiBresp(axi_brsp_item B_channel);
//extern virtual function void write_Presetn(logic preset_n);
//extern virtual function void write_ApbContent(apb_item ApbContent);
//extern virtual function void write_Pseltb(logic [`SLAVE_CNT-1:0] psel_tb);
//other methods
extern virtual function void convert_axi_to_compare(axi_data_item axi_item);
extern virtual function void convert_apb_to_compare(apb_item apb_trans);
extern virtual function void display_member();
extern virtual function void clr_member();
extern virtual function void flush_apb_tlm_fifo();
extern virtual task wait_apb_transfer();
extern virtual task compare_transaction(input bit wr_en);
extern virtual task Fetch_Valid_Req (input bit wr_en);
extern virtual function bit Check_Valid_Addr(input logic [31:0] start_address);
extern virtual task Pop_unvalid_data();
extern virtual task Do_Comparison(input bit wr_en);
extern virtual task compare_transfer(input int i);
extern virtual task handle_wait_data(input bit write_enable, input bit axi_or_apb, output bit break_enable);
extern virtual function void check_missing_transaction;
//
endclass
//=========================================================================
//-----------------IMPLEMENTATION of OTHER METHODs
//=========================================================================
function void axi_apb_scoreboard::write_Aresetn(logic arst_n);
    if (~arst_n) begin
        axi_rst_flg = 1'b1;
        flush_sim_result();
        flush_req_q();
        flush_axi_addr_q();
        flush_data();
        flush_apb_tlm_fifo();
        clr_member();
        //
       `uvm_info(get_type_name(), "areset_n signal is acting", UVM_LOW)
    end
    else begin
       axi_rst_flg = 1'b0;
    end
endfunction
    //
    //(2)
    //
    function void axi_apb_scoreboard::write_AxiRdRequest(axi_req_item rd_req);
        rd_req_q.push_back(rd_req);
        //req_q tmp_q = {};
        //rd_req.print();
        //
        //if(rd_req_arr.exists(rd_req.slv_idx) == 1'b1) begin
            //tmp_q = rd_req_arr[rd_req.slv_idx];
            //tmp_q.push_back(rd_req);
            //rd_req_arr[rd_req.slv_idx] = tmp_q;
        //end
        //else begin
            //tmp_q.push_back(rd_req);
            //rd_req_arr[rd_req.slv_idx] = tmp_q;
        //end
    endfunction
    //(3)
    //put rdata_item into associative array with queue element
    //
    function void axi_apb_scoreboard::write_AxiRData(axi_data_item rd_content);
	//    rd_content.print();
	    data_q axi_rdata_q = {};
	if(axi_rdata_arr.exists(rd_content.id)) begin
		axi_rdata_q = axi_rdata_arr[rd_content.id];
		axi_rdata_q.push_back(rd_content);
		axi_rdata_arr[rd_content.id] = axi_rdata_q;
		`uvm_info(get_type_name(), $sformatf("[EXIST]Push Rd_content into axi_rdata_arr[%0d]", rd_content.id), UVM_HIGH);
	end
	else begin
		axi_rdata_q.push_back(rd_content);
		axi_rdata_arr[rd_content.id] = axi_rdata_q;
		`uvm_info(get_type_name(), $sformatf("[NEW]Push Rd_content into axi_rdata_arr[%0d]", rd_content.id), UVM_HIGH);
	end
        //
    endfunction
    //(4)
    function void axi_apb_scoreboard::write_AxiWrRequest(axi_req_item wr_req);
		wr_req_q.push_back(wr_req);
        //req_q tmp_q = {};
        //
        //if(wr_req_arr.exists(wr_req.slv_idx) == 1'b1) begin
            //tmp_q = wr_req_arr[wr_req.slv_idx];
            //tmp_q.push_back(wr_req);
            //wr_req_arr[wr_req.slv_idx] = tmp_q;
        //end
        //else begin
            //tmp_q.push_back(wr_req);
            //wr_req_arr[wr_req.slv_idx] = tmp_q;
        //end
        //
    endfunction
    //(5)
    function void axi_apb_scoreboard::write_AxiWData(axi_data_item wr_content);
        axi_wdata_q.push_back(wr_content);
    endfunction
    //(6)
    function void axi_apb_scoreboard::write_AxiBresp(axi_brsp_item B_channel);
	   resp_q actual_bresp_q = {};
	    //
	if(actual_bresp_array.exists(B_channel.id)) begin
		actual_bresp_q = actual_bresp_array[B_channel.id];
		actual_bresp_q.push_back(B_channel.resp);
		actual_bresp_array[B_channel.id] = actual_bresp_q;
		`uvm_info(get_name(), 
		$sformatf("[EXISTING]Push Actual BRESP into actual_bresp_arr[%0d]", B_channel.id), UVM_HIGH);
	end
	else begin
		actual_bresp_q.push_back(B_channel.resp);
		actual_bresp_array[B_channel.id] = actual_bresp_q;
		`uvm_info(get_name(), 
		$sformatf("[NEW]Push Actual BRESP into actual_bresp_arr[%0d]", B_channel.id), UVM_HIGH);
	end
    endfunction
    //
    //----APB Protocol
    //(1)
    //function void axi_apb_scoreboard::write_Presetn(logic preset_n);
        //if(~preset_n) begin
		   //apb_rst_flag = 1'b1;
		   //clr_member();
		   //`uvm_info(get_type_name(), $sformatf("[%0t ns] preset_n signal is acting", $time), UVM_MEDIUM)
	//end
        //else begin
		   //apb_rst_flag = 1'b0;
        //end
    //endfunction
    //
    //(2)
    //function void axi_apb_scoreboard::write_ApbContent(apb_item ApbContent);
        //apb_trans_fifo[apb_slv_idx].push_back(ApbContent);
    //endfunction
    //
    //(3)
    //function void axi_apb_scoreboard::write_Pseltb(logic [`SLAVE_CNT-1:0] psel_tb);
        //if ($countones(psel_tb) > 1) begin
		   //`uvm_error(get_type_name(),
            //$sformatf("[PSEL_ACTIVE_ERROR][%0t ns] multiple APB psel are active at the same time!!!", $time))
        //end
    //endfunction
    //-------------------------------------------------------------------------------
    //-------------------------END OF WRITE FUNCTION IMPLEMENTATION
    //-------------------------------------------------------------------------------
function void axi_apb_scoreboard::convert_axi_to_compare(axi_data_item axi_item);
    axi_transfer = shared_item::type_id::create("axi_transfer");	
    axi_transfer.addr = axi_addr_q.pop_front();
 //
    axi_transfer.id = axi_item.id;
    axi_transfer.write = axi_item.wr_or_rd;
    axi_transfer.data = axi_item.data;
    axi_transfer.wstrb = axi_item.be;
    axi_transfer.resp = axi_item.resp;
    axi_transfer.last = axi_item.last;
    //
endfunction
//
//
function void axi_apb_scoreboard::convert_apb_to_compare(apb_item apb_trans);
    apb_transfer = shared_item::type_id::create("apb_transfer");	
    //
    apb_transfer.id = 'hz;
    apb_transfer.write = apb_trans.pwrite;
    apb_transfer.addr = apb_trans.paddr;
    apb_transfer.data = apb_trans.pwrite ? apb_trans.pwdata : apb_trans.prdata;
    apb_transfer.wstrb = apb_trans.pstrb;
    apb_transfer.resp = apb_trans.pslverr ? resp_name'(2'b10) : resp_name'(2'b00);
    apb_transfer.last = 0;
endfunction
//
function void axi_apb_scoreboard::display_member();
    `uvm_info(get_name(), $sformatf("value of compare_start: %0b", compare_start), UVM_LOW)
endfunction
//
function void axi_apb_scoreboard::clr_member();
    cur_rsp = OKAY;
    compare_start = 1'b0;
    //
    `uvm_info(get_name(), "COMPARE_START trigger is cleared", UVM_HIGH)
endfunction
//
function void axi_apb_scoreboard::flush_apb_tlm_fifo();
    for(int i = 0; i<env_cfg_h.no_apb_agt; i++) begin
        apb_trans_fifo[i].flush();
    end
endfunction
    //
task axi_apb_scoreboard::wait_apb_transfer();
    logic rst_done = 0;
    logic apb_avail = 0;
    clr_member();//clear compare_start 
    $cast(apb_slv_idx, 999);
    fork
        forever begin: DETECT_APB_RESET 
        //begin: DETECT_APB_RESET 
            foreach(presetn_fifo[i]) begin: RSTN_LOOP
               if(presetn_fifo[i].try_get(apb_rst_flag) == 1'b1) begin
                    if(apb_rst_flag == 1'b0) begin
                       `uvm_info(get_type_name(), "APB RESET is active", UVM_LOW)
                        $cast(apb_slv_idx, 999);
                        rst_done = 1;
                       break;
                   end
               end
            end:RSTN_LOOP
            //`uvm_info(get_name(), "DETECT_APB_REST", UVM_HIGH)
            //
            if(rst_done == 1'b1) begin
                break;
            end
            #(`CLK_CYCLE);
        end: DETECT_APB_RESET 
        //
        forever begin: DETECT_APB_TRANS 
        //begin: DETECT_APB_TRANS 
            foreach(apb_trans_fifo[i]) begin: APB_TRANSFER_LOOP
               if(apb_trans_fifo[i].is_empty() == 0) begin
                    compare_start = 1'b1;
                    $cast(apb_slv_idx, i);
                    apb_avail = 1;
                    break;
               end
            end: APB_TRANSFER_LOOP
           // `uvm_info(get_name(), "DETECT_APB_TRANS", UVM_HIGH)
            //
            if(apb_avail == 1'b1) begin
                break;
            end
            //
            #(`CLK_CYCLE);
        end:DETECT_APB_TRANS 
        //
        begin:TIMEOUT_FOR_APB 
            #APB_TIMEOUT;
            `uvm_warning(get_type_name(), "APB TRANSFER TIMEOUT!!!");
        end: TIMEOUT_FOR_APB
    join_any
    //
    disable fork;
endtask
//
//
//
task axi_apb_scoreboard::compare_transaction(
	 input bit wr_en
);
	wait(axi_rst_flg == 1'b0);
    fork 
        begin:DETECT_AXI_RST
            @(posedge axi_rst_flg);
            `uvm_info(get_type_name(), "RISING EDGE AXI_RST_FLAG!!!", UVM_LOW);
        end:DETECT_AXI_RST
        begin:COMP_TRANS_THREAD
            clear_signals_for_each_trans();
            Fetch_Valid_Req(wr_en);
            Do_Comparison(wr_en);
        end:COMP_TRANS_THREAD
    join_any
    disable fork;
endtask
//==================================================================================================
//-----------------------IMPLEMENTATION of INSIDE tasks in compare_transaction
//==================================================================================================
//Operation Order:
//--: check unvalid req -> pop unvalid data
//--: return valid req and do compare     
task axi_apb_scoreboard:: Fetch_Valid_Req(input bit wr_en);
    //
    bit queue_not_empty;
    bit error_case;
    //req_q wr_req_q = {};
    //req_q rd_req_q = {};
    //
    begin: FETCH_VLD_REQ_BLOCK
        forever begin: FETCH_VLD_REQ_LOOP
            //wr_req_q = wr_req_arr[apb_slv_idx];
            //rd_req_q = rd_req_arr[apb_slv_idx];
            //
            if(wr_en == 1'b1 && wr_req_q.size() == 0) begin
                `uvm_error(get_name(), "write transaction is NOT available!!!")
            end
            //
            if(wr_en == 1'b0 && rd_req_q.size() == 0) begin
                `uvm_warning(get_name(), "read_ transaction is NOT available!!!")
            end
            //---------------------------------------------------------
            //----------------START CHECKING REQ QUEUE
            //---------------------------------------------------------
            queue_not_empty = (wr_en == 1'b1) ? (wr_req_q.size() > 0) : (rd_req_q.size() > 0);
            //
            if(queue_not_empty == 1'b1) begin
                raw_req = axi_req_item::type_id::create("raw_req");
                raw_req = (wr_en == 1'b1) ? (wr_req_q.pop_front()) : (rd_req_q.pop_front());
                //=========================================================
                //-----------------update element of array
                //=========================================================
                //wr_req_arr[apb_slv_idx] = wr_req_q;
                //rd_req_arr[apb_slv_idx] = rd_req_q;
                //raw_req.print();
                //disallowed trans
                error_case = (raw_req.size != 3'b010) || (raw_req.burst != INCR && raw_req.addr[1:0] != 2'b00);
                //
                if(Check_Valid_Addr(raw_req.addr) == 1'b0) begin
                    dec_err_trans++;
                    `uvm_error(get_name(),
                     $sformatf("[%s][%0d]: Unvalid_address: 0x%08h", (wr_en == 1'b1) ? "WRITE" : "READ_", raw_req.id[7:0], raw_req.addr))
                    //
                    if(wr_en == 1'b1) begin
                        `uvm_info(get_type_name(), "Write Req", UVM_HIGH)
                        cur_rsp = DECERR;
                        Store_Expected_Bresp(cur_rsp); //decerr
                    end
                    Pop_unvalid_data();
                end
                else if(error_case == 1'b1) begin
                    slv_err_trans++;
                    `uvm_error(get_name(),
                     $sformatf("[%s][%0d]: unsupported transaction: addr: 0x%08h",
                     (wr_en == 1'b1) ? "WRITE" : "READ_", raw_req.id[7:0], raw_req.addr))
                    //`uvm_info(get_type_name(), "Unvalid request (size is not 4 bytes)", UVM_LOW)
                    if(wr_en == 1'b1) begin
                        cur_rsp = PSLVERR;
                        Store_Expected_Bresp(cur_rsp);//pslverr
                    end
                    Pop_unvalid_data();
                end
                else begin
                    valid_trans++;
                    `uvm_info(get_type_name(), "Valid transaction", UVM_LOW)
                    break;
                end
            end //end of if queue_not_empty
            else begin
                #AXI_REQ_TIMEOUT; 
                `uvm_error(get_name(), $sformatf("[FETCH_VALID_REQ]: UNAVAILABLE %s REQ", (wr_en == 1'b1) ? "WRITE" : "READ"))
                //`uvm_warning(get_name(), $sformatf("[FETCH_VALID_REQ]: UNAVAILABLE %s REQ", (wr_en == 1'b1) ? "WRITE" : "READ"))
            end
            #(`CLK_CYCLE); //avoid being stuck at specific time simulation
    end: FETCH_VLD_REQ_LOOP
        `uvm_info(get_type_name(), "Exit Fetch_Valid_Request task", UVM_LOW)
    end: FETCH_VLD_REQ_BLOCK
endtask
    //
    function bit axi_apb_scoreboard::Check_Valid_Addr(input logic [31:0] start_address);
         `uvm_info(get_name(), $sformatf("start_address: 0x%8h", start_address), UVM_LOW)
         if(start_address <= apb_base_end_addr_q[`SLAVE_CNT*2-1]) return 1'b1;
         else return 1'b0;
    endfunction
    //
    task axi_apb_scoreboard::Pop_unvalid_data();
        //
        bit wr_en;
        bit data_rdy = 0;
        bit exit_data_while_loop = 0;
        data_q axi_rdata_tmp_q = {};
        //
        begin: POP_UNVALID_DAT_BLOCK
            wr_en = raw_req.wr_or_rd;
            //
            while(1) begin
            data_rdy = (wr_en == 1'b1) ? (axi_wdata_q.size() > 0) : (axi_rdata_arr.exists(raw_req.id) && axi_rdata_arr[raw_req.id].size() > 0);
            if (data_rdy == 1'b1) begin: DAT_RDY_BLOCK
               axi_content = axi_data_item::type_id::create("axi_content");
               if(wr_en == 1'b1) begin
                    axi_content = axi_wdata_q.pop_front();
                    `uvm_info(get_type_name(), "[INVALID_WDATA]: REMOVED FROM QUEUE!!!", UVM_MEDIUM)
                end
                else begin
                    axi_rdata_tmp_q = axi_rdata_arr[raw_req.id];
                    axi_content = axi_rdata_tmp_q.pop_front();
                    axi_rdata_arr[raw_req.id] = axi_rdata_tmp_q;
                    `uvm_info(get_type_name(), "[INVALID_RDATA]: REMOVED FROM QUEUE!!!", UVM_MEDIUM)
                end
                    //axi_content.print();
                last_beat = axi_content.last;
                axi_data_wait_cnt = 0;
                //
                if(last_beat == 1'b1) begin
                    `uvm_info(get_type_name(), "[INVALID LAST_DATA]: REMOVED FROM QUEUE!!!", UVM_MEDIUM)
                    if(~wr_en) begin
                        cur_rsp = axi_content.resp;
                    end
                    store_simulation_result(cur_rsp); 
                    break; //exit while(1) 
                end
            end: DAT_RDY_BLOCK
	       	else begin
                axi_data_wait_cnt++;
                #(`CLK_CYCLE);
//wr_en
//axi_or_apb;
//output bit break_enable;
                handle_wait_data(wr_en, 1'b1, exit_data_while_loop);
                if(exit_data_while_loop==1) begin
                    #(`CLK_CYCLE);
                    break;//exit while(1) 
                end
            end
	end //end of while(1)
            `uvm_info(get_name(), "REMOVING DATA of unvalid transaction DONE", UVM_LOW) 
            raw_req.print();
	end: POP_UNVALID_DAT_BLOCK 
endtask
//
//
//
task axi_apb_scoreboard::Do_Comparison(input bit wr_en);
        //
	int transfer_index = 0;
    int fifo_idx;
	resp_name bresp = resp_name'(2'b00);
	data_q axi_rdata_tmp_q = {};
        //
	begin: COMPARE_BLOCK 
	    calculate_and_store_addr();
	    assert(axi_addr_q.size() > 0) begin
        end
        else `uvm_error(get_name(), "axi_addr_queue for one transaction is EMPTY")
        //--translate from logic to int type
        if(!$cast(fifo_idx, apb_slv_idx)) begin
            `uvm_error(get_name(), "Casting APB FIFO index is FAILED")
        end
        //**************************************************************
        //--------------------AXI - APB
        //**************************************************************
	forever begin: COMPARE_LOOP
		    `uvm_info(get_type_name(), "[DO_COMPARE]: APB TRANSFER WAIT!!!", UVM_LOW)
		    //wait(apb_trans_fifo[fifo_idx].is_empty() == 0);
		    //wait(apb_trans_fifo[apb_slv_idx].used() > 0);
		    if(wr_en == 1'b1) begin
                `uvm_info(get_type_name(), "[DO_COMPARE]: WR_AXI TRANSFER WAIT!!!", UVM_LOW)
			    wait(axi_wdata_q.size() > 0);
		    end
		    else begin
                `uvm_info(get_type_name(), "[DO_COMPARE]: RD_AXI TRANSFER WAIT!!!", UVM_LOW)
			    wait(axi_rdata_arr.exists(raw_req.id) && axi_rdata_arr[raw_req.id].size() > 0);
		    end
		    `uvm_info(get_type_name(), "[DO_COMPARE]: TRANSFER START!!!", UVM_LOW)
		//----APB
		   apb_content = apb_item::type_id::create("apb_content");
		   apb_trans_fifo[fifo_idx].get(apb_content);
		//----AXI
		   axi_content = axi_data_item::type_id::create("axi_content");
		    if(wr_en == 1'b1) begin
                axi_content = axi_wdata_q.pop_front();
                `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: READY FOR WR_TRANSFER COMPARE!!!"), UVM_MEDIUM)
		    end
		    else begin
                axi_rdata_tmp_q = axi_rdata_arr[raw_req.id[7:0]];
                axi_content = axi_rdata_tmp_q.pop_front();
                axi_rdata_arr[raw_req.id[7:0]] = axi_rdata_tmp_q;
                `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: READY FOR RD_TRANSFER COMPARE!!!"), UVM_MEDIUM)
		    end
		//----COMPARE
            convert_axi_to_compare(axi_content);
            convert_apb_to_compare(apb_content);
		    compare_transfer(transfer_index);
		    transfer_index++;
		    `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: TRANSFER DONE!!!"), UVM_MEDIUM)
		    //
		    //store resp
		    bresp = resp_name'(bresp | apb_transfer.resp);
		    last_beat = axi_content.last;
		    //
		    if(last_beat == 1'b1) begin
			    if(wr_en == 1'b1) begin
		            //raw_req.print();
                    //`uvm_info(get_type_name(), $sformatf("BRESP: %s", bresp.name()), UVM_LOW)
                    Store_Expected_Bresp(bresp);
                    axi_content.resp = bresp;
			    end
                `uvm_info(get_type_name(),
                 $sformatf("[DO_COMPARE]: %s TRANSACTION DONE", wr_en ? "WRITE" : "READ"), UVM_MEDIUM)
                    //
                store_simulation_result(axi_content.resp);
                break; //exit while(1) 
		    end
	    end: COMPARE_LOOP
	end: COMPARE_BLOCK
endtask
//
//compare task
//
task axi_apb_scoreboard::compare_transfer(input int i);
    string header;
    bit rid_match, rsp_match;
    string rid_header;
    //
    begin
	//open file
        //`ifdef PRINT_TO_COMPARE_FILE
        //compare_file = $fopen($sformatf("%s/COMPARE/cmp.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
		//if(compare_file == 0) begin
			//`uvm_warning(get_type_name(), $sformatf("Failed to open cmp.log"))
		//end
        //`endif
        //
        header = (raw_req.wr_or_rd == 1'b1) ? "wr_transfer" : "rd_transfer";
        rid_match = (raw_req.wr_or_rd == 1'b1) ? 1'b1 : (raw_req.id == axi_transfer.id);
        rsp_match = (raw_req.wr_or_rd == 1'b1) ? 1'b1 : (axi_transfer.resp == apb_transfer.resp);
	    if(axi_transfer.compare(apb_transfer) && rid_match && rsp_match) begin 
                //`ifdef PRINT_TO_COMPARE_FILE
                //$fdisplay(compare_file, 
                        //$sformatf("%s[%0d][%0d][%0t ns] PASS:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        //header, raw_req.id, (i+1), $time, axi_transfer.convert2string(), apb_transfer.convert2string()));
                //`else
                `uvm_info("COMPARE_TRANSFER", 
                        $sformatf("%s[%0d][%0d] PASS:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, raw_req.id, (i+1), axi_transfer.convert2string(), apb_transfer.convert2string()), UVM_LOW)
                //`endif
                pass_of_each_id++;
                total_pass++;
            end
            else begin
                //`ifdef PRINT_TO_COMPARE_FILE
                //$fdisplay(compare_file, 
                        //$sformatf("%s[%0d][%0d][%0t ns] FAILED:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        //header, raw_req.id, (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()));
                //`else
                `uvm_info("COMPARE_TRANSFER", 
                        $sformatf("%s[%0d][%0d] FAILED:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, raw_req.id, (i+1), axi_transfer.convert2string(), apb_transfer.convert2string()), UVM_LOW)
                //`endif
                fail_of_each_id++;
                total_fail++;
            end
        //end
        //
        //`ifdef PRINT_TO_COMPARE_FILE
        //$fclose(compare_file);
        //`endif
        //
    end
endtask
//===================================================================================================
//-----------------------------handle timeout for waiting data 
//===================================================================================================
task axi_apb_scoreboard::handle_wait_data(input bit write_enable, input bit axi_or_apb, output bit break_enable);
    //
    resp_name wait_resp;
    string header;
    int fifo_idx;
    //
    begin
        $cast(fifo_idx, apb_slv_idx);
        //
        if (axi_data_wait_cnt > TIME_OUT_BOUNDARY) begin
            wait_resp = NO_USE;
            store_simulation_result(wait_resp);
            if(axi_or_apb == 1) begin
                if((write_enable==1'b0) && (axi_rdata_arr.size() == 0)) begin
                    `uvm_info(get_type_name(),
                    $sformatf("TRANS[READ][%0d]:Timeout Timeout Timeout--axi_rdata_arr is EMPTY", raw_req.id[7:0]), UVM_MEDIUM);
                end
                //
                if((write_enable==1'b1) && (axi_wdata_q.size() == 0)) begin
                    `uvm_info(get_type_name(), 
                    $sformatf("TRANS[WRITE][%0d]:Timeout Timeout Timeout--axi_wdata_q is EMPTY", raw_req.id[7:0]), UVM_MEDIUM);
                end
            end
            else begin
                if(apb_trans_fifo[fifo_idx].is_empty() == 1'b1) begin
                    header = write_enable ? "WRITE" : "READ";
                    `uvm_info(get_name(), $sformatf("Timeout---[%s]apb_tlm_fifo[%0d] is EMPTY", header, apb_slv_idx
                    ), UVM_MEDIUM);
                end
            end
            //
            #(`CLK_CYCLE);
            break_enable = 1'b1;
        end
        else begin
            break_enable = 1'b0;
        end
    end
endtask
//
//
function void axi_apb_scoreboard::check_missing_transaction;
begin: CHECK_MISSING_BLOCK
    //req_q tmp_miss_q = {};
    raw_req = axi_req_item::type_id::create("raw_req");
	//============================================================
    //---------------------MISSING READ_  TRANSACTION
	//============================================================
    //if(rd_req_arr.num() == 0) begin
        //`uvm_info(get_name(), "[READ_] NO missing transaction!!!", UVM_LOW)
    //end
    //else begin
        //for(int i = 0; i < `SLAVE_CNT; i++) begin: RD_MISSING_LOOP
            //$cast(apb_slv_idx, i);
            //
            //if(rd_req_arr.exists(apb_slv_idx) == 1'b1) begin
                //tmp_miss_q = rd_req_arr[apb_slv_idx];
                //
                while(1) begin: RD_WHILE_LOOP
                    if (rd_req_q.size() == 0) begin
                         break;
                     end
                    rd_missing_trans++;
                    //
                    raw_req = rd_req_q.pop_front();
                    //
                    if(!Check_Valid_Addr(raw_req.addr)) begin 
                        store_simulation_result(DECERR);
                    end
                    else begin 
                        store_simulation_result(PSLVERR);
                    end
                end: RD_WHILE_LOOP
            //end 
        //end: RD_MISSING_LOOP
    //end
	//============================================================
    //---------------------MISSING WRITE TRANSACTION
	//============================================================
    //if(wr_req_arr.num() == 0) begin
        //`uvm_info(get_name(), "[WRITE] NO missing transaction!!!", UVM_LOW)
    //end
    //else begin
        //for(int i = 0; i < `SLAVE_CNT; i++) begin: WR_MISSING_LOOP
            //$cast(apb_slv_idx, i);
            ////
            //if(wr_req_arr.exists(apb_slv_idx) == 1'b1) begin
                //tmp_miss_q = wr_req_arr[apb_slv_idx];
                //
                while(1)begin: WR_WHILE_LOOP
                    if (wr_req_q.size() == 0) break;
                    //raw_req = axi_req_item::type_id::create("raw_req");
                    raw_req = wr_req_q.pop_front();
                    wr_missing_trans++;
                    //
                    if(!Check_Valid_Addr(raw_req.addr)) begin  
                        store_simulation_result(DECERR);
                        Store_Expected_Bresp(DECERR); 
                    end
                    else begin
                        store_simulation_result(PSLVERR);
                        Store_Expected_Bresp(PSLVERR); 
                    end
                end: WR_WHILE_LOOP
            //end
        //end: WR_MISSING_LOOP
    //end
end: CHECK_MISSING_BLOCK
endfunction
//
//
//


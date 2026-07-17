//===========================================================================
//--Project: AXI_TO_APB IP
//--File: axi_apb_axi_apb_scoreboard.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//===========================================================================
//declare all functions that relate to ports of Monitor
`include "base_scoreboard.sv"
//
`uvm_analysis_imp_decl(_Aresetn)
`uvm_analysis_imp_decl(_AxiRdRequest)
`uvm_analysis_imp_decl(_AxiRData)
`uvm_analysis_imp_decl(_AxiWrRequest)
`uvm_analysis_imp_decl(_AxiWData) 
`uvm_analysis_imp_decl(_AxiBresp) 
`uvm_analysis_imp_decl(_Presetn)    
`uvm_analysis_imp_decl(_Pseltb)    
`uvm_analysis_imp_decl(_ApbContent)  
//
//axi_apb_scb class
//

typedef apb_seq_item#(DW2, AW2) apb_item;
//
class axi_apb_scoreboard extends base_scoreboard;
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
    uvm_analysis_imp_Presetn #(logic, axi_apb_scoreboard) aimp_Presetn;
    uvm_analysis_imp_Pseltb #(logic [`SLAVE_CNT-1:0], axi_apb_scoreboard) aimp_Pseltb;
    uvm_analysis_imp_ApbContent #(apb_item, axi_apb_scoreboard) aimp_ApbContent;
    //--------------------------------------
    //data members
    //---------------------------------------
    //
    //(1) apb transfer queue
    apb_item apb_content_q [$];
    //
    //(2) reset
    bit axi_rst_flg;
    bit apb_rst_flag;
    //
    //(3) others
    bit compare_start;
    resp_name cur_rsp;
    axi_data_item axi_content;
    apb_item apb_content; 
    shared_item axi_transfer, apb_transfer;//common content of two protocol (wr_rd enable, data, wstrb, resp, last)
    //end of simulation
    bit done;
    int sim_counter;
    //
    int compare_file;
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
	//
	clr_member();
	init_slave_addr(APB_BASE_END_ADDR_QUEUE_WIDTH, 32'h0000_0000, 32'h0000_0FFF);
endfunction
//
virtual task run_phase(uvm_phase phase);
	super.run_phase(phase);
	//
	init_checker();
	forever begin
	    wait_apb_transfer(3);
	    #(`CLK_CYCLE);
	    if(compare_start) begin
		    if(apb_content_q[0].pwrite) begin
			`uvm_info(get_type_name(), $sformatf("[WRITE] COMPARE TRANSACTION START"), UVM_MEDIUM);
			compare_transaction(1'b1);
		    end
		    else begin
			wait(axi_rdata_arr.num() > 0);
			`uvm_info(get_type_name(), $sformatf("[READ] COMPARE TRANSACTION START"), UVM_MEDIUM);
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
    display_checker(); //total pass and fail 
endfunction
//-------------------------------------------------
//-- final_phase() function
//---------------------------------------------------
virtual function void final_phase(uvm_phase phase);
    flush_slave_addr();
    flush_sim_result();
    flush_resp();
endfunction
//
//write methods
extern virtual function void write_Aresetn(logic arst_n);
extern virtual function void write_AxiRdRequest(axi_req_item rd_req);
extern virtual function void write_AxiRData(axi_data_item rd_content);
extern virtual function void write_AxiWrRequest(axi_req_item wr_req);
extern virtual function void write_AxiWData(axi_data_item wr_content);
extern virtual function void write_AxiBresp(axi_brsp_item B_channel);
extern virtual function void write_Presetn(logic preset_n);
extern virtual function void write_ApbContent(apb_item ApbContent);
extern virtual function void write_Pseltb(logic [`SLAVE_CNT-1:0] psel_tb);
//other methods
extern virtual function void convert_axi_to_compare(axi_data_item axi_item);
extern virtual function void convert_apb_to_compare(apb_item apb_trans);
extern virtual function void clr_member();
extern virtual function void flush_apb_queue();
extern virtual task wait_apb_transfer(input int timeout);
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
    //
    //-------------------EXTERN METHODS IMPLEMENTATION
    //(1)
    function void axi_apb_scoreboard::write_Aresetn(logic arst_n);
        if (~arst_n) begin
            axi_rst_flg = 1'b1;
            flush_sim_result();
	    flush_req_queue();
	    flush_axi_addr_q();
	    flush_data();
	    flush_apb_queue();
	    clr_member();
            //
	   `uvm_info(get_type_name(), $sformatf("[%0t ns] areset_n signal is acting", $time), UVM_MEDIUM)
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
		`uvm_info(get_type_name(), $sformatf("[EXIST]Push Rd_content into axi_rdata_arr[%0d]", rd_content.id), UVM_MEDIUM);
	end
	else begin
		axi_rdata_q.push_back(rd_content);
		axi_rdata_arr[rd_content.id] = axi_rdata_q;
		`uvm_info(get_type_name(), $sformatf("[NEW]Push Rd_content into axi_rdata_arr[%0d]", rd_content.id), UVM_MEDIUM);
	end
        //
    endfunction
    //(4)
    function void axi_apb_scoreboard::write_AxiWrRequest(axi_req_item wr_req);
		wr_req_q.push_back(wr_req);
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
		`uvm_info(get_type_name(), 
		$sformatf("[EXIST]Push Actual BRESP into actual_bresp_array[%0d]", B_channel.id), UVM_MEDIUM);
	end
	else begin
		actual_bresp_q.push_back(B_channel.resp);
		actual_bresp_array[B_channel.id] = actual_bresp_q;
		`uvm_info(get_type_name(), 
		$sformatf("[NEW]Push Actual BRESP into actual_bresp_array[%0d]", B_channel.id), UVM_MEDIUM);
	end
    endfunction
    //
    //----APB Protocol
    //(1)
    function void axi_apb_scoreboard::write_Presetn(logic preset_n);
        if(~preset_n) begin
		   apb_rst_flag = 1'b1;
		   clr_member();
		   `uvm_info(get_type_name(), $sformatf("[%0t ns] preset_n signal is acting", $time), UVM_MEDIUM)
	end
        else begin
		   apb_rst_flag = 1'b0;
        end
    endfunction
    //
    //(2)
    function void axi_apb_scoreboard::write_ApbContent(apb_item ApbContent);
        apb_content_q.push_back(ApbContent);
    endfunction
    //
    //(3)
    function void axi_apb_scoreboard::write_Pseltb(logic [`SLAVE_CNT-1:0] psel_tb);
        if ($countones(psel_tb) > 1) begin
		   `uvm_error(get_type_name(),
            $sformatf("[PSEL_ACTIVE_ERROR][%0t ns] multiple APB psel are active at the same time!!!", $time))
        end
    endfunction
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
//
function void axi_apb_scoreboard::clr_member();
    done = 0;
    sim_counter = 0;
    cur_rsp = OKAY;
endfunction
//
function void axi_apb_scoreboard::flush_apb_queue();
    apb_content_q.delete();
endfunction
    //
task axi_apb_scoreboard::wait_apb_transfer(input int timeout);
//
compare_start = 0;
wait(apb_rst_flag == 0);
fork
	begin: thread_1
		@(posedge apb_rst_flag);
		   `uvm_info(get_type_name(), $sformatf("[%0t (ns)] apb_rst_flag posedge", $time), UVM_MEDIUM)
	end
	//
	begin: thread_2
		wait(apb_content_q.size() > 0); 
		compare_start = 1'b1;
		clr_member();
	end
	//
	begin: thread_3
		#APB_TIMEOUT;
		sim_counter++;
		if(sim_counter == timeout) done = 1;
		//
		if(~done) begin
		`uvm_warning(get_type_name(), $sformatf("at[%0t (ns)]APB TRANSFER TIMEOUT!!!", $time));
		end
	end
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
            begin //FIRST THREAD
                @(posedge axi_rst_flg);
                `uvm_info(get_type_name(), $sformatf("RISING EDGE AXI_RST_FLAG!!!"), UVM_MEDIUM);
            end
            begin //SECOND_THREAD
		init_attribute();
		Fetch_Valid_Req(wr_en);
		Do_Comparison(wr_en);
            end //end of SECOND_THREAD
        join_any
        disable fork;
endtask
    //**************************************************************************************************
    //-------------------------------------SUB TASKS
    //**************************************************************************************************
//Operation Order:
//--: check unvalid req -> pop unvalid data
//--: return valid req and do compare     
task axi_apb_scoreboard:: Fetch_Valid_Req(input bit wr_en);
    //
    bit queue_not_empty;
    bit error_case;
    //
    begin//begin_end block
        while (1) begin
            queue_not_empty = (wr_en) ? (wr_req_q.size() > 0) : (rd_req_q.size() > 0);
            if(queue_not_empty) begin
		raw_req = axi_req_item::type_id::create("raw_req");
                raw_req = (wr_en) ? (wr_req_q.pop_front()) : (rd_req_q.pop_front());
		//raw_req.print();
		//disallowed trans
		error_case = (raw_req.size != 3'b010) || (raw_req.burst != INCR && raw_req.addr[1:0] != 2'b00);
                //
                if(Check_Valid_Addr(raw_req.addr) == 1'b0) begin
		    //`uvm_info(get_type_name(), "Unvalid address", UVM_LOW)
                    if(wr_en) begin
			//`uvm_info(get_type_name(), "Write Req", UVM_LOW)
			cur_rsp = DECERR;
                        Store_Expected_Bresp(cur_rsp); //decerr
                    end
                    Pop_unvalid_data();
                end
		else if(error_case) begin
                    if(wr_en) begin
		    	//`uvm_info(get_type_name(), "Unvalid request (size is not 4 bytes)", UVM_LOW)
			cur_rsp = PSLVERR;
                        Store_Expected_Bresp(cur_rsp);//pslverr
		    end
                    Pop_unvalid_data();
		end
                else begin
		    break;
                end
            end //end of if queue_not_empty
            else begin
	    `uvm_fatal(get_type_name(), $sformatf("[FETCH_VALID_REQ]: UNAVAILABLE %s REQ", wr_en ? "READ" : "WRITE"))
            end
    end//end of while(1)
    end//end of begin_end block
endtask
    //
    function bit axi_apb_scoreboard::Check_Valid_Addr(input logic [31:0] start_address);
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
        begin//START
	    wr_en = raw_req.wr_or_rd;
            //
            while(1) begin
data_rdy = (wr_en) ? (axi_wdata_q.size() > 0) : (axi_rdata_arr.exists(raw_req.id) && axi_rdata_arr[raw_req.id].size() > 0);
                if (data_rdy) begin
		   axi_content = axi_data_item::type_id::create("axi_content");
		   if(wr_en) begin
			axi_content = axi_wdata_q.pop_front();
		    `uvm_info(get_type_name(), $sformatf("[INVALID_WDATA]: REMOVED FROM QUEUE!!!"), UVM_MEDIUM)
		    end
		    else begin
			axi_rdata_tmp_q = axi_rdata_arr[raw_req.id];
			axi_content = axi_rdata_tmp_q.pop_front();
			axi_rdata_arr[raw_req.id] = axi_rdata_tmp_q;
		    `uvm_info(get_type_name(), $sformatf("[INVALID_RDATA]: REMOVED FROM QUEUE!!!"), UVM_MEDIUM)
		    end
		    //axi_content.print();
		    last_beat = axi_content.last;
		    axi_data_wait_cnt = 0;
		    //
		    if(last_beat == 1'b1) begin
			    `uvm_info(get_type_name(), $sformatf("[INVALID LAST_DATA]: REMOVED FROM QUEUE!!!"), UVM_MEDIUM)
			    if(~wr_en) cur_rsp = axi_content.resp;
			    store_simulation_result(cur_rsp); 
			break; //exit while(1) 
		    end
                end
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
	end //end of START
    endtask
//
//
//
task axi_apb_scoreboard::Do_Comparison(input bit wr_en);
        //
	int transfer_index = 0;
	resp_name bresp = resp_name'(2'b00);
	data_q axi_rdata_tmp_q = {};
        //
	begin //begin_end block
	    //raw_req.print();
	    calculate_and_store_addr();
	    assert(axi_addr_q.size() > 0);
            //**************************************************************
            //--------------------AXI - APB
            //**************************************************************
	while(1) begin
		    `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: TRANSFER WAIT!!!"), UVM_MEDIUM)
		    wait(apb_content_q.size() > 0);
		    if(wr_en) begin
			    wait(axi_wdata_q.size() > 0);
		    end
		    else begin
			    wait(axi_rdata_arr.exists(raw_req.id) && axi_rdata_arr[raw_req.id].size() > 0);
		    end
		    `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: TRANSFER START!!!"), UVM_MEDIUM)
		//----APB
		   apb_content = apb_item::type_id::create("apb_content");
		   apb_content = apb_content_q.pop_front();
		//----AXI
		   axi_content = axi_data_item::type_id::create("axi_content");
		    if(wr_en) begin
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
			    if(wr_en) begin
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
	    end//end of while(1)
	end//end of begin_end block
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
        `ifdef PRINT_TO_COMPARE_FILE
        compare_file = $fopen($sformatf("%s/COMPARE/cmp.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
		if(compare_file == 0) begin
			`uvm_warning(get_type_name(), $sformatf("Failed to open cmp.log"))
		end
        `endif
        //
        header = (raw_req.wr_or_rd == 1'b1) ? "wr_transfer" : "rd_transfer";
        rid_match = (raw_req.wr_or_rd == 1'b1) ? 1'b1 : (raw_req.id == axi_transfer.id);
        rsp_match = (raw_req.wr_or_rd == 1'b1) ? 1'b1 : (axi_transfer.resp == apb_transfer.resp);
	    if(axi_transfer.compare(apb_transfer) && rid_match && rsp_match) begin 
                `ifdef PRINT_TO_COMPARE_FILE
                $fdisplay(compare_file, 
                        $sformatf("%s[%0d][%0d][%0t ns] PASS:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, raw_req.id, (i+1), $time, axi_transfer.convert2string(), apb_transfer.convert2string()));
                `else
                `uvm_info("COMPARE_TRANSFER", 
                        $sformatf("%s[%0d][%0d][%0t ns] PASS:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, raw_req.id, (i+1), $time, axi_transfer.convert2string(), apb_transfer.convert2string()), UVM_LOW)
                `endif
                match++;
		total_pass++;
            end
            else begin
                `ifdef PRINT_TO_COMPARE_FILE
                $fdisplay(compare_file, 
                        $sformatf("%s[%0d][%0d][%0t ns] FAILED:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, raw_req.id, (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()));
                `else
                `uvm_info("COMPARE_TRANSFER", 
                        $sformatf("%s[%0d][%0d][%0t ns] FAILED:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, raw_req.id, (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()), UVM_LOW)
                `endif
                mismatch++;
		total_fail++;
            end
        //end
        //
        `ifdef PRINT_TO_COMPARE_FILE
        $fclose(compare_file);
        `endif
        //
    end
endtask
//
//
//
task axi_apb_scoreboard::handle_wait_data(input bit write_enable, input bit axi_or_apb, output bit break_enable);
    //
    resp_name wait_resp;
    string header;
    //
    begin
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
                if(apb_content_q.size() == 0) begin
                    header = write_enable ? "WRITE" : "READ";
                    `uvm_info(get_type_name(),
                    $sformatf("Timeout Timeout Timeout--[%s]apb_content_q is EMPTY", header), UVM_MEDIUM);
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
begin
	while(1)begin
		if (rd_req_q.size() == 0) break;
		raw_req = axi_req_item::type_id::create("raw_req");
		raw_req = rd_req_q.pop_front();
		if(!Check_Valid_Addr(raw_req.addr))  
			store_simulation_result(DECERR);
	        else 
			store_simulation_result(PSLVERR);
	end
	//
	while(1)begin
		if (wr_req_q.size() == 0) break;
		raw_req = axi_req_item::type_id::create("raw_req");
		raw_req = wr_req_q.pop_front();
		if(!Check_Valid_Addr(raw_req.addr)) begin  
			store_simulation_result(DECERR);
                        Store_Expected_Bresp(DECERR); 
		end
		else begin
			store_simulation_result(PSLVERR);
                        Store_Expected_Bresp(PSLVERR); 
		end
	end
end
endfunction
//


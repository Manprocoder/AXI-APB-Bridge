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
	typedef logic [7:0] id_type;
	typedef shared_item data_q[$]; 
	typedef resp_name resp_queue[$]; //write response
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
    //end of simulation
    bit done;
    int sim_counter;
    //
    //1--queues and arrays
    //
    //(1.a) queues 
    req_info rd_req_q [$];
    req_info wr_req_q [$];
    shared_item axi_wdata_q [$];
    //------------------------------------
    data_q axi_rdata_q, axi_rdata_tmp_q;
    //------------------------------------
    //b_channel_info actual_bchannel_q [$];
    //b_channel_info expected_bchannel_q [$];
    resp_queue actual_bresp_q, expected_bresp_q;
    //bresp associative array
    resp_queue actual_bresp_array [id_type];
    resp_queue expected_bresp_array [id_type];
    //apb transfer queue
    shared_item apb_content_q [$];
    //
    logic [31:0] apb_base_end_addr_q [$];
    logic [31:0] base_addr, end_addr;
    //(1.b) associative array
    data_q axi_rdata_array [id_type]; //each id_type maps to an individual q
    //(1.c) struct types
    //
    req_info raw_req;
    //resp_name latch_resp;
    //(1.d) queue contains all addr of axi transaction 
    logic [31:0] axi_addr_q [$];

    //(2) checkers
    int match, mismatch;
    //(3) reset
    bit axi_rst_flg;
    bit apb_rst_flag;
    //
    //(5) others
    bit compare_start;
    bit axi_transaction_valid;
    bit last_transfer;
    bit exit_data_while_loop;
    //handle in long wait (hang infinite loop)
    int axi_data_wait_cnt; //avoid waiting infinite loop with empty status of axi_rdata_array OR axi_wdata_q
    shared_item axi_content, apb_content; //common content of two protocol (wr_rd enable, data, wstrb, resp, last)
    //
    //store simulation comparison result and print all in report_phase function
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
	done = 0;
	sim_counter = 0;
        //
        //queue to store base and end address of supported APB SLAVES
        for (int i = 0; i < APB_BASE_END_ADDR_QUEUE_WIDTH; i++) begin
            base_addr = 32'h0000_0000 * (i+1);
            end_addr  = base_addr + 32'h0000_0FFF;
            apb_base_end_addr_q.push_back(base_addr);
            apb_base_end_addr_q.push_back(end_addr);
        end
        //
        if (!uvm_config_db#(string)::get(this, "", "sim_result_path", sim_result_path)) begin
         `uvm_fatal(get_type_name(), "No sim_result_path found in config DB!!!")
        end

        `uvm_info(get_type_name(), $sformatf("Results will be stored at: %s", sim_result_path), UVM_MEDIUM)
    endfunction

    //-------------------------------------------------------------------------------
    //---------------------PUSH DATA RECEVING FROM MONITOR INTO EACH QUEUE
    //-------------------------------------------------------------------------------
    //----AXI Protocol
    //(1)
    virtual function void write_Aresetn(logic arst_n);
        if (~arst_n) begin
            axi_rst_flg = 1'b1;
            sim_result_q.delete();
            rd_req_q.delete();
            wr_req_q.delete();
	    //
            axi_rdata_array.delete();
            axi_wdata_q.delete();
	    //
            actual_bresp_array.delete();
            expected_bresp_array.delete();
	    //
            apb_content_q.delete();
	    done = 0;
	    sim_counter = 0;
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
    virtual function void write_AxiRdRequest(req_info rd_req);
	rd_req_q.push_back(rd_req);
    endfunction
    //(3)
    //put rdata_item into associative array with queue element
    //
    virtual function void write_AxiRData(shared_item RdContent);
	//    RdContent.print();
	axi_rdata_q = {};
	if(axi_rdata_array.exists(RdContent.id)) begin
		axi_rdata_q = axi_rdata_array[RdContent.id];
		axi_rdata_q.push_back(RdContent);
		axi_rdata_array[RdContent.id] = axi_rdata_q;
		`uvm_info(get_type_name(), $sformatf("[EXIST]Push Rd_content into axi_rdata_array[%0d]", RdContent.id), UVM_MEDIUM);
	end
	else begin
		axi_rdata_q.push_back(RdContent);
		axi_rdata_array[RdContent.id] = axi_rdata_q;
		`uvm_info(get_type_name(), $sformatf("[NEW]Push Rd_content into axi_rdata_array[%0d]", RdContent.id), UVM_MEDIUM);
	end
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
    virtual function void write_AxiBresp(b_channel_info B_channel);
	    actual_bresp_q = {};
	    //
	if(actual_bresp_array.exists(B_channel.bid)) begin
		actual_bresp_q = actual_bresp_array[B_channel.bid];
		actual_bresp_q.push_back(B_channel.bresp);
		actual_bresp_array[B_channel.bid] = actual_bresp_q;
		`uvm_info(get_type_name(), $sformatf("[EXIST]Push Actual BRESP into actual_bresp_array[%0d]", B_channel.bid), UVM_MEDIUM);
	end
	else begin
		actual_bresp_q.push_back(B_channel.bresp);
		actual_bresp_array[B_channel.bid] = actual_bresp_q;
		`uvm_info(get_type_name(), $sformatf("[NEW]Push Actual BRESP into actual_bresp_array[%0d]", B_channel.bid), UVM_MEDIUM);
	end
    endfunction
    //
    //----APB Protocol
    //(1)
    virtual function void write_Presetn(logic preset_n);
        if(~preset_n) begin
		   apb_rst_flag = 1'b1;
		    done = 0;
		    sim_counter = 0;
		   `uvm_info(get_type_name(), $sformatf("[%0t ns] preset_n signal is acting", $time), UVM_MEDIUM)
	end
        else begin
		   apb_rst_flag = 1'b0;
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
    //-------------------------WAIT ACTUAL TRANSFER
    //-------------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        //
        forever begin
	    wait_apb_transfer(3);
	    #(`CLK_CYCLE);
	    if(compare_start) begin
		    if(apb_content_q[0].write) begin
			`uvm_info(get_type_name(), $sformatf("[WRITE] COMPARE TRANSACTION START"), UVM_MEDIUM);
			compare_transaction(1'b1);
		    end
		    else begin
			wait(axi_rdata_array.num() > 0);
			`uvm_info(get_type_name(), $sformatf("[READ] COMPARE TRANSACTION START"), UVM_MEDIUM);
			compare_transaction(1'b0);
		    end
	    end
        end
        //
    endtask
    //**************************************************************************************************
    //----------------------------------------MAIN TASKS----------------------------------------------
    //**************************************************************************************************
    virtual task wait_apb_transfer(
	    input int timeout_consecutive_times
    );
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
				sim_counter = 0;
				done = 0;
			end
			//
			begin: thread_3
				#APB_TIMEOUT;
				sim_counter++;
				if(sim_counter == timeout_consecutive_times) done = 1;
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
virtual task compare_transaction(
	 input bit wr_en
);

	wait(axi_rst_flg == 1'b0);
        fork 
            begin //FIRST THREAD
                @(posedge axi_rst_flg);
                `uvm_info(get_type_name(), $sformatf("RISING EDGE AXI_RST_FLAG!!!"), UVM_MEDIUM);
            end
            begin //SECOND_THREAD
		init_variable();
		//Fetch valid request to parse and compare
		Fetch_Valid_Req(wr_en, raw_req);// axi_transaction_valid);
		    Do_Comparison(wr_en, raw_req);
		    //if(wr_en) begin 
			    //Store_Expected_Bresp(raw_req.id[7:0], resp_name'(2'b00));
		    //end
            end //end of SECOND_THREAD
        join_any
        disable fork;
endtask
    //**************************************************************************************************
    //-------------------------------------SUB TASKS
    //**************************************************************************************************
virtual task init_variable;
begin
	//axi_transaction_valid = 1'b0;
	match = 0;
	mismatch = 0;
	last_transfer = 1'b0;
	axi_data_wait_cnt = 0;
	clr_req(raw_req);
end
endtask
//
//Operation Order:
//--: check unvalid req -> pop unvalid data
//--: return valid req and do compare     
virtual task Fetch_Valid_Req
(
    input bit wr_en,
    output req_info req
    //output bit req_valid
);
    //
    bit queue_not_empty;
    bit error_case;
    req_info temp_req;
    //
    begin//begin_end block
	clr_req(req);
        while (1) begin
            queue_not_empty = (wr_en) ? (wr_req_q.size() > 0) : (rd_req_q.size() > 0);
            if(queue_not_empty) begin
		clr_req(temp_req); //refresh struct before receving new request
		temp_req = wr_en ? wr_req_q[0] : rd_req_q[0];
		error_case = (temp_req.size != 3'b010) | (temp_req.burst == 2'b11);//unsupported transactions
                //
                if(!Check_Valid_Addr(temp_req.address) || (error_case)) begin
		    
                    temp_req = (wr_en) ? (wr_req_q.pop_front()) : (rd_req_q.pop_front());
                    if(wr_en) begin
			if(error_case) 
                        Store_Expected_Bresp(temp_req.id[7:0], resp_name'(2'b10));
			else 
                        Store_Expected_Bresp(temp_req.id[7:0], resp_name'(2'b11));
                    end
                    Pop_unvalid_data(wr_en, temp_req);
                    //req_valid = 1'b0;
                end
                else begin
		    req = (wr_en) ? wr_req_q.pop_front() : rd_req_q.pop_front();
		    //req_valid = 1'b1;
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
    //
    //
    virtual function bit Check_Valid_Addr(
        input logic [31:0] start_address
    );
        begin
            if(start_address <= apb_base_end_addr_q[`SLAVE_CNT*2-1]) begin
                return 1;
            end
            else begin
                return 0;
            end
        end
    endfunction
    //
    //
    //
    virtual task Do_Comparison(
        input bit wr_en,
	input req_info req
    );
        //
	int transfer_index = 0;
	resp_name bresp = resp_name'(2'b00);
        //
	begin //begin_end block
            //at first
	    calculate_and_store_addr(1'b1, req, axi_addr_q);
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
			    wait(axi_rdata_array.exists(req.id[7:0]) && axi_rdata_array[req.id[7:0]].size() > 0);
		    end
		    `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: TRANSFER START!!!"), UVM_MEDIUM)
			clr_content();
			apb_content = apb_content_q.pop_front();
				//
		    if(wr_en) begin
			axi_content = axi_wdata_q.pop_front();
		    `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: READY FOR WR_TRANSFER COMPARE!!!"), UVM_MEDIUM)
		    end
		    else begin
			axi_rdata_tmp_q = axi_rdata_array[req.id[7:0]];
			axi_content = axi_rdata_tmp_q.pop_front();
			axi_rdata_array[req.id[7:0]] = axi_rdata_tmp_q;
		    `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: READY FOR RD_TRANSFER COMPARE!!!"), UVM_MEDIUM)
		    end
		    //aligned address (1'b1 in second argument)
		    axi_content.addr = axi_addr_q.pop_front(); 
		    //axi_content.print();
		    //store resp
		    bresp = resp_name'(bresp | apb_content.resp);
		    //
		    compare_transfer(req.id, axi_content, apb_content, transfer_index);
		    transfer_index++;
		    `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: TRANSFER DONE!!!"), UVM_MEDIUM)
		    //
		    last_transfer = axi_content.last;
		    //
		    if(last_transfer == 1'b1) begin
			    if(wr_en) begin
			    Store_Expected_Bresp(raw_req.id[7:0], bresp);
			    end
		    `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: %s TRANSACTION DONE", wr_en ? "WRITE" : "READ"), UVM_MEDIUM)
		    	//
			handle_last_transfer(req, axi_content.resp, match, mismatch);
			break; //exit while(1) 
		    end
	    end//end of while(1)
	end//end of begin_end block
    endtask
    //
    //
    //
    virtual task Pop_unvalid_data(
        input bit wr_en,
        input req_info req
    );
        //
	bit data_available = 0;
	//
        begin//START
            //
            while(1) begin
		    data_available = (wr_en) ? (axi_wdata_q.size() > 0) : (axi_rdata_array[req.id[7:0]].size() > 0);
                if (data_available) begin
			 clr_content();
		   if(wr_en) begin
			axi_content = axi_wdata_q.pop_front();
		    `uvm_info(get_type_name(), $sformatf("[INVALID_WDATA]: REMOVED FROM QUEUE!!!"), UVM_MEDIUM)
		    end
		    else begin
			axi_rdata_tmp_q = axi_rdata_array[req.id[7:0]];
			axi_content = axi_rdata_tmp_q.pop_front();
			axi_rdata_array[req.id[7:0]] = axi_rdata_tmp_q;
		    `uvm_info(get_type_name(), $sformatf("[INVALID_RDATA]: REMOVED FROM QUEUE!!!"), UVM_MEDIUM)
		    end
		    //axi_content.print();
		    last_transfer = axi_content.last;
		    axi_data_wait_cnt = 0;
		    //
		    if(last_transfer == 1'b1) begin
			    `uvm_info(get_type_name(), $sformatf("[INVALID LAST_DATA]: REMOVED FROM QUEUE!!!"), UVM_MEDIUM)
			handle_last_transfer(req, axi_content.resp, match, mismatch);
			break; //exit while(1) 
		    end
                end
	       	else begin
                    axi_data_wait_cnt++;
                    #(`CLK_CYCLE);
    //wr_en
    //axi_or_apb;
    //data_wait_cnt;
    //raw_req;
    //match_cnt;
    //mismatch_cnt;
    //output bit break_enable;
                    handle_wait_data(wr_en, 1'b1, axi_data_wait_cnt, req, match, mismatch, exit_data_while_loop);
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
    virtual task Store_Expected_Bresp(
        input logic [7:0] id,
        input resp_name rsp
    );
        //
	resp_queue expected_bresp_q;
        begin
	    expected_bresp_q = {};
	   //
	   if(expected_bresp_array.exists(id)) begin
		   expected_bresp_q = expected_bresp_array[id];
		   expected_bresp_q.push_back(rsp);
		   expected_bresp_array[id] = expected_bresp_q;
	   end
	   else begin
		   expected_bresp_q.push_back(rsp);
		   expected_bresp_array[id] = expected_bresp_q;
	   end	   
        end
    endtask

//***********************************************************************************
//---------------------------------AXI_ADDR_CALCULATION FUNCTION---------------------
//***********************************************************************************
virtual task calculate_and_store_addr(
	    input bit only_aligned_addr,
	    input req_info req,
	    output logic [31:0] addr_q [$]
);
//
parsed_req_info parsed_req;
logic [31:0] addr_of_beat;
//
begin
	    clr_req(parsed_req);
            parsed_req = parse_request(req);
	    //
	    addr_q = {};
	    for(int i = 0; i < parsed_req.len; i++) begin
		    addr_of_beat = 0;
		    addr_of_beat = calculate_next_addr(i, only_aligned_addr, parsed_req); 
		    addr_q.push_back(addr_of_beat);
	    end

end
endtask
//
//
//
function parsed_req_info parse_request(
    input req_info raw_req
);
    //inter-function variables
    //
    int req_file;
    string header;
    parsed_req_info req;
  //
  begin
    //declare
    req_file = $fopen($sformatf("%s/REQ_INFO/req_detail.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
	if(req_file == 0) begin
		`uvm_warning(get_type_name(), $sformatf("Failed to open req_detail.log"))
	end
	req.id = raw_req.id;
    req.start_address = raw_req.address;
    req.size = raw_req.size;
    req.len = raw_req.len + 1;
    req.burst = raw_req.burst;
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
    input bit only_aligned_addr,
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
            //`uvm_info(get_type_name(), $sformatf("[%s][id: %0d][%0d]: next_wrap_address = 0x%08h", header, req.id[7:0], i, next_address),UVM_MEDIUM);
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
        //recalculate address if needed 
        next_address = (only_aligned_addr) ? {next_address[31:2], 2'b00} : next_address;
        //
        return next_address;
    end
endfunction
//
//compare task
//
virtual task compare_transfer(
    input logic [8:0] id,
    input shared_item axi_transfer,
    input shared_item apb_transfer,
    input int i
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
	    if(axi_transfer.compare(apb_transfer) && rid_match) begin 
                `ifdef PRINT_TO_SUM_FILE
                $fdisplay(compare_file, 
                        $sformatf("%s[%0d][%0d][%0t ns] matched:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, id[7:0], (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()));
                `else
                `uvm_info("COMPARE_TRANSFER" 
                        $sformatf("%s[%0d][%0d][%0t ns] matched:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, id[7:0], (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()), UVM_MEDIUM)
                `endif
                match++;
            end
            else begin
                `ifdef PRINT_TO_SUM_FILE
                $fdisplay(compare_file, 
                        $sformatf("%s[%0d][%0d][%0t ns] unmatched:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, id[7:0], (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()));
                `else
                `uvm_info("COMPARE_TRANSFER", 
                        $sformatf("%s[%0d][%0d][%0t ns] unmatched:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, id[7:0], (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()), UVM_MEDIUM)
                `endif
                mismatch++;
            end
        //end
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
		//#(`CLK_CYCLE);
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
        //trans_completed = 1'b1;
        //#(`CLK_CYCLE);
    end
endtask
//
virtual function void store_comparison_result(
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
endfunction
//
//
//
virtual task handle_wait_data(
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
            //trans_completed = 1'b1;
            if(axi_or_apb == 1) begin
                if((write_enable==1'b0) && (axi_rdata_array.size() == 0)) begin
                    `uvm_info(get_type_name(),
                    $sformatf("TRANS[READ][%0d]:Timeout Timeout Timeout--axi_rdata_array is EMPTY", raw_req.id[7:0]), UVM_MEDIUM);
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
//
virtual function void check_missing_transaction;
	//
	req_info req;
begin
	while(1)begin
		if (rd_req_q.size() == 0) break;
		req = rd_req_q.pop_front();
		store_comparison_result(req, resp_name'(2'b11), 0, 0);
	end
	//
	while(1)begin
		if (wr_req_q.size() == 0) break;
		req = wr_req_q.pop_front();
		store_comparison_result(req, resp_name'(2'b11), 0, 0);
	end
end
endfunction
//******************************************************************************************************************
//------------------------- report_phase() and final_phase() function
//******************************************************************************************************************
virtual function void report_phase(uvm_phase phase);
    //declare needed variables
    string rw_type;
    string burst_str;
    string resp_str;
    //
    check_missing_transaction();
    // file variable
    `ifdef PRINT_TO_SUM_FILE
        sim_summary_file = $fopen($sformatf("%s/SIM_SUMMARY/summary.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
		if(sim_summary_file == 0) begin
			`uvm_warning(get_type_name(), $sformatf("Failed to open summary.log file"))
		end
		$fdisplay(sim_summary_file,"================== REPORT SUMMARY =================");
	`else
		`uvm_info(get_type_name(),"================== REPORT SUMMARY =================", UVM_MEDIUM)
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
                sim_result_q[i].case_mismatches), UVM_MEDIUM);
			`endif
        end
    end
    else begin
        `ifdef PRINT_TO_SUM_FILE
		$fdisplay(sim_summary_file,"======== Simulation Result Queue is EMPTY =========");
        `else 
        `uvm_info(get_type_name(),"======== Simulation Result Queue is EMPTY =========",UVM_MEDIUM);
        `endif
    end
    //empty all queues
    apb_base_end_addr_q.delete();
    sim_result_q.delete();
    //
    `ifdef PRINT_TO_SUM_FILE
	$fdisplay(sim_summary_file,"===================================================");
    `else
    `uvm_info(get_type_name(),"===================================================",UVM_MEDIUM);
    `endif
endfunction
//-------------------------------------------------
//-- final_phase() function
//---------------------------------------------------
virtual function void final_phase(uvm_phase phase);
    //logic [7:0] expected_bid;
    //logic [7:0] actual_bid;
    logic [7:0] id;
    resp_name expected_bresp, actual_bresp;
    resp_queue expected_tmp_q, actual_tmp_q;
    `ifdef PRINT_TO_SUM_FILE
	$fdisplay(sim_summary_file,"================== BCHANNEL REPORT =================");
    `else 
    `uvm_info(get_type_name(),"================== BCHANNEL REPORT =================", UVM_MEDIUM);
    `endif 
    if(expected_bresp_array.num() > 0 && actual_bresp_array.num() > 0) begin
	id = 0;
	for(int i = 0; i < 256; i++) begin
	if(expected_bresp_array.exists(id)) begin //existence
		if(actual_bresp_array.exists(id)) begin
			actual_tmp_q = {};
			actual_tmp_q = actual_bresp_array[id];
			expected_tmp_q = {};
			expected_tmp_q = expected_bresp_array[id];
			//do compare
			foreach(actual_tmp_q[i]) begin
				actual_bresp = actual_tmp_q[i]; 
				expected_bresp = expected_tmp_q[i]; 
			`ifdef PRINT_TO_SUM_FILE
				$fdisplay(sim_summary_file,
				$sformatf("[COMPARE_BCHANNEL]: actual_bid=%0d---expected_bid=%0d", id, id));
				//
				if(actual_bresp == expected_bresp) begin
				$fdisplay(sim_summary_file,
				$sformatf("[----------------]: actual_bresp=%s MATCH expected_bresp=%s",
			       	actual_bresp.name(), expected_bresp.name())); 
				end
				else begin
				$fdisplay(sim_summary_file,
				$sformatf("[----------------]: actual_bresp=%s MISMATCH expected_bresp=%s",
			       	actual_bresp.name(), expected_bresp.name())); 
				end
		    	`else 
				`uvm_info(get_type_name(),
				$sformatf("[COMPARE_BCHANNEL]: actual_bid=%0d---expected_bid=%0d", id, id), UVM_MEDIUM);
				//
				if(actual_bresp == expected_bresp) begin
				`uvm_info(get_type_name(),
				$sformatf("[----------------]: actual_bresp=%s MATCH expected_bresp=%s",
			       	actual_bresp.name(), expected_bresp.name()), UVM_MEDIUM); 
				end
				else begin
				`uvm_info(get_type_name(),
				$sformatf("[----------------]: actual_bresp=%s MISMATCH expected_bresp=%s",
			       	actual_bresp.name(), expected_bresp.name()), UVM_MEDIUM); 
				end
			`endif
				actual_bresp = resp_name'(2'b00);
				expected_bresp = resp_name'(2'b00);
			end
		end
		else begin
		    `ifdef PRINT_TO_SUM_FILE
			$fdisplay(sim_summary_file,$sformatf("id = %0d does not appear in actual array", id));
		    `else 
		    `uvm_info(get_type_name(),$sformatf("id = %0d does not appear in actual array", id), UVM_MEDIUM);
		    `endif 
		end
	end//end of existence
	id++;
	end//end of for	
    end
    else begin
	    if(expected_bresp_array.num() == 0) begin
		    `uvm_info(get_type_name(),"EMPTY expected_bresp_array", UVM_MEDIUM);
	    end
	    if(actual_bresp_array.num() == 0) begin
		    `uvm_info(get_type_name(),"EMPTY actual_bresp_array", UVM_MEDIUM);
	    end
    end
            expected_bresp_array.delete();
            actual_bresp_array.delete();
    //
    `ifdef PRINT_TO_SUM_FILE
    $fdisplay(sim_summary_file,"=======================================================");
	$fclose(sim_summary_file);
    `else
    `uvm_info(get_type_name(),"=======================================================", UVM_MEDIUM);
    `endif 
endfunction
endclass

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
typedef logic [7:0] id_of_burst;
typedef shared_item data_q[$]; 
typedef resp_name resp_q[$]; //write response
typedef result_info result_q[$];
//
class base_scoreboard extends uvm_scoreboard;
    //register UVM factory
    `uvm_component_utils(base_scoreboard)
    //
    //Data members
    //
    protected req_info raw_req;
    protected parsed_req_info parsed_req;
    protected int match, mismatch;
    protected bit last_beat;
    protected logic [31:0] apb_base_end_addr_q [$];
    protected logic [31:0] axi_addr_q[$]; //axi transfer address queue
    //handle in long wait (hang infinite loop)
    protected int axi_data_wait_cnt; //avoid waiting infinite loop with empty status of axi_rdata_array OR axi_wdata_q
    //associate array to store id
    protected int rd_id_arr [id_of_burst];
    protected int wr_id_arr [id_of_burst];
    //queue to store request info
    protected req_info rd_req_q [$];
    protected req_info wr_req_q [$];
    protected shared_item axi_wdata_q [$];
    protected data_q axi_rdata_array [id_of_burst]; //each id_of_burst maps to an individual q
    //bresp associative array
    protected resp_q actual_bresp_array [id_of_burst];
    protected resp_q expected_bresp_array [id_of_burst];
    //
    //store simulation comparison result and print all in report_phase function
    //
    protected result_q sim_result_arr [id_of_burst];

    function new(string name ="base_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction
    //
    virtual function void build_phase(uvm_phase phase);

    endfunction
//
//methods
//
virtual function void flush_req_queue();
	rd_req_q.delete();
	wr_req_q.delete();
endfunction
//
virtual function void flush_data();
	axi_wdata_q.delete();
	axi_rdata_array.delete();
endfunction
//
virtual function void flush_resp();
    actual_bresp_array.delete();
    expected_bresp_array.delete();
endfunction
//
virtual function void flush_sim_result();
	sim_result_arr.delete();
endfunction
//
virtual function void store_id(input bit wr_en, id_of_burst id);
	if(wr_en) begin
		if(wr_id_arr.exists(id)) wr_id_arr[id]++;
		else wr_id_arr[id] = 1;
	end
	else begin
		if(rd_id_arr.exists(id)) rd_id_arr[id]++;
		else rd_id_arr[id] = 1;
	end
endfunction
//
//queue to store base and end address of supported APB SLAVES
virtual function void init_slave_addr(
    input int total_base_end_addr,
    input logic [31:0] starting_addr,
    input logic [31:0] page_size 
);
    logic [31:0] base_addr, end_addr;
    //
    begin
        for (int i = 0; i < total_base_end_addr; i++) begin
            base_addr = starting_addr * (i+1);//32'h0000_0000 * (i+1);
            end_addr  = base_addr + page_size; //32'h0000_0FFF;
            apb_base_end_addr_q.push_back(base_addr);
            apb_base_end_addr_q.push_back(end_addr);
        end
    end
endfunction
//
virtual function void flush_axi_addr_q;
	axi_addr_q.delete();
endfunction
//
virtual function void flush_slave_addr;
	apb_base_end_addr_q.delete();
endfunction
//
//
virtual function void init_attribute;
begin
	match = 0;
	mismatch = 0;
	last_beat = 1'b0;
	axi_data_wait_cnt = 0;
	clr_raw_req();
end
endfunction
//
//virtual function void clr_raw_req(
	//input req_info req
//);
virtual function void clr_raw_req;
	begin
		raw_req.id = 0;
		raw_req.address = 0;
		raw_req.len = 0;
		raw_req.size = 0;
		raw_req.burst = burst_name'(2'b11);
	end
endfunction
//
//---------------------------------AXI_ADDR_CALCULATION FUNCTION---------------------
//
virtual function void calculate_and_store_addr(
    input bit only_aligned_addr
);
//
logic [31:0] addr_of_beat;
//
begin
            parse_request();
	    //
	    axi_addr_q = {};
	    for(int i = 0; i < parsed_req.len; i++) begin
		    addr_of_beat = 0;
		    addr_of_beat = calculate_next_addr(i, only_aligned_addr); 
		    axi_addr_q.push_back(addr_of_beat);
	    end

end
endfunction
//
//
virtual function void parse_request;
  begin
    parsed_req.id = raw_req.id;
    parsed_req.start_address = raw_req.address;
    parsed_req.size = raw_req.size;
    parsed_req.len = raw_req.len + 1;
    parsed_req.burst = raw_req.burst;
    //---------------------------------------------------
    // pre-calculate address details
    //---------------------------------------------------
    parsed_req.bytes_in_transfer = 2**raw_req.size;
    //incr addr
    parsed_req.total_bytes = parsed_req.bytes_in_transfer * parsed_req.len;    
    parsed_req.aligned_address = (parsed_req.bytes_in_transfer!=0) 
    ? (int'(parsed_req.start_address/parsed_req.bytes_in_transfer)) * parsed_req.bytes_in_transfer : 'hz;
    //wrap addr
    parsed_req.wrap_boundary = (int'(parsed_req.start_address/parsed_req.total_bytes)) * parsed_req.total_bytes;
    parsed_req.wrap_highest_address = parsed_req.wrap_boundary + parsed_req.total_bytes; 
  end
  //
endfunction
//
//function to calculate transfer address
//
virtual function logic [31:0] calculate_next_addr(
    input int i,
    input bit only_aligned_addr
);
	//
//	string header;
    logic [31:0] next_address;
	//
    begin
//	header = (parsed_req.id[8] == 1) ? "WRITE" : "READ";
        //
        if(parsed_req.burst == 2'b00)begin  //fixed
            next_address = parsed_req.start_address;
        end
        else if (parsed_req.burst == 2'b01) begin //incr
            if(i==0) begin
                next_address = parsed_req.start_address;
            end
            else 
                next_address = parsed_req.aligned_address + i * parsed_req.bytes_in_transfer;
        end
        else if (parsed_req.burst == 2'b10) begin //wrap
            next_address = parsed_req.aligned_address + i * parsed_req.bytes_in_transfer;
            if(next_address == parsed_req.wrap_highest_address) begin
                next_address = parsed_req.wrap_boundary;
            end
            else if(next_address > parsed_req.wrap_highest_address) begin
            //`uvm_info(get_type_name(), $sformatf("[%s][id: %0d][%0d]: next_wrap_address = 0x%08h", header, parsed_req.id[7:0], i, next_address),UVM_MEDIUM);
                next_address = parsed_req.wrap_boundary + (next_address - parsed_req.wrap_highest_address); 
            end
            else begin
                next_address = next_address;
            end   
        end //end of  "else if (m_mon_vif.awburst == 2'b10)""
        //recalculate address if needed 
        next_address = (only_aligned_addr) ? {next_address[31:2], 2'b00} : next_address;
        //
        return next_address;
    end
endfunction
    //
    //
virtual function void handle_last_transfer(
    input resp_name transfer_resp
);
    begin
        store_simulation_result(transfer_resp);
    end
endfunction
//
virtual function void store_simulation_result(
    input resp_name actual_status
);
    //
    result_info Transaction_result;
    result_q tmp_q; 
    //
    begin
        Transaction_result.id = raw_req.id;
        Transaction_result.address = raw_req.address;
        Transaction_result.len = raw_req.len;
        Transaction_result.size = raw_req.size;
        Transaction_result.burst = raw_req.burst;
        Transaction_result.resp = resp_name'(actual_status);
        Transaction_result.case_matches = match;
        Transaction_result.case_mismatches = mismatch;
	//
	tmp_q = {};
        //
	if(sim_result_arr.exists(raw_req.id[7:0])) begin
		tmp_q = sim_result_arr[raw_req.id[7:0]];
		tmp_q.push_back(Transaction_result);
		sim_result_arr[raw_req.id[7:0]] = tmp_q;
		`uvm_info(get_type_name(), 
		$sformatf("[EXISTING]Store SIM RESULT of [%s][%0d(ID)]", raw_req.id[8] ? "WRITE" : "READ_", raw_req.id[7:0]), UVM_LOW)
	end
	else begin
		tmp_q.push_back(Transaction_result);
		sim_result_arr[raw_req.id[7:0]] = tmp_q;
		`uvm_info(get_type_name(), 
		$sformatf("[NEW]Store SIM RESULT of [%s][%0d(ID)]", raw_req.id[8] ? "WRITE" : "READ_", raw_req.id[7:0]), UVM_LOW)
	end
    end
    //
endfunction
//
//
virtual task Store_Expected_Bresp(
	input id_of_burst id,
	input resp_name rsp
);
//
resp_q expected_bresp_q;
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
//
//
endclass
//
//axi_apb_scb class
//
class scoreboard extends base_scoreboard;
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
    //
    //(1) apb transfer queue
    shared_item apb_content_q [$];
    //
    //(2) reset
    bit axi_rst_flg;
    bit apb_rst_flag;
    //
    //(3) others
    bit compare_start;
    shared_item axi_content, apb_content; //common content of two protocol (wr_rd enable, data, wstrb, resp, last)
    //end of simulation
    bit done;
    int sim_counter;
    //
    string sim_result_path;
    int compare_file;
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
        //super.build_phase(phase);
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
	clr_member();
	init_slave_addr(APB_BASE_END_ADDR_QUEUE_WIDTH, 32'h0, 32'h0000_0FFF);
	//
	if(!uvm_config_db#(string)::get(this, "", "sim_result_path", sim_result_path)) begin
		`uvm_error(get_type_name(), "sim_result_path is NOT FOUND!!!")
	end
    endfunction
    //
    virtual function void clr_member();
	    done = 0;
	    sim_counter = 0;
    endfunction
    //	
    //
    virtual function void flush_apb_queue();
	    apb_content_q.delete();
    endfunction
    //-------------------------------------------------------------------------------
    //---------------------PUSH DATA RECEVING FROM MONITOR INTO EACH QUEUE
    //-------------------------------------------------------------------------------
    //----AXI Protocol
    //(1)
    virtual function void write_Aresetn(logic arst_n);
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
    virtual function void write_AxiRdRequest(req_info rd_req);
	rd_req_q.push_back(rd_req);
    endfunction
    //(3)
    //put rdata_item into associative array with queue element
    //
    virtual function void write_AxiRData(shared_item RdContent);
	//    RdContent.print();
	    data_q axi_rdata_q = {};
	//axi_rdata_q = {};
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
    virtual function void write_AxiWData(shared_item wr_content);
        axi_wdata_q.push_back(wr_content);
    endfunction
    //(6)
    virtual function void write_AxiBresp(b_channel_info B_channel);
	   resp_q actual_bresp_q = {};
	    //
	if(actual_bresp_array.exists(B_channel.bid)) begin
		actual_bresp_q = actual_bresp_array[B_channel.bid];
		actual_bresp_q.push_back(B_channel.bresp);
		actual_bresp_array[B_channel.bid] = actual_bresp_q;
		`uvm_info(get_type_name(), 
		$sformatf("[EXIST]Push Actual BRESP into actual_bresp_array[%0d]", B_channel.bid), UVM_MEDIUM);
	end
	else begin
		actual_bresp_q.push_back(B_channel.bresp);
		actual_bresp_array[B_channel.bid] = actual_bresp_q;
		`uvm_info(get_type_name(), 
		$sformatf("[NEW]Push Actual BRESP into actual_bresp_array[%0d]", B_channel.bid), UVM_MEDIUM);
	end
    endfunction
    //
    //----APB Protocol
    //(1)
    virtual function void write_Presetn(logic preset_n);
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
		init_attribute();
		//Fetch valid request to parse and compare
		Fetch_Valid_Req(wr_en);//, raw_req);
		Do_Comparison(wr_en);//, raw_req);
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
virtual task Fetch_Valid_Req
(
    input bit wr_en
);
    //
    bit queue_not_empty;
    bit error_case;
    //
    begin//begin_end block
        while (1) begin
            queue_not_empty = (wr_en) ? (wr_req_q.size() > 0) : (rd_req_q.size() > 0);
            if(queue_not_empty) begin
		clr_raw_req(); //refresh struct before receving new request
		//raw_req = wr_en ? wr_req_q[0] : rd_req_q[0];
                raw_req = (wr_en) ? (wr_req_q.pop_front()) : (rd_req_q.pop_front());
		error_case = (raw_req.size != 3'b010);// | (raw_req.burst == 2'b11);//unsupported transactions
                //
                if(!Check_Valid_Addr(raw_req.address) || (error_case)) begin
		    
                    if(wr_en) begin
			if(error_case) 
                        Store_Expected_Bresp(raw_req.id[7:0], resp_name'(2'b10));//pslverr
			else 
                        Store_Expected_Bresp(raw_req.id[7:0], resp_name'(2'b11)); //decerr
                    end
                    Pop_unvalid_data(wr_en);
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
    //
    //
    virtual function bit Check_Valid_Addr(
    	input logic [31:0] start_address
    );
    	//
	bit flag;
        begin
            flag = (start_address <= apb_base_end_addr_q[`SLAVE_CNT*2-1]);
        end
	//
	return flag;
    endfunction
    //
    //
    //
    virtual task Pop_unvalid_data(
        input bit wr_en
    );
        //
	bit data_available = 0;
	bit exit_data_while_loop = 0;
        data_q axi_rdata_tmp_q = {};
	//
        begin//START
            //
            while(1) begin
		    data_available = (wr_en) ? (axi_wdata_q.size() > 0) : (axi_rdata_array[raw_req.id[7:0]].size() > 0);
                if (data_available) begin
			 clr_content();
		   if(wr_en) begin
			axi_content = axi_wdata_q.pop_front();
		    `uvm_info(get_type_name(), $sformatf("[INVALID_WDATA]: REMOVED FROM QUEUE!!!"), UVM_MEDIUM)
		    end
		    else begin
			axi_rdata_tmp_q = axi_rdata_array[raw_req.id[7:0]];
			axi_content = axi_rdata_tmp_q.pop_front();
			axi_rdata_array[raw_req.id[7:0]] = axi_rdata_tmp_q;
		    `uvm_info(get_type_name(), $sformatf("[INVALID_RDATA]: REMOVED FROM QUEUE!!!"), UVM_MEDIUM)
		    end
		    //axi_content.print();
		    last_beat = axi_content.last;
		    axi_data_wait_cnt = 0;
		    //
		    if(last_beat == 1'b1) begin
			    `uvm_info(get_type_name(), $sformatf("[INVALID LAST_DATA]: REMOVED FROM QUEUE!!!"), UVM_MEDIUM)
			handle_last_transfer(axi_content.resp);
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
virtual task Do_Comparison(
        input bit wr_en
    );
        //
	int transfer_index = 0;
	resp_name bresp = resp_name'(2'b00);
	data_q axi_rdata_tmp_q = {};
        //
	begin //begin_end block
            //at first
	    calculate_and_store_addr(1'b1);
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
			    wait(axi_rdata_array.exists(raw_req.id[7:0]) && axi_rdata_array[raw_req.id[7:0]].size() > 0);
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
			axi_rdata_tmp_q = axi_rdata_array[raw_req.id[7:0]];
			axi_content = axi_rdata_tmp_q.pop_front();
			axi_rdata_array[raw_req.id[7:0]] = axi_rdata_tmp_q;
		    `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: READY FOR RD_TRANSFER COMPARE!!!"), UVM_MEDIUM)
		    end
		    //aligned address (1'b1 in second argument)
		    axi_content.addr = axi_addr_q.pop_front(); 
		    //axi_content.print();
		    //store resp
		    bresp = resp_name'(bresp | apb_content.resp);
		    //
		    compare_transfer(raw_req.id, axi_content, apb_content, transfer_index);
		    transfer_index++;
		    `uvm_info(get_type_name(), $sformatf("[DO_COMPARE]: TRANSFER DONE!!!"), UVM_MEDIUM)
		    //
		    last_beat = axi_content.last;
		    //
		    if(last_beat == 1'b1) begin
			    if(wr_en) begin
			    Store_Expected_Bresp(raw_req.id[7:0], bresp);
			    end
		    `uvm_info(get_type_name(),
		     $sformatf("[DO_COMPARE]: %s TRANSACTION DONE", wr_en ? "WRITE" : "READ"), UVM_MEDIUM)
		    	//
			handle_last_transfer(axi_content.resp);
			break; //exit while(1) 
		    end
	    end//end of while(1)
	end//end of begin_end block
    endtask

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
                //`ifdef PRINT_TO_SUM_FILE
                //$fdisplay(compare_file, 
                        //$sformatf("%s[%0d][%0d][%0t ns] matched:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        //header, id[7:0], (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()));
                //`else
                //`uvm_info("COMPARE_TRANSFER", 
                        //$sformatf("%s[%0d][%0d][%0t ns] matched:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        //header, id[7:0], (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()), UVM_LOW)
                //`endif
                match++;
            end
            else begin
                `ifdef PRINT_TO_SUM_FILE
                $fdisplay(compare_file, 
                        $sformatf("%s[%0d][%0d][%0t ns] FAILED:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, id[7:0], (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()));
                `else
                `uvm_info("COMPARE_TRANSFER", 
                        $sformatf("%s[%0d][%0d][%0t ns] FAILED:\nAXI_TRANSFER: %sAPB_TRANSFER: %s",
                        header, id[7:0], (i+1), $time,axi_transfer.convert2string(), apb_transfer.convert2string()), UVM_LOW)
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
//
virtual task handle_wait_data(
    input bit write_enable,
    input bit axi_or_apb,
    output bit break_enable
);
    //
    resp_name wait_resp;
    string header;
    //
    begin
        //
        if (axi_data_wait_cnt > TIME_OUT_BOUNDARY) begin
            wait_resp = resp_name'(2'b01);
            store_simulation_result(wait_resp);
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
virtual task clr_content;
    //clear old values
    axi_content.clear();
    apb_content.clear();
endtask
//
//
//
virtual function void check_missing_transaction;
begin
	while(1)begin
		if (rd_req_q.size() == 0) break;
		raw_req = rd_req_q.pop_front();
		store_simulation_result(resp_name'(2'b11));
	end
	//
	while(1)begin
		if (wr_req_q.size() == 0) break;
		raw_req = wr_req_q.pop_front();
		store_simulation_result(resp_name'(2'b11));
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
    id_of_burst arr_idx;
    result_q sim_result_q;
    //
    check_missing_transaction();
    // file variable
    //`ifdef PRINT_TO_SUM_FILE
        //sim_summary_file = $fopen($sformatf("%s/SIM_SUMMARY/summary.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
		//if(sim_summary_file == 0) begin
			//`uvm_warning(get_type_name(), $sformatf("Failed to open summary.log file"))
		//end
		//$fdisplay(sim_summary_file,"================== REPORT SUMMARY =================");
	//`else
		`uvm_info(get_type_name(),"================== REPORT SUMMARY =================", UVM_LOW)
	//`endif
    if (sim_result_arr.size() > 0) begin
	    for(int k = 0; k <= 255; k++) begin
		assert($cast(arr_idx, k));
		if(sim_result_arr.exists(arr_idx)) begin
		   sim_result_q = {};
		   //
		   sim_result_q = sim_result_arr[arr_idx];
		   `uvm_info(get_type_name(), $sformatf("SIM RESULT of %0d(ID):", arr_idx), UVM_LOW);
		   //
		   if(sim_result_q.size() == 0) begin
			   `uvm_error(get_type_name(), $sformatf("Sim result of %0d(ID) is EMPTY!!!", arr_idx))
		   end
		   //
		foreach (sim_result_q[i]) begin
		    rw_type   = (sim_result_q[i].id[8]) ? "WRITE" : "READ_";
		    burst_str = sim_result_q[i].burst.name(); // assuming enum has .name()
		    resp_str = sim_result_q[i].resp.name(); // assuming enum has .name()
		    // print transaction detail
				//`ifdef PRINT_TO_SUM_FILE
		    //$fdisplay(sim_summary_file,
		    //$sformatf("TRANS[%0d] %s:
		    //Addr=0x%04h_%04h Len_1=%0d Size=%0d(bytes_in_beat) Burst=%s Resp=%s | Matches=%0d, MisMatches=%0d",
			//sim_result_q[i].id[7:0],
			//rw_type,
			//sim_result_q[i].address[31:16],
			//sim_result_q[i].address[15:0],
			//sim_result_q[i].len + 1,
			//2**sim_result_q[i].size,
			//burst_str,
			//resp_str,
			//sim_result_q[i].case_matches,
			//sim_result_q[i].case_mismatches));
				//`else
    `uvm_info(get_type_name(),
    $sformatf("TRANS[%0d] %s:Addr=0x%04h_%04h Len_1=%0d Size=%0d(bytes_in_beat) Burst=%s Resp=%s | PASS=%0d, FAIL=%0d",
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
				//`endif
			end//end of foreach
			`uvm_info(get_type_name(), "\n", UVM_LOW)
		end//end of if arr_idx
	end
	end//end of if sim_result_arr.size() > 0
    else begin
        //`ifdef PRINT_TO_SUM_FILE
		//$fdisplay(sim_summary_file,"======== Simulation Result Queue is EMPTY =========");
        //`else 
        `uvm_info(get_type_name(),"======== Simulation Result Associate Array is EMPTY =========",UVM_LOW);
        //`endif
    end
    //empty all queues
    flush_slave_addr();
    flush_sim_result();
    //
    //`ifdef PRINT_TO_SUM_FILE
	//$fdisplay(sim_summary_file,"===================================================");
    //`else
    `uvm_info(get_type_name(),"===================================================",UVM_LOW);
    //`endif
endfunction
//-------------------------------------------------
//-- final_phase() function
//---------------------------------------------------
virtual function void final_phase(uvm_phase phase);
    id_of_burst id;
    resp_name expected_bresp, actual_bresp;
    resp_q expected_tmp_q, actual_tmp_q;
    int pass_cnt;
    int fail_cnt;
    //`ifdef PRINT_TO_SUM_FILE
	//$fdisplay(sim_summary_file,"================== BCHANNEL REPORT =================");
    //`else 
    `uvm_info(get_type_name(),"================== BCHANNEL REPORT =================", UVM_LOW);
    //`endif 

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
			//`ifdef PRINT_TO_SUM_FILE
				//$fdisplay(sim_summary_file,
				//$sformatf("[COMPARE_BCHANNEL]: actual_bid=%0d---expected_bid=%0d", id, id));
				////
				//if(actual_bresp == expected_bresp) begin
				//$fdisplay(sim_summary_file,
				//$sformatf("[----------------]: actual_bresp=%s MATCH expected_bresp=%s",
			       	//actual_bresp.name(), expected_bresp.name())); 
				//end
				//else begin
				//$fdisplay(sim_summary_file,
				//$sformatf("[----------------]: actual_bresp=%s MISMATCH expected_bresp=%s",
			       	//actual_bresp.name(), expected_bresp.name())); 
				//end
		    	//`else 
				`uvm_info(get_type_name(),
				$sformatf("[COMPARE_BCHANNEL]: actual_bid=%0d---expected_bid=%0d", id, id), UVM_LOW);
				//
				if(actual_bresp == expected_bresp) begin
				`uvm_info(get_type_name(),
				$sformatf("[----------------][PASS]: actual_bresp=%s___expected_bresp=%s",
			       	actual_bresp.name(), expected_bresp.name()), UVM_LOW); 
				pass_cnt++;
				end
				else begin
				`uvm_info(get_type_name(),
				$sformatf("[----------------][FAIL]: actual_bresp=%s___expected_bresp=%s",
			       	actual_bresp.name(), expected_bresp.name()), UVM_LOW); 
				fail_cnt++;
				end
			//`endif
				actual_bresp = resp_name'(2'b00);
				expected_bresp = resp_name'(2'b00);
			end
		end
		else begin
		    //`ifdef PRINT_TO_SUM_FILE
			//$fdisplay(sim_summary_file,$sformatf("id = %0d does not appear in actual array", id));
		    //`else 
		    `uvm_info(get_type_name(),$sformatf("id = %0d does not appear in actual array", id), UVM_LOW);
		    //`endif 
		end
	end//end of existence
	id++;
	end//end of for	
    end
    else begin
	    if(expected_bresp_array.num() == 0) begin
		    `uvm_info(get_type_name(),"EMPTY expected_bresp_array", UVM_LOW);
	    end
	    if(actual_bresp_array.num() == 0) begin
		    `uvm_info(get_type_name(),"EMPTY actual_bresp_array", UVM_LOW);
	    end
    end
    flush_resp();
    //
    //`ifdef PRINT_TO_SUM_FILE
    //$fdisplay(sim_summary_file,"=======================================================");
	//$fclose(sim_summary_file);
    //`else
    `uvm_info(get_type_name(), $sformatf("RESP CHECK: %0d(PASS)___%0d(FAIL)", pass_cnt, fail_cnt), UVM_LOW)
    `uvm_info(get_type_name(),"=======================================================", UVM_LOW);
    //`endif 
endfunction
endclass

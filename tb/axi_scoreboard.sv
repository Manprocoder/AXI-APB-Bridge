//===========================================================================
//--Project: AXI_TO_APB IP
//--File: axi_scoreboard.sv
//--Author: Nguyen Ngoc Man
//--Description: this class is used for AXI protocol 
//===========================================================================
//declare all functions that relate to ports of Monitor
//
typedef logic [07:0] id_of_burst;
typedef logic [15:0] slv_idx;
typedef axi_data_item data_q[$]; 
typedef resp_name resp_q[$]; //write response
typedef result_info result_q[$];
typedef axi_req_item req_q [$];
//
virtual class axi_scoreboard extends uvm_scoreboard;
    //register UVM factory
    `uvm_component_utils(axi_scoreboard)
    //===============================================
    //-----------------Data members
    //===============================================
    protected axi_req_item raw_req; //raw information of request
    protected parsed_req_info parsed_req;//contains parsed request
    protected int fail_of_each_id, pass_of_each_id; //contains result of comparision of each AXI ID
    protected bit last_beat;
    //-------checkers to track missing AXI transactions
    //--AXI transactions are not handled during SIMULATION time
    protected int rd_missing_trans, wr_missing_trans;
    //
    protected int valid_trans, dec_err_trans, slv_err_trans;
    //
    protected int total_pass, total_fail;
    protected logic [31:0] apb_base_end_addr_q [$];
    protected logic [31:0] axi_addr_q[$]; //axi transfer address queue
    //handle in long wait (hang infinite loop)
    protected int axi_data_wait_cnt; //avoid waiting infinite loop with axi_rdata_arr OR axi_wdata_q
    //array to store request info 
    protected req_q rd_req_q;//rd_req_q [slv_idx];
    protected req_q wr_req_q; //wr_req_q [slv_idx];
    //----store data
    protected axi_data_item axi_wdata_q [$];
    protected data_q axi_rdata_arr [id_of_burst]; //each id_of_burst maps to an individual queue
    //bresp associative array
    protected resp_q actual_bresp_array [id_of_burst];
    protected resp_q expected_bresp_array [id_of_burst];
    //--APB slaves
    slv_idx apb_slv_idx;
    //
    //store result of simulation comparison and print all in report_phase function
    //
    protected result_q sim_result_arr [id_of_burst];

    function new(string name ="axi_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction
    //
    pure virtual function void build_phase(uvm_phase phase);
    pure virtual task run_phase(uvm_phase phase);
    //============================================================
    //-----------------------METHODs
    //============================================================
extern virtual function void flush_req_q();
extern virtual function void flush_data();
extern virtual function void flush_resp();
extern virtual function void flush_sim_result();
extern virtual function void init_slave_addr(input int no_addr, input logic [31:0] start_addr, input logic [31:0] page_size);
extern virtual function void display_slv_base_end_addr_q();
extern virtual function void flush_axi_addr_q();
extern virtual function void flush_slave_addr();
extern virtual function void clear_signals_for_each_trans();
extern virtual function void init_type_of_trans_checker();
extern virtual function void display_type_of_trans_checker();
extern virtual function void display_slv_index();
extern virtual function void init_total_checker();
extern virtual function void display_total_checker();
extern virtual function void calculate_and_store_addr();
extern virtual function void parse_request();
extern virtual function logic [31:0] calculate_next_addr(input int i);
extern virtual function void store_simulation_result(input resp_name status);
extern virtual function void display_sim_res();
extern virtual function void Store_Expected_Bresp(input resp_name rsp);
extern virtual function void display_rsp_report();
//===========================================================================
//--------------------------------END of METHODs
//===========================================================================
endclass
//===========================================================================
//------------------IMPLEMENTATION of METHODs
//===========================================================================
//
function void axi_scoreboard::flush_req_q();
	rd_req_q.delete();
	wr_req_q.delete();
endfunction
//
function void axi_scoreboard::flush_data();
	axi_wdata_q.delete();
	axi_rdata_arr.delete();
endfunction
//
function void axi_scoreboard::flush_resp();
    actual_bresp_array.delete();
    expected_bresp_array.delete();
endfunction
//
function void axi_scoreboard::flush_sim_result();
	sim_result_arr.delete();
endfunction
//
//queue to store base and end address of supported APB SLAVES
function void axi_scoreboard::init_slave_addr(input int no_addr, input logic [31:0] start_addr, input logic [31:0] page_size);
    logic [31:0] axi_addr, end_addr;
    //
    //init_slave_addr(APB_BASE_END_ADDR_QUEUE_WIDTH, 32'h0000_0000, 32'h0000_0FFF);
    begin
        for (int i = 0; i < no_addr; i++) begin
            axi_addr = start_addr + {20'd0 + i, 12'd0};
            end_addr  = axi_addr + page_size; //32'h0000_0FFF;
            apb_base_end_addr_q.push_back(axi_addr);
            apb_base_end_addr_q.push_back(end_addr);
        end
    end
endfunction
//
function void axi_scoreboard::display_slv_base_end_addr_q();
    `uvm_info(get_name(), "BASE_END APB ADDR AS FOLLOWS:", UVM_LOW)
    //
    foreach(apb_base_end_addr_q[i]) begin
        `uvm_info(get_name(), $sformatf("apb_addr[%0d] = 0x%8h", i, apb_base_end_addr_q[i]), UVM_LOW)
    end
endfunction
//
function void axi_scoreboard::flush_axi_addr_q;
	axi_addr_q.delete();
endfunction
//
function void axi_scoreboard::flush_slave_addr;
	apb_base_end_addr_q.delete();
endfunction
//
//
function void axi_scoreboard::clear_signals_for_each_trans;
begin
    pass_of_each_id = 0; 
    fail_of_each_id = 0; 
	last_beat = 1'b0;
	axi_data_wait_cnt = 0;
end
endfunction
//
function void axi_scoreboard::init_type_of_trans_checker;
begin
    rd_missing_trans = 0;
    wr_missing_trans = 0;
    valid_trans = 0;
    dec_err_trans = 0;
    slv_err_trans = 0;
end
endfunction
//
//
function void axi_scoreboard::display_type_of_trans_checker();
	`uvm_info(get_name(), $sformatf("RD_MISSING_TRANS: %0d", rd_missing_trans), UVM_LOW)
	`uvm_info(get_name(), $sformatf("WR_MISSING_TRANS: %0d", wr_missing_trans), UVM_LOW)
	`uvm_info(get_name(), $sformatf("_____VALID_TRANS: %0d", valid_trans), UVM_LOW)
	`uvm_info(get_name(), $sformatf("___SLV_ERR_TRANS: %0d", slv_err_trans), UVM_LOW)
	`uvm_info(get_name(), $sformatf("___DEC_ERR_TRANS: %0d", dec_err_trans), UVM_LOW)
endfunction
//
function void axi_scoreboard::display_slv_index();
	`uvm_info(get_name(), $sformatf("Current APB SLAVE: 0x%4h", apb_slv_idx), UVM_LOW)
endfunction
//
function void axi_scoreboard::init_total_checker();
	total_pass = 0;
	total_fail = 0;
    `uvm_info(get_name(), "Initialization of total checker DONE ", UVM_LOW)
endfunction
//
function void axi_scoreboard::display_total_checker();
	`uvm_info(get_type_name, $sformatf("TOTAL PASS: %0d___TOTAL FAIL: %0d", total_pass, total_fail), UVM_LOW)
endfunction
//
//---------------------------------AXI_ADDR_CALCULATION FUNCTION---------------------
//
function void axi_scoreboard::calculate_and_store_addr();
logic [31:0] addr_of_beat;
//
begin
            parse_request();
	    //
	    axi_addr_q = {};
	    for(int i = 0; i < (raw_req.len + 1'b1); i++) begin
		    addr_of_beat = 0;
		    addr_of_beat = calculate_next_addr(i); 
		    axi_addr_q.push_back(addr_of_beat);
	    end

end
endfunction
//
//
function void axi_scoreboard::parse_request;
  begin
    parsed_req.start_address = raw_req.addr;
    //---------------------------------------------------
    // pre-calculate address detail
    //---------------------------------------------------
    parsed_req.bytes_in_transfer = 2**raw_req.size;
    //incr addr
    parsed_req.total_bytes = parsed_req.bytes_in_transfer * (raw_req.len + 1'b1);    
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
function logic [31:0] axi_scoreboard::calculate_next_addr(input int i);
    logic [31:0] next_address;
	//
    begin
        if(raw_req.burst == 2'b00)begin  //fixed
            next_address = parsed_req.start_address;
        end
        else if (raw_req.burst == 2'b01) begin //incr
            if(i==0) begin
                next_address = parsed_req.start_address;
            end
            else 
                next_address = parsed_req.aligned_address + i * parsed_req.bytes_in_transfer;
        end
        else if (raw_req.burst == 2'b10) begin //wrap
            next_address = parsed_req.aligned_address + i * parsed_req.bytes_in_transfer;
            if(next_address == parsed_req.wrap_highest_address) begin
                next_address = parsed_req.wrap_boundary;
            end
            else if(next_address > parsed_req.wrap_highest_address) begin
                next_address = parsed_req.wrap_boundary + (next_address - parsed_req.wrap_highest_address); 
            end
            else begin
                next_address = next_address;
            end   
        end //wrap
        //recalculate address 
        next_address = (i!=0) ? {next_address[31:2], 2'b00} : next_address;
        //
        return next_address;
    end
endfunction
    //
    //
function void axi_scoreboard::store_simulation_result(input resp_name status);
    result_info Transaction_result;
    result_q tmp_q; 
    //
    begin
	Transaction_result.wr_or_rd = raw_req.wr_or_rd;
        Transaction_result.id = raw_req.id;
        Transaction_result.address = raw_req.addr;
        Transaction_result.len = raw_req.len;
        Transaction_result.size = raw_req.size;
        Transaction_result.burst = raw_req.burst;
        Transaction_result.resp = status;
        Transaction_result.case_matches = pass_of_each_id;
        Transaction_result.case_mismatches = fail_of_each_id;
	//
        tmp_q = {};
            //
        if(sim_result_arr.exists(raw_req.id[7:0])) begin
            tmp_q = sim_result_arr[raw_req.id[7:0]];
            tmp_q.push_back(Transaction_result);
            sim_result_arr[raw_req.id[7:0]] = tmp_q;
            `uvm_info(get_type_name(), 
            $sformatf("[EXISTING]Store SIM RESULT of [%s][%0d(ID)]",
                raw_req.wr_or_rd ? "WRITE" : "READ_", raw_req.id[7:0]), UVM_MEDIUM)
        end
        else begin
            tmp_q.push_back(Transaction_result);
            sim_result_arr[raw_req.id[7:0]] = tmp_q;
            `uvm_info(get_type_name(), 
            $sformatf("[NEW]Store SIM RESULT of [%s][%0d(ID)]", 
            raw_req.wr_or_rd ? "WRITE" : "READ_", raw_req.id[7:0]), UVM_MEDIUM)
        end
	//
	clear_signals_for_each_trans();
    end
    //
endfunction
//
function void axi_scoreboard::display_sim_res();
    //declare local-function variables
    string rw_type;
    string burst_str;
    string resp_str;
    id_of_burst arr_idx;
    result_q sim_result_q;
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
		    rw_type   = (sim_result_q[i].wr_or_rd) ? "WRITE" : "READ_";
		    burst_str = sim_result_q[i].burst.name(); 
		    resp_str = sim_result_q[i].resp.name(); 
		    // print transaction detail
    //`uvm_info(get_name(),
    //$sformatf("\nTRANS[%0d] %s:Addr=0x%04h_%04h Len_1=%0d Size=%0d(bytes_in_beat) Burst=%s Resp=%s | PASS=%0d, FAIL=%0d",
    $display("TRANS[%0d] %s:Addr=0x%04h_%04h Len_1=%0d Size=%0d(bytes_in_beat) Burst=%s Resp=%s | PASS=%0d, FAIL=%0d",
			sim_result_q[i].id[7:0],
			rw_type,
			sim_result_q[i].address[31:16],
			sim_result_q[i].address[15:0],
			sim_result_q[i].len + 1,
			2**sim_result_q[i].size,
			burst_str,
			resp_str,
			sim_result_q[i].case_matches,
			sim_result_q[i].case_mismatches);
			//sim_result_q[i].case_mismatches), UVM_LOW);
			end//end of foreach
		end//end of if arr_idx
	end
	end//end of if sim_result_arr.size() > 0
    else begin
        `uvm_info(get_name(),"======== Simulation Result Associate Array is EMPTY =========",UVM_LOW);
    end
    //
    `uvm_info(get_name(),"===================================================",UVM_LOW);
endfunction
//
function void axi_scoreboard::Store_Expected_Bresp(input resp_name rsp);
//
resp_q expected_bresp_q = {};
begin
   if(expected_bresp_array.exists(raw_req.id)) begin
	   expected_bresp_q = expected_bresp_array[raw_req.id];
	   expected_bresp_q.push_back(rsp);
	   expected_bresp_array[raw_req.id] = expected_bresp_q;
   end
   else begin
	   expected_bresp_q.push_back(rsp);
	   expected_bresp_array[raw_req.id] = expected_bresp_q;
   end	   
end
endfunction

//
function void axi_scoreboard::display_rsp_report();
    resp_name expected_bresp, actual_bresp;
    resp_q expected_tmp_q, actual_tmp_q;
    int pass_cnt = 0;
    int fail_cnt = 0;
    id_of_burst id;
    `uvm_info(get_type_name(),"================== BCHANNEL REPORT =================", UVM_LOW);

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
				`uvm_info(get_name(),
				$sformatf("[BCHANNEL]: actual_bid=%0d---expected_bid=%0d", id, id), UVM_LOW);
				//
				if(actual_bresp == expected_bresp) begin
				`uvm_info(get_name(),
				$sformatf("[--------][PASS]: actual_bresp=%s___expected_bresp=%s",
			       	actual_bresp.name(), expected_bresp.name()), UVM_LOW); 
				pass_cnt++;
				end
				else begin
				`uvm_info(get_name(),
				$sformatf("[--------][FAIL]: actual_bresp=%s___expected_bresp=%s",
			       	actual_bresp.name(), expected_bresp.name()), UVM_LOW); 
				fail_cnt++;
				end
				actual_bresp = resp_name'(2'b00);
				expected_bresp = resp_name'(2'b00);
			end
		end
		else begin
		    `uvm_info(get_type_name(),$sformatf("id = %0d does not appear in actual array", id), UVM_LOW);
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
    //
    `uvm_info(get_type_name(), $sformatf("WRITE_RSP CHECK: %0d(PASS)___%0d(FAIL)", pass_cnt, fail_cnt), UVM_LOW)
endfunction

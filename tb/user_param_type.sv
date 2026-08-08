///===========================================================================
//--Project: AXI_TO_APB IP
//--File: type_param_pkg.sv
//--Author: Nguyen Ngoc Man
//--Description: those informations are used in scoreboard class 
//===========================================================================
    import axi_pkg::*;
    import apb_pkg::*;
//
//
//
    parameter int APB_BASE_END_ADDR_QUEUE_WIDTH = 8;
    parameter TIME_OUT_BOUNDARY = 100;
    parameter AXI_REQ_TIMEOUT = 5*(10**7);
    parameter APB_TIMEOUT = 5*(10**9);
    parameter logic [31:0] START_ADDR = 32'h0000_0000;
    //
    //
   typedef struct packed {
        logic [31:0] start_address;
        logic [7:0]  bytes_in_transfer;
        logic [16:0] total_bytes;
        logic [31:0] aligned_address;
        logic [31:0] wrap_boundary;
        logic [31:0] wrap_highest_address;
    } parsed_req_info;
    //
    //  
    typedef struct packed{
	logic wr_or_rd;
        logic [7:0] id; 
        logic [31:0] address;
        logic [7:0] len;
        logic [2:0] size;
        burst_name burst;
        resp_name resp;
        int case_matches;
        int case_mismatches;
    //
    } result_info;

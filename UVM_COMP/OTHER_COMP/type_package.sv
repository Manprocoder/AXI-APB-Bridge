//
//
//
package type_package;
    //
    parameter APB_BASE_END_ADDR_QUEUE_WIDTH = 8;
    parameter TIME_OUT_BOUNDARY = 100;
    parameter APB_TIMEOUT = 5000;
    parameter logic [31:0] START_ADDR = 32'h0000_0000;
    //
    typedef enum bit [1:0] {FIXED, INCR, WRAP, RESERVED} burst_name;
    typedef enum logic [1:0] {OKAY, NO_USE, PSLVERR, DECERR} resp_name;
    burst_name burst_pattern [] = '{FIXED, INCR, WRAP};
    //
    typedef struct packed{
        logic [8:0] id;
        logic [31:0] address;
        logic [7:0] len;
        logic [2:0] size;
        burst_name burst;
    //
   } req_info;
   //
   typedef struct packed {
	logic [8:0] id; //[8]=1: wr/ 0: rd
        logic [2:0] size;
        logic [7:0]  len;
        burst_name  burst;
        logic [31:0] start_address;
        logic [7:0]  bytes_in_transfer;
        logic [15:0] total_bytes;
        logic [31:0] aligned_address;
        logic [31:0] wrap_boundary;
        logic [31:0] wrap_highest_address;
    } parsed_req_info;
    //
    //  
    typedef struct packed{
        logic [8:0] id; //[8] 0:RD/1:WR
        logic [31:0] address;
        logic [7:0] len;
        logic [2:0] size;
        burst_name burst;
        resp_name resp;
        int case_matches;
        int case_mismatches;
    //
    } result_info;
    //
    //coverage 
    //
    //typedef struct {
        //logic [3:0] be [];
        //logic [31:0] data [];
        //logic last [];
    //} w_channel_info;
    ////
    //typedef struct {
        //logic [31:0] data [];
        //logic [7:0] rid [];
        //resp_name rresp [];
        //logic last [];
    //} r_channel_info;
    //
    typedef struct packed{
        logic [7:0] bid; 
        resp_name bresp;
    } b_channel_info;
endpackage

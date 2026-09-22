//==========================================================================
//Project: AXI to APB IP
//Author: Nguyen Ngoc Man
//--File: test_pkg.sv
//--Description: 
//==========================================================================
package test_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	`include "base_test.sv"
	`include "random_test.sv"
    `include "addr_first_wdata_then_test.sv"
    `include "addr_wdata_parallel_test.sv"
    `include "wdata_first_addr_then_test.sv"
endpackage

//===========================================================================
//--Project: Design and Verify AXI_TO_APB IP
//===========================================================================
//--File: seq_pkg.sv
//--Author: Nguyen Ngoc Man
//===========================================================================
//--Description: AXI, APB sequences for verification 
//===========================================================================
package seq_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	`include "./base_vseq.sv"
	`include "./stimulus_generator.sv"
	`include "./common_sequence.sv"
	`include "./reset_sequence.sv"
    `include "./unsupported_size_seq.sv"
    `include "./disallowed_addr_seq.sv"
    `include "./dec_err_seq.sv"
    `include "./unaligned_addr_seq.sv"
    `include "./rdata_almost_full_seq.sv"
	`include "./virtual_seq.sv"
endpackage

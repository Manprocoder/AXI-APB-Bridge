//===========================================================================
//--Project: AXI_TO_APB IP
//--File: seq_pkg.sv
//--Author: Nguyen Ngoc Man
//--Description: AXI, APB sequences for verification 
//===========================================================================
package seq_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	`include "./base_vseq.sv"
	`include "./common_sequence.sv"
	`include "./reset_sequence.sv"
	`include "./virtual_seq.sv"
endpackage

//===============================================================-----------------------------------------------------------
//--Project: AXI_2_APB IP
//--Author: Nguyen Ngoc Man
//--File: env_pkg.sv
//--Description: this package includes config object, scoreboard and shared_item (common signal between AXI and APB
//===============================================================-----------------------------------------------------------
package env_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	`include "user_param_type.sv"
	`include "env_cfg.sv"
	`include "shared_item.sv"
	`include "axi_apb_scoreboard.sv"
	`include "env.sv"
endpackage

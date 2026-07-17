//===========================================================================
//--Project: AXI to APB IP
//--File: env_cfg.sv
//--Author: Nguyen Ngoc Man
//--Description: ENV configuration object
//===========================================================================
class env_config extends uvm_object;
	//
    `uvm_object_utils(env_config)
	//
	bit scb;
	bit fc;
	//
	function new(string name = "env_config");
		super.new();
	endfunction
endclass

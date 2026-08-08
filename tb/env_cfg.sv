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
	int no_apb_agt = `SLAVE_CNT;
	//
	function new(string name = "env_config");
		super.new(name);
	endfunction
endclass

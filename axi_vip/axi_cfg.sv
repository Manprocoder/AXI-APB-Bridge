//==========================================================
//--Project: AXI to APB IP
//--File: axi_cfg.sv
//--Author: Nguyen Ngoc Man
//--Description: AXI configuration object
//===========================================================================
class axi_agent_config extends uvm_object;
	//register factory to use type_id::create() method
    `uvm_object_utils(axi_agent_config)
	//
	virtual interface axi_intf #(DW1,AW1) vif;
	uvm_active_passive_enum active = UVM_ACTIVE;
	bit scb;
  	bit fc;
	//
	function new(string name = "axi_agent_config");
		super.new(name);
	endfunction
endclass


//
//
//
//(1) axi_config
class axi_agent_config extends uvm_object;
	//register factory to use type_id::create() method
    `uvm_object_utils(axi_agent_config)
	//
	virtual interface axi_intf #(DW,AW1) axi_vif;
	uvm_active_passive_enum active = UVM_ACTIVE;
	//
	function new(string name = "axi_agent_config");
		super.new();
	endfunction
endclass
//(2) apb_config
class apb_agent_config extends uvm_object;
//register factory to use type_id::create() method
    `uvm_object_utils(apb_agent_config)
    //
	virtual interface apb_intf #(DW,AW2) apb_vif;
	uvm_active_passive_enum active = UVM_PASSIVE;
	//
	function new(string name = "apb_agent_config");
		super.new();
	endfunction
endclass
//(3) env_config
class env_config extends uvm_object;
	//
    `uvm_object_utils(env_config)
	//
	bit scoreboard = 1;
	axi_agent_config axi_agt_cfg;
	apb_agent_config apb_agt_cfg;
	//
	function new(string name = "env_config");
		super.new();
	endfunction
endclass

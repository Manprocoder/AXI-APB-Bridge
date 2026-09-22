//===========================================================================
//--Project: AXI to APB IP
//--File: apb_cfg.sv
//--Author: Nguyen Ngoc Man
//--Description: APB configuration object
//===========================================================================
class apb_agent_config extends uvm_object;
//register factory to use type_id::create() method
    `uvm_object_utils(apb_agent_config)
    //
	virtual interface apb_intf #(DW2, AW2, `SLAVE_CNT) vif;
	uvm_active_passive_enum active = UVM_ACTIVE;
    bit mst_role;
    int slv_order; //APB slaves could be multiple ones in environment
	bit scoreboard;
	bit functional_coverage;
	//
	function new(string name = "apb_agent_config");
		super.new();
	endfunction
endclass


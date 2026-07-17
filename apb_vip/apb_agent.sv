//===========================================================================
//--Project: AXI_TO_APB IP
//--File: apb_agent.sv
//--Author: Nguyen Ngoc Man
//--Description: APB agent 
//===========================================================================
class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)
    //
    apb_driver apb_drv_h;
    apb_monitor apb_mon_h;
    ApbSequencer s_seqr0;
    //
    apb_agent_config apb_cfg_h;
    //
    function new(string name="APB Agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
   
endclass

//
function void apb_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    //
    if(!uvm_config_db #(apb_agent_config)::get(this,"", "apb_cfg", apb_cfg_h))begin
        `uvm_fatal(get_type_name(), "apb_agent_config is not found!!!")
    end
    //
    apb_mon_h = apb_monitor::type_id::create("apb_mon_h", this);
    apb_drv_h = apb_driver::type_id::create("apb_drv_h", this);
    //
    //if(apb_cfg_h.active == UVM_ACTIVE) begin
        //apb_drv_h = apb_driver::type_id::create("apb_drv_h", this);
        s_seqr0 = ApbSequencer::type_id::create("s_seqr0", this);
    //end
    //
    apb_drv_h.drv_cfg = apb_cfg_h; // assign config object
    apb_mon_h.mon_cfg = apb_cfg_h; // assign config object
endfunction

function void apb_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
        apb_drv_h.seq_item_port.connect(s_seqr0.seq_item_export);
endfunction

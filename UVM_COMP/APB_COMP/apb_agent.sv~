//-------------------------------------------------------------
//-- file: apb_slave.sv
//-- class: apb_slave
//-------------------------------------------------------------
class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)
    //
    apb_driver apb_driver0;
    apb_monitor apb_monitor0;
    ApbSequencer s_seqr0;
    //
    env_config env_cfg_inst;
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
    if(!uvm_config_db #(env_config)::get(this,"", "env_cfg", env_cfg_inst))begin
        `uvm_fatal(get_type_name(), "env_cfg is not found!!!")
    end
    //
    apb_monitor0 = apb_monitor::type_id::create("apb_monitor0", this);
    apb_driver0 = apb_driver::type_id::create("apb_driver0", this);
    //
    //if(agent_cfg.active == UVM_ACTIVE) begin
        //apb_driver0 = apb_driver::type_id::create("apb_driver0", this);
        s_seqr0 = ApbSequencer::type_id::create("s_seqr0", this);
    //end
    //
    apb_driver0.apb_drv_vif  = env_cfg_inst.apb_agt_cfg.apb_vif;
    apb_monitor0.apb_mon_vif = env_cfg_inst.apb_agt_cfg.apb_vif;
    apb_driver0.drv_cfg = env_cfg_inst.apb_agt_cfg; // assign config object
endfunction

function void apb_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
        apb_driver0.seq_item_port.connect(s_seqr0.seq_item_export);
endfunction

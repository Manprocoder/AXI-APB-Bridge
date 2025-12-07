//===================================
//--file: axi_agent.sv
//--function: AXI UVM agent
//--Author: Nguyen Ngoc Man
//-----------------------------------
import type_package::*; //req_info
//import in class scope -> illegal
class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)
    //handles
    AxiMasterDriver m_driver0;
    WriteSequencer w_seqr0;
    ReadSequencer r_seqr0;
    ResetSequencer rst_seqr;
    AxiMasterMonitor m_monitor0;
    //config
    env_config env_cfg_inst;
    //constructor
    function new(string name = "axi_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);

endclass

function void axi_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    //
    if(!uvm_config_db #(env_config)::get(this,"", "env_cfg", env_cfg_inst))begin
        `uvm_fatal(get_type_name(), "env_cfg object is not found!!!")
    end
        m_driver0 = AxiMasterDriver::type_id::create("m_driver0", this);
        w_seqr0   = WriteSequencer::type_id::create("w_seqr0", this);
        r_seqr0   = ReadSequencer::type_id::create("r_seqr0", this);
    //
    if (env_cfg_inst.axi_agt_cfg.active == UVM_ACTIVE) begin
        rst_seqr  = ResetSequencer::type_id::create("rst_seqr", this);
    end

    m_monitor0 = AxiMasterMonitor::type_id::create("m_monitor0", this);
    //
    m_driver0.drv_cfg = env_cfg_inst;
    m_monitor0.mon_cfg = env_cfg_inst;
    //
    //assign driver, monitor, and sequencer(as needed) interfaces
    m_driver0.m_drv_vif  = env_cfg_inst.axi_agt_cfg.axi_vif;
    m_monitor0.m_mon_vif = env_cfg_inst.axi_agt_cfg.axi_vif;
    w_seqr0.axi_vif = env_cfg_inst.axi_agt_cfg.axi_vif;
    r_seqr0.axi_vif = env_cfg_inst.axi_agt_cfg.axi_vif;

endfunction

function void axi_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_driver0.seq_item_port.connect(w_seqr0.seq_item_export);
    m_driver0.seq_item_port2.connect(r_seqr0.seq_item_export);
    //
    if (env_cfg_inst.axi_agt_cfg.active == UVM_ACTIVE) begin
        m_driver0.seq_item_port3.connect(rst_seqr.seq_item_export);
    end
    //
endfunction



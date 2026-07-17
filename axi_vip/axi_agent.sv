//======================================================
//--Project: AXI to APB IP
//--file: axi_agent.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//======================================================
class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)
    //handles
    AxiMasterDriver m_drv_h;
    WriteSequencer w_seqr0;
    ReadSequencer r_seqr0;
    ResetSequencer rst_seqr;
    AxiMasterMonitor m_mon_h;
    //config
    axi_agent_config axi_cfg_h;
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
    if(!uvm_config_db #(axi_agent_config)::get(this,"", "axi_cfg", axi_cfg_h))begin
        `uvm_fatal(get_type_name(), "axi_cfg object is not found!!!")
    end
        m_drv_h = AxiMasterDriver::type_id::create("m_drv_h", this);
        w_seqr0   = WriteSequencer::type_id::create("w_seqr0", this);
        r_seqr0   = ReadSequencer::type_id::create("r_seqr0", this);
    //
    if (axi_cfg_h.active == UVM_ACTIVE) begin
        rst_seqr  = ResetSequencer::type_id::create("rst_seqr", this);
    end
    //
    m_mon_h = AxiMasterMonitor::type_id::create("m_mon_h", this);
    //
    m_drv_h.drv_cfg = axi_cfg_h;
    m_mon_h.mon_cfg = axi_cfg_h;
    //
    //assign driver, monitor, and sequencer(as needed) interfaces
    w_seqr0.axi_vif = axi_cfg_h.vif;
    r_seqr0.axi_vif = axi_cfg_h.vif;

endfunction

function void axi_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_drv_h.seq_item_port.connect(w_seqr0.seq_item_export);
    m_drv_h.seq_item_port2.connect(r_seqr0.seq_item_export);
    //
    if (axi_cfg_h.active == UVM_ACTIVE) begin
        m_drv_h.seq_item_port3.connect(rst_seqr.seq_item_export);
    end
    //
endfunction



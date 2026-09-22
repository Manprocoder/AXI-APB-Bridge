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
    WriteSequencer w_seqr_h;
    ReadSequencer r_seqr_h;
    ResetSequencer rst_seqr;
    AxiMasterMonitor m_mon_h;
    //config
    axi_agent_config axi_cfg_h;
    int no_test;
    string str_from_test;
    //constructor
    function new(string name = "axi_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern function void end_of_elaboration_phase(uvm_phase phase);

endclass

function void axi_agent::build_phase(uvm_phase phase);
    `uvm_info("BUILD_PHASE OF AGENT", "HELLO AXI AGENT", UVM_LOW)
    
    super.build_phase(phase);
    //
    if(!uvm_config_db #(axi_agent_config)::get(this,"", "axi_cfg", axi_cfg_h))begin
        `uvm_fatal(get_type_name(), "axi_cfg object is not found!!!")
    end
        m_drv_h = AxiMasterDriver::type_id::create("m_drv_h", this);
        w_seqr_h   = WriteSequencer::type_id::create("w_seqr_h", this);
        r_seqr_h   = ReadSequencer::type_id::create("r_seqr_h", this);
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
    w_seqr_h.axi_vif = axi_cfg_h.vif;
    r_seqr_h.axi_vif = axi_cfg_h.vif;
    //
    //
    if(!uvm_config_db#(int)::get(this, "", "NO_TEST", no_test)) begin
      `uvm_fatal(get_name(), "Didn't found no_test variable!!!")
    end 
    else begin
        `uvm_info(get_name(), $sformatf("[AXI_AGENT]no_test = %0d", no_test), UVM_LOW)
    end
    //
    //-------------------------ONLY FOR TRIAL
    //
    if(!uvm_config_db#(string)::get(this, "", "TRIAL", str_from_test)) begin
      `uvm_fatal(get_name(), "Didn't found string from random test!!!")
    end 
    else begin
        `uvm_info(get_name(), $sformatf("[AXI_AGENT]str_from_test = %0s", str_from_test), UVM_LOW)
    end

endfunction

function void axi_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_drv_h.seq_item_port.connect(w_seqr_h.seq_item_export);
    m_drv_h.seq_item_port2.connect(r_seqr_h.seq_item_export);
    //
    if (axi_cfg_h.active == UVM_ACTIVE) begin
        m_drv_h.seq_item_port3.connect(rst_seqr.seq_item_export);
    end
    //
endfunction
//
function void axi_agent::end_of_elaboration_phase(uvm_phase phase);
    `uvm_info(get_name(), "[end_of_elaboration_phase UVM_AXI_AGENT]", UVM_LOW)
    uvm_top.print_topology();
endfunction


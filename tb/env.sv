//===========================================================================
//--Project: AXI_TO_APB IP
//--File: env.sv
//--Author: Nguyen Ngoc Man
//--Description: AXI_TO_APB environment
//===========================================================================
class m_env extends uvm_env;
    `uvm_component_utils(m_env)

    axi_agent axi_mst_agt;
    apb_agent apb_slv_agt;
    axi_apb_scoreboard m_sb;
    //------------------------------------------
    //----INTERFACE handles
    //-----------------------------------------
    virtual interface axi_intf #(DW1, AW1) t_axi_vif;
    virtual interface apb_intf #(DW2, AW2) t_apb_vif; // it is assigned from APB AGENT class
    //------------------------------------------
    //configuration objects
    //-----------------------------------------
    env_config env_cfg;
    axi_agent_config m_cfg;
    apb_agent_config s_cfg;
    //
    //methods
    //
    extern function new(string name = "m_env", uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);

endclass
//======================================================================================
//--------------------------IMPLEMENTATION of all METHODs
//======================================================================================
function m_env::new(string name = "m_env", uvm_component parent);
    super.new(name, parent);
endfunction
//function 
function void m_env::build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_mst_agt = axi_agent::type_id::create("axi_mst_agt", this);
    apb_slv_agt = apb_agent::type_id::create("apb_slv_agt", this);
    //**************************************************************
    //--------------------------INTERFACE
    //**************************************************************
    if (!uvm_config_db#(virtual interface axi_intf #(DW1, AW1))::get(this, "", "m_vif", t_axi_vif)) begin
      `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface m_vif")
    end
    if (!uvm_config_db#(virtual interface apb_intf #(DW2, AW2))::get(this, "", "s_vif", t_apb_vif)) begin
      `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface s_vif")
    end
    //**************************************************************
    //--------------------------INSTANCES
    //**************************************************************
    m_cfg = axi_agent_config::type_id::create("m_cfg");   //axi agent config object
    s_cfg = apb_agent_config::type_id::create("s_cfg");   //apb agent config object
    env_cfg = env_config::type_id::create("env_cfg");   //environment config object
    //**************************************************************
    //--Pass vital information  
    //**************************************************************
    m_cfg.vif = t_axi_vif;
    s_cfg.vif = t_apb_vif;
    //**************************************************************
    //--store env_cfg into uvm_config_db to leverage reusability
    //**************************************************************
    uvm_config_db#(env_config)::set(this, "*", "env_cfg", env_cfg);
    uvm_config_db#(axi_agent_config)::set(this, "*", "axi_cfg", m_cfg);
    uvm_config_db#(apb_agent_config)::set(this, "*", "apb_cfg", s_cfg);
    //
    // 
    m_sb = axi_apb_scoreboard::type_id::create("m_sb", this);
    //
endfunction

//function
function void m_env::connect_phase(uvm_phase phase); 
    super.connect_phase(phase);
    //
        axi_mst_agt.m_mon_h.AxiResetn_toScoreBoard.connect(m_sb.aimp_Aresetn);           //ap_imp : analysis port implement
        axi_mst_agt.m_mon_h.AxiRdAddr_toScoreBoard.connect(m_sb.aimp_AxiRdRequest);           //ap_imp : analysis port implement
        axi_mst_agt.m_mon_h.AxiRData_toScoreBoard.connect(m_sb.aimp_AxiRData);           //ap_imp : analysis port implement
        axi_mst_agt.m_mon_h.AxiWrAddr_toScoreBoard.connect(m_sb.aimp_AxiWrRequest);           //ap_imp : analysis port implement
        axi_mst_agt.m_mon_h.AxiWData_toScoreBoard.connect(m_sb.aimp_AxiWData);           //ap_imp : analysis port implement
        axi_mst_agt.m_mon_h.AxiBresp_toScoreBoard.connect(m_sb.aimp_AxiBresp);           //ap_imp : analysis port implement
        apb_slv_agt.apb_mon_h.ApbContent_toScoreboard.connect(m_sb.aimp_ApbContent);    
        apb_slv_agt.apb_mon_h.presetn_toScoreboard.connect(m_sb.aimp_Presetn);    
        apb_slv_agt.apb_mon_h.pseltb_toScoreboard.connect(m_sb.aimp_Pseltb);    
endfunction

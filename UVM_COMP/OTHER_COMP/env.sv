//===========================================================================
//
//===========================================================================
class m_env extends uvm_env;
    `uvm_component_utils(m_env)

    axi_agent axi_mst_agt;
    apb_agent apb_slv_agt;
    scoreboard m_sb;
    env_config env_cfg;
    axi_agent_config axi_agent_cfg;
    apb_agent_config apb_agent_cfg;
    

    function new(string name = "m_env", uvm_component parent);
        super.new(name, parent);
    endfunction
    //
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);

endclass

//function 
function void m_env::build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi_mst_agt = axi_agent::type_id::create("axi_mst_agt", this);
    apb_slv_agt = apb_agent::type_id::create("apb_slv_agt", this);
    //
    if(!uvm_config_db #(env_config)::get(this, "", "env_cfg", env_cfg)) begin
        `uvm_fatal(get_full_name(), "env_cfg is not found in db");
    end
    // 
    m_sb = scoreboard::type_id::create("m_sb", this);
    //
endfunction

//function
function void m_env::connect_phase(uvm_phase phase); 
    super.connect_phase(phase);
    //
    if(env_cfg.scoreboard) begin
        axi_mst_agt.m_monitor0.AxiResetn_toScoreBoard.connect(m_sb.aimp_Aresetn);           //ap_imp : analysis port implement
        axi_mst_agt.m_monitor0.AxiRdAddr_toScoreBoard.connect(m_sb.aimp_AxiRdRequest);           //ap_imp : analysis port implement
        axi_mst_agt.m_monitor0.AxiRData_toScoreBoard.connect(m_sb.aimp_AxiRData);           //ap_imp : analysis port implement
        axi_mst_agt.m_monitor0.AxiWrAddr_toScoreBoard.connect(m_sb.aimp_AxiWrRequest);           //ap_imp : analysis port implement
        axi_mst_agt.m_monitor0.AxiWData_toScoreBoard.connect(m_sb.aimp_AxiWData);           //ap_imp : analysis port implement
        axi_mst_agt.m_monitor0.AxiBresp_toScoreBoard.connect(m_sb.aimp_AxiBresp);           //ap_imp : analysis port implement
        apb_slv_agt.apb_monitor0.ApbContent_toScoreboard.connect(m_sb.aimp_ApbContent);    
        apb_slv_agt.apb_monitor0.presetn_toScoreboard.connect(m_sb.aimp_Presetn);    
        apb_slv_agt.apb_monitor0.pseltb_toScoreboard.connect(m_sb.aimp_Pseltb);    

    end
endfunction

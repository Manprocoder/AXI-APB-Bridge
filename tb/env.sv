//===========================================================================
//--Project: AXI_TO_APB IP
//--File: env.sv
//--Author: Nguyen Ngoc Man
//--Description: AXI_TO_APB environment
//===========================================================================
class m_env extends uvm_env;
    `uvm_component_utils(m_env)
    //------------------------------------------
    //----------PARAMETERs
    //------------------------------------------
    localparam NO_SLAVE = 1;
    //
    axi_agent axi_mst_agt;
    apb_agent apb_slv_agt [];
    axi_apb_scoreboard m_sb;
    //------------------------------------------
    //----INTERFACE handles
    //-----------------------------------------
    virtual interface axi_intf #(DW1, AW1) axi_vif;
    virtual interface apb_intf #(DW2, AW2, NO_SLAVE) apb_vif [`SLAVE_CNT]; // it is assigned from APB AGENT class
    //------------------------------------------
    //configuration objects
    //-----------------------------------------
    env_config env_cfg_h;
    axi_agent_config m_cfg;
    apb_agent_config s_cfg[];
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
    //**************************************************************
    //-----------------------Get ENV handle
    //**************************************************************
    if (!uvm_config_db#(env_config)::get(this, "", "env_cfg", env_cfg_h)) begin
      `uvm_fatal(get_name(), "Didn't get ENV config handle!!!")
    end
    //**************************************************************
    //-----------------------Instantiate subcomponent
    //**************************************************************
    axi_mst_agt = axi_agent::type_id::create("axi_mst_agt", this);
    apb_slv_agt = new[env_cfg_h.no_apb_agt];
    //
    foreach(apb_slv_agt[i]) begin
        apb_slv_agt[i] = apb_agent::type_id::create($sformatf("apb_slv_agt_%0d", i), this);
    end
    //**************************************************************
    //--------------------------INTERFACE
    //**************************************************************
    if (!uvm_config_db#(virtual interface axi_intf #(DW1, AW1))::get(this, "", "m_vif", axi_vif)) begin
      `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface m_vif")
    end
    //
    //**************************************************************
    //--------------------ASSIGN VITAL INFORMATION
    //**************************************************************
    //--APB
    //
    s_cfg = new[env_cfg_h.no_apb_agt];
    //
    foreach(s_cfg[i]) begin
        if(!uvm_config_db#(virtual interface apb_intf #(DW2, AW2, NO_SLAVE))::get(this, "", $sformatf("apb_vif_%0d", i), apb_vif[i])) begin
          `uvm_fatal(get_type_name(), $sformatf("Didn't get handle to virtual interface apb_vif[%0d]", i))
        end
        //
        s_cfg[i] = apb_agent_config::type_id::create($sformatf("s_cfg_%0d", i));   //apb agent config object
        s_cfg[i].vif = apb_vif[i];
        uvm_config_db#(apb_agent_config)::set(this, $sformatf("apb_slv_agt_%0d*", i), "apb_cfg", s_cfg[i]);
    end
    //---AXI 
    //
    m_cfg = axi_agent_config::type_id::create("m_cfg");   //axi agent config object
    m_cfg.vif = axi_vif;
    uvm_config_db#(axi_agent_config)::set(this, "*", "axi_cfg", m_cfg);
    //
    m_sb = axi_apb_scoreboard::type_id::create("m_sb", this);
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
        //
        for(int i = 0; i < env_cfg_h.no_apb_agt; i++) begin
            apb_slv_agt[i].apb_mon_h.ApbContent_toScoreboard.connect(m_sb.apb_trans_fifo[i].analysis_export);    
            apb_slv_agt[i].apb_mon_h.presetn_toScoreboard.connect(m_sb.presetn_fifo[i].analysis_export);    
        end
endfunction

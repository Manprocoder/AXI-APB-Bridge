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
    //localparam NO_SLAVE = 1;
    //
    axi_agent axi_mst_agt;
    apb_agent apb_slv_agt [];
    axi_apb_scoreboard m_sb;
    int no_test;
    //------------------------------------------
    //----INTERFACE handles
    //-----------------------------------------
    virtual interface axi_intf #(DW1, AW1) axi_vif;
    virtual interface apb_intf #(DW2, AW2, `SLAVE_CNT) apb_vif; // it is assigned from APB AGENT class
    //------------------------------------------
    //configuration objects
    //-----------------------------------------
    env_config env_cfg_h;
    axi_agent_config m_cfg;
    apb_agent_config s_cfg[];
    //
    virtual_sequencer v_sqr_h;
    //
    //methods
    //
    extern function new(string name = "m_env", uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);

    extern virtual function void end_of_elaboration_phase (uvm_phase phase);
    extern virtual function void start_of_simulation_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);

endclass
//======================================================================================
//--------------------------IMPLEMENTATION of all METHODs
//======================================================================================
function m_env::new(string name = "m_env", uvm_component parent);
    super.new(name, parent);
endfunction
//function 
function void m_env::build_phase(uvm_phase phase);
  `uvm_info(get_name(), "[BUILD_PHASE ENV]", UVM_LOW)
    super.build_phase(phase);
    //**************************************************************
    //-----------------------Get ENV handle
    //**************************************************************
    if (!uvm_config_db#(env_config)::get(this, "", "env_cfg", env_cfg_h)) begin
      `uvm_fatal(get_name(), "Didn't get ENV config handle!!!")
    end
    //

    //uvm_config_db#(int)::set(this, "*", "NO_TEST", 2000);
    //if(!uvm_config_db#(int)::get(this, "", "NO_TEST", no_test)) begin
      //`uvm_fatal(get_name(), "Didn't found no_test!!!")
    //end 
    //else begin
       //no_test = 2000;
       //uvm_config_db#(int)::set(this, "*", "NO_TEST", no_test);
    //end
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
    //if(!uvm_config_db#(virtual interface apb_intf #(DW2, AW2, `SLAVE_CNT))::get(this, "", $sformatf("apb_vif_%0d", i), apb_vif[i])) begin
    if(!uvm_config_db#(virtual interface apb_intf #(DW2, AW2, `SLAVE_CNT))::get(this, "", "apb_vif", apb_vif)) begin
      `uvm_fatal(get_type_name(), $sformatf("Didn't get handle to virtual interface apb_vif"))
    end
    //
    foreach(s_cfg[i]) begin
        //
        s_cfg[i] = apb_agent_config::type_id::create($sformatf("s_cfg_%0d", i));   //apb agent config object
        s_cfg[i].vif = apb_vif;
        s_cfg[i].slv_order = i;
        s_cfg[i].mst_role = 0;
        s_cfg[i].active = UVM_ACTIVE;
        uvm_config_db#(apb_agent_config)::set(this, $sformatf("apb_slv_agt_%0d*", i), "apb_cfg", s_cfg[i]);
    end
    //---AXI 
    //
    m_cfg = axi_agent_config::type_id::create("m_cfg");   //axi agent config object
    m_cfg.vif = axi_vif;
    uvm_config_db#(axi_agent_config)::set(this, "*", "axi_cfg", m_cfg);
    //
    m_sb = axi_apb_scoreboard::type_id::create("m_sb", this);
    //
    //--virtual sequencer 
    //
    v_sqr_h = virtual_sequencer::type_id::create("v_sqr_h", this);
    //
    //
endfunction

//function
function void m_env::connect_phase(uvm_phase phase); 
    super.connect_phase(phase);
    //=============================================
    //----------assign handles to actual sequencers
    //=============================================
    v_sqr_h.B = new[env_cfg_h.no_apb_agt]; 
    //
    foreach(v_sqr_h.B[i]) begin
        v_sqr_h.B[i] = apb_slv_agt[i].s_seqr_h;
    end
    //
    v_sqr_h.R = axi_mst_agt.rst_seqr;
    v_sqr_h.A1 = axi_mst_agt.w_seqr_h;
    v_sqr_h.A2 = axi_mst_agt.r_seqr_h;
    //=============================================
    //----------connect port
    //=============================================
        axi_mst_agt.m_mon_h.AxiResetn_toScoreBoard.connect(m_sb.aimp_Aresetn);           //ap_imp : analysis port implement
        axi_mst_agt.m_mon_h.AxiRdAddr_toScoreBoard.connect(m_sb.aimp_AxiRdRequest);           //ap_imp : analysis port implement
        axi_mst_agt.m_mon_h.AxiRData_toScoreBoard.connect(m_sb.aimp_AxiRData);           //ap_imp : analysis port implement
        axi_mst_agt.m_mon_h.AxiWrAddr_toScoreBoard.connect(m_sb.aimp_AxiWrRequest);           //ap_imp : analysis port implement
        axi_mst_agt.m_mon_h.AxiWData_toScoreBoard.connect(m_sb.aimp_AxiWData);           //ap_imp : analysis port implement
        axi_mst_agt.m_mon_h.AxiBresp_toScoreBoard.connect(m_sb.aimp_AxiBresp);           //ap_imp : analysis port implement
        //
        //---------------only for test seq item port-export connection between monitor and scoreboard
        //
        axi_mst_agt.m_mon_h.mon_seq_item_port.connect(m_sb.scb_seq_item_export);
        //
        for(int i = 0; i < env_cfg_h.no_apb_agt; i++) begin
            apb_slv_agt[i].apb_mon_h.ApbContent_toScoreboard.connect(m_sb.apb_trans_fifo[i].analysis_export);    
            apb_slv_agt[i].apb_mon_h.presetn_toScoreboard.connect(m_sb.presetn_fifo[i].analysis_export);    
        end
endfunction
//
function void m_env::end_of_elaboration_phase(uvm_phase phase);
    `uvm_info(get_name(), "[END_OF_ELABORATION_PHASE ENV]", UVM_LOW)
    uvm_top.print_topology();
endfunction
//
function void m_env::start_of_simulation_phase(uvm_phase phase);
    `uvm_info(get_name(), "[START_OF_SIMULATION_PHASE ENV]", UVM_LOW)
endfunction
//
task m_env::run_phase(uvm_phase phase);
    `uvm_info(get_name(), "[RUN_PHASE ENV]", UVM_LOW)
endtask

//---------------------------------------------------------------
//--File: test.sv
//--Function: uvm_test
//--Author: Nguyen Ngoc Man
//----------------------------------------------------------------
class base_test extends uvm_test;
    //register
    `uvm_component_utils(base_test)

    m_env m_env0; //uvm_component
    virtual interface axi_intf #(DW,AW1) t_axi_vif;
    virtual interface apb_intf #(DW, AW2) t_apb_vif; // it is assigned from APB AGENT class
    //------------------------------------------
    //configuration objects
    //-----------------------------------------
    axi_agent_config m_cfg;
    apb_agent_config s_cfg;
    env_config env_cfg;
    //virtual seq
    virtual_seq vseq;
    //
    string testcase_name;
    string sim_result_path;
    int no_trans = 300;
    //constructor
    function new(string name, uvm_component parent = null);
        super.new(name,parent);
    endfunction
    //
    extern function void init_vseq(base_vseq vseq);
    extern virtual function void build_phase (uvm_phase phase);
    extern function void end_of_elaboration_phase (uvm_phase phase);
    extern function void start_of_simulation_phase (uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    //
endclass
//
//define all methods in turn
//
function void base_test::init_vseq(base_vseq vseq);
    vseq.R = m_env0.axi_mst_agt.rst_seqr;
    vseq.A1 = m_env0.axi_mst_agt.w_seqr0;
    vseq.A2 = m_env0.axi_mst_agt.r_seqr0;
    vseq.B  = m_env0.apb_slv_agt.s_seqr0;
endfunction: init_vseq
//
function void base_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    //**************************************************************
    //--------------------------INTERFACE
    //**************************************************************
    if (!uvm_config_db#(virtual interface axi_intf #(DW, AW1))::get(this, "", "m_vif", t_axi_vif)) begin
      `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface m_vif")
    end
    if (!uvm_config_db#(virtual interface apb_intf #(DW, AW2))::get(this, "", "s_vif", t_apb_vif)) begin
      `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface s_vif")
    end
    //**************************************************************
    //--------------------------INSTANCES
    //**************************************************************
    m_env0 = m_env::type_id::create("m_env0", this);
    env_cfg = env_config::type_id::create("env_cfg");   //env config object
    m_cfg = axi_agent_config::type_id::create("m_cfg");   //axi agent config object
    s_cfg = apb_agent_config::type_id::create("s_cfg");   //apb agent config object
    //**************************************************************
    //--Pass vital information to config object (env_cfg)
    //**************************************************************
    env_cfg.axi_agt_cfg = m_cfg;  
    env_cfg.apb_agt_cfg = s_cfg;
    env_cfg.axi_agt_cfg.axi_vif = t_axi_vif;
    env_cfg.apb_agt_cfg.apb_vif = t_apb_vif;
    //**************************************************************
    //--store env_cfg into uvm_config_db to leverage reusability
    //**************************************************************
    uvm_config_db#(env_config)::set(this, "*", "env_cfg", env_cfg);
    //
    //Create and Store Sim Result Path
    //
    if (!$value$plusargs("UVM_TESTNAME=%s", testcase_name)) begin
      testcase_name = "DEFAULT";
    end
    // `uvm_info(get_type_name(), $sformatf("UVM_TESTNAME = %s", testcase_name), UVM_LOW)
    $sformat(sim_result_path, "../SIM_RESULT/%0dSLAVE/%s", `SLAVE_CNT, testcase_name);
    //store simulation result path
    uvm_config_db#(string)::set(this, "*", "sim_result_path", sim_result_path);
    //store number of transactions
    uvm_config_db#(int)::set(this, "*", "NO_TEST", no_trans); 
    //
endfunction

//
function void base_test::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
endfunction

//
function void base_test::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
endfunction

//
task base_test::run_phase(uvm_phase phase);
    super.run_phase(phase);
    //
    phase.raise_objection(this);
    //
    vseq = virtual_seq::type_id::create("virtual_seq");
    vseq.no_trans = no_trans;
    fork
        begin
            init_vseq(vseq);
            vseq.start(null); 
        end
	//
        begin
            #10ms;
	    $display("#--------------------------------------------------------------");
	    `uvm_warning("TEST WARNING", "TIMEOUT TIMEOUT TIMEOUT TIMEOUT TIMEOUT!!!")
	    $display("#--------------------------------------------------------------");
        end
     join_any
     disable fork;
    phase.drop_objection(this);
endtask


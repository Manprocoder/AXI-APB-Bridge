//---------------------------------------------------------------
//--File: test.sv
//--Function: uvm_test
//--Author: Nguyen Ngoc Man
//----------------------------------------------------------------
import env_pkg::*;
import seq_pkg::*;
class base_test extends uvm_test;
    //register factory
    `uvm_component_utils(base_test)
    //environment handle
    m_env env_h; 
    //virtual_seq handle
    virtual_seq vseq;
    //
    string testcase_name;
    string sim_result_path;
    int no_trans = 300;
    //constructor
    function new(string name = "base_test", uvm_component parent = null);
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
//========================================================================
//---------------------DEFINE ALL METHODS IN TURN
//========================================================================
function void base_test::init_vseq(base_vseq vseq);
    vseq.R = env_h.axi_mst_agt.rst_seqr;
    vseq.A1 = env_h.axi_mst_agt.w_seqr0;
    vseq.A2 = env_h.axi_mst_agt.r_seqr0;
    vseq.B  = env_h.apb_slv_agt.s_seqr0;
endfunction: init_vseq
//
function void base_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    env_h = m_env::type_id::create("env_h", this);
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
        begin: MAIN_THREAD
            init_vseq(vseq);
            vseq.start(null); 
        end
	//
        begin: TIME_OUT
            #10ms;
	    $display("#--------------------------------------------------------------");
	    `uvm_warning("TEST WARNING", "TIMEOUT TIMEOUT TIMEOUT TIMEOUT TIMEOUT!!!")
	    $display("#--------------------------------------------------------------");
        end
     join_any
     disable fork;
    phase.drop_objection(this);
endtask


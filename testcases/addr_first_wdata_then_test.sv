//---------------------------------------------------------------
//--Project design and verify AXI-APB bridge
//--File: addr_first_wdata_then_test.sv
//--Description: 
//--Author: Nguyen Ngoc Man
//----------------------------------------------------------------
import axi_pkg::*; // get axi interface
import env_pkg::*;
import seq_pkg::*;
class addr_first_wdata_then_test extends base_test;
    //register factory
    `uvm_component_utils(addr_first_wdata_then_test)
    //
  //  interface axi_intf#(DW1, AW1) axi_if_h; //=> without virtual keyword, compiler signals error
    //virtual_seq handle
    virtual_seq vseq;
    //
    //constructor
    function new(string name = "addr_first_wdata_then_test", uvm_component parent = null);
        super.new(name,parent);
    endfunction
    //
    extern virtual function void build_phase (uvm_phase phase);
    extern virtual function void end_of_elaboration_phase (uvm_phase phase);
    extern virtual function void start_of_simulation_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual function void check_phase(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);
    extern virtual function void final_phase(uvm_phase phase);
    extern virtual task apply_reset();
    //
endclass
//========================================================================
//---------------------DEFINE ALL METHODS IN TURN
//========================================================================
function void addr_first_wdata_then_test::build_phase(uvm_phase phase);
    //store number of transactions--driver use this number
    uvm_factory f_h = uvm_factory::get(); //get static handle, singleton class
    `uvm_info(get_name(), "[BUILD_PHASE_START UVM_TEST]", UVM_LOW)
    //
    set_inst_override_by_type("env_h.axi_mst_agt.*", AxiMasterDriver::get_type(), axi_addr_first_wdata_then_driver::get_type());
    f_h.print();
    //
    env_h = m_env::type_id::create("env_h", this);
    env_cfg_h = env_config::type_id::create("env_cfg_h");   //environment config object
    uvm_config_db#(env_config)::set(this, "*", "env_cfg", env_cfg_h);
    uvm_config_db#(int)::set(this, "*", "NO_TEST", 1000); 
    //--only for trial
    uvm_config_db#(string)::set(this, "env_h.*", "TRIAL", "addr_first_wdata_then_test"); //absolute path
   // uvm_config_db#(string)::set(this, "axi_mst_agt", "TRIAL", "addr_first_wdata_then_test"); //relative path 
    //
     if(!uvm_config_db#(virtual interface axi_intf #(DW1, AW1))::get(this, "", "m_vif", axi_vif)) begin
         `uvm_fatal(get_name(), "Virtual AXI interface is not FOUND!!!")
     end
    `uvm_info(get_name(), "[BUILD_PHASE_END UVM_TEST]", UVM_LOW)
endfunction
//
//
function void addr_first_wdata_then_test::end_of_elaboration_phase(uvm_phase phase);
    `uvm_info(get_name(), "[END_OF_ELABORATION_PHASE UVM_TEST]", UVM_LOW)
    super.end_of_elaboration_phase(phase);
endfunction
//
function void addr_first_wdata_then_test::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(get_name(), "[START_OF_SIMULATION_PHASE UVM_TEST]", UVM_LOW)
endfunction
//
//
task addr_first_wdata_then_test::run_phase(uvm_phase phase);
    `uvm_info(get_name(), "[RUN_PHASE UVM_TEST]", UVM_LOW)
    phase.raise_objection(this);
    //
    if(env_h == null) begin
        `uvm_fatal(get_name(), "env handle is NULL")
    end
    //
    vseq = virtual_seq::type_id::create("virtual_seq");
    vseq.no_rd_wr_para = 1000;
    vseq.no_rd_wr_rd = 300;
    vseq.no_wr_rd_wr = 300;
    //vseq.no_unsupported_size = 100; //size is not 4 bytes
    //vseq.no_disallowed_addr = 100; //unaligned addr for WRAP, FIXED (error)
    //vseq.no_dec_err = 20;
    //vseq.no_unaligned_addr = 100;
    vseq.no_rdata_almost_full = 1;
    //
    `uvm_info(get_name(), "Start run phase!!!", UVM_LOW)
    //
    apply_reset();
    `uvm_info(get_name(), "Apply Reset Done!!!", UVM_LOW)
    //
    fork
        begin: MAIN_THREAD
            `uvm_info(get_name(), "Enter MAIN THREAD!!!", UVM_LOW)
            //init_vseq(vseq);
            `uvm_info(get_name(), "Init virtual sequence done!!!", UVM_LOW)
            //vseq.start(null); 
            vseq.start(env_h.v_sqr_h); 
            //#10ms;
        end
	//
        begin: TIME_OUT
            #300ms;
            `uvm_info(get_name(), "=========================================", UVM_LOW);
            `uvm_warning(get_name(), "======TIMEOUT TIMEOUT TIMEOUT!!!======")
            `uvm_info(get_name(), "=========================================", UVM_LOW);
        end
     join_any
     disable fork;
    phase.drop_objection(this);
endtask
//
function void addr_first_wdata_then_test::check_phase(uvm_phase phase);
    `uvm_info(get_name(), "[CHECK_PHASE]", UVM_LOW);
endfunction
//
function void addr_first_wdata_then_test::report_phase(uvm_phase phase);
        int total_trans = vseq.no_rd_wr_para + vseq.no_rd_wr_rd + vseq.no_wr_rd_wr;// + vseq.no_rdata_almost_full; 
        //int total_trans = vseq.no_rd_wr_para + vseq.no_rd_wr_rd + vseq.no_wr_rd_wr + vseq.no_unsupported_size + 
        //vseq.no_disallowed_addr + vseq.no_dec_err + vseq.no_unaligned_addr
    //+ vseq.no_rdata_almost_full;
        `uvm_info(get_name(), "================================================", UVM_LOW);
        `uvm_info(get_name(), "=======ADDR_FIRST_WDATA_THEN TEST REPORT========", UVM_LOW);
        `uvm_info(get_name(), "================================================", UVM_LOW);
        `uvm_info(get_name(), $sformatf("TRANSACTION IN TOTAL: %0d", total_trans), UVM_LOW)
endfunction
//
function void addr_first_wdata_then_test::final_phase(uvm_phase phase);
    `uvm_info(get_name(), "[FINAL_PHASE]", UVM_LOW);
endfunction
//
task addr_first_wdata_then_test::apply_reset();
    axi_vif.aresetn = 1'b1;
    #(`CLK_CYCLE*5);
    axi_vif.aresetn = 1'b0;
    #(`CLK_CYCLE*5);
    axi_vif.aresetn = 1'b1;
endtask


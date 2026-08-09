//---------------------------------------------------------------
//--Project design and verify AXI-APB bridge
//--File: random_test.sv
//--Description: 
//--Author: Nguyen Ngoc Man
//----------------------------------------------------------------
import axi_pkg::*; // get axi interface
import env_pkg::*;
import seq_pkg::*;
class random_test extends base_test;
    //register factory
    `uvm_component_utils(random_test)
    //virtual_seq handle
    virtual_seq vseq;
    //
    //constructor
    function new(string name = "random_test", uvm_component parent = null);
        super.new(name,parent);
    endfunction
    //
    extern virtual function void build_phase (uvm_phase phase);
    extern virtual function void end_of_elaboration_phase (uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);
    extern virtual task apply_reset();
    //
endclass
//========================================================================
//---------------------DEFINE ALL METHODS IN TURN
//========================================================================
function void random_test::build_phase(uvm_phase phase);
    //super.build_phase(phase);
    //store number of transactions--driver use this number
    env_h = m_env::type_id::create("env_h", this);
    env_cfg_h = env_config::type_id::create("env_cfg_h");   //environment config object
    uvm_config_db#(env_config)::set(this, "*", "env_cfg", env_cfg_h);
    uvm_config_db#(int)::set(this, "*", "NO_TEST", 1000); 
    //
     if(!uvm_config_db#(virtual interface axi_intf #(DW1, AW1))::get(this, "", "m_vif", axi_vif)) begin
         `uvm_fatal(get_name(), "Virtual AXI interface is not FOUND!!!")
     end
endfunction
//
//
function void random_test::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
endfunction
//
//
task random_test::run_phase(uvm_phase phase);
    `uvm_info(get_name(), "Enter run phase!!!", UVM_LOW)
    phase.raise_objection(this);
    //
    if(env_h == null) begin
        `uvm_fatal(get_name(), "env handle is NULL")
    end
    //
    vseq = virtual_seq::type_id::create("virtual_seq");
    vseq.no_rd_wr_para = 400;
    vseq.no_rd_wr_rd = 300;
    vseq.no_wr_rd_wr = 300;
    vseq.no_unsupported_size = 100; //size is not 4 bytes
    vseq.no_disallowed_addr = 100; //unaligned addr for WRAP, FIXED (error)
    vseq.no_dec_err = 20;
    vseq.no_unaligned_addr = 100;
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
            init_vseq(vseq);
            `uvm_info(get_name(), "Init virtual sequence done!!!", UVM_LOW)
            vseq.start(null); 
            #10ms;
        end
	//
        begin: TIME_OUT
            #15ms;
            `uvm_info(get_name(), "=========================================", UVM_LOW);
            `uvm_warning(get_name(), "======TIMEOUT TIMEOUT TIMEOUT!!!======")
            `uvm_info(get_name(), "=========================================", UVM_LOW);
        end
     join_any
     disable fork;
    phase.drop_objection(this);
endtask
//
function void random_test::report_phase(uvm_phase phase);
        int total_trans = vseq.no_rd_wr_para + vseq.no_rd_wr_rd + vseq.no_wr_rd_wr + vseq.no_unsupported_size + 
        vseq.no_disallowed_addr + vseq.no_dec_err + vseq.no_unaligned_addr
    + vseq.no_rdata_almost_full;
        `uvm_info(get_name(), "==================================================", UVM_LOW);
        `uvm_info(get_name(), "================RANDOM TEST REPORT================", UVM_LOW);
        `uvm_info(get_name(), "==================================================", UVM_LOW);
        `uvm_info(get_name(), $sformatf("TRANSACTION IN TOTAL: %0d", total_trans), UVM_LOW)
endfunction
//
task random_test::apply_reset();
    axi_vif.aresetn = 1'b1;
    #(`CLK_CYCLE*5);
    axi_vif.aresetn = 1'b0;
    #(`CLK_CYCLE*5);
    axi_vif.aresetn = 1'b1;
endtask


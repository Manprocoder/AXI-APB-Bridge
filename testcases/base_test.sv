//---------------------------------------------------------------
//--Project design and verify AXI-APB bridge
//--File: base_test.sv
//--Description: 
//--Author: Nguyen Ngoc Man
//----------------------------------------------------------------
import axi_pkg::*; //import DW1, AW1
import env_pkg::*;
import seq_pkg::*;
virtual class base_test extends uvm_test;
    //register factory
    `uvm_component_utils(base_test)
    //===================================================
    //-----------------DATA members
    //===================================================
    //---interface
    virtual interface axi_intf#(DW1, AW1) axi_vif; 
    //---env config handle
    env_config env_cfg_h;
    //environment handle
    m_env env_h; 
    //constructor
    function new(string name = "base_test", uvm_component parent = null);
        super.new(name,parent);
    endfunction
    //
    extern function void init_vseq(base_vseq vseq);
    pure virtual function void build_phase (uvm_phase phase);
    extern function void end_of_elaboration_phase (uvm_phase phase);
    pure virtual task run_phase(uvm_phase phase);
    //
endclass
//========================================================================
//---------------------DEFINE ALL METHODS IN TURN
//========================================================================
function void base_test::init_vseq(base_vseq vseq);
    vseq.R = env_h.axi_mst_agt.rst_seqr;
    vseq.A1 = env_h.axi_mst_agt.w_seqr_h;
    vseq.A2 = env_h.axi_mst_agt.r_seqr_h;
    //
    vseq.B = new[env_cfg_h.no_apb_agt];
    //
    for(int i = 0; i < env_cfg_h.no_apb_agt; i++) begin
        vseq.B[i] = env_h.apb_slv_agt[i].s_seqr_h;
    end
endfunction: init_vseq
//
//
function void base_test::end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
endfunction
//


//======================================================
//--Project: AXI to APB IP
//--file: base_vseq.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//======================================================
//import axi_pkg::*;
//import apb_pkg::*;
import env_pkg::*;
class base_vseq extends uvm_sequence#(uvm_sequence_item);
    //register to factory
    `uvm_object_utils(base_vseq)
    `uvm_declare_p_sequencer(virtual_sequencer) //$cast available attribute m_sequencer to p_sequencer
//--MUST NOTICE:
//
//derived class (virtual_seq) does not receive p_sequencer
//
    //---following handles are inside virtual sequencer class
    //ResetSequencer R;
    //WriteSequencer A1;
    //ReadSequencer A2;
    //apb_sequencer B [];
    //
    m_env env_h;
    //
    function new(string name = "base_vseq");
        super.new(name);
    endfunction
    //
    virtual function void get_env_handle();
        //
        if(!$cast(env_h, uvm_top.find("uvm_test_top.env_h"))) begin
            `uvm_error(get_type_name(), "env_h is not found");
        end
    endfunction
    //
endclass

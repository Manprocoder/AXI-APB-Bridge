//======================================================
//--Project: AXI to APB IP
//--file: base_vseq.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//======================================================
import axi_pkg::*;
import apb_pkg::*;
class base_vseq extends uvm_sequence#(uvm_sequence_item);
    //register to factory
    `uvm_object_utils(base_vseq)
    //
    ResetSequencer R;
    WriteSequencer A1;
    ReadSequencer A2;
    ApbSequencer B;
    //
    function new(string name = "base_vseq");
        super.new(name);
    endfunction
    //
endclass

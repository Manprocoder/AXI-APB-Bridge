//======================================================
//--Project: AXI to APB IP
//--file: virtual_sequencer.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//======================================================
import axi_pkg::*;
import apb_pkg::*;
class virtual_sequencer extends uvm_sequencer#(uvm_sequence_item);
    //register to factory
    `uvm_component_utils(virtual_sequencer)
    //
    ResetSequencer R;
    WriteSequencer A1;
    ReadSequencer A2;
    apb_sequencer B [];
    //
    //
    function new(string name = "virtual_sequencer", uvm_component parent);
        super.new(name);
    endfunction
    //
endclass

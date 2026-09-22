//************************************************************
//--Project: AXI APB IP 
//************************************************************
//--file: stimulus_generator.sv
//--Author: Nguyen Ngoc Man
//************************************************************
//--Description: it serves a blueprint for other sequences 
//***********************************************************
import axi_pkg::*;
//this class takes responsibility for generating stimulus
//typedef axi_transaction#(DW1,AW1) axi_item;
//
virtual class stimulus_generator extends uvm_sequence#(axi_item); 
	`uvm_object_utils(stimulus_generator)
	//
	mailbox #(axi_item) mb;
	axi_item trans_h;
	int no_test;
    bit reconfigure_id;
    bit wr_en;
	//
	function new(string name = "sti_gen");
		super.new(name);
	endfunction
	//
	pure virtual function void gen_item();
    pure virtual task body();
	//
endclass

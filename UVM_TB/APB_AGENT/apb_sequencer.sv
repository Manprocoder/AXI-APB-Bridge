//
//
//
class ApbSequencer extends uvm_sequencer#(apb_seq_item#(DW,AW2));
  //Register to Factory
	`uvm_component_utils(ApbSequencer)
  //
  // TO_DO: component must have variable "parent"
  // object must not have veriable "parent" (refer to class cVSequence) 
	function new (string name = "ApbSequencer", uvm_component parent = null);
		super.new(name,parent);
    //Add more code if any
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
    //Add more code if any
	endfunction

endclass

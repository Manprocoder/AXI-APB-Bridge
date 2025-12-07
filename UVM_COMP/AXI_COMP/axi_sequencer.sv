//
//
//
class WriteSequencer extends uvm_sequencer#(axi_transaction#(DW,AW1));
  //Register to Factory
	`uvm_component_utils(WriteSequencer)
	virtual interface axi_intf#(DW,AW1) axi_vif;
  //
  // TO_DO: component must have variable "parent"
  // object must not have variable "parent" (refer to class cVSequence) 
	function new (string name = "WriteSequencer", uvm_component parent = null);
		super.new(name,parent);
    //Add more code if any
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		// if (!uvm_config_db#(virtual interface axi_intf #(DW, AW1))::get(this, "", "m_vif", axi_vif)) begin
		// `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface m_vif")
		// end
    //Add more code if any
	endfunction

endclass
//
//
//
class ReadSequencer extends uvm_sequencer#(axi_transaction#(DW,AW1));
  //Register to Factory
	`uvm_component_utils(ReadSequencer)
	virtual interface axi_intf#(DW,AW1) axi_vif;
  //
  // TO_DO: component must have variable "parent"
  // object must not have veriable "parent" (refer to class cVSequence) 
	function new (string name = "ReadSequencer", uvm_component parent = null);
		super.new(name,parent);
    //Add more code if any
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
    //Add more code if any
	endfunction

endclass
//
//
//
class ResetSequencer extends uvm_sequencer#(axi_transaction#(DW,AW1));
  //Register to Factory
	`uvm_component_utils(ResetSequencer)
  //
  // TO_DO: component must have variable "parent"
  // object must not have veriable "parent" (refer to class cVSequence) 
	function new (string name = "ResetSequencer", uvm_component parent = null);
		super.new(name,parent);
    //Add more code if any
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
    //Add more code if any
	endfunction

endclass

//==============================================================
//--Project: Design and Verify AXI-APB 
//--File: apb_seq.sv
//--Author: Nguyen Ngoc Man
//--Description:
//==============================================================
class apb_seq#(DW = 32, AW2 = 32) extends uvm_sequence;
`uvm_object_param_utils(apb_seq#(DW, AW2))

    apb_seq_item #(DW, AW2) rsp;
  // Constructor
  function new(string name="apb_seq");
    super.new(name);
  endfunction
    
  // Main task body
  virtual task body();
    // Declare request and response items
    `uvm_info(get_type_name(), "APB SLAVE SEQUENCE body() enters!!!", UVM_LOW);
    //
    forever begin
      // Create request item
      rsp = apb_seq_item#(DW, AW2)::type_id::create("APB SLAVE RSP");
      if (rsp == null) begin
        `uvm_error(get_type_name(), $sformatf("Failed to create RSP item!!!"));
      end
      else begin //rsp_not_null
        // Send slave request
        start_item(rsp);
        assert(rsp.randomize());
        finish_item(rsp);
      end //end of rsp_not_null
    end //end of forever
  endtask:body	
endclass
  

//
//
//
class AxiResetSeq extends uvm_sequence#(axi_transaction#(DW1,AW1));
  `uvm_object_utils(AxiResetSeq)
    //
    axi_transaction#(DW1,AW1) reset_item;
    //
    bit rst_value_q [$];
    bit rst_run_time_en;

    function new(string name = "AxiResetSeq");
      super.new(name);
    endfunction 
    //
    extern virtual task body();
endclass
//
//
task AxiResetSeq::body();
    //create item
    foreach (rst_value_q[i]) begin
      reset_item = axi_transaction#(DW1,AW1)::type_id::create("reset_item");
      //
      start_item(reset_item);
      assert(reset_item.randomize() with {
        reset_item.reset == rst_value_q[i];
        rst_run_time_enable == rst_run_time_en;
      }) else
      $error("Randomization failed for AxiResetSeq object!!!");
      finish_item(reset_item);
      #10;
    end
    rst_value_q.delete();
  //
endtask

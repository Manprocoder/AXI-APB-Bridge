//
// testcase: wr_rd_wr test1
//
class wr_rd_wr_test extends base_test;
  `uvm_component_utils(wr_rd_wr_test)
  wr_rd_wr_vseq vseq;
  //
  //constructor
  function new(string name, uvm_component parent = null);
      super.new(name,parent);
  endfunction
  //
  task run_phase(uvm_phase phase);
    //
    //super.run_phase(phase); //comment this line to avoid calling base_test run_phase() task
    phase.raise_objection(this);
    //
    vseq = wr_rd_wr_vseq::type_id::create("wr_rd_wr_vseq");
    fork
      begin
        init_vseq(vseq);
        vseq.start(null);
      end
      begin
        #10ms;
        $display("#--------------------------------------------------------------");
        `uvm_warning("TEST WARNING", "TIMEOUT TIMEOUT TIMEOUT TIMEOUT TIMEOUT!!!")
        $display("#--------------------------------------------------------------");
      end
    join_any
    disable fork;
    phase.drop_objection(this);
  endtask
endclass
//
//
// testcase: rd_wr_rd_test
class rd_wr_rd_test extends base_test;
  `uvm_component_utils(rd_wr_rd_test)
  rd_wr_rd_vseq vseq;
  //
  //constructor
  function new(string name, uvm_component parent = null);
      super.new(name,parent);
  endfunction
  //
  task run_phase(uvm_phase phase);
    //
    //super.run_phase(phase); //comment this line to avoid calling base_test run_phase() task
    phase.raise_objection(this);
    //
    vseq = rd_wr_rd_vseq::type_id::create("rd_wr_rd_vseq");
    fork
      begin
        init_vseq(vseq);
        vseq.start(null);
      end
      begin
        #10ms;
        $display("#--------------------------------------------------------------");
        `uvm_warning("TEST WARNING", "TIMEOUT TIMEOUT TIMEOUT TIMEOUT TIMEOUT!!!")
        $display("#--------------------------------------------------------------");
      end
    join_any
    disable fork;
    phase.drop_objection(this);
  endtask
endclass
//
/////
//// testcase: wr_rd_rd_wr test
//class wr_rd_rd_wr_test extends base_test;
  //`uvm_component_utils(wr_rd_rd_wr_test)
  //wr_rd_rd_wr_vseq vseq;
  ////
  ////constructor
  //function new(string name, uvm_component parent = null);
      //super.new(name,parent);
  //endfunction
  ////
  //task run_phase(uvm_phase phase);
    ////
    ////super.run_phase(phase); //comment this line to avoid calling base_test run_phase() task
    //phase.raise_objection(this);
    ////
    //vseq = wr_rd_rd_wr_vseq::type_id::create("wr_rd_rd_wr_vseq");
    //fork
      //begin
        //init_vseq(vseq);
        //vseq.start(null);
      //end
      //begin
        //#1ms;
        //$display("#--------------------------------------------------------------");
        //`uvm_warning("TEST WARNING", "TIMEOUT TIMEOUT TIMEOUT TIMEOUT TIMEOUT!!!")
        //$display("#--------------------------------------------------------------");
      //end
    //join_any
    //disable fork;
    //phase.drop_objection(this);
  //endtask
//endclass

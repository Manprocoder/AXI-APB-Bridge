//
//
//
class AxiMasterDriver extends uvm_driver#(axi_transaction#(DW, AW1));
  //register UVM factory
  `uvm_component_utils(AxiMasterDriver)
  // Virtual interface (expected to contain a clocking block named 
  virtual interface axi_intf #(DW, AW1) m_drv_vif;
  //virtual interface axi_intf #(DW, AW1) axi_vif;
  //config object
  env_config drv_cfg;
  // Second port for read channel (write uses the base class's seq_item_port)
  uvm_seq_item_pull_port#(REQ, RSP) seq_item_port2, seq_item_port3;
  // queues for outstanding requests
  mailbox #(REQ) w_trans_mailbox;
  // Local control signals (kept for readability; driver logic manages them)
  logic BREADY, RREADY;
  //
  REQ wtx0, wtx1;
  REQ rtx, rxt1;
  //
  bit [2:0] rst_cnt;
  bit [7:0] rst_high_cnt;
  REQ rst_tx;
  //
  int beats = 0;

  // constructor
  function new(string name = "AxiMasterDriver", uvm_component parent = null);
    super.new(name, parent);
    // initialize local flags
    BREADY  = 0;
    RREADY  = 0;
    //
  endfunction

  // build_phase: get virtual interface
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    //if(!uvm_config_db#(virtual interface axi_intf #(DW, AW1))::get(this, "", "m_vif", axi_vif)) begin
	    //`uvm_error(get_type_name(), "axi_vif not found!!!")
    //end
    seq_item_port2 = new("seq_item_port2", this);
    //
    if(drv_cfg.axi_agt_cfg.active == UVM_ACTIVE) begin
      seq_item_port3 = new("seq_item_port3", this);
    end
    w_trans_mailbox = new();
  endfunction
  //
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    if(drv_cfg.axi_agt_cfg.active == UVM_ACTIVE) begin
      fork
        Drive_Reset();
        Master_Write_Driver();
        Master_Read_Driver();
        Reset_All();
      join_none
    end
  endtask
  //
  //-----------------------------------------MAIN EXECUTION----------------------------------------------
  //
  virtual task Drive_Reset();
    forever begin
      seq_item_port3.get_next_item(rst_tx);
      //
      m_drv_vif.aresetn = rst_tx.reset;
      if(rst_tx.rst_run_time_enable == 1'b1) begin
        if(m_drv_vif.aresetn == 1'b0) begin
          while(rst_cnt < rst_tx.rst_low_delay) begin
            // `uvm_info(get_type_name(), $sformatf("rst_cnt = %0d", rst_cnt), UVM_LOW);
            @(m_drv_vif.m_drv_cb);
            rst_cnt++; 
          end
          rst_cnt = 0;
        end
        else begin
          while(rst_high_cnt < rst_tx.rst_high_delay) begin
            // `uvm_info(get_type_name(), $sformatf("rst_cnt = %0d", rst_cnt), UVM_LOW);
            @(m_drv_vif.m_drv_cb);
            rst_high_cnt++; 
          end
            rst_high_cnt = 0; 
        end
      end //end of if rst_run_time_enable
      else if(m_drv_vif.aresetn == 1'b0) begin
        while(rst_cnt < rst_tx.rst_low_delay) begin
          // `uvm_info(get_type_name(), $sformatf("rst_cnt = %0d", rst_cnt), UVM_LOW);
          @(m_drv_vif.m_drv_cb);
          rst_cnt++; 
        end
        rst_cnt = 0;
      end
      //
      seq_item_port3.item_done();
    end
  endtask
  //
  virtual task Reset_All();
    m_drv_vif.wait_for_reset();
    begin
      w_trans_mailbox = new();
      `uvm_info(get_type_name(), $sformatf("[LEVEL_SENSITIVE]all signals reset!!!"), UVM_LOW)
      //
      m_drv_vif.m_drv_cb.awvalid <= 0;
      m_drv_vif.m_drv_cb.awid    <= 0;
      m_drv_vif.m_drv_cb.awaddr  <= 0;
      m_drv_vif.m_drv_cb.awlen   <= 0;
      m_drv_vif.m_drv_cb.awsize  <= 0;
      m_drv_vif.m_drv_cb.awburst <= 0;
      m_drv_vif.m_drv_cb.awprot <= 0;
      //
      m_drv_vif.m_drv_cb.wdata  <= 0;
      m_drv_vif.m_drv_cb.wstrb  <= 0;
      m_drv_vif.m_drv_cb.wlast  <= 0;
      m_drv_vif.m_drv_cb.wvalid <= 0;
      m_drv_vif.m_drv_cb.bready <= 1'b0;
      //
      m_drv_vif.m_drv_cb.arvalid <= 0;
      m_drv_vif.m_drv_cb.araddr  <= '0;
      m_drv_vif.m_drv_cb.arsize  <= '0;
      m_drv_vif.m_drv_cb.arlen   <= '0;
      m_drv_vif.m_drv_cb.arburst <= '0;
      m_drv_vif.m_drv_cb.arid    <= '0;
      m_drv_vif.m_drv_cb.arprot <= 0;
      //
      m_drv_vif.m_drv_cb.rready <= 1'b0;
    end
    //
    while(1) begin
      m_drv_vif.wait_FallingEdge_reset();
      w_trans_mailbox = new();
      `uvm_info(get_type_name(), $sformatf("[EDGE_SENSITIVE]all signals reset!!!"), UVM_LOW)
      //
      m_drv_vif.m_drv_cb.awvalid <= 0;
      m_drv_vif.m_drv_cb.awid    <= 0;
      m_drv_vif.m_drv_cb.awaddr  <= 0;
      m_drv_vif.m_drv_cb.awlen   <= 0;
      m_drv_vif.m_drv_cb.awsize  <= 0;
      m_drv_vif.m_drv_cb.awburst <= 0;
      m_drv_vif.m_drv_cb.awprot <= 0;
      //
      m_drv_vif.m_drv_cb.wdata  <= 0;
      m_drv_vif.m_drv_cb.wstrb  <= 0;
      m_drv_vif.m_drv_cb.wlast  <= 0;
      m_drv_vif.m_drv_cb.wvalid <= 0;
      m_drv_vif.m_drv_cb.bready <= 1'b0;
      //
      m_drv_vif.m_drv_cb.arvalid <= 0;
      m_drv_vif.m_drv_cb.araddr  <= '0;
      m_drv_vif.m_drv_cb.arsize  <= '0;
      m_drv_vif.m_drv_cb.arlen   <= '0;
      m_drv_vif.m_drv_cb.arburst <= '0;
      m_drv_vif.m_drv_cb.arid    <= '0;
      m_drv_vif.m_drv_cb.arprot <= 0;
      //
      m_drv_vif.m_drv_cb.rready <= 1'b0;
    end 
  endtask
  // ------------------------------------------------------------------------
  // Master_Write_Driver
  //-- here, we MUST use fork-join_none to initialize two independent thread
  // ------------------------------------------------------------------------
  virtual task Master_Write_Driver();
    // forever begin
      fork
        forever begin
          m_drv_vif.wait_RisingEdge_reset();
         // #10ns;
          while(m_drv_vif.aresetn_value() == 1'b1) begin
            // get_next_item / item_done must be in same thread for this port
	     //	`uvm_info(get_type_name(), $sformatf("W_Driver starts!!!"), UVM_LOW);
            seq_item_port.get_next_item(wtx0);
            //put transaction into mailbox for later usage of wdata chnnel
            send_write_address(wtx0);
            w_trans_mailbox.put(wtx0);
            //
            seq_item_port.item_done();
	     //	`uvm_info(get_type_name(), $sformatf("W_Driver done!!!"), UVM_LOW);
          end
        end
        //
        forever begin
          // `uvm_info(get_type_name(), $sformatf("WAITING RISING EDGE ARESETN---SendWriteData() TASK!!!"), UVM_LOW);
          m_drv_vif.wait_RisingEdge_reset();
          while(m_drv_vif.aresetn_value() == 1'b1) begin
            w_trans_mailbox.get(wtx1);
            send_write_data(wtx1);
          end
        end
        forever begin
          m_drv_vif.wait_RisingEdge_reset();
          //#10ns;
          while(m_drv_vif.aresetn_value() == 1'b1) begin
            get_bresp();
          end
        end
      join_none
  endtask
  // ------------------------------
  // Master_Read_Driver: owns seq_item_port2 (separate read port)
  // ------------------------------
  virtual task Master_Read_Driver();
    // here, we MUST use FORK-JOIN_NONE to setup INDEPENDENT read_addr channel and read_data one
    // if using jork-join, task will be stuck because get_read_data run while(1) and never stops
    // fork-join waits BOTH sub-tasks done 
      fork
        forever begin
          m_drv_vif.wait_RisingEdge_reset();
          //#10ns;
          while(m_drv_vif.aresetn_value() == 1'b1) begin
            `uvm_info(get_name(), $sformatf("[START]Master_Read_Driver"), UVM_HIGH);
            seq_item_port2.get_next_item(rtx);
            `uvm_info(get_name(), $sformatf("[DONE]Master_Read_Driver"), UVM_HIGH);
            send_read_address(rtx);
            seq_item_port2.item_done();
            // `uvm_info(get_name(), $sformatf("Master_Read_Driver: transaction done (id=%0d)", rtx.id), UVM_LOW);
          end
        end
        forever begin
          m_drv_vif.wait_RisingEdge_reset();
          //#10ns;
          while(m_drv_vif.aresetn_value() == 1'b1) begin
            get_read_data();
          end
        end
      join_none
  endtask

  // send_write_address: issue AW until awready
  // "ref" keyword means this task is inside class -- we do not use "extern" keyword
  virtual task send_write_address(ref REQ tx);
      // `uvm_info(get_type_name(), $sformatf("time_0 = %0t", $time), UVM_LOW);
      fork
        begin
          m_drv_vif.wait_FallingEdge_reset();
        end
        begin
           `uvm_info(get_type_name(), $sformatf("time_0 = %0t", $time), UVM_DEBUG);
          @(m_drv_vif.m_drv_cb);
           `uvm_info(get_type_name(), $sformatf("time_1 = %0t", $time), UVM_DEBUG);
          // present AW signals
	  //tx.print();
          m_drv_vif.m_drv_cb.awvalid <= 1;
          m_drv_vif.m_drv_cb.awid    <= tx.id;
          m_drv_vif.m_drv_cb.awaddr  <= tx.addr;
          m_drv_vif.m_drv_cb.awlen   <= tx.len;
          m_drv_vif.m_drv_cb.awsize  <= tx.size;
          m_drv_vif.m_drv_cb.awburst <= tx.burst;
          m_drv_vif.m_drv_cb.awprot <= tx.prot;

          //m_drv_vif.m_drv_cb.awvalid = 1;
          //m_drv_vif.m_drv_cb.awid    = tx.id;
          //m_drv_vif.m_drv_cb.awaddr  = tx.addr;
          //m_drv_vif.m_drv_cb.awlen   = tx.len;
          //m_drv_vif.m_drv_cb.awsize  = tx.size;
          //m_drv_vif.m_drv_cb.awburst = tx.burst;
          //m_drv_vif.m_drv_cb.awprot = tx.prot;
          // wait until slave asserts awready
          @(m_drv_vif.m_drv_cb iff m_drv_vif.m_drv_cb.awready);
          // deassert and z-state
          m_drv_vif.m_drv_cb.awvalid <= 0;
          m_drv_vif.m_drv_cb.awid    <= 'hz;
          m_drv_vif.m_drv_cb.awaddr  <= 'hz;
          m_drv_vif.m_drv_cb.awlen   <= 'hz;
          m_drv_vif.m_drv_cb.awsize  <= 'hz;
          m_drv_vif.m_drv_cb.awburst <= 'hz;
          m_drv_vif.m_drv_cb.awprot <= 'hz;
        end
      join_any
      disable fork;
      // `uvm_info(get_name(), $sformatf("send_write_address: AW accepted (id=%0d)", tx.id), UVM_LOW);
      // break;  //avoid this task to pass SAME ITEM down to DUT before get NEW ITEM
    // end
  endtask
  //
  // send_write_data: stream WDATA and WSTRB for tx.len+1 beats
  //
  virtual task send_write_data(ref REQ tx);
    beats = 0;
    //
    beats = tx.len + 1;
    // `uvm_info(get_type_name(), $sformatf("WR_BEATS = %0d", beats), UVM_LOW)
    //
    // ensure tx.data[] and tx.wstrb[] are valid and sized appropriately before calling
    fork 
      begin
        // @(negedge m_drv_vif.aresetn);
        m_drv_vif.wait_FallingEdge_reset();
        // `uvm_info(get_type_name(), $sformatf("FALLING EDGE ARESETN---SendWriteData() TASK!!!"), UVM_LOW);
      end
      //
      begin
        for (int i = 0; i < beats; i++) begin
          @(m_drv_vif.m_drv_cb);
	  //tx.print();
          //
          m_drv_vif.m_drv_cb.wdata  <= tx.data[i];
          m_drv_vif.m_drv_cb.wstrb  <= tx.wstrb[i];
          m_drv_vif.m_drv_cb.wlast  <= (i == (beats-1)) ? 1'b1 : 1'b0;
          m_drv_vif.m_drv_cb.wvalid <= 1;
          // wait for slave to accept this beat
          @(m_drv_vif.m_drv_cb iff m_drv_vif.m_drv_cb.wready);
          // on acceptance, deassert & z-state
          m_drv_vif.m_drv_cb.wvalid <= 0;
          m_drv_vif.m_drv_cb.wdata  <= 0;
          m_drv_vif.m_drv_cb.wstrb  <= 0;
          m_drv_vif.m_drv_cb.wlast  <= 0;
        end//end of for
        //
      end
    join_any
    disable fork;
    // `uvm_info(get_type_name(), $sformatf("W_TRANS[%0d]:DISABLE FORK_JOIN_ANY---SendWriteData() TASK!!!", tx.id), UVM_LOW);
  endtask
  //
  //
  virtual task get_bresp();
    fork
      begin
        m_drv_vif.wait_FallingEdge_reset();
        // @(negedge m_drv_vif.aresetn);
      end
      //
      begin
        @(m_drv_vif.m_drv_cb);
        m_drv_vif.m_drv_cb.bready <= 1'b1;
        @(m_drv_vif.m_drv_cb iff m_drv_vif.m_drv_cb.bvalid);
        m_drv_vif.m_drv_cb.bready <= 1'b0;
      end
    join_any
    disable fork;
    // `uvm_info(get_type_name(), $sformatf("DISABLE FORK_JOIN_ANY---GetBresp() TASK!!!"), UVM_LOW);
  endtask
  //
  //--------------------------------------AXI READ TRANSACTION-----------------------------------------
  //
  // send_read_address: AR handshake until arready
  virtual task send_read_address(ref REQ tx);
    //
    fork
      begin
        m_drv_vif.wait_FallingEdge_reset();
      end
      begin
        @(m_drv_vif.m_drv_cb);
        m_drv_vif.m_drv_cb.arvalid <= 1;
        m_drv_vif.m_drv_cb.arid    <= tx.id;
        m_drv_vif.m_drv_cb.araddr  <= tx.addr;
        m_drv_vif.m_drv_cb.arlen   <= tx.len;
        m_drv_vif.m_drv_cb.arsize  <= tx.size;
        m_drv_vif.m_drv_cb.arburst <= tx.burst;
        m_drv_vif.m_drv_cb.arprot <= tx.prot;
        // wait for arready
        @(m_drv_vif.m_drv_cb iff m_drv_vif.m_drv_cb.arready);
        // deassert and z-state
        m_drv_vif.m_drv_cb.arvalid <= 0;
        m_drv_vif.m_drv_cb.arid    <= 'hz;
        m_drv_vif.m_drv_cb.araddr  <= 'hz;
        m_drv_vif.m_drv_cb.arlen   <= 'hz;
        m_drv_vif.m_drv_cb.arsize  <= 'hz;
        m_drv_vif.m_drv_cb.arburst <= 'hz;
        m_drv_vif.m_drv_cb.arprot <= 'hz;
      end
    join_any
    disable fork;
    // `uvm_info(get_name(), $sformatf("send_read_address: AR accepted (id=%0d)", tx.id), UVM_LOW);
  endtask

  virtual task get_read_data();
    fork
    begin
        // @(negedge m_drv_vif.aresetn);
      m_drv_vif.wait_FallingEdge_reset();
        // `uvm_info(get_type_name(), $sformatf("FALLING EDGE ARESETN---GetReadData() TASK!!!"), UVM_LOW);
    end 
    //
    begin
      forever begin
        @(m_drv_vif.m_drv_cb);
        RREADY = $urandom_range(1'b0, 1'b1);
        // `uvm_info(get_type_name(), $sformatf("RREADY = %0b", RREADY), UVM_LOW)
        m_drv_vif.m_drv_cb.rready <= RREADY;
        //consistently wait rvalid == 1'b1 event each clock 
        //CRITICAL NOTE: be careful to handle this event, if event never occurs, program will be stuck forever HERE
        @(m_drv_vif.m_drv_cb iff m_drv_vif.m_drv_cb.rvalid);
      end
    end
    //
    join_any
    disable fork;
    // `uvm_info(get_type_name(), $sformatf("DISABLE FORK_JOIN_ANY---GetReadData() TASK!!!"), UVM_LOW);
  endtask

endclass : AxiMasterDriver

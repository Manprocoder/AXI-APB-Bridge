//
//
//
class AxiMasterDriver extends uvm_driver#(axi_transaction#(DW, AW1));
  //register UVM factory
  `uvm_component_utils(AxiMasterDriver)
  // Virtual interface (expected to contain a clocking block named 
  virtual interface axi_intf #(DW, AW1) m_drv_vif;
  //config object
  env_config drv_cfg;
  // Second port for read channel (write uses the base class's seq_item_port)
  uvm_seq_item_pull_port#(REQ, RSP) seq_item_port2, seq_item_port3;
  uvm_tlm_fifo#(REQ) w_trans_fifo;
  uvm_blocking_put_port#(REQ) put_port;
  uvm_blocking_get_port#(REQ) get_port;
  // Local control signals (kept for readability; driver logic manages them)
  logic RREADY;
  //
  REQ wtx0, wtx1;
  REQ rtx, rxt1;
  //
  bit [2:0] rst_cnt;
  bit [7:0] rst_high_cnt;
  REQ rst_tx;
  //
  int beats = 0;
  int no_trans;
  int bready_cnt;
  int low_bready_duration;

  // constructor
  function new(string name = "AxiMasterDriver", uvm_component parent = null);
    super.new(name, parent);
    // initialize local flags
    RREADY  = 0;
    //
  endfunction

  // build_phase: get virtual interface
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
      seq_item_port2 = new("seq_item_port2", this);
    //
    if(drv_cfg.axi_agt_cfg.active == UVM_ACTIVE) begin
      seq_item_port3 = new("seq_item_port3", this);
    end
    //
	if(!uvm_config_db#(int)::get(this, "", "NO_TEST", no_trans)) begin
		`uvm_fatal(get_type_name(), "NO_TEST is not FOUND")
	end
    //
    put_port = new("put_port", this);
    get_port = new("get_port", this);
    w_trans_fifo = new("w_trans_tlm_fifo", this, no_trans);
  endfunction
  //
  virtual function void connect_phase(uvm_phase phase);
	  put_port.connect(w_trans_fifo.put_export);
	  get_port.connect(w_trans_fifo.get_export);
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
  virtual task count_reset(input REQ rst_tx);
          while(rst_cnt < rst_tx.rst_low_delay) begin
            // `uvm_info(get_type_name(), $sformatf("rst_cnt = %0d", rst_cnt), UVM_MEDIUM);
            @(m_drv_vif.m_drv_cb);
            rst_cnt++; 
          end
          rst_cnt = 0;
  endtask
  //
  virtual task Drive_Reset();
    forever begin
      seq_item_port3.get_next_item(rst_tx);
      //
      m_drv_vif.aresetn = rst_tx.reset;
      if(rst_tx.rst_run_time_enable == 1'b1) begin
        if(m_drv_vif.aresetn == 1'b0) begin
		count_reset(rst_tx);
        end
        else begin
          while(rst_high_cnt < rst_tx.rst_high_delay) begin
            // `uvm_info(get_type_name(), $sformatf("rst_cnt = %0d", rst_cnt), UVM_MEDIUM);
            @(m_drv_vif.m_drv_cb);
            rst_high_cnt++; 
          end
            rst_high_cnt = 0; 
        end
      end //end of if rst_run_time_enable
      else if(m_drv_vif.aresetn == 1'b0) begin
		count_reset(rst_tx);
      end
      //
      seq_item_port3.item_done();
    end
  endtask
  //
  virtual task reset_wr_req_signals();
      m_drv_vif.m_drv_cb.awvalid <= 0;
      m_drv_vif.m_drv_cb.awid    <= 0;
      m_drv_vif.m_drv_cb.awaddr  <= 0;
      m_drv_vif.m_drv_cb.awlen   <= 0;
      m_drv_vif.m_drv_cb.awsize  <= 0;
      m_drv_vif.m_drv_cb.awburst <= 0;
      m_drv_vif.m_drv_cb.awprot <= 0;
  endtask
  //
  virtual task reset_rd_req_signals();
      m_drv_vif.m_drv_cb.arvalid <= 0;
      m_drv_vif.m_drv_cb.araddr  <= '0;
      m_drv_vif.m_drv_cb.arsize  <= '0;
      m_drv_vif.m_drv_cb.arlen   <= '0;
      m_drv_vif.m_drv_cb.arburst <= '0;
      m_drv_vif.m_drv_cb.arid    <= '0;
      m_drv_vif.m_drv_cb.arprot <= 0;
  endtask
  //
  virtual task reset_wr_dat_signals();
      m_drv_vif.m_drv_cb.wdata  <= 0;
      m_drv_vif.m_drv_cb.wstrb  <= 0;
      m_drv_vif.m_drv_cb.wlast  <= 0;
      m_drv_vif.m_drv_cb.wvalid <= 0;
      m_drv_vif.m_drv_cb.bready <= 1'b0;
  endtask
  //
  virtual task reset_signals();
      w_trans_fifo.flush();
      reset_wr_req_signals();
      reset_rd_req_signals();
      reset_wr_dat_signals();
      //
      m_drv_vif.m_drv_cb.rready <= 1'b0;
  endtask
  //
  virtual task Reset_All();
    m_drv_vif.wait_for_reset();
	`uvm_info(get_type_name(), $sformatf("[LEVEL_SENSITIVE]all signals reset!!!"), UVM_LOW)
	reset_signals();
    //
    while(1) begin
      m_drv_vif.wait_FallingEdge_reset();
      `uvm_info(get_type_name(), $sformatf("[EDGE_SENSITIVE]all signals reset!!!"), UVM_LOW)
      reset_signals();
    end 
  endtask
  // ------------------------------------------------------------------------
  // Master_Write_Driver
  //-- here, we MUST use fork-join_none to initialize two independent thread
  // ------------------------------------------------------------------------
  virtual task Master_Write_Driver();
      fork
        forever begin
          m_drv_vif.wait_RisingEdge_reset();
          //#(`CLK_CYCLE);
          while(m_drv_vif.aresetn_value() == 1'b1) begin
	    `uvm_info(get_type_name(), $sformatf("[Drive Write Request] START!!!"), UVM_MEDIUM);
            seq_item_port.get_next_item(wtx0);
            //put transaction into mailbox for later usage of wdata chnnel
            send_write_address(wtx0);
	    //
	    if(w_trans_fifo.is_full()) begin
		    `uvm_info(get_type_name(), "WR trans TLM FIFO is FULL!!!", UVM_LOW)
	    end
            else put_port.put(wtx0);
            //
            seq_item_port.item_done();
	    `uvm_info(get_type_name(), $sformatf("[Drive Write Request] done!!!"), UVM_MEDIUM);
          end
        end
        //
        forever begin
          // `uvm_info(get_type_name(), $sformatf("WAITING RISING EDGE ARESETN---SendWriteData() TASK!!!"), UVM_MEDIUM);
          m_drv_vif.wait_RisingEdge_reset();
          while(m_drv_vif.aresetn_value() == 1'b1) begin
            get_port.get(wtx1);
            send_write_data(wtx1);
          end
        end
        forever begin
          m_drv_vif.wait_RisingEdge_reset();
         //#(`CLK_CYCLE);
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
         //#(`CLK_CYCLE);
          while(m_drv_vif.aresetn_value() == 1'b1) begin
            `uvm_info(get_name(), $sformatf("[START]Master_Read_Driver"), UVM_MEDIUM);
            seq_item_port2.get_next_item(rtx);
            send_read_address(rtx);
            seq_item_port2.item_done();
            `uvm_info(get_name(), $sformatf("[DONE]Master_Read_Driver"), UVM_MEDIUM);
            // `uvm_info(get_name(), $sformatf("Master_Read_Driver: transaction done (id=%0d)", rtx.id), UVM_MEDIUM);
          end
        end
        forever begin
          m_drv_vif.wait_RisingEdge_reset();
         //#(`CLK_CYCLE);
          while(m_drv_vif.aresetn_value() == 1'b1) begin
            get_read_data();
          end
        end
      join_none
  endtask

  // send_write_address: issue AW until awready
  virtual task send_write_address(input REQ tx);
      fork
        begin
          m_drv_vif.wait_FallingEdge_reset();
        end
        begin
           `uvm_info(get_type_name(), $sformatf("before clocking block"), UVM_HIGH);
          @(m_drv_vif.m_drv_cb);
           `uvm_info(get_type_name(), $sformatf("after clocking block"), UVM_HIGH);
	  //tx.print();
          m_drv_vif.m_drv_cb.awvalid <= 1;
          m_drv_vif.m_drv_cb.awid    <= tx.id;
          m_drv_vif.m_drv_cb.awaddr  <= tx.addr;
          m_drv_vif.m_drv_cb.awlen   <= tx.len;
          m_drv_vif.m_drv_cb.awsize  <= tx.size;
          m_drv_vif.m_drv_cb.awburst <= tx.burst;
          m_drv_vif.m_drv_cb.awprot <= tx.prot;
          // wait until slave asserts awready
          @(m_drv_vif.m_drv_cb iff m_drv_vif.m_drv_cb.awready);
          // deassert and z-state
          reset_wr_req_signals();
        end
      join_any
      disable fork;
  endtask
  //
  // send_write_data: stream WDATA and WSTRB for tx.len+1 beats
  //
  virtual task send_write_data(input REQ tx);
    beats = 0;
    beats = tx.len + 1;
    fork 
      begin
        m_drv_vif.wait_FallingEdge_reset();
        // `uvm_info(get_type_name(), $sformatf("FALLING EDGE ARESETN---SendWriteData() TASK!!!"), UVM_MEDIUM);
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
          reset_wr_dat_signals();
        end//end of for
        //
      end
    join_any
    disable fork;
    // `uvm_info(get_type_name(), $sformatf("W_TRANS[%0d]:DISABLE FORK_JOIN_ANY---SendWriteData() TASK!!!", tx.id), UVM_MEDIUM);
  endtask
  //
  //
  virtual task get_bresp();
    bready_cnt = 0;
    low_bready_duration = $urandom_range(255, 0);
    fork
      begin
        m_drv_vif.wait_FallingEdge_reset();
      end
      //
      begin
        @(m_drv_vif.m_drv_cb);
        m_drv_vif.m_drv_cb.bready <= 1'b0;
        @(m_drv_vif.m_drv_cb iff m_drv_vif.m_drv_cb.bvalid);
	while(1) begin
		if(bready_cnt == low_bready_duration) break;
		else begin 
			bready_cnt++;
			@(m_drv_vif.m_drv_cb);
		end
	end
        m_drv_vif.m_drv_cb.bready <= 1'b1;
	@(m_drv_vif.m_drv_cb);
        m_drv_vif.m_drv_cb.bready <= 1'b0;
      end
    join_any
    disable fork;
  endtask
  //
  //--------------------------------------AXI READ TRANSACTION-----------------------------------------
  //
  // send_read_address: AR handshake until arready
  virtual task send_read_address(input REQ tx);
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
          reset_rd_req_signals();
      end
    join_any
    disable fork;
    // `uvm_info(get_name(), $sformatf("send_read_address: AR accepted (id=%0d)", tx.id), UVM_MEDIUM);
  endtask

  virtual task get_read_data();
    fork
    begin
        // @(negedge m_drv_vif.aresetn);
      m_drv_vif.wait_FallingEdge_reset();
        // `uvm_info(get_type_name(), $sformatf("FALLING EDGE ARESETN---GetReadData() TASK!!!"), UVM_MEDIUM);
    end 
    //
    begin
      forever begin
        @(m_drv_vif.m_drv_cb);
        RREADY = $urandom_range(1'b0, 1'b1);
        // `uvm_info(get_type_name(), $sformatf("RREADY = %0b", RREADY), UVM_MEDIUM)
        m_drv_vif.m_drv_cb.rready <= RREADY;
        //consistently wait rvalid == 1'b1 event each clock 
        //CRITICAL NOTE: be careful to handle this event, if event never occurs, program will be stuck forever HERE
        @(m_drv_vif.m_drv_cb iff m_drv_vif.m_drv_cb.rvalid);
      end
    end
    //
    join_any
    disable fork;
    // `uvm_info(get_type_name(), $sformatf("DISABLE FORK_JOIN_ANY---GetReadData() TASK!!!"), UVM_MEDIUM);
  endtask

endclass : AxiMasterDriver

//================================================================================
//--Project: AXI to APB IP
//--File: axi_driver.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//================================================================================
class AxiMasterDriver extends uvm_driver#(axi_transaction#(DW1, AW1));
  //register UVM factory
  `uvm_component_utils(AxiMasterDriver)
  //================================================================
  //--------------------DATA members
  //================================================================
  //--1: Config
  axi_agent_config drv_cfg;
  //--2: Ports
  uvm_seq_item_pull_port#(REQ, RSP) seq_item_port2, seq_item_port3;
  uvm_blocking_put_port#(REQ) put_port;
  uvm_blocking_get_port#(REQ) get_port;
  //--3: Fifo
  uvm_tlm_fifo#(REQ) w_trans_fifo;
  int no_trans; //ACTUAL size of w_trans_fifo, which is retrieved from uvm_config_db
  //--4: request handles
  REQ wtx0, wtx1;
  REQ rtx, rxt1;
  REQ rst_tx;
  //--5: others
  //--5.1:  Local control signals (kept for readability; driver logic manages them)
  logic RREADY;
  //--5.2: reset-related variables
  bit [2:0] rst_low_cnt;
  bit [7:0] rst_high_cnt;
  //--5.3: handle in sending write data 
  int beats = 0;
  //--5.4: handles WRITE RESPONSE channel
  int bready_cnt;
  int low_bready_duration;

  //================================================================
  //-------------------- METHODS
  //================================================================

  extern function new(string name = "AxiMasterDriver", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task count_reset(input REQ rst_tx, input bit high_or_low);
  extern virtual task Drive_Reset();
  extern virtual task reset_wr_req_signals();
  extern virtual task reset_rd_req_signals();
  extern virtual task reset_wr_dat_signals();
  extern virtual task reset_members();
  extern virtual task Reset_All();
  extern virtual task Master_Write_Driver();
  extern virtual task Master_Read_Driver();
  extern virtual task send_write_address(input REQ tx);
  extern virtual task send_write_data(input REQ tx);
  extern virtual task get_bresp();
  extern virtual task send_read_address(input REQ tx);
  extern virtual task get_read_data();

endclass: AxiMasterDriver
  //================================================================
  //--------------------IMPLEMENTATION of ALL METHODS
  //================================================================
function AxiMasterDriver::new(string name = "AxiMasterDriver", uvm_component parent = null);
    super.new(name, parent);
    // initialize local flags
    RREADY  = 0;
    //
  endfunction

  // build_phase: get virtual interface
  function void AxiMasterDriver::build_phase(uvm_phase phase);
    super.build_phase(phase);
      seq_item_port2 = new("seq_item_port2", this);
    //
    if(drv_cfg.active == UVM_ACTIVE) begin
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
  function void AxiMasterDriver::connect_phase(uvm_phase phase);
	  put_port.connect(w_trans_fifo.put_export);
	  get_port.connect(w_trans_fifo.get_export);
  endfunction
  //
  task AxiMasterDriver::run_phase(uvm_phase phase);
    super.run_phase(phase);
    if(drv_cfg.active == UVM_ACTIVE) begin
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
  task AxiMasterDriver::count_reset(input REQ rst_tx, input bit high_or_low);
          if(high_or_low == 1'b1) begin
              while(rst_high_cnt < rst_tx.rst_high_delay) begin
                `uvm_info(get_type_name(), $sformatf("[HIGH_LEVEL]rst_high_cnt = %0d", rst_high_cnt), UVM_HIGH);
                @(drv_cfg.vif.m_drv_cb);
                rst_high_cnt++; 
              end
                rst_high_cnt = 0; 
          end
          else begin 
              while(rst_low_cnt < rst_tx.rst_low_delay) begin
                `uvm_info(get_type_name(), $sformatf("[LOW_LEVEL]rst_low_cnt = %0d", rst_low_cnt), UVM_HIGH);
                @(drv_cfg.vif.m_drv_cb);
                rst_low_cnt++; 
              end
              rst_low_cnt = 0;
          end
  endtask
  //
  task AxiMasterDriver::Drive_Reset();
    forever begin
      seq_item_port3.get_next_item(rst_tx);
      //
      drv_cfg.vif.aresetn = rst_tx.reset;
      if(rst_tx.rst_run_time_enable == 1'b1) begin
        if(drv_cfg.vif.aresetn == 1'b0) begin
		count_reset(rst_tx, 1'b0);
        end
        else begin
            count_reset(rst_tx, 1'b1);
        end
      end //end of if rst_run_time_enable
      else if(drv_cfg.vif.aresetn == 1'b0) begin
		count_reset(rst_tx, 1'b0);
      end
      //
      seq_item_port3.item_done();
    end
  endtask
  //
  task AxiMasterDriver::reset_wr_req_signals();
      drv_cfg.vif.m_drv_cb.awvalid <= 0;
      drv_cfg.vif.m_drv_cb.awid    <= 0;
      drv_cfg.vif.m_drv_cb.awaddr  <= 0;
      drv_cfg.vif.m_drv_cb.awlen   <= 0;
      drv_cfg.vif.m_drv_cb.awsize  <= 0;
      drv_cfg.vif.m_drv_cb.awburst <= 0;
      drv_cfg.vif.m_drv_cb.awprot <= 0;
  endtask
  //
  task AxiMasterDriver::reset_rd_req_signals();
      drv_cfg.vif.m_drv_cb.arvalid <= 0;
      drv_cfg.vif.m_drv_cb.araddr  <= '0;
      drv_cfg.vif.m_drv_cb.arsize  <= '0;
      drv_cfg.vif.m_drv_cb.arlen   <= '0;
      drv_cfg.vif.m_drv_cb.arburst <= '0;
      drv_cfg.vif.m_drv_cb.arid    <= '0;
      drv_cfg.vif.m_drv_cb.arprot <= 0;
  endtask
  //
  task AxiMasterDriver::reset_wr_dat_signals();
      drv_cfg.vif.m_drv_cb.wdata  <= 0;
      drv_cfg.vif.m_drv_cb.wstrb  <= 0;
      drv_cfg.vif.m_drv_cb.wlast  <= 0;
      drv_cfg.vif.m_drv_cb.wvalid <= 0;
      drv_cfg.vif.m_drv_cb.bready <= 1'b0;
  endtask
  //
  task AxiMasterDriver::reset_members();
      w_trans_fifo.flush();
      reset_wr_req_signals();
      reset_rd_req_signals();
      reset_wr_dat_signals();
      //
      drv_cfg.vif.m_drv_cb.rready <= 1'b0;
  endtask
  //
  task AxiMasterDriver::Reset_All();
    drv_cfg.vif.wait_for_reset();
	`uvm_info(get_type_name(), $sformatf("[LEVEL_SENSITIVE]all signals reset!!!"), UVM_LOW)
	reset_members();
    //
    while(1) begin
      drv_cfg.vif.wait_FallingEdge_reset();
      `uvm_info(get_type_name(), $sformatf("[EDGE_SENSITIVE]all signals reset!!!"), UVM_LOW)
        reset_members();
    end 
  endtask
  // ------------------------------------------------------------------------
  // Master_Write_Driver
  //-- here, we MUST use fork-join_none to initialize two independent thread
  // ------------------------------------------------------------------------
  task AxiMasterDriver::Master_Write_Driver();
      fork
        forever begin: GET_WR_REQUEST
          drv_cfg.vif.wait_RisingEdge_reset();
          //#(`CLK_CYCLE);
          while(drv_cfg.vif.aresetn_value() == 1'b1) begin: Master_Write_Driver_Run
            `uvm_info(get_type_name(), $sformatf("[Drive Write Request] START!!!"), UVM_MEDIUM);
                seq_item_port.get_next_item(wtx0);
                //put transaction into mailbox for later usage of wdata chnnel
                send_write_address(wtx0);
            //
            if(w_trans_fifo.is_full()) begin
                `uvm_info(get_type_name(), "WR trans TLM FIFO is FULL!!!", UVM_LOW)
            end
            //else begin
                put_port.put(wtx0);
            //end
                //
                seq_item_port.item_done();
            `uvm_info(get_type_name(), $sformatf("[Drive Write Request] done!!!"), UVM_MEDIUM);
          end //end of while
        end//end of GET_WR_REQUEST
        //
        forever begin: SEND_WDATA
          `uvm_info(get_name(), $sformatf("WAIT RISI_EDGE_of_ARESETN---SendWriteData!!!"), UVM_HIGH);
          drv_cfg.vif.wait_RisingEdge_reset();
          while(drv_cfg.vif.aresetn_value() == 1'b1) begin
            get_port.get(wtx1);
            send_write_data(wtx1);
          end
        end//end of SEND_WDATA
        //
        forever begin: GET_BRESP
          drv_cfg.vif.wait_RisingEdge_reset();
         //#(`CLK_CYCLE);
          while(drv_cfg.vif.aresetn_value() == 1'b1) begin
            get_bresp();
          end
        end//end of GET_BRESP
      join_none
  endtask
  // ------------------------------
  // Master_Read_Driver: owns seq_item_port2 (separate read port)
  // ------------------------------
  task AxiMasterDriver::Master_Read_Driver();
    // here, we MUST use FORK-JOIN_NONE to setup INDEPENDENT read_addr channel and read_data one
    // if using jork-join, task will be stuck because get_read_data run while(1) and never stops
    // fork-join waits BOTH sub-tasks done 
      fork
        forever begin: GET_RD_REQUEST
          drv_cfg.vif.wait_RisingEdge_reset();
         //#(`CLK_CYCLE);
          while(drv_cfg.vif.aresetn_value() == 1'b1) begin
            `uvm_info(get_name(), $sformatf("[START]Master_Read_Driver"), UVM_MEDIUM);
            seq_item_port2.get_next_item(rtx);
            send_read_address(rtx);
            seq_item_port2.item_done();
            `uvm_info(get_name(), $sformatf("[DONE]Master_Read_Driver"), UVM_MEDIUM);
            // `uvm_info(get_name(), $sformatf("Master_Read_Driver: transaction done (id=%0d)", rtx.id), UVM_MEDIUM);
          end
        end//end of GET_RD_REQUEST
        //
        forever begin: GET_RD_DATA
          drv_cfg.vif.wait_RisingEdge_reset();
         //#(`CLK_CYCLE);
          while(drv_cfg.vif.aresetn_value() == 1'b1) begin
            get_read_data();
          end
        end//end of GET_RD_DATA
      join_none
  endtask

  // send_write_address: issue AW until awready
  task AxiMasterDriver::send_write_address(input REQ tx);
      fork
        begin: DETECT_RST_IN_SEND_WR_ADRR
          drv_cfg.vif.wait_FallingEdge_reset();
        end
        begin: SEND_WR_ADDR
           `uvm_info(get_type_name(), $sformatf("before clocking block"), UVM_HIGH);
          @(drv_cfg.vif.m_drv_cb);
           `uvm_info(get_type_name(), $sformatf("after clocking block"), UVM_HIGH);
	  //tx.print();
          drv_cfg.vif.m_drv_cb.awvalid <= 1;
          drv_cfg.vif.m_drv_cb.awid    <= {tx.slv_idx, 8'd0, tx.id};
          drv_cfg.vif.m_drv_cb.awaddr  <= tx.addr;
          drv_cfg.vif.m_drv_cb.awlen   <= tx.len;
          drv_cfg.vif.m_drv_cb.awsize  <= tx.size;
          drv_cfg.vif.m_drv_cb.awburst <= tx.burst;
          drv_cfg.vif.m_drv_cb.awprot <= tx.prot;
          // wait until slave asserts awready
          @(drv_cfg.vif.m_drv_cb iff drv_cfg.vif.m_drv_cb.awready);
          // deassert and z-state
          reset_wr_req_signals();
        end
      join_any
      disable fork;
  endtask
  //
  // send_write_data: stream WDATA and WSTRB for tx.len+1 beats
  //
  task AxiMasterDriver::send_write_data(input REQ tx);
    beats = 0;
    beats = tx.len + 1;
    fork 
      begin: DETECT_RST_IN_SEND_WDATA
        drv_cfg.vif.wait_FallingEdge_reset();
        `uvm_info(get_type_name(), $sformatf("FALLING EDGE ARESETN---SendWriteData() TASK!!!"), UVM_HIGH);
      end
      //
      begin: SEND_WDATA
        for (int i = 0; i < beats; i++) begin
          @(drv_cfg.vif.m_drv_cb);
          drv_cfg.vif.m_drv_cb.wdata  <= tx.data_arr[i];
          drv_cfg.vif.m_drv_cb.wstrb  <= tx.wstrb[i];
          drv_cfg.vif.m_drv_cb.wlast  <= (i == (beats-1)) ? 1'b1 : 1'b0;
          drv_cfg.vif.m_drv_cb.wvalid <= 1;
          // wait for slave to accept this beat
          @(drv_cfg.vif.m_drv_cb iff drv_cfg.vif.m_drv_cb.wready);
          // on acceptance, deassert & z-state
          reset_wr_dat_signals();
        end//end of for
        //
      end
    join_any
    disable fork;
   `uvm_info(get_type_name(), $sformatf("W_TRANS[%0d]SendWriteData DONE!!!", tx.id), UVM_HIGH);
  endtask
  //
  //
  task AxiMasterDriver::get_bresp();
    bready_cnt = 0;
    low_bready_duration = $urandom_range(255, 0);
    fork
      begin: DETECT_RST_IN_GET_BRESP
        drv_cfg.vif.wait_FallingEdge_reset();
      end
      //
      begin: IN_BRESP_CHANNEL
        @(drv_cfg.vif.m_drv_cb);
        drv_cfg.vif.m_drv_cb.bready <= 1'b0;
        @(drv_cfg.vif.m_drv_cb iff drv_cfg.vif.m_drv_cb.bvalid);
        while(1) begin
            if(bready_cnt == low_bready_duration) break;
            else begin 
                bready_cnt++;
                @(drv_cfg.vif.m_drv_cb);
            end
        end
        //
        drv_cfg.vif.m_drv_cb.bready <= 1'b1;
        @(drv_cfg.vif.m_drv_cb);
        drv_cfg.vif.m_drv_cb.bready <= 1'b0;
      end
    join_any
    disable fork;
  endtask
  //
  //--------------------------------------AXI READ TRANSACTION-----------------------------------------
  //
  // send_read_address: AR handshake until arready
  task AxiMasterDriver::send_read_address(input REQ tx);
    //
    fork
      begin: DETECT_RST_IN_SEND_RD_ADDR
        drv_cfg.vif.wait_FallingEdge_reset();
      end
      begin: IN_SEND_RD_ADDR
        @(drv_cfg.vif.m_drv_cb);
        drv_cfg.vif.m_drv_cb.arvalid <= 1;
        drv_cfg.vif.m_drv_cb.arid    <= {tx.slv_idx, 8'd0, tx.id};
        drv_cfg.vif.m_drv_cb.araddr  <= tx.addr;
        drv_cfg.vif.m_drv_cb.arlen   <= tx.len;
        drv_cfg.vif.m_drv_cb.arsize  <= tx.size;
        drv_cfg.vif.m_drv_cb.arburst <= tx.burst;
        drv_cfg.vif.m_drv_cb.arprot <= tx.prot;
        // wait for arready
        @(drv_cfg.vif.m_drv_cb iff drv_cfg.vif.m_drv_cb.arready);
        // deassert and z-state
          reset_rd_req_signals();
      end
    join_any
    disable fork;
     `uvm_info(get_name(), $sformatf("send_read_address: AR accepted (id=%0d)", tx.id), UVM_HIGH);
  endtask

  task AxiMasterDriver::get_read_data();
    fork
    begin: DETECT_RST_IN_GET_RDATA
      drv_cfg.vif.wait_FallingEdge_reset();
      `uvm_info(get_type_name(), $sformatf("FALLING EDGE ARESETN---GetReadData() TASK!!!"), UVM_HIGH);
    end 
    //
    begin: IN_GET_RDATA
      forever begin
        @(drv_cfg.vif.m_drv_cb);
        RREADY = $urandom_range(1'b0, 1'b1);
        `uvm_info(get_type_name(), $sformatf("RREADY = %0b", RREADY), UVM_HIGH)
        drv_cfg.vif.m_drv_cb.rready <= RREADY;
        //consistently wait rvalid == 1'b1 event each clock 
        //CRITICAL NOTE: be careful to handle this event, if event never occurs, program will be stuck forever HERE
        @(drv_cfg.vif.m_drv_cb iff drv_cfg.vif.m_drv_cb.rvalid);
      end
    end
    //
    join_any
    disable fork;
    `uvm_info(get_type_name(), $sformatf("[DONE]GetReadData!!!"), UVM_HIGH);
  endtask


//=============================================
//CLASS description
//-- AxiMasterDriver.sv
//=============================================
class AxiMasterDriver extends uvm_driver#(axi_transaction#(DW, AW1));
    //register UVM factory
    `uvm_component_utils(AxiMasterDriver)
    //---------------------------------------------
    //Data members
    //---------------------------------------------
  	virtual interface axi_intf#(DW, AW1) m_drv_vif;
    bit w_done, r_done;
    //
    //--all upper variables(AWVALID, ARVALID, BREADY, RREADY) serve to local (this class) usage 
    //--they are output of clocking block, we can not read their's value
    //--for instance: if(m_drv_vif.m_drv_cb.bready or ...rready) causes error
    //
  	bit AWVALID, ARVALID;
  	bit BREADY, RREADY;
    logic [7:0] ReadLengthQueue [$];
    logic [7:0] WriteLengthQueue [$];
    uvm_seq_item_pull_port#(REQ, RSP) seq_item_port2;   //seq_item_port is default
  	REQ w_trans, r_trans;
    bit [7:0] ReadLengthQueueDataOut;
    bit CaptureReadDataDone, CaptureReadDataStart;
    bit ReadLengthQueueFirstRead = 1'b1;
    //--write
    bit [7:0] WriteLengthQueueDataOut;
    bit SendWriteDataDone, SendWriteDataStart;
    bit WriteLengthQueueFirstRead = 1'b1;
    int wr_len = 0;
    //
    function new (string name = "AxiMasterDriver", uvm_component parent);
        super.new(name, parent);
        w_done = 1'b1;
        r_done = 1'b1;
        //index = 0;
        seq_item_port2 = new("seq_item_port2", this);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase (uvm_phase phase);

    extern task drive();
    extern task send_write_address();
    extern task send_write_data();
    extern task GetWriteLength();
    extern task SendReadAddress();
    extern task GetReadData();
    extern task GetReadLength();

endclass

//
function void AxiMasterDriver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    //
    if (!uvm_config_db #(virtual interface axi_intf #(DW, AW1))::get(this, "", "m_vif", m_drv_vif)) begin
      `uvm_fatal (get_type_name (), "Didn't get handle to virtual interface if_name")
    end
   
endfunction:build_phase

task AxiMasterDriver::run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info(get_name(), "Axi_Master_Driver in run_phase", UVM_LOW);
    drive();
endtask:run_phase

task AxiMasterDriver::drive();
    `uvm_info(get_name(), "Axi_Master_Driver enters", UVM_LOW);
  while(1) begin
    @(m_drv_vif.m_drv_cb);
    if(m_drv_vif.aresetn == 1'b0) begin
        
      `uvm_info(get_name(), "Axi_Master_Driver in reset status", UVM_LOW);
      m_drv_vif.m_drv_cb.awvalid <= 1'b0;
      m_drv_vif.m_drv_cb.arvalid <= 1'b0;
      m_drv_vif.m_drv_cb.bready  <= 1'b0;
      m_drv_vif.m_drv_cb.rready  <= 1'b0;
      m_drv_vif.m_drv_cb.wlast   <= 1'b0;
      m_drv_vif.m_drv_cb.wvalid  <= 1'b0;
    end 
    else begin
      
      `uvm_info(get_name(), "Axi_Master_Driver START!!!", UVM_LOW);
      //read and write request on a concurrent method
      fork 
        //
        if(w_done == 1'b1) begin
          w_done = 1'b0;
          seq_item_port.get_next_item(w_trans);
          //
          `uvm_info(get_name(), "drive() task does MASTER_WRITE", UVM_LOW);
          fork
            send_write_address();
            send_write_data();
            GetWriteLength();
          join
          //
          seq_item_port.item_done();
          `uvm_info(get_name(), "drive() task finishes MASTER_WRITE!!!", UVM_LOW);
          w_done = 1'b1;
        end
        //
        //
        if(r_done == 1'b1) begin
          r_done = 1'b0;
          seq_item_port2.get_next_item(r_trans);
          //
          `uvm_info(get_name(), "drive() task does MASTER_READ", UVM_LOW);
          fork 
            SendReadAddress();
            GetReadData();
            GetReadLength();
          join
          //
          seq_item_port2.item_done();
          `uvm_info(get_name(), "drive() task finishes MASTER_READ!!!", UVM_LOW);
          r_done = 1'b1;
        end
      join
    end //end of else if(aresetn)
  end //end of while(1)
endtask:drive


task AxiMasterDriver::send_write_address();
  //start on each clock
  @(m_drv_vif.m_drv_cb)
    if(~m_drv_vif.aresetn) begin
      `uvm_info(get_name(), "sending write address in reset status!!!", UVM_LOW);
      AWVALID = 0;
      m_drv_vif.m_drv_cb.awvalid <= AWVALID;
      m_drv_vif.m_drv_cb.awid    <= 0;
      m_drv_vif.m_drv_cb.awaddr  <= 0;
      m_drv_vif.m_drv_cb.awlen   <= 0;
      m_drv_vif.m_drv_cb.awsize  <= 0;
      m_drv_vif.m_drv_cb.awburst <= 0;

    end
    else begin
      AWVALID = 1;
      m_drv_vif.m_drv_cb.awvalid <= AWVALID;
      m_drv_vif.m_drv_cb.awid    <= w_trans.id[7:0];
      m_drv_vif.m_drv_cb.awaddr  <= w_trans.addr;
      m_drv_vif.m_drv_cb.awlen   <= w_trans.len;
      m_drv_vif.m_drv_cb.awsize  <= w_trans.size;
      m_drv_vif.m_drv_cb.awburst <= w_trans.burst;
      //
      @(m_drv_vif.m_drv_cb)
      wait(m_drv_vif.m_drv_cb.awready)
      WriteLengthQueue.push_back(w_trans.len);
      `uvm_info(get_name(), "succeed in sending write address", UVM_LOW);
      AWVALID = 0;
      m_drv_vif.m_drv_cb.awvalid <= AWVALID;
      m_drv_vif.m_drv_cb.awid    <= 'hz;
      m_drv_vif.m_drv_cb.awaddr  <= 'hz;
      m_drv_vif.m_drv_cb.awlen   <= 'hz;
      m_drv_vif.m_drv_cb.awsize  <= 'hz;
      m_drv_vif.m_drv_cb.awburst <= 'hz;
    end

endtask:send_write_address
//
//
task AxiMasterDriver::send_write_data();
  SendWriteDataDone = 1'b0;
  //start on each clock
  @(m_drv_vif.m_drv_cb);
  if(m_drv_vif.aresetn == 1'b0) begin
    `uvm_info(get_name(), "SendWriteData() in reset status!!!", UVM_LOW);
    BREADY = 0;
    m_drv_vif.m_drv_cb.bready <= BREADY;
    m_drv_vif.m_drv_cb.wdata  <= 32'd0;
    m_drv_vif.m_drv_cb.wstrb  <= 4'd0;
    m_drv_vif.m_drv_cb.wlast  <= 1'b0;
    m_drv_vif.m_drv_cb.wvalid <= 1'b0;
  end
  else begin
    if(SendWriteDataStart == 1'b1) begin
      `uvm_info(get_name(), "SendWriteData() task STARTS!!!", UVM_LOW);
      wr_len = WriteLengthQueueDataOut + 1;
      w_trans.data = new[wr_len];
      //	
      foreach(w_trans.data[i]) begin
        @(m_drv_vif.m_drv_cb);
          BREADY = 1;
          m_drv_vif.m_drv_cb.bready <= BREADY;
          m_drv_vif.m_drv_cb.wdata  <= w_trans.data[i];
          m_drv_vif.m_drv_cb.wstrb  <= w_trans.wstrb[i];
          m_drv_vif.m_drv_cb.wlast  <= (i == wr_len-1) ? 1'b1 : 1'b0;
          m_drv_vif.m_drv_cb.wvalid <= 1'b1;
        // `uvm_info(get_name(), $sformatf("i = %d, wlast = %b", i, (i == len-1) ? 1'b1 : 1'b0), UVM_LOW);
        @(m_drv_vif.m_drv_cb);
        wait(m_drv_vif.m_drv_cb.wready)
          m_drv_vif.m_drv_cb.wlast  <= 1'b0;
          m_drv_vif.m_drv_cb.wvalid <= 1'b0;
          m_drv_vif.m_drv_cb.wdata  <= 'hz;
        `uvm_info(get_name(), "WriteData is succesfully passed down to SLAVE!!!", UVM_LOW);
      end
    
      // `uvm_info(get_name(), "write transaction finishes_a", UVM_LOW);
      @(m_drv_vif.m_drv_cb);
      wait(m_drv_vif.m_drv_cb.bvalid);
      BREADY = 0;
      m_drv_vif.m_drv_cb.bready <= BREADY;
      SendWriteDataDone = 1'b1;
    end
  end
  
endtask:send_write_data

//
task AxiMasterDriver::SendReadAddress();
  `uvm_info(get_name(), "sending read address", UVM_LOW);
  //start on each clock
  @(m_drv_vif.m_drv_cb)
    if(m_drv_vif.aresetn == 1'b0) begin
      ARVALID = 0;
      m_drv_vif.m_drv_cb.arvalid <= ARVALID;
      m_drv_vif.m_drv_cb.araddr <= 0;
      m_drv_vif.m_drv_cb.arsize  <= 0;
      m_drv_vif.m_drv_cb.arlen   <= 0;
      m_drv_vif.m_drv_cb.arburst <= 0;
      m_drv_vif.m_drv_cb.arid    <= 0;
    end
    else begin
      ARVALID = 1;
      m_drv_vif.m_drv_cb.arvalid <= ARVALID;
      m_drv_vif.m_drv_cb.araddr <= r_trans.addr;
      m_drv_vif.m_drv_cb.arsize  <= r_trans.size;
      m_drv_vif.m_drv_cb.arlen   <= r_trans.len;
      m_drv_vif.m_drv_cb.arburst <= r_trans.burst;
      m_drv_vif.m_drv_cb.arid    <= r_trans.id[7:0];
      //
      @(m_drv_vif.m_drv_cb)
      wait(m_drv_vif.m_drv_cb.arready)
      `uvm_info(get_name(), "succeed in sending read address", UVM_LOW);
      ReadLengthQueue.push_back(r_trans.len);
      ARVALID = 0;
      m_drv_vif.m_drv_cb.arvalid <= ARVALID;
      m_drv_vif.m_drv_cb.araddr  <= 'hz;
      m_drv_vif.m_drv_cb.arsize  <= 'hz;
      m_drv_vif.m_drv_cb.arlen   <= 'hz;
      m_drv_vif.m_drv_cb.arburst <= 'hz;
    end
  
endtask:SendReadAddress

//
task AxiMasterDriver::GetReadData();
  `uvm_info(get_name(), "GetReadData task is running!!!", UVM_LOW);
  @(m_drv_vif.m_drv_cb);
  if(CaptureReadDataStart == 1'b1) begin 
    RREADY = 1;
    m_drv_vif.m_drv_cb.rready <= RREADY;
    r_trans.data  = new [ReadLengthQueueDataOut + 1];
  
    for (int i=0; i < ReadLengthQueueDataOut + 1; i++) begin
      @(m_drv_vif.m_drv_cb);
      wait(m_drv_vif.m_drv_cb.rvalid);
      r_trans.data[i] <= m_drv_vif.m_drv_cb.rdata;
      r_trans.rresp  <= m_drv_vif.m_drv_cb.rresp;
      r_trans.id_rsp <= {1'b0, m_drv_vif.m_drv_cb.rid};
      r_trans.last   <= m_drv_vif.m_drv_cb.rlast;
    end
    wait(m_drv_vif.m_drv_cb.rlast);
    RREADY = 0;
    m_drv_vif.m_drv_cb.rready <= RREADY;
    CaptureReadDataDone <= 1'b1;
    `uvm_info(get_name(), "read transaction finishes", UVM_LOW);
  end
endtask:GetReadData

//
task AxiMasterDriver::GetReadLength();
  @(m_drv_vif.m_drv_cb);
  if((ReadLengthQueueFirstRead == 1'b1) && (ReadLengthQueue.size() > 0)) begin
     ReadLengthQueueDataOut <= ReadLengthQueue.pop_front();
     ReadLengthQueueFirstRead <= 1'b0;
     CaptureReadDataStart <= 1'b1;
  end
  else if((m_drv_vif.m_drv_cb.rlast & m_drv_vif.m_drv_cb.rvalid & RREADY) && (ReadLengthQueue.size() > 0)) begin
     ReadLengthQueueDataOut <= ReadLengthQueue.pop_front();
     CaptureReadDataStart <= 1'b1;
  end
  else if(CaptureReadDataDone == 1'b1) begin
    CaptureReadDataStart <= 1'b0;
  end
endtask: GetReadLength
//
//
task AxiMasterDriver::GetWriteLength();
  @(m_drv_vif.m_drv_cb);
  if((WriteLengthQueueFirstRead == 1'b1) && (WriteLengthQueue.size() > 0)) begin
     WriteLengthQueueDataOut <= WriteLengthQueue.pop_front();
     WriteLengthQueueFirstRead <= 1'b0;
     SendWriteDataStart <= 1'b1;
  end
  else if((m_drv_vif.m_drv_cb.bvalid & BREADY) && (WriteLengthQueue.size() > 0)) begin
     WriteLengthQueueDataOut <= WriteLengthQueue.pop_front();
     SendWriteDataStart <= 1'b1;
  end
  else if(SendWriteDataDone == 1'b1) begin
    SendWriteDataStart <= 1'b0;
  end
endtask: GetWriteLength

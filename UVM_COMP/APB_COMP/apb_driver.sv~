//---------------------------------------------------------------
//-- file: apb_driver.sv
//-- class: apb_driver
//---------------------------------------------------------------
//typedef apb_seq_item#(DW,AW2) REQ;
class apb_driver extends uvm_driver#(apb_seq_item#(DW,AW2));
  `uvm_component_utils(apb_driver)
  //
  virtual interface apb_intf #(DW, AW2) apb_drv_vif; // it is assigned from APB AGENT class
  REQ item;
  apb_agent_config drv_cfg; //config object
  int counter = 0;
  bit [`SLAVE_CNT-1:0] actual_pready;
  bit done, done2;
  logic [DW-1:0] rdata;
  //
parameter DEPTH = 4096; //using localparam causes error 
  logic [7:0] mem [`SLAVE_CNT-1:0][DEPTH]; // Memory declaration
  logic [DW-1:0] new_value, current_value;
  //
function new (string name ="APB Driver", uvm_component parent);
    super.new(name, parent);
endfunction:new
//
//
//
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // if (!uvm_config_db #(virtual interface apb_intf #(DW, AW2))::get(this, "", "s_vif", apb_drv_vif)) begin
      // `uvm_fatal (get_type_name (), "Didn't get handle to virtual interface apb_intf!!!")
    // end
    //
    if(drv_cfg == null) begin
      `uvm_fatal (get_type_name (), "APB_AGENT_CONFIG OBJECT is NULL!!!")
    end
    else begin
     
    end
    //
  endfunction:build_phase
  //
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
      fork
      begin
	      reset_all();
      end
      //
      begin
      if(drv_cfg.active == UVM_ACTIVE) begin //APB MASTER
        // master_task();
      end
      else begin //APB SLAVE
        slave_task();
      end
      end
      join_none
  endtask
    
    //---------------------------------------
  extern virtual task reset_all();
  // extern virtual task master_task();
  extern virtual task slave_task();
  extern virtual task slave_handle_packet(REQ packet);
  extern virtual function void mem_init();
  extern virtual task mem_access(int sel, bit wr_en,
	 logic [3:0] be, logic [11:0] addr, logic [31:0] data_in, output logic [31:0] data_o);
  //extern virtual task setup_phase(REQ ApbReq);
  //extern virtual task access_phase(REQ ApbRsp);
  
endclass
//**************************************************************************************
//***********************************MAIN TASKS*****************************************
//**************************************************************************************
//Initiate all control signals when the reset is active
//Run time: run until the end of the simulation
task apb_driver::reset_all();
  wait (~apb_drv_vif.presetn) begin
      if(drv_cfg.active == UVM_PASSIVE) begin
	apb_drv_vif.s_drv_cb.pready <= {`SLAVE_CNT{1'b0}};
	apb_drv_vif.s_drv_cb.pslverr <= {`SLAVE_CNT{1'b0}};
      end
    mem_init();
  end

  while (1) begin
    @(negedge apb_drv_vif.presetn);
	@(apb_drv_vif.s_drv_cb iff ~apb_drv_vif.presetn); //Reset of DUT is synchronize reset
	      if(drv_cfg.active == UVM_PASSIVE) begin
		apb_drv_vif.s_drv_cb.pready <= {`SLAVE_CNT{1'b0}};
		apb_drv_vif.s_drv_cb.pslverr <= {`SLAVE_CNT{1'b0}};
	      end
	    mem_init();
	//@(posedge apb_drv_vif.presetn);
	//`uvm_info (get_type_name(), "END of reset", UVM_HIGH)
  end

endtask: reset_all
//
function void apb_driver::mem_init();
for(int i = 0; i < `SLAVE_CNT; i++) begin
for(int j=0; j < DEPTH; j++) begin
mem[i][j] = 0;
end
end
endfunction	
//
//definition of mem_access function
//
task apb_driver::mem_access(
	input int sel,
	input bit wr_en,
	input logic [3:0] be,
	input logic [11:0] addr,
	input logic [31:0] data_in,
	output logic [31:0] data_o
);	
	//big-endian
	begin
		if(wr_en) begin
			mem[sel][addr+0] = (be[3]) ? data_in[31:24] : mem[sel][addr+0];
			mem[sel][addr+1] = (be[2]) ? data_in[23:16] : mem[sel][addr+1];
			mem[sel][addr+2] = (be[1]) ? data_in[15:08] : mem[sel][addr+2];
			mem[sel][addr+3] = (be[0]) ? data_in[07:00] : mem[sel][addr+3];
			//data_o = 32'd0;
		end
		else begin
			data_o = {mem[sel][addr+0], mem[sel][addr+1], mem[sel][addr+2], mem[sel][addr+3]};
		end
	end
endtask
//
//definition of slave task
//
task apb_driver::slave_task();
forever begin
	@(posedge apb_drv_vif.presetn);
	#(`CLK_CYCLE);
	while(apb_drv_vif.presetn) begin
		seq_item_port.get_next_item(item);
		slave_handle_packet(item);
		seq_item_port.item_done();

	end
end

endtask
//
//
//
task apb_driver::slave_handle_packet(REQ packet);
counter = 0;
fork
begin //THREAD_1
@(negedge apb_drv_vif.presetn);
`uvm_info(get_type_name(), $sformatf("PRESET_N EDGE-SENSITIVE!!!"), UVM_HIGH);
end
//
begin//THREAD_2
fork

//
forever begin //SUB_THREAD_2_1
 `uvm_info(get_type_name(), $sformatf("time_1: %0t ns", $time), UVM_HIGH)
//iterates psel in turn to determine selected slave
@(apb_drv_vif.s_drv_cb iff |apb_drv_vif.s_drv_cb.psel);
foreach(apb_drv_vif.s_drv_cb.psel[i]) begin
if(apb_drv_vif.s_drv_cb.psel[i]) begin//PSEL
	if(apb_drv_vif.s_drv_cb.pwrite && apb_drv_vif.s_drv_cb.penable) begin
	mem_access(i, 1'b1, apb_drv_vif.s_drv_cb.pstrb, apb_drv_vif.s_drv_cb.paddr[11:0], apb_drv_vif.s_drv_cb.pwdata, rdata);
	done2 = 1'b1;
	`uvm_info(get_type_name(),
	$sformatf("[APB WRITE_TRANSFER]: paddr=0x%0h WriteData=0x%08h Pstrb=0x%0h\n cur_mem = 0x%08h new_mem = 0x%08h",
	apb_drv_vif.s_drv_cb.paddr, apb_drv_vif.s_drv_cb.pwdata, apb_drv_vif.s_drv_cb.pstrb, current_value, new_value), UVM_HIGH);
	//
	end
else if(~apb_drv_vif.s_drv_cb.pwrite && ~apb_drv_vif.s_drv_cb.penable) begin
	mem_access(i, 1'b0, apb_drv_vif.s_drv_cb.pstrb, apb_drv_vif.s_drv_cb.paddr[11:0], apb_drv_vif.s_drv_cb.pwdata, rdata);
	apb_drv_vif.s_drv_cb.prdata[i] <= rdata;
	done2 = 1'b1;
	`uvm_info(get_type_name(), $sformatf("[APB READ_TRANSFER]: paddr=0x%0h ReadData=0x%08h",
	apb_drv_vif.s_drv_cb.paddr, rdata), UVM_HIGH);
end
else begin
	done2 = 1'b0;
end
//
end//end of PSEL
end //end of foreach
if(done2) break;
end//end of SUB_THREAD_2_1
//
forever begin //SUB_THREAD_2_2
@(apb_drv_vif.s_drv_cb iff |apb_drv_vif.s_drv_cb.psel);
//packet.print();
`uvm_info(get_type_name(), $sformatf("counter = %0d", counter), UVM_HIGH);
`uvm_info(get_type_name(), $sformatf("preadyDelay = %0d", packet.preadyDelay), UVM_HIGH);
foreach(apb_drv_vif.s_drv_cb.psel[i]) begin
if(apb_drv_vif.s_drv_cb.psel[i]) begin //PSEL
	if(packet.pready[i]) begin
	actual_pready = packet.pready;
	done = 1'b1;
	end
	else if(counter == packet.preadyDelay)begin
	actual_pready[i] = 1'b1;
	done = 1'b1;
	end
	else begin
	actual_pready = packet.pready;
	done = 1'b0;
	end
	//
	apb_drv_vif.s_drv_cb.pready <= actual_pready;
	// usually 1 (ready)
	apb_drv_vif.s_drv_cb.pslverr <= packet.pslverr; // usually 0 (no error)
	//
	if(~packet.pready[i] && apb_drv_vif.s_drv_cb.penable) counter++;
end//end of PSEL
end//end of foreach
if(done) begin
break;
end

end //end of SUB_THREAD_2_2
join
end//end of THREAD_2 
join_any
disable fork;
endtask


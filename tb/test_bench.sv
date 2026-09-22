//===========================================================================
//--Project: AXI to APB IP
//--File: test_bench.sv
//--Author: Nguyen Ngoc Man
//--Description: tb
//===========================================================================
import uvm_pkg::*;
import axi_pkg::*; //AXI parameter 
import apb_pkg::*; //APB parameter 
import test_pkg::*;//get test name
typedef virtual interface apb_intf #(DW2, AW2, `SLAVE_CNT) apb_if;
//
module tb;
//----------------------------------------
//host signals
//----------------------------------------
bit clk_tb;
//----------------------------------------
//gen clk
//----------------------------------------
initial begin
    forever #(`CLK_CYCLE/2) clk_tb = ~clk_tb;
end
//----------------------------------------
//-------------- INTERFACE 
//----------------------------------------
axi_intf #(.AXI_DW(DW1), .AXI_AW(AW1)) AXI_IF(); //lack of symbol "()" causes error
//--1: APB master module interface
apb_intf #(.APB_DW(DW2), .APB_AW(AW2), .SLAVE_NUM(`SLAVE_CNT)) APB_IF (clk_tb);
//----------------------------------------
//---------------APB variables
//----------------------------------------
//----using below signals to interact will lose purpose of system verilog interface
//----because, when using SV interface, we use only one line to connect signals between TB and DUT
//logic presetn_tb;
//logic [`SLAVE_CNT-1:0] psel_tb;
//logic penable_tb;
//logic pwrite_tb;
//logic [2:0] pprot_tb;
//logic [DW2/8-1:0] pstrb_tb;
//logic [AW2-1:0] paddr_tb;
//logic [DW2-1:0] pwdata_tb;
//logic [`SLAVE_CNT-1:0][DW2-1:0] prdata_tb;
//logic [`SLAVE_CNT-1:0] pready_tb;
//logic [`SLAVE_CNT-1:0] pslverr_tb;
//
assign AXI_IF.aclk = clk_tb;
assign APB_IF.presetn = AXI_IF.aresetn;//continous assignment
  //----------------------------------------
  //instantiate DUT interface
  //----------------------------------------
x2p_top dut_top (
  .axi_if(AXI_IF.DUT),
  .apb_if(APB_IF.DUT)
);

  //functional coverage
  axi_cov_top axi_cov_top();
  axi_checker_top axi_checker_top();
  //--------------------------------------------
  //--include rst assertion module 
  //--------------------------------------------
//`include "assertion_instance_module.sv"
  //--------------------------------------------
  //SET virtual interface 
  //--------------------------------------------
    initial begin
      uvm_config_db#(virtual axi_intf #(DW1, AW1))::set(null, "uvm_test_top*", "m_vif", AXI_IF);
      uvm_config_db#(apb_if)::set(null, "uvm_test_top*", "apb_vif", APB_IF);
    end
   //------------------------------------------------------------
   //---------------------RUN SIMULATION
   //------------------------------------------------------------
   initial begin
    run_test();
   end 
endmodule

  //global signals
  //.aclk(AXI.aclk),
  //.aresetn(AXI.aresetn),
  ////write addr channel
  //.awid(AXI.awid[7:0]),       //MSB is fixed
  //.awvalid(AXI.awvalid),
  //.awaddr(AXI.awaddr),   //2 bit used for handling byte, halfword, word
  //.awlen(AXI.awlen),     //a number of transfers in one burst, possible 8-bit width
  //.awsize(AXI.awsize),    //000: byte, 001: half word, 010: word, etc
  //.awburst(AXI.awburst),    //00: fixed, 01: incr, 10: wrap, 11:reserved
  //.awprot(AXI.awprot),
  //.awready(AXI.awready),
//
  ////write data channel
  //.wvalid(AXI.wvalid),
  //.wlast(AXI.wlast),
  //.wdata(AXI.wdata),
  //.wstrb(AXI.wstrb),      //used for unaligned address
  //.wready(AXI.wready),
//
  ////write response channel
  //.bready(AXI.bready),
  //.bvalid(AXI.bvalid),
  //.bid(AXI.bid),       //must match awid signal
  //.bresp(AXI.bresp),     //OKAY, EXOKAY, SLVERR, DECERR
//
  ////read addr channel
  //.araddr(AXI.araddr),     //2 bit used for handling byte, halfword, word
  //.arid(AXI.arid[7:0]),
  //.arsize(AXI.arsize),
  //.arlen(AXI.arlen),
  //.arburst(AXI.arburst),
  //.arprot(AXI.arprot),
  //.arvalid(AXI.arvalid),
  //.arready(AXI.arready),
//
  ////read data channel
  //.rdata(AXI.rdata),
  //.rresp(AXI.rresp),         //OKAY, EXOKAY, SLVERR, DECERR
  //.rid(AXI.rid),           //must match arid signal
  //.rlast(AXI.rlast),
  //.rvalid(AXI.rvalid),
  //.rready(AXI.rready),        //

  //APB Interface
  //.pclk(clk_tb),        
  //.preset_n(presetn_tb),
  //.pprot(pprot_tb),
  //.pready(pready_tb)   ,
  //.pslverr(pslverr_tb) ,
  //.psel(psel_tb)	      ,
  //.penable(penable_tb) ,
  //.pwrite(pwrite_tb)	  ,
  //.pstrb(pstrb_tb)	    ,
  //.paddr(paddr_tb)		  ,
  //.pwdata(pwdata_tb)   ,
  //.prdata(prdata_tb)	    
  //

    //
    //generate 
      //for (genvar i = 0; i < `SLAVE_CNT; i++) begin  
        //initial begin
            //uvm_config_db#(apb_if)::set(null, "uvm_test_top*", $sformatf("apb_vif_%0d", i), APB_IF[i]);
        //end
      //end
    //endgenerate
    //-------------------------------------------------------------------------
    //------------------------APB INTERFACE ASSIGNMENT
    //-------------------------------------------------------------------------
//generate
  //for (genvar i = 0; i < `SLAVE_CNT; i++) begin : ASSIGN_INTERFACE_LOOP 
    //assign APB_IF[i].presetn = presetn_tb;
    //assign APB_IF[i].psel    = psel_tb[i];
    //assign APB_IF[i].penable = penable_tb;
    //assign APB_IF[i].pwrite  = pwrite_tb;
    //assign APB_IF[i].paddr   = paddr_tb;
    //assign APB_IF[i].pstrb   = pstrb_tb;
    //assign APB_IF[i].pwdata  = pwdata_tb;
    //assign pready_tb[i]  = APB_IF[i].pready;
    //assign pslverr_tb[i] = APB_IF[i].pslverr;
    //assign prdata_tb[i]  = APB_IF[i].prdata;
  //end: ASSIGN_INTERFACE_LOOP
//endgenerate
//-----assign virtual interface handle to physical interface
//generate
  //for (genvar i = 0; i < `SLAVE_CNT; i++) begin : ASSIGN_INTERFACE_LOOP 
    //assign APB_IF[i].presetn = APB_MST_IF.presetn;
    //assign APB_IF[i].psel    = APB_MST_IF.psel[i];
    //assign APB_IF[i].penable = APB_MST_IF.penable;
    //assign APB_IF[i].pwrite  = APB_MST_IF.pwrite;
    //assign APB_IF[i].paddr   = APB_MST_IF.paddr;
    //assign APB_IF[i].pstrb   = APB_MST_IF.pstrb;
    //assign APB_IF[i].pwdata  = APB_MST_IF.pwdata;
    //assign APB_MST_IF.pready[i]  = APB_IF[i].pready;
    //assign APB_MST_IF.pslverr[i] = APB_IF[i].pslverr;
    //assign APB_MST_IF.prdata[i]  = APB_IF[i].prdata;
  //end: ASSIGN_INTERFACE_LOOP
//endgenerate

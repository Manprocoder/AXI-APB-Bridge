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
typedef virtual interface apb_intf #(DW2, AW2, 1) apb_if;
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
axi_intf #(.AXI_DW(DW1), .AXI_AW(AW1)) AXI(clk_tb); //lack of symbol "()" causes error
//--1: APB master module interface
apb_intf #(.APB_DW(DW2), .APB_AW(AW2), .SLAVE_NUM(1)) APB [`SLAVE_CNT] (clk_tb);
//----------------------------------------
//---------------APB variables
//----------------------------------------
logic presetn_tb;
logic [`SLAVE_CNT-1:0] psel_tb;
logic penable_tb;
logic pwrite_tb;
logic [2:0] pprot_tb;
logic [DW2/8-1:0] pstrb_tb;
logic [AW2-1:0] paddr_tb;
logic [DW2-1:0] pwdata_tb;
logic [`SLAVE_CNT-1:0][DW2-1:0] prdata_tb;
logic [`SLAVE_CNT-1:0] pready_tb;
logic [`SLAVE_CNT-1:0] pslverr_tb;
//
assign presetn_tb = AXI.aresetn;//continous assignment

  //----------------------------------------
  //instantiate DUT interface
  //----------------------------------------
  x2p_top dut_top (
  //global signals
  .aclk(AXI.aclk),
  .aresetn(AXI.aresetn),
  //write addr channel
  .awid(AXI.awid[7:0]),       //MSB is fixed
  .awvalid(AXI.awvalid),
  .awaddr(AXI.awaddr),   //2 bit used for handling byte, halfword, word
  .awlen(AXI.awlen),     //a number of transfers in one burst, possible 8-bit width
  .awsize(AXI.awsize),    //000: byte, 001: half word, 010: word, etc
  .awburst(AXI.awburst),    //00: fixed, 01: incr, 10: wrap, 11:reserved
  .awprot(AXI.awprot),
  .awready(AXI.awready),

  //write data channel
  .wvalid(AXI.wvalid),
  .wlast(AXI.wlast),
  .wdata(AXI.wdata),
  .wstrb(AXI.wstrb),      //used for unaligned address
  .wready(AXI.wready),

  //write response channel
  .bready(AXI.bready),
  .bvalid(AXI.bvalid),
  .bid(AXI.bid),       //must match awid signal
  .bresp(AXI.bresp),     //OKAY, EXOKAY, SLVERR, DECERR

  //read addr channel
  .araddr(AXI.araddr),     //2 bit used for handling byte, halfword, word
  .arid(AXI.arid[7:0]),
  .arsize(AXI.arsize),
  .arlen(AXI.arlen),
  .arburst(AXI.arburst),
  .arprot(AXI.arprot),
  .arvalid(AXI.arvalid),
  .arready(AXI.arready),

  //read data channel
  .rdata(AXI.rdata),
  .rresp(AXI.rresp),         //OKAY, EXOKAY, SLVERR, DECERR
  .rid(AXI.rid),           //must match arid signal
  .rlast(AXI.rlast),
  .rvalid(AXI.rvalid),
  .rready(AXI.rready),        //

  //APB Interface
  .pclk(clk_tb),        
  .preset_n(presetn_tb),
  .pprot(pprot_tb),
  .pready(pready_tb)   ,
  .pslverr(pslverr_tb) ,
  .psel(psel_tb)	      ,
  .penable(penable_tb) ,
  .pwrite(pwrite_tb)	  ,
  .pstrb(pstrb_tb)	    ,
  .paddr(paddr_tb)		  ,
  .pwdata(pwdata_tb)   ,
  .prdata(prdata_tb)	    
  //
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
      uvm_config_db#(virtual axi_intf #(DW1, AW1))::set(null, "uvm_test_top*", "m_vif", AXI);
    end
    //
    generate 
      for (genvar i = 0; i < `SLAVE_CNT; i++) begin  
          initial begin
            uvm_config_db#(apb_if)::set(null, "uvm_test_top*", $sformatf("apb_vif_%0d", i), APB[i]);
        end
      end
    endgenerate
    //-------------------------------------------------------------------------
    //------------------------APB INTERFACE ASSIGNMENT
    //-------------------------------------------------------------------------
generate
  for (genvar i = 0; i < `SLAVE_CNT; i++) begin : ASSIGN_INTERFACE_LOOP 
    assign APB[i].presetn = presetn_tb;
    assign APB[i].psel    = psel_tb[i];
    assign APB[i].penable = penable_tb;
    assign APB[i].pwrite  = pwrite_tb;
    assign APB[i].paddr   = paddr_tb;
    assign APB[i].pstrb   = pstrb_tb;
    assign APB[i].pwdata  = pwdata_tb;
    assign pready_tb[i]  = APB[i].pready;
    assign pslverr_tb[i] = APB[i].pslverr;
    assign prdata_tb[i]  = APB[i].prdata;
  end: ASSIGN_INTERFACE_LOOP
  //if(`SLAVE_CNT == 1) begin  
    //assign APB[0].presetn = presetn_tb;
    //assign APB[0].psel    = psel_tb[0];
    //assign APB[0].penable = penable_tb;
    //assign APB[0].pwrite  = pwrite_tb;
    //assign APB[0].paddr   = paddr_tb;
    //assign APB[0].pstrb   = pstrb_tb;
    //assign APB[0].pwdata  = pwdata_tb;
    //assign pready_tb[0]  = APB[0].pready;
    //assign pslverr_tb[0] = APB[0].pslverr;
    //assign prdata_tb[0]  = APB[0].prdata;
  //end
  //else if(`SLAVE_CNT == 2) begin
    //assign APB[0].presetn = presetn_tb;
    //assign APB[0].psel    = psel_tb[0];
    //assign APB[0].penable = penable_tb;
    //assign APB[0].pwrite  = pwrite_tb;
    //assign APB[0].paddr   = paddr_tb;
    //assign APB[0].pstrb   = pstrb_tb;
    //assign APB[0].pwdata  = pwdata_tb;
    //assign pready_tb[0]  = APB[0].pready;
    //assign pslverr_tb[0] = APB[0].pslverr;
    //assign prdata_tb[0]  = APB[0].prdata;
    ////
    //assign APB[1].presetn = presetn_tb;
    //assign APB[1].psel    = psel_tb[1];
    //assign APB[1].penable = penable_tb;
    //assign APB[1].pwrite  = pwrite_tb;
    //assign APB[1].paddr   = paddr_tb;
    //assign APB[1].pstrb   = pstrb_tb;
    //assign APB[1].pwdata  = pwdata_tb;
    //assign pready_tb[1]  = APB[1].pready;
    //assign pslverr_tb[1] = APB[1].pslverr;
    //assign prdata_tb[1]  = APB[1].prdata;
  //end
  //else if(`SLAVE_CNT == 3) begin
    //assign APB[0].presetn = presetn_tb;
    //assign APB[0].psel    = psel_tb[0];
    //assign APB[0].penable = penable_tb;
    //assign APB[0].pwrite  = pwrite_tb;
    //assign APB[0].paddr   = paddr_tb;
    //assign APB[0].pstrb   = pstrb_tb;
    //assign APB[0].pwdata  = pwdata_tb;
    //assign pready_tb[0]  = APB[0].pready;
    //assign pslverr_tb[0] = APB[0].pslverr;
    //assign prdata_tb[0]  = APB[0].prdata;
    ////
    //assign APB[1].presetn = presetn_tb;
    //assign APB[1].psel    = psel_tb[1];
    //assign APB[1].penable = penable_tb;
    //assign APB[1].pwrite  = pwrite_tb;
    //assign APB[1].paddr   = paddr_tb;
    //assign APB[1].pstrb   = pstrb_tb;
    //assign APB[1].pwdata  = pwdata_tb;
    //assign pready_tb[1]  = APB[1].pready;
    //assign pslverr_tb[1] = APB[1].pslverr;
    //assign prdata_tb[1]  = APB[1].prdata;
    ////
    //assign APB[2].presetn = presetn_tb;
    //assign APB[2].psel    = psel_tb[2];
    //assign APB[2].penable = penable_tb;
    //assign APB[2].pwrite  = pwrite_tb;
    //assign APB[2].paddr   = paddr_tb;
    //assign APB[2].pstrb   = pstrb_tb;
    //assign APB[2].pwdata  = pwdata_tb;
    //assign pready_tb[2]  = APB[2].pready;
    //assign pslverr_tb[2] = APB[2].pslverr;
    //assign prdata_tb[2]  = APB[2].prdata;
  //end
  //else if(`SLAVE_CNT == 4) begin
    //assign APB[0].presetn = presetn_tb;
    //assign APB[0].psel    = psel_tb[0];
    //assign APB[0].penable = penable_tb;
    //assign APB[0].pwrite  = pwrite_tb;
    //assign APB[0].paddr   = paddr_tb;
    //assign APB[0].pstrb   = pstrb_tb;
    //assign APB[0].pwdata  = pwdata_tb;
    //assign pready_tb[0]  = APB[0].pready;
    //assign pslverr_tb[0] = APB[0].pslverr;
    //assign prdata_tb[0]  = APB[0].prdata;
    ////
    //assign APB[1].presetn = presetn_tb;
    //assign APB[1].psel    = psel_tb[1];
    //assign APB[1].penable = penable_tb;
    //assign APB[1].pwrite  = pwrite_tb;
    //assign APB[1].paddr   = paddr_tb;
    //assign APB[1].pstrb   = pstrb_tb;
    //assign APB[1].pwdata  = pwdata_tb;
    //assign pready_tb[1]  = APB[1].pready;
    //assign pslverr_tb[1] = APB[1].pslverr;
    //assign prdata_tb[1]  = APB[1].prdata;
    ////
    //assign APB[2].presetn = presetn_tb;
    //assign APB[2].psel    = psel_tb[2];
    //assign APB[2].penable = penable_tb;
    //assign APB[2].pwrite  = pwrite_tb;
    //assign APB[2].paddr   = paddr_tb;
    //assign APB[2].pstrb   = pstrb_tb;
    //assign APB[2].pwdata  = pwdata_tb;
    //assign pready_tb[2]  = APB[2].pready;
    //assign pslverr_tb[2] = APB[2].pslverr;
    //assign prdata_tb[2]  = APB[2].prdata;
    ////
    //assign APB[3].presetn = presetn_tb;
    //assign APB[3].psel    = psel_tb[3];
    //assign APB[3].penable = penable_tb;
    //assign APB[3].pwrite  = pwrite_tb;
    //assign APB[3].paddr   = paddr_tb;
    //assign APB[3].pstrb   = pstrb_tb;
    //assign APB[3].pwdata  = pwdata_tb;
    //assign pready_tb[3]  = APB[3].pready;
    //assign pslverr_tb[3] = APB[3].pslverr;
    //assign prdata_tb[3]  = APB[3].prdata;
  //end
  //end: DO_ASSIGN
endgenerate
   //------------------------------------------------------------
   //---------------------RUN SIMULATION
   //------------------------------------------------------------
   initial begin
    run_test();
   end 
endmodule


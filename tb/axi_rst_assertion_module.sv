//===================================================================================
//--Project: Design And Verify AXI_APB Bridge
//===================================================================================
//===================================================================================
// File name: axi_assertion_module.sv	
// Module:   axi_assertion 
//===================================================================================
//--Description: this module checks DUT's behavior
//===================================================================================
import parameter_pkg::*;
//
module axi_rst_assertion;
logic aclk;
logic aresetn;
//fifo pointers
//req
logic [REQ_POINTER_WIDTH:0] wreq_fifo_wptr;
logic [REQ_POINTER_WIDTH:0] wreq_fifo_rptr;
logic [REQ_POINTER_WIDTH:0] rreq_fifo_wptr;
logic [REQ_POINTER_WIDTH:0] rreq_fifo_rptr;
//data
logic [DATA_POINTER_WIDTH:0] wdata_fifo_wptr;
logic [DATA_POINTER_WIDTH:0] wdata_fifo_rptr;
logic [DATA_POINTER_WIDTH:0] rdata_fifo_wptr;
logic [DATA_POINTER_WIDTH:0] rdata_fifo_rptr;
//req
logic [REQ_POINTER_WIDTH:0] brsp_fifo_wptr;
logic [REQ_POINTER_WIDTH:0] brsp_fifo_rptr;
//axi transaction controller
logic [7:0] bid_reg;
//axi counter module
logic [7:0] transfer_cnt;
//
//------------------------------------------------------------
//-----------------SIGNALs ASSIGNMENT
//------------------------------------------------------------
assign aclk = dut_top.aclk;
assign aresetn = dut_top.aresetn;
assign wreq_fifo_wptr = dut_top.axi_slv_inst.aw_sfifo.w_pointer;
assign wreq_fifo_rptr = dut_top.axi_slv_inst.aw_sfifo.r_pointer;
//
assign rreq_fifo_wptr = dut_top.axi_slv_inst.ar_sfifo.w_pointer;
assign rreq_fifo_rptr = dut_top.axi_slv_inst.ar_sfifo.r_pointer;
//
assign wdata_fifo_wptr = dut_top.axi_slv_inst.wd_sfifo.w_pointer;
assign wdata_fifo_rptr = dut_top.axi_slv_inst.wd_sfifo.r_pointer;
//
assign rdata_fifo_wptr = dut_top.axi_slv_inst.rd_sfifo.w_pointer;
assign rdata_fifo_rptr = dut_top.axi_slv_inst.rd_sfifo.r_pointer;
//
assign brsp_fifo_wptr = dut_top.axi_slv_inst.bchannel_sfifo.w_pointer;
assign brsp_fifo_rptr = dut_top.axi_slv_inst.bchannel_sfifo.r_pointer;
//
assign bid_reg = dut_top.axi_slv_inst.bid_reg;
assign transfer_cnt = dut_top.cnt_inst.transfer_cnt;
//------------------------------------------------------------
//-----------------PROPERTY
//------------------------------------------------------------
//DEFINE
property chk_rst(clk, rst, value);
    @(posedge clk)
    (rst == 1'b0) |=> (value == 0);
endproperty
//APPLY
//--1
assert property(chk_rst(aclk, aresetn, wreq_fifo_wptr))
$error("Write pointer of AXI write request fifo is not 0 after reset");
//--2
assert property(chk_rst(aclk, aresetn, wreq_fifo_rptr))
$error("Read pointer of AXI write request fifo is not 0 after reset");
//--3
assert property(chk_rst(aclk, aresetn, rreq_fifo_wptr))
$error("Write pointer of AXI read request fifo is not 0 after reset");
//--4
assert property(chk_rst(aclk, aresetn, rreq_fifo_rptr))
$error("Read pointer of AXI read request fifo is not 0 after reset");
//--5
assert property(chk_rst(aclk, aresetn, wdata_fifo_wptr))
$error("Write pointer of AXI write data fifo is not 0 after reset");
//--6
assert property(chk_rst(aclk, aresetn, wdata_fifo_rptr))
$error("Read pointer of AXI write data fifo is not 0 after reset");
//--7
assert property(chk_rst(aclk, aresetn, rdata_fifo_wptr))
$error("Write pointer of AXI read data fifo is not 0 after reset");
//--8
assert property(chk_rst(aclk, aresetn, rdata_fifo_rptr))
$error("Read pointer of AXI read data fifo is not 0 after reset");
//--9
assert property(chk_rst(aclk, aresetn, brsp_fifo_wptr))
$error("Write pointer of AXI write response fifo is not 0 after reset");
//--10
assert property(chk_rst(aclk, aresetn, brsp_fifo_rptr))
$error("Read pointer of AXI write response fifo is not 0 after reset");
//--11
assert property(chk_rst(aclk, aresetn, bid_reg))
$error("Bid register is not 0 after reset");
//--12
assert property(chk_rst(aclk, aresetn, transfer_cnt))
$error("Transfer_cnt of Counter submodule is not 0 after reset");
endmodule
//
//


//===================================================================================
//--Project: Design And Verify AXI_APB Bridge
//===================================================================================
//===================================================================================
// File name: apb_rst_assertion_module.sv	
// Module:   apb_rst_assertion 
//===================================================================================
//--Description: this module checks DUT's behavior
//===================================================================================
module apb_rst_assertion;
logic pclk;
logic presetn;
//
logic [`SLAVE_CNT-1:0] true_psel_reg;
logic false_psel_reg;
logic [1:0] apb_cs;
//------------------------------------------------------------
//-----------------SIGNALs ASSIGNMENT
//------------------------------------------------------------
assign pclk = dut_top.pclk;
assign presetn = dut_top.presetn;
assign true_psel_reg = dut_top.apb_mst_inst.true_psel_reg;
assign false_psel_reg = dut_top.apb_mst_inst.false_psel_reg;
assign apb_cs = dut_top.apb_mst_inst.apb_cs;
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
assert property(chk_rst(pclk, presetn, true_psel_reg))
$error("true_psel_reg of APB_MASTER module is not 0 after reset");
//--2
assert property(chk_rst(pclk, presetn, false_psel_reg))
$error("false_psel_reg of APB_MASTER module is not 0 after reset");
//--3
assert property(chk_rst(pclk, presetn, apb_cs))
$error("apb_cs of APB_MASTER module is not IDLE state after reset");
endmodule

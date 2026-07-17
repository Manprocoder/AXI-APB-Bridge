//===========================================================================
//--Project: AXI to APB IP
//--File: axi_param.sv 
//--Author: Nguyen Ngoc Man
//--Description: DW, AW  
//===========================================================================
parameter DW1 = 32;
parameter AW1 = 32;
typedef enum bit [1:0] {FIXED, INCR, WRAP, RESERVED} burst_name;
typedef enum logic [1:0] {OKAY, NO_USE, PSLVERR, DECERR} resp_name;
  


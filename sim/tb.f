//===========================================================================
//--Project: AXI to APB IP
//--File: tb.f
//--Author: Nguyen Ngoc Man
//--Description: includes AXI VIP, APB VIP, environment and testbench 
//===========================================================================

+incdir+${AXI_TO_APB_VIP_VERIF_PATH}/testcases
+incdir+${AXI_TO_APB_VIP_VERIF_PATH}/sequences
+incdir+${AXI_TO_APB_VIP_VERIF_PATH}/tb


// Compilation VIP design (agent) list
//-f ${AXI_TO_APB_VIP_ROOT}/apb_vip/apb_vip.f
//-f ${AXI_TO_APB_VIP_ROOT}/axi_vip/axi_vip.f
-f ${AXI_TO_APB_VIP_VERIF_PATH}/apb_vip/apb_vip.f
-f ${AXI_TO_APB_VIP_VERIF_PATH}/axi_vip/axi_vip.f

// Functional coverage modules
${AXI_TO_APB_VIP_VERIF_PATH}/tb/axi_cov.sv
${AXI_TO_APB_VIP_VERIF_PATH}/tb/axi_cov_top.sv


// AXI protocol checker modules
${AXI_TO_APB_VIP_VERIF_PATH}/tb/axi_checker.sv
${AXI_TO_APB_VIP_VERIF_PATH}/tb/axi_checker_top.sv


// Compilation Environment
${AXI_TO_APB_VIP_VERIF_PATH}/tb/env_pkg.sv
${AXI_TO_APB_VIP_VERIF_PATH}/sequences/seq_pkg.sv
${AXI_TO_APB_VIP_VERIF_PATH}/testcases/test_pkg.sv
${AXI_TO_APB_VIP_VERIF_PATH}/tb/test_bench.sv

//====================================================
//--Project: Design and Verify AXI_to_APB bridge
//--File: apb_if.sv
//--Author: Nguyen Ngoc Man
//--Description: APB4 virtual interface
//====================================================
interface apb_intf (input logic pclk);
parameter APB_DW = 32;
parameter APB_AW = 32;
parameter SLAVE_NUM = 1;
//
//
//
  logic presetn;
  logic [SLAVE_NUM-1:0] psel;
  logic penable;
  logic pwrite;
  logic [2:0] pprot;
  logic [APB_DW/8-1:0] pstrb;
  logic [APB_AW-1:0] paddr;
  logic [APB_DW-1:0] pwdata;
  logic [SLAVE_NUM-1:0][APB_DW-1:0] prdata;
  logic [SLAVE_NUM-1:0] pready;
  logic [SLAVE_NUM-1:0] pslverr;
  // =====================================
  // SVA Protocol Checks
  // =====================================
  genvar i;
    generate;
    for(i = 0; i < SLAVE_NUM; i++) begin : apb_slave_checks
      //(1)
      property psel_onehot;
        @(posedge pclk) disable iff (!presetn)
          $onehot0(psel);
      endproperty
      assert property (psel_onehot)
      else begin
        $error("PSEL_SVA: multiple slaves selected at the same time!!! Value = %0b", psel);
      end
      //reset all signals
      //DEFINE
      property reset_all_signals;
        @(posedge pclk) disable iff (!presetn)
        (presetn == 0) |=> (psel == 0 && penable == 0 && paddr == 0);
      endproperty
      //DO
      assert property (reset_all_signals)
      else begin
        $error("[RESEL_ALL_SIGNALS]: all APB signals are not properly reset!!!");
      end
      //
      //(2)
      // access_phase: if psel[i] and !penable, then penable must go high next cycle
      property access_phase;
        @(posedge pclk) disable iff (!presetn)
          (psel[i] && !penable) |=> penable;
      endproperty
      assert property(access_phase)
      else begin
        $error("APB[%0d]: penable not asserted in ACCESS phase", i);
      end
      //
      //(3)
      // Transfer Completion only when pready[i] is asserted
      //DEFINE
      property complete_with_pready;
        @(posedge pclk) disable iff (!presetn)
          (psel[i] && penable && ~pready[i]) |=> penable;
      endproperty
      //DO
      assert property(complete_with_pready)
      else begin
        $error("APB_SVA[%0d]: Transfer ended without pready", i);
      end
      //
      //(4)
      //
      //DEFINE
      property penable_deassert;
        @(posedge pclk) disable iff (!presetn)
          (psel[i] && penable && pready[i]) |=> !penable;
      endproperty
      //DO
      assert property(penable_deassert)
      else begin
        $error("APB[%0d]: Penable also ASSERT as pready is high", i);
      end
    end
  endgenerate
  //===========================================================================
  //-----------------------------APB Clocking blocks
  //===========================================================================
  //---driver
  clocking s_drv_cb @(posedge pclk);
      input psel, penable, pwrite, pstrb, paddr, pwdata, pprot;
      output prdata, pready, pslverr;
  endclocking
  //---monitor
  clocking s_mon_cb @(posedge pclk);
      input psel, penable, pwrite, paddr, pwdata, pstrb, prdata, pready, pslverr, pprot;
  endclocking
endinterface



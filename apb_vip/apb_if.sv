//
//
//
interface apb_intf (input logic pclk);
parameter DW = 32;
parameter AW2 = 32;
//apb channel
  logic presetn;
  logic [`SLAVE_CNT-1:0] psel;
  logic penable;
  logic pwrite;
  logic [2:0] pprot;
  logic [3:0] pstrb;
  logic [AW2-1:0] paddr;
  logic [DW-1:0] pwdata;
  logic [`SLAVE_CNT-1:0][DW-1:0] prdata;
  logic [`SLAVE_CNT-1:0] pready;
  logic [`SLAVE_CNT-1:0] pslverr;
  //
  //
  //Open file for logging
  //
  `ifdef PRINT_TO_VIF_SVA_FILE
	  string test_case;
  string sim_result_path; 
  integer apb_log_fh;
  initial begin
    if (!$value$plusargs("UVM_TESTNAME=%s", test_case)) begin
      test_case = "DEFAULT";
    end
    $sformat(sim_result_path, "../SIM_RESULT/%0dSLAVE/%s", `SLAVE_CNT, test_case);
    apb_log_fh = $fopen($sformatf("%s/VIF_SVA/apb_error.log", sim_result_path), "a"); // "w" = overwrite, "a" = append
    if (apb_log_fh == 0) begin
      $display("ERROR: Could not open apb_error.log!!!");
    end
  end
  `endif
  // =====================================
  // SVA Protocol Checks
  // =====================================
  genvar i;
    generate;
    for(i = 0; i < `SLAVE_CNT; i++) begin : apb_slave_checks
      //(1)
      property psel_onehot;
        @(posedge pclk) disable iff (!presetn)
          $onehot0(psel);
      endproperty
      assert property (psel_onehot)
      else begin
        `ifdef PRINT_TO_VIF_SVA_FILE
        $fdisplay(apb_log_fh, "PSEL_SVA: multiple slaves selected at the same time!!! Value = %0b @time=%0t ns", psel, $time);
        `else
        $error("PSEL_SVA: multiple slaves selected at the same time!!! Value = %0b", psel);
        `endif
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
        `ifdef PRINT_TO_VIF_SVA_FILE
        $fdisplay(apb_log_fh, "[RESEL_ALL_SIGNALS]: all APB signals are not properly reset!!! @time=%0t ns", $time);
        `else
        $error("[RESEL_ALL_SIGNALS]: all APB signals are not properly reset!!!");
        `endif
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
        `ifdef PRINT_TO_VIF_SVA_FILE
        $fdisplay(apb_log_fh, $sformatf("APB_SVA[%0d]: penable not asserted in ACCESS phase @time=%0t ns", i, $time));
        `else
        $error("APB[%0d]: penable not asserted in ACCESS phase", i);
        `endif
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
        `ifdef PRINT_TO_VIF_SVA_FILE
        $fdisplay(apb_log_fh, $sformatf("APB_SVA[%0d]: Transfer ended without pready @time=%0t ns", i, $time));
        `else
        $error("APB_SVA[%0d]: Transfer ended without pready", i);
        `endif
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
        `ifdef PRINT_TO_VIF_SVA_FILE
        $fdisplay(apb_log_fh, $sformatf("APB_SVA[%0d]: Penable also ASSERT as pready is high @time=%0t ns", i, $time));
        `else
        $error("APB[%0d]: Penable also ASSERT as pready is high", i);
        `endif
      end
    end
  endgenerate
  clocking s_drv_cb @(posedge pclk);
      input psel, penable, pwrite, pstrb, paddr, pwdata, pprot;
      output prdata, pready, pslverr;
  endclocking

  //
  clocking s_mon_cb @(posedge pclk);
      input psel, penable, pwrite, paddr, pwdata, pstrb, prdata, pready, pslverr, pprot;
  endclocking
  //
  //close file
  //
  `ifdef PRINT_TO_VIF_SVA_FILE
  final begin
    if(apb_log_fh == 1) begin
     $fclose(apb_log_fh);
    end
  end
  `endif
endinterface



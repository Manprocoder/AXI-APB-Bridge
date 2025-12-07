onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut_top/aclk
add wave -noupdate /tb/dut_top/aresetn
add wave -noupdate -divider -height 23 {AXI WRITE ADDR CHANNEL}
add wave -noupdate /tb/dut_top/awvalid
add wave -noupdate /tb/dut_top/awready
add wave -noupdate -unsigned /tb/dut_top/awid
add wave -noupdate -hex /tb/dut_top/awaddr
add wave -noupdate /tb/dut_top/awlen
add wave -noupdate /tb/dut_top/awsize
add wave -noupdate /tb/dut_top/awburst
add wave -noupdate -divider -height 23 {AXI WRITE ADDR FIFO}
add wave -noupdate /tb/dut_top/axi_slv_inst/aw_sfifo/wr
add wave -noupdate /tb/dut_top/axi_slv_inst/aw_sfifo/rd
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/aw_sfifo/sfifo_empty
add wave -noupdate -divider -height 23 {AXI WRITE DATA CHANNEL}
add wave -noupdate /tb/dut_top/wready
add wave -noupdate /tb/dut_top/wvalid
add wave -noupdate /tb/dut_top/wstrb
add wave -noupdate /tb/dut_top/wlast
add wave -noupdate -hex /tb/dut_top/wdata
add wave -noupdate -divider -height 23 {WDATA FIFO}
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/sfifo_wd_we
add wave -noupdate -unsigned /tb/dut_top/axi_slv_inst/wd_sfifo/w_pointer
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/sfifo_wd_full
add wave -noupdate -hex /tb/dut_top/axi_slv_inst/wd_sfifo/data_in
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/sfifo_wd_re
add wave -noupdate -unsigned /tb/dut_top/axi_slv_inst/wd_sfifo/r_pointer
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/sfifo_wd_almost_empty
add wave -noupdate -hex /tb/dut_top/axi_slv_inst/wd_sfifo/data_out
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/wlast_flag
add wave -noupdate -divider -height 23 {AXI WRITE RESP CHANNEL}
add wave -noupdate /tb/dut_top/bready
add wave -noupdate /tb/dut_top/bvalid
add wave -noupdate /tb/dut_top/bresp
add wave -noupdate /tb/dut_top/bid
add wave -noupdate -divider -height 23 {AXI READ ADDR CHANNEL}
add wave -noupdate /tb/dut_top/aclk
add wave -noupdate /tb/dut_top/aresetn
add wave -noupdate /tb/dut_top/arvalid
add wave -noupdate /tb/dut_top/arready
add wave -noupdate -unsigned /tb/dut_top/arid
add wave -noupdate -hex /tb/dut_top/araddr
add wave -noupdate /tb/dut_top/arlen
add wave -noupdate /tb/dut_top/arsize
add wave -noupdate /tb/dut_top/arburst
add wave -noupdate -divider -height 23 {AXI READ ADDR FIFO}
add wave -noupdate /tb/dut_top/axi_slv_inst/ar_sfifo/wr
add wave -noupdate -hex /tb/dut_top/axi_slv_inst/ar_sfifo/data_in
add wave -noupdate /tb/dut_top/axi_slv_inst/ar_sfifo/rd
add wave -noupdate -hex /tb/dut_top/axi_slv_inst/ar_sfifo/data_out
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/ar_sfifo/sfifo_empty
add wave -noupdate -divider -height 23 {AXI READ DATA CHANNEL}
add wave -noupdate /tb/dut_top/rready
add wave -noupdate /tb/dut_top/rvalid
add wave -noupdate /tb/dut_top/rlast
add wave -noupdate -hex /tb/dut_top/rdata
add wave -noupdate -unsigned /tb/dut_top/rid
add wave -noupdate /tb/dut_top/rresp
add wave -noupdate -divider -height 23 {AXI CLOCK}
add wave -noupdate /tb/dut_top/axi_slv_inst/aclk
add wave -noupdate -divider -height 23 {RDATA FIFO}
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/sfifo_rd_we
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/sfifo_rd_almost_full
add wave -noupdate -hex /tb/dut_top/axi_slv_inst/rd_sfifo/data_in
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/sfifo_rd_re
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/sfifo_rd_empty
add wave -noupdate -hex /tb/dut_top/axi_slv_inst/rd_sfifo/data_out
add wave -noupdate -divider -height 23 {AXI FSM}
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/new_req_rdy
add wave -noupdate -bin /tb/dut_top/axi_slv_inst/burst_en
add wave -noupdate -hex /tb/dut_top/axi_slv_inst/axi_cs
add wave -noupdate -hex /tb/dut_top/axi_slv_inst/axi_ns
add wave -noupdate -divider -height 23 {ARBITER}
add wave -noupdate -bin /tb/dut_top/arbiter_inst/rd_req_avail
add wave -noupdate -bin /tb/dut_top/arbiter_inst/wr_req_avail
add wave -noupdate -bin /tb/dut_top/arbiter_inst/used_grant_o
add wave -noupdate -bin /tb/dut_top/arbiter_inst/nextSel
add wave -noupdate -bin /tb/dut_top/arbiter_inst/nextGrant
add wave -noupdate /tb/dut_top/arbiter_inst/update
add wave -noupdate -divider -height 23 {DECODER}
add wave -noupdate -bin /tb/dut_top/apb_mst_inst/decoder_inst/nonexist_transfer
add wave -noupdate -bin /tb/dut_top/apb_mst_inst/decoder_inst/preadyX_o
add wave -noupdate -bin /tb/dut_top/apb_mst_inst/decoder_inst/pslverrX_o
add wave -noupdate -hex /tb/dut_top/apb_mst_inst/decoder_inst/true_psel_o
add wave -noupdate -bin /tb/dut_top/apb_mst_inst/decoder_inst/false_psel_o
add wave -noupdate -bin /tb/dut_top/apb_mst_inst/decoder_inst/dec_error_o
add wave -noupdate -divider -height 23 {COUNTER}
add wave -noupdate -unsigned /tb/dut_top/cnt_inst/transfer_cnt
add wave -noupdate -bin /tb/dut_top/cnt_inst/burst_almost_done_o
add wave -noupdate -bin /tb/dut_top/cnt_inst/burst_done_o
add wave -noupdate -divider -height 23 {TRANSACTION_ID}
add wave -noupdate -hex /tb/dut_top/axi_slv_inst/sfifo_ar_id
add wave -noupdate -hex /tb/dut_top/axi_slv_inst/sfifo_aw_id
add wave -noupdate -divider -height 23 {APB INTERFACE}
add wave -noupdate /tb/dut_top/pclk
add wave -noupdate /tb/dut_top/preset_n
add wave -noupdate -hex /tb/dut_top/apb_mst_inst/apb_cs
add wave -noupdate -hex /tb/dut_top/apb_mst_inst/apb_ns
add wave -noupdate -hex /tb/dut_top/apb_mst_inst/start_addr_i
add wave -noupdate -bin /tb/dut_top/apb_mst_inst/begin_transfer
add wave -noupdate -bin /tb/dut_top/apb_mst_inst/next_transfer_rdy_i
add wave -noupdate -bin /tb/dut_top/apb_mst_inst/end_of_burst_i
add wave -noupdate /tb/dut_top/pwrite
add wave -noupdate -bin /tb/dut_top/apb_mst_inst/psel
add wave -noupdate -bin /tb/dut_top/apb_mst_inst/invalid_psel
add wave -noupdate /tb/dut_top/apb_mst_inst/penable
add wave -noupdate -hex /tb/dut_top/apb_mst_inst/paddr
add wave -noupdate -hex /tb/dut_top/apb_mst_inst/pwdata
add wave -noupdate /tb/dut_top/apb_mst_inst/pstrb
add wave -noupdate /tb/dut_top/apb_mst_inst/prdata
add wave -noupdate -bin /tb/dut_top/apb_mst_inst/pready
add wave -noupdate -bin /tb/dut_top/apb_mst_inst/pslverr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {925 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 218
configure wave -valuecolwidth 145
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1050 ns}

//
//-----Master Write
//
//MACRO does: create_item, start_item, assert_randomize, finish_item
`define AxiMasterWriteFixedBurst(address) \
`uvm_do_with(WriteSeq, { \
               WriteSeq.waddr[31:0] == address; \
               WriteSeq.wburst[1:0] == 2'b00; \
               WriteSeq.wvalid == 1'b1; \
               })
`define AxiMasterWriteIncrBurst(address) \
`uvm_do_with(WriteSeq, { \
               WriteSeq.waddr[31:0] == address; \
               WriteSeq.wburst[1:0] == 2'b01; \
               WriteSeq.wvalid == 1'b1; \
               })
`define AxiMasterWriteWrapBurst(address) \
`uvm_do_with(WriteSeq, { \
               WriteSeq.waddr[31:0] == address; \
               WriteSeq.wburst[1:0] == 2'b10; \
               WriteSeq.wvalid == 1'b1; \
               })
//
//----Master Read
//
`define AxiMasterReadFixedBurst(address) \
`uvm_do_with(ReadSeq, { \
               ReadSeq.raddr[31:0] == address; \
               ReadSeq.rburst[1:0] == 2'b00; \
               ReadSeq.wvalid == 1'b0; \
               })
`define AxiMasterReadIncrBurst(address) \
`uvm_do_with(ReadSeq, { \
               ReadSeq.raddr[31:0] == address; \
               ReadSeq.rburst[1:0] == 2'b01; \
               ReadSeq.wvalid == 1'b0; \
               })
`define AxiMasterReadWrapBurst(address) \
`uvm_do_with(ReadSeq, { \
               ReadSeq.raddr[31:0] == address; \
               ReadSeq.rburst[1:0] == 2'b10; \
               ReadSeq.wvalid == 1'b0; \
               })



//
 assign decError = (startAddr[31:0] > A_END_SLAVE3);
	else if(`SLAVE_CNT == 5)
	  assign decError = (startAddr[31:0] > A_END_SLAVE4);
	else if(`SLAVE_CNT == 6)
	  assign decError = (startAddr[31:0] > A_END_SLAVE5);
	else if(`SLAVE_CNT == 7)
	  assign decError = (startAddr[31:0] > A_END_SLAVE6);
	else if(`SLAVE_CNT == 8)
	  assign decError = (startAddr[31:0] > A_END_SLAVE7);
	else if(`SLAVE_CNT == 9)
	  assign decError = (startAddr[31:0] > A_END_SLAVE8);
	else if(`SLAVE_CNT == 10)
	  assign decError = (startAddr[31:0] > A_END_SLAVE9);
	else if(`SLAVE_CNT == 11)
	  assign decError = (startAddr[31:0] > A_END_SLAVE10);
	else if(`SLAVE_CNT == 12)
	  assign decError = (startAddr[31:0] > A_END_SLAVE11);
	else if(`SLAVE_CNT == 13)
	  assign decError = (startAddr[31:0] > A_END_SLAVE12);
	else if(`SLAVE_CNT == 14)
	  assign decError = (startAddr[31:0] > A_END_SLAVE13);
	else if(`SLAVE_CNT == 15)
	  assign decError = (startAddr[31:0] > A_END_SLAVE14);
	else if(`SLAVE_CNT == 16)
	  assign decError = (startAddr[31:0] > A_END_SLAVE15);
//else if(`SLAVE_CNT == 17)

	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE16);
	//else if(`SLAVE_CNT == 18)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE17);
	//else if(`SLAVE_CNT == 19)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE18);
	//else if(`SLAVE_CNT == 20)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE19);
	//else if(`SLAVE_CNT == 21)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE20);
	//else if(`SLAVE_CNT == 22)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE21);
	//else if(`SLAVE_CNT == 23)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE22);
	//else if(`SLAVE_CNT == 24)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE23);
	//else if(`SLAVE_CNT == 25)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE24);
	//else if(`SLAVE_CNT == 26)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE25);
	//else if(`SLAVE_CNT == 27)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE26);
	//else if(`SLAVE_CNT == 28)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE27);
	//else if(`SLAVE_CNT == 29)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE28);
	//else if(`SLAVE_CNT == 30)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE29);
	//else if(`SLAVE_CNT == 31)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE30);
	//else if(`SLAVE_CNT == 32)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE31);
if(`SLAVE_CNT == 5)
	  assign false_startAddr  = (startAddr[31:0] > A_END_SLAVE4);
	if(`SLAVE_CNT == 6)
	  assign false_startAddr  = (startAddr[31:0] > A_END_SLAVE5);
	if(`SLAVE_CNT == 7)
	  assign false_startAddr  = (startAddr[31:0] > A_END_SLAVE6);
	if(`SLAVE_CNT == 8)
	  assign false_startAddr  = (startAddr[31:0] > A_END_SLAVE7);
    if(`SLAVE_CNT == 9)
	  assign false_startAddr  = (startAddr[31:0] > A_END_SLAVE8);
	if(`SLAVE_CNT == 10)
	  assign false_startAddr  = (startAddr[31:0] > A_END_SLAVE9);
	if(`SLAVE_CNT == 11)
	  assign false_startAddr  = (startAddr[31:0] > A_END_SLAVE10);
	if(`SLAVE_CNT == 12)
	  assign false_startAddr  = (startAddr[31:0] > A_END_SLAVE11);
    if(`SLAVE_CNT == 13)
	  assign false_startAddr  = (startAddr[31:0] > A_END_SLAVE12);
	if(`SLAVE_CNT == 14)
	  assign false_startAddr  = (startAddr[31:0] > A_END_SLAVE13);
	if(`SLAVE_CNT == 15)
	  assign false_startAddr  = (startAddr[31:0] > A_END_SLAVE14);
	if(`SLAVE_CNT == 16)
	  assign false_startAddr  = (startAddr[31:0] > A_END_SLAVE15);
//if(`SLAVE_CNT == 17)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE16);
	//if(`SLAVE_CNT == 18)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE17);
	//if(`SLAVE_CNT == 19)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE18);
	//if(`SLAVE_CNT == 20)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE19);
    //if(`SLAVE_CNT == 21)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE20);
	//if(`SLAVE_CNT == 22)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE21);
	//if(`SLAVE_CNT == 23)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE22);
	//if(`SLAVE_CNT == 24)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE23);
    //if(`SLAVE_CNT == 25)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE24);
	//if(`SLAVE_CNT == 26)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE25);
	//if(`SLAVE_CNT == 27)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE26);
	//if(`SLAVE_CNT == 28)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE27);
    //if(`SLAVE_CNT == 29)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE28);
	//if(`SLAVE_CNT == 30)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE29);
	//if(`SLAVE_CNT == 31)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE30);
	//if(`SLAVE_CNT == 32)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE31);
//fsmCal
  //always_ff @(posedge pclk, negedge preset_n) begin
    //if(~preset_n)
	  //fsmCal <= 1'b0;
	//else if(transCompleted)
	  //fsmCal <= 1'b0;
	//else
	  //fsmCal <= |psel[`SLAVE_CNT-1:0] | pselRegBlock;
  //end
  //psel
  //always_ff @(posedge pclk, negedge preset_n) begin
    //if(~preset_n) begin
		//psel <= {`SLAVE_CNT{1'b0}};
		//pselRegBlock <= '0;
		//falseReg <= '0;
	//end
	//else begin
	  //case(currentState[1:0])
	    //IDLE:begin
		  //if(next_trans_rdy) begin
			//psel <= sel;
			//falseReg <= false_startAddr;
			//pselRegBlock <= selRegBlock;
		  //end
		  //else begin
			//psel <= {`SLAVE_CNT{1'b0}};
			//falseReg  <= '0;
			//pselRegBlock <= '0;
		  //end
		//end
	    //SETUP:begin
      	  //psel <= sel;
		  //falseReg <= false_startAddr;
		  //pselRegBlock <= selRegBlock;
		//end
	    //ACCESS:begin
			//if(preadyX) begin
				//if(transCompleted || ~next_trans_rdy) begin
					//psel <= {`SLAVE_CNT{1'b0}};
					//falseReg <= '0;
					//pselRegBlock <= '0;
				//end
			//end
			//else begin
				//psel <= psel;
				//falseReg <= false_startAddr;
				//pselRegBlock <= selRegBlock;
			//end
		//end
	  //endcase
	//end
  //end
  //penable
  //always_ff @(posedge pclk, negedge preset_n) begin
    //if(~preset_n)
	  //penable <= 1'b0;
	//else begin
	  //case(currentState[1:0])
	    //IDLE: begin
			//penable <= 1'b0;
		//end
		//SETUP: begin
			//penable <= 1'b1;
		//end
		//ACCESS: begin
			//if(preadyX) penable <= 1'b0;
			//else penable <= 1'b1;
		//end
	  //endcase
	//end
  //end
////pwrite
  //always_ff @(posedge pclk, negedge preset_n) begin
    //if(~preset_n)
	  //pwrite <= 1'b0;
	//else begin
	  //case(currentState[1:0])
	    //IDLE: begin
		  //if(~abtGrant[0])
		    //pwrite <= 1'b1;
		  //else
		    //pwrite <= 1'b0;
		//end
		//SETUP: begin
			//pwrite <= pwrite;
		//end
		//ACCESS: pwrite <= pwrite;
	  //endcase
	//end
  //end
  //pwdata
  //always_ff @(posedge pclk, negedge preset_n) begin
    //if(~preset_n)
	  //pwdata[31:0]           <= 32'd0;
	//else begin
	  //case(currentState[1:0])
	    //IDLE: pwdata[31:0]   <= 32'd0;
		//SETUP: begin
		  //if(abtGrant[0])
		    //pwdata[31:0]     <= 32'd0;
		  //else
		    //pwdata[31:0]     <= sfifoWdWdata[31:0];
		//end
		//ACCESS: pwdata[31:0] <= pwdata[31:0];
	  //endcase
	//end
  //end
  //pprot
  //always_ff @(posedge pclk, negedge preset_n) begin
    //if(~preset_n)
	  //pprot[2:0] <= 3'd0;
	//else begin
	  //case(currentState[1:0])
	    //IDLE: pprot[2:0] <= 3'd0;
	    //SETUP: begin
		  //if(abtGrant[0])
		    //pprot[2:0] <= sfifoArCtrlArprot[2:0];
		  //else
		    //pprot[2:0] <= sfifoAwCtrlAwprot[2:0];
		//end
		//ACCESS: pprot[2:0] <= pprot[2:0];
	  //endcase
	//end
  //end
  ////pstrb
  //always_ff @(posedge pclk, negedge preset_n) begin
    //if(~preset_n)
	  //pstrb[3:0] = 4'd0;
	//else begin
	  //case(currentState[1:0])
	    //IDLE: pstrb[3:0] <= 4'd0;
		//SETUP: begin
		  //if(~abtGrant[0])
		    //pstrb[3:0] <= sfifoWdWstrb[3:0];
		  //else
		    //pstrb[3:0] <= 4'd0;
		//end
		//ACCESS: pstrb[3:0] <= pstrb[3:0];
	  //endcase
	//end
  //end
//
//
//FallingEdgeDetector FE_Detector_transCompleted(
    //.clk_i(pclk),
    //.rstn_i(preset_n),
    //.sign_i(transCompleted),
    //.fed_o(transCompleted_fe)  //
//);
//generate
    //if(`SLAVE_CNT == 1)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE0);
	//else if(`SLAVE_CNT == 2)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE1);
	//else if(`SLAVE_CNT == 3)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE2);
	//else if(`SLAVE_CNT == 4)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE3);
	//else if(`SLAVE_CNT == 5)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE4);
	//else if(`SLAVE_CNT == 6)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE5);
	//else if(`SLAVE_CNT == 7)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE6);
	//else if(`SLAVE_CNT == 8)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE7);
	//else if(`SLAVE_CNT == 9)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE8);
	//else if(`SLAVE_CNT == 10)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE9);
	//else if(`SLAVE_CNT == 11)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE10);
	//else if(`SLAVE_CNT == 12)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE11);
	//else if(`SLAVE_CNT == 13)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE12);
	//else if(`SLAVE_CNT == 14)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE13);
	//else if(`SLAVE_CNT == 15)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE14);
	//else if(`SLAVE_CNT == 16)
	  //assign decError = (startAddr[31:0] < A_START_REG) | (startAddr[31:0] > A_END_SLAVE15);
  //endgenerate
//false_startAddr
  //generate
    //if(`SLAVE_CNT == 1)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE0);
	//if(`SLAVE_CNT == 2)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE1);
	//if(`SLAVE_CNT == 3)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE2);
	//if(`SLAVE_CNT == 4)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE3);
    //if(`SLAVE_CNT == 5)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE4);
	//if(`SLAVE_CNT == 6)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE5);
	//if(`SLAVE_CNT == 7)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE6);
	//if(`SLAVE_CNT == 8)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE7);
    //if(`SLAVE_CNT == 9)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE8);
	//if(`SLAVE_CNT == 10)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE9);
	//if(`SLAVE_CNT == 11)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE10);
	//if(`SLAVE_CNT == 12)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE11);
    //if(`SLAVE_CNT == 13)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE12);
	//if(`SLAVE_CNT == 14)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE13);
	//if(`SLAVE_CNT == 15)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE14);
	//if(`SLAVE_CNT == 16)
	  //assign false_startAddr  = (startAddr[31:0] < A_START_REG)|(startAddr[31:0] > A_END_SLAVE15);
  //endgenerate
	if(`SLAVE_CNT >= 5)
      assign sel[4]  = (startAddr[31:0] >= A_START_SLAVE4) & (startAddr[31:0] <= A_END_SLAVE4);
	if(`SLAVE_CNT >= 6)
	  assign sel[5]  = (startAddr[31:0] >= A_START_SLAVE5) & (startAddr[31:0] <= A_END_SLAVE5);
	if(`SLAVE_CNT >= 7)
      assign sel[6]  = (startAddr[31:0] >= A_START_SLAVE6) & (startAddr[31:0] <= A_END_SLAVE6);
    if(`SLAVE_CNT >= 8)
      assign sel[7]  = (startAddr[31:0] >= A_START_SLAVE7) & (startAddr[31:0] <= A_END_SLAVE7);
    if(`SLAVE_CNT >= 9)
	  assign sel[8]  = (startAddr[31:0] >= A_START_SLAVE8) & (startAddr[31:0] <= A_END_SLAVE8);
	if(`SLAVE_CNT >= 10)
	  assign sel[9]  = (startAddr[31:0] >= A_START_SLAVE9) & (startAddr[31:0] <= A_END_SLAVE9);
	if(`SLAVE_CNT >= 11)
	  assign sel[10] = (startAddr[31:0] >= A_START_SLAVE10) & (startAddr[31:0] <= A_END_SLAVE10);
	if(`SLAVE_CNT >= 12)
	  assign sel[11] = (startAddr[31:0] >= A_START_SLAVE11) & (startAddr[31:0] <= A_END_SLAVE11);
	if(`SLAVE_CNT >= 13)
      assign sel[12] = (startAddr[31:0] >= A_START_SLAVE12) & (startAddr[31:0] <= A_END_SLAVE12);
	if(`SLAVE_CNT >= 14)
	  assign sel[13] = (startAddr[31:0] >= A_START_SLAVE13) & (startAddr[31:0] <= A_END_SLAVE13);
	if(`SLAVE_CNT >= 15)
      assign sel[14] = (startAddr[31:0] >= A_START_SLAVE14) & (startAddr[31:0] <= A_END_SLAVE14);
    if(`SLAVE_CNT >= 16)
      assign sel[15] = (startAddr[31:0] >= A_START_SLAVE15) & (startAddr[31:0] <= A_END_SLAVE15);

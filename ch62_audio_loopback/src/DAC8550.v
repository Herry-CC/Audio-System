module dac8550
(
	input						clk,         //这个模块采样率应该是 频率/25
	input						rst_n,
	input						endac,
    input        [15:0]         indata,

	output						sclk,
	output		reg				SYNC_n,
	output		reg				dout
	//output		reg[15:0]		data_out,
	//output		reg[4:0]		bit_cnt    

);

//reg			[23:0]				shift_reg;
reg			[15:0]				data_out;
reg			    [1:0]				cnt;
wire			[23:0]			    shift_reg;
reg			[4:0]				bit_cnt;

/*
always	@(posedge clk or negedge rst_n)
	if(!rst_n)
		cnt <= 2'b00;
	else if(cnt == 2'b11)
		cnt <= 2'b00;
	else 
		cnt <= cnt + 1'b1;
//-----------------sclk-------------------------------------
always	@(posedge clk or negedge rst_n)
	if(!rst_n)
		sclk <= 1'b0;
	else if(cnt == 2'b01)
		sclk <= !sclk;
	else
		sclk <= sclk;
*/

assign sclk = clk;


//------------------SYNC_n----------------------------------
always	@(posedge sclk or negedge rst_n)
	if(!rst_n)
		SYNC_n <= 1'b1;
	else if(bit_cnt == 5'd23)
		SYNC_n <= 1'b1;
	else if(endac)
		SYNC_n <= 1'b0;
	else
		SYNC_n <= SYNC_n;
//-------------------bit_cnt--------------------------------
always @(posedge sclk or negedge rst_n)
	if(!rst_n)
		bit_cnt <= 1'b0;
	else if(bit_cnt == 5'd23 || SYNC_n == 1'b1)
		bit_cnt <= 1'b0;
	else if(SYNC_n == 1'b0)
		bit_cnt <= bit_cnt + 1'b1;
	else
		bit_cnt <= bit_cnt; 
//-----------------------data_out--------------------------
always	@(posedge sclk or negedge rst_n)
	if(!rst_n)
		data_out <= 16'b0;
	else if(bit_cnt == 5'd23)
		data_out <= indata;
	else
		data_out <= data_out;
//-----------------------shift_reg-------------------------
assign shift_reg = {8'b0, data_out};
//----------------------dout-------------------------------
always	@(posedge sclk or negedge rst_n)
	if(!rst_n)
		dout <= 1'b1;
	else if(SYNC_n == 1'b0 )
		dout <= shift_reg[23 - bit_cnt];
	else if(bit_cnt == 5'd23)
		dout <= 1'b1;
	else
		dout <= 1'b1;
endmodule
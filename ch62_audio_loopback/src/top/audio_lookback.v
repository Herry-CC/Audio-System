 module audio_lookback(
		input clk,                    
		input reset_n,                                   
		inout iic_0_scl,              
		inout iic_0_sda,   
	    output led,
		
		input I2S_ADCDAT,
		input I2S_ADCLRC,
		input I2S_BCLK,
		output I2S_DACDAT,
		input I2S_DACLRC,
		output I2S_MCLK,

/**********************下面又是我重新加入进来的输入输出************************************************/        

        //加上的串口引脚0
        input uart_rx,
        output uart_tx,
        //串口屏的引脚
        input LCD_rx,
        //外界dac的管脚
        output   sclk    ,   //DA输出数据
        output   SYNC_n  ,       //给DA模块的时钟
        output   dout    ,
        //外界dac2
        output   sclk_1    ,   //DA输出数据
        output   SYNC_n_1  ,       //给DA模块的时钟
        output   dout_1,
        //外接dac解码芯片
        output I2S_BCLK_DAC,
        output I2S_DACDAT_DAC,
        output I2S_DACLRC_DAC

);
	
	parameter DATA_WIDTH        = 32;     
	reg [5:0] N                 = 10;    //倍频的倍数

    wire clk_48M;
    wire clk_19and2M;
    wire clk_12M;

    Gowin_PLL Gowin_PLL(
        .clkout0(I2S_MCLK), //output clkout0
        .clkout1(clk_48M),
        .clkin(clk) //input clkin
    );
    Gowin_DAC your_instance_name(
        .clkout0(), //output clkout0
        .clkout1(clk_19and2M), //output clkout1
        .clkout2(clk_12M), //output clkout2
        .clkin(clk) //input clkin
    );
 	wire Init_Done;
	WM8960_Init WM8960_Init(
		.Clk(clk),
		.Rst_n(reset_n),
		.I2C_Init_Done(Init_Done),
		.i2c_sclk(iic_0_scl),
		.i2c_sdat(iic_0_sda)
	);
	
	assign led = Init_Done;
	
   
	reg adcfifo_read;
	wire [DATA_WIDTH - 1:0] adcfifo_readdata;
	wire signed [15:0] adcfifo_readdata_0;
	wire signed [15:0] adcfifo_readdata_1;    
	wire adcfifo_empty;

	reg dacfifo_write;
	reg [DATA_WIDTH - 1:0] dacfifo_writedata;
	wire dacfifo_full;
	
    wire [31:0]yout_2;
    wire  signed [15:0]yout_0;
    wire  signed [15:0]yout_1;
    wire valid_1;
    wire valid_2;
    reg en;

    //dac输出
    reg signed [15:0] data_dac_out_0; 
    reg signed [15:0] data_dac_out_1; 

    /*0.1的计数器*/
    reg [23:0]cnt_0and1s;
    /*来个串口接收与接收*/
    wire rx_done;
    wire [7:0] data_byte_rx;

    wire Tx_done;
    wire [7:0] data_byte_tx;

    /*先来个简单的插值处理*/

    wire signed [15:0] chazhi_0;             //插值的左耳
    wire signed [15:0] chazhi_1 ;            //插值的右耳
    wire [31:0] chazhi_even  ;        //插值的最终

    reg [11:0] counter = 0;         //这是分频到48k的计数器
    reg clk_out_48k = 0;            //48k的时钟

    reg [11:0] counter_24k = 0;     //这是分频到24k的计数器
    reg clk_out_24k = 0;            //24k的时钟

    reg [12:0] counter_8k = 0;      //这是分频到8k的计数器
    reg clk_out_8k = 0;             //8k的时钟

    reg [8:0] cnt_192k = 0;
    reg clk_out_192k = 0;

    
    reg [4:0] cnt_4and8M = 0;
    reg clk_out_4and8M = 0;

    reg [8:0] cnt_200k = 0;
    reg clk_out_200k = 0;

    initial en = 1;                 //这个是滤波器使能
  
//dac输出的中间变量
    wire [7:0] out_data_wire;

//写的是回声的
reg adcfifo_write_delay ;
wire adcfifo_full_delay;
wire adcfifo_empty_delay;
reg adcfifo_read_delay;
reg [23:0] cnt_delay = 'd3;
reg [23:0] cnt_delay_last = 'd3; 

//这是混响参数
reg adcfifo_read_max_1;
reg adcfifo_read_max_2;
reg adcfifo_read_max_3;

reg [12:0] cnt_max1;
reg [12:0] cnt_max2;
reg [12:0] cnt_max3;

initial begin
    adcfifo_write_delay <= 1'd1;
    adcfifo_read_delay  <= 1'd0;
    adcfifo_read_max_1  <= 1'd0;
    adcfifo_read_max_2  <= 1'd0;
    adcfifo_read_max_3  <= 1'd0;
end


//这是延迟后的数据
parameter Huisheng =  500;


wire [DATA_WIDTH-1:0] adcfifo_readdata_0and1s;
wire   signed [15:0] adcfifo_readdata_0and1s_0;
wire   signed [15:0] adcfifo_readdata_0and1s_1;

//这是混响参数
wire [DATA_WIDTH-1:0] adcfifo_readdata_max_1;
wire [DATA_WIDTH-1:0] adcfifo_readdata_max_2;
wire [DATA_WIDTH-1:0] adcfifo_readdata_max_3;

wire   signed [15:0] adcfifo_readdata_max_1_high;
wire   signed [15:0] adcfifo_readdata_max_1_low;

wire   signed [15:0] adcfifo_readdata_max_2_high;
wire   signed [15:0] adcfifo_readdata_max_2_low;

wire   signed [15:0] adcfifo_readdata_max_3_high;
wire   signed [15:0] adcfifo_readdata_max_3_low; 

assign adcfifo_readdata_0and1s_0 = adcfifo_readdata_0and1s[31:16];
assign adcfifo_readdata_0and1s_1 = adcfifo_readdata_0and1s[15:0];

assign adcfifo_readdata_max_1_high = adcfifo_readdata_max_1[31:16];
assign adcfifo_readdata_max_1_low =  adcfifo_readdata_max_1[15:0];

assign adcfifo_readdata_max_2_high = adcfifo_readdata_max_2[31:16];
assign adcfifo_readdata_max_2_low =  adcfifo_readdata_max_2[15:0];

assign adcfifo_readdata_max_3_high = adcfifo_readdata_max_3[31:16];
assign adcfifo_readdata_max_3_low  = adcfifo_readdata_max_3[15:0];

//reg  [DATA_WIDTH-1:0] adcfifo_readdata_0and1s_reg[Huisheng - 1:0]; 

reg reset_n_delay_fifo;
reg again_flag;

reg adc_clk;
reg dac_clk;
reg dac_clk_normal;

reg [3:0] high_beishu;
reg [3:0] mid_beishu;
reg [3:0] low_beishu;

reg [3:0] beishu_1;
reg [3:0] beishu_2;
reg [3:0] beishu_3;
reg [3:0] beishu_4;
reg [3:0] beishu_5;
reg [3:0] beishu_6;
reg [3:0] beishu_7;
reg [3:0] beishu_8;


initial
begin
    
    beishu_1 = 'd1;
    beishu_2 = 'd1;
    beishu_3 = 'd1;
    beishu_4 = 'd1; 
    beishu_5 = 'd1;
    beishu_6 = 'd1;
    beishu_7 = 'd1;
    beishu_8 = 'd1;


end

    //**********************************可调节回声************************************************
    always @ ( posedge clk_out_48k or negedge reset_n_delay_fifo)
    begin
        if ( ~reset_n_delay_fifo )
        begin
            cnt_0and1s <= 0;
            adcfifo_read_delay <= 0;
        end
        else if( cnt_0and1s == cnt_delay-1-2 )
        begin

            adcfifo_read_delay <= 1;
        end
        else begin
           
            cnt_0and1s = cnt_0and1s + 1;
        end


    end

    always @ ( posedge clk or negedge reset_n)
    begin
        if ( ~reset_n )
        begin
            reset_n_delay_fifo<=0;
        end        
        else if( again_flag == 1)
        begin
            reset_n_delay_fifo<=0;
        end
        else begin
            reset_n_delay_fifo<=1;
        end
    end

    //**************************************混响*****************************************************

reg reset_n_delay_max;

reg [11:0] cnt_mix = 'd1200;
reg [11:0] cnt_mix_last = 'd1200;   
reg mix_flag;

    always @ ( posedge clk or negedge reset_n)
    begin
        if ( ~reset_n )
        begin
            reset_n_delay_max<=0;
        end        
        else if( mix_flag == 1)
        begin
            reset_n_delay_max<=0;
        end
        else begin
            reset_n_delay_max<=1;
        end
    end

    /*mix1*/
    always @ ( posedge clk_out_48k or negedge reset_n_delay_max )
    begin
        if ( ~reset_n_delay_max )
        begin
            cnt_max1 <= 0;
            adcfifo_read_max_1 <= 0;
        end
        else if( cnt_max1 == cnt_mix -1-2 )
        begin
            adcfifo_read_max_1 <= 1;
        end
        else begin
            cnt_max1 = cnt_max1 + 1;
        end    
    end



    /*mix2*/
    always @ ( posedge clk_out_48k or negedge reset_n_delay_max)
    begin
        if ( ~reset_n_delay_max )
        begin
            cnt_max2 <= 0;
            adcfifo_read_max_2 <= 0;
        end
        else if( cnt_max2 == cnt_mix/2 -1-2 )
        begin
            adcfifo_read_max_2 <= 1;
        end
        else begin
           
            cnt_max2 = cnt_max2 + 1;
        end    
    end

    //mix3
    always @ ( posedge clk_out_48k or negedge reset_n_delay_max)
    begin
        if ( ~reset_n_delay_max )
        begin
            cnt_max3 <= 0;
            adcfifo_read_max_3 <= 0;
        end
        else if( cnt_max3 == cnt_mix/4 -1-2 )
        begin
            adcfifo_read_max_3 <= 1;
        end
        else begin
           
            cnt_max3 = cnt_max3 + 1;
        end    
    end


    //***********************************回声和混响的FIFO***********************************************
wire [10:0] Wnum;
wire [10:0] Rnum;

//目前深度是2048
	fifo_top delay_fifo(
		.Data(adcfifo_readdata), //input [31:0] Data
		.Reset(~reset_n_delay_fifo), //input Reset
		.WrClk(clk_out_48k), //input WrClk
		.RdClk(clk_out_48k), //input RdClk
		.WrEn('d1), //input WrEn
		.RdEn(adcfifo_read_delay), //input RdEn
		.Wnum(), //是对写入数据进行读数
		.Rnum(), //Rnum 并不是读出的数据个数，而是fifo中可读数据个数
		.Almost_Empty(), //output Almost_Empty
		.Almost_Full(), //output Almost_Full
		.Q(adcfifo_readdata_0and1s), //output [31:0] Q
		.Empty(), //output Empty
		.Full() //output Full
	);




	fifo_mix fifo_mix_1(
		.Data(adcfifo_readdata), //input [31:0] Data
		.Reset(~reset_n_delay_max), //input Reset	
		.WrClk(clk_out_48k), //input WrClk
		.RdClk(clk_out_48k), //input RdClk
		.WrEn('d1), //input WrEn
		.RdEn(adcfifo_read_max_1), //input RdEn
		.Wnum(), //output [8:0] Wnum
		.Rnum(), //output [8:0] Rnum
		.Almost_Empty(), //output Almost_Empty
		.Almost_Full(), //output Almost_Full
		.Q(adcfifo_readdata_max_1), //output [31:0] Q
		.Empty(), //output Empty
		.Full() //output Full
	);


	fifo_mix fifo_mix_2(
		.Data(adcfifo_readdata), //input [31:0] Data
		.Reset(~reset_n_delay_max), //input Reset	
		.WrClk(clk_out_48k), //input WrClk
		.RdClk(clk_out_48k), //input RdClk
		.WrEn('d1), //input WrEn
		.RdEn(adcfifo_read_max_2), //input RdEn
		.Wnum(), //output [8:0] Wnum
		.Rnum(), //output [8:0] Rnum
		.Almost_Empty(), //output Almost_Empty
		.Almost_Full(), //output Almost_Full
		.Q(adcfifo_readdata_max_2), //output [31:0] Q
		.Empty(), //output Empty
		.Full() //output Full
	);


	fifo_mix fifo_mix_3(
		.Data(adcfifo_readdata), //input [31:0] Data
		.Reset(~reset_n_delay_max), //input Reset	
		.WrClk(clk_out_48k), //input WrClk
		.RdClk(clk_out_48k), //input RdClk
		.WrEn('d1), //input WrEn
		.RdEn(adcfifo_read_max_3), //input RdEn
		.Wnum(), //output [8:0] Wnum
		.Rnum(), //output [8:0] Rnum
		.Almost_Empty(), //output Almost_Empty
		.Almost_Full(), //output Almost_Full
		.Q(adcfifo_readdata_max_3), //output [31:0] Q
		.Empty(), //output Empty
		.Full() //output Full
	);


        //****************************************时钟分频系数**************************************
reg [4:0] cnt_768k= 0;
reg clk_out_768k = 0;

   always @ (posedge clk_19and2M or  negedge reset_n )
   begin
        if( ~reset_n )
        begin
            
            clk_out_768k <= 0; 
        end
        else if(cnt_768k == 0 || cnt_768k == 12)    
        begin       
          clk_out_768k <= ~clk_out_768k;
        end
        else begin
            clk_out_768k <= clk_out_768k;         
        end
   end
   always @ (posedge clk_19and2M or  negedge reset_n )
   begin
        if( ~reset_n )
        begin           
            cnt_768k <= 0; 
        end
        else begin
            cnt_768k <= (cnt_768k==24)?0:cnt_768k+1;
        end
   end



reg [6:0] cnt_1200k= 0;
reg clk_out_1200k = 0;


   always @ (posedge clk_48M or  negedge reset_n)
    begin
        if (~reset_n) 
        begin
            cnt_1200k <= 0;
            clk_out_1200k <= 0;
        end 
        else 
        begin
            if (cnt_1200k == 19) 
            begin
                cnt_1200k <= 0;
                clk_out_1200k <= ~clk_out_1200k; // 翻转输出时钟
            end 
            else begin
                cnt_1200k <= cnt_1200k + 1;
            end
        end        
    end



   always @ (posedge clk_48M or  negedge reset_n)
    begin
        if (~reset_n) 
        begin
            counter <= 0;
            clk_out_48k <= 0;
        end 
        else 
        begin
            if (counter == 499) 
            begin
                counter <= 0;
                clk_out_48k <= ~clk_out_48k; // 翻转输出时钟
            end 
            else begin
                counter <= counter + 1;
            end
        end        
    end

    always @ (posedge clk_48M or negedge reset_n)
    begin
        if (~reset_n) 
        begin
            counter <= 0;
            clk_out_48k <= 0;
        end 
        else 
        begin
            if (counter == 499) 
            begin
                counter <= 0;
                clk_out_48k <= ~clk_out_48k; // 翻转输出时钟
            end 
            else begin
                counter <= counter + 1;
            end
        end        
    end

    always @ (posedge clk_48M or negedge reset_n)
    begin
        if (~reset_n) 
        begin
            counter_24k <= 0;
            clk_out_24k <= 0;
        end 
        else 
        begin
            if (counter_24k == 999) 
            begin
                counter_24k <= 0;
                clk_out_24k <= ~clk_out_24k; // 翻转输出时钟
            end 
            else begin
                counter_24k <= counter_24k + 1;
            end
        end        
    end

    always @ (posedge clk_48M or negedge reset_n)
    begin
        if (~reset_n) 
        begin
            cnt_192k <= 0;
            clk_out_192k <= 0;
        end 
        else 
        begin
            if (cnt_192k == 124) 
            begin
                cnt_192k <= 0;
                clk_out_192k <= ~clk_out_192k; // 翻转输出时钟
            end 
            else begin
                cnt_192k <= cnt_192k + 1;
            end
        end        
    end

    always @ (posedge clk_48M or negedge reset_n)
    begin
        if (~reset_n) 
        begin
            cnt_4and8M <= 0;
            clk_out_4and8M <= 0;
        end 
        else 
        begin
            if (cnt_4and8M == 4) 
            begin
                cnt_4and8M <= 0;
                clk_out_4and8M <= ~clk_out_4and8M; // 翻转输出时钟
            end 
            else begin
                cnt_4and8M <= cnt_4and8M + 1;
            end
        end        
    end

    always @ (posedge clk_48M or negedge reset_n)
    begin
        if (~reset_n) 
        begin
            cnt_200k <= 0;
            clk_out_200k <= 0;
        end 
        else 
        begin
            if (cnt_200k == 4) 
            begin
                cnt_200k <= 0;
                clk_out_200k <= ~clk_out_200k; // 翻转输出时钟
            end 
            else begin
                cnt_200k <= cnt_200k + 1;
            end
        end        
    end


    always @ (posedge clk_out_48k or negedge reset_n)
    begin
        if (~reset_n) 
        begin
            counter_8k <= 0;
            clk_out_8k <= 0;
        end 
        else begin
            if (counter_8k == 'd2) 
            begin
                counter_8k <= 0;
                clk_out_8k <= ~clk_out_8k; // 翻转输出时钟
            end 
            else begin
                counter_8k <= counter_8k + 1;
            end
        end        
    end

    
   
reg [7:0] cnt_480k= 0;
reg clk_out_480k = 0;

 always @ (posedge clk_48M or negedge reset_n)
    begin
        if (~reset_n) 
        begin
            cnt_480k <= 0;
            clk_out_480k <= 0;
        end 
        else begin
            if (cnt_480k == 'd49) 
            begin
                cnt_480k <= 0;
                clk_out_480k <= ~clk_out_480k; // 翻转输出时钟
            end 
            else begin
                cnt_480k <= cnt_480k + 1;
            end
        end        
    end



//**********************************************************************

	always @ (posedge clk or negedge reset_n)
	begin
		if (~reset_n)
		begin
			adcfifo_read <= 1'b0;
		end
		else if (~adcfifo_empty)
		begin
			adcfifo_read <= 1'b1;
		end
		else
		begin
			adcfifo_read <= 1'b0;
		end
	end

	always @ (posedge clk or negedge reset_n)
	begin
		if(~reset_n)
			dacfifo_write <= 1'd0;
		else if(~dacfifo_full && (~adcfifo_empty)) begin
			dacfifo_write <= 1'd1;
			//dacfifo_writedata <= data_low_adc_add;
            dacfifo_writedata <= yout_2;          /*************在这修改最终输出哦*****************/
		end
		else begin
			dacfifo_write <= 1'd0;
		end
	end

 
assign adcfifo_readdata_0 =  adcfifo_readdata[31:16];
assign adcfifo_readdata_1 =  adcfifo_readdata[15:0];
    
    //************************************线性插值************************************

    Linear_Interpolation Linear_Interpolation
    (
       .N(N),
       .clk(dac_clk_normal),
       .reset_n(reset_n),
       .adcfifo_readdata( adcfifo_readdata ),

       .chazhi_0( chazhi_0 ),
       .chazhi_1( chazhi_1 ),
       .chazhi_even( chazhi_even )
    );

/*
//低通4k
    reg    signed    [15:0]   coef_a_b[7:0];

    initial coef_a_b[0]        = -16'd9    ;
    initial coef_a_b[1]        = -16'd5   ;
    initial coef_a_b[2]        = 16'd22  ;
    initial coef_a_b[3]        = 16'd79   ;
    initial coef_a_b[4]        = 16'd164   ;
    initial coef_a_b[5]        = 16'd262 ;
    initial coef_a_b[6]        = 16'd350  ;
    initial coef_a_b[7]        = 16'd402 ;
*/

//FS 192K   低通24K
/*
    reg    signed    [15:0]   coef_a_b[7:0];

    initial coef_a_b[0]        = -16'd33    ;
    initial coef_a_b[1]        = -16'd93   ;
    initial coef_a_b[2]        = -16'd110  ;
    initial coef_a_b[3]        = -16'd55   ;
    initial coef_a_b[4]        = 16'd71   ;
    initial coef_a_b[5]        = 16'd241 ;
    initial coef_a_b[6]        = 16'd402  ;
    initial coef_a_b[7]        = 16'd499 ;
*/

//FS 480K   低通24K

    reg    signed    [15:0]   coef_a_b[7:0];

    initial 
    begin
          /*if( DAC_FS == 480)
          begin  */
            coef_a_b[0]        = 16'd61    ;
            coef_a_b[1]        = 16'd89   ;
            coef_a_b[2]        = 16'd117  ;
            coef_a_b[3]        = 16'd143   ;
            coef_a_b[4]        = 16'd166   ;
            coef_a_b[5]        = 16'd185 ;
            coef_a_b[6]        = 16'd198  ;
            coef_a_b[7]        = 16'd204 ;
          /*end
          else if( DAC_FS == 768)
          begin
              coef_a_b[0]        = 16'd86    ;
              coef_a_b[1]        = 16'd94   ;
              coef_a_b[2]        = 16'd102  ;
              coef_a_b[3]        = 16'd109   ;
              coef_a_b[4]        = 16'd114   ;
              coef_a_b[5]        = 16'd118 ;
              coef_a_b[6]        = 16'd121  ;
              coef_a_b[7]        = 16'd122 ;
          end*/
    end
always @ (posedge clk or negedge reset_n)
begin
    if( ~reset_n )
    begin
            coef_a_b[0]        <= 16'd0  ;
            coef_a_b[1]        <= 16'd0  ;
            coef_a_b[2]        <= 16'd0  ;
            coef_a_b[3]        <= 16'd0  ;
            coef_a_b[4]        <= 16'd0  ;
            coef_a_b[5]        <= 16'd0  ;
            coef_a_b[6]        <= 16'd0  ;
            coef_a_b[7]        <= 16'd0  ;
    end
    else if( DAC_FS == 480 )
    begin
            coef_a_b[0]        <= 16'd61   ;
            coef_a_b[1]        <= 16'd89   ;
            coef_a_b[2]        <= 16'd117  ;
            coef_a_b[3]        <= 16'd143  ;
            coef_a_b[4]        <= 16'd166  ;
            coef_a_b[5]        <= 16'd185  ;
            coef_a_b[6]        <= 16'd198  ;
            coef_a_b[7]        <= 16'd204  ;
    end
    else if( DAC_FS == 768 )
    begin
            coef_a_b[0]        <= 16'd86   ;
            coef_a_b[1]        <= 16'd94   ;
            coef_a_b[2]        <= 16'd102  ;
            coef_a_b[3]        <= 16'd109  ;
            coef_a_b[4]        <= 16'd114  ;
            coef_a_b[5]        <= 16'd118  ;
            coef_a_b[6]        <= 16'd121  ;
            coef_a_b[7]        <= 16'd122  ;
    end
end

//FS 768K   低通24K
/*
    reg    signed    [15:0]   coef_a_b[7:0];

    initial coef_a_b[0]        = 16'd86    ;
    initial coef_a_b[1]        = 16'd94   ;
    initial coef_a_b[2]        = 16'd102  ;
    initial coef_a_b[3]        = 16'd109   ;
    initial coef_a_b[4]        = 16'd114   ;
    initial coef_a_b[5]        = 16'd118 ;
    initial coef_a_b[6]        = 16'd121  ;
    initial coef_a_b[7]        = 16'd122 ;
*/

//FS 48K   低通24K
/*
    reg    signed    [15:0]   coef_a_b[7:0];

    initial coef_a_b[0]        = -16'd48    ;
    initial coef_a_b[1]        = 16'd66   ;
    initial coef_a_b[2]        = -16'd90 ;
    initial coef_a_b[3]        = 16'd120    ;
    initial coef_a_b[4]        = -16'd167   ;
    initial coef_a_b[5]        = 16'd247 ;
    initial coef_a_b[6]        = -16'd426  ;
    initial coef_a_b[7]        = 16'd1301 ;
*/

    fir_normal fir_guide_a
    (
             .rstn(reset_n),  //复位，低有效
             .clk(dac_clk_normal),       //工作频率，即采样频率
             .en(en),         //输入数据有效信号
             .xin(chazhi_0),   //输入混合频率的信号数据
             .coef_0(coef_a_b[0]),
             .coef_1(coef_a_b[1]),
             .coef_2(coef_a_b[2]),
             .coef_3(coef_a_b[3]),
             .coef_4(coef_a_b[4]),
             .coef_5(coef_a_b[5]),
             .coef_6(coef_a_b[6]),
             .coef_7(coef_a_b[7]),

             .valid(valid_1),   //输出数据有效信号
             .yout(),    //输出数据
             .hjhfak(yout_0)
    );

    fir_normal fir_guide_b
    (
             .rstn(reset_n),  //复位，低有效
             .clk(dac_clk_normal),       //工作频率，即采样频率
             .en(en),         //输入数据有效信号
             .xin(chazhi_1),   //输入混合频率的信号数据
             .coef_0(coef_a_b[0]),
             .coef_1(coef_a_b[1]),
             .coef_2(coef_a_b[2]),
             .coef_3(coef_a_b[3]),
             .coef_4(coef_a_b[4]),
             .coef_5(coef_a_b[5]),
             .coef_6(coef_a_b[6]),
             .coef_7(coef_a_b[7]),

             .valid(valid_2),   //输出数据有效信号
             .yout(),    //输出数据
             .hjhfak(yout_1)
    );

    assign yout_2 = { yout_0,yout_1 };

	
/*串口接收*/
/*    
    always @ (posedge clk or negedge reset_n)
    begin
        if(!reset_n) begin 
        data_byte <= 8'd0; 
        end 
        else if(rx_done) begin
            if( data_byte == 1 ) begin
            
            end
        end
    end
*/

    //I2S 接收模块，主要功能是将音频芯片内部 ADC 采集得到的串行数据解析出来存储至 FIFO 中
    i2s_rx 
	#(
		.DATA_WIDTH(DATA_WIDTH) 
	)i2s_rx
	(
		.reset_n(reset_n),
		.bclk(I2S_BCLK),
		.adclrc(I2S_ADCLRC),
		.adcdat(I2S_ADCDAT),
		.adcfifo_rdclk(adc_clk),
		.adcfifo_read(adcfifo_read),
		.adcfifo_empty(adcfifo_empty),
		.adcfifo_readdata(adcfifo_readdata)
	);

//********************************************降采样***********************************************	
//降采样数据
wire   [15:0]    out_low_adc_0;
wire   [15:0]    out_low_adc_1;

//FS:48K   低通4k
    reg    signed    [15:0]   coef_low_adc[7:0];

    initial coef_low_adc[0]        = -16'd85 ;
    initial coef_low_adc[1]        = -16'd72 ;
    initial coef_low_adc[2]        = -16'd23 ;
    initial coef_low_adc[3]        = 16'd58  ;
    initial coef_low_adc[4]        = 16'd158 ;
    initial coef_low_adc[5]        = 16'd260 ;
    initial coef_low_adc[6]        = 16'd343 ;
    initial coef_low_adc[7]        = 16'd389 ;

//这是降采样的滤波 
    fir_normal fir_guide_low_adc_a
    (
             .rstn(reset_n),  //复位，低有效
             .clk(clk_out_48k),       //工作频率，即采样频率
             .en(en),         //输入数据有效信号
             .xin(adcfifo_readdata[31:16]),   //输入混合频率的信号数据
             .coef_0(coef_low_adc[0]),
             .coef_1(coef_low_adc[1]),
             .coef_2(coef_low_adc[2]),
             .coef_3(coef_low_adc[3]),
             .coef_4(coef_low_adc[4]),
             .coef_5(coef_low_adc[5]),
             .coef_6(coef_low_adc[6]),
             .coef_7(coef_low_adc[7]),

             .valid(),   //输出数据有效信号
             .yout(),    
             .hjhfak(out_low_adc_0)//输出数据
    );
	
    fir_normal fir_guide_low_adc_b
    (
             .rstn(reset_n),  //复位，低有效
             .clk(clk_out_48k),       //工作频率，即采样频率
             .en(en),         //输入数据有效信号
             .xin(adcfifo_readdata[15:0]),   //输入混合频率的信号数据
             .coef_0(coef_low_adc[0]),
             .coef_1(coef_low_adc[1]),
             .coef_2(coef_low_adc[2]),
             .coef_3(coef_low_adc[3]),
             .coef_4(coef_low_adc[4]),
             .coef_5(coef_low_adc[5]),
             .coef_6(coef_low_adc[6]),
             .coef_7(coef_low_adc[7]),

             .valid(),   //输出数据有效信号
             .yout(),    
             .hjhfak(out_low_adc_1)//输出数据
    );


reg     [15:0]    data_low_adc_0  ;
reg     [15:0]    data_low_adc_1  ;


wire     [31:0]    data_low_adc_add;

//降采样间隔取值
always @ (  posedge clk_out_8k or  negedge reset_n )
begin
    if( ~reset_n )
    begin
        data_low_adc_0 <= 0;
        data_low_adc_1 <= 0;
    end
    else begin
        data_low_adc_0 <= out_low_adc_0;
        data_low_adc_1 <= out_low_adc_1;
    end
end

  
assign data_low_adc_add = { data_low_adc_0,data_low_adc_1 };
 





	i2s_tx
	#(
		 .DATA_WIDTH(DATA_WIDTH)
	)i2s_tx
	(
		 .reset_n(reset_n),
		 .dacfifo_wrclk(clk),
		 .dacfifo_wren(adcfifo_readdata),
		 .dacfifo_wrdata(dacfifo_writedata),
		 .dacfifo_full(dacfifo_full),

		 .bclk(I2S_BCLK),  //这是将I2s_rx中fifo的数据读出来之后，写入到I2_s_tx中的fifo中，在I2_s_tx中将数据以I2S_BCLK时钟输出,I2S_BCLK(12M)  
		 .daclrc(I2S_DACLRC),
		 .dacdat(I2S_DACDAT)
	);


        assign I2S_BCLK_DAC = I2S_BCLK;
        //assign I2S_BCLK_DAC = clk_out_48k;
        assign I2S_DACLRC_DAC = clk_out_768k;

        

	i2s_tx
	#(
		 .DATA_WIDTH(DATA_WIDTH)
	)DAC_i2s_tx
	(
		 .reset_n(reset_n),
		 .dacfifo_wrclk(clk),
		 .dacfifo_wren(),
		 .dacfifo_wrdata(),
		 .dacfifo_full(),

		 .bclk(I2S_BCLK_DAC),    
		 .daclrc(I2S_DACLRC_DAC),
		 .dacdat(I2S_DACDAT_DAC)
	);





    parameter UART_DATA_R_WIDTH = 8*32;
    parameter UART_DATA_T_WIDTH = 8*16;
	parameter MSB_FIRST = 1;

    wire [UART_DATA_R_WIDTH-1:0]rx_data;
    wire [UART_DATA_T_WIDTH-1:0]tx_data;

    wire [63:0] rx_data_zhongjian;
   
    assign rx_data_zhongjian = rx_data[63:0];

    integer  uart_i = 0;
        //         aa08           aa07             aa06               aa05          0128           0126            0123           0118
        //         aa4            aa3              aa2                aa1           110            103             95             86
    // assign tx_data = {rx_data[63:32],rx_data[127:96],rx_data[191:160],rx_data[255:224],rx_data[31:0],rx_data[95:64],rx_data[159:128],rx_data[223:192],"\n" };

  

    wire Rx_Done;
    wire [7:0]data_byte;

    reg send_en = 1'd0;
    //wire tx_data = "6";

    uart_data_rx 
    #(
		.DATA_WIDTH(UART_DATA_R_WIDTH),
		.MSB_FIRST(MSB_FIRST)		
	)
	uart_data_rx(
        .Clk(clk),
        .Rst_n(reset_n),
        .uart_rx(uart_rx),
        
        .data(rx_data),
        .Rx_Done(Rx_Done),
        .timeout_flag(),
        
        .Baud_Set(3'd4)
     );

wire [7:0] adc_fs_100;
wire [7:0] adc_fs_10;
wire [7:0] adc_fs_1;
wire [7:0] lp_100;
wire [7:0] lp_10;
wire [7:0] lp_1;

assign adc_fs_100 = ADC_FS/100 + 48;
assign adc_fs_10 = ADC_FS%100/10 + 48;
assign adc_fs_1 = ADC_FS%100%10 + 48;
assign lp_100 = LP/100 + 48;
assign lp_10 = LP%100/10 + 48;
assign lp_1 = LP%100%10 + 48;
 
     //assign tx_data = (LP>=10)?{"ab",1000," ",""}:{"ab","  ","%d"};
     //assign tx_data = "ab"," ","%d",1000;
        
     //assign tx_data = "ab12341234123412341234123412341234";
        
     assign tx_data = {8'd97,8'd98,adc_fs_100,adc_fs_10,adc_fs_1,8'd48,8'd48,8'd48,8'd32,lp_100,lp_10,lp_1,8'd48,8'd48,8'd48,8'd10};
     //assign   tx_data = 'd97;
     //assign tx_data = {8'd97,8'd98,adc_fs_100,adc_fs_10,adc_fs_1,8'd48,8'd48,8'd48,8'd32};

     uart_data_tx 
        #(
            .DATA_WIDTH(UART_DATA_T_WIDTH),
            .MSB_FIRST(MSB_FIRST)
        )uart_data_tx(
            .Clk(clk),
            .Rst_n(reset_n),
          
            .data(tx_data),
            .send_en(send_en),   
            .Baud_Set(3'd4),  
            
            .uart_tx(uart_tx),  
            .Tx_Done(Tx_Done),   
            .uart_state()
        );


    parameter LCD_DATA_R_WIDTH = 8*4;
    wire [LCD_DATA_R_WIDTH-1:0]LCD_rx_data;
    wire LCD_Rx_Done;
    uart_data_rx 
    #(
		.DATA_WIDTH(LCD_DATA_R_WIDTH),
		.MSB_FIRST(MSB_FIRST)		
	)
	LCD_uart_data_rx(
        .Clk(clk),
        .Rst_n(reset_n),
        .uart_rx(LCD_rx),
        
        .data(LCD_rx_data),
        .Rx_Done(LCD_Rx_Done),
        .timeout_flag(),
        
        .Baud_Set(3'd4)
     );


reg [3:0] mode = 'd0;



reg [10:0] ADC_FS = 'd48;
reg [10:0] LP = 'd24;
reg [10:0] DAC_FS = 'd48;  



always @ (posedge clk or negedge reset_n)
begin
        if( ~reset_n )
        begin
            mode <= 'd0;
        end
        else begin
            if( LCD_rx_data == "000a")                            //对应滤波的题 
            begin
                    mode <= 'd1;
            end
            else if( LCD_rx_data == "000b" )                      //对应倍频的题
            begin
                    mode <= 'd2;
            end
            else if( LCD_rx_data == "000c" )                      //降频
            begin
                    mode <= 'd3;
            end
            else if( LCD_rx_data == "000d")                      //对应回声的题
            begin
                    mode <= 'd4;
            end
            else if( LCD_rx_data == "000e")                      //混响
            begin
                    mode <= 'd5;
            end    
            else if( LCD_rx_data == "000f")                      //均衡器
            begin
                    mode <= 'd6;
            end
        end
end


always @ (posedge clk or negedge reset_n)
begin
    if( ~reset_n )
     begin
            
     end
    else begin
        if( mode == 'd1)                      //只进滤波器
        begin
            ADC_FS <= 48;
            DAC_FS <= 48;
            if( LCD_rx_data[31:24] == "a" )
            begin
                ADC_FS <= (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
            end
            else if( LCD_rx_data[31:24] == "b" ) begin
                LP <= (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
                send_en <=1;
            end
            if( send_en == 1)
            begin
                send_en <=0;
            end
            data_dac_out_0 <= dac_out_n1;
            data_dac_out_1 <= dac_out_n1;
        end
        else if( mode == 'd2 )                 //倍频
        begin
             if( LCD_rx_data[31:24] == "a" )
             begin
                 ADC_FS <= (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             end
             else if( LCD_rx_data[31:24] == "b" )
             begin
                 DAC_FS <= (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             end              
                 //倍频
                N <= DAC_FS/ADC_FS;
                data_dac_out_0 <= yout_0;
                data_dac_out_1 <= yout_1;
        end
        else if( mode == 'd3 )                 //降频
        begin
             if( LCD_rx_data[31:24] == "a" )
             begin
                 ADC_FS <= (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             end
             else if( LCD_rx_data[31:24] == "b")
             begin
                 DAC_FS <= (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             end
                //降频
                data_dac_out_0 <= data_low_adc_0;
                data_dac_out_1 <= data_low_adc_1;
        end
        else if( mode == 'd4)                  //延时
        begin
             cnt_delay <= (LCD_rx_data[31:24] - 'h30)*1000 + (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             cnt_delay_last <= cnt_delay;
             if( cnt_delay_last != cnt_delay)
             begin
                again_flag = 1;
             end
             else begin
                again_flag = 0;
             end
             ADC_FS  <= 48;
             DAC_FS  <= 48;            
             data_dac_out_0 <= adcfifo_readdata_0and1s_0 + adcfifo_readdata_0;
             data_dac_out_1 <= adcfifo_readdata_0and1s_1 + adcfifo_readdata_1;
        end
        else if( mode == 'd5)                 //混响
        begin
             ADC_FS  <= 48;
             DAC_FS  <= 48;
             
             cnt_mix <= (LCD_rx_data[31:24] - 'h30)*1000 + (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             cnt_mix_last <= cnt_mix;
             if( cnt_mix_last != cnt_mix)
             begin
                mix_flag <= 1;
             end
             else begin
                mix_flag <= 0;
             end
             data_dac_out_0 <= adcfifo_readdata_max_3_high + adcfifo_readdata_max_2_high +adcfifo_readdata_max_1_high + adcfifo_readdata_0;
             data_dac_out_1 <= adcfifo_readdata_max_3_low + adcfifo_readdata_max_2_low + adcfifo_readdata_max_1_low+ adcfifo_readdata_1;
        end
        else if( mode == 'd6)                 //均衡器
        begin
             ADC_FS  <= 48;
             DAC_FS  <= 48;
             if( LCD_rx_data[31:24] == "a" )   
             begin
                    beishu_1 =(LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             end
             else if( LCD_rx_data[31:24] == "b" )
             begin
                    beishu_2 =  (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             end
             else if( LCD_rx_data[31:24] == "c") 
             begin
                    beishu_3 =  (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             end
             else if( LCD_rx_data[31:24] == "d" )
             begin
                    beishu_4 =  (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             end
             else if( LCD_rx_data[31:24] == "e" )
             begin
                    beishu_5 =  (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             end
             else if( LCD_rx_data[31:24] == "f" )
             begin
                    beishu_6 =  (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             end
             else if( LCD_rx_data[31:24] == "g" )
             begin
                    beishu_7 =  (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             end
             else if( LCD_rx_data[31:24] == "h" )
             begin
                    beishu_8 =  (LCD_rx_data[23:16] - 'h30)*100 + (LCD_rx_data[15:8] - 'h30)*10 + (LCD_rx_data[7:0] - 'h30);
             end
            data_dac_out_0 <= audio_1_wire_0*beishu_1+audio_2_wire_0*beishu_2+audio_3_wire_0*beishu_3+audio_4_wire_0*beishu_4+audio_5_wire_0*beishu_5+audio_6_wire_0*beishu_6+audio_7_wire_0*beishu_7+audio_8_wire_0*beishu_8;
            data_dac_out_1 <= audio_1_wire_1*beishu_1+audio_2_wire_1*beishu_2+audio_3_wire_1*beishu_3+audio_4_wire_1*beishu_4+audio_5_wire_1*beishu_5+audio_6_wire_1*beishu_6+audio_7_wire_1*beishu_7+audio_8_wire_1*beishu_8;
       end

    end

end

always @ ( posedge clk or negedge reset_n )
begin
    if( ~reset_n)
    begin
        dac_clk <= 'd0;
    end
    else if( DAC_FS == 8)
    begin
        dac_clk <= clk_out_200k;
        dac_clk_normal <= clk_out_8k;
    end
    else if( DAC_FS == 48 )
    begin
        dac_clk <= clk_out_1200k;
        dac_clk_normal <= clk_out_48k;
    end
    else if( DAC_FS == 192 )
    begin
        dac_clk <= clk_out_4and8M;
        dac_clk_normal <= clk_out_192k;
    end
    else if( DAC_FS == 480)
    begin
        dac_clk <= clk_12M;
        dac_clk_normal <= clk_out_480k;     
    end
    else if( DAC_FS == 768)
    begin
        dac_clk <= clk_19and2M;
        dac_clk_normal <= clk_out_768k;
    end

end

always @ ( posedge clk or negedge reset_n )
begin
    if( ~reset_n)
    begin
        adc_clk <= 'd0;
    end
    else if( ADC_FS == 8)
    begin
        adc_clk <= clk_out_8k;
    end
    else if( ADC_FS == 48 )
    begin
        adc_clk <= clk_out_48k;
    end


end

//matlab 接收数据
reg    signed    [15:0]   coef_matlab[7:0];

always @ (posedge clk or negedge reset_n)
begin
        if( ~reset_n )
        begin
            for( integer i = 0; i < 7 ; i = i + 1 )
            begin
                coef_matlab[i] <= 0;
            end            
        end
        else begin
            if( rx_data[255:224] == "aa01")
            begin
                coef_matlab[0] <= (rx_data[223:216]-'h30)*1000 + (rx_data[215:208] - 'h30)*100 + (rx_data[ 207:200] - 'h30)*10 + rx_data[199:192]-  'h30;
            end
            else if( rx_data[255:224] == "bb01" )
            begin
                 coef_matlab[0] <= -((rx_data[223:216]-'h30)*1000 + (rx_data[215:208] - 'h30)*100 + (rx_data[ 207:200] - 'h30)*10 + rx_data[199:192]-  'h30);
            end
            if( rx_data[191:160] == "aa02" )
            begin
                coef_matlab[1] <= (rx_data[159:152]- 'h30)*1000 + (rx_data[151:144]- 'h30)*100 + (rx_data[143:136]- 'h30)*10 + (rx_data[135:128]- 'h30);
            end
            else if( rx_data[191:160] == "bb02" )
            begin
                coef_matlab[1] <= -( (rx_data[159:152]- 'h30)*1000 + (rx_data[151:144]- 'h30)*100 + (rx_data[143:136]- 'h30)*10 + (rx_data[135:128]- 'h30) );
            end
            if( rx_data[127:96] == "aa03")
            begin
                coef_matlab[2] <= (rx_data[95:88]- 'h30)*1000 + (rx_data[87:80]- 'h30)*100 + (rx_data[79:72]- 'h30)*10 + rx_data[71:64]- 'h30 ;
            end
            else if( rx_data[127:96] == "bb03")
            begin
                coef_matlab[2] <= -( (rx_data[95:88]- 'h30)*1000 + (rx_data[87:80]- 'h30)*100 + (rx_data[79:72]- 'h30)*10 + rx_data[71:64]- 'h30 );
            end
            if( rx_data[63:32] == "aa04" )
            begin
                coef_matlab[3] <= (rx_data[31:24] - 'h30)*1000 + (rx_data[23:16] - 'h30)*100 + (rx_data[15:8] - 'h30)*10 + (rx_data[7:0] - 'h30) ;
            end
            else if( rx_data[63:32] == "bb04" )
            begin
                coef_matlab[3] <=  -( (rx_data[31:24] - 'h30)*1000 + (rx_data[23:16] - 'h30)*100 + (rx_data[15:8] - 'h30)*10 + (rx_data[7:0] - 'h30) ) ;
            end
           if(rx_data[255:224] == "aa05")
           begin
                coef_matlab[4] <= (rx_data[223:216]-'h30)*1000 + (rx_data[215:208] - 'h30)*100 + (rx_data[ 207:200] - 'h30)*10 + rx_data[199:192]-  'h30;    
           end
           else if( rx_data[255:224] == "bb05")
           begin
                coef_matlab[4] <= -( (rx_data[223:216]-'h30)*1000 + (rx_data[215:208] - 'h30)*100 + (rx_data[ 207:200] - 'h30)*10 + rx_data[199:192]-  'h30 );
           end
           if( rx_data[191:160] == "aa06")
           begin
               coef_matlab[5] <=  (rx_data[159:152]- 'h30)*1000 + (rx_data[151:144]- 'h30)*100 + (rx_data[143:136]- 'h30)*10 + (rx_data[135:128]- 'h30);
           end
           else if( rx_data[191:160] == "bb06")
           begin
               coef_matlab[5] <= -(rx_data[159:152]- 'h30)*1000 + (rx_data[151:144]- 'h30)*100 + (rx_data[143:136]- 'h30)*10 + (rx_data[135:128]- 'h30);
           end
           if( rx_data[127:96] == "aa07")
           begin
               coef_matlab[6] <= (rx_data[95:88]- 'h30)*1000 + (rx_data[87:80]- 'h30)*100 + (rx_data[79:72]- 'h30)*10 + rx_data[71:64]- 'h30;
           end
           else if( rx_data[127:96] == "bb07")
           begin
               coef_matlab[6] <= -( (rx_data[95:88]- 'h30)*1000 + (rx_data[87:80]- 'h30)*100 + (rx_data[79:72]- 'h30)*10 + rx_data[71:64]- 'h30 );
           end
           if( rx_data[63:32] == "aa08")
           begin
               coef_matlab[7] <= (rx_data[31:24] - 'h30)*1000 + (rx_data[23:16] - 'h30)*100 + (rx_data[15:8] - 'h30)*10 + (rx_data[7:0] - 'h30) ;
           end
           else if( rx_data[63:32] == "bb08")
           begin
                coef_matlab[7] <= -( (rx_data[31:24] - 'h30)*1000 + (rx_data[23:16] - 'h30)*100 + (rx_data[15:8] - 'h30)*10 + (rx_data[7:0] - 'h30) );
           end


        end

end
   


initial en = 1'b1;
wire [15:0] audio_1_wire_0;
wire [15:0] audio_2_wire_0;
wire [15:0] audio_3_wire_0;
wire [15:0] audio_4_wire_0;
wire [15:0] audio_5_wire_0;
wire [15:0] audio_6_wire_0;
wire [15:0] audio_7_wire_0;
wire [15:0] audio_8_wire_0;

wire [15:0] audio_1_wire_1;
wire [15:0] audio_2_wire_1;
wire [15:0] audio_3_wire_1;
wire [15:0] audio_4_wire_1;
wire [15:0] audio_5_wire_1;
wire [15:0] audio_6_wire_1;
wire [15:0] audio_7_wire_1;
wire [15:0] audio_8_wire_1;

//滤波器系数audio_8     FS 48k 21~23.9k 带通 
reg    signed    [15:0]   coef_audio_8[7:0];

initial coef_audio_8[0]        = -16'd172   ;
initial coef_audio_8[1]        = 16'd183   ;
initial coef_audio_8[2]        = -16'd184  ;
initial coef_audio_8[3]        = 16'd173  ;
initial coef_audio_8[4]        = -16'd150  ;
initial coef_audio_8[5]        = 16'd116  ;
initial coef_audio_8[6]        = -16'd73  ;
initial coef_audio_8[7]        = 16'd25  ;


fir_normal fir_guide_audio_8_0
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_0),   //输入混合频率的信号数据
         .coef_0(coef_audio_8[0]),
         .coef_1(coef_audio_8[1]),
         .coef_2(coef_audio_8[2]),
         .coef_3(coef_audio_8[3]),
         .coef_4(coef_audio_8[4]),
         .coef_5(coef_audio_8[5]),
         .coef_6(coef_audio_8[6]),
         .coef_7(coef_audio_8[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_8_wire_0)
);

fir_normal fir_guide_audio_8_1
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_1),   //输入混合频率的信号数据
         .coef_0(coef_audio_8[0]),
         .coef_1(coef_audio_8[1]),
         .coef_2(coef_audio_8[2]),
         .coef_3(coef_audio_8[3]),
         .coef_4(coef_audio_8[4]),
         .coef_5(coef_audio_8[5]),
         .coef_6(coef_audio_8[6]),
         .coef_7(coef_audio_8[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_8_wire_1)
);




//滤波器系数audio_7     FS 48k 18~21k 带通
reg    signed    [15:0]   coef_audio_7[7:0];

initial coef_audio_7[0]        = 16'd166   ;
initial coef_audio_7[1]        = -16'd122   ;
initial coef_audio_7[2]        = 16'd20  ;
initial coef_audio_7[3]        = 16'd106  ;
initial coef_audio_7[4]        = -16'd208  ;
initial coef_audio_7[5]        = 16'd245  ;
initial coef_audio_7[6]        = 16'd195  ;
initial coef_audio_7[7]        = 16'd74  ;


fir_normal fir_guide_audio_7_0
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_0),   //输入混合频率的信号数据
         .coef_0(coef_audio_7[0]),
         .coef_1(coef_audio_7[1]),
         .coef_2(coef_audio_7[2]),
         .coef_3(coef_audio_7[3]),
         .coef_4(coef_audio_7[4]),
         .coef_5(coef_audio_7[5]),
         .coef_6(coef_audio_7[6]),
         .coef_7(coef_audio_7[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_7_wire_0)
);

fir_normal fir_guide_audio_7_1
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_1),   //输入混合频率的信号数据
         .coef_0(coef_audio_7[0]),
         .coef_1(coef_audio_7[1]),
         .coef_2(coef_audio_7[2]),
         .coef_3(coef_audio_7[3]),
         .coef_4(coef_audio_7[4]),
         .coef_5(coef_audio_7[5]),
         .coef_6(coef_audio_7[6]),
         .coef_7(coef_audio_7[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_7_wire_1)
);

//滤波器系数audio_6     FS 48k 15~18k 带通
reg    signed    [15:0]   coef_audio_6[7:0];

initial coef_audio_6[0]        = -16'd153   ;
initial coef_audio_6[1]        = 16'd19   ;
initial coef_audio_6[2]        = 16'd162  ;
initial coef_audio_6[3]        = -16'd214  ;
initial coef_audio_6[4]        = 16'd69  ;
initial coef_audio_6[5]        = 16'd156  ;
initial coef_audio_6[6]        = -16'd251  ;
initial coef_audio_6[7]        = 16'd120  ;


fir_normal fir_guide_audio_6_0
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_0),   //输入混合频率的信号数据
         .coef_0(coef_audio_6[0]),
         .coef_1(coef_audio_6[1]),
         .coef_2(coef_audio_6[2]),
         .coef_3(coef_audio_6[3]),
         .coef_4(coef_audio_6[4]),
         .coef_5(coef_audio_6[5]),
         .coef_6(coef_audio_6[6]),
         .coef_7(coef_audio_6[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_6_wire_0)
);


fir_normal fir_guide_audio_6_1
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_1),   //输入混合频率的信号数据
         .coef_0(coef_audio_6[0]),
         .coef_1(coef_audio_6[1]),
         .coef_2(coef_audio_6[2]),
         .coef_3(coef_audio_6[3]),
         .coef_4(coef_audio_6[4]),
         .coef_5(coef_audio_6[5]),
         .coef_6(coef_audio_6[6]),
         .coef_7(coef_audio_6[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_6_wire_1)
);


//滤波器系数audio_5     FS 48k 12~15k 带通
reg    signed    [15:0]   coef_audio_5[7:0];

initial coef_audio_5[0]        = -16'd153   ;
initial coef_audio_5[1]        = 16'd19   ;
initial coef_audio_5[2]        = 16'd162  ;
initial coef_audio_5[3]        = -16'd214  ;
initial coef_audio_5[4]        = 16'd69  ;
initial coef_audio_5[5]        = 16'd156  ;
initial coef_audio_5[6]        = -16'd251  ;
initial coef_audio_5[7]        = 16'd120  ;


fir_normal fir_guide_audio_5_0
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_0),   //输入混合频率的信号数据
         .coef_0(coef_audio_5[0]),
         .coef_1(coef_audio_5[1]),
         .coef_2(coef_audio_5[2]),
         .coef_3(coef_audio_5[3]),
         .coef_4(coef_audio_5[4]),
         .coef_5(coef_audio_5[5]),
         .coef_6(coef_audio_5[6]),
         .coef_7(coef_audio_5[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_5_wire_0)
);

fir_normal fir_guide_audio_5_1
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_1),   //输入混合频率的信号数据
         .coef_0(coef_audio_5[0]),
         .coef_1(coef_audio_5[1]),
         .coef_2(coef_audio_5[2]),
         .coef_3(coef_audio_5[3]),
         .coef_4(coef_audio_5[4]),
         .coef_5(coef_audio_5[5]),
         .coef_6(coef_audio_5[6]),
         .coef_7(coef_audio_5[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_5_wire_1)
);


//滤波器系数audio_4     FS 48k 9~12k 带通
reg    signed    [15:0]   coef_audio_4[7:0];

initial coef_audio_4[0]        = -16'd110   ;
initial coef_audio_4[1]        = -16'd169   ;
initial coef_audio_4[2]        = 16'd61  ;
initial coef_audio_4[3]        = 16'd223  ;
initial coef_audio_4[4]        = 16'd23  ;
initial coef_audio_4[5]        = -16'd235  ;
initial coef_audio_4[6]        = -16'd119  ;
initial coef_audio_4[7]        = 16'd198  ;


fir_normal fir_guide_audio_4_0
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_0),   //输入混合频率的信号数据
         .coef_0(coef_audio_4[0]),
         .coef_1(coef_audio_4[1]),
         .coef_2(coef_audio_4[2]),
         .coef_3(coef_audio_4[3]),
         .coef_4(coef_audio_4[4]),
         .coef_5(coef_audio_4[5]),
         .coef_6(coef_audio_4[6]),
         .coef_7(coef_audio_4[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_4_wire_0)
);


fir_normal fir_guide_audio_4_1
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_1),   //输入混合频率的信号数据
         .coef_0(coef_audio_4[0]),
         .coef_1(coef_audio_4[1]),
         .coef_2(coef_audio_4[2]),
         .coef_3(coef_audio_4[3]),
         .coef_4(coef_audio_4[4]),
         .coef_5(coef_audio_4[5]),
         .coef_6(coef_audio_4[6]),
         .coef_7(coef_audio_4[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_4_wire_1)
);


//滤波器系数audio_2     FS 48k 3~6k 带通
reg    signed    [15:0]   coef_audio_2[7:0];

initial coef_audio_2[0]        = -16'd50   ;
initial coef_audio_2[1]        = -16'd148   ;
initial coef_audio_2[2]        = -16'd208  ;
initial coef_audio_2[3]        = -16'd198  ;
initial coef_audio_2[4]        = -16'd111  ;
initial coef_audio_2[5]        = 16'd24  ;
initial coef_audio_2[6]        = 16'd160  ;
initial coef_audio_2[7]        = 16'd245  ;


fir_normal fir_guide_audio_2_0
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_0),   //输入混合频率的信号数据
         .coef_0(coef_audio_2[0]),
         .coef_1(coef_audio_2[1]),
         .coef_2(coef_audio_2[2]),
         .coef_3(coef_audio_2[3]),
         .coef_4(coef_audio_2[4]),
         .coef_5(coef_audio_2[5]),
         .coef_6(coef_audio_2[6]),
         .coef_7(coef_audio_2[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_2_wire_0)
);


fir_normal fir_guide_audio_2_1
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_1),   //输入混合频率的信号数据
         .coef_0(coef_audio_2[0]),
         .coef_1(coef_audio_2[1]),
         .coef_2(coef_audio_2[2]),
         .coef_3(coef_audio_2[3]),
         .coef_4(coef_audio_2[4]),
         .coef_5(coef_audio_2[5]),
         .coef_6(coef_audio_2[6]),
         .coef_7(coef_audio_2[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_2_wire_1)
);




//滤波器系数audio_1     FS 48k 0~3k 带通
reg    signed    [15:0]   coef_audio_1[7:0];

initial coef_audio_1[0]        = 16'd8   ;
initial coef_audio_1[1]        = 16'd47   ;
initial coef_audio_1[2]        = 16'd90  ;
initial coef_audio_1[3]        = 16'd134  ;
initial coef_audio_1[4]        = 16'd174  ;
initial coef_audio_1[5]        = 16'd208  ;
initial coef_audio_1[6]        = 16'd233  ;
initial coef_audio_1[7]        = 16'd245  ;


fir_normal fir_guide_audio_1_0
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_0),   //输入混合频率的信号数据
         .coef_0(coef_audio_1[0]),
         .coef_1(coef_audio_1[1]),
         .coef_2(coef_audio_1[2]),
         .coef_3(coef_audio_1[3]),
         .coef_4(coef_audio_1[4]),
         .coef_5(coef_audio_1[5]),
         .coef_6(coef_audio_1[6]),
         .coef_7(coef_audio_1[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_1_wire_0)
);


fir_normal fir_guide_audio_1_1
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_1),   //输入混合频率的信号数据
         .coef_0(coef_audio_1[0]),
         .coef_1(coef_audio_1[1]),
         .coef_2(coef_audio_1[2]),
         .coef_3(coef_audio_1[3]),
         .coef_4(coef_audio_1[4]),
         .coef_5(coef_audio_1[5]),
         .coef_6(coef_audio_1[6]),
         .coef_7(coef_audio_1[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_1_wire_1)
);

/*
reg en;//滤波器使能信号
initial en = 1'b1;
reg [15:0] audio_out_reg;


wire [15:0] audio_low_wire;
wire [15:0] audio_mid_wire;
wire [15:0] audio_high_wire;


//滤波器系数audio_low     FS 48k 8k 低通 
reg    signed    [15:0]   coef_audio_low[7:0];

initial coef_audio_low[0]        = 16'd87   ;
initial coef_audio_low[1]        = 16'd50   ;
initial coef_audio_low[2]        = -16'd59  ;
initial coef_audio_low[3]        = -16'd145  ;
initial coef_audio_low[4]        = -16'd93  ;
initial coef_audio_low[5]        = 16'd130  ;
initial coef_audio_low[6]        = 16'd435  ;
initial coef_audio_low[7]        = 16'd652  ;



fir_normal fir_guide_audio_low
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_0),   //输入混合频率的信号数据
         .coef_0(coef_audio_low[0]),
         .coef_1(coef_audio_low[1]),
         .coef_2(coef_audio_low[2]),
         .coef_3(coef_audio_low[3]),
         .coef_4(coef_audio_low[4]),
         .coef_5(coef_audio_low[5]),
         .coef_6(coef_audio_low[6]),
         .coef_7(coef_audio_low[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_low_wire)
);


//滤波器系数audio_mid   FS 48k  8K~16K 带通
reg    signed    [15:0]   coef_audio_mid[7:0];

initial coef_audio_mid[0]        = -16'd87   ;
initial coef_audio_mid[1]        = 16'd37   ;
initial coef_audio_mid[2]        = -16'd43  ;
initial coef_audio_mid[3]        = 16'd145  ;
initial coef_audio_mid[4]        = 16'd254  ;
initial coef_audio_mid[5]        = -16'd356  ;
initial coef_audio_mid[6]        = -16'd435  ;
initial coef_audio_mid[7]        = 16'd477  ;

fir_normal fir_guide_audio_mid
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_0),   //输入混合频率的信号数据
         .coef_0(coef_audio_mid[0]),
         .coef_1(coef_audio_mid[1]),
         .coef_2(coef_audio_mid[2]),
         .coef_3(coef_audio_mid[3]),
         .coef_4(coef_audio_mid[4]),
         .coef_5(coef_audio_mid[5]),
         .coef_6(coef_audio_mid[6]),
         .coef_7(coef_audio_mid[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_mid_wire)
);



//滤波器系数audio_high
reg    signed    [15:0]   coef_audio_high[7:0];

initial coef_audio_high[0]        = -16'd87   ;
initial coef_audio_high[1]        = 16'd13   ;
initial coef_audio_high[2]        = -16'd16  ;
initial coef_audio_high[3]        = 16'd145  ;
initial coef_audio_high[4]        = -16'd348  ;
initial coef_audio_high[5]        = 16'd487  ;
initial coef_audio_high[6]        = -16'd435  ;
initial coef_audio_high[7]        = 16'd175  ;


fir_normal fir_guide_coef_audio_high
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(adcfifo_readdata_0),   //输入混合频率的信号数据
         .coef_0(coef_audio_high[0]),
         .coef_1(coef_audio_high[1]),
         .coef_2(coef_audio_high[2]),
         .coef_3(coef_audio_high[3]),
         .coef_4(coef_audio_high[4]),
         .coef_5(coef_audio_high[5]),
         .coef_6(coef_audio_high[6]),
         .coef_7(coef_audio_high[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(audio_high_wire)
); 


*/

//assign audio_out_wire = audio_low + audio_mid + audio_high;
/*

//滤波器系数audio_even
reg    signed    [15:0]   coef_audio_even[7:0];

initial coef_audio_even[0]        = -16'd87   ;
initial coef_audio_even[1]        = 16'd13   ;
initial coef_audio_even[2]        = -16'd16  ;
initial coef_audio_even[3]        = 16'd145  ;
initial coef_audio_even[4]        = -16'd348  ;
initial coef_audio_even[5]        = 16'd487  ;
initial coef_audio_even[6]        = -16'd435  ;
initial coef_audio_even[7]        = 16'd175  ;


wire  signed  [15:0]  EQ_out_0;

fir_normal fir_guide_coef_audio_even
(
         .rstn(reset_n),  //复位，低有效
         .clk(clk_out_48k),       //工作频率，即采样频率
         .en('d1),         //输入数据有效信号
         .xin(AudioEqualizer_out_0),   //输入混合频率的信号数据
         .coef_0(coef_audio_even[0]),
         .coef_1(coef_audio_even[1]),
         .coef_2(coef_audio_even[2]),
         .coef_3(coef_audio_even[3]),
         .coef_4(coef_audio_even[4]),
         .coef_5(coef_audio_even[5]),
         .coef_6(coef_audio_even[6]),
         .coef_7(coef_audio_even[7]),

         .valid(),   //输出数据有效信号
         .yout(),    //输出数据
         .hjhfak(EQ_out_0)
);



wire signed [15:0]AudioEqualizer_out_0;
wire signed [15:0]AudioEqualizer_out_1;

//clk_19and2M   adcfifo_readdata[31:16]+               adcfifo_readdata_0and1s[31:16]

*/
/*
AudioEqualizer  AudioEqualizer_inst_0
(
     .clk(clk_out_48k),          // 时钟信号
     .fliter_clk(clk_out_48k), 
     .rst(reset_n),          // 复位信号
     .audio_low_wire(audio_low_wire),
     .audio_mid_wire(audio_mid_wire),
     .audio_high_wire(audio_high_wire),
     .audio_in(adcfifo_readdata_0),     // 输入音频信号
     .eq_gain_low('d8),  // 低频增益设置，每个频段一个2位增益值
     .eq_gain_mid('d0),  // 中频增益设置
     .eq_gain_high('d0), // 高频增益设置
     .audio_out(AudioEqualizer_out_0)     // 输出音频信号
     
);
*/
/*
AudioEqualizer  AudioEqualizer_inst_1
(
     .clk(clk_out_48k),          // 时钟信号
     .fliter_clk(clk_out_48k), 
     .rst(reset_n),          // 复位信号
     .audio_in(adcfifo_readdata_1),     // 输入音频信号
     .eq_gain_low('d64),  // 低频增益设置，每个频段一个2位增益值
     .eq_gain_mid('d64),  // 中频增益设置
     .eq_gain_high('d64), // 高频增益设置
     .audio_out(AudioEqualizer_out_1)     // 输出音频信号
);
*/



wire signed [15:0] dac_out_n1;
    reg    signed    [15:0]   coef_n1[7:0];

//FS 48K   低通24K
/*
    initial coef_n1[0]        = -16'd87    ;
    initial coef_n1[1]        = 16'd100   ;
    initial coef_n1[2]        = -16'd118 ;
    initial coef_n1[3]        = 16'd145    ;
    initial coef_n1[4]        = -16'd186   ;
    initial coef_n1[5]        = 16'd261 ;
    initial coef_n1[6]        = -16'd435  ;
    initial coef_n1[7]        = 16'd1304 ;
*/

/*
    initial coef_n1[0]        = -16'd85 ;
    initial coef_n1[1]        = -16'd90 ;
    initial coef_n1[2]        = -16'd52 ;
    initial coef_n1[3]        = 16'd28 ;
    initial coef_n1[4]        = 16'd140 ;
    initial coef_n1[5]        = 16'd260 ;
    initial coef_n1[6]        = 16'd361;
    initial coef_n1[7]        = 16'd419 ;
*/
        initial
        begin
            coef_n1[0]        = coef_matlab[0] ;
            coef_n1[1]        = coef_matlab[1] ;
            coef_n1[2]        = coef_matlab[2] ;
            coef_n1[3]        = coef_matlab[3] ;
            coef_n1[4]        = coef_matlab[4] ;
            coef_n1[5]        = coef_matlab[5] ;
            coef_n1[6]        = coef_matlab[6] ;
            coef_n1[7]        = coef_matlab[7] ;
        end




always @ ( posedge clk or negedge reset_n)
begin
    if( ~reset_n)
    begin
        coef_n1[0]        = -16'd87  ;
        coef_n1[1]        = 16'd100  ;
        coef_n1[2]        = -16'd118 ;
        coef_n1[3]        = 16'd145  ;
        coef_n1[4]        = -16'd186 ;
        coef_n1[5]        = 16'd261  ;
        coef_n1[6]        = -16'd435 ;
        coef_n1[7]        = 16'd1304 ;
    end
    else begin
            coef_n1[0]        = coef_matlab[0] ;
            coef_n1[1]        = coef_matlab[1] ;
            coef_n1[2]        = coef_matlab[2] ;
            coef_n1[3]        = coef_matlab[3] ;
            coef_n1[4]        = coef_matlab[4] ;
            coef_n1[5]        = coef_matlab[5] ;
            coef_n1[6]        = coef_matlab[6] ;
            coef_n1[7]        = coef_matlab[7] ;
    end

    

end




    fir_normal fir_guide_n1
    (
             .rstn(reset_n),  //复位，低有效
             .clk(clk_out_48k),       //工作频率，即采样频率
             .en(en),         //输入数据有效信号
             .xin(adcfifo_readdata_0),   //输入混合频率的信号数据
             .coef_0(coef_n1[0]),
             .coef_1(coef_n1[1]),
             .coef_2(coef_n1[2]),
             .coef_3(coef_n1[3]),
             .coef_4(coef_n1[4]),
             .coef_5(coef_n1[5]),
             .coef_6(coef_n1[6]),
             .coef_7(coef_n1[7]),

             .valid(),   //输出数据有效信号
             .yout(),    //输出数据
             .hjhfak(dac_out_n1)
    );




//************************************************DAC输出****************************************************
wire endac = 1;

        dac8550 dac8550_inst
        (
            .clk(dac_clk),//这里48M实际上应该是192k  audio_mid_wire
            .rst_n(reset_n),
            //.indata(  (  adcfifo_readdata_max_3_high + adcfifo_readdata_max_2_high +adcfifo_readdata_max_1_high + adcfifo_readdata_0and1s_0 + 32767) ),
            //.indata(audio_high_wire*high_beishu +  audio_mid_wire+   audio_low_wire*low_beishu  + 32767),
            //.indata(audio_1_wire_0*beishu_1+audio_2_wire_0*beishu_2+audio_3_wire_0*beishu_3+audio_4_wire_0*beishu_4+audio_5_wire_0*beishu_5+audio_6_wire_0*beishu_6+audio_7_wire_0*beishu_7+audio_8_wire_0*beishu_8+ 32767),
            //.indata(dac_out_n1+ 32767),
            .indata((mode==3)?(data_low_adc_1 + 32767):((mode == 2)?(yout_0 + 32767):(data_dac_out_0+ 32767))),
            .endac(endac),
            .sclk(sclk),
            .SYNC_n(SYNC_n),
            .dout(dout)      
            
        );


    dac8550 dac8550_inst_2
    (
        .clk(dac_clk),//这里的4.8M实际上应该是192k  audio_mid_wire
        .rst_n(reset_n),
        //.indata(  ( adcfifo_readdata_max_3_low + adcfifo_readdata_max_2_low + adcfifo_readdata_max_1_low+ adcfifo_readdata_0and1s_1   + 32767) ),
        //.indata(audio_high_wire*high_beishu + audio_mid_wire +  audio_low_wire*low_beishu + 32767),
        //.indata(audio_1_wire_1*beishu_1+audio_2_wire_1*beishu_2+audio_3_wire_1*beishu_3+audio_4_wire_1*beishu_4+audio_5_wire_1*beishu_5+audio_6_wire_1*beishu_6+audio_7_wire_1*beishu_7+audio_8_wire_1*beishu_8+ 32767),
        //.indata(dac_out_n1+ 32767),
        .indata( (mode==3)?(data_low_adc_1 + 32767):((mode == 2)?(yout_0 + 32767):(data_dac_out_1+ 32767)) ),
        .endac(endac),
        .sclk(sclk_1),
        .SYNC_n(SYNC_n_1),
        .dout(dout_1)        

    );

endmodule

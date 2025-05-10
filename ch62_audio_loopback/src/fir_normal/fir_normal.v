  /***********************************************************
>> V201001 : Fs：50Mhz, fstop：1Mhz-6Mhz, order： 15
************************************************************/
/*

`define SAFE_DESIGN
 
module fir_normal    (
    input                rstn,  //复位，低有效
    input                clk,   //工作频率，即采样频率
    input                en,    //输入数据有效信号
    input        [15:0]  xin,   //输入混合频率的信号数据
    output               valid, //输出数据有效信号
    output       [28:0]  yout   //输出数据，低频信号，即250KHz
    );
 
    //data en delay 
    reg [3:0]            en_r ;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            en_r[3:0]      <= 'b0 ;
        end
        else begin
            en_r[3:0]      <= {en_r[2:0], en} ;
        end
    end
 
   //(1) 16 组移位寄存器
    reg        [15:0]    xin_reg[15:0];
    reg [3:0]            i, j ;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i=0; i<15; i=i+1) begin
                xin_reg[i]  <= 12'b0;
            end
        end
        else if (en) begin
            xin_reg[0] <= xin ;
            for (j=0; j<15; j=j+1) begin
                xin_reg[j+1] <= xin_reg[j] ; //周期性移位操作
            end
        end
    end
 
   //Only 8 multipliers needed because of the symmetry of FIR filter coefficient
   //(2) 系数对称，16个移位寄存器数据进行首位相加
    reg        [16:0]    add_reg[7:0];
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i=0; i<8; i=i+1) begin
                add_reg[i] <= 13'd0 ;
            end
        end
        else if (en_r[0]) begin
            for (i=0; i<8; i=i+1) begin
                add_reg[i] <= xin_reg[i] + xin_reg[15-i] ;
            end
        end
    end
 
    //(3) 8个乘法器
    // 滤波器系数，已经过一定倍数的放大
    wire        [15:0]   coe[7:0] ;

    assign coe[0]        = 12'd11 ;
    assign coe[1]        = 12'd31 ;
    assign coe[2]        = 12'd63 ;
    assign coe[3]        = 12'd104 ;
    assign coe[4]        = 12'd152 ;
    assign coe[5]        = 12'd198 ;
    assign coe[6]        = 12'd235 ;
    assign coe[7]        = 12'd255 ;


    assign coe[0]        = -16'd23    ;
    assign coe[1]        = -16'd26   ;
    assign coe[2]        = -16'd5  ;
    assign coe[3]        = 16'd49   ;
    assign coe[4]        = 16'd133   ;
    assign coe[5]        = 16'd231 ;
    assign coe[6]        = 16'd319  ;
    assign coe[7]        = 16'd371 ;

    reg        [29:0]   mout[7:0]; 
 
`ifdef SAFE_DESIGN
    //如果对时序要求不高，可以直接用乘号
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i=0 ; i<8; i=i+1) begin
                mout[i]     <= 25'b0 ;
            end
        end
        else if (en_r[1]) begin
            for (i=0 ; i<8; i=i+1) begin
                mout[i]     <= coe[i] * add_reg[i] ;
            end
        end
    end
    wire valid_mult7 = en_r[2];
 
`else


    //流水线式乘法器
    wire [7:0]          valid_mult ;
    genvar              k ;
    generate
        for (k=0; k<8; k=k+1) begin
            mult_man #(13, 12)
            u_mult_paral          (
              .clk        (clk),
              .rstn       (rstn),
              .data_rdy   (en_r[1]),
              .mult1      (add_reg[k]),
              .mult2      (coe[k]),
              .res_rdy    (valid_mult[k]), //所有输出使能完全一致  
              .res        (mout[k])
            );
        end
    endgenerate
    wire valid_mult7     = valid_mult[7] ;
`endif
 
    //(4) 积分累加，8组25bit数据 -> 1组 29bit 数据
    //数据有效延时
    reg [3:0]            valid_mult_r ;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_mult_r[3:0]  <= 'b0 ;
        end
        else begin
            valid_mult_r[3:0]  <= {valid_mult_r[2:0], valid_mult7} ;
        end
    end

`ifdef SAFE_DESIGN
    //加法运算时，分多个周期进行流水，优化时序
    reg        [28:0]    sum1 ;
    reg        [28:0]    sum2 ;
    reg        [28:0]    yout_t ;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sum1   <= 29'd0 ;
            sum2   <= 29'd0 ;
            yout_t <= 29'd0 ;
        end
        else if(valid_mult7) begin
            sum1   <= mout[0] + mout[1] + mout[2] + mout[3] ;
            sum2   <= mout[4] + mout[5] + mout[6] + mout[7] ;
            yout_t <= sum1 + sum2 ;
        end
    end
 
`else 
    //一步计算累加结果，但是实际中时序非常危险
    reg signed [28:0]    sum ;
    reg signed [28:0]    yout_t ;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sum    <= 29'd0 ;
            yout_t <= 29'd0 ;
        end
        else if (valid_mult7) begin
            sum    <= mout[0] + mout[1] + mout[2] + mout[3] + mout[4] + mout[5] + mout[6] + mout[7];
            yout_t <= sum ;
        end
    end 
`endif
    assign yout  = yout_t ;
    assign valid = valid_mult_r[0];

endmodule
*/
`define SAFE_DESIGN
 
module fir_normal    (
    input                rstn,  //复位，低有效
    input                clk,   //工作频率，即采样频率
    input                en,    //输入数据有效信号
    input     signed   [15:0]  xin,   //输入混合频率的信号数据
    input     signed   [15:0]  coef_0,
    input     signed   [15:0]  coef_1,
    input     signed   [15:0]  coef_2,
    input     signed   [15:0]  coef_3,
    input     signed   [15:0]  coef_4,
    input     signed   [15:0]  coef_5,
    input     signed   [15:0]  coef_6,
    input     signed   [15:0]  coef_7,

    output               valid, //输出数据有效信号
    output signed     [28:0]  yout,   //输出数据，低频信号，即250KHz
    output       [15:0]  hjhfak
    );
 
    //data en delay 
    reg [3:0]            en_r ;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            en_r[3:0]      <= 'b0 ;
        end
        else begin
            en_r[3:0]      <= {en_r[2:0], en} ;
        end
    end
 
   //(1) 16 组移位寄存器
    reg    signed    [15:0]    xin_reg[15:0];
    reg [3:0]            i, j ;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i=0; i<15; i=i+1) begin
                xin_reg[i]  <= 16'b0;
            end
        end
        else if (en) begin
            xin_reg[0] <= xin ;
            for (j=0; j<15; j=j+1) begin
                xin_reg[j+1] <= xin_reg[j] ; //周期性移位操作
            end
        end
    end
 
   //Only 8 multipliers needed because of the symmetry of FIR filter coefficient
   //(2) 系数对称，16个移位寄存器数据进行首位相加
    reg    signed    [16:0]    add_reg[7:0];
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i=0; i<8; i=i+1) begin
                add_reg[i] <= 16'd0 ;
            end
        end
        else if (en_r[0]) begin
            for (i=0; i<8; i=i+1) begin
                add_reg[i] <= xin_reg[i] + xin_reg[15-i] ;
            end
        end
    end
 
    //(3) 8个乘法器
    // 滤波器系数，已经过一定倍数的放大
    wire    signed    [15:0]   coe[7:0];
/*
    assign coe[0]        = -16'd48    ;
    assign coe[1]        = 16'd66   ;
    assign coe[2]        = -16'd89  ;
    assign coe[3]        = 16'd121   ;
    assign coe[4]        = -16'd167   ;
    assign coe[5]        = 16'd247 ;
    assign coe[6]        = -16'd426  ;
    assign coe[7]        = 16'd1301 ;
*/

//低通4K
/*
    assign coe[0]        = -16'd9    ;
    assign coe[1]        = -16'd5   ;
    assign coe[2]        = 16'd22  ;
    assign coe[3]        = 16'd79   ;
    assign coe[4]        = 16'd164   ;
    assign coe[5]        = 16'd262 ;
    assign coe[6]        = 16'd350  ;
    assign coe[7]        = 16'd402 ;
*/

    assign  coe[0]       = coef_0 ;
    assign  coe[1]       = coef_1 ;
    assign  coe[2]       = coef_2 ;
    assign  coe[3]       = coef_3 ;
    assign  coe[4]       = coef_4 ;
    assign  coe[5]       = coef_5 ;
    assign  coe[6]       = coef_6 ;
    assign  coe[7]       = coef_7 ;    


    reg    signed  [29:0]   mout[7:0];    //这里原来是reg
 
`ifdef SAFE_DESIGN

     //如果对时序要求不高，可以直接用乘号
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i=0 ; i<8; i=i+1) begin
                mout[i]     <= 25'b0 ;
            end
        end
        else if (en_r[1]) begin
            for (i=0 ; i<8; i=i+1) begin
                mout[i]     <= coe[i] * add_reg[i] ;
            end
        end
    end
    wire valid_mult7 = en_r[2];
`else
    //流水线式乘法器
    wire [7:0]          valid_mult ;
    genvar              k ;
    generate
        for (k=0; k<8; k=k+1) begin
            mult_man #(17, 16)
            u_mult_paral          (
              .clk        (clk),
              .rstn       (rstn),
              .data_rdy   (en_r[1]),
              .mult1      (add_reg[k]),
              .mult2      (coe[k]),
              .res_rdy    (valid_mult[k]), //所有输出使能完全一致  
              .res        (mout[k])
            );
        end
    endgenerate
    wire valid_mult7     = valid_mult[7] ;
`endif
 
    //(4) 积分累加，8组25bit数据 -> 1组 29bit 数据
    //数据有效延时
    reg [3:0]            valid_mult_r ;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_mult_r[3:0]  <= 'b0 ;
        end
        else begin
            valid_mult_r[3:0]  <= {valid_mult_r[2:0], valid_mult7} ;
        end
    end

`ifdef SAFE_DESIGN
    //加法运算时，分多个周期进行流水，优化时序
    reg        [28:0]    sum1 ;
    reg        [28:0]    sum2 ;
    reg        [28:0]    yout_t ;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sum1   <= 29'd0 ;
            sum2   <= 29'd0 ;
            yout_t <= 29'd0 ;
        end
        else if(valid_mult7) begin
            sum1   <= mout[0] + mout[1] + mout[2] + mout[3] ;
            sum2   <= mout[4] + mout[5] + mout[6] + mout[7] ;
            yout_t <= sum1 + sum2 ;
        end
    end
 
`else 
    //一步计算累加结果，但是实际中时序非常危险
    reg signed [28:0]    sum ;
    reg signed [28:0]    yout_t ;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sum    <= 29'd0 ;
            yout_t <= 29'd0 ;
        end
        else if (valid_mult7) begin
            sum    <= mout[0] + mout[1] + mout[2] + mout[3] + mout[4] + mout[5] + mout[6] + mout[7];
            yout_t <= sum ;
        end
    end 
`endif
    assign yout  = yout_t ;
    assign hjhfak = yout_t[23:8];
    assign valid = valid_mult_r[0];

endmodule

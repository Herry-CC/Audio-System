module Linear_Interpolation   
(
       input clk,
       input reset_n,
       input [31:0] adcfifo_readdata,
       input [5:0]  N,    //倍频的倍数
       output reg [15:0] chazhi_0,
       output reg [15:0] chazhi_1,
       output[31:0] chazhi_even
    
);




    reg [31:0] shuzu [1:0];         //插值用到的数组
    reg [31:0] shuzu_1[1:0];

    reg [2:0]  time_cnt;                //插值次数
    reg [2:0]  time_cnt_1;

    reg [10:0]  i;                   //插值点的次数
    reg [2:0]  j;
    initial time_cnt = 3'd0;    
    initial time_cnt_1 = 3'd0;
    initial i = 3'd1;         
    initial j = 3'd1;  
//    reg [15:0] chazhi_0;             //插值的左耳
//    reg [15:0] chazhi_1 ;            //插值的右耳
//    reg [31:0] chazhi_even  ;        //插值的最终


/*线性插值*/

    always @ (posedge clk or negedge reset_n)
    begin
      	if(~reset_n)
        begin
            i <= 1'b1;
            time_cnt <= 1'b0; 
            shuzu[0] <= 32'd0;
            shuzu[1] <= 32'd0;
        end
		else
        begin
            if( time_cnt == 0  )
            begin
                shuzu[1] <= adcfifo_readdata[31:16];
                shuzu[0] <= shuzu[1];
                time_cnt <= time_cnt + 1'b1;   
                chazhi_0 <= adcfifo_readdata[31:16];
            end
            
            if( time_cnt == 1 || time_cnt == 2 )
            begin
               if( time_cnt == 1 )
                begin
                       shuzu[1] <= adcfifo_readdata[31:16];
                       shuzu[0] <= shuzu[1];
                       time_cnt <= time_cnt + 1'b1;
                       i <= 'd1;
                       chazhi_0 <= 0;
               end
               if( i < N-1)
               begin
                    i <= i + 1;
                    //chazhi_0 <= chazhi_0 + 'd1;
                    //chazhi_0 <= (shuzu[1] - shuzu[0])*i/N + shuzu[0];
                    chazhi_0 <= 0;
               end
               if( i == N - 1'b1)
               begin
                    i <= i + 1;
                    chazhi_0 <= shuzu[1];
                    time_cnt <= 1;
               end
                
              /* if( i == N )
               begin
                    i <= 'd1;
                    time_cnt <= 1;
                   
               end
                */
            end
        end
    end


               

    always @ (posedge clk or negedge reset_n)
    begin
      	if(~reset_n)
        begin
            j <= 1'b1;
            time_cnt_1 <= 1'b0; 
            shuzu_1[0] <= 32'd0;
            shuzu_1[1] <= 32'd0;
        end
		else
        begin
            if( time_cnt_1 == 0  )
            begin
                shuzu_1[1] <= adcfifo_readdata[15:0];
                shuzu_1[0] <= shuzu_1[1];
                time_cnt_1 <= time_cnt_1 + 1'b1;   
                chazhi_1 <= adcfifo_readdata[15:0];
            end
            
            if( time_cnt_1 == 1 || time_cnt_1 == 2 )
            begin
               if( time_cnt_1 == 1 )
                begin
                       shuzu_1[1] <= adcfifo_readdata[15:0];
                       shuzu_1[0] <= shuzu_1[1];
                       time_cnt_1 <= time_cnt_1 + 1'b1;
                       j <= 1;
                       chazhi_1 <= 0;  
                end
               if( j < N -  1)
               begin
                    j <= j + 1;
                    //chazhi_1 <= (shuzu_1[1] - shuzu_1[0])*j/N + shuzu_1[0];
                    chazhi_1 <= 0;
               end
               if( j == N - 1)
               begin
                    j <= j + 1;
                    time_cnt_1 <= 1;
                    chazhi_1 <= shuzu_1[1];
               end
            end
        end
    end

assign chazhi_even = { chazhi_0,chazhi_1};

endmodule

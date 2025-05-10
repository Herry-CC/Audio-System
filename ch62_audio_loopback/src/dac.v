module dac
(
    input                       clk        ,  //fifo读时钟
    input                       reset_n    ,  
    input         [7:0]         da_data    ,  //DA输入数据
  

    output      reg  [7:0]      out_data   ,   //DA输出数据
    output                      dac_clk           //给DA模块的时钟
    
);
    
assign dac_clk = clk;

//reg     [25:0]   cnt;

/*    
always@(posedge clk)
    if(cnt >= 26'd49)                                                                                                                                                                     
        cnt <= 26'd0;
    else
        cnt <= cnt + 26'd1;
        
always@(posedge clk)
    if((out_data <= 8'd0) && (cnt == 26'd0))
        out_data <= 8'd255;
    else    if(cnt == 26'd0)
        out_data <= out_data - 8'd1;
*/
     
always@(posedge clk or negedge reset_n)
begin
    if(~reset_n)
    begin
        out_data <= 'd0;
    end
    else begin
        out_data <= 'd255 - da_data;
    end
end



endmodule
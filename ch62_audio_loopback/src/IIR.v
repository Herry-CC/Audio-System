module IIR_filter(
  input wire clk,
  input wire reset,
  input wire enable,
  input wire [15:0] x,
  output wire [15:0] y
);

reg signed [15:0] x_reg[2:0];
reg signed [15:0] y_reg[2:0];

//2048  
reg signed [11:0] b0;
reg signed [11:0] b1;
reg signed [11:0] b2;
reg signed [11:0] a1;
reg signed [11:0] a2;

initial
begin
        b0 = 'd2048  ;
        b1 =  -'d1270;
        b2 = 'd492   ;
        a1 = 'd318   ;
        a2 = 'd635   ;
end

always @(posedge clk or negedge reset) 
begin
    if (~reset)
    begin
      {x_reg[0], x_reg[1], x_reg[2]} <= 3'd0;
      {y_reg[0], y_reg[1], y_reg[2]} <= 3'd0;
    end
    else if (enable)
    begin
        {x_reg[0], x_reg[1], x_reg[2]} <= {x_reg[1], x_reg[2], x};
        {y_reg[0], y_reg[1], y_reg[2]} <= {y_reg[1], y_reg[2], b0*x_reg[0] + b1*x_reg[1] + b2*x_reg[2] - a1*y_reg[0] - a2*y_reg[1]};
    end
 end

  assign y = y_reg[2];
  
endmodule
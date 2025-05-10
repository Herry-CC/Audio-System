module AudioEqualizer (
    input clk, // 时钟信号
    input fliter_clk,
    input rst, // 复位信号
    input signed [15:0] audio_in, // 输入音频信号
    input signed [15:0] audio_low_wire,
    input signed [15:0] audio_mid_wire,
    input signed [15:0] audio_high_wire,

    input [3:0] eq_gain_low, // 低频增益设置，每个频段一个2位增益值
    input [3:0] eq_gain_mid, // 中频增益设置
    input [3:0] eq_gain_high, // 高频增益设置

    output reg [15:0] audio_out// 输出音频信号 
    
);

// 音频均衡器参数设置
parameter [7:0] GAIN_MAX = 64;  // 最大增益
parameter [7:0] GAIN_MIN = 0;   // 最小增益

reg  [15:0] audio_low;  // 低频信号  
reg  [15:0] audio_mid;  // 中频信号
reg  [15:0] audio_high; // 高频信号







/*
assign audio_low_wire = audio_low;
assign audio_mid_wire = audio_mid;
assign audio_high_wire = audio_high;
*/





always @ (posedge clk or negedge rst) begin
    if (~rst) begin
        audio_low <= 0;
        audio_mid <= 0;
        audio_high <= 0;
    end else begin
        // 频段调整audio_low_wire
        audio_low <=  audio_low_wire* (eq_gain_low - GAIN_MIN) / (GAIN_MAX - GAIN_MIN);
        audio_mid <= audio_mid_wire * (eq_gain_mid - GAIN_MIN) / (GAIN_MAX - GAIN_MIN);
        audio_high <= audio_high_wire * (eq_gain_high - GAIN_MIN) / (GAIN_MAX - GAIN_MIN);
    end
end


always @ (posedge clk or negedge rst) begin
    if (~rst)
        audio_out <= 0;
    else
        audio_out <= audio_low + audio_mid + audio_high; // 各频段信号叠加
end



endmodule
module gw_gao(
    \adcfifo_readdata[31] ,
    \adcfifo_readdata[30] ,
    \adcfifo_readdata[29] ,
    \adcfifo_readdata[28] ,
    \adcfifo_readdata[27] ,
    \adcfifo_readdata[26] ,
    \adcfifo_readdata[25] ,
    \adcfifo_readdata[24] ,
    \adcfifo_readdata[23] ,
    \adcfifo_readdata[22] ,
    \adcfifo_readdata[21] ,
    \adcfifo_readdata[20] ,
    \adcfifo_readdata[19] ,
    \adcfifo_readdata[18] ,
    \adcfifo_readdata[17] ,
    \adcfifo_readdata[16] ,
    \adcfifo_readdata[15] ,
    \adcfifo_readdata[14] ,
    \adcfifo_readdata[13] ,
    \adcfifo_readdata[12] ,
    \adcfifo_readdata[11] ,
    \adcfifo_readdata[10] ,
    \adcfifo_readdata[9] ,
    \adcfifo_readdata[8] ,
    \adcfifo_readdata[7] ,
    \adcfifo_readdata[6] ,
    \adcfifo_readdata[5] ,
    \adcfifo_readdata[4] ,
    \adcfifo_readdata[3] ,
    \adcfifo_readdata[2] ,
    \adcfifo_readdata[1] ,
    \adcfifo_readdata[0] ,
    \mode[3] ,
    \mode[2] ,
    \mode[1] ,
    \mode[0] ,
    \ADC_FS[10] ,
    \ADC_FS[9] ,
    \ADC_FS[8] ,
    \ADC_FS[7] ,
    \ADC_FS[6] ,
    \ADC_FS[5] ,
    \ADC_FS[4] ,
    \ADC_FS[3] ,
    \ADC_FS[2] ,
    \ADC_FS[1] ,
    \ADC_FS[0] ,
    \DAC_FS[10] ,
    \DAC_FS[9] ,
    \DAC_FS[8] ,
    \DAC_FS[7] ,
    \DAC_FS[6] ,
    \DAC_FS[5] ,
    \DAC_FS[4] ,
    \DAC_FS[3] ,
    \DAC_FS[2] ,
    \DAC_FS[1] ,
    \DAC_FS[0] ,
    clk_out_48k,
    clk_out_768k,
    dac_clk_normal,
    \LP[10] ,
    \LP[9] ,
    \LP[8] ,
    \LP[7] ,
    \LP[6] ,
    \LP[5] ,
    \LP[4] ,
    \LP[3] ,
    \LP[2] ,
    \LP[1] ,
    \LP[0] ,
    \high_beishu[3] ,
    \high_beishu[2] ,
    \high_beishu[1] ,
    \high_beishu[0] ,
    send_en,
    \coef_matlab[0][15] ,
    \coef_matlab[0][14] ,
    \coef_matlab[0][13] ,
    \coef_matlab[0][12] ,
    \coef_matlab[0][11] ,
    \coef_matlab[0][10] ,
    \coef_matlab[0][9] ,
    \coef_matlab[0][8] ,
    \coef_matlab[0][7] ,
    \coef_matlab[0][6] ,
    \coef_matlab[0][5] ,
    \coef_matlab[0][4] ,
    \coef_matlab[0][3] ,
    \coef_matlab[0][2] ,
    \coef_matlab[0][1] ,
    \coef_matlab[0][0] ,
    clk_19and2M,
    clk_48M,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \adcfifo_readdata[31] ;
input \adcfifo_readdata[30] ;
input \adcfifo_readdata[29] ;
input \adcfifo_readdata[28] ;
input \adcfifo_readdata[27] ;
input \adcfifo_readdata[26] ;
input \adcfifo_readdata[25] ;
input \adcfifo_readdata[24] ;
input \adcfifo_readdata[23] ;
input \adcfifo_readdata[22] ;
input \adcfifo_readdata[21] ;
input \adcfifo_readdata[20] ;
input \adcfifo_readdata[19] ;
input \adcfifo_readdata[18] ;
input \adcfifo_readdata[17] ;
input \adcfifo_readdata[16] ;
input \adcfifo_readdata[15] ;
input \adcfifo_readdata[14] ;
input \adcfifo_readdata[13] ;
input \adcfifo_readdata[12] ;
input \adcfifo_readdata[11] ;
input \adcfifo_readdata[10] ;
input \adcfifo_readdata[9] ;
input \adcfifo_readdata[8] ;
input \adcfifo_readdata[7] ;
input \adcfifo_readdata[6] ;
input \adcfifo_readdata[5] ;
input \adcfifo_readdata[4] ;
input \adcfifo_readdata[3] ;
input \adcfifo_readdata[2] ;
input \adcfifo_readdata[1] ;
input \adcfifo_readdata[0] ;
input \mode[3] ;
input \mode[2] ;
input \mode[1] ;
input \mode[0] ;
input \ADC_FS[10] ;
input \ADC_FS[9] ;
input \ADC_FS[8] ;
input \ADC_FS[7] ;
input \ADC_FS[6] ;
input \ADC_FS[5] ;
input \ADC_FS[4] ;
input \ADC_FS[3] ;
input \ADC_FS[2] ;
input \ADC_FS[1] ;
input \ADC_FS[0] ;
input \DAC_FS[10] ;
input \DAC_FS[9] ;
input \DAC_FS[8] ;
input \DAC_FS[7] ;
input \DAC_FS[6] ;
input \DAC_FS[5] ;
input \DAC_FS[4] ;
input \DAC_FS[3] ;
input \DAC_FS[2] ;
input \DAC_FS[1] ;
input \DAC_FS[0] ;
input clk_out_48k;
input clk_out_768k;
input dac_clk_normal;
input \LP[10] ;
input \LP[9] ;
input \LP[8] ;
input \LP[7] ;
input \LP[6] ;
input \LP[5] ;
input \LP[4] ;
input \LP[3] ;
input \LP[2] ;
input \LP[1] ;
input \LP[0] ;
input \high_beishu[3] ;
input \high_beishu[2] ;
input \high_beishu[1] ;
input \high_beishu[0] ;
input send_en;
input \coef_matlab[0][15] ;
input \coef_matlab[0][14] ;
input \coef_matlab[0][13] ;
input \coef_matlab[0][12] ;
input \coef_matlab[0][11] ;
input \coef_matlab[0][10] ;
input \coef_matlab[0][9] ;
input \coef_matlab[0][8] ;
input \coef_matlab[0][7] ;
input \coef_matlab[0][6] ;
input \coef_matlab[0][5] ;
input \coef_matlab[0][4] ;
input \coef_matlab[0][3] ;
input \coef_matlab[0][2] ;
input \coef_matlab[0][1] ;
input \coef_matlab[0][0] ;
input clk_19and2M;
input clk_48M;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \adcfifo_readdata[31] ;
wire \adcfifo_readdata[30] ;
wire \adcfifo_readdata[29] ;
wire \adcfifo_readdata[28] ;
wire \adcfifo_readdata[27] ;
wire \adcfifo_readdata[26] ;
wire \adcfifo_readdata[25] ;
wire \adcfifo_readdata[24] ;
wire \adcfifo_readdata[23] ;
wire \adcfifo_readdata[22] ;
wire \adcfifo_readdata[21] ;
wire \adcfifo_readdata[20] ;
wire \adcfifo_readdata[19] ;
wire \adcfifo_readdata[18] ;
wire \adcfifo_readdata[17] ;
wire \adcfifo_readdata[16] ;
wire \adcfifo_readdata[15] ;
wire \adcfifo_readdata[14] ;
wire \adcfifo_readdata[13] ;
wire \adcfifo_readdata[12] ;
wire \adcfifo_readdata[11] ;
wire \adcfifo_readdata[10] ;
wire \adcfifo_readdata[9] ;
wire \adcfifo_readdata[8] ;
wire \adcfifo_readdata[7] ;
wire \adcfifo_readdata[6] ;
wire \adcfifo_readdata[5] ;
wire \adcfifo_readdata[4] ;
wire \adcfifo_readdata[3] ;
wire \adcfifo_readdata[2] ;
wire \adcfifo_readdata[1] ;
wire \adcfifo_readdata[0] ;
wire \mode[3] ;
wire \mode[2] ;
wire \mode[1] ;
wire \mode[0] ;
wire \ADC_FS[10] ;
wire \ADC_FS[9] ;
wire \ADC_FS[8] ;
wire \ADC_FS[7] ;
wire \ADC_FS[6] ;
wire \ADC_FS[5] ;
wire \ADC_FS[4] ;
wire \ADC_FS[3] ;
wire \ADC_FS[2] ;
wire \ADC_FS[1] ;
wire \ADC_FS[0] ;
wire \DAC_FS[10] ;
wire \DAC_FS[9] ;
wire \DAC_FS[8] ;
wire \DAC_FS[7] ;
wire \DAC_FS[6] ;
wire \DAC_FS[5] ;
wire \DAC_FS[4] ;
wire \DAC_FS[3] ;
wire \DAC_FS[2] ;
wire \DAC_FS[1] ;
wire \DAC_FS[0] ;
wire clk_out_48k;
wire clk_out_768k;
wire dac_clk_normal;
wire \LP[10] ;
wire \LP[9] ;
wire \LP[8] ;
wire \LP[7] ;
wire \LP[6] ;
wire \LP[5] ;
wire \LP[4] ;
wire \LP[3] ;
wire \LP[2] ;
wire \LP[1] ;
wire \LP[0] ;
wire \high_beishu[3] ;
wire \high_beishu[2] ;
wire \high_beishu[1] ;
wire \high_beishu[0] ;
wire send_en;
wire \coef_matlab[0][15] ;
wire \coef_matlab[0][14] ;
wire \coef_matlab[0][13] ;
wire \coef_matlab[0][12] ;
wire \coef_matlab[0][11] ;
wire \coef_matlab[0][10] ;
wire \coef_matlab[0][9] ;
wire \coef_matlab[0][8] ;
wire \coef_matlab[0][7] ;
wire \coef_matlab[0][6] ;
wire \coef_matlab[0][5] ;
wire \coef_matlab[0][4] ;
wire \coef_matlab[0][3] ;
wire \coef_matlab[0][2] ;
wire \coef_matlab[0][1] ;
wire \coef_matlab[0][0] ;
wire clk_19and2M;
wire clk_48M;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top_0  u_la0_top(
    .control(control0[9:0]),
    .trig0_i(clk_out_48k),
    .data_i({\adcfifo_readdata[31] ,\adcfifo_readdata[30] ,\adcfifo_readdata[29] ,\adcfifo_readdata[28] ,\adcfifo_readdata[27] ,\adcfifo_readdata[26] ,\adcfifo_readdata[25] ,\adcfifo_readdata[24] ,\adcfifo_readdata[23] ,\adcfifo_readdata[22] ,\adcfifo_readdata[21] ,\adcfifo_readdata[20] ,\adcfifo_readdata[19] ,\adcfifo_readdata[18] ,\adcfifo_readdata[17] ,\adcfifo_readdata[16] ,\adcfifo_readdata[15] ,\adcfifo_readdata[14] ,\adcfifo_readdata[13] ,\adcfifo_readdata[12] ,\adcfifo_readdata[11] ,\adcfifo_readdata[10] ,\adcfifo_readdata[9] ,\adcfifo_readdata[8] ,\adcfifo_readdata[7] ,\adcfifo_readdata[6] ,\adcfifo_readdata[5] ,\adcfifo_readdata[4] ,\adcfifo_readdata[3] ,\adcfifo_readdata[2] ,\adcfifo_readdata[1] ,\adcfifo_readdata[0] ,\mode[3] ,\mode[2] ,\mode[1] ,\mode[0] ,\ADC_FS[10] ,\ADC_FS[9] ,\ADC_FS[8] ,\ADC_FS[7] ,\ADC_FS[6] ,\ADC_FS[5] ,\ADC_FS[4] ,\ADC_FS[3] ,\ADC_FS[2] ,\ADC_FS[1] ,\ADC_FS[0] ,\DAC_FS[10] ,\DAC_FS[9] ,\DAC_FS[8] ,\DAC_FS[7] ,\DAC_FS[6] ,\DAC_FS[5] ,\DAC_FS[4] ,\DAC_FS[3] ,\DAC_FS[2] ,\DAC_FS[1] ,\DAC_FS[0] ,clk_out_48k,clk_out_768k,dac_clk_normal,\LP[10] ,\LP[9] ,\LP[8] ,\LP[7] ,\LP[6] ,\LP[5] ,\LP[4] ,\LP[3] ,\LP[2] ,\LP[1] ,\LP[0] ,\high_beishu[3] ,\high_beishu[2] ,\high_beishu[1] ,\high_beishu[0] ,send_en,\coef_matlab[0][15] ,\coef_matlab[0][14] ,\coef_matlab[0][13] ,\coef_matlab[0][12] ,\coef_matlab[0][11] ,\coef_matlab[0][10] ,\coef_matlab[0][9] ,\coef_matlab[0][8] ,\coef_matlab[0][7] ,\coef_matlab[0][6] ,\coef_matlab[0][5] ,\coef_matlab[0][4] ,\coef_matlab[0][3] ,\coef_matlab[0][2] ,\coef_matlab[0][1] ,\coef_matlab[0][0] ,clk_19and2M}),
    .clk_i(clk_48M)
);

endmodule

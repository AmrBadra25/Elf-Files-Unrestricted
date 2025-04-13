import actuator_package::*;
import hwpe_ctrl_package::*;

module actuator_top
#(
  parameter int unsigned N_CORES = 1,
  parameter int unsigned MP  = 4,
  parameter int unsigned ID  = 10
)
(
  // global signals
  input  logic                                  clk_i,
  input  logic                                  rst_ni,
  input  logic                                  test_mode_i,
  // events
  output logic [N_CORES-1:0][REGFILE_N_EVT-1:0] evt_o,
  // tcdm master ports
  hwpe_stream_intf_tcdm.master                  tcdm[MP-1:0],
  // periph slave port
  hwpe_ctrl_intf_periph.slave                   periph
);

logic a10_r,a10_i,a30_r,a30_i,a50_r,a50_i;

  logic enable, clear;
  ctrl_streamer_t  streamer_ctrl;
  flags_streamer_t streamer_flags;
  ctrl_engine_t    engine_ctrl;
  flags_engine_t   engine_flags;

  hwpe_stream_intf_stream #(
    .DATA_WIDTH(32)
  ) in_r (
    .clk ( clk_i )
  );
  hwpe_stream_intf_stream #(
    .DATA_WIDTH(32)
  ) in_i (
    .clk ( clk_i )
  );
  hwpe_stream_intf_stream #(
    .DATA_WIDTH(32)
  ) out_r (
    .clk ( clk_i )
  );
  hwpe_stream_intf_stream #(
    .DATA_WIDTH(32)
  ) out_i (
    .clk ( clk_i )
  );

  actuator_engine i_engine (
    .clk_i            ( clk_i          ),
    .rst_ni           ( rst_ni         ),
    .test_mode_i      ( test_mode_i    ),
    .in_r_i           ( in_r.sink      ),
    .in_i_i           ( in_i.sink      ),
    .a10_r_i          (a10_r),
    .a10_i_i          (a10_i),
    .a30_r_i          (a30_r),
    .a30_i_i          (a30_i),
    .a50_r_i          (a50_r),
    .a50_i_i          (a50_i),
    .out_r_o          ( out_r.source   ),
    .out_i_o          ( out_i.source   ),
    .ctrl_i           ( engine_ctrl    ),
    .flags_o          ( engine_flags   )
  );

  actuator_streamer #(
    .MP ( MP )
  ) i_streamer (
    .clk_i            ( clk_i          ),
    .rst_ni           ( rst_ni         ),
    .test_mode_i      ( test_mode_i    ),
    .enable_i         ( enable         ),
    .clear_i          ( clear          ),
    .in_r_o           ( in_r.source       ),
    .in_i_o           ( in_i.source       ),
    .out_r_i          ( out_r.sink         ),
    .out_i_i          ( out_i.sink         ),
    .tcdm             ( tcdm           ),
    .ctrl_i           ( streamer_ctrl  ),
    .flags_o          ( streamer_flags )
  );

  actuator_ctrl #(
    .N_CORES   ( 1  ),
    .N_CONTEXT ( 2  ),
    .N_IO_REGS ( 16 ), //check how many registers we will need to control this thing.
    .ID ( ID )
  ) i_ctrl (
    .clk_i            ( clk_i          ),
    .rst_ni           ( rst_ni         ),
    .test_mode_i      ( test_mode_i    ),
    .evt_o            ( evt_o          ),
    .a10_r_out        ( a10_r          ),
    .a10_i_out        ( a10_i          ),
    .a30_r_out        ( a30_r          ),
    .a30_i_out        ( a30_i          ),
    .a50_r_out        ( a50_r          ),
    .a50_i_out        ( a50_i          ),
    .clear_o          ( clear          ),
    .ctrl_streamer_o  ( streamer_ctrl  ), //output control signals for the streamer
    .flags_streamer_i ( streamer_flags ), //flags coming from the streamer to control
    .ctrl_engine_o    ( engine_ctrl    ), //output control signals for the engine
    .flags_engine_i   ( engine_flags   ), //flags coming from the engine to control 
    .periph           ( periph         )
  );

  assign enable = 1'b1;

endmodule // actuator_top
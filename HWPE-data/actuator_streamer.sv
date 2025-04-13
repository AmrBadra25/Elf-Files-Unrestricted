import actuator_package::*;
import hwpe_stream_package::*;

module mac_streamer
#(
  parameter int unsigned MP = 4, 
  parameter int unsigned FD = 2  
)
(
  // global signals
  input  logic                   clk_i,
  input  logic                   rst_ni,
  input  logic                   test_mode_i,
  // local enable & clear
  input  logic                   enable_i,
  input  logic                   clear_i,

  // input in_r stream + handshake
  hwpe_stream_intf_stream.source in_r_o, 
  // input in_i stream + handshake
  hwpe_stream_intf_stream.source in_i_o,
  // output out_r stream + handshake
  hwpe_stream_intf_stream.sink   out_r_i,
  // output out_i stream + handshake
  hwpe_stream_intf_stream.sink   out_i_i,

  // TCDM ports
  hwpe_stream_intf_tcdm.master tcdm [MP-1:0],


  // control channel
  input  ctrl_streamer_t  ctrl_i,  
  output flags_streamer_t flags_o 
);

  logic in_r_tcdm_fifo_ready, in_i_tcdm_fifo_ready;


  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( 32 )
  ) in_r_prefifo (
    .clk ( clk_i )
  );
  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( 32 )
  ) in_i_prefifo (
    .clk ( clk_i )
  );
  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( 32 )
  ) out_r_postfifo (
    .clk ( clk_i )
  );
  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( 32 )
  ) out_i_postfifo (
    .clk ( clk_i )
  ); 

//instantiate more HWPE-Mem interfaces

  hwpe_stream_intf_tcdm tcdm_fifo [MP-1:0] (
    .clk ( clk_i )
  );
  hwpe_stream_intf_tcdm tcdm_fifo_0 [0:0] (
    .clk ( clk_i )
  );
  hwpe_stream_intf_tcdm tcdm_fifo_1 [0:0] (
    .clk ( clk_i )
  );
  hwpe_stream_intf_tcdm tcdm_fifo_8 [0:0] (
    .clk ( clk_i )
  );
  hwpe_stream_intf_tcdm tcdm_fifo_9 [0:0] (
    .clk ( clk_i )
  );


  
  hwpe_stream_source #(
    .DATA_WIDTH ( 32 ),
    .DECOUPLED  ( 1  )
  ) i_in_r_source (
    .clk_i              ( clk_i                  ),
    .rst_ni             ( rst_ni                 ),
    .test_mode_i        ( test_mode_i            ),
    .clear_i            ( clear_i                ),
    .tcdm               ( tcdm_fifo_0            ), // this syntax is necessary for Verilator as hwpe_stream_source expects an array of interfaces
    .stream             ( in_r_prefifo.source       ),
    .ctrl_i             ( ctrl_i.in_r_source_ctrl   ),
    .flags_o            ( flags_o.in_r_source_flags ),
    .tcdm_fifo_ready_o  ( in_r_tcdm_fifo_ready      )
  );


  hwpe_stream_source #(
    .DATA_WIDTH ( 32 ),
    .DECOUPLED  ( 1  )
  ) i_in_i_source (
    .clk_i              ( clk_i                  ),
    .rst_ni             ( rst_ni                 ),
    .test_mode_i        ( test_mode_i            ),
    .clear_i            ( clear_i                ),
    .tcdm               ( tcdm_fifo_1            ), // this syntax is necessary for Verilator as hwpe_stream_source expects an array of interfaces
    .stream             ( in_i_prefifo.source       ),
    .ctrl_i             ( ctrl_i.in_i_source_ctrl   ),
    .flags_o            ( flags_o.in_i_source_flags ),
    .tcdm_fifo_ready_o  ( in_i_tcdm_fifo_ready      )
  );

  hwpe_stream_sink #(
    .DATA_WIDTH ( 32 )
  ) i_out_r_sink (
    .clk_i       ( clk_i                ),
    .rst_ni      ( rst_ni               ),
    .test_mode_i ( test_mode_i          ),
    .clear_i     ( clear_i              ),
    .tcdm        ( tcdm_fifo_8          ), // this syntax is necessary for Verilator as hwpe_stream_source expects an array of interfaces
    .stream      ( out_r_postfifo.sink      ),
    .ctrl_i      ( ctrl_i.out_r_sink_ctrl   ),
    .flags_o     ( flags_o.out_r_sink_flags )
  );

  hwpe_stream_sink #(
    .DATA_WIDTH ( 32 )
  ) i_out_i_sink (
    .clk_i       ( clk_i                ),
    .rst_ni      ( rst_ni               ),
    .test_mode_i ( test_mode_i          ),
    .clear_i     ( clear_i              ),
    .tcdm        ( tcdm_fifo_9          ), // this syntax is necessary for Verilator as hwpe_stream_source expects an array of interfaces
    .stream      ( out_i_postfifo.sink      ),
    .ctrl_i      ( ctrl_i.out_i_sink_ctrl   ),
    .flags_o     ( flags_o.out_i_sink_flags )
  );


  hwpe_stream_tcdm_fifo_load #(
    .FIFO_DEPTH ( 4 )
  ) i_in_r_tcdm_fifo_load (
    .clk_i       ( clk_i             ),
    .rst_ni      ( rst_ni            ),
    .clear_i     ( clear_i           ),
    .flags_o     (                   ),
    .ready_i     ( in_r_tcdm_fifo_ready ),
    .tcdm_slave  ( tcdm_fifo_0[0]    ),
    .tcdm_master ( tcdm      [0]     )
  );

  hwpe_stream_tcdm_fifo_load #(
    .FIFO_DEPTH ( 4 )
  ) i_in_i_tcdm_fifo_load (
    .clk_i       ( clk_i             ),
    .rst_ni      ( rst_ni            ),
    .clear_i     ( clear_i           ),
    .flags_o     (                   ),
    .ready_i     ( in_i_tcdm_fifo_ready ),
    .tcdm_slave  ( tcdm_fifo_1[0]    ),
    .tcdm_master ( tcdm      [1]     )
  );

  hwpe_stream_tcdm_fifo_store #(
    .FIFO_DEPTH ( 4 )
  ) i_out_r_tcdm_fifo_store (
    .clk_i       ( clk_i          ),
    .rst_ni      ( rst_ni         ),
    .clear_i     ( clear_i        ),
    .flags_o     (                ),
    .tcdm_slave  ( tcdm_fifo_8[0] ),
    .tcdm_master ( tcdm       [2] )
  );

  hwpe_stream_tcdm_fifo_store #(
    .FIFO_DEPTH ( 4 )
  ) i_out_i_tcdm_fifo_store (
    .clk_i       ( clk_i          ),
    .rst_ni      ( rst_ni         ),
    .clear_i     ( clear_i        ),
    .flags_o     (                ),
    .tcdm_slave  ( tcdm_fifo_9[0] ),
    .tcdm_master ( tcdm       [3] )
  );

  hwpe_stream_fifo #(
    .DATA_WIDTH( 32 ),
    .FIFO_DEPTH( 2  ),
    .LATCH_FIFO( 0  )
  ) i_in_r_fifo (
    .clk_i   ( clk_i          ),
    .rst_ni  ( rst_ni         ),
    .clear_i ( clear_i        ),
    .push_i  ( in_r_prefifo.sink ),
    .pop_o   ( in_r_o            ),
    .flags_o (                )
  );

  hwpe_stream_fifo #(
    .DATA_WIDTH( 32 ),
    .FIFO_DEPTH( 2  ),
    .LATCH_FIFO( 0  )
  ) i_in_i_fifo (
    .clk_i   ( clk_i          ),
    .rst_ni  ( rst_ni         ),
    .clear_i ( clear_i        ),
    .push_i  ( in_i_prefifo.sink ),
    .pop_o   ( in_i_o            ),
    .flags_o (                )
  );

  hwpe_stream_fifo #(
    .DATA_WIDTH( 32 ),
    .FIFO_DEPTH( 2  ),
    .LATCH_FIFO( 0  )
  ) i_out_r_fifo (
    .clk_i   ( clk_i             ),
    .rst_ni  ( rst_ni            ),
    .clear_i ( clear_i           ),
    .push_i  ( out_r_i               ),
    .pop_o   ( out_r_postfifo.source ),
    .flags_o (                   )
  );

  hwpe_stream_fifo #(
    .DATA_WIDTH( 32 ),
    .FIFO_DEPTH( 2  ),
    .LATCH_FIFO( 0  )
  ) i_out_i_fifo (
    .clk_i   ( clk_i             ),
    .rst_ni  ( rst_ni            ),
    .clear_i ( clear_i           ),
    .push_i  ( out_i_i               ),
    .pop_o   ( out_i_postfifo.source ),
    .flags_o (                   )
  );

endmodule // actuator_streamer
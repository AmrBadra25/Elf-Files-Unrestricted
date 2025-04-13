import hwpe_stream_package::*;

package actuator_package;

  // registers in register file
  parameter int unsigned MAC_REG_IN_R_ADDR           = 0;
  parameter int unsigned MAC_REG_IN_I_ADDR           = 1;
  parameter int unsigned MAC_REG_A10_R_DATA          = 2;
  parameter int unsigned MAC_REG_A10_I_DATA          = 3;
  parameter int unsigned MAC_REG_A30_R_DATA          = 4;
  parameter int unsigned MAC_REG_A30_I_DATA          = 5;
  parameter int unsigned MAC_REG_A50_R_DATA          = 6;
  parameter int unsigned MAC_REG_A50_I_DATA          = 7;
  parameter int unsigned MAC_REG_OUT_R_ADDR          = 8;
  parameter int unsigned MAC_REG_OUT_I_ADDR          = 9;
  parameter int unsigned MAC_REG_NB_ITER             = 10;
  parameter int unsigned MAC_REG_LEN_ITER            = 11; //we likely don't need this SIMPLEMUL option since it's not a feature in our design.
  parameter int unsigned MAC_REG_SHIFT_VECTSTRIDE    = 12; //interesting, look into

  // microcode offset indeces -- this should be aligned to the microcode compiler of course!
  parameter int unsigned MAC_UCODE_IN_R_OFFS = 0;
  parameter int unsigned MAC_UCODE_IN_I_OFFS = 1;
  // parameter int unsigned MAC_UCODE_A10_R_OFFS = 2;
  // parameter int unsigned MAC_UCODE_A10_I_OFFS = 3; //look into.
  // parameter int unsigned MAC_UCODE_A30_R_OFFS = 4;
  // parameter int unsigned MAC_UCODE_A30_I_OFFS = 5;
  // parameter int unsigned MAC_UCODE_A50_R_OFFS = 6;  
  // parameter int unsigned MAC_UCODE_A50_I_OFFS = 7;  
  parameter int unsigned MAC_UCODE_OUT_R_OFFS = 8;  
  parameter int unsigned MAC_UCODE_OUT_I_OFFS = 9;  

  // microcode mnemonics -- this should be aligned to the microcode compiler of course!
  parameter int unsigned MAC_UCODE_MNEM_NBITER     = 4 - 4;
  parameter int unsigned MAC_UCODE_MNEM_ITERSTRIDE = 5 - 4;
  parameter int unsigned MAC_UCODE_MNEM_ONESTRIDE  = 6 - 4; //look into.

  typedef struct packed {
    logic clear;
    logic enable;
    logic start;
  } ctrl_engine_t; 

  typedef struct packed {
    logic done; 
  } flags_engine_t;

  typedef struct packed {
    hwpe_stream_package::ctrl_sourcesink_t in_r_source_ctrl;
    hwpe_stream_package::ctrl_sourcesink_t in_i_source_ctrl;
    hwpe_stream_package::ctrl_sourcesink_t out_r_sink_ctrl;
    hwpe_stream_package::ctrl_sourcesink_t out_i_sink_ctrl;
  } ctrl_streamer_t;

  typedef struct packed {
    hwpe_stream_package::flags_sourcesink_t in_r_source_flags;
    hwpe_stream_package::flags_sourcesink_t in_i_source_flags;
    hwpe_stream_package::flags_sourcesink_t out_r_sink_flags;
    hwpe_stream_package::flags_sourcesink_t out_i_sink_flags;
  } flags_streamer_t;

  typedef struct packed {
    logic unsigned [$clog2(MAC_CNT_LEN):0] len; // 1 bit more as cnt starts from 1, not 0
  } ctrl_fsm_t;

  typedef enum {
    FSM_IDLE,
    FSM_START,
    FSM_COMPUTE,
    FSM_WAIT,
    FSM_UPDATEIDX,
    FSM_TERMINATE
  } state_fsm_t;

endpackage // actuator_package
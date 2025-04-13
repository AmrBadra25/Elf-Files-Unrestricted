

import actuator_package::*;
import hwpe_ctrl_package::*;

module actuator_fsm (
  // global signals
  input  logic                clk_i,
  input  logic                rst_ni,
  input  logic                test_mode_i,
  input  logic                clear_i,
  // ctrl & flags
  output ctrl_streamer_t      ctrl_streamer_o,
  input  flags_streamer_t     flags_streamer_i,
  output ctrl_engine_t        ctrl_engine_o,
  input  flags_engine_t       flags_engine_i,
  output ctrl_uloop_t         ctrl_uloop_o,
  input  flags_uloop_t        flags_uloop_i,
  output ctrl_slave_t         ctrl_slave_o,
  input  flags_slave_t        flags_slave_i,
  input  ctrl_regfile_t       reg_file_i,
  input  ctrl_fsm_t           ctrl_i
);

  state_fsm_t curr_state, next_state; //check how we'll need to edit state_fsm_t

  always_ff @(posedge clk_i or negedge rst_ni)
  begin : main_fsm_seq
    if(~rst_ni) begin
      curr_state <= FSM_IDLE;
    end
    else if(clear_i) begin
      curr_state <= FSM_IDLE;
    end
    else begin
      curr_state <= next_state;
    end
  end

  always_comb
  begin : main_fsm_comb
    // direct mappings - these have to be here due to blocking/non-blocking assignment
    // combination with the same ctrl_engine_o/ctrl_streamer_o variable
    // shift-by-3 due to conversion from bits to bytes
    // in_r stream
    ctrl_streamer_o.in_r_source_ctrl.addressgen_ctrl.trans_size  = 1;
    ctrl_streamer_o.in_r_source_ctrl.addressgen_ctrl.line_stride = '0;
    ctrl_streamer_o.in_r_source_ctrl.addressgen_ctrl.line_length = 1;
    ctrl_streamer_o.in_r_source_ctrl.addressgen_ctrl.feat_stride = '0;
    ctrl_streamer_o.in_r_source_ctrl.addressgen_ctrl.feat_length = 1;
    ctrl_streamer_o.in_r_source_ctrl.addressgen_ctrl.base_addr   = reg_file_i.hwpe_params[MAC_REG_IN_R_ADDR] + (flags_uloop_i.offs[MAC_UCODE_IN_R_OFFS]);
    ctrl_streamer_o.in_r_source_ctrl.addressgen_ctrl.feat_roll   = '0;
    ctrl_streamer_o.in_r_source_ctrl.addressgen_ctrl.loop_outer  = '0;
    ctrl_streamer_o.in_r_source_ctrl.addressgen_ctrl.realign_type = '0;
    // in_i stream
    ctrl_streamer_o.in_i_source_ctrl.addressgen_ctrl.trans_size  = 1;
    ctrl_streamer_o.in_i_source_ctrl.addressgen_ctrl.line_stride = '0;
    ctrl_streamer_o.in_i_source_ctrl.addressgen_ctrl.line_length = 1;
    ctrl_streamer_o.in_i_source_ctrl.addressgen_ctrl.feat_stride = '0;
    ctrl_streamer_o.in_i_source_ctrl.addressgen_ctrl.feat_length = 1;
    ctrl_streamer_o.in_i_source_ctrl.addressgen_ctrl.base_addr   = reg_file_i.hwpe_params[MAC_REG_IN_I_ADDR] + (flags_uloop_i.offs[MAC_UCODE_IN_I_OFFS]);
    ctrl_streamer_o.in_i_source_ctrl.addressgen_ctrl.feat_roll   = '0;
    ctrl_streamer_o.in_i_source_ctrl.addressgen_ctrl.loop_outer  = '0;
    ctrl_streamer_o.in_i_source_ctrl.addressgen_ctrl.realign_type = '0;
    // out_r stream
    ctrl_streamer_o.out_r_sink_ctrl.addressgen_ctrl.trans_size  = 1;
    ctrl_streamer_o.out_r_sink_ctrl.addressgen_ctrl.line_stride = '0;
    ctrl_streamer_o.out_r_sink_ctrl.addressgen_ctrl.line_length = 1;
    ctrl_streamer_o.out_r_sink_ctrl.addressgen_ctrl.feat_stride = '0;
    ctrl_streamer_o.out_r_sink_ctrl.addressgen_ctrl.feat_length = 1;
    ctrl_streamer_o.out_r_sink_ctrl.addressgen_ctrl.base_addr   = reg_file_i.hwpe_params[MAC_REG_OUT_R_ADDR] + (flags_uloop_i.offs[MAC_UCODE_OUT_R_OFFS]);
    ctrl_streamer_o.out_r_sink_ctrl.addressgen_ctrl.feat_roll   = '0;
    ctrl_streamer_o.out_r_sink_ctrl.addressgen_ctrl.loop_outer  = '0;
    ctrl_streamer_o.out_r_sink_ctrl.addressgen_ctrl.realign_type = '0;
    // out_i stream
    ctrl_streamer_o.out_i_sink_ctrl.addressgen_ctrl.trans_size  = 1;
    ctrl_streamer_o.out_i_sink_ctrl.addressgen_ctrl.line_stride = '0;
    ctrl_streamer_o.out_i_sink_ctrl.addressgen_ctrl.line_length = 1;
    ctrl_streamer_o.out_i_sink_ctrl.addressgen_ctrl.feat_stride = '0;
    ctrl_streamer_o.out_i_sink_ctrl.addressgen_ctrl.feat_length = 1;
    ctrl_streamer_o.out_i_sink_ctrl.addressgen_ctrl.base_addr   = reg_file_i.hwpe_params[MAC_REG_OUT_I_ADDR] + (flags_uloop_i.offs[MAC_UCODE_OUT_I_OFFS]);
    ctrl_streamer_o.out_i_sink_ctrl.addressgen_ctrl.feat_roll   = '0;
    ctrl_streamer_o.out_i_sink_ctrl.addressgen_ctrl.loop_outer  = '0;
    ctrl_streamer_o.out_i_sink_ctrl.addressgen_ctrl.realign_type = '0;

    // engine
    ctrl_engine_o.clear      = '1;
    ctrl_engine_o.enable     = '1;
    ctrl_engine_o.start      = '0;

    // slave
    ctrl_slave_o.done = '0;
    ctrl_slave_o.evt  = '0;

    // real finite-state machine
    next_state   = curr_state;
    ctrl_streamer_o.in_r_source_ctrl.req_start  = '0;
    ctrl_streamer_o.in_i_source_ctrl.req_start  = '0;
    ctrl_streamer_o.out_r_sink_ctrl.req_start   = '0;
    ctrl_streamer_o.out_i_sink_ctrl.req_start   = '0;
    ctrl_uloop_o.enable                         = '0;
    ctrl_uloop_o.clear                          = '0;
    ctrl_uloop_o.ready                          = 1'b1;

    case(curr_state)
      FSM_IDLE: begin
        // wait for a start signal
        ctrl_uloop_o.clear = '1;
        if(flags_slave_i.start) begin
          next_state = FSM_START;
        end
      end
      FSM_START: begin
        // update the indeces, then load the first feature
        if(flags_streamer_i.in_r_source_flags.ready_start &
           flags_streamer_i.in_i_source_flags.ready_start &
           flags_streamer_i.out_r_sink_flags.ready_start &
           flags_streamer_i.out_i_sink_flags.ready_start) begin
          next_state  = FSM_COMPUTE;

          ctrl_engine_o.start  = 1'b1;
          ctrl_engine_o.clear  = 1'b0;
          ctrl_engine_o.enable = 1'b1;

          ctrl_streamer_o.in_r_source_ctrl.req_start  = 1'b1;
          ctrl_streamer_o.in_i_source_ctrl.req_start  = 1'b1;
          ctrl_streamer_o.out_r_sink_ctrl.req_start   = 1'b1;
          ctrl_streamer_o.out_i_sink_ctrl.req_start   = 1'b1;

        end
        else begin
          next_state = FSM_WAIT;
        end
      end
      FSM_COMPUTE: begin
        ctrl_engine_o.clear  = 1'b0;
        // compute, then update the indeces (and write output if necessary)
        if(flags_engine_i.done) begin
          next_state = FSM_UPDATEIDX;
        end
      end
      FSM_UPDATEIDX: begin
        // update the indeces, then go back to load or idle
        if(flags_uloop_i.valid == 1'b0) begin
          ctrl_uloop_o.enable = 1'b1;
        end
        else if(flags_uloop_i.done) begin
          next_state = FSM_TERMINATE;
        end
        else if(flags_streamer_i.in_r_source_flags.ready_start &
                flags_streamer_i.in_i_source_flags.ready_start &
                flags_streamer_i.out_r_sink_flags.ready_start &
                flags_streamer_i.out_i_sink_flags.ready_start) begin

          next_state = FSM_COMPUTE;
          ctrl_engine_o.start  = 1'b1;
          ctrl_engine_o.clear  = 1'b0;
          ctrl_engine_o.enable = 1'b1;

          ctrl_streamer_o.in_r_source_ctrl.req_start  = 1'b1;
          ctrl_streamer_o.in_i_source_ctrl.req_start  = 1'b1;
          ctrl_streamer_o.out_r_sink_ctrl.req_start   = 1'b1;
          ctrl_streamer_o.out_i_sink_ctrl.req_start   = 1'b1;
        end
        else begin
          next_state = FSM_WAIT;
        end
      end
      FSM_WAIT: begin
        // wait for the flags to be ok then go back to load
        ctrl_engine_o.clear  = 1'b0;
        ctrl_engine_o.enable = 1'b0;
        ctrl_uloop_o.enable  = 1'b0;
        if(flags_streamer_i.in_r_source_flags.ready_start &
           flags_streamer_i.in_i_source_flags.ready_start &
           flags_streamer_i.out_r_sink_flags.ready_start &
           flags_streamer_i.out_i_sink_flags.ready_start) begin

          next_state = FSM_COMPUTE;
          ctrl_engine_o.start = 1'b1;
          ctrl_engine_o.enable = 1'b1;

          ctrl_streamer_o.in_r_source_ctrl.req_start  = 1'b1;
          ctrl_streamer_o.in_i_source_ctrl.req_start  = 1'b1;
          ctrl_streamer_o.out_r_sink_ctrl.req_start   = 1'b1;
          ctrl_streamer_o.out_i_sink_ctrl.req_start   = 1'b1;
        end
      end
      FSM_TERMINATE: begin
        // wait for the flags to be ok then go back to idle
        ctrl_engine_o.clear  = 1'b0;
        ctrl_engine_o.enable = 1'b0;
        if(flags_streamer_i.in_r_source_flags.ready_start &
           flags_streamer_i.in_i_source_flags.ready_start &
           flags_streamer_i.out_r_sink_flags.ready_start &
           flags_streamer_i.out_i_sink_flags.ready_start) begin
          next_state = FSM_IDLE;
          ctrl_slave_o.done = 1'b1;
        end
      end
    endcase // curr_state
  end

endmodule // actuator_fsm

import actuator_package::*;

module actuator_engine
(
  // global signals
  input  logic                   clk_i,
  input  logic                   rst_ni,
  input  logic                   test_mode_i,
  // input streams
  hwpe_stream_intf_stream.sink   in_r_i,
  hwpe_stream_intf_stream.sink   in_i_i,
  hwpe_stream_intf_stream.sink   a10_r_i,
  hwpe_stream_intf_stream.sink   a10_i_i,
  hwpe_stream_intf_stream.sink   a30_r_i,
  hwpe_stream_intf_stream.sink   a30_i_i,
  hwpe_stream_intf_stream.sink   a50_r_i,
  hwpe_stream_intf_stream.sink   a50_i_i,
  // output streams
  hwpe_stream_intf_stream.source out_r_o,
  hwpe_stream_intf_stream.source out_i_o,
  // control channel
  input  ctrl_engine_t           ctrl_i,
  output flags_engine_t          flags_o
);

  //if ctrl_i.enable is true, we want to sample the data coming from the streamer and start operating on it, operation takes 6 cycles

  logic [31:0] in_r_sample_i;
  logic [31:0] in_i_sample_i;
  logic [31:0] a10_r_sample_i;
  logic [31:0] a10_i_sample_i;
  logic [31:0] a30_r_sample_i;
  logic [31:0] a30_i_sample_i;
  logic [31:0] a50_r_sample_i;
  logic [31:0] a50_i_sample_i;
  logic [31:0] out_r_wire_o;
  logic [31:0] out_i_wire_o;
  logic [31:0] out_r_sample_o;
  logic [31:0] out_i_sample_o;
  logic [ 2:0] counter;


always@(posedge clk_i or negedge rst_ni)begin
    if(~rst_ni or ctrl_i.clear)begin

        in_r_sample_i   <= 32'b0;
        in_i_sample_i   <= 32'b0;
        a10_r_sample_i  <= 32'b0;
        a10_i_sample_i  <= 32'b0;
        a30_r_sample_i  <= 32'b0;
        a30_i_sample_i  <= 32'b0;
        a50_r_sample_i  <= 32'b0;
        a50_i_sample_i  <= 32'b0;
        out_r_sample_o  <= 32'b0;
        out_i_sample_o  <= 32'b0;

    end
    else if(!counter & ctrl_i.enable & in_r_i.valid & in_r_i.ready & a10_r_i.valid & a30_r_i.valid & a50_r_i.valid & a10_r_i.ready & a30_r_i.ready & a50_r_i.ready & a10_i_i.valid & a30_i_i.valid & a50_i_i.valid & a10_i_i.ready & a30_i_i.ready & a50_i_i.ready)begin
        
        in_r_sample_i   <= in_r.data;
        in_i_sample_i   <= in_i.data;
        a10_r_sample_i  <= a10_r.data;
        a10_i_sample_i  <= a10_i.data;
        a30_r_sample_i  <= a30_r.data;
        a30_i_sample_i  <= a30_i.data;
        a50_r_sample_i  <= a50_r.data;
        a50_i_sample_i  <= a50_i.data;

    end
end

//pass the data to the actuator core and wait 6 clock cycles to get the output

actuator_core core (

    .clk_368 (clk_i                  ),
    .rst_n   (rst_ni                 ),
    .in_r    (in_r_sample_i[17:0]    ),
    .in_i    (in_i_sample_i[17:0]    ),
    .a10_r   (a10_r_sample_i[17:0]   ),
    .a10_i   (a10_i_sample_i[17:0]   ),
    .a30_r   (a30_r_sample_i[17:0]   ),
    .a30_i   (a30_i_sample_i[17:0]   ),
    .a50_r   (a50_r_sample_i[17:0]   ),
    .a50_i   (a50_i_sample_i[17:0]   ),
    .out_r   (out_r_wire_o[17:0]   ),
    .out_i   (out_i_wire_o[17:0]   )

);

//now since the enable is raised we require 1 clock cycle to register the data, then 6 clock cycles to process them, which means we expect the output 7 cycles after.

always@(posedge clk_i or negedge rst_ni)begin
    if(~rst_ni or ctrl_i.clear)begin
        counter <= 3'b0;
    end
    else if(!counter & ctrl_i.enable & in_r_i.valid & in_r_i.ready & a10_r_i.valid & a30_r_i.valid & a50_r_i.valid & a10_r_i.ready & a30_r_i.ready & a50_r_i.ready & a10_i_i.valid & a30_i_i.valid & a50_i_i.valid & a10_i_i.ready & a30_i_i.ready & a50_i_i.ready)begin
        counter <= 3'b1;
    end
    else if(counter != 0)
        counter = counter + 1;
end

//now we should extract our output on a register when counter is 7

always@(posedge clk_i or negedge rst_ni)begin
    if(counter == 3'b111)begin
        out_r_sample_o <= out_r_wire_o;
        out_i_sample_o <= out_r_wire_o;
    end
end

//now we want to output this data to the tcdm again

always_comb begin
    out_r_o.data  = out_r_sample_o;
    out_i_o.data  = out_i_sample_o;
    out_r_o.valid = ctrl_i.enable & (counter == 3'b111);
    out_i_o.valid = ctrl_i.enable & (counter == 3'b111);
    out_r_o.strb  = '1;
    out_i_o.strb  = '1;
end

//now we should also export our flags, we only have 1 flag here which is done.

assign flags_o.done = (counter == 3'b111)? 1:0;

//lastly we back-propagate our ready to the stream

assign in_r_i.ready  = (counter == 3'b0)? 1 : 0; 
assign in_i_i.ready  = (counter == 3'b0)? 1 : 0; 
assign a10_r_i.ready = (counter == 3'b0)? 1 : 0; 
assign a10_i_i.ready = (counter == 3'b0)? 1 : 0; 
assign a30_r_i.ready = (counter == 3'b0)? 1 : 0; 
assign a30_i_i.ready = (counter == 3'b0)? 1 : 0; 
assign a50_r_i.ready = (counter == 3'b0)? 1 : 0; 
assign a50_i_i.ready = (counter == 3'b0)? 1 : 0; 

//this implementation does not include pipelining, the circuit is only operating on a single set of inputs every time. check for functionality and then add pipelining after.

endmodule 
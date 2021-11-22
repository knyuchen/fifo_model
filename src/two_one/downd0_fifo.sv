// down: input bitwidth is larger then output bitwidth
module downd0_fifo 
#(
   parameter WIDTH = 16,    //from perspective of the smaller size
   parameter SIZE  = 32,    //from perspective of the smaller size
   parameter FULL  = 1,
   parameter EMPTY = 1,
   parameter AL_FULL = 2,
   parameter AL_EMPTY = 2,
   parameter ACK   = 1,
   parameter VALID = 1
)
(
   input                           clk,
   input                           rst_n,
   input         [1:0]             push,
   input                           pop,
   input         [2*WIDTH - 1 : 0] wdata,
   output  logic [WIDTH - 1 : 0]   rdata,
   output  logic [1:0]             full,
   output  logic                   empty,
   output  logic [1:0]             al_full,
   output  logic                   al_empty,
   output  logic                   ack,
   output  logic                   valid

);

   logic [WIDTH - 1 : 0]  wdata0, wdata1, rdata0, rdata1;
   logic push0, push1, pop0, pop1;
   logic full0, full1, empty0, empty1;
   logic al_full0, al_full1, al_empty0, al_empty1;
   logic ack0, ack1, valid0, valid1; 

   dofifo #
   ( .WIDTH(WIDTH),
     .SIZE(SIZE/2),
     .FULL(FULL),
     .EMPTY(EMPTY),
     .AL_FULL(AL_FULL/2),
     .AL_EMPTY(AL_EMPTY/2),
     .ACK(ACK),
     .VALID(VALID)
   ) d0 
   (
      .*,
      .push(push0),
      .pop(pop0),
      .wdata(wdata0),
      .rdata(rdata0),

   );
 


endmodule

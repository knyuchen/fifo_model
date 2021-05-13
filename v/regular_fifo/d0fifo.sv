module d0fifo 
#(
   parameter WIDTH = 16,
   parameter SIZE  = 32,
   parameter FULL  = 1,
   parameter EMPTY = 1,
   parameter AL_FULL = 2,
   parameter AL_EMPTY = 2,
   parameter ACK   = 1,
   parameter VALID = 1,
   parameter FLUSH = 1
)
(
   input                          clk,
   input                          rst_n,
   input                          push,
   input                          pop,
   input                          flush,
   input         [WIDTH - 1 : 0]  wdata,
   output  logic [WIDTH - 1 : 0]  rdata,
   output  logic                  full,
   output  logic                  empty,
   output  logic                  al_full,
   output  logic                  al_empty,
   output  logic                  ack,
   output  logic                  valid
)
   logic [$clog2(SIZE) : 0]             rd_ptr, rd_ptr_w;
   logic [$clog2(SIZE) : 0]             wr_ptr, wr_ptr_w;
   logic [$clog2(SIZE) : 0]             rd_ptr_cal, wr_ptr_cal;
   logic [$clog2(SIZE) : 0]             diff;

   always_comb begin
      if (rd_ptr_cal[$clog2(SIZE)] ^ wr_ptr_cal[$clog2(SIZE)] == 1) begin
         rd_ptr_cal = {1'b0, rd_ptr[$clog2(SIZE) - 1 : 0]};
         wr_ptr_cal = {1'b1, wr_ptr[$clog2(SIZE) - 1 : 0]};
      end
      else begin
         rd_ptr_cal = rd_ptr;
         wr_ptr_cal = wr_ptr;
      end
   end
  
   logic  real_flush;

   assign real_flush = (FLUSH == 1) ? flush : 0;
 
   assign diff        = wr_ptr_cal - rd_ptr_cal;
   assign empty       = (EMPTY == 1)    ? (diff == 0)           : 0;
   assign full        = (FULL  == 1)    ? (diff == SIZE)        : 0;
   assign al_empty    = (AL_EMPTY != 0) ? (diff == AL_EMPTY)    : 0;
   assign al_full     = (AL_FULL  != 0) ? (diff == AL_FULL)     : 0;

   logic  wen, ren, corner;
   logic [$clog2(SIZE) - 1 : 0]  waddr, raddr; 

   assign wen         = push == 1 && (full  != 1 || (full == 1 && pop == 1)) && real_flush == 0;
   assign ren         = pop  == 1 && empty != 1 && real_flush == 0;
   assign corner      = empty == 1 && push == 1 && pop == 1 && real_flush == 0;
   assign waddr       = (wen == 1) ? wr_ptr[$clog2(SIZE) - 1 : 0];
   assign raddr       = (ren == 1) ? rd_ptr[$clog2(SIZE) - 1 : 0];

   assign wr_ptr_w = (real_flush == 1) ? 0 : ((wen == 1) ? wr_ptr + 1 : wr_ptr);
   assign rd_ptr_w = (real_flush == 1) ? 0 : ((ren == 1) ? rd_ptr + 1 : rd_ptr);
   
   assign ack   = (ACK   == 1) ? wen : 0;
   assign valid = (VALID == 1) ? (ren == 1 || corner == 1) : 0;

   logic [WIDTH - 1 : 0] rdata_ram;

   assign rdata = (corner == 1) wdata : rdata_ram;


   d0ram #(.WIDTH(WIDTH), .SIZE(SIZE)) d1 (.*, .rdata (rdata_ram)); 

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         rd_ptr <= 0;
         wr_ptr <= 0;
      end
      else begin
         rd_ptr <= rd_ptr_w;
         wr_ptr <= wr_ptr_w;
      end
   end
endmodule

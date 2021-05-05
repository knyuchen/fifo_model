module d1spfifo 
#(
   parameter WIDTH = 16,
   parameter SIZE  = 32,
   parameter SRAM  = 1,
   parameter FULL  = 1,
   parameter EMPTY = 1,
   parameter AL_FULL = 2,
   parameter AL_EMPTY = 2,
   parameter ACK   = 1,
   parameter VALID = 1
)
(
   input                          clk,
   input                          rst_n,
   input                          push,
   input                          pop,
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
   
   assign diff        = wr_ptr_cal - rd_ptr_cal;
   assign empty       = (EMPTY == 1)    ? (diff == 0)           : 0;
   assign full        = (FULL  == 1)    ? (diff == SIZE)        : 0;
   assign al_empty    = (AL_EMPTY != 0) ? (diff == AL_EMPTY)    : 0;
   assign al_full     = (AL_FULL  != 0) ? (diff == AL_FULL)     : 0;

   logic  wen, ren;
   logic [$clog2(SIZE) - 1 : 0]  waddr, raddr; 

   assign wen         = push == 1 && full  != 1;
   assign ren         = pop  == 1 && empty != 1;
   assign waddr       = (wen == 1) ? wr_ptr[$clog2(SIZE) - 1 : 0];
   assign raddr       = (ren == 1) ? rd_ptr[$clog2(SIZE) - 1 : 0];

   assign wr_ptr_w = (wen == 1) ? wr_ptr + 1 : wr_ptr;
   assign rd_ptr_w = (ren == 1) ? rd_ptr + 1 : rd_ptr;
   
   assign ack   = (ACK   == 1) ? wen : 0;
  
   logic  wen0, wen1, ren0, ren1;
   logic  [$clog2(SIZE) - 2 : 0] waddr0, waddr1, raddr0, raddr1;
   logic  [WIDTH - 1 : 0] wdata0, wdata1, rdata0, rdata1;

   assign ren0 = (raddr[0] == 0) ? ren : 0;
   assign ren1 = (raddr[0] == 1) ? ren : 0;
   assign raddr0 = (ren0 == 1) ? raddr[$clog2(SIZE) - 1 : 1];
   assign raddr1 = (ren1 == 1) ? raddr[$clog2(SIZE) - 1 : 1];

   logic  [1:0] ren_d;
   assign valid = (VALID == 1) ? (ren_d != 0) : 0;

   assign rdata = (ren_d[1] == 1) ? rdata1 : ((ren_d[0] == 1) ? rdata0 : 0);
  
   logic [$clog2(SIZE) - 2 : 0] addr_buf, addr_buf_w;
   logic [WIDTH - 1 : 0] data_buf, data_buf_w;
   logic [1:0]  indi_buf, indi_buf_w;
   logic buf_0, buf_1, clean_0, clean_1;  


   always_comb begin
      wen0 = 0;
      waddr0 = 0;
      wdata0 = 0;
      buf_0 = 0;
      clean_0 = 0;
      if (wen == 1 && waddr[0] == 0) begin
         if (ren0 == 1) begin
            buf_0 = 1;
         end
         else begin
            wen0 = 1;
            waddr0 = waddr[$clog2(SIZE) - 1 : 1];
            wdata0 = wdata;
         end
      end
      else if (indi_buf[0] == 1) begin
         clean_0 = 1;
         wen0 = 1;
         wdata0 = data_buf;
         waddr0 = addr_buf;
      end
   end
   
   always_comb begin
      wen1 = 0;
      waddr1 = 0;
      wdata1 = 0;
      buf_1 = 0;
      clean_1 = 0;
      if (wen == 1 && waddr[0] == 1) begin
         if (ren1 == 1) begin
            buf_1 = 1;
         end
         else begin
            wen1 = 1;
            waddr1 = waddr[$clog2(SIZE) - 1 : 1];
            wdata1 = wdata;
         end
      end
      else if (indi_buf[1] == 1) begin
         clean_1 = 1;
         wen1 = 1;
         wdata1 = data_buf;
         waddr1 = addr_buf;
      end
   end
   
   always_comb begin
      data_buf_w = data_buf;
      addr_buf_w = addr_buf;
      indi_buf_w = indi_buf;
      if (buf_0 == 1 || buf_1 == 1) begin
         data_buf_w = wdata;
         addr_buf_w = waddr[$clog2(SIZE) - 1 : 1];
      end
      case ({buf_1, buf_0, clean_1, clean_0})
         0001: indi_buf_w = 2'b00;
         0010: indi_buf_w = 2'b00;
         0100: indi_buf_w = 2'b01;
         0110: indi_buf_w = 2'b01;
         1001: indi_buf_w = 2'b10;
         1000: indi_buf_w = 2'b10;
         default: begin
         end
      endcase 
   end


 
   d1spram 
   #(.WIDTH(WIDTH), .SIZE(SIZE/2), .SRAM(SRAM)) d0 
   (.*,
    .wen(wen0),
    .ren(ren0),
    .waddr(waddr0),
    .raddr(raddr0),
    .wdata(wdata0),
    .rdata(rdata0)
   ); 

   d1spram 
   #(.WIDTH(WIDTH), .SIZE(SIZE/2), .SRAM(SRAM)) d1 
   (.*,
    .wen(wen1),
    .ren(ren1),
    .waddr(waddr1),
    .raddr(raddr1),
    .wdata(wdata1),
    .rdata(rdata1)
   ); 



   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         rd_ptr <= 0;
         wr_ptr <= 0;
         addr_buf <= 0;
         data_buf <= 0;
         indi_buf <= 0;
         ren_d <= 0;
      end
      else begin
         rd_ptr <= rd_ptr_w;
         wr_ptr <= wr_ptr_w;
         addr_buf <= addr_buf_w;
         data_buf <= data_buf_w;
         indi_buf <= indi_buf_w;
         ren_d <= {ren1, ren0};
      end
   end
endmodule

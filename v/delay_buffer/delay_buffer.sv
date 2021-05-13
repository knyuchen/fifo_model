/*
   The data will come out one cycle later, so 2 stage pipeline is needed on the outside
*/
module delay_buffer #(parameter MAX_DELAY = 128, WIDTH = 32, SRAM = 1) (
   input                                clk,
   input                                rst_n,
   input          [DATA_WIDTH - 1 : 0]  data_in,
   input                                valid_in,
   output  logic                        valid_out,
   output  logic  [DATA_WIDTH - 1 : 0]  data_out,
   input                                flush,
   input          [$clog2(MAX_DELAY) - 1 : 0]  delay
);

   logic push, pop;
   logic [WIDTH - 1 : 0] wdata, rdata;
   logic [WIDTH - 1 : 0] data_out_pre;
   logic full, empty, al_full, al_empty, ack, valid;

   assign valid_out = valid_in;
   assign data_out = rdata;
   assign wdata =  data_in;

   d1spfifo #(
      .WIDTH (WIDTH),
      .SIZE (MAX_DELAY),
      .SRAM(SRAM),
      .FULL(0),
      .EMPTY(0),
      .AL_FULL(0),
      .AL_EMPTY(0),
      .ACK(0),
      .VALID(1) 
   ) df1 (.*);
 
   logic  flag, flag_w;
   logic  [$clog2(MAX_DELAY) - 1 : 0]  count, count_w;

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         flag <= 0;
         count <= 0;
      end
      else begin
         flag <= flag_w;
         count <= count_w;
      end
   end


   always_comb begin
      flag_w = flag;
      count_w = count;
      push = 0;
      pop = 0;
      if (flush == 1) begin
         flag_w = 0;
         count_w = 0;
      end
      else if (valid_in == 1) begin
         if (flag == 0) begin
            if (delay == 0) begin
               push = 1;
               pop  = 1;
            end
            else begin
               if (count != delay) begin
                  count_w = count + 1;
                  push = 1; 
               end
               else begin
                  count_w = 0;
                  push = 1;
                  pop = 1;
               end
            end
         end
         else begin
            push = 1;
            pop  = 1;
         end 
      end
   end
endmodule

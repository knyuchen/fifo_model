module fifo_8I8O
#(
   parameter WIDTH = 32,
   parameter SIZE  = 32,
   parameter FULL  = 1,
   parameter EMPTY = 1,
   parameter VALID = 1,
   parameter FLUSH = 1
)

(
   input                          clk,
   input                          rst_n,
   input         [3:0]            push,
   input         [3:0]            pop,
   input                          flush,
   input         [7:0][WIDTH - 1 : 0]  wdata,
   output  logic [7:0][WIDTH - 1 : 0]  rdata,
   output  logic                  full,
   output  logic                  empty,
   output  logic [3:0]            valid
);
   logic [$clog2(SIZE) : 0]             rd_ptr, rd_ptr_w;
   logic [$clog2(SIZE) : 0]             wr_ptr, wr_ptr_w;
   logic [$clog2(SIZE) : 0]             rd_ptr_cal, wr_ptr_cal;
   logic [$clog2(SIZE) : 0]             diff;
   
   always_comb begin
      if (rd_ptr[$clog2(SIZE)] ^ wr_ptr[$clog2(SIZE)] == 1) begin
         rd_ptr_cal = {1'b0, rd_ptr[$clog2(SIZE) - 1 : 0]};
         wr_ptr_cal = {1'b1, wr_ptr[$clog2(SIZE) - 1 : 0]};
      end
      else begin
       wr_ptr_cal = wr_ptr;
       rd_ptr_cal = rd_ptr;
      end
   end

  
   logic  real_flush, real_valid;

   assign real_flush = (FLUSH == 1) ? flush : 0;
 
   assign diff        = wr_ptr_cal - rd_ptr_cal;
   assign empty       = (EMPTY == 1)    ? (diff < 8)           : 0;
   assign full        = (FULL  == 1)    ? (diff > SIZE - 9)        : 0;

   logic [SIZE - 1 : 0][WIDTH - 1 : 0] store, store_w;
  
   logic [3:0]  wen, ren;

   assign wen = (full == 0) ? push : 0;
   assign ren = (empty == 0) ? pop : 0;
   assign valid = ren;

   logic [7:0] [$clog2(SIZE) - 1 : 0] r_index, w_index;
   
   assign r_index[0] = rd_ptr[$clog2(SIZE) - 1 : 0];
   assign w_index[0] = wr_ptr[$clog2(SIZE) - 1 : 0];

   assign r_index[1] = r_index[0] + 1;
   assign r_index[2] = r_index[0] + 2;
   assign r_index[3] = r_index[0] + 3;
   assign r_index[4] = r_index[0] + 4;
   assign r_index[5] = r_index[0] + 5;
   assign r_index[6] = r_index[0] + 6;
   assign r_index[7] = r_index[0] + 7;

   assign w_index[1] = w_index[0] + 1;
   assign w_index[2] = w_index[0] + 2;
   assign w_index[3] = w_index[0] + 3;
   assign w_index[4] = w_index[0] + 4;
   assign w_index[5] = w_index[0] + 5;
   assign w_index[6] = w_index[0] + 6;
   assign w_index[7] = w_index[0] + 7;

   assign rd_ptr_w = rd_ptr + ren;
   assign wr_ptr_w = wr_ptr + wen;

   always_comb begin
      store_w = store;
      case (wen)
      1: begin
         store_w [w_index[0]] = wdata[0];
      end 
      2: begin
         store_w [w_index[0]] = wdata[0];
         store_w [w_index[1]] = wdata[1];
      end 
      3: begin
         store_w [w_index[0]] = wdata[0];
         store_w [w_index[1]] = wdata[1];
         store_w [w_index[2]] = wdata[2];
      end 
      4: begin
         store_w [w_index[0]] = wdata[0];
         store_w [w_index[1]] = wdata[1];
         store_w [w_index[2]] = wdata[2];
         store_w [w_index[3]] = wdata[3];
      end 
      5: begin
         store_w [w_index[0]] = wdata[0];
         store_w [w_index[1]] = wdata[1];
         store_w [w_index[2]] = wdata[2];
         store_w [w_index[3]] = wdata[3];
         store_w [w_index[4]] = wdata[4];
      end 
      6: begin
         store_w [w_index[0]] = wdata[0];
         store_w [w_index[1]] = wdata[1];
         store_w [w_index[2]] = wdata[2];
         store_w [w_index[3]] = wdata[3];
         store_w [w_index[4]] = wdata[4];
         store_w [w_index[5]] = wdata[5];
      end 
      7: begin
         store_w [w_index[0]] = wdata[0];
         store_w [w_index[1]] = wdata[1];
         store_w [w_index[2]] = wdata[2];
         store_w [w_index[3]] = wdata[3];
         store_w [w_index[4]] = wdata[4];
         store_w [w_index[5]] = wdata[5];
         store_w [w_index[6]] = wdata[6];
      end 
      8: begin
         store_w [w_index[0]] = wdata[0];
         store_w [w_index[1]] = wdata[1];
         store_w [w_index[2]] = wdata[2];
         store_w [w_index[3]] = wdata[3];
         store_w [w_index[4]] = wdata[4];
         store_w [w_index[5]] = wdata[5];
         store_w [w_index[6]] = wdata[6];
         store_w [w_index[7]] = wdata[7];
      end 
      default: begin
      end
      endcase
   end

   always_comb begin
      rdata = 0;
      case (ren)
      1: begin
         rdata[0] = store [r_index[0]];
      end
      2: begin
         rdata[0] = store [r_index[0]];
         rdata[1] = store [r_index[1]];
      end
      3: begin
         rdata[0] = store [r_index[0]];
         rdata[1] = store [r_index[1]];
         rdata[2] = store [r_index[2]];
      end
      4: begin
         rdata[0] = store [r_index[0]];
         rdata[1] = store [r_index[1]];
         rdata[2] = store [r_index[2]];
         rdata[3] = store [r_index[3]];
      end
      5: begin
         rdata[0] = store [r_index[0]];
         rdata[1] = store [r_index[1]];
         rdata[2] = store [r_index[2]];
         rdata[3] = store [r_index[3]];
         rdata[4] = store [r_index[4]];
      end
      6: begin
         rdata[0] = store [r_index[0]];
         rdata[1] = store [r_index[1]];
         rdata[2] = store [r_index[2]];
         rdata[3] = store [r_index[3]];
         rdata[4] = store [r_index[4]];
         rdata[5] = store [r_index[5]];
      end
      7: begin
         rdata[0] = store [r_index[0]];
         rdata[1] = store [r_index[1]];
         rdata[2] = store [r_index[2]];
         rdata[3] = store [r_index[3]];
         rdata[4] = store [r_index[4]];
         rdata[5] = store [r_index[5]];
         rdata[6] = store [r_index[6]];
      end
      8: begin
         rdata[0] = store [r_index[0]];
         rdata[1] = store [r_index[1]];
         rdata[2] = store [r_index[2]];
         rdata[3] = store [r_index[3]];
         rdata[4] = store [r_index[4]];
         rdata[5] = store [r_index[5]];
         rdata[6] = store [r_index[6]];
         rdata[7] = store [r_index[7]];
      end
      endcase
   end

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         store <= 0;
         rd_ptr <= 0;
         wr_ptr <= 0;
      end
      else begin
         store <= store_w;
         rd_ptr <= rd_ptr_w;
         wr_ptr <= wr_ptr_w;
      end
   end

endmodule

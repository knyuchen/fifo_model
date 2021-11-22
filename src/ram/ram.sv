module fpga_ram
#(
   parameter DATA_WIDTH  = 16, 
   parameter MEM_SIZE    = 1024,
   parameter ADDR_WIDTH = (MEM_SIZE==1)? 1 : $clog2(MEM_SIZE)
)
(
   input                                        clk,
   input                                        enable_write,
   input                                        enable_read,
   input                                        ctrl_write,
   input                  [ADDR_WIDTH - 1 : 0]  addr,
   input        signed  [DATA_WIDTH - 1 : 0]  data_write,
   output logic signed  [DATA_WIDTH - 1 : 0]  data_read
);

   (* ram_style = "block" *) logic [DATA_WIDTH - 1 : 0] mem [MEM_SIZE - 1 : 0];

   always @(posedge clk) begin
      if (enable_write) begin
         if (ctrl_write) begin
               mem[addr] <= data_write;
         end
      end
   end

   always @(posedge clk) begin
      if (enable_read) begin
         data_read <=   mem[addr];
      end
   end

endmodule


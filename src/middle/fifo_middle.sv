module fifo_middle
#( parameter WIDTH = 32
)
(
   output logic [WIDTH - 1 : 0]  data_push,
   input                         full,
   output logic                  push,
   
   input        [WIDTH - 1 : 0]  data_pop,
   input                         valid,
   input                         empty,
   output logic                  pop
);

   assign data_push = data_pop;
   assign pop       = full == 0 && empty == 0;
   assign push      = full == 0 && valid == 1;

endmodule 

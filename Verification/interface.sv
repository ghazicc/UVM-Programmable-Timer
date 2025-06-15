interface timer_interface (input logic clk);
 
//inputs
logic   [3:0]  d;       // 4-bit data bus
logic   [1:0]  a;       // 2-bit address bus  
logic          g0;      // Gate for counter0
logic          g1;      // Gate for counter1
        
//outputs
logic          out0;    // Output for counter0
logic          out1;    // Output for counter1

  clocking drv @(posedge clk);
  default input #2ns output #2ns;
    output d;
    output a;
    output g0;
    output g1;         
  endclocking

  clocking mon @(posedge clk);
  default input #2ns output #2ns;
    input d;
    input a;
    input g0;
    input g1;
    input out0;
    input out1;
  endclocking

  modport driver(clocking drv, input clk);
  modport monitor(clocking mon, input clk);


endinterface : timer_interface

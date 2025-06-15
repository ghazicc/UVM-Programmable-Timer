class timer_sequence_item extends uvm_sequence_item;

//1.Constructor
  function new(string name = "timer_sequence_item");
    super.new(name);
  endfunction : new

//2.Initialization
// inputs
  rand logic    [3:0]   d;           // 4-bit data bus
  rand logic    [1:0]   a;           // 2-bit address bus
  rand logic            g0;          // Gate for counter0
  rand logic            g1;          // Gate for counter1

//outputs
logic           out0;     // Output for counter0
logic           out1;     // Output for counter1

//3. UVM Registration Macros
  `uvm_object_utils_begin(timer_sequence_item)
    `uvm_field_int(d, UVM_ALL_ON)
    `uvm_field_int(a, UVM_ALL_ON)
    `uvm_field_int(g0, UVM_ALL_ON)
    `uvm_field_int(g1, UVM_ALL_ON)
    `uvm_field_int(out0, UVM_ALL_ON)
    `uvm_field_int(out1, UVM_ALL_ON)
  `uvm_object_utils_end

  //4.Constraints
  constraint addr_c {
    a inside {2'b00, 2'b01, 2'b10};  // Valid addresses only
  }
  
  constraint data_c {
    d inside {[0:15]};  // 4-bit data range
  }


endclass : timer_sequence_item

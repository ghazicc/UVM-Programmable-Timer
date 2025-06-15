class timer_sequencer extends uvm_sequencer #(timer_sequence_item);

//1. UVM component
`uvm_component_utils(timer_sequencer)

//2. Constructor
  function new(string name = "timer_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction


//3. Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

endclass: timer_sequencer
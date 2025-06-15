// Timer Basic Sequence - Tests basic functionality
class timer_basic_sequence extends timer_base_sequence;
  
  `uvm_object_utils(timer_basic_sequence)
  
  function new(string name = "timer_basic_sequence");
    super.new(name);
  endfunction
  
  task body();
    timer_sequence_item req;
    
    `uvm_info(get_type_name(), "Starting Timer Basic Sequence", UVM_LOW)
    
    repeat(10) begin
      req = timer_sequence_item::type_id::create("req");
      
      start_item(req);
      if (!req.randomize()) begin
        `uvm_error(get_type_name(), "Randomization failed")
      end
      finish_item(req);
      
      #10ns; // Small delay between transactions
    end
    
    `uvm_info(get_type_name(), "Timer Basic Sequence Complete", UVM_LOW)
  endtask
  
endclass

// Timer Mode Sequence - Tests different operating modes
class timer_mode_sequence extends timer_base_sequence;
  
  `uvm_object_utils(timer_mode_sequence)
  
  function new(string name = "timer_mode_sequence");
    super.new(name);
  endfunction
  
  task body();
    timer_sequence_item req;
    
    `uvm_info(get_type_name(), "Starting Timer Mode Sequence", UVM_LOW)
    
    // Test each mode (0-4)
    for(int mode = 0; mode < 5; mode++) begin
      // Set control register for counter0
      req = timer_sequence_item::type_id::create("req");
      start_item(req);
      req.a = 2'b10;  // Control register address
      req.d = {1'b0, mode[2:0]};  // Counter0, mode
      req.g0 = 1'b1;
      req.g1 = 1'b1;
      finish_item(req);
      
      // Set count value for counter0 (even for mode 2, odd for mode 3,4)
      req = timer_sequence_item::type_id::create("req");
      start_item(req);
      req.a = 2'b00;  // Counter0 address
      if(mode == 2) 
        req.d = 4'd10;  // Even count for mode 2
      else if(mode == 3 || mode == 4)
        req.d = 4'd9;   // Odd count for mode 3,4
      else
        req.d = 4'd8;   // General count
      req.g0 = 1'b1;
      req.g1 = 1'b1;
      finish_item(req);
      
      // Let timer run for a few cycles
      repeat(20) begin
        req = timer_sequence_item::type_id::create("req");
        start_item(req);
        req.a = 2'b11;  // Don't care address
        req.d = 4'b0;
        req.g0 = 1'b1;
        req.g1 = 1'b1;
        finish_item(req);
      end
    end
    
    `uvm_info(get_type_name(), "Timer Mode Sequence Complete", UVM_LOW)
  endtask
  
endclass

// Timer Counter Sequence - Tests counter range limits
class timer_counter_sequence extends timer_base_sequence;
  
  `uvm_object_utils(timer_counter_sequence)
  
  function new(string name = "timer_counter_sequence");
    super.new(name);
  endfunction
  
  task body();
    timer_sequence_item req;
    
    `uvm_info(get_type_name(), "Starting Timer Counter Sequence", UVM_LOW)
    
    // Test Counter0 boundaries (2-150)
    int counter0_values[] = {2, 5, 50, 100, 150};
    
    foreach(counter0_values[i]) begin
      // Set control for counter0, mode 0
      req = timer_sequence_item::type_id::create("req");
      start_item(req);
      req.a = 2'b10;
      req.d = 4'b0000;  // Counter0, mode 0
      req.g0 = 1'b1;
      req.g1 = 1'b0;
      finish_item(req);
      
      // Set counter0 value (split into nibbles)
      req = timer_sequence_item::type_id::create("req");
      start_item(req);
      req.a = 2'b00;
      req.d = counter0_values[i][3:0];  // Lower nibble first
      req.g0 = 1'b1;
      req.g1 = 1'b0;
      finish_item(req);
      
      req = timer_sequence_item::type_id::create("req");
      start_item(req);
      req.a = 2'b00;
      req.d = counter0_values[i][7:4];  // Upper nibble
      req.g0 = 1'b1;
      req.g1 = 1'b0;
      finish_item(req);
      
      // Run timer
      repeat(10) begin
        req = timer_sequence_item::type_id::create("req");
        start_item(req);
        req.a = 2'b11;
        req.d = 4'b0;
        req.g0 = 1'b1;
        req.g1 = 1'b0;
        finish_item(req);
      end
    end
    
    `uvm_info(get_type_name(), "Timer Counter Sequence Complete", UVM_LOW)
  endtask
  
endclass

// Timer Gate Sequence - Tests gate control functionality
class timer_gate_sequence extends timer_base_sequence;
  
  `uvm_object_utils(timer_gate_sequence)
  
  function new(string name = "timer_gate_sequence");
    super.new(name);
  endfunction
  
  task body();
    timer_sequence_item req;
    
    `uvm_info(get_type_name(), "Starting Timer Gate Sequence", UVM_LOW)
    
    // Setup counter0
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = 2'b10;  // Control register
    req.d = 4'b0000;  // Counter0, mode 0
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
    
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = 2'b00;  // Counter0 value
    req.d = 4'd8;
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
    
    // Test gate control patterns
    bit gate_patterns[8] = {1,1,0,0,1,0,1,1};
    
    foreach(gate_patterns[i]) begin
      req = timer_sequence_item::type_id::create("req");
      start_item(req);
      req.a = 2'b11;  // Don't care
      req.d = 4'b0;
      req.g0 = gate_patterns[i];
      req.g1 = gate_patterns[i];
      finish_item(req);
    end
    
    `uvm_info(get_type_name(), "Timer Gate Sequence Complete", UVM_LOW)
  endtask
  
endclass

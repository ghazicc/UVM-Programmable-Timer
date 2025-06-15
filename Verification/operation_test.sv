class timer_test extends timer_base_test;
    // 1. Component
    `uvm_component_utils(timer_test)

    timer_basic_sequence basic_seq;
    timer_mode_sequence mode_seq;
    timer_counter_sequence counter_seq;
    timer_gate_sequence gate_seq;

    // 2. Constructor
    function new(string name = "timer_test", uvm_component parent);
        super.new(name, parent);
        basic_seq = timer_basic_sequence::type_id::create("basic_seq");
        mode_seq = timer_mode_sequence::type_id::create("mode_seq");
        counter_seq = timer_counter_sequence::type_id::create("counter_seq");
        gate_seq = timer_gate_sequence::type_id::create("gate_seq");
    endfunction

    // 3. Build Phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    // 4. Run Phase
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Starting Timer Verification Tests", UVM_LOW)
        
        // Run different test sequences
        basic_seq.start(env.agent.sequencer);
        mode_seq.start(env.agent.sequencer);
        counter_seq.start(env.agent.sequencer);
        gate_seq.start(env.agent.sequencer);
        
        `uvm_info(get_type_name(), "Timer Verification Tests Completed", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
endclass

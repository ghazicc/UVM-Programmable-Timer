class timer_reference_model;
    
    // Counter structure matching DUT
    typedef struct {
        bit [7:0] count;
        bit [7:0] max_count;
        bit [2:0] mode;
        bit valid;
    } counter_ref_t;
    
    // Internal state
    counter_ref_t counter0, counter1;
    bit [7:0] control_reg;
    bit out0_expected, out1_expected;
    bit counter_select;
    
    // Constructor
    function new();
        reset();
    endfunction
    
    // Reset function
    function void reset();
        counter0 = '{count: 0, max_count: 0, mode: 0, valid: 0};
        counter1 = '{count: 0, max_count: 0, mode: 0, valid: 0};
        control_reg = 0;
        out0_expected = 0;
        out1_expected = 0;
        counter_select = 0;
    endfunction
    
    // Write operation (mimics DUT register writes)
    function void write_register(bit [1:0] addr, bit [3:0] data);
        case(addr)
            2'b00: begin // Counter0 data
                if(counter0.valid) begin
                    counter0.count = {counter0.count[3:0], data};
                    counter0.max_count = counter0.count;
                    // Validate counter0 range (2-150)
                    if(counter0.count < 2 || counter0.count > 150) begin
                        counter0.count = 2;
                        counter0.max_count = 2;
                        counter0.valid = 0;
                    end
                    validate_mode_constraints(0);
                end
            end
            
            2'b01: begin // Counter1 data
                if(counter1.valid) begin
                    counter1.count = {counter1.count[3:0], data};
                    counter1.max_count = counter1.count;
                    // Validate counter1 range (50-200)
                    if(counter1.count < 50 || counter1.count > 200) begin
                        counter1.count = 50;
                        counter1.max_count = 50;
                        counter1.valid = 0;
                    end
                    validate_mode_constraints(1);
                end
            end
            
            2'b10: begin // Control register
                control_reg = data;
                counter_select = data[3];
                // Set mode and validate
                if(counter_select == 0) begin
                    counter0.mode = data[2:0];
                    counter0.valid = (data[2:0] <= 3'b100);
                end else begin
                    counter1.mode = data[2:0];
                    counter1.valid = (data[2:0] <= 3'b100);
                end
            end
        endcase
    endfunction
    
    // Validate mode constraints
    function void validate_mode_constraints(bit counter_num);
        counter_ref_t cnt = (counter_num == 0) ? counter0 : counter1;
        
        case(cnt.mode)
            3'b010: begin // Mode 2: count must be even
                if(cnt.count[0] != 0) cnt.valid = 0;
            end
            3'b011, 3'b100: begin // Mode 3,4: count must be odd
                if(cnt.count[0] != 1) cnt.valid = 0;
            end
        endcase
        
        if(counter_num == 0) counter0 = cnt;
        else counter1 = cnt;
    endfunction
    
    // Clock edge processing
    function void clock_edge(bit g0, bit g1);
        // Process counter0
        if(g0 && counter0.valid) begin
            process_counter(0);
        end
        
        // Process counter1  
        if(g1 && counter1.valid) begin
            process_counter(1);
        end
        
        // Update outputs based on counter_select
        out0_expected = (counter_select == 0) ? get_counter_output(0) : 0;
        out1_expected = (counter_select == 1) ? get_counter_output(1) : 0;
    endfunction
    
    // Process individual counter
    function void process_counter(bit counter_num);
        counter_ref_t cnt = (counter_num == 0) ? counter0 : counter1;
        
        if(cnt.count == 0) begin
            cnt.count = cnt.max_count - 1;
        end else begin
            cnt.count = cnt.count - 1;
        end
        
        if(counter_num == 0) counter0 = cnt;
        else counter1 = cnt;
    endfunction
    
    // Get expected output for counter
    function bit get_counter_output(bit counter_num);
        counter_ref_t cnt = (counter_num == 0) ? counter0 : counter1;
        bit result = 0;
        
        if(!cnt.valid) return 0;
        
        case(cnt.mode)
            3'b000: begin // Mode 0: 1/n duty cycle
                result = (cnt.count == (cnt.max_count - 1));
            end
            
            3'b001: begin // Mode 1: (n-1)/n duty cycle
                result = (cnt.count != (cnt.max_count - 1));
            end
            
            3'b010: begin // Mode 2: 1/2 duty cycle
                result = (cnt.count >= cnt.max_count/2);
            end
            
            3'b011: begin // Mode 3: (n+1)/2 low, (n-1)/2 high
                result = (cnt.count < (cnt.max_count - 1)/2);
            end
            
            3'b100: begin // Mode 4: (n-1)/2 low, (n+1)/2 high
                result = (cnt.count >= (cnt.max_count + 1)/2);
            end
            
            default: result = 0;
        endcase
        
        return result;
    endfunction
    
    // Get expected outputs
    function bit get_out0_expected();
        return out0_expected;
    endfunction
    
    function bit get_out1_expected();
        return out1_expected;
    endfunction
    
    // Debug function to print internal state
    function void print_state();
        $display("Reference Model State:");
        $display("  Counter0: count=%0d, max=%0d, mode=%0d, valid=%0b", 
                 counter0.count, counter0.max_count, counter0.mode, counter0.valid);
        $display("  Counter1: count=%0d, max=%0d, mode=%0d, valid=%0b", 
                 counter1.count, counter1.max_count, counter1.mode, counter1.valid);
        $display("  Control: 0x%02h, select=%0b", control_reg, counter_select);
        $display("  Expected outputs: out0=%0b, out1=%0b", out0_expected, out1_expected);
    endfunction

endclass
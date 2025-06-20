/*
    Timer Reference Model
    Matches DUT behavior exactly according to specifications
    
    Team:
    Abdulhameed Aboushi 1212478
    Ghazi Haj Qassem 1210778
*/

class timer_reference_model;
    
    // Internal registers (matching DUT)
    bit [7:0] counter0;        // Counter0 register (range: 2-150)
    bit [7:0] counter1;        // Counter1 register (range: 50-200)
    bit [7:0] control;         // Control register [x,x,x,x,c,m2,m1,m0]
    
    // Working registers for counters
    bit [7:0] counter0_count;  // Current count for counter0
    bit [7:0] counter1_count;  // Current count for counter1
    bit [7:0] counter0_max;    // Max count for counter0
    bit [7:0] counter1_max;    // Max count for counter1
    bit [2:0] counter0_mode;   // Mode for counter0
    bit [2:0] counter1_mode;   // Mode for counter1
    
    // 3-cycle update mechanism state
    bit [1:0] cycle_state;     // 00: idle, 01: cycle1, 10: cycle2, 11: cycle3
    bit [7:0] temp_control;    // Temporary control register
    bit [3:0] temp_msn;        // Temporary MSN storage
    bit       valid_sequence;  // Valid sequence flag
    bit       counter_select;  // Which counter to update
  
    bit start = 0;
    
    // Expected outputs
    bit out0_expected;
    bit out1_expected;
    
    // File logging
    integer log_file;
    string log_file_name = "timer_reference.log";
    
    // Constructor
    function new();
        reset();
        log_file = $fopen(log_file_name, "w");
        if (log_file == 0) begin
            $display("Error: Could not open log file %s", log_file_name);
        end
    endfunction
    
    // Reset function
    function void reset();
        counter0 = 8'd0;        // Default minimum for counter0
        counter1 = 8'd0;       // Default minimum for counter1
        control = 8'h00;
        counter0_count = 8'd0;
        counter1_count = 8'd0;
        counter0_max = 8'd0;
        counter1_max = 8'd0;
        counter0_mode = 3'b000;
        counter1_mode = 3'b000;
        cycle_state = 2'b00;
        valid_sequence = 1'b0;
        out0_expected = 1'b0;
        out1_expected = 1'b0;
        start = 0;
    endfunction
    
    // Process register write (mimics DUT's 3-cycle process)
    function void write_register(bit [1:0] addr, bit [3:0] data);
        case (cycle_state)
            2'b00: begin // Idle state
                if (addr == 2'b10) begin // Control register write
                    temp_control = {4'b0000, data}; // Store control data
                    cycle_state = 2'b01;
                    valid_sequence = 1'b0;
                end
            end
            
            2'b01: begin // Cycle 2: Check address validity and store MSN
                counter_select = temp_control[3];
                // Check if address matches: addr[1] must match temp_control[3], addr[0] must be 0
                if ((addr[1] == temp_control[3]) && (addr[0] == 1'b0)) begin
                    temp_msn = data; // Store most significant nibble
                    valid_sequence = 1'b1;
                    cycle_state = 2'b10;
                end else begin
                    cycle_state = 2'b00; // Invalid sequence, return to idle
                    valid_sequence = 1'b0;
                end
            end
            
            2'b10: begin // Cycle 3: Load LSN and validate
                if (valid_sequence) begin
                    bit [7:0] new_count;
                    bit       count_valid;
                    
                    new_count = {temp_msn, data}; // Combine MSN and LSN
                    count_valid = 1'b1;
                    
                    // Validate based on counter and mode constraints
                    if (counter_select == 1'b0) begin // Counter0
                        // Check range (2-150)
                        if (new_count < 8'd2 || new_count > 8'd150) begin
                            count_valid = 1'b0;
                        end
                        // Check mode constraints
                        case (temp_control[2:0])
                            3'b010: if (new_count[0] != 1'b0) count_valid = 1'b0; // Mode 2: even
                            3'b011, 3'b100: if (new_count[0] != 1'b1) count_valid = 1'b0; // Mode 3,4: odd
                        endcase
                        
                        if (count_valid && temp_control[2:0] <= 3'b100) begin
                            counter0 = new_count;
                            counter0_max = new_count;
                            counter0_count = new_count;
                            counter0_mode = temp_control[2:0];
                            control = temp_control;
                        end
                    end else begin // Counter1
                        // Check range (50-200)
                        if (new_count < 8'd50 || new_count > 8'd200) begin
                            count_valid = 1'b0;
                        end
                        // Check mode constraints
                        case (temp_control[2:0])
                            3'b010: if (new_count[0] != 1'b0) count_valid = 1'b0; // Mode 2: even
                            3'b011, 3'b100: if (new_count[0] != 1'b1) count_valid = 1'b0; // Mode 3,4: odd
                        endcase
                        
                        if (count_valid && temp_control[2:0] <= 3'b100) begin
                            counter1 = new_count;
                            counter1_max = new_count;
                            counter1_count = new_count;
                            counter1_mode = temp_control[2:0];
                            control = temp_control;
                        end
                    end
                end
                cycle_state = 2'b00; // Return to idle
                valid_sequence = 1'b0;
            end
            
            default: cycle_state = 2'b00;
        endcase
    endfunction
    
    // Clock edge processing
    function void clock_edge(bit g0, bit g1);
        // Counter0 operation
        if (g0 && cycle_state == 2'b00) begin // Only count when not in update cycle
            if (counter0_count == 8'd1) begin
                counter0_count = counter0_max;
            end else begin
                counter0_count = counter0_count - 1'b1;
            end
        end
        
        // Counter1 operation  
        if (g1 && cycle_state == 2'b00) begin // Only count when not in update cycle
            if (counter1_count == 8'd1) begin
                counter1_count = counter1_max;
            end else begin
                counter1_count = counter1_count - 1'b1;
            end
        end
        
        // Update expected outputs
        update_outputs(g0, g1);
    endfunction
    
    // Update output expectations
    function void update_outputs(bit g0, bit g1);
        // Output generation for counter0
        case (counter0_mode)
            3'b000: begin // Mode 0: 1/n duty cycle (n-1 low, 1 high)
                out0_expected = (counter0_count == counter0_max) && g0;
            end
            3'b001: begin // Mode 1: (n-1)/n duty cycle (1 low, n-1 high)
                out0_expected = (counter0_count != counter0_max) && g0;
            end
            3'b010: begin // Mode 2: 1/2 duty cycle (n/2 low, n/2 high)
                out0_expected = (counter0_count <= (counter0_max >> 1)) && g0;
            end
            3'b011: begin // Mode 3: (n+1)/2 low, (n-1)/2 high
                out0_expected = (counter0_count > ((counter0_max + 1) >> 1)) && g0;
            end
            3'b100: begin // Mode 4: (n-1)/2 low, (n+1)/2 high
                out0_expected = (counter0_count <= ((counter0_max - 1) >> 1)) && g0;
            end
            default: out0_expected = 1'b0;
        endcase
        
        // Output generation for counter1
        case (counter1_mode)
            3'b000: begin // Mode 0: 1/n duty cycle (n-1 low, 1 high)
                out1_expected = (counter1_count == counter1_max) && g1;
            end
            3'b001: begin // Mode 1: (n-1)/n duty cycle (1 low, n-1 high)
                out1_expected = (counter1_count != counter1_max) && g1;
            end
            3'b010: begin // Mode 2: 1/2 duty cycle (n/2 low, n/2 high)
                out1_expected = (counter1_count <= (counter1_max >> 1)) && g1;
            end
            3'b011: begin // Mode 3: (n+1)/2 low, (n-1)/2 high
                out1_expected = (counter1_count > ((counter1_max + 1) >> 1)) && g1;
            end
            3'b100: begin // Mode 4: (n-1)/2 low, (n+1)/2 high
                out1_expected = (counter1_count <= ((counter1_max - 1) >> 1)) && g1;
            end
            default: out1_expected = 1'b0;
        endcase
    endfunction
    
    // Get expected outputs
    function bit get_out0_expected();
        return out0_expected;
    endfunction
    
    function bit get_out1_expected();
        return out1_expected;
    endfunction
    
    // Get current state for debugging
    function string get_state_string();
        return $sformatf("Cycle: %0d, Counter0: %0d/%0d (mode %0d), Counter1: %0d/%0d (mode %0d), Control: 0x%02h", 
                        cycle_state, counter0_count, counter0_max, counter0_mode,
                        counter1_count, counter1_max, counter1_mode, control);
    endfunction
    
    // Debug function to print internal state
    function void print_state();
        if (log_file != 0) begin
            $fdisplay(log_file, "@%0t: out0 = %0b, out1 = %0b", $time, out0_expected, out1_expected);
            $fdisplay(log_file, "Reference Model State:");
            $fdisplay(log_file, "  Cycle State: %0d", cycle_state);
            $fdisplay(log_file, "  Counter0: count=%0d, max=%0d, mode=%0d", 
                     counter0_count, counter0_max, counter0_mode);
            $fdisplay(log_file, "  Counter1: count=%0d, max=%0d, mode=%0d", 
                     counter1_count, counter1_max, counter1_mode);
            $fdisplay(log_file, "  Control: 0x%02h", control);
            $fdisplay(log_file, "  Expected outputs: out0=%0b, out1=%0b", out0_expected, out1_expected);
            if (cycle_state != 2'b00) begin
                $fdisplay(log_file, "  Update in progress: temp_control=0x%02h, temp_msn=0x%01h, valid=%0b", 
                         temp_control, temp_msn, valid_sequence);
            end
            $fdisplay(log_file, "");
        end
        // Also print to console for immediate debugging
        $display("@%0t: out0 = %0b, out1 = %0b", $time, out0_expected, out1_expected);
        $display("Reference Model State:");
        $display("  Cycle State: %0d", cycle_state);
        $display("  Counter0: count=%0d, max=%0d, mode=%0d", 
                 counter0_count, counter0_max, counter0_mode);
        $display("  Counter1: count=%0d, max=%0d, mode=%0d", 
                 counter1_count, counter1_max, counter1_mode);
        $display("  Control: 0x%02h", control);
        $display("  Expected outputs: out0=%0b, out1=%0b", out0_expected, out1_expected);
        if (cycle_state != 2'b00) begin
            $display("  Update in progress: temp_control=0x%02h, temp_msn=0x%01h, valid=%0b", 
                     temp_control, temp_msn, valid_sequence);
        end
        $display("");
    endfunction
    
    // Cleanup function to close the log file
    function void finish();
        if (log_file != 0) begin
            $fclose(log_file);
            log_file = 0;
        end
    endfunction

endclass
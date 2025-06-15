/*
    Team:
    Abdulhameed Aboushi 1212478
    Ghazi Haj Qassem 1210778
    
    Timer Design - Programmable Clock Divider
    Based on specifications provided
*/

module timer(d, a, clk, g0, g1, out0, out1);

    // Port declarations
    input  [3:0] d;        // 4-bit data bus
    input  [1:0] a;        // 2-bit address bus
    input        clk;      // Main clock input
    input        g0;       // Gate for counter0
    input        g1;       // Gate for counter1
    output       out0;     // Output for counter0
    output       out1;     // Output for counter1

    // Internal registers
    reg [7:0] counter0;    // Counter0 register (range: 2-150)
    reg [7:0] counter1;    // Counter1 register (range: 50-200)
    reg [7:0] control;     // Control register [x,x,x,x,c,m2,m1,m0]
    
    // Working registers for counters
    reg [7:0] counter0_count; // Current count for counter0
    reg [7:0] counter1_count; // Current count for counter1
    
    // 3-cycle control update mechanism
    reg [1:0] cycle_state;    // 00: idle, 01: cycle1, 10: cycle2, 11: cycle3
    reg [7:0] temp_control;   // Temporary control register
    reg [3:0] temp_msn;       // Temporary MSN storage
    reg       valid_sequence; // Valid sequence flag
    reg       counter_select; // Which counter to update
    
    // Output generation registers
    reg [7:0] counter0_max;   // Max count for counter0
    reg [7:0] counter1_max;   // Max count for counter1
    reg [2:0] counter0_mode;  // Mode for counter0
    reg [2:0] counter1_mode;  // Mode for counter1
    reg       out0_reg;
    reg       out1_reg;
    
    // Control register bit assignments
    wire counter_sel = control[3];    // c: counter select
    wire [2:0] mode = control[2:0];   // m2,m1,m0: mode selection
    
    // Initialize
    initial begin
        counter0 = 8'd2;        // Default minimum for counter0
        counter1 = 8'd50;       // Default minimum for counter1
        control = 8'h00;
        counter0_count = 8'd2;
        counter1_count = 8'd50;
        cycle_state = 2'b00;
        valid_sequence = 1'b0;
        counter0_max = 8'd2;
        counter1_max = 8'd50;
        counter0_mode = 3'b000;
        counter1_mode = 3'b000;
        out0_reg = 1'b0;
        out1_reg = 1'b0;
    end
    
    // 3-cycle control update process
    always @(posedge clk) begin
        case (cycle_state)
            2'b00: begin // Idle state
                if (a == 2'b10) begin // Control register write
                    temp_control <= {4'b0000, d}; // Store control data
                    cycle_state <= 2'b01;
                    valid_sequence <= 1'b0;
                end
            end
            
            2'b01: begin // Cycle 2: Check address validity and store MSN
                counter_select <= temp_control[3];
                // Check if address matches: a[1] must match temp_control[3], a[0] must be 0
                if ((a[1] == temp_control[3]) && (a[0] == 1'b0)) begin
                    temp_msn <= d; // Store most significant nibble
                    valid_sequence <= 1'b1;
                    cycle_state <= 2'b10;
                end else begin
                    cycle_state <= 2'b00; // Invalid sequence, return to idle
                    valid_sequence <= 1'b0;
                end
            end
            
            2'b10: begin // Cycle 3: Load LSN and validate
                if (valid_sequence) begin
                    reg [7:0] new_count;
                    reg       count_valid;
                    
                    new_count = {temp_msn, d}; // Combine MSN and LSN
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
                            counter0 <= new_count;
                            counter0_max <= new_count;
                            counter0_count <= new_count;
                            counter0_mode <= temp_control[2:0];
                            control <= temp_control;
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
                            counter1 <= new_count;
                            counter1_max <= new_count;
                            counter1_count <= new_count;
                            counter1_mode <= temp_control[2:0];
                            control <= temp_control;
                        end
                    end
                end
                cycle_state <= 2'b00; // Return to idle
                valid_sequence <= 1'b0;
            end
            
            default: cycle_state <= 2'b00;
        endcase
    end
    
    // Counter0 operation
    always @(posedge clk) begin
        if (g0 && cycle_state == 2'b00) begin // Only count when not in update cycle
            if (counter0_count == 8'd1) begin
                counter0_count <= counter0_max;
            end else begin
                counter0_count <= counter0_count - 1'b1;
            end
        end
    end
    
    // Counter1 operation  
    always @(posedge clk) begin
        if (g1 && cycle_state == 2'b00) begin // Only count when not in update cycle
            if (counter1_count == 8'd1) begin
                counter1_count <= counter1_max;
            end else begin
                counter1_count <= counter1_count - 1'b1;
            end
        end
    end
    
    // Output generation for counter0
    always @(*) begin
        case (counter0_mode)
            3'b000: begin // Mode 0: 1/n duty cycle (n-1 low, 1 high)
                out0_reg = (counter0_count == counter0_max);
            end
            3'b001: begin // Mode 1: (n-1)/n duty cycle (1 low, n-1 high)
                out0_reg = (counter0_count != counter0_max);
            end
            3'b010: begin // Mode 2: 1/2 duty cycle (n/2 low, n/2 high)
                out0_reg = (counter0_count <= (counter0_max >> 1));
            end
            3'b011: begin // Mode 3: (n+1)/2 low, (n-1)/2 high
                out0_reg = (counter0_count > ((counter0_max + 1) >> 1));
            end
            3'b100: begin // Mode 4: (n-1)/2 low, (n+1)/2 high
                out0_reg = (counter0_count <= ((counter0_max - 1) >> 1));
            end
            default: out0_reg = 1'b0;
        endcase
    end
    
    // Output generation for counter1
    always @(*) begin
        case (counter1_mode)
            3'b000: begin // Mode 0: 1/n duty cycle (n-1 low, 1 high)
                out1_reg = (counter1_count == counter1_max);
            end
            3'b001: begin // Mode 1: (n-1)/n duty cycle (1 low, n-1 high)
                out1_reg = (counter1_count != counter1_max);
            end
            3'b010: begin // Mode 2: 1/2 duty cycle (n/2 low, n/2 high)
                out1_reg = (counter1_count <= (counter1_max >> 1));
            end
            3'b011: begin // Mode 3: (n+1)/2 low, (n-1)/2 high
                out1_reg = (counter1_count > ((counter1_max + 1) >> 1));
            end
            3'b100: begin // Mode 4: (n-1)/2 low, (n+1)/2 high
                out1_reg = (counter1_count <= ((counter1_max - 1) >> 1));
            end
            default: out1_reg = 1'b0;
        endcase
    end
    
    // Output assignments
    assign out0 = out0_reg && g0; // Output only when gate is enabled
    assign out1 = out1_reg && g1; // Output only when gate is enabled

endmodule
                    counter_select <= d[3]; // Store counter select
                    update_in_progress <= 1; // Start update process
                    // Check mode availability
                    if (d[2:0] <= 3'b100) begin // Valid modes: 0 to 4
                        if (counter_select == 0) counter0_next.valid <= 1;
                        else counter1_next.valid <= 1;
                    end else begin
                        if (counter_select == 0) counter0_next.valid <= 0;
                        else counter1_next.valid <= 0;
                    end
                end
            end
            2'b01: begin // Cycle 2: Store 4-bit data and check constraints
                if (a == 2'b00 || a == 2'b01) begin
                    temp_data <= d; // Store 4-bit data
                end
            end
            2'b10: begin // Cycle 3: Update next counter with constraints
                update_in_progress <= 0; // End update process
                if (a == 2'b00 && counter0_next.valid) begin // Counter0
                    counter0_next.count <= {counter0_next.count[3:0], temp_data};
                    counter0_next.mode <= temp_mode;
                    // Check counter0 range (2 to 150)
                    if (counter0_next.count < 2 || counter0_next.count > 150) begin
                        counter0_next.count <= 2;
                        counter0_next.valid <= 0;
                    end
                    // Check mode constraints
                    if (temp_mode == 3'b010 && counter0_next.count[0] != 0) begin // Mode 2: even
                        counter0_next.valid <= 0;
                    end
                    if ((temp_mode == 3'b011 || temp_mode == 3'b100) && counter0_next.count[0] != 1) begin // Mode 3, 4: odd
                        counter0_next.valid <= 0;
                    end
                end
                else if (a == 2'b01 && counter1_next.valid) begin // Counter1
                    counter1_next.count <= {counter1_next.count[3:0], temp_data};
                    counter1_next.mode <= temp_mode;
                    // Check counter1 range (50 to 200)
                    if (counter1_next.count < 50 || counter1_next.count > 200) begin
                        counter1_next.count <= 50;
                        counter1_next.valid <= 0;
                    end
                    // Check mode constraints
                    if (temp_mode == 3'b010 && counter1_next.count[0] != 0) begin // Mode 2: even
                        counter1_next.valid <= 0;
                    end
                    if ((temp_mode == 3'b011 || temp_mode == 3'b100) && counter1_next.count[0] != 1) begin // Mode 3, 4: odd
                        counter1_next.valid <= 0;
                    end
                end
            end
            default: update_in_progress <= 0;
        endcase
    end

    // Register write for control register
    always @(posedge clk) begin
        if (a == 2'b10 && cycle_count == 0) begin
            control_reg <= d;
        end
    end

    // Counter0 logic
    always @(posedge clk) begin
        if (g0 && counter0_next.valid) begin // Counter0 active when g0 = 1
            if (counter0_current.count == 0) begin
                counter0_current <= counter0_next; // Update current from next
                case (counter0_next.mode)
                    3'b000: begin // Mode 0: freq = 1/n, duty = 1/n
                        out0_reg <= 1'b1;
                        counter0_current.count <= counter0_next.max_count - 1;
                    end
                    3'b001: begin // Mode 1: freq = 1/n, duty = (n-1)/n
                        out0_reg <= (counter0_current.count == counter0_next.max_count - 1) ? 1'b0 : 1'b1;
                        counter0_current.count <= (counter0_current.count == 0) ? counter0_next.max_count - 1 : counter0_current.count - 1;
                    end
                    3'b010: begin // Mode 2: freq = 1/2, duty = 1/2 (n even)
                        out0_reg <= (counter0_current.count < counter0_next.max_count/2) ? 1'b0 : 1'b1;
                        counter0_current.count <= (counter0_current.count == 0) ? counter0_next.max_count - 1 : counter0_current.count - 1;
                    end
                    3'b011: begin // Mode 3: freq = 1/2, duty = (n+1)/2 low, (n-1)/2 high (n odd)
                        out0_reg <= (counter0_current.count < (counter0_next.max_count + 1)/2) ? 1'b0 : 1'b1;
                        counter0_current.count <= (counter0_current.count == 0) ? counter0_next.max_count - 1 : counter0_current.count - 1;
                    end
                    3'b100: begin // Mode 4: freq = 1/2, duty = (n-1)/2 low, (n+1)/2 high (n odd)
                        out0_reg <= (counter0_current.count < (counter0_next.max_count - 1)/2) ? 1'b0 : 1'b1;
                        counter0_current.count <= (counter0_current.count == 0) ? counter0_next.max_count - 1 : counter0_current.count - 1;
                    end
                    default: begin
                        out0_reg <= 1'b0;
                        counter0_current.count <= counter0_next.max_count - 1;
                    end
                endcase
            end else begin
                counter0_current.count <= counter0_current.count - 1;
                case (counter0_current.mode)
                    3'b000: out0_reg <= 1'b0;
GB1                    3'b001: out0_reg <= (counter0_current.count == counter0_next.max_count - 1) ? 1'b0 : 1'b1;
                    3'b010: out0_reg <= (counter0_current.count < counter0_next.max_count/2) ? 1'b0 : 1'b1;
                    3'b011: out0_reg <= (counter0_current.count < (counter0_next.max_count + 1)/2) ? 1'b0 : 1'b1;
                    3'b100: out0_reg <= (counter0_current.count < (counter0_next.max_count - 1)/2) ? 1'b0 : 1'b1;
                    default: out0_reg <= 1'b0;
                endcase
            end
        end
    end

    // Counter1 logic
    always @(posedge clk) begin
        if (g1 && counter1_next.valid) begin // Counter1 active when g1 = 1
            if (counter1_current.count == 0) begin
                counter1_current <= counter1_next; // Update current from next
                case (counter1_next.mode)
                    3'b000: begin // Mode 0
                        out1_reg <= 1'b1;
                        counter1_current.count <= counter1_next.max_count - 1;
                    end
                    3'b001: begin // Mode 1
                        out1_reg <= (counter1_current.count == counter1_next.max_count - 1) ? 1'b0 : 1'b1;
                        counter1_current.count <= (counter1_current.count == 0) ? counter1_next.max_count - 1 : counter1_current.count - 1;
                    end
                    3'b010: begin // Mode 2
                        out1_reg <= (counter1_current.count < counter1_next.max_count/2) ? 1'b0 : 1'b1;
                        counter1_current.count <= (counter1_current.count == 0) ? counter1_next.max_count - 1 : counter1_current.count - 1;
                    end
                    3'b011: begin // Mode 3
                        out1_reg <= (counter1_current.count < (counter1_next.max_count + 1)/2) ? 1'b0 : 1'b1;
                        counter1_current.count <= (counter1_current.count == 0) ? counter1_next.max_count - 1 : counter1_current.count - 1;
                    end
                    3'b100: begin // Mode 4
                        out1_reg <= (counter1_current.count < (counter1_next.max_count - 1)/2) ? 1'b0 : 1'b1;
                        counter1_current.count <= (counter1_current.count == 0) ? counter1_next.max_count - 1 : counter1_current.count - 1;
                    end
                    default: begin
                        out1_reg <= 1'b0;
                        counter1_current.count <= counter1_next.max_count - 1;
                    end
                endcase
            end else begin
                counter1_current.count <= counter1_current.count - 1;
                case (counter1_current.mode)
                    3'b000: out1_reg <= 1'b0;
                    3'b001: out1_reg <= (counter1_current.count == counter1_next.max_count - 1) ? 1'b0 : 1'b1;
                    3'b010: out1_reg <= (counter1_current.count < counter1_next.max_count/2) ? 1'b0 : 1'b1;
                    3'b011: out1_reg <= (counter1_current.count < (counter1_next.max_count + 1)/2) ? 1'b0 : 1'b1;
                    3'b100: out1_reg <= (counter1_current.count < (counter1_next.max_count - 1)/2) ? 1'b0 : 1'b1;
                    default: out1_reg <= 1'b0;
                endcase
            end
        end
    end

    // Output assignments
    assign out0 = (counter_select == 0) ? out0_reg : 1'b0;
    assign out1 = (counter_select == 1) ? out1_reg : 1'b0;

endmodule
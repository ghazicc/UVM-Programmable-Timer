/*
    Team:
    Abdulhameed Aboushi 1212478
    Ghazi Haj Qassem 1210778
*/


module timer (
    input  [3:0] d,        // 4-bit data bus
    input  [1:0] a,        // 2-bit address bus
    input  clk,            // Main clock input
    input  g0,             // Gate for counter0
    input  g1,             // Gate for counter1
    output out0,           // Output for counter0
    output out1            // Output for counter1
);

    // Define struct for counter
    typedef struct packed {
        reg [7:0] count;      // Current count value
        reg [7:0] max_count;  // Maximum count value
        reg [2:0] mode;       // Mode (m2, m1, m0)
        reg       valid;      // Validity flag for mode/count
    } counter_t;

    // Instances for current and next counter values
    counter_t counter0_current, counter1_current; // Current state
    counter_t counter0_next, counter1_next;      // Next state
    reg [7:0] control_reg;                       // Control register
    reg [2:0] temp_mode;                         // Temporary mode register
    reg [1:0] cycle_count;                       // 3-cycle counter
    reg [3:0] temp_data;                         // Temporary data storage
    reg       update_in_progress;                // Flag for update process
    reg       counter_select;                    // Counter select (from control_reg)
    reg       out0_reg, out1_reg;                // Output registers

    // Control register bits
    assign counter_select = control_reg[3];      // c: counter select (0 for counter0, 1 for counter1)

    // 3-cycle update process
    always @(posedge clk) begin
        if (update_in_progress) begin
            cycle_count <= cycle_count + 1;
        end else begin
            cycle_count <= 0;
        end

        case (cycle_count)
            2'b00: begin // Cycle 1: Check mode and store in temp
                if (a == 2'b10) begin // Control register write
                    temp_mode <= d[2:0]; // Store mode
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
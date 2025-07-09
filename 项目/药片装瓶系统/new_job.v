module new_job ( 
    input  wire        clk,
    input  wire        rst_n,
    input  wire        mode_control_one,
    input  wire        mode_control_two,
    input  wire [6:0]  set_pills_per_bottle,
    input  wire [4:0]  set_total_bottles,
    output reg  [7:0]  bottle_count_bcd, // {tens, ones}
    output reg  [7:0]  pill_count_bcd,   // {tens, ones}
    output reg  [1:0]  current,          // 00=SPACE, 01=SETTING, 10=CLEARING, 11=WORKING
    output reg  [1:0]  padding = 0,
    output reg         speaker           // �ߵ�ƽ����
);

// ״̬����
localparam SPACE    = 2'b00;
localparam SETTING  = 2'b01;
localparam CLEARING = 2'b10;
localparam WORKING  = 2'b11;

reg [1:0] current_state, next_state;
reg [3:0] pill_ones, pill_tens;
reg [3:0] bottle_ones, bottle_tens;

// ���������ƣ�100ms tick��
reg [3:0] clk_div;
reg       tick_enable;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_div     <= 0;
        tick_enable <= 0;
    end else if (clk_div == 4'd2) begin
        clk_div     <= 0;
        tick_enable <= 1;
    end else begin
        clk_div     <= clk_div + 1;
        tick_enable <= 0;
    end
end

// ת��Ϊ���������ڱȽ�
wire [6:0] current_pill_count   = (pill_tens << 3) + (pill_tens << 1) + pill_ones;
wire [5:0] current_bottle_count = (bottle_tens << 3) + (bottle_tens << 1) + bottle_ones;

// ״̬��
always @(posedge clk or negedge rst_n)
    if (!rst_n) current_state <= SPACE;
    else        current_state <= next_state;

always @(posedge clk or negedge rst_n)
    if (!rst_n) current <= SPACE;
    else        current <= current_state;

always @(*) begin
    case ({mode_control_two, mode_control_one})
        2'b01: next_state = SETTING;
        2'b10: next_state = CLEARING;
        2'b11: next_state = WORKING;
        default: next_state = SPACE;
    endcase
end

// ��־����
reg done_flag;
reg error_flag;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pill_ones    <= 0;
        pill_tens    <= 0;
        bottle_ones  <= 0;
        bottle_tens  <= 0;
        done_flag    <= 0;
        error_flag   <= 0;
        speaker      <= 0;
    end else if (tick_enable) begin
        speaker <= 0; // Ĭ������

        case (current_state)
            CLEARING: begin
                pill_ones    <= 0;
                pill_tens    <= 0;
                bottle_ones  <= 0;
                bottle_tens  <= 0;
                done_flag    <= 0;
                error_flag   <= 0;
            end

            WORKING: begin
                if (!error_flag && !done_flag && set_pills_per_bottle > 0 && current_bottle_count < set_total_bottles) begin
                    // ���ҩƬ���Ƿ����99
                    if (pill_tens > 9) begin
                        error_flag <= 1;
                    end else begin
                        // ҩƬδ����������
                        if (current_pill_count < set_pills_per_bottle - 1) begin
                            if (pill_ones == 9) begin
                                pill_ones <= 0;
                                pill_tens <= pill_tens + 1;
                            end else begin
                                pill_ones <= pill_ones + 1;
                            end
                        end else begin
                            // ҩƬ��������ҩƬ����
                            pill_ones <= 0;
                            pill_tens <= 0;

                            // ��������һ��
                            speaker <= 1;

                            // ����ƿ��
                            if (bottle_ones == 9) begin
                                bottle_ones <= 0;
                                bottle_tens <= bottle_tens + 1;
                            end else begin
                                bottle_ones <= bottle_ones + 1;
                            end

                            // ����Ƿ�����ƿװ��
                            if ((current_bottle_count + 1) >= set_total_bottles)
                                done_flag <= 1;
                        end
                    end
                end
            end
        endcase
    end
end

// ���������߼���FF=Ϩ��
always @(*) begin
    bottle_count_bcd = {bottle_tens, bottle_ones};

    if ((done_flag || error_flag) && clk)  // ��˸����ɻ򱨴�
        pill_count_bcd = 8'hFF;            // Ϩ��
    else
        pill_count_bcd = {pill_tens, pill_ones};
end

endmodule
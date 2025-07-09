module pillows (
    input wire clk,           
    input wire rst_n,//复位信号
    input wire set_mode,//设置 状态控制信号
    input wire clear_mode,//清零 状态控制信号
    input wire start_work,//开始工作 状态控制信号
    input wire [7:0] set_pills_per_bottle, 
    input wire [7:0] set_total_bottles,
    output reg [7:0] bottle_count,  
    output reg [7:0] pill_count,    
    output reg working_state,       
    output reg alarm_state          
);


localparam SPACE = 2'b00;//等待进入下一个状态的空置状态
localparam SETTING = 2'b01;
localparam CLEARING = 2'b10;
localparam WORKING = 2'b11;

reg [7:0] total_bottle;
reg [7:0] pills_per_bottle;
reg [1:0] current_state;
reg [1:0] next_state;

//由状态信号控制的后继状态改变
always @(*) begin
    case (current_state)
        SPACE: begin
            if (set_mode) next_state = SETTING;
            else if (clear_mode) next_state = CLEARING;
            else if (start_work) next_state = WORKING;
            else next_state = SPACE;
        end
        SETTING: begin
            if (!set_mode) next_state = SPACE;
            else next_state = SETTING;
        end
        CLEARING: begin
            if (!clear_mode) next_state = SPACE;
            else next_state = CLEARING;
        end
        WORKING: begin
            if (!start_work) next_state = SPACE;
            else if (pill_count >= set_pills_per_bottle) begin
                next_state = SPACE;//此时药片数量已经大于最大值
            end
            else next_state = WORKING;
        end
        default: next_state = SPACE;
    endcase
end

//由后继状态以及复位信号控制的状态改变
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= SPACE;
    end else begin
        current_state <= next_state;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bottle_count <= 8'b0000_0000;
        pill_count <= 8'b0000_0000;
        working_state <= 1'b0;
        alarm_state <= 1'b0;
    end else begin
        case (current_state)
            SPACE: begin
                working_state <= 1'b0;
                alarm_state <= 1'b0;
            end
            SETTING: begin
                pills_per_bottle <= set_pills_per_bottle; 
                total_bottle <= set_total_bottles;
            end
            CLEARING: begin
                bottle_count <= 8'b0000_0000;
                pill_count <= 8'b0000_0000;
            end
            WORKING: begin
                working_state <= 1'b1;
                if (pill_count < set_pills_per_bottle) begin
                    if (pill_count + 1 == set_pills_per_bottle) begin
								if(bottle_count < total_bottle)begin
									bottle_count <= bottle_count + 1;
									pill_count <= 8'b0000_0000;
								end 
								else begin
									alarm_state <= 1'b1;
								end
                    end 
						  else begin
						  bottle_count <= bottle_count + 1;
						  end
                end else begin
                    alarm_state <= 1'b1; 
                end
            end
        endcase
    end
end

endmodule
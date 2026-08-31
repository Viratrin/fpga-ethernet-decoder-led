// Protocol for the upduino's LED: a matching UDP packet's
// first payload byte selects a color - 1=green, 2=blue, 3=red, any
// other value turns it off. The LED remains on until the next matching command.
module led_command #(
    parameter logic [31:0] FILTER_DST_IP   = 32'hEF01_0203,
    parameter logic [15:0] FILTER_DST_PORT = 16'd5000
) (
    input logic clk,

    input logic [31:0] dst_ip,
    input logic [15:0] udp_dst_port,
    input logic        udp_header_valid,

    input logic [7:0] payload_data,
    input logic       payload_valid,
    input logic       payload_sof,

    output logic led_red   = 1'b0,
    output logic led_green = 1'b0,
    output logic led_blue  = 1'b0
);

    logic match_pending = 1'b0;

    always_ff @(posedge clk) begin
        if (udp_header_valid) begin
            match_pending <= (dst_ip == FILTER_DST_IP) && (udp_dst_port == FILTER_DST_PORT);
        end
    end

    always_ff @(posedge clk) begin
        if (payload_valid && payload_sof && match_pending) begin
            led_red   <= (payload_data == 8'd3);
            led_green <= (payload_data == 8'd1);
            led_blue  <= (payload_data == 8'd2);
        end
    end

endmodule

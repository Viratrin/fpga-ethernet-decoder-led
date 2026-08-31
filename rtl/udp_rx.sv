// Decodes the UDP header (src port, dst port, length) from ipv4_rx's
// payload stream, gated on protocol == 17 (UDP), and forwards everything
// after the 8-byte header as the UDP payload stream.
module udp_rx (
    input logic clk,

    input  logic [7:0] s_data,
    input  logic       s_valid,
    input  logic       s_sof,
    input  logic       s_eof,
    input  logic       s_error,

    input logic [7:0] protocol,
    input logic       ip_header_valid,

    output logic [15:0] udp_src_port = 16'd0,
    output logic [15:0] udp_dst_port = 16'd0,
    output logic [15:0] udp_length   = 16'd0,
    output logic        udp_header_valid,

    output logic [7:0] m_data,
    output logic       m_valid,
    output logic       m_sof,
    output logic       m_eof,
    output logic       m_error
);

    logic is_udp_protocol = 1'b0;

    always_ff @(posedge clk) begin
        if (ip_header_valid) begin
            is_udp_protocol <= (protocol == 8'h11);
        end
    end

    logic [3:0] byte_idx = 4'd0;
    logic [3:0] cur_idx;
    assign cur_idx = s_sof ? 4'd0 : byte_idx;

    logic payload_sof_pending = 1'b0;

    always_ff @(posedge clk) begin
        udp_header_valid <= 1'b0;
        m_valid          <= 1'b0;
        m_sof            <= 1'b0;
        m_eof            <= 1'b0;
        m_error          <= 1'b0;
        m_data           <= 8'd0;

        if (s_valid && is_udp_protocol) begin
            byte_idx <= (cur_idx == 4'd8) ? 4'd8 : (cur_idx + 4'd1);

            if (cur_idx < 4'd8) begin
                case (cur_idx)
                    4'd0: udp_src_port[15:8] <= s_data;
                    4'd1: udp_src_port[7:0]  <= s_data;
                    4'd2: udp_dst_port[15:8] <= s_data;
                    4'd3: udp_dst_port[7:0]  <= s_data;
                    4'd4: udp_length[15:8]   <= s_data;
                    4'd5: udp_length[7:0]    <= s_data;
                    4'd6: ;
                    4'd7: begin
                        udp_header_valid    <= 1'b1;
                        payload_sof_pending <= 1'b1;
                    end
                    default: ;
                endcase
            end else begin
                m_data              <= s_data;
                m_valid             <= 1'b1;
                m_sof               <= payload_sof_pending;
                m_eof               <= s_eof;
                m_error             <= s_error;
                payload_sof_pending <= 1'b0;
            end
        end
    end

endmodule

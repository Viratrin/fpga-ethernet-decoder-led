// Decodes the IPv4 header (src_ip, dst_ip, protocol, total_length) from
// eth_rx's payload stream, checks for EtherType == 0x0800 (ipv4) and IHL == 5, and
// forwards everything after the header as the IP payload stream.
module ipv4_rx (
    input logic clk,

    input  logic [7:0] s_data,
    input  logic       s_valid,
    input  logic       s_sof,
    input  logic       s_eof,
    input  logic       s_error,

    input logic [15:0] ethertype,
    input logic        header_valid,

    output logic [31:0] src_ip        = 32'd0,
    output logic [31:0] dst_ip        = 32'd0,
    output logic [7:0]  protocol      = 8'd0,
    output logic [15:0] total_length  = 16'd0,
    output logic        ip_header_valid,

    output logic [7:0] m_data,
    output logic       m_valid,
    output logic       m_sof,
    output logic       m_eof,
    output logic       m_error
);

    logic is_ipv4_ethertype = 1'b0;

    always_ff @(posedge clk) begin
        if (header_valid) begin
            is_ipv4_ethertype <= (ethertype == 16'h0800);
        end
    end

    logic [4:0] byte_idx = 5'd0;
    logic [4:0] cur_idx;
    assign cur_idx = s_sof ? 5'd0 : byte_idx;

    logic ip_supported = 1'b0;

    logic payload_sof_pending = 1'b0;

    always_ff @(posedge clk) begin
        ip_header_valid <= 1'b0;
        m_valid         <= 1'b0;
        m_sof           <= 1'b0;
        m_eof           <= 1'b0;
        m_error         <= 1'b0;
        m_data          <= 8'd0;

        if (s_valid) begin
            byte_idx <= (cur_idx == 5'd20) ? 5'd20 : (cur_idx + 5'd1);

            if (cur_idx == 5'd0) begin
                ip_supported <= is_ipv4_ethertype
                                && (s_data[7:4] == 4'd4)
                                && (s_data[3:0] == 4'd5);
            end else if (ip_supported) begin
                if (cur_idx < 5'd20) begin
                    case (cur_idx)
                        5'd2:  total_length[15:8] <= s_data;
                        5'd3:  total_length[7:0]  <= s_data;
                        5'd9:  protocol           <= s_data;
                        5'd12: src_ip[31:24]      <= s_data;
                        5'd13: src_ip[23:16]      <= s_data;
                        5'd14: src_ip[15:8]       <= s_data;
                        5'd15: src_ip[7:0]        <= s_data;
                        5'd16: dst_ip[31:24]      <= s_data;
                        5'd17: dst_ip[23:16]      <= s_data;
                        5'd18: dst_ip[15:8]       <= s_data;
                        5'd19: begin
                            dst_ip[7:0]         <= s_data;
                            ip_header_valid     <= 1'b1;
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
    end

endmodule

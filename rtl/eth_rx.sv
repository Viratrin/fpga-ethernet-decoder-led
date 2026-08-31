// Decodes the Ethernet header (dst_mac, src_mac, EtherType) from rmii_rx's
// byte stream and forwards everything after byte 13 as the payload stream.
module eth_rx (
    input logic clk,

    input  logic [7:0] s_data,
    input  logic       s_valid,
    input  logic       s_sof,
    input  logic       s_eof,
    input  logic       s_error,

    output logic [47:0] dst_mac   = 48'd0,
    output logic [47:0] src_mac   = 48'd0,
    output logic [15:0] ethertype = 16'd0,
    output logic        header_valid,

    output logic [7:0] m_data,
    output logic       m_valid,
    output logic       m_sof,
    output logic       m_eof,
    output logic       m_error
);

    logic [3:0] byte_idx = 4'd0;
    logic [3:0] cur_idx;
    assign cur_idx = s_sof ? 4'd0 : byte_idx;

    logic payload_sof_pending = 1'b0;

    always_ff @(posedge clk) begin
        header_valid <= 1'b0;
        m_valid      <= 1'b0;
        m_sof        <= 1'b0;
        m_eof        <= 1'b0;
        m_error      <= 1'b0;
        m_data       <= 8'd0;

        if (s_valid) begin
            byte_idx <= (cur_idx == 4'd14) ? 4'd14 : (cur_idx + 4'd1);

            if (cur_idx < 4'd14) begin
                case (cur_idx)
                    4'd0:  dst_mac[47:40]  <= s_data;
                    4'd1:  dst_mac[39:32]  <= s_data;
                    4'd2:  dst_mac[31:24]  <= s_data;
                    4'd3:  dst_mac[23:16]  <= s_data;
                    4'd4:  dst_mac[15:8]   <= s_data;
                    4'd5:  dst_mac[7:0]    <= s_data;
                    4'd6:  src_mac[47:40]  <= s_data;
                    4'd7:  src_mac[39:32]  <= s_data;
                    4'd8:  src_mac[31:24]  <= s_data;
                    4'd9:  src_mac[23:16]  <= s_data;
                    4'd10: src_mac[15:8]   <= s_data;
                    4'd11: src_mac[7:0]    <= s_data;
                    4'd12: ethertype[15:8] <= s_data;
                    4'd13: begin
                        ethertype[7:0]      <= s_data;
                        header_valid        <= 1'b1;
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

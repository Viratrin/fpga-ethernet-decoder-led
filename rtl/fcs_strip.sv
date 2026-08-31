// Strips the trailing 4-byte Ethernet FCS from rmii_rx's output stream so
// that eof lands on the true last content byte instead of the last FCS byte.
module fcs_strip (
    input logic clk,

    input  logic [7:0] s_data,
    input  logic       s_valid,
    input  logic       s_sof,
    input  logic       s_eof,
    input  logic       s_error,

    output logic [7:0] m_data,
    output logic       m_valid,
    output logic       m_sof,
    output logic       m_eof,
    output logic       m_error
);

    localparam int FCS_BYTES = 4;

    logic [7:0] buf_data  [FCS_BYTES];
    logic       buf_sof   [FCS_BYTES];
    logic       buf_error [FCS_BYTES];
    logic [2:0] fill_count = 3'd0;

    always_ff @(posedge clk) begin
        m_valid <= 1'b0;
        m_sof   <= 1'b0;
        m_eof   <= 1'b0;
        m_error <= 1'b0;
        m_data  <= 8'd0;

        if (s_valid) begin
            if (s_sof) begin
                fill_count   <= 3'd1;
                buf_data[0]  <= s_data;
                buf_sof[0]   <= 1'b1;
                buf_error[0] <= s_error;
            end else if (fill_count == FCS_BYTES) begin
                m_data  <= buf_data[0];
                m_valid <= 1'b1;
                m_sof   <= buf_sof[0];
                m_error <= buf_error[0];
                if (s_eof) begin
                    m_eof <= 1'b1;
                end

                for (int i = 0; i < FCS_BYTES - 1; i++) begin
                    buf_data[i]  <= buf_data[i + 1];
                    buf_sof[i]   <= buf_sof[i + 1];
                    buf_error[i] <= buf_error[i + 1];
                end
                buf_data[FCS_BYTES-1]  <= s_data;
                buf_sof[FCS_BYTES-1]   <= 1'b0;
                buf_error[FCS_BYTES-1] <= s_error;
            end else begin
                buf_data[fill_count]  <= s_data;
                buf_sof[fill_count]   <= 1'b0;
                buf_error[fill_count] <= s_error;
                fill_count            <= fill_count + 3'd1;
            end
        end
    end

endmodule

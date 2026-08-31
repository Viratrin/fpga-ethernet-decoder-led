// RMII receive frontend: assembles 2-bit RMII dibits into an 8-bit byte
// stream, locking onto the SFD and outputting content starting at destination 
// MAC byte 0.
module rmii_rx (
    input  logic       rmii_clk,
    input  logic [1:0] rmii_rxd,
    input  logic       rmii_crs_dv,
    input  logic       rmii_rx_er,

    output logic [7:0] data,
    output logic       valid,
    output logic       sof,
    output logic       eof,
    output logic       error
);

    localparam logic [7:0] SFD = 8'hD5;

    logic [7:0] shift_reg = 8'd0;
    logic [3:0] err_shift = 4'd0;

    logic [7:0] next_byte;
    logic [3:0] next_err;

    logic       sfd_found = 1'b0;
    logic [1:0] phase     = 2'd0;

    logic is_first_byte = 1'b1;

    logic       pend_valid = 1'b0;
    logic [7:0] pend_data  = 8'd0;
    logic       pend_sof   = 1'b0;
    logic       pend_error = 1'b0;

    assign next_byte = {rmii_rxd, shift_reg[7:2]};
    assign next_err  = {rmii_rx_er, err_shift[3:1]};

    always_ff @(posedge rmii_clk) begin
        valid <= 1'b0;
        sof   <= 1'b0;
        eof   <= 1'b0;
        error <= 1'b0;
        data  <= 8'd0;

        if (rmii_crs_dv) begin
            shift_reg <= next_byte;
            err_shift <= next_err;

            if (!sfd_found) begin
                if (next_byte == SFD && next_err == 4'b0) begin
                    sfd_found <= 1'b1;
                    phase     <= 2'd0;
                end
            end else begin
                if (phase == 2'd0 && pend_valid) begin
                    data       <= pend_data;
                    valid      <= 1'b1;
                    sof        <= pend_sof;
                    error      <= pend_error;
                    pend_valid <= 1'b0;
                end

                if (phase == 2'd3) begin
                    pend_valid    <= 1'b1;
                    pend_data     <= next_byte;
                    pend_sof      <= is_first_byte;
                    pend_error    <= |next_err;
                    is_first_byte <= 1'b0;
                end

                phase <= (phase == 2'd3) ? 2'd0 : phase + 2'd1;
            end
        end else begin
            sfd_found     <= 1'b0;
            phase         <= 2'd0;
            err_shift     <= 4'd0;
            is_first_byte <= 1'b1;

            if (pend_valid) begin
                data       <= pend_data;
                valid      <= 1'b1;
                sof        <= pend_sof;
                eof        <= 1'b1;
                error      <= pend_error;
                pend_valid <= 1'b0;
            end
        end
    end

endmodule

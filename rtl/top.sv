// Wires the RX decode chain together: rmii_rx -> fcs_strip -> eth_rx
// -> ipv4_rx -> udp_rx -> led_command.
module top #(
    parameter logic [31:0] FILTER_DST_IP   = 32'hEF01_0203,
    parameter logic [15:0] FILTER_DST_PORT = 16'd5000
) (
    input logic       rmii_clk,
    input logic [1:0] rmii_rxd,
    input logic       rmii_crs_dv,
    input logic       rmii_rx_er,

    output logic led_red,
    output logic led_green,
    output logic led_blue
);

    logic [7:0] rx_data;
    logic       rx_valid, rx_sof, rx_eof, rx_error;

    rmii_rx u_rmii_rx (
        .rmii_clk    (rmii_clk),
        .rmii_rxd    (rmii_rxd),
        .rmii_crs_dv (rmii_crs_dv),
        .rmii_rx_er  (rmii_rx_er),
        .data        (rx_data),
        .valid       (rx_valid),
        .sof         (rx_sof),
        .eof         (rx_eof),
        .error       (rx_error)
    );

    logic [7:0] content_data;
    logic       content_valid, content_sof, content_eof, content_error;

    fcs_strip u_fcs_strip (
        .clk     (rmii_clk),
        .s_data  (rx_data),
        .s_valid (rx_valid),
        .s_sof   (rx_sof),
        .s_eof   (rx_eof),
        .s_error (rx_error),
        .m_data  (content_data),
        .m_valid (content_valid),
        .m_sof   (content_sof),
        .m_eof   (content_eof),
        .m_error (content_error)
    );

    logic [47:0] dst_mac, src_mac;
    logic [15:0] ethertype;
    logic        header_valid;
    logic [7:0]  ip_in_data;
    logic        ip_in_valid, ip_in_sof, ip_in_eof, ip_in_error;

    eth_rx u_eth_rx (
        .clk          (rmii_clk),
        .s_data       (content_data),
        .s_valid      (content_valid),
        .s_sof        (content_sof),
        .s_eof        (content_eof),
        .s_error      (content_error),
        .dst_mac      (dst_mac),
        .src_mac      (src_mac),
        .ethertype    (ethertype),
        .header_valid (header_valid),
        .m_data       (ip_in_data),
        .m_valid      (ip_in_valid),
        .m_sof        (ip_in_sof),
        .m_eof        (ip_in_eof),
        .m_error      (ip_in_error)
    );

    logic [31:0] src_ip, dst_ip;
    logic [7:0]  protocol;
    logic        ip_header_valid;
    logic [15:0] total_length;
    logic [7:0]  udp_in_data;
    logic        udp_in_valid, udp_in_sof, udp_in_eof, udp_in_error;

    ipv4_rx u_ipv4_rx (
        .clk             (rmii_clk),
        .s_data          (ip_in_data),
        .s_valid         (ip_in_valid),
        .s_sof           (ip_in_sof),
        .s_eof           (ip_in_eof),
        .s_error         (ip_in_error),
        .ethertype       (ethertype),
        .header_valid    (header_valid),
        .src_ip          (src_ip),
        .dst_ip          (dst_ip),
        .protocol        (protocol),
        .total_length    (total_length),
        .ip_header_valid (ip_header_valid),
        .m_data          (udp_in_data),
        .m_valid         (udp_in_valid),
        .m_sof           (udp_in_sof),
        .m_eof           (udp_in_eof),
        .m_error         (udp_in_error)
    );

    logic [15:0] udp_src_port, udp_dst_port, udp_length;
    logic        udp_header_valid;
    logic [7:0]  payload_data;
    logic        payload_valid, payload_sof, payload_eof, payload_error;

    udp_rx u_udp_rx (
        .clk              (rmii_clk),
        .s_data           (udp_in_data),
        .s_valid          (udp_in_valid),
        .s_sof            (udp_in_sof),
        .s_eof            (udp_in_eof),
        .s_error          (udp_in_error),
        .protocol         (protocol),
        .ip_header_valid  (ip_header_valid),
        .udp_src_port     (udp_src_port),
        .udp_dst_port     (udp_dst_port),
        .udp_length       (udp_length),
        .udp_header_valid (udp_header_valid),
        .m_data           (payload_data),
        .m_valid          (payload_valid),
        .m_sof            (payload_sof),
        .m_eof            (payload_eof),
        .m_error          (payload_error)
    );

    led_command #(
        .FILTER_DST_IP   (FILTER_DST_IP),
        .FILTER_DST_PORT (FILTER_DST_PORT)
    ) u_led_command (
        .clk              (rmii_clk),
        .dst_ip           (dst_ip),
        .udp_dst_port     (udp_dst_port),
        .udp_header_valid (udp_header_valid),
        .payload_data     (payload_data),
        .payload_valid    (payload_valid),
        .payload_sof      (payload_sof),
        .led_red          (led_red),
        .led_green        (led_green),
        .led_blue         (led_blue)
    );

endmodule

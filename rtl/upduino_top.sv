// Top-level for the UPduino wired to a LAN8720 ETH board - maps top.sv
// onto physical pins and drives the onboard LED from led_command.sv's
// color selection.
module upduino_top (
    input logic gpio_35,
    input logic gpio_31,
    input logic gpio_34,
    input logic gpio_37,

    output logic led_red,
    output logic led_green,
    output logic led_blue
);

    logic cmd_led_red, cmd_led_green, cmd_led_blue;

    top u_top (
        .rmii_clk    (gpio_35),
        .rmii_rxd    ({gpio_34, gpio_31}),
        .rmii_crs_dv (gpio_37),
        .rmii_rx_er  (1'b0),
        .led_red     (cmd_led_red),
        .led_green   (cmd_led_green),
        .led_blue    (cmd_led_blue)
    );

    SB_RGBA_DRV u_rgb (
        .RGBLEDEN (1'b1),
        .RGB0PWM  (cmd_led_green),
        .RGB1PWM  (cmd_led_blue),
        .RGB2PWM  (cmd_led_red),
        .CURREN   (1'b1),
        .RGB0     (led_green),
        .RGB1     (led_blue),
        .RGB2     (led_red)
    );
    defparam u_rgb.RGB0_CURRENT = "0b000001";
    defparam u_rgb.RGB1_CURRENT = "0b000001";
    defparam u_rgb.RGB2_CURRENT = "0b000001";

endmodule

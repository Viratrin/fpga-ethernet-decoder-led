# fpga-ethernet-decoder

A SystemVerilog Ethernet receive decoder for the UPduino 3.1
(iCE40 UP5K) that decodes Ethernet/IPv4/UDP frames over RMII and uses
one UDP packet's payload byte to remotely set the onboard RGB LED's color.

Pipeline: `rmii_rx -> fcs_strip -> eth_rx -> ipv4_rx -> udp_rx -> led_command`.
Every stage passes bytes to the next over the same streaming signals:
`data`/`valid`/`sof`/`eof`/`error`, one byte per cycle.

## Hardware

- UPduino 3.1 (iCE40 UP5K)
- A LAN8720 RMII board,
  wired to the UPduino as:

| PHY board pin | UPduino pin |
|---|---|
| nINT/RETCK (REF_CLK out) | gpio_35 |
| RXD0 | gpio_31 |
| RXD1 | gpio_34 |
| CRS_DV | gpio_37 |
| 3V3 | 3V3 |
| GND | GND |

`TX1`/`TX0`/`TX-EN`/`MDIO`/`MDC`/`NC` are unused because this is receive-only (for now).

## Build and flash

Requires the [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build)
(Yosys, nextpnr-ice40, IceStorm tools) on `PATH`, and GNU Make.

```
make            # synthesize -> place & route -> pack the bitstream
make flash      # program the UPduino over USB
```

## Running the demo

```
pip install scapy
python scripts/send_led_command.py green --send-iface Ethernet
```

`color` is one of `off`/`green`/`blue`/`red`. `--send-iface` is your network
interface name. The packet is sent to a fixed multicast address/port 
(`239.1.2.3:5000`) with a broadcast destination MAC, so it reaches 
the board through a switch/router.

## Latency

All stages run off the 50 MHz RMII reference clock (20 ns/cycle). Per-stage
delay from a byte arriving on the wire to it reaching the next stage:

| Stage | Latency | Explanation |
|---|---|---|
| `rmii_rx` | 1 cycle (20 ns) | releases each byte as soon as one more dibit proves it wasn't the frame's last byte |
| `fcs_strip` | 16 cycles (320 ns) | 4-byte lookahead because we can't know a byte isn't part of the trailing FCS until 4 more bytes arrive |
| `eth_rx` | 1 cycle (20 ns) | single register stage |
| `ipv4_rx` | 1 cycle (20 ns) | single register stage |
| `udp_rx` | 1 cycle (20 ns) | single register stage |
| `led_command` | 1 cycle (20 ns) | registers the color decision on the payload's first byte |
| **Total** | **21 cycles = 420 ns** | from the command byte hitting the wire to the LED color register updating |

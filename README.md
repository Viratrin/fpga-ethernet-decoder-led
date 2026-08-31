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

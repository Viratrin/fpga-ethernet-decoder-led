# fpga-ethernet-decoder

A from-scratch SystemVerilog Ethernet receive datapath for the UPduino 3.1
(iCE40 UP5K) that decodes real Ethernet/IPv4/UDP frames over RMII and uses
one UDP packet's payload byte to remotely set the onboard RGB LED's color.

Pipeline: `rmii_rx -> fcs_strip -> eth_rx -> ipv4_rx -> udp_rx -> led_command`.
Every stage passes bytes to the next over the same flat streaming signals
(`data`/`valid`/`sof`/`eof`/`error`, one byte per cycle, no backpressure).

## Hardware

- UPduino 3.1 (iCE40 UP5K)
- A LAN8720 RMII breakout board (e.g. the Waveshare LAN8720 ETH board),
  wired to the UPduino as:

| PHY board pin | UPduino pin |
|---|---|
| nINT/RETCK (REF_CLK out) | gpio_35 |
| RXD0 | gpio_31 |
| RXD1 | gpio_34 |
| CRS_DV | gpio_37 |
| 3V3 | 3V3 |
| GND | GND |

`TX1`/`TX0`/`TX-EN`/`MDIO`/`MDC`/`NC` are unused (this design is receive-only).

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
interface name (find it with `Get-NetAdapter` on Windows). The packet is
sent to a fixed multicast address/port (`239.1.2.3:5000`) with a broadcast
destination MAC, so it reaches the board whether it's plugged directly into
your PC or through a switch/router.

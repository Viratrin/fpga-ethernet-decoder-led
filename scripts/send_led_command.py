#!/usr/bin/env python3
"""Send led_command.sv's 1-byte UDP color command to the UPduino."""
import argparse
import sys

from scapy.layers.inet import IP, UDP
from scapy.layers.l2 import Ether
from scapy.packet import Raw
from scapy.sendrecv import sendp

LED_COLOR_BYTES = {"off": 0, "green": 1, "blue": 2, "red": 3}
BROADCAST_MAC = "ff:ff:ff:ff:ff:ff"
LED_COMMAND_DST_IP = "239.1.2.3"
LED_COMMAND_DPORT = 5000


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("color", choices=sorted(LED_COLOR_BYTES))
    parser.add_argument("--send-iface", required=True, help="network interface to send on, e.g. 'Ethernet'")
    parser.add_argument("--src-mac", default="aa:bb:cc:dd:ee:ff")
    parser.add_argument("--src-ip", default="192.168.1.1")
    parser.add_argument("--count", type=int, default=1)
    args = parser.parse_args()

    packet = (
        Ether(dst=BROADCAST_MAC, src=args.src_mac)
        / IP(src=args.src_ip, dst=LED_COMMAND_DST_IP)
        / UDP(sport=1234, dport=LED_COMMAND_DPORT)
        / Raw(load=bytes([LED_COLOR_BYTES[args.color]]))
    )
    sendp(packet, iface=args.send_iface, count=args.count, verbose=False)
    print(f"Sent '{args.color}' x{args.count} to {LED_COMMAND_DST_IP}:{LED_COMMAND_DPORT} on '{args.send_iface}'", file=sys.stderr)


if __name__ == "__main__":
    main()

TOP   := upduino_top
RTL   := rtl/rmii_rx.sv rtl/fcs_strip.sv rtl/eth_rx.sv rtl/ipv4_rx.sv rtl/udp_rx.sv rtl/led_command.sv rtl/top.sv rtl/upduino_top.sv
PCF   := constraints/upduino.pcf
BUILD := build

bitstream: $(BUILD)/$(TOP).bin

$(BUILD)/$(TOP).json: $(RTL)
	mkdir -p $(BUILD)
	yosys -p "synth_ice40 -top $(TOP) -json $(BUILD)/$(TOP).json" $(RTL)

$(BUILD)/$(TOP).asc: $(BUILD)/$(TOP).json $(PCF)
	nextpnr-ice40 --up5k --package sg48 --pcf $(PCF) --json $(BUILD)/$(TOP).json --asc $(BUILD)/$(TOP).asc --freq 50

$(BUILD)/$(TOP).bin: $(BUILD)/$(TOP).asc
	icepack $(BUILD)/$(TOP).asc $(BUILD)/$(TOP).bin

flash: $(BUILD)/$(TOP).bin
	iceprog $(BUILD)/$(TOP).bin

clean:
	rm -rf $(BUILD)

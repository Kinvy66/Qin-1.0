BUILD:=./build

SRC:=./

ASM_INCLUDE:=./boot/include/


all: $(BUILD)/master.img

$(BUILD)/boot/%.bin: $(SRC)/boot/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -I $(ASM_INCLUDE) -f bin $< -o $@

$(BUILD)/master.img: $(BUILD)/boot/boot.bin \
	$(BUILD)/boot/loader.bin \

	yes | bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat $@
	dd if=$(BUILD)/boot/boot.bin of=$@ bs=512 count=1 conv=notrunc
	dd if=$(BUILD)/boot/loader.bin of=$@ bs=512 count=4 seek=2 conv=notrunc


.PHONY: bochs
bochs: $(BUILD)/master.img
	bochs -q -f ./bochs/bochsrc

.PHONY: clean
clean:
	rm -rf $(BUILD)/*
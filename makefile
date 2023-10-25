BUILD:= build

SRC:= ./

ASM_INCLUDE:=./boot/include/

OBJECTS:= $(BUILD)/kernel/main.o


ENTRYPOINT := 0xc0001500

GCCPREFIX := i686-elf-

CC	:= $(GCCPREFIX)gcc 
AS	:= $(GCCPREFIX)as
AR	:= $(GCCPREFIX)ar
LD	:= $(GCCPREFIX)ld


CFLAGS = -Wall $(LIB) -c -fno-builtin -W -Wstrict-prototypes \
         -Wmissing-prototypes 

all: $(BUILD)/master.img

$(BUILD)/boot/%.bin: $(SRC)/boot/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -I $(ASM_INCLUDE) -f bin $< -o $@

$(BUILD)/kernel/%.o: $(SRC)/kernel/%.c
	$(shell mkdir -p $(dir $@))
	$(CC) $(CFLAGS) $< -o $@

$(BUILD)/kernel.bin : $(OBJECTS)
	$(shell mkdir -p $(dir $@))
	$(LD) $< -Ttext $(ENTRYPOINT) -e main -o $@ -m elf_i386

$(BUILD)/master.img: $(BUILD)/boot/boot.bin \
	$(BUILD)/boot/loader.bin \
	$(BUILD)/kernel.bin \

	yes | bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat $@
	dd if=$(BUILD)/boot/boot.bin of=$@ bs=512 count=1 conv=notrunc
	dd if=$(BUILD)/boot/loader.bin of=$@ bs=512 count=4 seek=2 conv=notrunc
	dd if=$(BUILD)/kernel.bin of=$@ bs=512 count=200 seek=9 conv=notrunc


test : $(OBJECTS)

.PHONY: bochs
bochs: $(BUILD)/master.img
	bochs -q -f ./bochs/bochsrc

.PHONY: clean
clean:
	rm -rf $(BUILD)/*
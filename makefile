BUILD:= build
SRC:= ./

V := 0

ifeq ($(V),1)
override V =
endif
ifeq ($(V),0)
override V = @
endif

INCLUDES := -I ./includes 


OBJECTS:= $(BUILD)/kernel/main.o \
		  $(BUILD)/kernel/init.o \
		  $(BUILD)/kernel/interrupt.o \
		  $(BUILD)/kernel/kernel.o \
		  $(BUILD)/kernel/debug.o \
		  $(BUILD)/kernel/mem.o \
		  $(BUILD)/kernel/switch.o \
		  $(BUILD)/kernel/thread.o \
		  $(BUILD)/device/timer.o \
		  $(BUILD)/lib/print.o \
		  $(BUILD)/lib/string.o \
		  $(BUILD)/lib/bitmap.o \
		  $(BUILD)/lib/list.o \


ENTRYPOINT := 0xc0001500

BUILD_MODE := debug

GCCPREFIX := i686-elf-

CC	:= $(GCCPREFIX)gcc 
AS	:= $(GCCPREFIX)as
AR	:= $(GCCPREFIX)ar
LD	:= $(GCCPREFIX)ld

CFLAGS := -c -fno-builtin
LDFLAGS = -Ttext $(ENTRYPOINT) -e main -Map $(BUILD)/kernel.map

all: $(BUILD)/master.img

# Bootloader
$(BUILD)/boot/%.bin: $(SRC)/boot/%.asm
	$(V)echo + nasm $<
	$(shell mkdir -p $(dir $@))
	$(V)nasm  $(INCLUDES) -f bin $< -o $@

# kernel header
$(BUILD)/kernel/%.o: $(SRC)/kernel/%.S
	$(V)echo + nasm $<
	$(shell mkdir -p $(dir $@))
	$(V)nasm -f elf $< -o $@

# kernel c files
$(BUILD)/kernel/%.o: $(SRC)/kernel/%.c
	$(V)echo + cc $<
	$(shell mkdir -p $(dir $@))
	$(V)$(CC) $(CFLAGS) $(INCLUDES) $< -o $@

# devices
$(BUILD)/device/%.o: $(SRC)/device/%.c
	$(V)echo + cc $<
	$(shell mkdir -p $(dir $@))
	$(V)$(CC) $(CFLAGS) $(INCLUDES) $< -o $@

# libs
$(BUILD)/lib/%.o: $(SRC)/lib/%.S
	$(V)echo + as lib
	$(shell mkdir -p $(dir $@))
	$(V)nasm -f elf $< -o $@

# libs C files
$(BUILD)/lib/%.o: $(SRC)/lib/%.c
	$(V)echo + as lib
	$(shell mkdir -p $(dir $@))
	$(V)$(CC) $(CFLAGS) $(INCLUDES) $< -o $@

# ld kernel
$(BUILD)/kernel.bin : $(OBJECTS)
	$(V)echo + ld $@
	$(shell mkdir -p $(dir $@))
	$(V)$(LD) $(LDFLAGS) $^ -o $@ 

$(BUILD)/master.img: $(BUILD)/boot/boot.bin \
	$(BUILD)/boot/loader.bin \
	$(BUILD)/kernel.bin \

	$(V)echo + mk $@
	$(V)if [ ! -f $@ ]; then \
		bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat $@; \
	fi
	$(V)dd if=$(BUILD)/boot/boot.bin of=$@ bs=512 count=1 conv=notrunc 2>/dev/null
	$(V)dd if=$(BUILD)/boot/loader.bin of=$@ bs=512 count=4 seek=2 conv=notrunc 2>/dev/null
	$(V)dd if=$(BUILD)/kernel.bin of=$@ bs=512 count=200 seek=9 conv=notrunc 2>/dev/null

.PHONY: bochs
bochs: $(BUILD)/master.img
	bochs -q -f ./bochs/bochsrc

.PHONY: clean
clean:
	rm -rf $(BUILD)/*
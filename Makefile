# コンパイラ
CC=i686-elf-gcc
LD=i686-elf-ld
OBJCOPY=i686-elf-objcopy
CFLAGS=-m32 -ffreestanding -O0 -Wall -Wextra
LDFLAGS=-T linker.ld

# ファイル
SRC_C=$(wildcard src/*.c)
SRC_S=$(wildcard boot/*.S)
OBJ_C=$(SRC_C:.c=.o)
OBJ_S=$(SRC_S:.S=.o)

# ターゲット
KERNEL=kernel.elf
ISO_DIR=isodir
ISO=$(ISO_DIR)/myos.iso

.PHONY: all clean iso

all: $(KERNEL) iso

# カーネルビルド
$(KERNEL): $(OBJ_C) $(OBJ_S)
	$(LD) $(LDFLAGS) -o $@ $^

# C コンパイル
src/%.o: src/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# ASM コンパイル
boot/%.o: boot/%.S
	$(CC) $(CFLAGS) -c $< -o $@

# ISO 作成
iso:
	mkdir -p $(ISO_DIR)/boot/grub
	cp $(KERNEL) $(ISO_DIR)/boot/
	cp boot/grub.cfg $(ISO_DIR)/boot/grub/
	grub-mkrescue -o $(ISO) $(ISO_DIR)

clean:
	rm -rf $(OBJ_C) $(OBJ_S) $(KERNEL) $(ISO_DIR) $(ISO)

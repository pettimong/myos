# ファイル名の定義
BOOT = boot.asm
KERNEL = kernel.asm
VGA = vga.asm
KEYBOARD = keyboard.asm

BOOT_BIN = boot.bin
KERNEL_BIN = kernel.bin
IMG = myos.img

# デフォルトのターゲット
all: $(IMG)

# 1. ブートセクタのビルド
$(BOOT_BIN): $(BOOT)
	nasm -f bin $(BOOT) -o $(BOOT_BIN)

# 2. カーネル本体のビルド（分割したファイルも依存関係に含める）
$(KERNEL_BIN): $(KERNEL) $(VGA) $(KEYBOARD)
	nasm -f bin $(KERNEL) -o $(KERNEL_BIN)

# 3. ディスクイメージの作成
# 先頭512バイトに boot.bin、その直後に kernel.bin を配置します
$(IMG): $(BOOT_BIN) $(KERNEL_BIN)
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(IMG)
	# フロッピーサイズ(1.44MB)に足りない分を埋める（QEMUの警告対策）
	truncate -s 1440k $(IMG)

run: $(IMG)
	qemu-system-x86_64 -drive format=raw,file=$(IMG)

clean:
	rm -f *.bin $(IMG)

ASM=nasm
IMG=myos.img

all: $(IMG)

$(IMG): boot.bin kernel.bin
	cat boot.bin kernel.bin > $(IMG)

boot.bin:
	$(ASM) -f bin boot.asm -o boot.bin

kernel.bin:
	$(ASM) -f bin kernel.asm -o kernel.bin

run:
	qemu-system-i386 -drive format=raw,file=$(IMG)

run-tty:
	qemu-system-i386 -drive format=raw,file=$(IMG) -nographic -monitor none -serial stdio

clean:
	rm -f *.bin *.img

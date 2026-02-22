# myOS

最小カーネル学習用プロジェクトです。

## 概要

- x86 向けの最小カーネル
- GRUB ブート対応
- VGA テキスト出力と無限ループによる基本動作確認

## ディレクトリ構成例
```
myos/
├── kernel.c # カーネル本体
├── linker.ld # リンカスクリプト
├── grub.cfg # GRUB 設定
├── iso/ # ISO 作成用フォルダ
└── README.md # このファイル
```
## ビルド・起動手順

1. コンパイル・リンク
   ```bash
   gcc -m32 -ffreestanding -c kernel.c -o kernel.o
   ld -m elf_i386 -T linker.ld -o kernel.bin kernel.o
2. ISO作成
   ```bash
   mkdir -p iso/boot/grub
   cp kernel.bin iso/boot/
   cp grub.cfg iso/boot/grub/
   grub-mkrescue -o myos.iso iso
3. QEMUで起動
   ```bash
   qemu-system-i386 -cdrom myos.iso

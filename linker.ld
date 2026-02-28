ENTRY(kernel_main)

SECTIONS
{
    . = 1M;

    .multiboot : { *(.multiboot) }  /* 先頭に Multiboot2 ヘッダ */
    .text       : { *(.text*) }
    .data       : { *(.data*) }
    .bss        : { *(.bss*) }
}

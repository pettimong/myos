# MyOS - README

## Overview

This repository is a hobby OS project aimed at learning the basics of a mini kernel in a 16-bit environment.

- Experience the full flow from bootloader to kernel
- Utilize BIOS-provided features such as VGA display and keyboard I/O
- Learn about interrupts and simple task management

---

## Current Progress

- Bootloader successfully loads the kernel
- Implemented a printf-like module for VGA text output
- Experimented with a simple software interrupt (ISR) without using a table
- Verified keyboard input and output workflow

---

## Roadmap (16-bit Environment)

1. **Memory Management**
   - Allocate static or simple dynamic memory within the 1MB address space
   - Manage stack and buffers manually within the kernel

2. **Pseudo Task Management**
   - Cooperative task switching (manual switching of functions or states)
   - Save and restore task states
   - Full multitasking will be implemented later in a 32-bit environment

3. **16-bit Learning Release**
   - VGA display, keyboard input/output, and simple interrupt handling (ISR without table)
   - Combine memory management and pseudo task switching to form a functional learning mini-kernel

---

## Outlook for 32-bit Environment

- Implement full GDT / IDT / ISR
- Support hardware interrupts such as `int3`
- Add paging, virtual memory, and multitasking
- Build an ELF / Multiboot-compliant kernel using a cross-compiler

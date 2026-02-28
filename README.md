# myOS

A tiny kernel project for learning and experimenting.
## Overview

- Minimal kernel targeting x86
- Bootable with GRUB 

## Roadmap (Current Progress)
### Basic Screen Output and Core Function
- [x] VGA text mode rendering with line breaks
- [x] Scrolling and string output
- [x] Color-changing functions
- [x] `printf`-style formatting
- [ ] Hardware cursor control

### Entering the World of Interrupts (Current Progress)
- [ ] Organize GDT (if necessary)
- [ ] Set up IDT <<<** NOW!**
- [ ] Keyboard interrupts
- [ ] Simple input buffer

### Memory Management
- [ ] Physical memory management (e.g., bitmap method)
- [ ] Implement `kmalloc'
- [ ] Enable paging
- [ ] Virual memory foundation 

### Min-Kernel Features
- [ ] Timer interrupts
- [ ] Context switching
- [ ] Simple task management
- [ ] User mode experiments (if time allows)

### Milestones (Future Plans / Goals)
- GitHub workflow: Eventually plan to use GitHub Actions to auto-build and run after `git pull`.
- Bochs usage: QEMU for fast tests, Bochs for detailed CPU and interrupt learning.
- Cross-platform reproducibility: Keep settings, configs, and experimental kernels organized so they can be pulled and tested on multiple machines.

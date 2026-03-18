# you asked

概ねβ版が出来上がりました（α版かな）。これについてのREADMEを作って欲しい。英語で作りたいが、参考に和訳文も出してほしい。
コンセプトとしては
# Binary Puzzle OS (myos branch)

This project is a standalone mini-game OS developed as a branch of the **[myos](https://github.com/pettimong/myos)** project. It serves as a practical implementation of low-level system concepts and future feature ideas explored in the main kernel development.

Built entirely in **16-bit Real Mode x86 Assembly**, this OS transforms your computer into a dedicated logic puzzle machine.


## 🎮 Concept
The goal is to transform a randomly generated **Start Value** into a **Goal Value** using bitwise operations. This project demonstrates:
* Direct VRAM manipulation (VGA Text Mode).
* Hardware interrupt handling (Keyboard and Timer).
* Pseudo-random number generation (LCG) using hardware timers.

## 🕹️ How to Play
1.  **Start:** Press the `g` key on the title screen to generate a new puzzle.
2.  **Objective:** Match the `current` value to the `goal` value within **5 moves**.
3.  **Commands:** Type the following commands and press `Enter`:
    * `xor`: Perform an XOR operation with the initial start value.
    * `not`: Bitwise NOT (flips all bits).
    * `shl` / `shr`: Shift bits left or right.
    * `rol` / `ror`: Rotate bits left or right.
    * `exit`: Return to the title screen.

## 🛠️ Environment & Build
This project is designed to be built and run in a **QEMU** environment.

### Prerequisites
* **NASM**: Netwide Assembler.
* **QEMU**: For hardware emulation.
* **Make**: To automate the build process.

### Running the Game
Please refer to the `Makefile` in the root directory for detailed build instructions. Simply run:
```bash
make run
```

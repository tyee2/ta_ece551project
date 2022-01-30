# ta_ece551project
Knight's Tour Project for ECE 551 Fall 2021 written by the TA, Tommy Yee.

## Overview
The Knight's Tour is a classic algorithmic problem in which the knight chess piece is placed on a chessboard (typically 8x8, but we use a 5x5 chessboard for this project) and, using an ordered sequence of L-shaped moves, visits each square on the board aside from its starting position exactly once. The rtl code was synthesized to a robotic demo platform containing an Altera Cyclone IV FPGA. The robot solves the Knight's Tour problem on a physical 5x5 chessboard given its initial coordinate, while playing the "Charge!" fanfare at the end of every move. Images of the demo platform and the physical 5x5 board are included below.

![image](https://user-images.githubusercontent.com/23202270/151713569-746fb4db-3c95-488a-aa61-83b07518379a.png)
![image](https://user-images.githubusercontent.com/23202270/151713745-27ef03b0-079f-4c3c-8124-c5c15bfebc68.png)

The robot interfaces with a [MEMS gyro](https://www.st.com/resource/en/datasheet/lsm6dsl.pdf) using the SPI protocol to obtain its current heading. The PID controller varies the strength of both PWM-driven motors given the error of the current heading from the desired heading. To prevent the robot from going off-course during a move, a combination of reflective tape "guardrails" and three IR sensors located on the underside of the robot are used. When either IR sensor on the sides detects a line of reflective tape, the controller will attempt to "nudge" the robot back into place.

Commands are received by the Bluetooth module on the robot, and the operation of the robot is controlled by a BLE app. Currently, the robot accepts four 16-bit commands:

| Command  | Description |
| -------- | ----------- |
| 0x0000   | Gyro calibration |
| 0x40XY   | Solve tour from given X and Y coordinate  |
| 0x2HHN   | Move N squares in desired heading HH  |
| 0x3HHN   | Move N squares in desired heading HH, with fanfare  |

Gyro headings below (replace HH with hex):

| Hex  | Heading |
| ---- | ------- |
| 0x00  | North |
| 0x3F  | West  |
| 0x7F  | South |
| 0xBF  | East  |

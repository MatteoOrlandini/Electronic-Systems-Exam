# Electronic-Systems-Exam
Assembly code for PIC16F887. This firmware receive a string from serial port and transmit the same string in reverse order.

# Introduction

Creation of a firmware that receives from the computer (via serial port) a word, as a sequence of ascii codes of the single characters. There word is terminated by a point and is of maximum length fixed a priori. After
having received the word, the program must send it back to the serial port written in reverse order.

# Prerequisites

* PIC16F887
* [MPLAB X IDE](https://www.microchip.com/mplab/mplab-x-ide)
* Cedar PIC Board
* (For Windows) Install [USB/serial converter FTDI driver](http://www.ftdichip.com/Drivers/VCP.htm)
* Download the [bootloader](http://www.microchip.com/stellent/idcplg?IdcService=SS_GET_PAGE&nodeId=1824&appnote=en546974)

# How to compile

Open [main.asm](https://github.com/MatteoOrlandini/Electronic-Systems-Exam/blob/master/Esame%20Sistemi%20Elettronici.X/main.asm) in MPLAB X IDE and build.

# How to run

1. Open AN1310 Serial Bootloader
2. Press "Break/reset application firmware"
3. Press the reset button on the board
4. Press "Bootloader mode"
5. Press "Open" and click on the [.hex file](https://github.com/MatteoOrlandini/Electronic-Systems-Exam/blob/master/Esame%20Sistemi%20Elettronici.X/dist/default/production/Esame_Sistemi_Elettronici.X.production.hex) created into the [dist folder](https://github.com/MatteoOrlandini/Electronic-Systems-Exam/tree/master/Esame%20Sistemi%20Elettronici.X/dist).
6. Press "Write device"
7. Press "Run application firmware".

# Flowchart

![](https://github.com/MatteoOrlandini/Electronic-Systems-Exam/blob/master/Diagramma_di_flusso.png)

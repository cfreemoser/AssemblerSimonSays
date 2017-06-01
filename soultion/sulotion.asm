;simon.asm - Game of Simon Says for 8051 Microcontroller
;Copyright (C) 2006 Danko Krajisnik

;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;as published by the Free Software Foundation; either version 2
;of the License, or (at your option) any later version.

;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.

;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

; start switch
start_sw    .equ    P3.7

; input switches
red_sw        .equ    P3.2
green_sw    .equ    P3.3
yellow_sw    .equ    P3.4
blue_sw    .equ    P3.5

; output LED's
red_led    .equ    P1.4
green_led    .equ    P1.5
yellow_led    .equ    P1.6
blue_led    .equ    P1.7


; status LED's
wrong_led    .equ    P3.0
right_led    .equ    P3.1

counter    .equ    30h
input_val    .equ    31h
sequence        .equ    40h

.org    00h
    ajmp    start

.org    03h
    reti

.org    0bh
    reti

.org    13h
    reti

.org    1bh
    reti

.org    23h
    reti

.org    25h
    reti

; delay for short time
delay_short:
    mov    r7, #0ffh
    djnz    r7, $
    ret

; delay longer
delay_medium:
    mov    r6, #0ffh
loop_delay_medium:
    acall    delay_short
    djnz    r6, loop_delay_medium
    ret

; delay even longer
delay_long:
    mov    r5, #04h
loop_delay_long:
    acall    delay_medium
    djnz    r5, loop_delay_long
    ret

; flash red status led 3 times
; to be used after incorrect input sequence
flash_wrong:
    clr    wrong_led
    acall    delay_medium
    setb    wrong_led    
    acall    delay_medium
    clr    wrong_led
    acall    delay_medium
    setb    wrong_led
    acall    delay_medium    
    clr    wrong_led
    acall    delay_medium
    setb    wrong_led
    ret

; flash green status led once
; to be used after every correct user input sequence
flash_right:
    clr    right_led
    acall    delay_medium
    setb    right_led
    ret

; flash green status led 3 times
; to be used after counter is maxed out
flash_win:
    clr    right_led
    acall    delay_medium
    setb    right_led    
    acall    delay_medium
    clr    right_led
    acall    delay_medium
    setb    right_led
    acall    delay_medium    
    clr    right_led
    acall    delay_medium
    setb    right_led
    ret

; flash the red led
flash_red:
    clr    red_led
    acall    delay_medium
    setb    red_led
    ret

; flash the green led
flash_green:
    clr    green_led
    acall    delay_medium
    setb    green_led
    ret

; flash the yellow led
flash_yellow:
    clr    yellow_led
    acall    delay_medium
    setb    yellow_led
    ret

; flash the blue led
flash_blue:
    clr    blue_led
    acall    delay_medium
    setb    blue_led
    ret

; add extra random byte to sequence sequence
add_random:
    mov    a, #sequence
    add    a, counter
    mov    r0, a
    mov    a, TL0

    ; divide timer value by 2 - fix odd/even issues
    mov    B, #02h
    div    ab

    ; isolate lowest 2 bits (random byte will be 0 - 3)
    mov    B, #040h    
    mul    ab
    mov    B, #040h
    div    ab

    mov    @r0, a
    inc    counter
    ret

; read input switch
; store value in input_val
; input_val is modified as follows:
; 0 - red switch was pressed
; 1 - green switch was pressed
; 2 - yellow switch was pressed
; 3 - blue switch was pressed
read_switch:
    jnb    blue_sw, blue_sw_input
    jnb    yellow_sw, yellow_sw_input
    jnb    green_sw, green_sw_input
    jnb    red_sw, red_sw_input
    ajmp    read_switch
red_sw_input:
    acall    flash_red
    mov    input_val, #00h
    jnb    red_sw, $
    ret
green_sw_input:
    acall    flash_green
    mov    input_val, #01h
    jnb    green_sw, $
    ret
yellow_sw_input:
    acall    flash_yellow
    mov    input_val, #02h
    jnb    yellow_sw, $
    ret
blue_sw_input:
    acall    flash_blue
    mov    input_val, #03h
    jnb    blue_sw, $
    ret
    
; flash entire sequence of sequence
flash_sequence:
    mov    r0, #00h
flash_sequence_loop:
    mov    a, counter
    subb    a, r0
    jz    flash_sequence_loop_end
    
    mov    a, #sequence
    add    a, r0
    mov    r1, a
    mov    a, @r1

    ; if sequence is 0 - flash red led
    jz    flash_sequence_red
    
    ; if sequence is 1 - flash green led
    subb    a, #01h
    jz    flash_sequence_green

    ; if sequence is 2 - flash yellow led
    subb    a, #01h
    jz    flash_sequence_yellow
    
    ; else (sequence is 3) - flash blue led
    ajmp    flash_sequence_blue
    
flash_sequence_red:
    acall    flash_red
    ajmp    flash_sequence_over
flash_sequence_green:
    acall    flash_green
    ajmp    flash_sequence_over
flash_sequence_yellow:
    acall    flash_yellow
    ajmp    flash_sequence_over
flash_sequence_blue:
    acall    flash_blue

flash_sequence_over:
    acall    delay_long

    inc    r0
    ajmp    flash_sequence_loop
flash_sequence_loop_end:
    ret

; read switch and compare user input to stored sequence
accept_input:
    mov    r0, #00h    
    mov    r4, #00h
accept_input_loop:
    mov    a, counter
    subb    a, r0
    jz    accept_input_loop_end

    acall    read_switch
    
    mov    a, #sequence
    add    a, r0
    mov    r1, a
    mov    a, @r1
    
    subb    a, input_val
    jz    accept_input_loop_cont
    mov    r4, #01h
    ajmp    accept_input_loop_end

accept_input_loop_cont:

    inc    r0
    ajmp    accept_input_loop

accept_input_loop_end:
    ret

init:
    ; timer 0 - 16 bit mode
    mov    TMOD, #01h
    setb    TR0
    
    mov    PSW, #00h
    mov    IE, #00h

    ; initialize counter
    mov    counter, #00h

    ; activate switches
    setb    red_sw
    setb    green_sw
    setb    yellow_sw
    setb    blue_sw
    setb    start_sw

    ret

start:
    acall    init
    
; wait for user to press and release start switch
wait_start_sw:
    jb    start_sw, $
    jnb    start_sw, $

    acall    delay_long
    acall    delay_long
    
loop:
    acall    add_random
    acall    flash_sequence
    acall    accept_input
    
    acall    delay_long

    mov    a, r4
    jz    cont1
    
    acall    flash_wrong
    mov    counter, #00h
    ajmp    wait_start_sw
    
cont1:
    mov    a, counter
    cjne    a, #0Ah, cont2
    
    acall    flash_win
    mov    counter, #00h
    ajmp    wait_start_sw

cont2:
    acall    flash_right
    acall    delay_long
    ajmp    loop

.end

 

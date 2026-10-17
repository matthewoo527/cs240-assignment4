#AI Disclosure:
# I used ChatGPT to help me get started. I also asked ChatGPT how to connect bitmap display.

#Bitmap Display SETUP:
#Unit Width:8
#Unit Height:8
#Display Width:256
#Display Height:256

#columns=256/8=32, "Formula" for columns: 32*4*COL
#Rows=256/8=32, "Formula" for row: 32*4*ROW

#offset = (row*128)+(column*4)

.data
screen: .space 4096 #address, reserve 4096 bytes for the bitmap display

#An array that stores the offset of each one for 9 positions in the grid
xPositions: .word 396, 440, 484
            .word 1804, 1848, 1892
            .word 3212, 3256, 3300

#An array that stores wheather the blocks has be taken by user
board: .word 0, 0, 0
       .word 0, 0, 0
       .word 0, 0, 0
       
printXWin: .asciiz "Player X wins!\n"
printOWin: .asciiz "Player O wins!\n"

xTurn: .asciiz "Player X's turn! Press 1-9\n"
oTurn: .asciiz "Player O's turn! Press 1-9\n"

instruction: .asciiz "Welcome to Tic-Tac-Toe!\n\nChoose a position:\n1 2 3\n4 5 6\n7 8 9\n\n"

moveCount: .word 0
printTie: .asciiz "It's a tie!\n"

.text
.globl main

main:
    #$a0 stores starting position (memory offset) offset = (row*128)+(column*4)
    #$a1 stores how many bytes move after each block, 4 * ?
    #$a2 stores number of blocks to draw
    #----------------------------------------------
    #----------draw grid--------------
    li $a2, 32 #32 blocks for the grid
    li $t2, 0x00FFFFFF     # White color
    # Draw first horizontal line (row 10)
    li $a0, 1280 #row10*4bytes*32blocks
    li $a1, 4 #Move 4 bytes after each draw
    jal draw_line

    # Draw second horizontal line (row 21)
    li $a0, 2688 #row21*4bytes*32blocks
    li $a1, 4 #Move 4 bytes after each draw
    jal draw_line
    
    # Draw first vertical line (col 10)
    li $a0, 40 #col10*4bytes
    li $a1, 128 #Move 32blocks*4bytes
    jal draw_line

    # Vertical line at column 21
    li $a0, 84 #10
    li $a1, 128 #Move 32blocks *4bytes
    jal draw_line
    
    li $t9, 1        # 1 = Player X, 2 = Player O
    
    #-------Instruction---------
    la $a0, instruction
    
    jal print_both
    #--------Keyboard Input---------
    li $t3, 0xFFFF0000     # Keyboard address

wait_key:
    li $t4, 1
    beq $t9, $t4, print_x

    # Print Player O's turn
    la $a0, oTurn
    j print_turn

print_x:
    # Print Player X's turn
    la $a0, xTurn

print_turn:
    jal print_both       # Print in BOTH windows

read_key:
    lw $t4, 0($t3)         # Check if a key was pressed
    beq $t4, $zero, read_key #if not keep waiting, if $t4=0 means there's no key yet, $t1 mean yes

    lw $t5, 4($t3)         # Read the key
    addi $t5, $t5, -48     # Convert ASCII to number
    
    la $t6, xPositions # Array of drawing positions
    la $t8, board      # Array of occupied cells
    li $t7, 1          # Start at cell 1

find_cell:
    beq $t5, $t7, select_cell

    addi $t6, $t6, 4     # Next drawing position
    addi $t8, $t8, 4     # Next board cell
    addi $t7, $t7, 1     # Next cell number

    li $t4, 10
    bne $t7, $t4, find_cell

    j wait_key           # Invalid input

select_cell:
    lw $t4, 0($t8)        # Read selected board cell
    bne $t4, $zero, wait_key # If not empty, try again
    sw $t9, 0($t8)        # Save current player (1 or 2)
    lw $t6, 0($t6)       # Get selected cell's offset

    li $t4, 1
    beq $t9, $t4, draw_x # If player 1, draw X
    j draw_o             # Otherwise draw O
#--------------draw x----------------    
draw_x:
    li $t2, 0x00FF0000   # Red
    li $a2, 5            # 5 blocks

    # First diagonal
    #\
    # \
    #  \
    add $a0, $t6, $zero
    li $a1, 132 # Down and right
    jal draw_line

    # Second diagonal
    #  /
    # /
    #/
    addi $a0, $t6, 16
    li $a1, 124 # Down and left
    jal draw_line
    
    j next_turn
    
#------------------draw o-----------------
draw_o:
    li $t2, 0x000000FF   # Blue
    li $a2, 3            # 3 blocks per line

    # Top line
    addi $a0, $t6, 4
    li $a1, 4
    jal draw_line

    # Bottom line
    addi $a0, $t6, 516
    li $a1, 4
    jal draw_line

    # Left line
    addi $a0, $t6, 128
    li $a1, 128
    jal draw_line

    # Right line
    addi $a0, $t6, 144
    li $a1, 128
    jal draw_line

    j next_turn

#--------------next turn-----------------
next_turn:
    # Increase number of moves
    lw $t0, moveCount
    addi $t0, $t0, 1
    sw $t0, moveCount
    
    #Check Winner
    jal check_win        # Check if current player won

    li $t4, 1
    beq $v0, $t4, game_won
    
    # Check tie
    lw $t0, moveCount
    li $t4, 9
    beq $t0, $t4, game_tie
    
    #Switch Player
    li $t8, 1
    beq $t9, $t8, switch_to_o
    
    # Switch to X
    li $t9, 1
    j wait_key

switch_to_o:
    # Switch to O
    li $t9, 2
    j wait_key

game_tie:
    la $a0, printTie
    jal print_both

    li $v0, 10
    syscall

finish:
    li $v0, 10 #exit
    syscall

game_won:
    li $t4, 1
    beq $t9, $t4, x_wins

    la $a0, printOWin
    j print_winner

x_wins:
    la $a0, printXWin

print_winner:
    jal print_both     # Print in both windows

    li $v0, 10
    syscall
    
    
#---------------draw grid-------------
draw_line:
    la $t0, screen #Load address to $t0
    #At row stores in $a0 (This just change the address that the color will put in)
    add $t0, $t0, $a0    # Start at row that stores in $a0, 32blocks*4bytes*row10 to skip=1280
    add $t1, $a2, $zero  # Numbers of blocks to draw
    
draw_loop:
    sw $t2, 0($t0)         # Draw one white block
    add $t0, $t0, $a1   # Move to next block
    addi $t1, $t1, -1      # One less block to draw, t1=t1-1
    bne $t1, $zero, draw_loop # If there's still blocks left, then continue draw line
    #Jump to the register, $ra return address refister, that the address was called from
    jr $ra #In this case is main

#---------------Print in Run I/O and Keyboard Display---------------------
print_both:
    add $t6, $a0, $zero   # Save string address

    # Print to Run I/O
    li $v0, 4
    syscall

    # Print to Keyboard Display
    li $t8, 0xFFFF0008   # Display control address

print_next:
    lb $t7, 0($t6)       # Read one character
    beq $t7, $zero, print_done

wait_display:
    lw $t4, 0($t8)       # Check if display is ready
    beq $t4, $zero, wait_display

    sw $t7, 4($t8)       # Print character

    addi $t6, $t6, 1     # Next character
    j print_next

print_done:
    jr $ra

#----------------check winner-----------------
check_win:
    la $t0, board

    # Row 1: cells 1, 2, 3
    lw $t1, 0($t0)
    lw $t4, 4($t0)
    lw $t5, 8($t0)
    bne $t1, $t9, row2
    bne $t4, $t9, row2
    beq $t5, $t9, win

row2:
    # Row 2: cells 4, 5, 6
    lw $t1, 12($t0)
    lw $t4, 16($t0)
    lw $t5, 20($t0)
    bne $t1, $t9, row3
    bne $t4, $t9, row3
    beq $t5, $t9, win

row3:
    # Row 3: cells 7, 8, 9
    lw $t1, 24($t0)
    lw $t4, 28($t0)
    lw $t5, 32($t0)
    bne $t1, $t9, col1
    bne $t4, $t9, col1
    beq $t5, $t9, win

col1:
    # Column 1: cells 1, 4, 7
    lw $t1, 0($t0)
    lw $t4, 12($t0)
    lw $t5, 24($t0)
    bne $t1, $t9, col2
    bne $t4, $t9, col2
    beq $t5, $t9, win

col2:
    # Column 2: cells 2, 5, 8
    lw $t1, 4($t0)
    lw $t4, 16($t0)
    lw $t5, 28($t0)
    bne $t1, $t9, col3
    bne $t4, $t9, col3
    beq $t5, $t9, win

col3:
    # Column 3: cells 3, 6, 9
    lw $t1, 8($t0)
    lw $t4, 20($t0)
    lw $t5, 32($t0)
    bne $t1, $t9, diag1
    bne $t4, $t9, diag1
    beq $t5, $t9, win

diag1:
    # Diagonal: cells 1, 5, 9
    lw $t1, 0($t0)
    lw $t4, 16($t0)
    lw $t5, 32($t0)
    bne $t1, $t9, diag2
    bne $t4, $t9, diag2
    beq $t5, $t9, win

diag2:
    # Diagonal: cells 3, 5, 7
    lw $t1, 8($t0)
    lw $t4, 16($t0)
    lw $t5, 24($t0)
    bne $t1, $t9, no_win
    bne $t4, $t9, no_win
    beq $t5, $t9, win
    
    j no_win

win:
    li $v0, 1
    jr $ra
#---------tie---------------
no_win:
    li $v0, 0         # No winner
    jr $ra
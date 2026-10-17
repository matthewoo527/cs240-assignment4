# cs240-assignment4
## Tic Tac Toe
AI Disclosure: I used ChatGPT to help me get started. I also asked ChatGPT how to connect a bitmap display.

### Source Code
```asm
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



```

### Screenshots of the graphic display
<img width="680" height="415" alt="Screenshot 2026-10-16 at 22 43 33" src="https://github.com/user-attachments/assets/6fe4dff0-8120-4fd6-b118-3a31718e51bf" />
<img width="828" height="633" alt="Screenshot 2026-10-16 at 22 43 45" src="https://github.com/user-attachments/assets/dbd5a3bc-93c0-492f-a1be-daf6c6d4c3cc" />
<img width="687" height="419" alt="Screenshot 2026-10-16 at 22 44 45" src="https://github.com/user-attachments/assets/cc303cfa-6358-4485-bc32-1da4d01c51c4" />
<img width="639" height="183" alt="Screenshot 2026-10-16 at 22 44 11" src="https://github.com/user-attachments/assets/eec6b2b3-4531-4067-9edb-1906349f2e64" />



### Instructions for running the program
0. Open MARS
1. Connect Bitmap display from tools

   <img width="303" height="24" alt="Screenshot 2026-10-16 at 22 46 06" src="https://github.com/user-attachments/assets/103333ee-cd9b-4190-8561-a690fc3808ab" />

   
   <img width="311" height="296" alt="Screenshot 2026-10-16 at 22 46 16" src="https://github.com/user-attachments/assets/630cc9d8-9e90-4d09-8c8b-bf8fa1d8c9c3" />

   Make sure the Bitmap Display settings is correct:
   
   <img width="378" height="167" alt="Screenshot 2026-10-16 at 22 54 06" src="https://github.com/user-attachments/assets/dab055f5-0877-4775-ab83-ccf0908b8675" />

3. Connect Keyboard and Display MMIO Simulator
   
   <img width="309" height="301" alt="Screenshot 2026-10-16 at 22 47 15" src="https://github.com/user-attachments/assets/87e1ece6-41c3-4ab9-97e7-2a03c61bc9b2" />
4. Press "Connect to MIPS" in both tools
   
   <img width="681" height="51" alt="Screenshot 2026-10-16 at 22 47 54" src="https://github.com/user-attachments/assets/beb79080-690a-42ac-a701-bc027681fbab" />
5. Press the assemble button <img width="22" height="20" alt="Screenshot 2026-10-16 at 22 49 33" src="https://github.com/user-attachments/assets/493f0beb-73b5-4a4a-b507-f65da02a7d07" /> and Run <img width="30" height="35" alt="Screenshot 2026-10-16 at 22 50 38" src="https://github.com/user-attachments/assets/04d118c9-1cb4-448c-920a-724c4a731cef" />

   __*IMPORTANT: After connecting both tools to MIPS, press the reset button on the keyboard and display MMIO simulator, or it will not show anything in the bitmap display.*__
6. Use the "Keyboard" in Keyboard and Display MMIO Simulator to start to play Tic Tac Toe!
   
   Follow the instructions on screen to play!
   
   <img width="820" height="228" alt="Screenshot 2026-10-16 at 22 55 39" src="https://github.com/user-attachments/assets/322f8a30-cc2a-40cb-8a4c-be8368fb87b6" />

### Test Cases
#### Three Normal Cases
__Normal Test Case 1__
Player X wins horizontally

<img width="705" height="676" alt="Screenshot 2026-10-17 at 12 47 35" src="https://github.com/user-attachments/assets/5a6ce77f-5ec4-4848-be04-b096bb20024b" />

<img width="547" height="262" alt="Screenshot 2026-10-17 at 12 52 19" src="https://github.com/user-attachments/assets/dd4be9e8-3754-479f-aba0-fe185376c228" />

<img width="700" height="407" alt="Screenshot 2026-10-17 at 12 47 52" src="https://github.com/user-attachments/assets/5369eac8-5d92-49ac-a9d4-2f38dceb9fa7" />

__Normal Test Case 2__
Player O wins vertically

<img width="705" height="672" alt="Screenshot 2026-10-17 at 12 51 01" src="https://github.com/user-attachments/assets/946be572-ab4b-4769-aebc-9b91b7c3d354" />

<img width="619" height="300" alt="Screenshot 2026-10-17 at 12 51 18" src="https://github.com/user-attachments/assets/4aee1e73-6b66-4e98-9613-86cda827e34f" />

<img width="696" height="408" alt="Screenshot 2026-10-17 at 12 50 49" src="https://github.com/user-attachments/assets/5e93425a-7c33-4565-8e12-4edac0f53a8d" />

__Normal Test Case 3__
Game ends in a tie

<img width="708" height="674" alt="Screenshot 2026-10-17 at 12 56 11" src="https://github.com/user-attachments/assets/92e998a3-a6bf-4056-8caa-6bef72b0be0d" />

<img width="696" height="407" alt="Screenshot 2026-10-17 at 12 56 33" src="https://github.com/user-attachments/assets/7a280659-2072-48d4-9498-ef2a07823097" />

<img width="546" height="340" alt="Screenshot 2026-10-17 at 12 56 26" src="https://github.com/user-attachments/assets/4a133529-fc70-4e11-862c-af2544a55fc4" />

#### Two edge cases

__Edge Case 1__
Player selects an occupied cell

It will ask the current player again:

<img width="703" height="671" alt="Screenshot 2026-10-17 at 13 03 13" src="https://github.com/user-attachments/assets/c8a34c6c-f4e9-4507-a80e-1afd583444e1" />

<img width="572" height="390" alt="Screenshot 2026-10-17 at 13 03 21" src="https://github.com/user-attachments/assets/8072df01-d0db-4b09-9507-3a420ef21116" />

<img width="695" height="403" alt="Screenshot 2026-10-17 at 13 03 28" src="https://github.com/user-attachments/assets/0e59bca0-6214-47ec-bf59-95bad8d81078" />

__Edge Case 2__
Player enters an invalid position (0 or 10)

It will ask the current player again:

<img width="704" height="669" alt="Screenshot 2026-10-17 at 12 58 47" src="https://github.com/user-attachments/assets/c70ffd64-8d8e-47dd-86c0-6d812019f737" />

<img width="538" height="408" alt="Screenshot 2026-10-17 at 12 58 56" src="https://github.com/user-attachments/assets/667656de-f1d7-42d5-86f5-9ced07e5df10" />

<img width="697" height="406" alt="Screenshot 2026-10-17 at 12 59 05" src="https://github.com/user-attachments/assets/5c35d039-0e94-4e41-ae5d-e919d6c2e355" />

### Short design note explaining the game procedures
This is a two-player tic-tac-toe game with human vs human. 
The draw_line procedure draws the board and X/O symbols, while print_both displays messages in Run I/O and MMIO Display. 
The check_win procedure checks if a player has won. 
The program also uses an array to track occupied positions and a counter to check for a tie. 
The game ends when a player wins or the board is full.




## Blackjack
### Source Code
```asm
#AI Disclosure: I used ChatGPT 6 to help me write the starter code and debug.
#I also used ChatGPT 6 to learn how to draw the cards and the background
#ChatGPT 6 also helped me to learn how to use the keyboard and display MMIO sim
#and char allows in the MMIO simulatar

.data
screen:      .space 4096             # 32 rows x 32 columns x 4 bytes
pScore:      .word 0                # Player score
pAces:       .word 0                # Player Aces still counted as 11
dScore:      .word 0                # Dealer score
dAces:       .word 0                # Dealer Aces still counted as 11
pCount:      .word 0                # Number of player cards
pNext:       .word 0                # Offset of next player card
dCount:      .word 0                # Number of dealer cards
dNext:       .word 0                # Offset of next dealer card

intro:       .asciiz "BLACKJACK!\nH = Hit, S = Stand. Get close to 21!\n"
playerDraw:  .asciiz "Player draws a card.\n"
dealerDraw:  .asciiz "Dealer draws a card.\n"
scoreText:   .asciiz "Your score: "
askText:     .asciiz "  Press H to Hit, S to Stand.\n"
newLine:     .asciiz "\n"
invalidText: .asciiz "Please press H or S.\n"
pFinal:      .asciiz "Final - Player: "
dFinal:      .asciiz "  Dealer: "
winText:     .asciiz "You win!\n"
loseText:    .asciiz "Dealer wins!\n"
tieText:     .asciiz "Tie!\n"

# Rank pictures: 3 columns by 5 rows; '1' = ink and '0' = white.
# The rank 10 uses a special 5-column by 5-row picture.
rankA:  .ascii "111101111101101"
rank2:  .ascii "111001111100111"
rank3:  .ascii "111001111001111"
rank4:  .ascii "101101111001001"
rank5:  .ascii "111100111001111"
rank6:  .ascii "111100111101111"
rank7:  .ascii "111001001001001"
rank8:  .ascii "111101111101111"
rank9:  .ascii "111101111001111"
rank10: .ascii "1011110101101011010110111"
rankJ:  .ascii "111001001101111"
rankQ:  .ascii "111101101111001"
rankK:  .ascii "101101110101101"
.align 2
#The addresses of 13 cards
fonts: .word rankA, rank2, rank3, rank4, rank5, rank6, rank7
       .word rank8, rank9, rank10, rankJ, rankQ, rankK

# -------- DEALER and PLAYER labels --------

dealerLabel:
    .ascii "110101101101110"    # D
    .ascii "111100110100111"    # E
    .ascii "111101111101101"    # A
    .ascii "100100100100111"    # L
    .ascii "111100110100111"    # E
    .ascii "110101110101101"    # R

playerLabel:
    .ascii "110101110100100"    # P
    .ascii "100100100100111"    # L
    .ascii "111101111101101"    # A
    .ascii "101101010010010"    # Y
    .ascii "111100110100111"    # E
    .ascii "110101110101101"    # R

.text
.globl main
main:
    #----Draw table----
    jal draw_table
    
    #-------- Draw DEALER label --------
    li $a0, 1296           # Row 10, column 4
    la $a1, dealerLabel    # Letters DEALER
    li $a2, 0x00FFFF00     # Yellow
    jal draw_label

    #-------- Draw PLAYER label --------
    li $a0, 3344           # Row 26, column 4
    la $a1, playerLabel    # Letters PLAYER
    li $a2, 0x0000FFFF     # Light blue
    jal draw_label

    #---Starting Card Position---
    la $t0, screen
    addi $t1, $zero, 388       # Dealer: row 3, col 1
    sw $t1, dNext
    addi $t1, $zero, 2436      # Player: row 19, col 1
    sw $t1, pNext

    la $a0, intro
    jal print_both

    #---Print starting cards---
    li $a0, 0                  # 0 = dealer
    jal deal
    li $a0, 1                  # 1 = player
    jal deal
    li $a0, 0
    jal deal
    li $a0, 1
    jal deal

player_turn:
    #print player current score
    la $a0, scoreText
    jal print_both
    lw $a0, pScore
    jal print_number
    la $a0, newLine
    jal print_both

    # 21 means stop; over 21 means bust.
    lw $t0, pScore
    li $t1, 21
    bgt $t0, $t1, finish
    beq $t0, $t1, dealer_turn

    # Ask the player for H or S.
    la $a0, askText
    jal print_both

#Check for input
input_loop:
    jal read_key                 # Key's ASCII code is returned in $v0.
    li $t0, 72                  # 'H'
    beq $v0, $t0, hit
    li $t0, 104                 # 'h'
    beq $v0, $t0, hit
    li $t0, 83                  # 'S'
    beq $v0, $t0, dealer_turn
    li $t0, 115                 # 's'
    beq $v0, $t0, dealer_turn
    la $a0, invalidText
    jal print_both
    j input_loop

hit:
    li $a0, 1                   # Give player one more card.
    jal deal
    j player_turn

dealer_turn:
    # Dealer keep drawing until 17
    lw $t0, dScore
    li $t1, 17
    bge $t0, $t1, finish #if >=17, then stop
    li $a0, 0
    jal deal
    j dealer_turn

finish:
    # Show both scores
    la $a0, pFinal
    jal print_both
    lw $a0, pScore
    jal print_number
    la $a0, dFinal
    jal print_both
    lw $a0, dScore
    jal print_number
    la $a0, newLine
    jal print_both

    lw $t0, pScore
    lw $t1, dScore
    li $t2, 21
    bgt $t0, $t2, player_loses   # Player busts.
    bgt $t1, $t2, player_wins    # Dealer busts.
    bgt $t0, $t1, player_wins
    blt $t0, $t1, player_loses
    la $a0, tieText
    j show_result

player_wins:
    la $a0, winText
    j show_result

player_loses:
    la $a0, loseText

show_result:
    jal print_both
    #exit
    li $v0, 10
    syscall

#-----------deal one card-----------
deal:
    addi $sp, $sp, -20
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $ra, 16($sp)
    add $s0, $a0, $zero          # Remember who gets the card.

    # MARS random number: 0..12; add 1 for ranks 1..13.
    li $v0, 42 #$v0=42 is random numbers
    li $a0, 0
    li $a1, 13
    syscall
    addi $s1, $a0, 1             # Rank: 1=A, 11=J, 12=Q, 13=K.

    # Choose which score to update.
    beq $s0, $zero, dealer_info #$s0 save which card was deal to
    la $s2, pScore
    la $s3, pAces
    la $a0, playerDraw
    j card_message

dealer_info:
    la $s2, dScore
    la $s3, dAces
    la $a0, dealerDraw

card_message:
    jal print_both

    # Card value: Ace=11 (can later become 1), J/Q/K=10, others=rank.
    add $t0, $s1, $zero
    li $t1, 1
    beq $s1, $t1, ace_value
    li $t1, 10
    ble $s1, $t1, add_points
    li $t0, 10
    j add_points

ace_value:
    li $t0, 11
    lw $t1, 0($s3)
    addi $t1, $t1, 1
    sw $t1, 0($s3)

add_points:
    lw $t1, 0($s2)
    add $t1, $t1, $t0
    sw $t1, 0($s2)

fix_aces:
    # If total >21 and an Ace counts as 11, reduce score by 10.
    lw $t0, 0($s2)
    li $t1, 21
    ble $t0, $t1, draw_dealt
    lw $t1, 0($s3)
    beq $t1, $zero, draw_dealt
    addi $t0, $t0, -10
    sw $t0, 0($s2)
    addi $t1, $t1, -1
    sw $t1, 0($s3)
    j fix_aces

draw_dealt:
    # Draw the card and move next position 6 blocks to the right.
    beq $s0, $zero, draw_dealer_card
    lw $t0, pCount
    li $t1, 5
    bge $t0, $t1, player_count
    lw $a0, pNext               # Bitmap offset
    add $a1, $s1, $zero         # Rank
    li $a2, 0x00CC0000          # Player's red ink
    jal draw_card
    lw $t0, pNext
    addi $t0, $t0, 24           # 6 blocks * 4 bytes
    sw $t0, pNext
player_count:
    lw $t0, pCount
    addi $t0, $t0, 1
    sw $t0, pCount
    j deal_done

draw_dealer_card:
    lw $t0, dCount
    li $t1, 5
    bge $t0, $t1, dealer_count
    lw $a0, dNext
    add $a1, $s1, $zero
    li $a2, 0x00000000           # Dealer's black ink
    jal draw_card
    lw $t0, dNext
    addi $t0, $t0, 24
    sw $t0, dNext
dealer_count:
    lw $t0, dCount
    addi $t0, $t0, 1
    sw $t0, dCount

deal_done:
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra

#Draw Backround(Table)
draw_table:
    la $t0, screen
    li $t1, 1024
    li $t2, 0x00005533 #Green
table_loop:
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bne $t1, $zero, table_loop

    la $t0, screen
    addi $t0, $t0, 1920        # Row 15 * 128 bytes
    li $t1, 32
    li $t2, 0x00AAAAAA
divider_loop:
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bne $t1, $zero, divider_loop
    jr $ra

#-----Draw Card--------
#$a0=screen offset
#$a1=rank (1..13)
#$a2=ink color.
#5colx7row, then draw its letter or number
draw_card:
    la $t0, screen
    add $t0, $t0, $a0
    li $t1, 7                   # Height = 7 blocks
    li $t4, 0x00FFFFFF
card_row:
    add $t3, $t0, $zero
    li $t2, 5                   # Width = 5 blocks
card_column:
    sw $t4, 0($t3)
    addi $t3, $t3, 4            # Move 1 block right
    addi $t2, $t2, -1
    bne $t2, $zero, card_column
    addi $t0, $t0, 128         # Move 1 row down
    addi $t1, $t1, -1
    bne $t1, $zero, card_row

    # Select the picture for rank A, 2, 3 ... 10, J, Q, K.
    la $t4, fonts
    addi $t5, $a1, -1
find_font:
    beq $t5, $zero, font_found
    addi $t4, $t4, 4
    addi $t5, $t5, -1
    j find_font
font_found:
    lw $t4, 0($t4)             # Address of the rank picture
    la $t0, screen
    add $t0, $t0, $a0
    addi $t0, $t0, 132          # Inside card: down 1, right 1
    li $t8, 3                   # Most ranks use 3 columns
    li $t9, 10
    bne $a1, $t9, font_begin
    addi $t0, $t0, -4           # Rank 10 needs all 5 columns
    li $t8, 5
font_begin:
    li $t1, 5                   # Each rank is 5 rows tall
font_row:
    add $t3, $t0, $zero
    add $t2, $t8, $zero
font_column:
    lb $t5, 0($t4)             # ASCII character '1' or '0'
    li $t6, 49                  # ASCII code for '1'
    bne $t5, $t6, leave_white
    sw $a2, 0($t3)             # Draw colored block
leave_white:
    addi $t4, $t4, 1            # Next pattern character
    addi $t3, $t3, 4            # Next display block
    addi $t2, $t2, -1
    bne $t2, $zero, font_column
    addi $t0, $t0, 128         # Next display row
    addi $t1, $t1, -1
    bne $t1, $zero, font_row
    jr $ra
# -------- Draw label --------
# $a0 = Starting bitmap offset
# $a1 = Address of letter patterns
# $a2 = Letter color

draw_label:
    la $t0, screen
    add $t0, $t0, $a0      # Starting position
    add $t4, $a1, $zero    # Address of first pattern
    li $t9, 6              # 6 letters

label_letter:
    add $t6, $t0, $zero    # Starting row
    li $t1, 5              # 5 rows per letter

label_row:
    add $t3, $t6, $zero    # Starting column
    li $t2, 3              # 3 columns per letter

label_column:
    lb $t5, 0($t4)         # Read '0' or '1'
    li $t7, 49             # ASCII '1'
    bne $t5, $t7, label_skip

    sw $a2, 0($t3)         # Draw colored block

label_skip:
    addi $t4, $t4, 1       # Next pattern character
    addi $t3, $t3, 4       # Next block right
    addi $t2, $t2, -1
    bne $t2, $zero, label_column

    addi $t6, $t6, 128     # Move down one row
    addi $t1, $t1, -1
    bne $t1, $zero, label_row

    addi $t0, $t0, 16      # Move 4 blocks right
    addi $t9, $t9, -1      # One less letter
    bne $t9, $zero, label_letter

    jr $ra

#Keyboard and Display MMIO
read_key:
    li $t0, 0xFFFF0000         # Keyboard control address
key_wait:
    lw $t1, 0($t0)
    beq $t1, $zero, key_wait   # Wait for a key
    lw $v0, 4($t0)             # Keyboard data address
    jr $ra

# ----------------------------------------------------------------
# PRINT STRING IN BOTH TEXT WINDOWS
# $a0 = address of a null-terminated string.
# Run I/O: syscall 4; MMIO Display: characters one at a time.
# ----------------------------------------------------------------
print_both:
    add $t6, $a0, $zero
    li $v0, 4
    syscall
    li $t8, 0xFFFF0008         # MMIO display control address
print_next:
    lb $t7, 0($t6)
    beq $t7, $zero, print_done
print_wait:
    lw $t4, 0($t8)
    beq $t4, $zero, print_wait
    sw $t7, 4($t8)             # MMIO display data address
    addi $t6, $t6, 1
    j print_next
print_done:
    jr $ra

#Prin char at Keyboard and Display MMIO
print_char:
    add $t5, $a0, $zero
    li $v0, 11                  # Run I/O: print one character
    syscall
    li $t8, 0xFFFF0008
char_wait:
    lw $t9, 0($t8)
    beq $t9, $zero, char_wait
    sw $t5, 4($t8)             # MMIO: print one character
    jr $ra

#----------print numbers-------------
print_number:
    addi $sp, $sp, -12 #Memory stack
    sw $s4, 0($sp)
    sw $s5, 4($sp)
    sw $ra, 8($sp)
    add $s4, $a0, $zero         # Number to print
    li $s5, 0                   # Tens digit
number_tens:
    li $t0, 10
    blt $s4, $t0, number_digits
    #----Subtract 10 repeatedly instead of using multiplication/division.-----
    #Make it a char for keyboard and display MMIO
    addi $s4, $s4, -10
    addi $s5, $s5, 1
    j number_tens
number_digits:
    beq $s5, $zero, number_ones
    addi $a0, $s5, 48           # Convert digit to ASCII
    jal print_char
number_ones:
    addi $a0, $s4, 48
    jal print_char
    lw $s4, 0($sp)
    lw $s5, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

```




## Snake
### Source Code
```asm
#AI Disclosure: Used ChatGPT 6 to help me start the snake code.
# Then I asked ChatGPT to tell me what is each part doing and make it better and shorter.

# Bitmap Display: Unit 4x4, Display 256x256, base 0x10010000.
# Keyboard and Display MMIO Simulator: connect before Run.
# W/A/S/D = move, Q = quit. Uppercase or lowercase works.

.data
screen: .space 16384               # 64 x 64 bitmap units, FIRST in .data
snake:  .word 8320, 8312, 8304    # Head and 2 body blocks
        .space 3108               # Space for 780 snake blocks total

intro:   .asciiz "SNAKE! W/A/S/D move, Q quit. Eat red food.\n"
over:    .asciiz "GAME OVER!\n"
quitMsg: .asciiz "Game stopped.\n"
won:     .asciiz "You filled the board!\n"
final:   .asciiz "Final score: "
scoreText: .asciiz "SCORE000\n"  # We change the last 3 digits as food is eaten

# Each bitmap letter is 5 columns x 7 rows (35 characters).
# '1' = colored pixel; '0' = background. Five letters followed by ten digits.
letters:
    .ascii "01111100001000001110000010000111110" # S
    .ascii "01111100001000010000100001000001111" # C
    .ascii "01110100011000110001100011000101110" # O
    .ascii "11110100011000111110101001001010001" # R
    .ascii "11111100001000011110100001000011111" # E
digits:
    .ascii "01110100011001110101110011000101110" # 0
    .ascii "00100011000010000100001000010001110" # 1
    .ascii "01110100010000100010001000100011111" # 2
    .ascii "11110000010000101110000010000111110" # 3
    .ascii "00010001100101010010111110001000010" # 4
    .ascii "11111100001000011110000010000111110" # 5
    .ascii "01110100001000011110100011000101110" # 6
    .ascii "11111000010001000100010000100001000" # 7
    .ascii "01110100011000101110100011000101110" # 8
    .ascii "01110100011000101111000010000101110" # 9

.text
.globl main
main:
    li $s0, 0       # Direction: 0=right, 1=down, 2=left, 3=up
    li $s1, 16      # Head column
    li $s2, 16      # Head row
    li $s3, 3       # Snake length
    li $s4, 0       # Score
    li $s5, 4256    # Food at row 8, column 20
    la $a0, intro
    jal print_both
    jal draw_scene

main_loop:
    li $v0, 32      # Pause 180 milliseconds (MARS syscall)
    li $a0, 180
    syscall
    jal read_key
    li $t0, 1
    beq $v0, $t0, quit_game
    jal move_snake
    li $t0, 1
    beq $v0, $t0, game_over
    li $t0, 2
    beq $v0, $t0, game_won
    jal draw_scene
    j main_loop

quit_game:
    la $a0, quitMsg
    j end_message
game_over:
    la $a0, over
    j end_message
game_won:
    la $a0, won
end_message:
    jal print_both
    la $a0, final
    jal print_both
    la $a0, scoreText
    addi $a0, $a0, 5       # Skip SCORE, print only the 3 digits
    jal print_both
    li $v0, 10
    syscall

# READ_KEY: Check keyboard without stopping the snake.
# $v0=1 if Q, otherwise 0. Ignore reverse direction.
read_key:
    li $v0, 0
    li $t0, 0xFFFF0000
    lw $t1, 0($t0)          # 0 = no key available
    beq $t1, $zero, key_done
    lw $t2, 4($t0)          # ASCII of key
    ori $t2, $t2, 32       # Convert uppercase letters to lowercase
    li $t3, 113            # q
    beq $t2, $t3, key_quit
    li $t3, 100            # d
    beq $t2, $t3, right
    li $t3, 115            # s
    beq $t2, $t3, down
    li $t3, 97             # a
    beq $t2, $t3, left
    li $t3, 119            # w
    beq $t2, $t3, up
    j key_done
right:
    li $t3, 2
    beq $s0, $t3, key_done
    li $s0, 0
    j key_done
down:
    li $t3, 3
    beq $s0, $t3, key_done
    li $s0, 1
    j key_done
left:
    li $t3, 0
    beq $s0, $t3, key_done
    li $s0, 2
    j key_done
up:
    li $t3, 1
    beq $s0, $t3, key_done
    li $s0, 3
    j key_done
key_quit:
    li $v0, 1
key_done:
    jr $ra

# MOVE_SNAKE: Move head, check walls/body, and update array.
# $t8 = next head offset; $t9 = 1 if eating food.
move_snake:
    addi $sp, $sp, -4
    sw $ra, 0($sp)          # Save $ra because we call new_food
    lw $t8, snake
    li $t0, 0
    beq $s0, $t0, go_right
    li $t0, 1
    beq $s0, $t0, go_down
    li $t0, 2
    beq $s0, $t0, go_left
    addi $s2, $s2, -1      # Up
    addi $t8, $t8, -512
    j wall_check
go_right:
    addi $s1, $s1, 1
    addi $t8, $t8, 8
    j wall_check
go_down:
    addi $s2, $s2, 1
    addi $t8, $t8, 512
    j wall_check
go_left:
    addi $s1, $s1, -1
    addi $t8, $t8, -8
wall_check:
    li $t0, 1              # Playable columns: 1..30
    blt $s1, $t0, lost
    li $t0, 31
    bge $s1, $t0, lost
    li $t0, 5              # Playable rows: 5..30
    blt $s2, $t0, lost
    li $t0, 31
    bge $s2, $t0, lost

    li $t9, 0              # Not eating unless head reaches food
    bne $t8, $s5, body_check
    li $t9, 1
body_check:
    la $t0, snake
    add $t1, $s3, $zero     # Check each body position
    bne $t9, $zero, body_loop
    addi $t1, $t1, -1      # Old tail moves away if not eating
body_loop:
    beq $t1, $zero, shift_start
    lw $t2, 0($t0)
    beq $t2, $t8, lost
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    j body_loop

shift_start:
    beq $t9, $zero, shift_setup
    addi $s3, $s3, 1      # Eating: grow by one
    addi $s4, $s4, 1      # Score +1
shift_setup:
    add $t1, $s3, $zero
    addi $t1, $t1, -1      # Last element index
    add $t2, $t1, $t1     # Index * 4 bytes (without mul)
    add $t2, $t2, $t2
    la $t0, snake
    add $t0, $t0, $t2
shift_loop:
    beq $t1, $zero, shift_done
    lw $t2, -4($t0)       # Copy previous segment into this one
    sw $t2, 0($t0)
    addi $t0, $t0, -4
    addi $t1, $t1, -1
    j shift_loop
shift_done:
    sw $t8, snake           # New head goes first in array
    beq $t9, $zero, moved
    jal update_score        # Update digits used in bitmap and final text
    li $t0, 780
    beq $s3, $t0, filled
    jal new_food
moved:
    li $v0, 0
    j move_return
lost:
    li $v0, 1
    j move_return
filled:
    li $v0, 2
move_return:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# UPDATE_SCORE: Change SCORE000 into SCORE001, SCORE002, etc.
# Subtract 100 and 10 to find the individual digits.
update_score:
    add $t0, $s4, $zero    # Number remaining
    la $t2, scoreText
    li $t1, 48             # ASCII '0' for hundreds
hundreds:
    li $t3, 100
    blt $t0, $t3, tens
    addi $t0, $t0, -100
    addi $t1, $t1, 1
    j hundreds
tens:
    sb $t1, 5($t2)         # Write hundreds character
    li $t1, 48
find_tens:
    li $t3, 10
    blt $t0, $t3, ones
    addi $t0, $t0, -10
    addi $t1, $t1, 1
    j find_tens
ones:
    sb $t1, 6($t2)         # Write tens character
    addi $t0, $t0, 48
    sb $t0, 7($t2)         # Write ones character
    jr $ra

# NEW_FOOD: Pick one of 780 playable cells, avoiding the snake.
new_food:
try_food:
    li $v0, 42
    li $a0, 0
    li $a1, 780
    syscall                # $a0 = random 0..779
    li $t6, 2568           # Top-left playable cell: row 5, col 1
food_row:
    li $t7, 30
    blt $a0, $t7, food_col
    addi $a0, $a0, -30
    addi $t6, $t6, 512     # Down one snake cell
    j food_row
food_col:
    add $t7, $a0, $a0
    add $t7, $t7, $t7
    add $t7, $t7, $t7      # Column * 8 bytes
    add $s5, $t6, $t7     # New food bitmap offset
    la $t0, snake
    add $t1, $s3, $zero
food_check:
    beq $t1, $zero, food_ok
    lw $t2, 0($t0)
    beq $t2, $s5, try_food
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    j food_check
food_ok:
    jr $ra

# DRAW_SCENE: Clear screen, draw border, food, snake, and SCORE.
draw_scene:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    la $t0, screen
    li $t1, 4096           # 64*64 bitmap units
    li $t2, 0x001A1A1A
clear_loop:
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bne $t1, $zero, clear_loop
    jal draw_border
    add $a0, $s5, $zero
    li $a1, 0x00FF3333     # Red food
    jal draw_block
    la $t3, snake
    add $t4, $s3, $zero
snake_loop:
    lw $a0, 0($t3)
    li $a1, 0x0000AA33     # Dark green body
    jal draw_block
    addi $t3, $t3, 4
    addi $t4, $t4, -1
    bne $t4, $zero, snake_loop
    lw $a0, snake
    li $a1, 0x0033FF55     # Bright green head
    jal draw_block
    jal draw_hud
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# DRAW_BORDER: Gray line across row 8 and row 63, plus sides.
draw_border:
    la $t0, screen
    li $t2, 0x00AAAAAA
    addi $t3, $t0, 2048   # Row 8
    li $t1, 64
border_top:
    sw $t2, 0($t3)
    addi $t3, $t3, 4
    addi $t1, $t1, -1
    bne $t1, $zero, border_top
    addi $t3, $t0, 16128  # Row 63
    li $t1, 64
border_bottom:
    sw $t2, 0($t3)
    addi $t3, $t3, 4
    addi $t1, $t1, -1
    bne $t1, $zero, border_bottom
    addi $t3, $t0, 2304   # Row 9
    li $t1, 54
border_sides:
    sw $t2, 0($t3)
    sw $t2, 252($t3)      # Right side: column 63
    addi $t3, $t3, 256
    addi $t1, $t1, -1
    bne $t1, $zero, border_sides
    jr $ra

# DRAW_BLOCK: 2x2 bitmap units, giving an 8x8-pixel snake/food square.
draw_block:
    la $t0, screen
    add $t0, $t0, $a0
    sw $a1, 0($t0)
    sw $a1, 4($t0)
    sw $a1, 256($t0)
    sw $a1, 260($t0)
    jr $ra

# DRAW_HUD: Draw 5 letters SCORE, then 3 digits from scoreText.
draw_hud:
    addi $sp, $sp, -12
    sw $s6, 0($sp)
    sw $s7, 4($sp)
    sw $ra, 8($sp)
    la $s6, letters        # Picture for S
    li $s7, 0              # Starting bitmap offset
hud_letters:
    add $a0, $s7, $zero
    add $a1, $s6, $zero
    li $a2, 0x00FFFF00     # Yellow
    jal draw_glyph
    addi $s6, $s6, 35      # Next 5x7 letter
    addi $s7, $s7, 24      # Move right 6 bitmap units
    li $t0, 120
    bne $s7, $t0, hud_letters
    la $s6, scoreText
    addi $s6, $s6, 5       # Point to first score digit
hud_digits:
    lb $t0, 0($s6)
    addi $t0, $t0, -48     # ASCII digit -> 0..9
    la $a1, digits
find_font:
    beq $t0, $zero, font_ready
    addi $a1, $a1, 35
    addi $t0, $t0, -1
    j find_font
font_ready:
    add $a0, $s7, $zero
    li $a2, 0x00FFFFFF     # White digits
    jal draw_glyph
    addi $s6, $s6, 1
    addi $s7, $s7, 24
    li $t0, 192
    bne $s7, $t0, hud_digits
    lw $s6, 0($sp)
    lw $s7, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

# DRAW_GLYPH: Draw one 5x7 picture ('1'=color, '0'=empty).
# $a0=bitmap offset, $a1=picture address, $a2=color.
draw_glyph:
    la $t0, screen
    add $t0, $t0, $a0
    add $t1, $a1, $zero
    li $t2, 7
glyph_row:
    add $t3, $t0, $zero
    li $t4, 5
glyph_col:
    lb $t5, 0($t1)
    li $t6, 49             # ASCII '1'
    bne $t5, $t6, no_pixel
    sw $a2, 0($t3)
no_pixel:
    addi $t1, $t1, 1
    addi $t3, $t3, 4
    addi $t4, $t4, -1
    bne $t4, $zero, glyph_col
    addi $t0, $t0, 256    # Next bitmap row
    addi $t2, $t2, -1
    bne $t2, $zero, glyph_row
    jr $ra

# PRINT_BOTH: String in $a0 -> Run I/O and MMIO text display.
print_both:
    add $t6, $a0, $zero
    li $v0, 4              # Print string in Run I/O
    syscall
    li $t8, 0xFFFF0008     # MMIO display control
print_next:
    lb $t7, 0($t6)
    beq $t7, $zero, print_done
print_wait:
    lw $t4, 0($t8)        # Wait for display to be ready
    beq $t4, $zero, print_wait
    sw $t7, 4($t8)        # Send one character to MMIO
    addi $t6, $t6, 1
    j print_next
print_done:
    jr $ra

```

# cs240-assignment4
## Tic Tac Toe
## AI Disclosure: I used ChatGPT to help me get started. I also asked ChatGPT how to connect a bitmap display.

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
6. Use the "Keyboard" in Keyboard and Display MMIO Simulator to start to play Tic Tac Toe!
   
   Follow the instructions on screen to play!
   
   <img width="820" height="228" alt="Screenshot 2026-10-16 at 22 55 39" src="https://github.com/user-attachments/assets/322f8a30-cc2a-40cb-8a4c-be8368fb87b6" />







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

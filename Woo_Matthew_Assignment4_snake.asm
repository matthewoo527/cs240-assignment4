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

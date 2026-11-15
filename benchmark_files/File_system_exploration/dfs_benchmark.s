# File System DFS traversal - RV32I / Ripes
# Full traversal from node 0.
# explored_count, peak_frontier, traversal_order are stored in data memory.
.data
.align 2
node_count: .word 9
start_node: .word 0
adj_matrix:
    .byte 0, 1, 1, 1, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 1, 1, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 1, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 1, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 1
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0
visited: .byte 0,0,0,0,0,0,0,0,0
.align 2
# DFS uses a stack of (node, next-neighbour-index) frames.
node_stack: .word 0,0,0,0,0,0,0,0,0
next_stack: .word 0,0,0,0,0,0,0,0,0
traversal_order: .word 0,0,0,0,0,0,0,0,0
explored_count: .word 0
peak_frontier: .word 0

.text
.globl main
main:
    la s0, node_count
    lw s0, 0(s0)              # N
    la s1, start_node
    lw s1, 0(s1)              # source
    la s2, adj_matrix
    la s3, visited
    la s4, node_stack
    la s5, next_stack
    la s6, traversal_order
    li s7, 0                  # stack depth
    li s8, 0                  # explored count
    li s9, 0                  # peak stack depth

    # Push source frame (node, next neighbour = 0).
    slli t0, s7, 2
    add t1, s4, t0
    sw s1, 0(t1)
    add t1, s5, t0
    sw zero, 0(t1)
    addi s7, s7, 1
    li s9, 1
    add t0, s3, s1
    li t1, 1
    sb t1, 0(t0)
    sw s1, 0(s6)
    li s8, 1

dfs_loop:
    beqz s7, dfs_done
    addi t0, s7, -1
    slli t0, t0, 2
    add t1, s5, t0
    lw s10, 0(t1)             # next neighbour index
    bge s10, s0, dfs_pop

    # Advance this frame before possibly pushing a child.
    addi t2, s10, 1
    sw t2, 0(t1)
    add t1, s4, t0
    lw s11, 0(t1)             # current node

    # matrix[current][next], N=8 or N=9
    slli t0, s11, 3
    add t0, t0, s11
    add t0, s2, t0
    add t0, t0, s10
    lbu t1, 0(t0)
    beqz t1, dfs_loop
    add t2, s3, s10
    lbu t1, 0(t2)
    bnez t1, dfs_loop

    # Discover child: mark, record preorder, push new frame.
    li t1, 1
    sb t1, 0(t2)
    slli t0, s8, 2
    add t0, s6, t0
    sw s10, 0(t0)
    addi s8, s8, 1

    slli t0, s7, 2
    add t1, s4, t0
    sw s10, 0(t1)
    add t1, s5, t0
    sw zero, 0(t1)
    addi s7, s7, 1
    bge s9, s7, dfs_loop
    mv s9, s7
    jal zero, dfs_loop

dfs_pop:
    addi s7, s7, -1
    jal zero, dfs_loop

dfs_done:
    la t0, explored_count
    sw s8, 0(t0)
    la t0, peak_frontier
    sw s9, 0(t0)

    # Ripes environment call 10 terminates the program.
    li a7, 10
    ecall

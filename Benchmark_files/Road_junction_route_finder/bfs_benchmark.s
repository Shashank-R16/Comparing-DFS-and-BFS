# Road Junction BFS traversal - RV32I / Ripes
# Full traversal from node 0.
# explored_count, peak_frontier, traversal_order are stored in data memory.
.data
.align 2
node_count: .word 8
start_node: .word 0
adj_matrix:
    .byte 0, 1, 1, 0, 0, 0, 0, 0
    .byte 1, 0, 0, 1, 1, 0, 0, 0
    .byte 1, 0, 0, 0, 0, 0, 1, 1
    .byte 0, 1, 0, 0, 0, 1, 0, 0
    .byte 0, 1, 0, 0, 0, 1, 0, 0
    .byte 0, 0, 0, 1, 1, 0, 1, 0
    .byte 0, 0, 1, 0, 0, 1, 0, 0
    .byte 0, 0, 1, 0, 0, 0, 0, 0
visited: .byte 0,0,0,0,0,0,0,0
.align 2
frontier: .word 0,0,0,0,0,0,0,0
traversal_order: .word 0,0,0,0,0,0,0,0
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
    la s4, frontier
    la s5, traversal_order
    li s6, 0                  # head
    li s7, 0                  # tail
    li s8, 0                  # explored count
    li s9, 0                  # peak queue occupancy

    # Enqueue source and mark it visited.
    slli t0, s7, 2
    add t0, s4, t0
    sw s1, 0(t0)
    add t0, s3, s1
    li t1, 1
    sb t1, 0(t0)
    addi s7, s7, 1
    li s9, 1

bfs_loop:
    beq s6, s7, bfs_done
    slli t0, s6, 2
    add t0, s4, t0
    lw s10, 0(t0)             # current node
    addi s6, s6, 1

    # Record dequeue/visit order.
    slli t0, s8, 2
    add t0, s5, t0
    sw s10, 0(t0)
    addi s8, s8, 1

    li s11, 0                 # neighbour index
bfs_neighbour:
    bge s11, s0, bfs_loop
    # matrix[current][neighbour], N=8 or N=9
    slli t0, s10, 3
    add t0, s2, t0
    add t0, t0, s11
    lbu t1, 0(t0)
    beqz t1, bfs_next
    add t2, s3, s11
    lbu t1, 0(t2)
    bnez t1, bfs_next

    # Mark when enqueued so each vertex enters once.
    li t1, 1
    sb t1, 0(t2)
    slli t0, s7, 2
    add t0, s4, t0
    sw s11, 0(t0)
    addi s7, s7, 1
    sub t0, s7, s6
    bge s9, t0, bfs_next
    mv s9, t0
bfs_next:
    addi s11, s11, 1
    jal zero, bfs_neighbour

bfs_done:
    la t0, explored_count
    sw s8, 0(t0)
    la t0, peak_frontier
    sw s9, 0(t0)

    # Ripes environment call 10 terminates the program.
    li a7, 10
    ecall

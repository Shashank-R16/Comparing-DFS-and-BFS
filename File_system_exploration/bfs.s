.data
.align 2

# --------------------------------------------------
# Basic configuration
# --------------------------------------------------
node_count: .word 9
root_node:  .word 0
dest_node:  .word 8             # Destination node ID to navigate to (e.g., 8 = main.c)

# --------------------------------------------------
# Node IDs:
# 0 = root
# 1 = documents
# 2 = pictures
# 3 = music
# 4 = report.txt
# 5 = projects
# 6 = photo.jpg
# 7 = song.mp3
# 8 = main.c
#
# Node type: 1 = directory, 0 = file
# --------------------------------------------------
node_type:
    .word 1, 1, 1, 1, 0, 1, 0, 0, 0

# --------------------------------------------------
# Directed adjacency matrix
#
# adjacency[parent][child] = 1:
#     parent contains child
#
# Rows and columns use node IDs 0 through 8.
# Every entry is one 4-byte word.
# --------------------------------------------------
adjacency:
    #     0  1  2  3  4  5  6  7  8
    .word 0, 1, 1, 1, 0, 0, 0, 0, 0  # 0: root
    .word 0, 0, 0, 0, 1, 1, 0, 0, 0  # 1: documents
    .word 0, 0, 0, 0, 0, 0, 1, 0, 0  # 2: pictures
    .word 0, 0, 0, 0, 0, 0, 0, 1, 0  # 3: music
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0  # 4: report.txt
    .word 0, 0, 0, 0, 0, 0, 0, 0, 1  # 5: projects
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0  # 6: photo.jpg
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0  # 7: song.mp3
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0  # 8: main.c

# --------------------------------------------------
# Working memory: one word per node
# Separate buffers make the two runs easy to inspect.
# --------------------------------------------------
dfs_visited:
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0

bfs_visited:
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0

dfs_order:
    .word -1, -1, -1, -1, -1, -1, -1, -1, -1

bfs_order:
    .word -1, -1, -1, -1, -1, -1, -1, -1, -1

dfs_stack:
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0

bfs_queue:
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0

dfs_count:      .word 0
bfs_count:      .word 0
dfs_dest_found: .word 0         # 1 if dest_node was reached in DFS, 0 otherwise
bfs_dest_found: .word 0         # 1 if dest_node was reached in BFS, 0 otherwise

# --------------------------------------------------
# Formatted Console Output Strings
# --------------------------------------------------
str_banner:     .asciz "========================================\n   BFS FILE SYSTEM TRAVERSAL & SEARCH\n========================================\n"
str_root_lbl:   .asciz "Start (Root) Node : "
str_dest_lbl:   .asciz "\nDestination Node  : "
str_tbl_hdr:    .asciz "\n----------------------------------------\nStep | Node ID | Type\n----------------------------------------\n"
str_row_prefix: .asciz "  "
str_col_sep1:   .asciz "  |    "
str_col_sep2:   .asciz "    | "
str_dir:        .asciz "[DIR]"
str_file:       .asciz "[FILE]"
str_reached:    .asciz "  <-- DESTINATION REACHED!\n"
str_found_msg:  .asciz "----------------------------------------\nStatus            : DESTINATION FOUND\n"
str_notfnd_msg: .asciz "----------------------------------------\nStatus            : DESTINATION NOT FOUND\n"
str_count_lbl:  .asciz "Nodes Visited     : "
str_order_lbl:  .asciz "\nNavigation Path   : "
str_arrow:      .asciz " -> "
str_footer:     .asciz "\n========================================\n"

.text
.globl main

# ==================================================
# Breadth-First Search (BFS) File System Traversal
# Navigates from root_node to dest_node using bfs_queue
# ==================================================
main:
    # --- Load configuration and base addresses ---
    la   t0, node_count
    lw   s0, 0(t0)              # s0 = node_count (9)
    la   t0, root_node
    lw   s1, 0(t0)              # s1 = root_node (0)
    la   t0, dest_node
    lw   s9, 0(t0)              # s9 = dest_node (8)
    la   s2, adjacency          # s2 = base address of adjacency matrix
    la   s3, bfs_visited        # s3 = base address of bfs_visited
    la   s4, bfs_order          # s4 = base address of bfs_order
    la   s5, bfs_queue          # s5 = base address of bfs_queue
    la   s6, node_type          # s6 = base address of node_type

    # --- Print Console Header ---
    la   a0, str_banner
    li   a7, 4
    ecall

    la   a0, str_root_lbl
    li   a7, 4
    ecall
    addi a0, s1, 0
    li   a7, 1
    ecall

    la   a0, str_dest_lbl
    li   a7, 4
    ecall
    addi a0, s9, 0
    li   a7, 1
    ecall

    la   a0, str_tbl_hdr
    li   a7, 4
    ecall

    # --- Initialize queue pointers and visit counter ---
    li   t0, 0                  # t0 = q_head (front dequeue index)
    li   t1, 0                  # t1 = q_tail (rear enqueue index)
    li   s8, 0                  # s8 = visit_count (number of nodes visited so far)

    # --- Enqueue root_node into bfs_queue and mark visited ---
    slli t2, s1, 2              # t2 = root_node * 4 (byte offset)
    add  t3, s3, t2             # t3 = &bfs_visited[root_node]
    li   t4, 1
    sw   t4, 0(t3)              # bfs_visited[root_node] = 1

    sw   s1, 0(s5)              # bfs_queue[0] = root_node
    addi t1, t1, 1              # q_tail = 1

bfs_loop:
    bge  t0, t1, bfs_not_found  # if (q_head >= q_tail) queue exhausted before dest_node

    # --- Dequeue front node u from bfs_queue (FIFO) ---
    slli t2, t0, 2              # t2 = q_head * 4
    add  t3, s5, t2             # t3 = &bfs_queue[q_head]
    lw   s7, 0(t3)              # s7 = u = bfs_queue[q_head]
    addi t0, t0, 1              # q_head++

    # --- Record u in bfs_order[visit_count] ---
    slli t2, s8, 2              # t2 = visit_count * 4
    add  t3, s4, t2             # t3 = &bfs_order[visit_count]
    sw   s7, 0(t3)              # bfs_order[visit_count] = u
    addi s8, s8, 1              # visit_count++

    # --- Load node_type[u] (1 = DIR, 0 = FILE) ---
    slli t2, s7, 2              # t2 = u * 4
    add  t3, s6, t2             # t3 = &node_type[u]
    lw   t4, 0(t3)              # t4 = node_type[u]

    # --- Print formatted table row for current step ---
    la   a0, str_row_prefix
    li   a7, 4
    ecall
    addi a0, s8, 0              # print step number (visit_count)
    li   a7, 1
    ecall

    la   a0, str_col_sep1
    li   a7, 4
    ecall
    addi a0, s7, 0              # print visited node ID (u)
    li   a7, 1
    ecall

    la   a0, str_col_sep2
    li   a7, 4
    ecall
    beq  t4, x0, bfs_print_file
    la   a0, str_dir
    li   a7, 4
    ecall
    jal  x0, bfs_check_dest

bfs_print_file:
    la   a0, str_file
    li   a7, 4
    ecall

bfs_check_dest:
    # --- Check if current node u is dest_node ---
    beq  s7, s9, bfs_found      # if (u == dest_node) destination reached!

    # --- Print newline for non-destination step ---
    li   a0, 10                 # '\n'
    li   a7, 11
    ecall

    # --- Skip child scan if u is a file (node_type[u] == 0) ---
    beq  t4, x0, bfs_loop

    # --- Compute row address &adjacency[u][0] without mul ---
    # u * 9 = (u << 3) + u
    slli t2, s7, 3              # t2 = u * 8
    add  t2, t2, s7             # t2 = u * 9 (word offset of row u)
    slli t2, t2, 2              # t2 = (u * 9) * 4 (byte offset of row u)
    add  t5, s2, t2             # t5 = &adjacency[u][0]

    # --- Scan children v from 0 up to node_count - 1 (8) ---
    li   t6, 0                  # t6 = v = 0

bfs_child_loop:
    bge  t6, s0, bfs_loop       # if (v >= node_count) finished scanning row u

    slli t2, t6, 2              # t2 = v * 4 (byte offset for column v)
    add  t3, t5, t2             # t3 = &adjacency[u][v]
    lw   t4, 0(t3)              # t4 = adjacency[u][v]
    beq  t4, x0, bfs_next_child # if (adjacency[u][v] == 0) not a child

    # --- Check if child v is already visited ---
    add  t3, s3, t2             # t3 = &bfs_visited[v]
    lw   t4, 0(t3)              # t4 = bfs_visited[v]
    bne  t4, x0, bfs_next_child # if (bfs_visited[v] != 0) skip

    # --- Mark child v visited and enqueue into bfs_queue ---
    li   t4, 1
    sw   t4, 0(t3)              # bfs_visited[v] = 1

    slli t2, t1, 2              # t2 = q_tail * 4
    add  t3, s5, t2             # t3 = &bfs_queue[q_tail]
    sw   t6, 0(t3)              # bfs_queue[q_tail] = v
    addi t1, t1, 1              # q_tail++

bfs_next_child:
    addi t6, t6, 1              # v++
    jal  x0, bfs_child_loop

bfs_found:
    la   t2, bfs_dest_found
    li   t3, 1
    sw   t3, 0(t2)              # bfs_dest_found = 1

    la   a0, str_reached
    li   a7, 4
    ecall

    la   a0, str_found_msg
    li   a7, 4
    ecall
    jal  x0, bfs_summary

bfs_not_found:
    la   a0, str_notfnd_msg
    li   a7, 4
    ecall

bfs_summary:
    # --- Store total visited count into bfs_count ---
    la   t2, bfs_count
    sw   s8, 0(t2)              # bfs_count = visit_count

    # --- Print total nodes visited ---
    la   a0, str_count_lbl
    li   a7, 4
    ecall
    addi a0, s8, 0
    li   a7, 1
    ecall

    # --- Print navigation path from bfs_order[0 .. visit_count-1] ---
    la   a0, str_order_lbl
    li   a7, 4
    ecall

    li   t2, 0                  # t2 = loop index i = 0
bfs_path_loop:
    bge  t2, s8, bfs_exit
    beq  t2, x0, bfs_print_node
    la   a0, str_arrow
    li   a7, 4
    ecall

bfs_print_node:
    slli t3, t2, 2
    add  t3, s4, t3             # t3 = &bfs_order[i]
    lw   a0, 0(t3)              # a0 = bfs_order[i]
    li   a7, 1
    ecall
    addi t2, t2, 1
    jal  x0, bfs_path_loop

bfs_exit:
    la   a0, str_footer
    li   a7, 4
    ecall

    li   a7, 10                 # ecall 10: exit program
    ecall
    

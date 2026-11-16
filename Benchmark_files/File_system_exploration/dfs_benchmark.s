# =====================================================================
#  DFS - File system exploration - pure algorithm (no console I/O)
#  Derived from Console_files/File_system_exploration/dfs_console.s
#  Console output removed; results are left in data memory. RV32I / Ripes.
# =====================================================================
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
# --------------------------------------------------
dfs_visited:
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0

dfs_order:
    .word -1, -1, -1, -1, -1, -1, -1, -1, -1

dfs_stack:
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0

dfs_count:      .word 0         # RESULT: nodes visited
dfs_dest_found: .word 0         # RESULT: 1 if dest_node was reached

.text
.globl main

# ==================================================
# Depth-First Search (DFS) File System Traversal
# Navigates from root_node to dest_node using dfs_stack
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
    la   s3, dfs_visited        # s3 = base address of dfs_visited
    la   s4, dfs_order          # s4 = base address of dfs_order
    la   s5, dfs_stack          # s5 = base address of dfs_stack
    la   s6, node_type          # s6 = base address of node_type

    # --- Initialize stack pointer and visit counter ---
    li   t0, 0                  # t0 = stack_top (number of elements on dfs_stack)
    li   t1, 0                  # t1 = visit_count (number of nodes visited so far)

    # --- Push root_node onto dfs_stack and mark visited ---
    slli t2, s1, 2              # t2 = root_node * 4 (byte offset)
    add  t3, s3, t2             # t3 = &dfs_visited[root_node]
    li   t4, 1
    sw   t4, 0(t3)              # dfs_visited[root_node] = 1

    sw   s1, 0(s5)              # dfs_stack[0] = root_node
    addi t0, t0, 1              # stack_top = 1

dfs_loop:
    beq  t0, x0, dfs_not_found  # if (stack_top == 0) stack exhausted before dest_node

    # --- Pop top node u from dfs_stack (LIFO) ---
    addi t0, t0, -1             # stack_top--
    slli t2, t0, 2              # t2 = stack_top * 4
    add  t3, s5, t2             # t3 = &dfs_stack[stack_top]
    lw   s7, 0(t3)              # s7 = u = dfs_stack[stack_top]

    # --- Record u in dfs_order[visit_count] ---
    slli t2, t1, 2              # t2 = visit_count * 4
    add  t3, s4, t2             # t3 = &dfs_order[visit_count]
    sw   s7, 0(t3)              # dfs_order[visit_count] = u
    addi t1, t1, 1              # visit_count++

    # --- Load node_type[u] (1 = DIR, 0 = FILE) ---
    slli t2, s7, 2              # t2 = u * 4
    add  t3, s6, t2             # t3 = &node_type[u]
    lw   t4, 0(t3)              # t4 = node_type[u]

dfs_check_dest:
    # --- Check if current node u is dest_node ---
    beq  s7, s9, dfs_found      # if (u == dest_node) destination reached!

    # --- Skip child scan if u is a file (node_type[u] == 0) ---
    beq  t4, x0, dfs_loop

    # --- Compute row address &adjacency[u][0] without mul ---
    # u * 9 = (u << 3) + u
    slli t2, s7, 3              # t2 = u * 8
    add  t2, t2, s7             # t2 = u * 9 (word offset of row u)
    slli t2, t2, 2              # t2 = (u * 9) * 4 (byte offset of row u)
    add  t5, s2, t2             # t5 = &adjacency[u][0]

    # --- Scan children v from node_count - 1 (8) down to 0 ---
    addi t6, s0, -1             # t6 = v = node_count - 1 (8)

dfs_child_loop:
    blt  t6, x0, dfs_loop       # if (v < 0) finished scanning row u

    slli t2, t6, 2              # t2 = v * 4 (byte offset for column v)
    add  t3, t5, t2             # t3 = &adjacency[u][v]
    lw   t4, 0(t3)              # t4 = adjacency[u][v]
    beq  t4, x0, dfs_next_child # if (adjacency[u][v] == 0) not a child

    # --- Check if child v is already visited ---
    add  t3, s3, t2             # t3 = &dfs_visited[v]
    lw   t4, 0(t3)              # t4 = dfs_visited[v]
    bne  t4, x0, dfs_next_child # if (dfs_visited[v] != 0) skip

    # --- Mark child v visited and push onto dfs_stack ---
    li   t4, 1
    sw   t4, 0(t3)              # dfs_visited[v] = 1

    slli t2, t0, 2              # t2 = stack_top * 4
    add  t3, s5, t2             # t3 = &dfs_stack[stack_top]
    sw   t6, 0(t3)              # dfs_stack[stack_top] = v
    addi t0, t0, 1              # stack_top++

dfs_next_child:
    addi t6, t6, -1             # v--
    jal  x0, dfs_child_loop

dfs_found:
    la   t2, dfs_dest_found
    li   t3, 1
    sw   t3, 0(t2)              # dfs_dest_found = 1   (destination reached)

dfs_not_found:                  # reached when the frontier empties (branch target kept)
dfs_exit:
    la   t2, dfs_count
    sw   t1, 0(t2)              # dfs_count = nodes visited
    li   a7, 10                 # exit program
    ecall

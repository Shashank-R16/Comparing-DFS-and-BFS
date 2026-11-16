# =====================================================================
#  BFS - Road junction route finder - pure algorithm (no console I/O)
#  Derived from Console_files/Road_junction_route_finder/bfs_console.s
#  Console output removed; results are left in data memory. RV32I / Ripes.
# =====================================================================
.data
num_nodes:      .word 8             # junctions J0..J7
start_node:     .word 0             # SOURCE junction
goal_node:      .word 6             # DESTINATION junction to navigate to

dest_found:     .word 0             # 1 = destination reached
explored_cnt:   .word 0             # junctions explored
path_len:       .word 0             # roads in the route
peak_size:      .word 0             # peak queue occupancy
path_nodes:     .word 0             # junctions on the route

queue_stack:    .word 0,0,0,0,0,0,0,0       # queue (FIFO for BFS)

#               J0 J1 J2 J3 J4 J5 J6 J7
adj_matrix:
        .byte 0, 1, 1, 0, 0, 0, 0, 0       # J0
        .byte 1, 0, 0, 1, 1, 0, 0, 0       # J1
        .byte 1, 0, 0, 0, 0, 0, 1, 1       # J2
        .byte 0, 1, 0, 0, 0, 1, 0, 0       # J3
        .byte 0, 1, 0, 0, 0, 1, 0, 0       # J4
        .byte 0, 0, 0, 1, 1, 0, 1, 0       # J5
        .byte 0, 0, 1, 0, 0, 1, 0, 0       # J6
        .byte 0, 0, 1, 0, 0, 0, 0, 0       # J7

visited:        .byte 0,0,0,0,0,0,0,0
parent:         .byte -1,-1,-1,-1,-1,-1,-1,-1
path_out:       .byte 0,0,0,0,0,0,0,0

        .text
main:
# ---- parameters and base addresses ---------------------------------
        la   t0, num_nodes
        lw   s0, 0(t0)
        la   t0, start_node
        lw   s1, 0(t0)
        la   t0, goal_node
        lw   s2, 0(t0)                  # s2 = destination
        la   s7, adj_matrix
        la   s8, visited
        la   s9, parent
        la   s10, queue_stack
        la   s11, path_out

# ---- clear work arrays and counters --------------------------------
        li   t0, 0
clr:    bge  t0, s0, clr_done
        add  t1, s8, t0
        sb   zero, 0(t1)                # visited[i] = 0
        add  t1, s9, t0
        li   t2, -1
        sb   t2, 0(t1)                  # parent[i] = -1
        add  t1, s11, t0
        sb   zero, 0(t1)                # path_out[i] = 0
        addi t0, t0, 1
        j    clr
clr_done:
        la   t0, dest_found
        sw   zero, 0(t0)
        la   t0, path_len
        sw   zero, 0(t0)
        la   t0, peak_size
        sw   zero, 0(t0)
        la   t0, path_nodes
        sw   zero, 0(t0)

# ---- BFS init: enqueue the source ----------------------------------
        li   s3, 0                      # head
        li   s4, 0                      # tail
        li   s5, 0                      # explored
        li   s6, 0                      # peak
        add  t1, s8, s1
        li   t2, 1
        sb   t2, 0(t1)                  # visited[source] = 1
        sw   s1, 0(s10)                 # queue[0] = source
        addi s4, s4, 1                  # tail++
        li   s6, 1                      # peak = 1

# ---- BFS loop ------------------------------------------------------
bfs:    beq  s3, s4, report             # queue empty -> no route
        slli t3, s3, 2
        add  t3, s10, t3
        lw   t4, 0(t3)                  # u = queue[head++]
        addi s3, s3, 1
        addi s5, s5, 1                  # explored++
        beq  t4, s2, found              # destination reached?

        li   t5, 0                      # v = 0
nb:     bge  t5, s0, bfs
        slli t0, t4, 3                  # u*8  (row stride = 8 junctions)
        add  t0, t0, t5
        add  t0, s7, t0
        lbu  t1, 0(t0)                  # adj[u][v]
        beq  t1, zero, nb_next
        add  t2, s8, t5
        lbu  t3, 0(t2)
        bne  t3, zero, nb_next          # already visited
        li   t3, 1
        sb   t3, 0(t2)                  # visited[v] = 1
        add  t3, s9, t5
        sb   t4, 0(t3)                  # parent[v] = u
        slli t3, s4, 2
        add  t3, s10, t3
        sw   t5, 0(t3)                  # queue[tail++] = v
        addi s4, s4, 1
        sub  t3, s4, s3                 # occupancy = tail - head
        bge  s6, t3, nb_next
        mv   s6, t3                     # peak = max(peak, occupancy)
nb_next:
        addi t5, t5, 1
        j    nb

# ---- route found: rebuild it through parent[] ----------------------
found:  li   t0, 1
        la   t1, dest_found
        sw   t0, 0(t1)                  # dest_found = 1

        li   t0, 0                      # count junctions
        mv   t1, s2
cnt:    blt  t1, zero, cnt_done
        addi t0, t0, 1
        add  t2, s9, t1
        lb   t1, 0(t2)                  # cur = parent[cur]
        j    cnt
cnt_done:
        la   t2, path_nodes
        sw   t0, 0(t2)                  # path_nodes = count
        addi t2, t0, -1
        la   t3, path_len
        sw   t2, 0(t3)                  # path_len = count - 1

        addi t3, t0, -1                 # fill path_out[] source -> goal
        mv   t1, s2
fill:   blt  t1, zero, report
        add  t2, s11, t3
        sb   t1, 0(t2)
        addi t3, t3, -1
        add  t2, s9, t1
        lb   t1, 0(t2)
        j    fill

# ---- publish results and terminate ---------------------------------
report:
        la   t0, explored_cnt
        sw   s5, 0(t0)                  # RESULT: junctions explored
        la   t0, peak_size
        sw   s6, 0(t0)                  # RESULT: peak frontier size
        li   a7, 10                     # exit program
        ecall

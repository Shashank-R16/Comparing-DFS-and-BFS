# =====================================================================
#  DFS ROUTE FINDER - road junction network (J0..J7) - Ripes (RV32I)
#  Stack based, so the route found is FEASIBLE but not necessarily the
#  shortest. Neighbours are pushed highest first, so they pop in the
#  natural order J0, J1, J2 ...
#
#  Change the query by editing start_node / goal_node only.
#  Ripes ecalls: a7=4 print string, a7=1 print int, a7=10 exit
#
#  Registers: s0=N  s1=source  s2=destination  s4=stack top
#             s5=explored  s6=peak  s7=&adj  s8=&visited  s9=&parent
#             s10=&stack  s11=&path_out     t4=current junction u
# =====================================================================
        .data
num_nodes:      .word 8             # junctions J0..J7
start_node:     .word 0             # SOURCE junction
goal_node:      .word 6             # DESTINATION junction to navigate to

dest_found:     .word 0             # 1 = destination reached
explored_cnt:   .word 0             # junctions explored
path_len:       .word 0             # roads in the route
peak_size:      .word 0             # peak stack occupancy
path_nodes:     .word 0             # junctions on the route

queue_stack:    .word 0,0,0,0,0,0,0,0       # stack (LIFO for DFS)

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

s_rule:     .string "-------------------------------------------------------------\n"
s_hdr:      .string " RESULT\n"
s_yes:      .string "   Destination reached  : YES\n"
s_no:       .string "   Destination reached  : NO  (no route exists)\n"
s_route:    .string "   Route (DFS order)    : "
s_noroute:  .string "   Route                : none\n"
s_roads:    .string "   Roads in route       : "
s_expl:     .string "   Junctions explored   : "
s_peak:     .string "   Peak stack size      : "
s_arrow:    .string " -> "
s_nl:       .string "\n"

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

# ---- DFS init: push the source -------------------------------------
        li   s4, 0                      # stack top (= stack size)
        li   s5, 0                      # explored
        li   s6, 0                      # peak
        add  t1, s8, s1
        li   t2, 1
        sb   t2, 0(t1)                  # visited[source] = 1
        sw   s1, 0(s10)                 # stack[0] = source
        addi s4, s4, 1                  # top++
        li   s6, 1                      # peak = 1

# ---- DFS loop ------------------------------------------------------
dfs:    beq  s4, zero, report            # stack empty -> no route
        addi s4, s4, -1                 # POP
        slli t3, s4, 2
        add  t3, s10, t3
        lw   t4, 0(t3)                  # u = stack[top]
        addi s5, s5, 1                  # explored++
        beq  t4, s2, found              # destination reached?

        addi t5, s0, -1                 # v = N-1 downwards
nb:     blt  t5, zero, dfs
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
        sw   t5, 0(t3)                  # PUSH v
        addi s4, s4, 1
        bge  s6, s4, nb_next
        mv   s6, s4                     # peak = max(peak, stack size)
nb_next:
        addi t5, t5, -1
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

# ---- print the result block ---------------------------------------
report:
        la   t0, explored_cnt
        sw   s5, 0(t0)
        la   t0, peak_size
        sw   s6, 0(t0)

        la   a0, s_rule
        jal  ra, print_str
        la   a0, s_hdr
        jal  ra, print_str

        la   t0, dest_found
        lw   t1, 0(t0)
        beq  t1, zero, no_route

        la   a0, s_yes
        jal  ra, print_str
        la   a0, s_route
        jal  ra, print_str
        li   t0, 0
p_loop: la   t1, path_nodes
        lw   t1, 0(t1)
        bge  t0, t1, p_done
        beq  t0, zero, p_noarrow
        la   a0, s_arrow
        jal  ra, print_str
p_noarrow:
        add  t2, s11, t0
        lbu  a0, 0(t2)
        jal  ra, print_j                # J<n>
        addi t0, t0, 1
        j    p_loop
p_done: la   a0, s_nl
        jal  ra, print_str
        j    stats

no_route:
        la   a0, s_no
        jal  ra, print_str
        la   a0, s_noroute
        jal  ra, print_str

stats:  la   a0, s_roads
        jal  ra, print_str
        la   t0, path_len
        lw   a0, 0(t0)
        jal  ra, print_int
        la   a0, s_nl
        jal  ra, print_str

        la   a0, s_expl
        jal  ra, print_str
        mv   a0, s5
        jal  ra, print_int
        la   a0, s_nl
        jal  ra, print_str

        la   a0, s_peak
        jal  ra, print_str
        mv   a0, s6
        jal  ra, print_int
        la   a0, s_nl
        jal  ra, print_str

        li   a7, 10                     # exit
        ecall

# ---- helpers (only a0 / a2 / a7 are clobbered) --------------------
print_str:
        li   a7, 4
        ecall
        ret
print_int:
        li   a7, 1
        ecall
        ret
print_j:                                # a0 = index -> "J<n>"
        mv   a2, a0
        li   a0, 74
        li   a7, 11
        ecall
        mv   a0, a2
        li   a7, 1
        ecall
        ret

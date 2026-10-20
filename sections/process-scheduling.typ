#import "../improts.typ":*

= Process Scheduling
*Two dimensions* of scheduling on WSC OS:
- *Which* process to run next
- *Where* must the process run
  - On which *Processing Element (PE)*: which Computer, which CPU

*Two Scheduling Approaches*
- Time-sharing: Processes run on the *same PE* by doing recurrent context switching
- Space-sharing: PEs are partitioned among multiple processes that execute side-by-side

*Job*
- A job is an application in execution, consists of *multiple* concurrent *processes/threads*.
- it is the *unit of scheduling* defined by
  - *Arrival time*
  - *Number of required PEs* (i.e. number of threads/processes), aka Job width, Job size
  - *Runtime estimation*, aka Job Length
- Classification
  - Number of processes
    - Serial
    - Parallel
  - Interaction with the user
    - Interactive: Immediate response, I/O redirected to a terminal. require *fast turnaround time*
    - Batch: Submitted to a queue to be scheduled, run when resources available
  - Capacity to adjust the number of processes/threads
    - Rigid: \#PEs *predefined*
    - Moldable: \#PEs determined *at start time*, cannot change after
    - Evolving: \#PEs change *at runtime* on its *own initiative*, request scheduler for PEs
    - Malleable: \#PEs change *at runtime* according to *availability of PEs* from the scheduler

== Scheduler Architecture
=== Monolithic Scheduler
Handles *all the jobs* using the *same logic*
- $arrow.t$ *Up-to-date global view* of the whole cluster
  - better scheduling decisions
  - easy to enforcing constraints
- $arrow.b$ Slow scheduling
- $arrow.b$ hard to handle *mixed workloads* 
  - interactive jobs
  - Queuing effects (head-of-line blocking)

=== Two-level scheduler
A *central resource manager* partitions cluster dynamically among *multiple independent* workload-specific *schedulers*. (Each schedulers make actual task placement)
- $arrow.t$ Placement tailored for specific workloads
- $arrow.t$ Better scalability (mitigate load on the scheduler)
- $arrow.b$ Limited cluster view
  - Hard to enforce global constraints
  - Hard to detect interference

=== Shared-state Scheduler
*Multiple* workload-specific schedulers have access to the *entire cluster*

Cluster state is *replicated* and can be independently updated by schedulers using *optimistic concurrency control* (abort/retry update if there are conflicting changes)

- $arrow.t$ Fast scheduling, good scalability
- $arrow.t$ Placement logic can be tailored to specific workloads
- $arrow.b$ Needs to decide with (occasionally) stale information (update is visible only after commit, update propagation takes time)
- $arrow.b$ Degraded performance under high contention

=== Fully Distributed Scheduler
Multiple independent schedulers serve incoming workloads *without any coordination* between them.\
Use only their *local*, *partial* and often *outdated* *view* of the cluster
- Jobs are submitted to *any* scheduler
- $arrow.t$ Fast scheduling, high throughput, high scalability
- $arrow.b$ Bad scheduling decisions, hard to enforce global constraints, hard to detect interference
  - More suitable for *short-running* jobs where the effect of bad decisions don't accumulate overtime

=== Hybrid Scheduler
Combines *fully-distributed* scheduler with *Monolithic* scheduler

*Two Scheduling Paths*
- Short jobs: Fully-distributed scheduler
- Long jobs: Centralised scheduler

$arrow.t$ Useful for heterogeneous workloads

== Time-sharing
- Multiple processes run on the *same PE* by doing recurrent context switching
- Processes can be *preempted* by others during execution and restart later
- $arrow.t$ Increase utilisation of PEs
- $arrow.b$ Overhead of context switches

=== Single Global Queue
Put all jobs that need to be schedules into a single global queue
- $arrow.t$ Simplicity
- $arrow.t$ Automatic load balance: workload distributed across all PEs by construction
- $arrow.b$ Does NOT preserve *data locality*
- $arrow.b$ Hard to implemented (distributed) global queue (without shared memory)
- $arrow.b$ Synchronisation needed, low scalability

#figure(
  image("../slides/3a-process-scheduling.pdf", page: 22, width: 60%),
)

=== Affinity Scheduling
Scheduling process *on the same PE* it used before
- Soft affinity: is possible
- Hard affinity: necessary

#figure(
  image("../slides/3a-process-scheduling.pdf", page: 23, width: 60%),
)

=== Local Queues
Independent queues for each PE
#figure(
  image("../slides/3a-process-scheduling.pdf", page: 25, width: 60%)
)

=== Load Balancing
Balance by migrating active processes between PEs\
Types
- Receiver-initiated (Work stealing): idle PEs steal process from overloaded PEs
- Sender-initiated (Work pushing): overloaded PEs offload processes to underloaded or idle PEs

$arrow.t$: Better load distribution
$arrow.b$ Communication and processing overhead
$arrow.b$ Does not preserve data locality

== Space-sharing
PEs are partitioned among multiple processes that execute side-by-side
- Normally, one process per PE, but we could combine time-sharing to schedule multiple processes a PE
- Jobs run side-by-side until completion
Advantages and disadvantages
- $arrow.t$ Partition is dedicated to a job
- $arrow.t$ Avoids context switch
- $arrow.b$ Interconnects and I/Os may be shared by several jobs
- $arrow.b$ Poor utilisation: wasted when a process *block*\s

=== Partitioning Mechanisms
- *Fixed Partitioning*
  - Partitions are set by the administrator
    - typically by using queues for different sizes and limits (\#PEs, execution time etc)
  - Partitions can be modified *only by rebooting*
  - $arrow.t$ Simple, preserves data locality
  - $arrow.b$ Arbitrary queuing
  - $arrow.b$ Internal fragmentation (unused PEs within a partition)
- *Variable Partitioning*
  - Partition size is set at *submission time* (of jobs)
  - Partition size is based on incoming *job request* (specified by the job)
  - Partition size does not change during job runtime
  - $arrow.t$ Matching job request, preserves data locality
  - $arrow.b$ Arbitrary queuing
  - $arrow.b$ External fragmentation (PEs not allocated to any partition)
  - $arrow.b$ Internal fragmentation *if* the architecture imposes restrictions to the partition size
- *Adaptive Partitioning*
  - *Requirement*: *Moldable Jobs* (determine \# of processes at *start time*)
  - Partition size is set when the *job starts*
  - Partition size is *based on system load* (specified by the system, taking into account job request)
  - Partition size does not change during job execution
- *Dynamic Partitioning*
  - *Requirement*: *Mellable Jobs* (change PEs *at runtime* according to the availability of PEs in the system)
  - Partition size can change *during job execution* to respond to load changes
  
=== Variable Partitioning Scheduling Policies
- Jobs are queued *until sufficient PEs* become available
- Alternatively, Combine with time-sharing to schedule multiple jobs within a partition
#figure(
  image("../slides/3a-process-scheduling.pdf", page:36, width: 60%),
)
==== First Come First Serve (FCFS)
- Activation time: Job arrival and termination
- $arrow.t$ Fiarness
- $arrow.b$ External fragmentation: first job blocks the rest of the queue
#figure(
  kind: "algorithm",
  supplement: [Algorithm],

  pseudocode-list(booktabs: true, numbered-title: [
    FCFS()
  ])[
    + job $<-$ Queue.head
    + *if* (availablePEs $>=$ job.requiredPEs *then*
      + Start(Queue, job);
    + *else*
      + Wait;
    + *end*
  ]
)

=== Backfilling
Backfill jobs that *arrive later* to the head of the queue (*fill holes*)
- Reduce fragmentation of *breaking FCFS order*
- Restriction: Backfilled jobs *cannot* delay reserved jobs (defines N reserved jobs)
- Activation time: Job arrival and termination
- Requires job runtime estimation and required PEs
==== EASY Backfilling (Earliest Arrival Start-time Yield)
- Only *ONE* reserved jobs
  - Guarantees the first job does not get delayed, but the second job may get delayed
- *Shadow time*: expected *start time* of the first job (in the queue)
  - In exams, this would mean that the first schedule-able time of the job (because the user didn't specify it) 
- *Extra PEs*: Available PEs when the first queued job starts
- Notes
  - Limited Vision
    - On each invocation, it only make decisions for *the current time*
    - The algorithm is invoked *whenever a job finishes* or *arrives*
  - Runtime Estimation
    - typically, jobs are killed if it takes longer than estimated (avoid delaying other jobs)
    - Aggressive Estimation: goes through the queue faster but may be killed
    - Conservative Estimation: Harder to backfill, but will less likely to be killed
#figure(
  kind: "algorithm",
  supplement: [Algorithm],
  pseudocode-list(booktabs: true, numbered-title: [
    CanSchedule($S$: Schedule, $J$: Job)
  ])[
    *return* $S$.currentAvailablePEs $>=$ $J$.requiredPEs
  ]
)
#figure(
  kind: "algorithm",
  supplement: [Algorithm],
  pseudocode-list(booktabs: true, numbered-title: [
    EASY-Backfilling($S$: Schedule)
  ])[
    + *while* CanSchedule($S$, $Q[0]$)
      + $Q$.remove($Q[0]$);
      + Schedule($S$, $Q[0]$);
    + $J_r <- Q[0]$;
    + *for* i = 1..$|Q|$
      + $J_i <- Q[i]$;
      + *if* ($t$ + Runtime($J_i$) $<=$ ShadowTime($J_r$, $S$)) $or$ ($J_i$.NeededPEs $<=$ $J_r$.ExtraPEs)
        + *if* CanSchedule($S$, $J_i$)
          + $Q$.remove($J_i$)
          + $J_r$.ExtraPEs $<-$ $J_r$.ExtraPEs - $J_i$.NeededPEs;
          + Schedule($S$, $J_i$) 
  ]
)

*Variations*
- Order of queues
  - FCFS: EASY backfilling
  - Priorities: Slack-based backfilling
  - Shortest-estimated-runntime-first: SJF backfilling
- Number of reserved jobs
  - One: EASY backfilling
  - ALL: conservative backfilling
    - HOW DO WE RESERVE ALL JOBS AND CALCULATE THEIR SHADOW TIME?
    - Idea: Backfilled jobs *cannot* delay *ANY* jobs
  - adaptive: selective backfilling
    - only reserve jobs whose expected slowdown exceeds a threshold
- Look-ahead in the queue (\#jobs analysed simultaneously to backfill)
  - One job at a time
  - the whole queue at once (HOW? some policices?)

== Adaptive Partitioning Scheduling Policies
=== Equipartition (Adaptive)
Aim for equal-sized partitions for all jobs\
*Activation time*: job arrival/termination

Consider only *waiting jobs*
- Allocate *one PE* at a time for each waiting job
- *Run the job* when the allocated *PEs* reach its requirement
  - Then start over again with the new *waiting jobs* (excluding this job because it's scheduled)

=== Proportional Partitioning
Aim for PEs proportional to the request

$p_i = "totalPEs" dot "req"_i / (sum_(j=1)^N ("req"_j))$ (Do we round down or up?)

The following figure show the difference between *Equipartition* and *Proportional Partitioning*
#figure(
  image("../slides/3a-process-scheduling.pdf", page: 50),
)

== Dynamic Partitioning Scheduling Policies
=== Equipartition (Dynamic)
Aim for equal-sized partition for all jobs
*Activation time*: job arrival/termination, job requirement change

Consider *all jobs*
- Allocate *one PE* at a time for each job
- *Run the job* when the allocated *PEs* reach its requirement

Some PEs might be preempted from running jobs and given to other jobs\
PEs of a finished job are *equally* divided among ALL the other jobs

=== Efficiency Preservation (Hybrid)
#figure(image("../slides/3a-process-scheduling.pdf", page: 53))

Folding policy
- On job arrival
- *the largest* current partition is *folded in half* (half of the PEsare freed)
  - assume \#PEs = $2^n$
- Processes on each partition will *time-share* PEs

In the following figure, the x and y axis are combined to show spacial distribution of the PEs in a mash
#figure(image("../slides/3a-process-scheduling.pdf", page: 54))

== Gang Scheduling
Schedule all *processes* of *a parallel job* together (a scheduling unit)
- Processes in a job are grouped into a gang
- Processes in a gang execute *simultaneously* in *distinct PEs* (using a one-to-one mapping)
- Time-sharing between gangs, *all* processes within the same gang must be preempted and rescheduled at the same time
- $arrow.t$ Reduces intereactions between processes within the same gang ($P_1$ send messages to $P_2$)
- $arrow.b$ Overhead for context switch and coordination
- $arrow.b$ May have external fragmentation

Assignment
- A job is usually assigned to *contiguous PEs* to facilitate *slot unification* when job terminates
- A job is usually assigned to the same PEs to exploit data locality (affinity scheduling)

*Time Slot* (in a Ousterhout Matrix)\
a quanta (time slot) consists a row of available PEs at each time 
#figure(
  image("../slides/3a-process-scheduling.pdf", page: 65, width: 60%),
)

=== First Fit
- Used slots are scanned in sequential order
  - From $t=1, 2, 3...$ and at each time, from $"PE"=1, 2, ...$.
- The *first one* with sufficient capacity is chosen
- If current time slot (at $t$) has enough capacity, open *a new time slot* (at $t+1$)

In the following example, we can see that
- We choose to start from PE=8 when the current time slots of our job is even and start from PE=1 when it is odd
  - $t=1, 3, 5, ...$ is considered even and $t=2,4,6,...$ is considered odd
- We schedule jobs in order ($J_1,J_2, J_3, ...$)
  - When we want to schedule $J_3$ at $t=1$, we cannot find available slots, so we open a new time slot at $t=2$ and schedule $J_3$, since $J_3$ needs 4 time slots, it is schedule starting at PE=8
  - When we want to schedule $J_4$, we find it can be schedule at $t=1$ (sequential scan)

#figure(image("../exams/sol-final-20-Q1.pdf", page: 3))

=== Best Fit
- Used slots are sorted according to their free capacity (time slots, with multiple space(PE) "cells")
- One time slot with the smallest sufficient capability is chosen
- If none has enough space, a new time slot is created
=== Varients
==== Left-Right Packing variant (Lower Job Overlaps) 
Used to lower overlaps between jobs
  - start using PEs from left/right
    - In the exam (Jan 2021), we consider the index of TIME slots and even slots starts from PE=1 and odd slots starts from PE=8
    - $t=1, 3, 5, ...$ is considered even and $t=2,4,6,...$ is considered odd
    - It is NOT the duration of the job, but the current time slot $t$ in the scheduling
==== Alternative Scheduling (Schedule a Job Multiple Times if Has Space) 
Schedule a job in multiple slots if corresponding PEs are free
  - $arrow.t$ Reduce fragmentation
  - $arrow.b$ Unfair: some jobs may have more opportunity to run in the same period (and may terminate sooner)
==== Slot unification (Merge Slots) 
Merge slots in which jobs use complementary PEs
- $arrow.t$ Reduces fragmentation
- $arrow.b$ Increases run fraction of all jobs
= PE Allocation
Select a specific subset of PEs to use
== Contiguous Partitions
=== Rectangular Allocation
We are choosing the bottom left point as the anchor point, the reject area, and coverages are meant to use this bottom left point.  
#figure(image("../slides/3a-process-scheduling.pdf", page: 57, width: 60%))

=== Contiguous Leak
- Search for free PE ti act as origin using a "snake" wave
- Origin found: test all direct neighbours ($arrow.t$, $arrow.r$, $arrow.b$, $arrow.l$), add free neighbours to the partition
- Allocate recursively until needed PEs are allocated
- Origin cannot allocate enough PEs: try *next* free PE in the search wave as origin
- Fail when no more PEs are available
#figure(image("../slides/3a-process-scheduling.pdf", page: 59))


== Non-contiguous Partitions
- $arrow.t$ Reduced external fragmentation
- $arrow.t$ Better compatibility with dynamic partitioning
- $arrow.b$ Overhead due to increased latency and network connection

=== Non-contiguous Leak
Similar to Contiguous leak, but
- When a source cannot allocate enough PEs, we don't retry by finding a new origin, we just keep finding another origin while keeping the allocated PEs
#figure(image("../slides/3a-process-scheduling.pdf", page: 61))



== Scheduling Metrices
Used to quantify how good a schedule is

=== Wait Time
Time spent in the queue waiting to be schedule $T_W$

- Does NOT capture users' notion of responsiveness
  - Users expect jobs to take time that is *proportional to their length*
  - e.g. a 100s wait is acceptable to a 1s job
  - $->$ needs a term for the running running time of the job

=== Response Time (Turnaround Time, Flow)
Time elapsed from job *submission* until its *completion* (waiting time + running time)
$
  T_"response" = underbrace(T_W, "Waiting Time") + underbrace(T_R, "Runtime")
$

- Places greater emphasis on longer jobs
- Not effected to a short job waiting a few minutes (as long as $T_W + T_R$ is good)

=== Slowdown (Stretch)
$
  T_"slowdown" = overbrace((T_W + T_R), "Response Time") / underbrace(T_R, "Runtime, Normalisation Facotr")\
               = T_W/T_R + 1
$
- Quantifies loss of performance due to competition for PEs
- Captures the responsiveness better
- *Overemphasis* on *very short jobs* (the denominator is small hence the whole ratio is large)
  - *Bounded slowdown* Reduce the influence of short jobs
- Almost equivalent jobs may have very different slowdown
  - Almost Equivalent Jobs: SAME amount of work and SAME response time
  - $(J_1: T_W = 0s, T_R = 100s, N_"PEs"=1)$, $(J_2: T_W = 90s, T_R = 10s, N_"PEs"=10)$
    - $T_"response" = T_W + T_R = 100s$
    - $"Work" = T_R dot N_"PEs" = 100$
    - $(T_"slowdown")_1 = T_"response" / T_"R1" = 1$
    - $(T_"slowdown")_2 = T_"response" / T_"R2" = 10$
  - $=>$ *Per-processor slowdown*:
    - $(T_W + T_R) / (T_R dot N_"PEs")$

=== Bounded Slowdown  
Measure the slowdown relative to some $tau$ to reduce the influence of short jobs.\
$
  T = max((T_W + T_R) / max(T_R, tau), 1)
$

=== Per-processor Slowdown
Divide the slowdown by the number of PEs used (not the numerator's Runtime though).\
$
  T = (T_W + T_R) / (T_R dot N_"PEs") = T_"slowdown" / N_"PEs"
$

=== Expansion Factor (XFactor)
Pre-execution metric for job schedling, similar to the "Slowdown" but the duration is used as user-specified parameter
$"XFactor" = ("wait" + "duration") / "duration"$

Here, at time $t_x$, the new coming jobs always have $"XFactor"=1$ since $"wait"=0$
- We prioritise older jobs that arrive at $t_(y<x)$ by their arrival time, meassured by $"wait"=t_x - t_y$
- We prioritise short jobs measured by $"duration"$. We normalise the response time $"wait+duration"$ by $"duration"$
- We respect the job arrival order by using FCFS policy to break ties (jobs arriving at the same time $t$ have an order)

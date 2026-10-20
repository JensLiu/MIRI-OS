= Process Resilience
Requirements
- Reliability: How long can the system operate without failure
- Availability: Percentage of time that the system is available to the user
- Maintainability: How easily can a failed system be repaired

== Resilience Metrics
#figure(image("../slides/3a-process-scheduling.pdf", page: 81, width: 60%),)
=== Reliability: Mean Time to Failure (MTTF)
Average time until a component fails

=== Maintainability: Mean Time to Repair (MTTR)
average time needed to repair a component

=== Availability: Percentage of Time when Available
$
  A = "Available Time" / "Total Time" = "MTTF" / ("MTTF" + "MTTR")
$

== Fault Tolerance
Increase process resilience
- Increase MTTF
  - more reliable HW ($arrow.t$ cost)
  - bug-free SW (infeasible)
- Decrease MTTR
  - Redundancy: replicate HW and SW components to *mask failures* to the application
  - Recovery: correct execution is *eventually* restored

== Redundancy

=== Modular Redundancy
==== Double Modular Redundancy
Replicate process or modules
- in general, *$f+1$* replicas can tolerate *$f$* *crash* or *omission* failures
  - At least *one* replica can response
- Can *detect* Byzantine Failures (*CANNOT* tolerate) by comparing output of replicas

==== Triple Modular Redundancy
Output is decided through *majority*
- in general, *$2f+1$* replicas can tolerate up to $f$ Byzantine failures
  - Apart form the $f$ lies, we still have $f+1$ truth tellers, hence the majority is the truth
  - Needs at least $underbrace(f, "under" f "crushes")+underbrace(1, "available truth-teller")$ nodes to operate normally (distinguish lies)
*Example:*
If the mean time until each replica has a Byzantine failure is 1 week and a failure typically takes 7 hours to fix, what is the availability (in good form) of the replicated service?
*Solution*
- To tolerate Byzantine Failure, we need *at least TWO* replicas to operate *normally* to reach majority
- $P("1-Available") = "MTTR"/("MTTR"+"MTTF") = (7 times 24) / (7 times 24 + 7) = 24/25$
- $P("1-Fail") = 1 - P("1-Available") = 1/25$
- $P("All-Available") = 1 - (P("2-Fails-1-Available") + P("3-Fails")) = 1 - (binom(1,3)P("1-Fail")^2P("1-Available") + P("1-Fail")^3)$



=== State Machine Replication (SMR)
- Client requests to *ALL* the replicas
- Replicas are *deterministic*: If run the same commands, their states and outputs should be identical
- Clients wait for
  - Masking crash: 1 reply
  - Making byzantine failure: $f+1$ *identical* replies
*SMR in _asynchronous_ environment*\
Achieved within the cluster
- Assume asynchronous systems
- Can accept concurrent requests from clients
- Number of replicas *higher than* modular redundancy
- Need to decide the ordering or concurrent events
- $2f + 1$ replicas to tolerate crash or omission failures
- $3f + 1$ replicas to tolerate Byzantine failures

We could separate the *agreement cluster* and the *execution cluster*
- Agreement Cluster: Consensus Algorithm
- Execution Cluster: Modular Redundancy
#figure(image("../slides/3a-process-scheduling.pdf", page: 93, width: 60%),)

== Quorum Systems
A quorum can represent the entire system
- Improve the SMR availability: only contact nodes in a quorum

*D-Availability*: At least one *fully correct* quorum exists all the time ($N - f >= |Q|$)

=== Crash Tolerance
Tolerate $f$ Crashes
- Number of replicas: $N = 2f+1$
- Size of Quorum: $|Q| = floor(N/2)+1$ (Majority quorum)
- $|Q| = floor((2f+1)/2)+1 = f+1$
- Tolerate $f$ crashed, if we contacted $f+1$ nodes and $f$ crashes, we are guaranteed to have *one* result

=== Crypto Byzantine Tolerance
Tolerate $f$ Byzantine Failures
- Number of Replicas: $|N| = 3f+1$
- Size of Quorum: $|Q| = floor((f+N)/2)+1$
- Derivation: (assume two quorums with size $|Q|$)
  - *Intersection Size*: $|Q_1 inter Q_2| = |Q_1| + |Q_2| - |Q_1 union Q_2| = 2|Q| - N$
  - *At least _one correct answer_ in the intersection*:
    - $2|Q|-N >= f + 1$
    - $=> |Q| >= ceil((N+f+1)/2)=floor((N+f)/2)+1$
  - *D-availability*
    - $N-f >= |Q|$
    - $=> N - f >= (N+f+1)/2 => N >= 3f+1$

=== Verbal Byzantine Tolerance
Tolerate $f$ Byzantine Failures
- Number of Nodes: $|N| = 4f+1$
- Size of Quorum: $|Q| = floor((2f+N)/2)+1$
- Derivation
  - *Intersection Size*: $2|Q| - N$
  - *At least _majority of correct answers_ in the intersection*:
    - $2|Q|-N >= 2f+1$
    - $=> |Q| >= ceil((2f+1+N)/2) = floor((2f+N)/2)+1$
  - *D-availability*:
    - $N-f >= |Q|$
    - $=> N - f >= (N+2f+1)/2 => N >= 4f+1$

== Recovery Strategies
Two types of recovery
- *Forward Recovery*: find a new error-free state
- *Backward Recovery (Rollback)*: Bring the system back into a previous error-free state

=== Backward Recovery
- Checkpoint/Snapshot: Record the system state periodically onto stable storage to establish recovery points 
- Downtime: Upon failure, reboot or bring a spare host online
- Recover: Recover the system by rolling back to the previous checkpoint

States in distributed programmes
- Individual states
- Communication channels
*Inter-process dependencies* causes non-failing processes to rollback just to avoid *orphan messages*

=== Global Consistent Recovery State
Processes must identify a *recovery line*
- The most recent *consistent collection* of checkpoints
- Consistent: without orphans
Techniques
- Independent (uncoordinated) Checkpointing
- Coordinated (consistent) Checkpointing

==== Independent Checkpointing
Each process takes checkpoints independently.
- $arrow.t$ Take a checkpoint when it is most convenient
- $arrow.b$ Requires *global coordination* to compute recovery line
- $arrow.b$ Potential domino effect: processes may roll back to the beginning
- $arrow.b$ Possible useless checkpoints (never be a part of a global consistent state)
- $arrow.b$ Each processes must keep multiple checkpoints (we don't know how far we will fallback to previous checkpoints)
Upon failure
- Rollback *each process* to its most recent saved state
- Check if the local states *jointly* form a "recovery line" (*consistent global state*)
- If not consistent, keep rolling back (Question: all processes roll back by one checkpoint uniformly? Otherwise we will need to explore a combinational search space...)

==== Coordinated Checkpointing
- $arrow.t$ Saved state is automatically globally consistent
- $arrow.t$ No domino effect because every process can start at he most recent checkpoint
- $arrow.t$ Each process only maintain one checkpoint on the stable storage
- $arrow.b$ Large latency (blocking coordination)

*Blocking Coordination*
- Coordinator multicasts a *checkpoint-request* message
- Participants receive the *checkpoint-request* message
  - *Freeze execution*
  - *Queues* every subsequent incoming messages
  - *Ackowledge* the coordinator
- Corrdinator: after gathering all ACKs, broadcast a *checkpoint-done* message
- Participants receive the *checkpoint-done* message
  - resume all processes
*Non-blocking Coordination*: Chandy & Lamport's Snapshot Algorithm

==== Recovery Message Handling
- Normal Messages: sent and received *before* the recovery line
  - not effected by the rollback
- Lost Messages: *sent before* the recovery line but *received on the other side* of the line
  - must be *replayed* from the log (it is queued)
- Delayed Messages: *sent after* the recovery line but have *not yet arrived*
  - discard on arrival after rollback to avoid orphan messages
  - it will be sent after recover in re-execution
- Vanished Messages: sent and received *after* the recovery line
  - no action needed, will be sent after recover in re-execution

=== Failure Prediction
  - "Precursor" events can provide a good sense of when a PE might fail in the future
  - Checkpoint proactively only when a failure seems likely in the short term
  - Migrate all processes running in a PE when a failure seems likely in the short term
=== Log-based recovery
  - Combine checkpoints with message logging, similar to "lost messages"
  - Processes take infrequent checkpoints
  - Processes log *all the received messages* to to local stable storage (pessimistic)
  - Upon a failure
    - the crashed process rolls back to its latest checkpoint
    - *reply* the messages received *since that checkpoint* in the right order
  - $arrow.t$ If a process fails, other process does not need to roll back to ensure consistency
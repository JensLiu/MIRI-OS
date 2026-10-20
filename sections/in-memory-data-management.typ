= In-Memory Data Management
== Desktop
Cache Coherence Protocols
- MSI: Modified-Shared-Invalid
- MESI: Exclusive-MSI
  - Exclusive: Read cache line is owned by 1 cache
- MOESI: Owned-MES
  - Owned: Modified cache line may be shared by others
- MOESIF: Forawrd-MOESI
  - Forward: Shared cache line may be forwarded to others (avoid broadcast the bus)
== Pre-WSC
N nodes, multiple processors
- N = 2-100 nodes
- Each node has its *own* memory chip *(Multiple address spaces)*
- Local-area network
=== Distributed Address Space
- \@Spaces of other nodes are not accessible
- Message passing mechanism needed (e.g. MPI)
- Explicit communication required for the programmer
=== Shared Address Space
- SW/HW layer
  - SW: Distributed Shared Memory (DSM)
  - HW: Non-Uniform Memory Access (NUMA)
==== Replicated Address Space
- Needs consistency protocol
- Memory access detection
  - Processor
    - Specific instructions: Load/Store
      - Generates bus operations
    - Loaded into cache (keep state)
  - Middleware
    - virtual memory 
      - page 4MB
      - Page tables (memory protection, page fault)
- Need a *directory* to keep page stage in global \@Space
- Each node has local caches (two levels of replica)

Strong consistency: All replicas updated before a write completes
Problems
- Emulate memory bus
- Latency of writes
- Local caches
- Cache line size
- False sharing

Example: Treadmarks
- Software DSM
- Allow wries on different memory regions
- Allow writes on *same* memory region
  - Calculates diffs and merge changes
- Programmer needs to *mark all critical regions*
- Based on locks, groups a set of addresses and operations
- Lasy Release Consistency Protocol

==== Aggregation of Address Space
- Larger \@Space
- Each node is responsible for a part of the \@Space
- No replicas 
  - no consistency problems
  - increased latency when accessing from other nodes

== WSC
Need replication to
- Improve *availability*
- Enhance *reliability*
- Improve performance and scalability
But, according to CAP, we have *inconsistencies*. Relax existing consistency constraints.
=== CAP Theorem
In a distributed system, only two of these three constraints can be satisfied
- Consistency: *Every read* receives the *most recent write or an error* 
- Availability: *Every request* (by a non-failing node) must receive a *non-error* response, *without* the guarantee that it contains the most recent write
- Partition Tolerance: The system continues to operate despite an *arbitrary number* of messages being *dropped* or *delayed* by the *network between nodes* 
In WSC, we choose availability and partition tolerance over consistency $->$ Eventual Consistency.
*Exam Question (21, i)*
In a distributed file system that implements an Immutable files semantics and enforces the availability of the whole file system, which of the following is false?
+ ($checkmark$) client will read always the last written content.
  - We enforced *Availability*, and we can (without further guarantee), enforce *Consistency*
+ ($checkmark$) File content can be updated.
  - Immutable file system: Files cannot be modified, it can be *updated* by creating a new *version* of the file
+ ($checkmark$) Any file will be accessible at all times.
  - We enforced *Availability*
+ ($crossmark$) Data will be consistent even in the case of network failures.
  - We already enforced *Availability*, now we want data *Consistency* during network *Partition*, it is impossible
=== Not-Only-CAP: PACELC
On internet *Partition*: Choose between *Availability* or *Consistency*
Else: choose between *Latency* and *Consistency*
=== Eventual Consistency
- Fast writes (Local only, propagated in the background)
- Fast reads (but may be corrupted)
- Inconsistency Window
  - The period between the *update* and the moment when it is guaranteed that *any observer* will *always* see the updated value
  - Depends on the implementation, latency, network partitions, etc
=== Session Guarantee
A *client-centric property* that ensures *a single user/session* perceives data in a consistent way (even if the database is eventually consistent). The following satisfy this guarantee.
- Read-Your-Writes: See your own updates
- Monotonic Reads: Never see data go back in time
- Monotonic Writes: Writes are processed in the order you sent them 
- Writes Follow Reads: If write after reading a value, the write is guaranteed to happen after the version you read
=== Data-Centric: Consistent Prefix
Readers observe an *ordered sequence* of writes, starting with the first write to the data store, for example
- current (x, y) = (0, 0)
- updates in order: write(y, 1), write(x, 1), write(y, 2)
- we can read $(x, y) in {(0, 0), (0, 1), (1, 1), (1, 2)}$
- The values we read are *always* valid values (it happened in real life, as opposed to _monotonic read_)

=== Data-Centric: Bounded Staleness
Read operation will return values no older than *more than $T$ minutes ago* or $K$ versions ago. i.e. any values *written $T$ minutes ago* must be visible to *all readers*.


=== User-Centric: Monotonic Read
- If a reader reads a *specific value*, all subsequent reads from the same reader will return *at least as recent as* this one
- Reader will *never* see a data rollback
- Note
  - Monotonic read is *independent*, if we write to two different objects, we will see monotonic writes on *each* of the objects independently
  - However, the collective read is *not in write order* (as opposed to _Consistent Prefix_), we could observe inconsistent data. For example
    - current: (x, y) = (2, 3)
    - updates in order: write(x, 4), write(x, 5), write(y, 6)
    - we can read $(x,y) in {x in {2, 4, 5} and y in {3, 6}}$
    - so there would be results like (x, y) = (2, 6), which *does not happen*
    - Results like $(x, y) = (2, 6)$ happen when we *DON'T* read $x$ before reading $y$, so $x$ is not guaranteed to be recent 
// #figure(
//   image("../slides/4-in-memory-data-management.pdf", page: 54, width: 60%),
// )
// In the above example, we can see that (a) represents monotonic read while (b) does not.\
// In (a), L2 registered *both $x_1$ and $x_2$*, hence we are guaranteed to have an at least as recent as the previous one

=== User-Centric: Read-Your-Writes
The effect of write operation by the process on data item will *always* be visible to the subsequent reads by that same process
- Even if the same process connects to different replicas, this still holds

== Consistency Protocols
(Originally,) Most common schemes are those that support *sequential consistency*\
*Eventual consistency* schemes are common now
=== Process Groups
==== Hierarchical Process Groups (Primary-Based Protocols)
- Clients send request to the coordinator (Primary)
  - Clients may be able to send read requests to workers (Replicas)
- Coordinator provides the desired service
- Coordinator update the workers using *Total FIFO-Order Atomic Multicast*
*Failure* ($F$ failures in total)\
If the primary fails, one of the workers promoted as primary
- Crash or Omission failures, need $F+1$ nodes
==== Flat Process Group (Replicated Protocols)
- Clients send their requests to *all replicas* using *Total FIFO-Ordered Atomic Multicast*
- Replicas process the request independently and reply (processes are *identical*)
Processes are assumed to be *identical*.\
If processes are *not identical*, non-faulty group members must *reach agreement* (consensus problem)

*Failure* $F$ failures in total\
If replicas fail, the remaining ones continue to respond
- Crash or Omission failures: need $F + 1$ nodes
- Byzantine Failures: need $2F + 1$ nodes
=== Primary-Based Protocol
==== Primary-Backup Remote-Write Protocol
- All writes are done at a *fixed* *single-replica*
- Reads can be carried out locally
*Steps*
+ Client request write to *some* backup (blocking until `ack`)
+ Write is *redirected* to the primary
+ Primary ask replicas to update and wait for replicas to finish
+ Replicas update and acknowledge the primary
+ (Primary or Replica?) Reply the client to mark complete
  - If it is replica, how does the replica know that the update is complete across all replicas? (Primary sent message? Query all replicas?)
  - The replica can replay to client and primary? Then we will not have a write majority.
// Then the client can read. If it is blocking write, the client should be guaranteed to see the most recent writes (read your writes)?

Analysis
- $arrow.b$ Writes can take a long time
  - especially when blocking write
  - use non-blocking protocols
    - Primary acknowlege the write but crash before it could send writes to backups, the read-your-writes guarantee is broken
- $arrow.t$ Easy to implement *sequential consistency* (All processes agree on *some* global total ordering of events)
  - Primary send all writes to each replica *in the same order* via *Total FIFO-Order Atomic Multicast*
  - Implements *Strong consistency* if read requests are also forwarded to the primary (Updates should be *visible to all processes* at *the same time $t in [t_"start", t_"end"]$*)
*Consistency Guarantee* (Close to these but may not be exactly these)
- Strong Consistency: All reads (and writes) are directed to the primary
  - Every client always see the most up-to-date version
- Sequential Consistency: Primary update using *Total FIFO-Order Atomic Multicast*
- Eventual Consistency: use primary uses non-blocking update (acknowledge the client immediately, update in the background)
  - On crash another node is promoted as the primary. Do we still have this guarantee?
#figure(
  image("../slides/4-in-memory-data-management.pdf", page: 76),
)
==== Primary-Backup Local-Write Protocol
- Primary migrates to the replica that is writing\
  - *NOTE* (Gemini): one primary for a specific *data item* at *any given time*
    - *Serialisation*: Only one process holds the primary copy before any writes can occur
    - *Global Order*
      - Writes only happen at current primary
      - Primary only migrates after completing/synchronising its state
        - Contradicts with the non-blocking protocol. Which one to use?
- Successive writes are carried out locally\
- Replicas are updated using a non-blocking protocol
- For consecutive updates to the same object, we only propagate the last value (higher performance)
- $arrow.b$ False sharing for concurrent writes (primary jump back and forth between two clients' chosen replicas) $=>$ Use replicated-write protocols
*Q*: What consistency guarantee does this provide
#figure(
  image("../slides/4-in-memory-data-management.pdf", page: 76),
)

=== Replicated-Write Protocol
Writes can be carried out at *multiple replicas*
==== Active Replication
- *Each operation* is forwarded to *all replicas*
- Operations need to be carried out *in the same order* *everywhere*
Clients uses *Total FIFO-Order multicast* (not atomic?) to send operations to the group of replicas.\
*Consistency Guarantees*
- *Sequential Consistency*: multicast *only write* operations
- *Strong Consistency*: multicast both *read and write* operations

==== Quorum-Based Protocols
Write to $N_R$ replicas before writing
- Update replicas in quorum, assign *new version number*
- Remaining replicas are updated as a *background task*
Read $N_R$ replicas before reading
- not all replicas in $N_R$ needs to be up-to-date
- Any up-to-date replicas may be read
- Avoid Read-Write Conflict: $N_R + N_W > N$ $=>$ *Always exists* an up-to-data value
- Avoid Write-Write Conflict: $R_W > N/2$
*Configurations*
- $N_R = 1, N_W = N$: Optimised for read (ROWA: Read-One, Write-All)
- $N_R = N, W_W = 1$: Optimised for very fast write
- $N_R + N_W <= N$: Eventual Consistency (May pick disjoint sets for reads and writes)
- $N_R + N_W > N$: Read-Write Conflict

== Redis
- Data structures
  - Sets, Hashes, Sorted Hashes
  - Lists
  - Bitmaps
- Publisher/subscriber paradigm
- Allow writes only with attached replicas
- key expiration
=== Consistency Protocol
- Primary-Backup Remote-Write
  - On Redis, write operation on non-primary nodes are disabled (don't need to forward request to the primary, all requests should make to the primary node)
  - Read request goes to *any* of the replicas, which means that it may read most recent or older values (if the replica has not been updated yet)
  - Asynchronous
    - timeout
  - Non-Blocking
    - `min-replicas-to-write`: minimum replicas to write until the primary acknowledge the client (otherwise timeout and fail)
=== Fault Tolerance
- Master Failure: No updates allowed, system is still accessible, data read may be stale
- Some writes may be lost during the master election
Use `sentinal` nodes to elect new masters\
`sentinal monitor <master-name> <master-ip> <master-port>` *`<quorum-size>`*
- Sentinel detect master's down (no heartbeat messages from the master)
  - `down-after-milliseconds`
- start fail-over mechanism
- A quorum of at least`<quorum-size>` nodes are required to declare the master is down
  - The `<quorum-size>` is *only* used to *detect master failure*
  - Leader election requires a *majority* of the sentinel processes
    - *NOTE*: The majority means the majority in *total \# of nodes*. If on internet partition, we still need $floor(N/2)+1$ nodes to elect a master, where $N$ is the *total \# of nodes*, not the number of nodes in a partition
=== Commands
- Create redis cluster
  - Create master: `redis-server` (default port 6379)
  - Create replicas: `redis-server --replica-of <master-ip> <master-port>`

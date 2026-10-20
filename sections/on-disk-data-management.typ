= On-Disk Data Management

== File System Properties
File System needs to solve two problems
- Naming: How do users locate their data
- Operations: How do users access their data

== Naming
How do users store/locate their data $=>$ Identification, Naming
*Name*: Map logical name and physical content
- User: map logical data objects to file names
- System: manages physical content
- filename $->$ (i-node)number $->$ blocks
Name hides implementation: how and where the file is stored on disk
*Namespace*: Organisation of names
- Create names and organise names
- Represented as a labeled and directed graph with two types of nodes
  - Leaf Node: Entry, stores file content
  - Directory Node: Directory table of $("edge-label", "node-id")$
- A naming path: $<"label"_1, ..., "label"_N>$
- Path name: Absolute path name, relative path name
*Directories*

== Operations
Virtual File Systems: provides uniform and transparent access to files
- System call layer
  - `open`, `read`, `write`
- Virtual file system
  - Access to files independent of where and how they are stored
  - Translation file $<->$ OS blocks identifiers
- Physical file system
  - Device specific code to read/write block content
  - e.g. Disk driver, tape driver

#figure(
  image("../slides/5-on-disk-storage-data-management.pdf", page: 23),
)

== Distributed File Systems
=== Semantics for Shared Files in Distributed Systems
==== Sequential Semantics (UNIX)
*Every operation* on a file is instantly available to *all processes*
==== Session Semantics
*No changes available* to other processes until the file is *closed*
==== Immutable Files
*No updates possible*, use new versions of files. Simplifies sharing and replication
==== Transactions
All changes occur *atomically* (`BEGIN_TRANSACTION`, `END_TRANSACTION`)
=== Architectures
==== Client-Server Architecture
Make remote files appear as if they were stored on a user's local disk.\
Separates data storage (server) from data consumption (client).\
It uses network as a transparent bridge
===== Implementation
- Client uses FS calls locally
- Request is forwarded to the remote file server
- File Server access local disk
- Send back the response with the request data
#figure(
  image("../slides/5-on-disk-storage-data-management.pdf", page: 40),
)
===== Client Side
Client mount remote directory locally
  - *VFS layer*: Kernel-level abstraction that allows the OS to handle different file systems using a single unified interface
  - *Client Module*: implements DFS protocol, converts local FS calls to network requests
  - *Cache*: Client stores copies of recently accessed data in a local memory or disk cache (Example: Sun NFS v4)
    - Cache data obtained from *read* operations
      - Validate cache blocks before they are used 
    - *Writes* carried out locally
        - Modified blocks are marked *dirty*
        - *Closing* the file implies *flushing* modifications to the server
    - Files can remain cached after closing it
      - Data must be *revalidated* when the file is reopened
      - Validation through timestamps (clock drift?)
    - Consistency problems
===== Server Side
  - *Flat File Service*: Handles actual data blocks and performs operation on file contents
  - *Directory Service*: Mapping between file names and unique identifiers (file IDs, i-nodes). Handles directory tree structures and metadata
  - *File Exporter*: Interface listens for requests from clients and interact with the server's local FS to retrieve the data.

===== Access Models
====== Remote Access Model
- Clients are offered transparent access to the FS
  - RPC: allow the client to call a function on the server as if it were local
====== Upload/Download Model
- Client access locally to a file after downloading it from the server
===== Server Stateness
====== Stateful
  - Store and manage files' state between operations
  - Client requests $->$ update the state
    - better performance
====== Stateless
  - Nothing is stored at server side
  - Client stores state
  - Full requests from client with all required info
    - file, offset, bytes
    - worse performance
==== Cluster-Based Architecture
===== Replication
Replicate through multiple servers to allow single file to be accessed by multiple clients
===== Distribution (Partition)
File-stripping: distribute the blocks of a file across servers $->$ files can be fetched in parallel.\
Use metadata server and load balancer
#figure(
  image("../slides/5-on-disk-storage-data-management.pdf", page: 47, width: 60%),
)
====== Consistency Problems
Semantics
- *Immutable Files*: no algorithm needed
- *Sequential/UNIX Semantics*
  - ($crossmark$) Avoid replication: NOT viable
  - ($crossmark$) Avoid write caching: slow
  - ($crossmark$) Only cache on server: bottleneck
  - ($checkmark$) Coherence Algorithm
- *Session and Transaction*: Coherence Algorithm

=== IBM General Purpose File System (GPFS)
- Cluster-based Architecture
- Distributed Metadata
- No Repatition
- Consistency
  - UNIX/sequential consistency semantics
  - Byte-Range Locking: uses distributed token manager to lock a specific range of a file
    - e.g. Node A can write to the first 1MB of the file while node B can write to the second 1MB of the file simultanuously
  - Sequential access
    - Optimised for large sequential reads and writes
- Remote Access Model
  - Direct I/O: perform read/write on a mounted drive. Data is pulled in blocks only when required
  - Client Cache
    - Data Cache
    - Inode Cache 
      - Internal file identifiers
    - File Attributes Cache
      - e.g. owner, permissions
  - Token-Based Consistency
- Stateful Server
  - System keeps 

=== GFS
- Can allow multiple writers to append to different files simultaneously
- A file is accessible when there is metadata about this file
- A file can be partially accessible when all replicas for some chunks of the file fails/network partition
- Very high $"Read"/"Write"$ ratio
*Features*
- Client connects directly with chunk servers
  - Clients ask the master for the location of chunk servers (which servers I should contact)
  - Caches the location for a limited time
  - interacts with chunk servers directly
- No *data caching* at server/client: utilise system buffer cache
- Clients *Caches metadata*
- Atomic namespace mutation
==== Interface
Not POSIX compliant, No Kernel/VFS for accessing files
User-level APIs to access files
Implemented in user space using the native Linux FS
Files are organised in directories
Operations
- Basic: `create`, `delete`, `open`, `close`, `read`, `write`
- Snapshot
- Record Append
  - Allows multiple clients to append to the same data concurrently
  - Guarantees atomicity of each client's append
  - *Atomically at least once* guarantee
  

==== Cluster
The GFS has *one master* and *multiple chunk servers*

ONE master:
- Stores file system metadata (names, attributes)
- Maps *files* to *chunks*

Chunk Servers:
- Stores data: fixed-size chunks
- Chunks replicated on several systems

==== Single Master
*NOTE*
- All *metadata* are stored *in memory*\
- *Namespace* and *file-to-chunk mapping* are also *kept persistent* by logging (*`operation log`*)
- Namespace mutations are *atomic*, guaranteed to have a *global total order* by the operation log 
Maintains *all* file system *metadata*\
- Namespace (PERSISTENT)
- access control info (PERSISTENT)
- `"Filename"` $->$ `Chunks[]` mapping (PERSISTENT)
- Current locations of chunks (NOT-PERSISTENT)
  - Queries from the chunk servers
  - Chunk servers have the final say on which chunk to have on its disk
  
Manages
- Chunk leases (locks)
  - Clients needs to ask permission from the master
- Garbage Collection (freeing unused chunks)
- Chunk Migration (copying/moving chunks)
Replication
The master *replicates its data* for fault tolerance

Communication\
The master periodically communicates with all chunk servers
- Via *Heartbeat* messages
- To get states and send commands

==== Chunk Servers
- *Chunk size* = 64MB by default
- *Checksum*: Stores *in-memory* and *on disk* a 32-bit checksum with *each chunk*
- *Chunk handle*: unique 64-bit number
  - *assigned by the master* on chunk *creation*
- *Chunk as Linux Files*: Chunk servers store chunks on local disk as Linux files 
  - usually under *`/tmp`*
  - total storage of chunks can be estimated by the total space of the `/` directory
- *Chunks Replicated*: Each chunk replicated on multiple chunk servers
  - By default, 3 replicas
  - Popular files may need more replicas to avoid hotspots

==== Read Path
+ Contact the master
+ Get the list of chunk handles and file's metadata
+ Get location of each of the chunk handles (replicated info)
+ Contact *any* available chunk server

==== Write Path
+ Master grants a *chunk lease* to one of the replicas
  - The master informs the primary replica of its primary selection
  - This replica will be the *primary replica*
  - The master increases the *chunk version number* and informs replicas
    - The replicas must record this new version number in *persistant storage* before master can reply to the client 
  - Client should contact the *master* only when the primary replica
    - Is not reachable, or
    - Replies that the client no longer has the lease 
+ *Control Phase*: send data (don't write, cached)
  + Client given a list of replicas
  + Client writes to the closest replica
  + The replica *forwards* to another chunk server
  + Chunk servers store this data in a cache
+ *Data Phase*: Write data
  + Client waits for replicas to acknowledge receiving data
  + *Send write request to the primary replica*
    - The request identifies the data pushed to all the replicas
  + The *primary* is responsible of *serialisation of writes*
    - Assign consecutive *serial numbers* to all writes
    - Serial numbers are used to detect stale values after a partition
    - When multiple clients want to write to the same offset
      - They are assigned to the same primary replica
      - The primary replica determines the write order
      - Regular writes may be undefined, use atomic append
  + Once all acknowledgements have been received, the primary acknowledges the client
  + If any error from the replicas, the client code will try to retry (The state is inconsistent)

=== HDFS
TODO

== Distributed Databases
*Traditional Databases*
- Data stored in (structured) tables
- Each row (data item) in a table has a unique Primary Key
- Queried using SQL
- Support joints
*Today*
- Large and unstructured data (Available > Consistent)
- Lots of random reads & writes
- Sometimes huge number of writes
- *Foreign Keys rarely used, infrequent joins*
*Needs*
- Speed
- Avoid Single Point of Failure (SPoF)
- Low Total Cost of Operation (TCO)
- Fewer system administrators
- Incremental Scalability, *scale OUT*
=== Scale Up/Out
- Scale up: Grow cluster capability with more *powerful machines*
  - Traditional, not cost-effective
  - Need to replace machines often
- Scale Out: *Incrementally* grow cluster capability by adding more *COTS machines* (Components Off the Shelf)
  - Cheaper
  - Over a long duration, phase in faster machines as we phase out few older ones
=== Key-Value (NoSQL) Data Model
*APIs*: `get(key)`, `put(key, value)`\
*Tables* (Column Families, Table, Collection)
- Like relational DBMS, but *not structures* (*missing columns* from rows)
- Supports for joins or foreign keys are *slow* and not used
- Can have indices
#figure(
  image("../slides/5-on-disk-storage-data-management.pdf",  page: 67, width: 60%),
)
=== Storing Data
Block-based FS stores structured (fix-sized) data well, but not for unstructured (variable-sized) data.
#figure(
  image("../slides/5-on-disk-storage-data-management.pdf", page: 70, width: 60%),
)
==== Block Storage Device
- Data stored in fix-sized blocks
- Identified by Logic Block Number (LBN), a positive integer starting from 0
- LBN used for data retrival
*Responsibilities*
- *Metadata Server*
  - Metadata
  - which *disk* and *block* a data is stored
#figure(
  image("../slides/5-on-disk-storage-data-management.pdf", page: 75, width: 60%),
)
===== File Creation
+ Client $->$ Metadata Server (create)
  - Server allocates an *i-node*?
===== File Access
+ Client $->$ Metadata Server
  - `Filename`, `Offset`
+ Metadata Server $->$ Client
  - `(Disk#, Block#)`
  - OR: the block
==== Object Storage Device (OSD)
Decouples metadata (naming) from data location
Data can be moved inside Object Storage Devices without notification
- Data is a single object $("Key", "Value")$
- Key: Positive integer
- Attributes
- Value: Arbutrary size
*Responsibilities*
Clients access directly both *Metadata Server* and the *OSD*
- *Metadata Server*: Metadata about the object (file $->$ object ID)
- *Object Storage Device*: which disk and block the data is located (Object ID $->$ i-node)
#figure(
  image("../slides/5-on-disk-storage-data-management.pdf", page: 77, width: 60%),
)
+ Client: `path/to/file`
+ Metadata Server: `objectID: 42`\
+ Object Storage Device: `inode`\
+ Block Storage Device: Retrieve data
===== File Creation
+ Client $->$ Metadata Server
  - Server allocates *i-node*
+ Metadata Server $->$ Object Storage Device
  - Create object for this file
===== File Access
+ Client $->$ Metadata Server
  - `path/to/file`
+ Metadata server $->$ Client
  - List of Object Storage Devices
+ Client $->$ Object Storage Devices
  - `File`, `Offset`
+ Object Storage Device $->$ Client
  - Data
=== Cassandra
- Peer-to-peer distributed system across homogeneous nodes
*Main Elements*
- *Nodes*: where data is stored
- *Datacentre*: collection of nodes
  - *Granularity* used by *replication*
  - Different workload can use separate datacentres
  - Datacentres must have *never span physical locations*
- *Cluster*: 1 or more datacentres
Cassandra is aware of network topology
#figure(
  image("../slides/5-on-disk-storage-data-management.pdf", page: 124, width: 80%),
)
==== Replication
Replication Factor: total number of replicas across the cluster
- `replication_factor` copies of each row, each copy on a *different node*
Replica Placement
- Partitioner: determines 
  - which node will receive the *first replica* of a piece of data
    - determined using consistent hashing
- Replica Placement Strategy
  - how to distribute other replicas across other nodes
  - `SimpleStrategy`: Move clockwise along the ring, pick $"RF" - 1$ nodes
    - From the slide: Single datacentre and 1 rack?
  - `NetworkTopologyStrategy`
    - Multi-DC Aware: Specify different $"RF"$ for each datacentre
    - Rack Aware: Within a datacentre, try to place replicas on *different racks*
==== Consistency
Per-query tunable consistency: how many nodes should response before an operation is considered successful
- *ANY*: At least one node 
  - just the coordinator is okay, doesn't need to be a replica
- *ONE*: At least one replica (*any* node of the cluster)
- *LOCAL_ONE*: one replica from the *same* node as the coordinator
- *ALL*: All replicas
- *QUORUM*: Waits for the majority of replica nodes in
  - *QUORUM*: response from *any* nodes in the cluster, the majority of the sum of RFs in all nodes
    - $floor((sum_(i in "DC")("RF"_i))/2)+1$
  - *EACH_QUORUM* (Only for writes): In *each* datacentre, require a majority
    - $forall i in "DC": floor("RF"_i/2) + 1$
  - *LOCAL_QUORUM*: majority in the *same* datacentre as the coordinator
  
Replicas mean the number of replicas of this specific data (`replication_factor`)\

==== Consistent Hashing
- Use a consistent key-space: a ring
- Data has a partition key
- Each partition key is hashed into a ring (`hash(partitionkey)`)
  - the hashed number is a 64-bit integer
- Each node in the cluster has a range of data based on hash value
- Cassandra place data on each node according to
  - Partition key
  - The responsible range of node
*Walk clockwise to find the node*
#figure(
  image("../images/consistent-hashing.png"),
)

==== Scalability
===== Gossip Protocol
Nodes are "equal", exchange messages using a *gossip protocol*
- alive nodes, dead nodes
- partition ranges
- schema versions (UUID)
- used disk spaces
- RPC IP addresss
Each node has its own view of the cluster, and each node can be the "coordinator" for a specific request

===== Bootstrap (Add Node)
To add a new node, specify
- `cluster_name`: the cluster to add the node (must match existing names)
- `seeds`: A subset of existing nodes' IP addresses
  - Used to contact when first joined in to gain full topology of the cluster
- `listen_addr`: Internal IP of the new node
*Contact Seed Nodes*
- Send gossip message to *one of* the *seed nodes* to get the topology of the cluster
- Start gossip with *every node*
*Token Selection*
- Default: select randomly `num_tokens` (usually 256) across the ring
- Allocation Algorithm: relieve the heaviest-loaded existing nodes
*Join and Streaming*
- Once the tokens are selected, the node enters *JOIN* state
- Contact the existing node that currently hold those ranges
- Existing node begins sending (streaming) the relevant SSTable files to the new node over the network
- During this process, the new node *accepts writes* (so it don't miss new data), but does *NOT serve read* yet because its data is still incomplete
use `nodetool netstats` to check

*Transition to NORMAL*\
- Once the streaming is 100% complete, the node update its status in *Gossip* to *NORMAL* (UP/NORMAL)
- The coordinator nodes access the cluster are notified
- Read requests will now be routed to this node
*Cleanup*
- The *old nodes* still have copies of that data that they no longer *own*
- Manually run `nodetool cleanup` on the neighbouring nodes
- Trigger a process where the old nodes delete the data range they no longer responsible for, freeing up disk space

===== Removing Nodes
- Use `nodetool` to remove node
- Tokens are reassigned automatically
*Decommissioning*
- `nodetool decommission`
- When node is *alive and healthy*
- The leaving node will identify which other nodes will take over its token ranges
- Physically streams its data to those new owners
- Enters the *LEAVING* state using gossip
- After streaming, sends the final "goodbye" message via gossip and shuts itself down
*Remove Node*
- `nodetool removenode` with the `Host ID` of the dead node
- When the node is physically failed or unreachable
- The remaining replicas for the token ranges will stream data to the node that are picking up the slack
- Cluster marks the dead node's ID as *REMOVED*
*Assassinate*
- `nodetool assasinate <IP>`
- Forcefully tell everyone to immediately forget about the target ID
- Does *NOT* stream the data, lost replica
*Final Cleanup*
run `nodetool cleanup`
==== Write Path
*Client*
- Client can contact *any* node as the *coordinator* for this request
  - Each node has a full view of the cluster (which nodes contains the required data) thanks to the gossip protocol
  - Coordinator's responsibility
    - Identify which replicas hold the data based on partition key
    - Manage communication between those replicas
*Coordinator*
- Coordinator send writes to *all* replicas
*Replicas (receiving write requests)*
- Replica writes to the write-ahead commit log
- Replica writes to the memtable (sorted map of recently written rows)
- Return to the client to acknowledge the write
- In the background, Each time the memory structure is full
  - flush it flush to disk into the *SSTable* (Sorted String Table)
  - SSTable is *immutable*, append-only
  - New writes creates new SSTable
  - SSTable are merged through *Compaction* (compact old rows)
#figure(
  image("../slides/5-on-disk-storage-data-management.pdf", page: 134),
)

=== Read Path
*Coordinator*
  + Send a *full read request* to the replica with *highest performance* (determined by dynamic snitching)
  + Send *digest request* to remaining (specified by the consistency level, not necessarily all) nodes
    - Digest request response: MD5 (hash) value of the data 
  + If the data's hash matches all digest data: Consistent, replay client immediately
  + If exists mistaching: Perform *Read Repair*
    - send *full read* to *ALL* replicas 
    - determine the latest version based on *timestamp*
    - update out-of-data nodes
- Coordinator waits for replies (according to consistency level), and then return
*Replicas (receiving read requests)*
- Checks *memtable* (in-memory buffer), if data's there, return immediately
- 
#grid(
  columns: (1fr, 1fr), // Two columns, each taking 50% of the available space
  image("../slides/5-on-disk-storage-data-management.pdf", page: 141, width: 100%),
  image("../slides/5-on-disk-storage-data-management.pdf", page: 142, width: 100%)
)

==== Key-Space
Use `IF NOT EXISTS` because multiple clients may create the same *Key-Space* or *Table* at the same time
Class:\
Replication Factor:
```SQL
CREEATE KEYSPACE IF NOT EXISTS store WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};
```
==== Tables
In Cassandra, tables are called *Column Families*.\
When creating tables, we use the name `<key-space-name>.<table-name>` to denote $"Table" in "KeySpace"$. Otherwise, use `use <key-space-name>`
- Primary Key $="partition-key":"clustering-key"$ where 
  - `partition-key` determines which node to store the data
  - `clustering-key` determines the row within a partition

```SQL
CREATE TABLE IF NOT EXISTS store.shopping_cart (
  userid                TEXT PRIMARY KEY,
  item_count            INT,
  last_update_timestamp TIMESTAMP
);
```

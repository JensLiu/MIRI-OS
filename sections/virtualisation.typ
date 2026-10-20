= Virtualisation
- Provides illusion of multiple dedicated systems
- Isolates programmes from the system and other programmes
- Virtual environments can be created and destroyed with little overhead
- Allow agile and fine-grain dynamic resource provisioning
- Enables fault tolerance for programmes

== Process Virtualisation
== System/Hardware Virtualisation
Provides *complete* system environment to allow a *guest OS* to *run in isolation* in a shared host. e.g. KVM, VMware\
*Virtualisation at ISA interface*: Emulate *ISA* and virtualise *HW resources*
- $arrow.b$ Overhead to run VM instances due to emulation
- $arrow.b$ Slow VM initialisation due to VM creation and loading of guest OS
- $arrow.b$ Great size of VM images and probable replicated contents (same OS)
#figure(
  image("../slides/3b-virtualization.pdf", page: 9, width: 60%),
)
=== Full Virtualisation
Use *hypervisor* to allow *unmodified* guest OS to run in isolation\
*Requirements*
- *Safety*: Only VVM should manage the HW (guest is limited to its virtual space)
  - Sensitive instructions must be emulated to make OS work correctly
- *Fidelity*: Programmes on VM execute identically to their execution on HW (except for timing)
  - Emulation is transparent to the guest OS
- *Performance*: non-sensitive instructions can be executed directly (if ISA is the same)

==== Bare-metal Hypervisor (Type I)
- The hypervisor is the *only* programme running on the *most privileged mode*
- Provide virtualisation and OS functionality
  - CPU scheduling
  - Memory and I/O management
  - device drivers
- Examples: VMware ESX, Xen, Hyper-V
- Typically deployed on server systems and production environments

==== Hosted Hypervisor (Type II)
- Run as a *user-level process* on top of an existing OS
- Depends on the host OS for much of its functionality
- Examples: VMware Workstation, VirtualBox
- Typically deployed on commodity devices and development/testing environemtns

==== Modern Hosted VMMs
- *VMM in Ring 0*
  - A sort-of Type I Hypervisor
- *Host OS in Ring 0*
  - *VMM App* that runs in user mode of the host OS
  - *VM Driver* that runs as a *kernel module* in the host OS
    - Install trap handlers in the kernel and se trap-and-emulate
    - Does the *world switch* from the *host world* to the *VMM world*
The host OS is responsible for scheduling resources between *VMs* and native applications.\
The host OS is responsible for handling I/Os (VMM has no device driver, it will switch back to the host OS)

#figure(
  image("../slides/3b-virtualization.pdf", page: 29),
)
  
==== Sensitive Instructions: Trap-and-Emulate
- *Requirement*: $"SensitiveInstructions" subset "PrivilegedInstructions"$
  - In x86, some sensitive instruction do not trap when run in user mode (e.g. `popf`)
  - Solution
    - Binary Translation + Protection Rings (At first)
    - Hardware-assisted Virtualisation (Later on)
- Privileged instructions issued by the guest OS will generate a trap in user mode
- VMM intercepts the traps and emulate the trapping instruction against the virtual machine state machine
- Execution mode
  - Kernel Mode: Hypervisor
  - User Mode: 1. Virtual User Mode, 2. Virtual Kernel Mode

#grid(
  columns: (1fr, 1fr), // Two columns of equal width
  // gutter: 10pt,        // Space between columns/rows
  image("../slides/3b-virtualization.pdf", page: 20),
  image("../slides/3b-virtualization.pdf", page: 20),
)

==== Binary Translation
Code in *virtual user mode*: directly executed\
Code in *virtual kernel mode*: emulated (interpreted)
- *Scanned* on the fly for basic blocks
- Blocks are rewritten to *replace* sensitive instructions with new code that *emulates their effect* against VM state
- Blocks can be *cached*

==== Protection Rings
On x86
- Guest User Process: Ring 3
- Guest OS: Ring 1
- Hypervisor: Ring 0
#figure(
  image("../slides/3b-virtualization.pdf", page: 24),
)

==== Hardware-Assisted Virtualisation
===== VMX mode
- Virtual Machine Monitor (VMM): *VMX Root*
- Guest OS: *VMX Non-Root* but remains in (Non-root) Ring 0
====== VMX Transitions
- *VM Entry*
  - VMM (VMX Root) -> Guest (VMX Non-Root)
  - `vmlaunch`: initial entry
  - `vmresume`: subsequent entry
- *VM Exit*
  - Gurst (VMX Non-Root) -> VMM (VMX Root)
  - Entered on *Trap*

====== VM Control Structures (VMCS)
Stored *by hardware*
+ *Guest* and *host* states
  - *Guest-State Area*: save on _vm exit_, load on _vm entry_
  - *Host-State Area*: load host state on _vm exit_
+ Behaviours of instructions in VMX mode
  - All *sensitive instructions* can be set to *trap* when executed on *Non-Root* mode
  - We can trap-and-emulate on x86 now
  
=== Paravirtualisation
*Modify source code* of the guest OS to replace *sensitive instructions* with *hyper calls* to the VMM
- $arrow.t$: Lower overhead than full virtualisation
- $arrow.b$: Guest OS is tied to VMM (use VMM-agnostic hypercalls)

=== Virtualisation of OS functions
==== VCPU Scheduling (Double Scheduling)
- Guest OS: Schedules processes onto vCPUs (each guest is assigned some vCPUs)
- VMM: Schedules vCPUs onto the physical CPUs
Typically based on proportional-share scheduling: better to ensure that *all* VMs can make progress (fair CPU scheduling, no starvation)

===== Borrowed Virtual Time (BVT)
- Allocate CPU time in proportion to the *weight (CPU Share)* assigned to a vCPU
====== Virtual Time 
Gives all runnable vCPUs equal amount of virtual time $=>$ always run vCPUs with *lowest virtual time*
- Consumed inversely proportional to weight
For each $"vCPU"_i$, track its virtual time ($A_i$)
$
  A_i =+= "RealRunningTime" times underbrace((1/w_i), m_i)
$
- RealRunningTime meassured by timer interrupt *minimum charging unit*
- $w_i$: weight, CPU consumption share
- $m_i = 1/w_i$ and normalised to be an integer ($w_i$ is the wright of vCPU)
- $=>$ vCPU with higher weight "consumes virtual time" slower
====== Context Switch Condition
switch from $i$ to $j$ if
$
  A_j <= A_i - C times m_i
$
- $C$: Context switch allowance (permission to run "overtime" beyond another runnabCle vCPU)
- Prevent ping-pong switches on every timer interrupt
====== Starvation Avoidance: Scheduler Virtual Time (SVT)
Avoid Starvation after waking up from *Voluntary* Sleep\
*must be from a *VOLUNTARY* sleep*
$
  "SVT" = min{A_j: j in "Active"("VCPUs")}
$
After waking up, set $A_i = max(A_i, "SVT")$ to avoid very low $A_i$
====== Time-Critical Support: Effective Virtual Time (EVT)
*Time-critical Task* support, if enabled, allow it to run more by decreasing the existing virtual time
- *Warp Values*: $"warp"_i in {0, 1}$ flag to enable/disable warp (on demand)
- *Borrow VT from Future Allocation* ($W_i$): Specify how much time needed from the future
- *Effective Virtual Time*
$
  A_i = cases(
    A_i - W_i &"if" &"warp"_i, 
    A_i       &"if" &not "warp"_i)
$

===== Lock Holder Preemption (LHP) problem
vCPU preempted while holding the lock
- Preempted: $"vCPU"_1$ on $"pCPU"_a$ holds the lock and is preempted, $"vCPU"_2$ on $"pCPU"_b$ busy wait during this period
- Stacked: $"vCPU"_1$ on $"pCPU"_a$ hols the lock and is preempted, $"vCPU"_2$ scheduled on the same $"cCPU"_b$ and then busy wait 
#grid(
  columns: (1fr, 1fr), // Two columns of equal width
  // gutter: 10pt,        // Space between columns/rows
  image("../slides/3b-virtualization.pdf", page: 40),
  image("../slides/3b-virtualization.pdf", page: 41),
)

===== Pause-Loop Exiting (PLE)
*Hardware support* to detect busy-waiting vCPUs
- Monitor the number of `pause` instructions
- VMM gets trapped so it can preempt busy-waiting vCPUs and yield to another one
- $arrow.b$ PLE events are not enough to determine *who* to yield to

=====  Paravirtualised Spinlocks
*Modify* spinlock implementation in the *guest OS* to add *hypercall*\s to the VMM
- Inform the VMM that a lock is acquired $->$ *prevents* the *preemption* of this vCPU
- *Yield* to another vCPU when lock *cannot* acquire quickly
- $arrow.t$ VMM can track the current lock holder (thanks to hypercall) and can yield to the most appropriate vCPU
- $arrow.b$ Modification of guest OS

===== Gang Schedulling
Scheduling vCPUs of the *same VM* simultaneously (if \#vCPUs < \#CPUs)
- $arrow.t$ Avoid stacking and busy-waiting
- $arrow.b$ Fragmentation, priority inversion

==== Memory Virtualisation
===== Software Memory Virtualisation
VMM maintains
- *Shadow Page Table*: *per-process* maps from (virtual) *Guest Physical Addresses* directly to (real) *Host Machine Addresses*
- *Virtual Page Table Base Register (vPTBR)*: points to the *shadow* page tables of the current active guest OS
The Hardware actually uses the *Shadow Page Table* for the address translation.\
VMM must *Keep shadow page table in sync*: Capture guest's attempt to install or update guest page tables
- $arrow.b$ Manipulating shadow page tables is *expensive*
- $arrow.b$ Space overhead due to shadow copying
#figure(
  image("../slides/3b-virtualization.pdf", page: 50),
)
*Full virtualisation*
- Instructions to modify *virtual* PTBR are privileged, hence traps into VMM
  - e.g. `MOV CR3, RAX` is privileged. Invocation by guest OS will trap into VMM
- Guest page tables are write-protected, hence modification by the guest OS (in user mode) traps into the VMM
*Paravirtualisation*
- Use hypercalls to inform VMM about changes to page tables

===== Hardware-Assisted Memory Virtualisation
EPT (intel) / NPT (AMD)\
MMU offers two *nested levels* of address translation
- *Guest page tables* (maintained by the guest OS)
- *Extended page tables* (maintained by the VMM)
MMU can walk directly through guest and extended page tables
- $arrow.t$ Better performance by avoiding shadow paging
  - No VMM involvement to sync tables
  - Less space needed: one EPT *per guest OS* instead of one shadow page table *per process*
- $arrow.b$ Longer address translation time, TLB misses are more costly

==== I/O Virtualisation
- Decouples virtual from physical I/O activity through software layer
- Guest OS is offered with virtual I/O devices
- VMM intercepts guest OS accesses to these virtual devices
- VMM emulates virtual I/O devices (using physical HW is needed)

===== Hypervisor Direct Mode
- VMM contains *virtual devices* that *emulates all the function* of the device
- $arrow.t$ Device sharing
- $arrow.t$ Easy VM migration
- $arrow.b$ Emulation overhead
- $arrow.b$ Complex hypervisor
- $arrow.b$ Exposed to driver faults: effects all VMs
#figure(
  image("../slides/3b-virtualization.pdf", page:55, width: 60%),
)

===== Service-VM/Hosted model
- Virtual devices only run on *privileged (service) VMs*
- Guest VMs' I/O calls are *redirected* to the service VMs by the hypervisor
- $arrow.t$ Higher security
- $arrow.t$ Device sharing
- $arrow.t$ Simple hypervisor
- $arrow.b$ Overhead due to *calls*, *redirection* and *world switch*
#figure(
  image("../slides/3b-virtualization.pdf", page: 56, width: 60%),
)

===== Pass-Through Model
- Physical device is *directly* and *exclusively* assigned to a particular guest OS (other VNs cannot use the same device)
- $arrow.t$ Removes emulation overhead
- $arrow.t$ Simpler hypervisor
- $arrow.b$ *Strong coupling* between guest OS and HW
  - Harder VM migration
  - Harder device sharing

===== I/O Interception in Full Virtualisation
Trap-and-emulate I/O operations of the guest OS
- Memory-Mapped I/O
  - Devices mapped in *regular memory*
  - access with `load`/`store` instructions
  - Use memory page protection to generate trap
- Port-Mapped I/O
  - Mapped in a *separate address space*
  - access with `in`/`out` instructions
  - these instructions are privileged, and generates trap
- Direct Memory Access
  - these devices bypasses CPU, needs *host machine addresses*
  - needs *address remapping* for the target
  - #image("../slides/3b-virtualization.pdf", page: 60)

===== I/O Interception in Paravirtualisation
Redesign virtual devices to optimise them for the virtualisation layer\
*Split the virtual device* (driver interface to the guest) *from the device driver* (interface with the actual device)
- Make hypercalls to VMM to initiate requests
- Buffers are shared between the guest OS and the hypervisor
- $arrow.t$ Lower overhead
- $arrow.b$ Specific drivers for each guest OS
- e.g. virt-io for KVM/QEMU (paravirtualisation I/O framework)
#figure(
  image("../slides/3b-virtualization.pdf", page: 61),
)

===== Hardware-Assisted I/O Virtualisation
VT-d (Intel)
- I/O MMU hardware virtualises memory
- Provides *address translation* for DMA (Guest PA to Host Machine Address)
- Provides *memory protection* for DMA
- Provides *dynamic remapping* of interrupts

=== OS-Level Virtualisation (Containers)
Seregate and isolate multiple user-space instances (containers) within a *single OS*
- $arrow.t$ Little overhead
- $arrow.t$ Minimal startup/shutdown
- $arrow.t$ Low resource requirement, high scalability
- $arrow.b$ All containers (in the same machine) *must* use the *same os*
- $arrow.b$ Containers *cannot* have their *own modules*
*Each container* feels list a virtual machine, but *shared the same OS*
- own process space (PID, etc)
- own network interface
- run stuff as root
- install packages, shells etc
#figure(
  image("../slides/3b-virtualization.pdf", page: 65, width: 60%),
)

*Linux Namespaces*
- types of namespaces `pid`, `net`, `mnt`, `uts`, `ipc` ,`user`, `time`, `cgroup`
- Namespaces are created with `create`, `unshare` system calls, with flags `CLONE_NEW*`
- `setns` call allows joining existing namespace
- Namespace is *deleted* when last process leaves
- `pid`: process have their own
  - *process numbering* and 
  - can only *kill* other processes *in the same namespace*
  - `ps` sees all processes with external PIDs unless we mount new `/proc`
  - `kill` uses internal PIDs
- `net` process get their own private network stack, including
  - network interfaces
  - routing tables
  - ip-table rules
  - sockets
- `uts`: processes can have their own host names
- `mnt`: processes can have their own
  - root file system and 
  - private mounts (`/proc`, `/tmp` etc)
- `ipc`: processes can have their own
  - message queues
  - semaphores
  - shared memory
- `user`: maps process UID-GID
  - e.g. *privileged* user ID *inside* and *unprivileged* user ID *outside*
- `time`: processes can see different clock
- `cgroup`: processes have their own set of `cgroup` root directories
  - Resource Limiting
    - \#CPUs, memory, \#PIDs, block I/O speed, network packets
  - Resource Prioritisation: when under heavy load, which cgroup to give priority (e.g. 80% to database group and 20% to backup group)
  - Resource Usage Monitoring
  - Process Control (e.g. suspend, restart all processes with in a cgroup at once)
*Capability*: divide privilege into distinct units to be independently enabled/disabled
- A process with root privilege can be limited to get only the minimal permissions it needs to operate
*Seccomp*: define which syscalls are allowed to be executed by a process

=== Application-Level Virtualisation (Programming-Environment Virtualisation)
Abstract away details of the underlying HW and OS, allow programme to execute the same way on any platform. e.g. JVM


== Virtual Clusters and Resource Management
- Built with VMs from one or more physical clusters
- VMs in a virtual cluster are *interconnected logically* by a *virtual network*
- Virtual clusters may grow and shrink dynamically
=== VM Deployment
+ Prepare disk image
  - Template images
  - Use COW to avoid copying the whole image
+ Configure VM
  - UUID, VM name, disk image, network settings, allocated CPUs and memory
+ Choose the destination host *(VM Allocation)*
  - Fulfill the VM requirements
  - Balance load, consolidate VMs, reduce energy consumption

=== Live VM Migration
*Requirements*
- Negligible downtime
- Lowest network bandwidth consumption
- Do not disrupt other services in host
- Must migrate
  - Memory
    - Could be compressed to reduce network bandwitdh
    - Pre-Copy and Post-Copy
  - Storage
  - Network

==== Memory Migration
===== Pre-Copy
- $arrow.t$ No need to fetch pages from the source list
- $arrow.t$ An up-to-date state of the VM is retained at the source host during migration
- $arrow.t$ If destination fails during migration, VM *can be recovered*
- $arrow.b$ Migration may *never end* if source $V_"dirty" > V_"transfer"$
- $arrow.b$ Can transfer the *same page multiple times*, if the page is *dirtied repeatedly* at host during migration

*Steps (Serial Steps)*
+ *Pre-Migration and Reservation*
  - VM Allocation
    - Determine migrating VM
    - Determine destination host
  - initialise a VM on he target host
+ *Memory Push (iterative Pre-Copy)*
  - In this stage, the *source* machine is still processing requests, but at a slower speed
  - Transfer *all* memory pages in the first round
  - Copy *dirty* memory pages (data which is changed) in successive rounds
  - Repeat until $\#"DirtyPages" < "Threshold"$
    - $V_"transfer" > V_"dirty"$, assume not memory intensive
    - *CANNOT* guarantee termination when $V_"transfer" <= V_"dirty"$
+ *Stop and Copy*
  - *Suspend* VM on the source host ($T_"off"$)
    - execution of this step is *serial* (in exams)
  - Network connection is *redirected* to the new VM
  - Transfer the *remaining* dirty pages
    - Transfer VCPU and Network States as well
+ *Commitment and Activation*
  - VM reloads state and resumes its execution on the destination host ($T_"on"$)
  - Remove orginal VM from the sources host

===== Post-Copy
- $arrow.t$ Live migration ends in a finite time
- $arrow.t$ Sends each page *exactly once* over the network
- $arrow.b$ VM *state is distributed* over both source and destination hosts $=>$ If destination fails during migration, the *VM cannot be recovered*
- $arrow.b$ Latency of remote page fault (fetching pages from the source host)

*Steps*
+ *Pre-Migration and Reservation* (SAME)
+ *Stop and Copy (Down)*
  - Suspend VM and transfer *minimal execution state*
  - $T_"OFF" + T_"context" + T_"ON"$
+ *Activation*: resume VM at destination host
+ *Running VM and Migrate Memory (Push)*
  - Demand Paging (Remote Page Fault)
    - If VM tries to access a memory page that has not been migrated, generate a page fault
    - Fetch the missing page with high priority
  - Proactive Page Push
    - The source continues to push remaining memory pages to the destination in the background until all pages are transferred
  - Notes
    - Here, every memory page is copied exact once, so the total time for memory transfer is $T_"migrate"="MemorySize"/"BandWidth"$
    - $T_"Migrate" = T_"PageFaultInstructions" + T_"RegularInstructions"$
    - If we know the useful instructions executed during this migration, we can calculate the rest of the instructions to execute on the new host
      - $"NI"_"migr" = "NI"_"PageFault" + overbrace("GIPS"(h_2), "Dest Full Speed") dot overbrace(R, "% used for normal execution") dot T_"RegularInstructions"$
      - $"NI" = "NI"(h_1) + "NI"_"migr" + "NI"(h_2)$
+ *Termination*
  - When all pages are transferred, the original VM is removed

==== Storage Migration
- *Shared Storage Model*
  - Virtual disks resides on a single shared volume accessible by all hosts
  - $arrow.t$ No copy needed
  - $arrow.b$ Required HW or SW support for shared storage
- *Shared-Nothing Mode*
  - Virtual disks are moved across different storage elements
  - $arrow.t$ Can worl with any kind of storage support
  - $arrow.b$ Must be optimised to avoid huge downtimes due to the current trend on disk capacity
===== Shared-Nothing: Snapshotting
+ Take a snapshot as *Base Disk* (source)
  - The base disk becomes read-only
  - The VM continues to work in a delta disk
+ Redirect write to *Delta Disk* or *Redo Log* (source)
+ After the copy *Base Disk*, *consolidate the Delta Disk into Base Disk*; while VM is working in *another* delta disk (source)
+ Repeat until the amount of data in the delta disk becomes smaller than the threshold
+ Suspend VM and consolidate the final delta disk
===== Shared-Nothing: Dirty Block Tracking
Same protocol as *memory pre-copy* but copies disk blocks instead of memory pages
- Instead of redirecting writes to a new delta disk, we writes to the *original disk*
  - We don't need to keep a strictly snapshot of the state before migration. While we are transferring data, we allow writes to go through (The old data will be overwritten anyway, no need in preserving them)
- It is tracked only by bitmap, less storage overhead
===== Shared-Nothing: I/O Mirroring
Mirroring writes to the source and destination concurrently
- Writes to region already copied: mirror to source and destination
- Writes to region not copied: to source
- Writes to region currently being copied: Delay until copy finishes and then mirror to both source and destination

==== Network Migration
VM keeps its virtual MAC and IP addresses
- Migrating within the *same local subnet*
  - Source host broadcasts ARP reply to advertise (to the *local network*) that the IP has moved to a new location
  - Same in-flight packets may get lost, but TPC retransmissions will take care of that
- Migrating across subnets, an *indirect layer* must exist
  - e.g. Mobile IP: a node on the source network forwards packets to a care-of address on the destination network

=== VM Allocation
- Decide mapping of VMs to physical hosts
- Migrations allow moving VMs among hosts
- Can be viewed as a *fully dynamic packing problem* (NP-hard)
- Simple *bin-packing heuristics* have been adapted
  - e.g. First Fit and Best Fit heuristics
  - VM allocation is harder than bin-packing
- Comparison between VM Allocation and Bin-Packing
  - Several resource dimensions
    - CPU, memory, disk
  - Performance degrades when the physical host is (close to) overloaded
  - Physical hosts have different capabilities
  - \#hosts is finite, constraining the \#VMs that can be allocated
  - \#VMs and \#hosts are volatile (changes over time)
  - VM migrations incur a performance cost

=== VM Consolidation
- Consolidate VMs running on underutilised hosts (Enhances utilisation)
- Live VM migration supports dynamic consolidation
- Suspend idle hosts to lower operational costs (e.g. electricity)

=== VM Load-Balancing
- Balance the VMs across hosts according to their changing resource requirements
- Spread the VMs to foster parallelism and dependability
- Live VM migration supports dynamic load balancing

=== VM Elasticity
- Dynamically and transparently scale up/down VMs that provide a service
- Horizontal: increase number of VMs among hosts
- Vertical: increase the size of the VM

=== VM Checkpoint/Recovery
- Upon a host failure, VMs are automatically resumed from their last checkpoint on *other physical hosts*
- Live VM migration allows *proactively* moving VMs when a failure seems likely in the short term

=== VM Replica Failover
- Maintain several replicas of the VMs on different hosts
- Upon a VM or host failure, service is automatically resumed from one of the replicas with *no downtime*
= Energy Management
Energy Consumption Accounting
- *Power Metering*: Measure the actual power consumption by instrumenting the hardware
- *Power Modeling*: Estimate power consumption by means of corelated indirect evidences
  - Performance monitoring counters
  - Resource utilisation metrics

== Metrics
=== Power Usage Efficiency (PUE)
Ratio multiplier to convert from *Total Energy Consumption* to *IT Equipment Consumption*
- Hyperscale WSCs (e.g. Google): $1.13$
- Traditional data centres: $1.6-2.35$
$"PUE" = E_"Total" / E_"IT"$
#figure(
  image("../slides/6-energy-management.pdf",page: 3, width: 60%),
)
- Not all PUE measurements include the same overheads $=>$ Adhere to Green Grid guidelines in measuring and reporting
- Instantaneous PUEs differ from average PUEs $=>$ Annual averages from data aggregates
- Some PUEs are based on optimal operating environment $=>$ Use real-time measurement

=== Server Power Usage Efficiency (SPUE)
Ratio multiplier to convert from *Server Input Power* to *Useful Power*\
$"SPUE" = E_"In" / E_"Useful"$

- *Useful Power*: power consumed *directly* involved in computation
  - Motherboard, disks, CPUs, DRAMs, etc
- *Unuseful Power*: Cooling fans, power supply, voltage regulator modules, etc.
- Google's $"SPUE" ~ 1.1$

=== Total Power Usage Efficiency (TPUE)
$"TPUE" = "PUE" times "SPUE"$

=== Energy Efficiency of WSCs
Measures energy used by a WSC to run a *particular workload*\
$"Eff" = E_"Computation"/E_"Total"=1/"PUE" times 1/"SPUE" times E_"Computation"/ E_"ElectricComponents"$

=== Data Centre Energy Productivity (DCeP)
Measures how the energy delivered to electronic components is actually converted into useful work
- Typically, benchmarks have been used (e.g. SPECpower)
In exams, it is defined as
$
  "DCeP" = (sum_"U=0"^100 "TotalWork"(U)) / (sum_"U=0"^100 "TotalEnergy"(U)) ["in" "#Oprations"/"Watt"]
$
In which we profile each utilisation
== Power Metering
Power-Energy Relation (Energy is power over time)
$
  E = T dot P
$
Units regarding energy:
$
  1 "Wh" = underbrace(1 "W", P) times underbrace(3600 "sec", t) = 3600 "J"
$
Frequency-Time Relation (Lower frequency, higher execution time)\
$
 T_1 dot f_1 = T_2 dot f_2
$
Total Work is defined as
$
  "TotalWork" = "Performance" times "Time" times "#Hosts"
$
Total Energy is defined as 
$
  "TotalEnergy" = E times "#Hosts"  
$
=== Integrated Metering on Hardware
Firmware offers API to query power usage
- Add specific sensors (e.g. Dell PowerEdge, HP ProLiant)
- Use software power models (Intel Running Average Power Limit, RAPL)
- $arrow.t$ Accurate power for individual components
- $arrow.b$ Architecture dependent
- $arrow.b$ Intrusive method (metering procedure itself consumes power)

=== External Meter
- General purpose meters
  - not appropriate for large-scale deployments)
  - e.g. PLOGG, Kill-A-Watt
- Intelligent Power Distribution Units (PDUs)
  - e.g. Raritan Dominion PX, HP Intelligent PDU
- $arrow.t$ Architecture independent
- $arrow.t$ Unobstructive external measurements
- $arrow.b$ Can measure only system-level power
- $arrow.b$ Less accurate measurements

== Power Modeling
Used to account for energy consumption when
- Direct measurement is not feasible
- To access the power consumption of *individual software components*
  - e.g. processes, virtual machine
- Forecast the power consumption in the future or in hypothetical scenario

Aspects
- Application workloads
- Server power load and energy consumption
- Server temperature and heat distribution
- Cooling and air flows
- Cost (operational and capital expenses)

Scales
- Time Scales: ms, s, min, hr
- Special Scales: components, servers, racks, WSCs

== Efficiency of IT Equipment
=== Low-Power Modes
==== Inactive Low-Power Modes
Turn off hosts when they are idle and turn them on when they are needed again
#figure(
  image("../slides/6-energy-management.pdf", page: 25),
)
Here, if we want to compare the *inactive* and *active* power modes, we should limit
$
  delta^"active"_"idle" = delta^"inactive"_("ON"->"OFF") + delta^"active"_"OFF" + T^"active"_("OFF"->"ON")
$
Otherwise, we would have delayed the original schedule in the inactive mode, hence the comparison isn't fiar.\
Hence
$
P_"idle" dot delta_"idle" > E_("ON"->"OFF") + E_("OFF"->"ON")+(P_"OFF" dot (delta_"idle" - delta_("ON"->"OFF") - delta_("ON"->"OFF")))
$
$
  => delta_"idle" > (E_("ON"->"OFF") + E_("OFF"->"ON") - P_"OFF" dot (delta_("ON"->"OFF") + delta_("ON"->"OFF"))) / (P_"idle" - P_"OFF")
$


==== Active Low-Power Modes
Better for *memory bounded* tasks (less effected by the frequency)
- Keep the host active but lower the CPU voltage/frequency to save power\
- Decreasing frequency increases the execution time
Dynamic Voltage and Frequency Scaling (DVFS)
- Allow changing dynamically the operating voltage/frequency of the processor

#figure(
  image("../slides/6-energy-management.pdf", page: 28),
)
Observation: $
P ~ alpha C_L V_"dd"^2 f
$
*Execution Time*\
*Total execution time* consists of *CPU* time $t_c$ and *Device* time $t_d$ $
  t = t_c + t_d
$
*Resource Usage Percentage (Workload)*: helps to divide execution time $R_c + R_d = 1$, hence 
$
  t_c = t dot R_c\ 
  t_d = t dot R_d
$
Since only *time* spent in the *CPU* and *CPU power* are sensitive to DVFS $
  t_d_1 = t_d_2 = t_d
$
Given frequency ratio $f_1/f_2 > 1$, and since frequency *only* influences *CPU time*,
$
  t_c_1 dot f_1 = t_c_2 = f_2
$
Hence $
  cases(
    t_1 = t_c_1 + t_d,
    t_2 = underbrace(t_c_1 dot f_1 / f_2, t_c_2) + t_d
  )
$
We denote the idle time (for non-DVFS configuration) as the waiting time 
$
  t_"idle" = t_2 - t_1\ => t_"idle" = t_c_1 - t_c_2
$

*Power*\
Static power $P_"idle"$ always consumes energy, and the current power is the sum of static and dynamic power $
  P = P_"dynamic" + P_"static"
$
hence $
  P = underbrace(P_c + P_d, P_"dynamic") + underbrace(P_"idle", P_"static")
$

*Note*: If we divide the power and time as *CPU* and *Device*, we should calculate their power consumption separately
$
  E = underbrace(P_c dot t_c, "CPU Consumption") + underbrace(P_d dot t_d, "Device Consumption")
$
We *CANNOT* calculate using
$
  E != (P_c + P_d) dot (t_c + t_d) = underbrace(P_c dot t_c + P_d dot t_d, "Correct" E) + underbrace(P_c dot t_d + P_d dot t_c, "WRONG!")
$
==== Non-Active and Active Power Saving Mode
For the *non-active configuration*, the total energy consumed should be
$ 
  E_1 = underbrace(underbrace((P_c_1 + P_"idle") dot t_c_1, "CPU consumption") + underbrace((P_d + P_"idle") dot t_d, "Device Consumption"), "Full Frequency Consumption") + underbrace(P_"idle" dot t_"idle", "Idle Consumption")
$
For the *DVFS configuration*, the total energy consumption should be
$
  E_2 = underbrace(underbrace((P_c_2 + P_"idle") dot t_c_2, "CPU Consumption") + underbrace((P_d + P_"idle") dot t_d, "Device Consumption"), "Decreased-Frequency Consumption")
$

To be able to compare, we could (in theory) simplify to
$
  E_2 - E_1 = P_c_2 t_c_2 - P_c_1 t_c_1 ???
$

==== Default and Active Power Saving Mode
*Power Measurement*
$
  P_2 &= (R_c dot underbrace(P_1 f_2/f_1 V_2^2/V_1^2, "CPU Power") + R_d dot underbrace(P_1, "Device Power"))\
  &= (R_c f_2/f_1 V_2^2/V_1^2 + R_d) P_1
$

*Work Measurement*\
We are given the performance $"perf"_1$ (req/sec) of the default configuration, our new configuration has the performance of
$
  "perf"_2 &= (R_c dot underbrace(f_2 / f_1 "perf"_1, "CPU Perf") + R_d dot underbrace("perf"_1, "Device Perf"))\
  &= (R_c f_2/f_1 + R_d) dot "perf"_1\
  "where" R_c + R_d = 1
$
We can find the amount of work (instruction execution) done for both configurations
$
  W_1 &= "perf"_1 dot T dot N_"hosts"\
  W_2 &= "perf"_2 dot T dot N_"hosts"\
      &= (R_c dot f_2/f_1 + R_d) dot "prof"_1 dot T dot N_"hosts"
$

== Resource Allocation and Scheduling
Nonproportional energy consumption to load

Adapt policy to optimise energy efficiency
- When to run each task
- How many PEs to assign to each task
- Which PEs to assign to each task
- *(NEW)* What power state to set for each PE

Virtualisation technology
- VM consolidation
- Live MV migration
- VM allocation

#figure(
  image("../slides/6-energy-management.pdf", page: 32, width: 60%),
)

=== VM Consolidation
- Run the hosts at *higher utilisations* closer to its *most energy-efficient operation point*
  - Live VM migration supports dynamic consolidation
- Reduce the number of hosts needed to serve a given workload
  - inactive low-power modes

VMs in the same physical host may suffer *resource contention (interference)*
- $->$ Use *contention-aware scheduling*

=== Live VM Migration
Consumes energy
$
  E_"migration" = E_"init" + E_"transfer" + E_"activation"
$
#figure(
  image("../slides/6-energy-management.pdf", page: 36, width: 70%),
)

(Most) Impacting factors on the energy $E_"migration"$
- CPU utilisation of the source and target hosts
  - Utilisation of each VM
  - Utilisation of the hypervisor
  - Utilisation added by the migration (VM suspension/restart, state transfer)
- Memory allocation to the migrating VM
- Memory dirty rate of the migrating VM
- Network of the bandwidth between the source and target for transferring the state of the VM

=== VM Allocation
Packing problem, consider more challenges
- Power consumption of the host regarding the load is non-proportional
- Host can have heterogeneous power consumption profiles regarding the load
- Migration has an energy cost

== WSCs Ecosystems
Select the most appropriate WSC to deploy every workload

*Follow the Moon*: deploy workloads by following the night-time
- $arrow.t$ *Easier Workload Allocation*: computers in an off-peak demand interval
- $arrow.t$ *Reduced Costs*: cheaper electricity
- $arrow.t$ *Free Cooling*: Lower outside temperature
- $arrow.b$ *Distant Geographic Location*
  - Increased performance and energy cost for VM migration
  - Increased communication latency
- $arrow.b$ Independent administrative domains involved in the ecosystem
  - Conflicting goals among WSCs
  - Lack of information about the energy consumption and energy mix of other WSCs

== Cooling Subsystem
Use some hierarchy of loop systems\
Each loop brings in a cold medium (such as air or water) that absorbs heat via a heat exchange process and is subsequently cooled back down.

*Open Loop*: The system replace the ongoing warn medium with cool supply from the *outside*
*Closed Loop*: The system recirculate the same medium repeatedly. It transfer the heat to the *upper loop* through a *heat exchanger*

=== Free Cooling
#figure(
  image("../slides/6-energy-management.pdf", page: 44, width: 60%),
)
Open single loop system that cools several servers by flowing *outside air*
- $arrow.t$ Most efficient cooling system
- $arrow.b$ Climate dependent
- $arrow.b$ May require auxiliary cooling when the external condition is not favourable
- $arrow.b$ Requires filtering to prevent external air contamination
- $arrow.b$ Temperature may be difficult to control (malfunction makes temperature go up quickly)



=== Computer Room Air Conditioning (CRAC) Based Cooling
#figure(
  image("../slides/6-energy-management.pdf", page: 48, width: 60%),
)
Closed-loop system consists of two loops
- *Air Circuit*: CRAC $->$ Server $->$ CRAC (Heat Exchanger)
- *Liquid Supply*: CRAC $->$ External Heat Exchanger

*Features*
- $arrow.t$ Easy to implement
- $arrow.t$ Relatively inexpensive
- $arrow.t$ Protection from external contamination
- $arrow.b$ Low operational efficiency
==== Insufficient air flow
Cold air flow from the floor does not match through the servers
#grid(
  columns: (1fr, 1fr), // Two columns, each taking 50% of the available space
  image("../slides/6-energy-management.pdf", page: 49),
  image("../slides/6-energy-management.pdf", page: 50)
)
- limits efficiency (Hot air can circulate)
- Makes some locations to be more efficient than others
- $->$ Lower the temperature (But increases energy costs significantly)

*Solution*: Physically separating cold and hot air
#figure(
  image("../slides/6-energy-management.pdf", page: 52, width: 60%)
)

=== High-Density Cooling
Associate CRAC unit with *rows* of racks or *individual* racks instead of the whole system
- $arrow.t$ Higher power density
- $arrow.t$ Better cooling efficiency
- $arrow.b$ Cooled water needs to be brough to each rack/row/plate $->$ greately increasing cost and complexity
- $arrow.b$ Danger of water leakage
#figure(
  image("../slides/6-energy-management.pdf", page: 54, width: 60%),
)
==== In-Rack Cooling
Add an air-to-water heat exchanger at the *back of the rack*
#figure(
  image("../slides/6-energy-management.pdf", page: 55, width: 60%),
)
==== In-Row Cooling
Cooling unit sit *within rows of racks*
#figure(
  image("../slides/6-energy-management.pdf", page: 56, width: 60%),
)
==== Cold Plates
Direct cool server components using local, liquid-cooled heat sinks
#figure(
  image("../slides/6-energy-management.pdf", page: 57, width: 60%),
)

=== Efficiency of Cooling Subsystem
==== Hardware Perspective
- Physically separate hot and cold air
- Keep path to the cooling unit short
- Elevate temperature of the cold aisle (Equipments can work correctly in higher-than-usual temperatures)
==== Software Perspective
===== Workload Adapted Cooling
- Proactive Adapt cooling to expected workloads
  - e.g. throttle down the cooling when low IT workload is expected in the near future
===== Temperature-Aware Allocation
Consider the resulting temperature of hosts as a criterion to decide allocations
- Power density
  - Spread tasks to balance the load
  - Delay task start (allocate fewer resources) to smooth the load
  - Extend task execution time (DVFS) to smooth the load
- Place hot tasks in the hosts that are *easier to cool*
- Schedule according to the impact of task in the temperature

== Power Supply Subsystem
#figure(
  image("../slides/6-energy-management.pdf", page: 66),
)

=== Uninterruptible Power Supply (UPS)
==== Active Power Input Switch
- Utility grid power
- On-site power
  - Diesel generator (used when utility power fails)
  - Renewable sources (if available)
==== Energy Storage
Bridge the time between *utility failure* and availability of *on-site power*
==== Remove Voltage Spikes
Remove voltage spikes through double conversion, some power efficiency is lost
===== Traditional Double Conversion
Input (AC) $->$ Battery (DC) $->$ Output to PDU (AC)\
State-of-the-art efficiency $~85%$
#figure(
  image("../slides/6-energy-management.pdf", page: 68, width: 80%),
)
===== DC System
System powered by DC, do not convert from DC back to AC\
State-of-the-art efficiency: $~89%$
- $arrow.t$ Slightly higher power efficiency
- $arrow.b$ Higher reliability (*reduced component count*)
- $arrow.t$ Easier integration of native DC output generators
  - Solar photovoltaic, fuel cells, wind turbines
- $arrow.b$ Commercial DC equipment costs more
- $arrow.b$ DC technology in WSCs is less mature
- $arrow.b$ Limited availability of DC technicians
#figure(
  image("../slides/6-energy-management.pdf", page: 68, width: 80%),
)

=== Power Distribution Unit (PDU)
- *Circuit Distribution*: break down input power feed from UPS into smaller circuit to distribute to individual racks
- *Safety*: *Per-Circuit Breaker* to prevent total power failure of the whole PDU or the upstream UPS

=== Renewable Energy
*Follow-the-Renewables* (Follow-the-Sun)
==== Workload Shaping
Adapt IT workload to available energy
- Use DVFS or server power state tuning to adjust *IT power demand* to time-varying *Renewable Energy Budget*
- Use *task scheduling* to postpone tasks when not enough renewable energy is available to execute
==== Efficiency of Energy Usage
- Manage short demand peaks or short-term renewable supply reductions
  - $->$ use stored energy instead of capping the load
- Flatten the WSC load profile
  - Use less utility power when it is most expensive
==== On-site Renewable Generation
*Load Following*: Adapt the amount of energy generated to the expected workload
- Not adequate when workload fluctuates in short-time intervals
  - Requires time to adapt the amount of generated energy
- Combine it with workload shaping
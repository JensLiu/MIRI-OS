// =================== COVER ========================
#set page(numbering: none)
#align(horizon + left)[
  #text(size: 24pt, "Notes for Warehouse-Scale Operating Systems")\
  
  #text("MIRI-OS")
  #v(2em)
  #text(size: 18pt, "Yuechao Liu")\
  #text(size: 12pt, [Universitat Politècnica de Catalunya])
]
#align(bottom + left)[#datetime.today().display()]
#pagebreak()

// =================== OUTLINE ========================
#set document(title: "Operating Systems", author: "Yuechao Liu")
#set page(
  header: [
    _Notes for Warehouse-Scale Operating Systems_
    #h(1fr)
    Yuechao Liu
  ],
  numbering: "1"
)

#outline()
#pagebreak()

// ================== TEXTS =======================
#set math.equation(numbering: "(1)")
#set math.mat(delim: "[")
#set math.vec(delim: "[")
// #set heading(numbering: "1.1")
#set heading(numbering: (..n) => numbering("1.1", ..n.pos().slice(1)))
#show heading.where(level: 1): set text(size: 19pt)
#show heading.where(level: 2): set text(size: 17pt)
#show heading.where(level: 3): set text(size: 15pt)
#show heading.where(level: 4): set text(size: 13pt)

#include "sections/process-scheduling.typ"
#include "sections/process-resilience.typ"
#include "sections/virtualisation.typ"
#include "sections/in-memory-data-management.typ"
#include "sections/on-disk-data-management.typ"
#include "sections/energy-management.typ"
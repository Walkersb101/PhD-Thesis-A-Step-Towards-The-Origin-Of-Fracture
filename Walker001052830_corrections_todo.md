# Thesis corrections checklist

Generated from `Walker001052830_corrections.pdf`. Each source link points to the current likely edit location. Check the contextual extraction if an annotation covers a figure or a broad section.

Progress: **6 / 60 appear addressed in the current source**. Recheck these after rebuilding the thesis PDF.

## Theoretical Framework and Methods

- [x] **C1 · PDF p. 33 · Rheological protocol** — Correct the dashed red stress-response schematic so that it is causal and, after startup, leads the imposed strain as appropriate.  
  Source: [`chapters/2-Background/chapter.tex:226`](chapters/2-Background/chapter.tex#L226)

- [x] **C2 · PDF p. 35 · Oscillatory Strain** — Add one sentence connecting oscillatory deformation to accelerated fatigue testing in materials science, with existing fatigue references.  
  Source: [`chapters/2-Background/chapter.tex:255`](chapters/2-Background/chapter.tex#L255) — appears addressed in the current source; verify in rebuilt PDF

- [x] **C3 · PDF p. 38 · The Navier-Stokes equations** — Rename the subsection “The Navier--Stokes Equations”.  
  Source: [`chapters/2-Background/chapter.tex:315`](chapters/2-Background/chapter.tex#L315) — appears addressed in the current source; verify in rebuilt PDF

- [x] **C4 · PDF p. 39 · Oseen Tensor** — Change “The solution ... is well known” to “Solutions ... are well known”.  
  Source: [`chapters/2-Background/chapter.tex:373`](chapters/2-Background/chapter.tex#L373)

- [x] **C5 · PDF p. 39 · Oseen Tensor** — Rename the subsection “The Oseen Tensor”.  
  Source: [`chapters/2-Background/chapter.tex:372`](chapters/2-Background/chapter.tex#L372)

- [x] **C6 · PDF p. 39 · Oseen Tensor** — Change the associated singular verb “has” to “have” after pluralising “Solutions”.  
  Source: [`chapters/2-Background/chapter.tex:373`](chapters/2-Background/chapter.tex#L373)

- [ ] **C7 · PDF p. 40 · Eshelby Stress Propagator** — Define the local plastic shear event explicitly when it is introduced.  
  Source: [`chapters/2-Background/chapter.tex:421`](chapters/2-Background/chapter.tex#L421)

- [x] **C8 · PDF p. 40 · Oseen Tensor** — Replace “The Oseen tensor is obtained” with “The Fourier transform of the Oseen tensor is obtained”.  
  Source: [`chapters/2-Background/chapter.tex:387`](chapters/2-Background/chapter.tex#L387)

- [x] **C9 · PDF p. 40 · Eshelby Stress Propagator** — Write the local plastic shear as a spatial delta-function field; explain that its amplitude is strain times event area and therefore has dimensions of area.  
  Source: [`chapters/2-Background/chapter.tex:421`](chapters/2-Background/chapter.tex#L421)

- [x] **C10 · PDF p. 41 · Oseen Tensor** — State that the Fourier-transformed plastic event equals the coefficient multiplying the real-space delta function.  
  Source: [`chapters/2-Background/chapter.tex:394`](chapters/2-Background/chapter.tex#L394)

- [x] **C11 · PDF p. 41 · Eshelby Stress Propagator** — Clarify “at the origin” and reconcile the unit event amplitude with the small-strain assumption.  
  Source: [`chapters/2-Background/chapter.tex:446`](chapters/2-Background/chapter.tex#L446)

- [x] **C12 · PDF p. 42 · Eshelby Stress Propagator** — Clarify whether the central element is assigned stress, strain, or both equal to -1, and describe the numerical yielding operation.  
  Source: [`chapters/2-Background/chapter.tex:452`](chapters/2-Background/chapter.tex#L452)

- [x] **C13 · PDF p. 42 · Eshelby Stress Propagator** — Briefly state the numerical method used to calculate the 512×512 propagator. Added inverse-DFT/FFTW3 method and citation.  
  Source: [`chapters/2-Background/chapter.tex:452`](chapters/2-Background/chapter.tex#L452)

- [x] **C14 · PDF p. 62 · Packing-Derived Networks** — Add a short comment on whether bidispersity imposes structure and how a polydisperse construction might differ. Added a caveat on discrete length scales, short-range structure, and the likely effects of continuous polydispersity.  
  Source: [`chapters/2-Background/chapter.tex:729`](chapters/2-Background/chapter.tex#L729)

- [x] **C15 · PDF p. 63 · Pruning Networks** — Define the pruning rule more precisely, including whether removal is deterministic or probabilistic among candidate bonds.  
  Source: [`chapters/2-Background/chapter.tex:758`](chapters/2-Background/chapter.tex#L758)

- [x] **C16 · PDF p. 65 · Generalised Lees--Edwards Boundary Conditions** — Explain why the Lees--Edwards construction is described as “generalised”, or remove that adjective.  
  Source: [`chapters/2-Background/chapter.tex:803`](chapters/2-Background/chapter.tex#L803)

- [x] **C17 · PDF p. 66 · Generalised Lees--Edwards Boundary Conditions** — Explain why Lees--Edwards boundary conditions are needed for a bond-breaking network with no bond reconnection.  
  Source: [`chapters/2-Background/chapter.tex:830`](chapters/2-Background/chapter.tex#L830)

## Absorption and Failure in Oscillatory Shear

- [ ] **C18 · PDF p. 72 · Introduction** — Split or simplify the long sentence contrasting metallic glasses with softer amorphous solids.  
  Source: [`chapters/Fatigue/chapter.tex:21`](chapters/Fatigue/chapter.tex#L21)

- [ ] **C19 · PDF p. 73 · Introduction** — Mention accelerated lifetime/fatigue testing in the oscillatory-shear introduction, reusing existing fatigue references.  
  Source: [`chapters/Fatigue/chapter.tex:29`](chapters/Fatigue/chapter.tex#L29)

- [ ] **C20 · PDF p. 74 · Introduction** — Check the grammar around “dynamics associated”; add a comma only if the phrase is parenthetical.  
  Source: [`chapters/Fatigue/chapter.tex:35`](chapters/Fatigue/chapter.tex#L35)

- [ ] **C21 · PDF p. 74 · Introduction** — Move the periodically driven suspensions/colloids paragraph earlier so it follows the discussion of reversible and irreversible states.  
  Source: [`chapters/Fatigue/chapter.tex:35`](chapters/Fatigue/chapter.tex#L35)

- [ ] **C22 · PDF p. 78 · Methodology** — Credit Pollard and Fielding when introducing the base elastoplastic model.  
  Source: [`chapters/Fatigue/chapter.tex:63`](chapters/Fatigue/chapter.tex#L63)

- [ ] **C23 · PDF p. 79 · Methodology** — Explain or qualify the assumption of affine loading between plastic events; cite prior model work if available.  
  Source: [`chapters/Fatigue/chapter.tex:79`](chapters/Fatigue/chapter.tex#L79)

- [ ] **C24 · PDF p. 79 · Methodology** — Add a sentence explaining how the unit yielding strain is compatible with the small-strain formulation.  
  Source: [`chapters/Fatigue/chapter.tex:83`](chapters/Fatigue/chapter.tex#L83)

- [ ] **C25 · PDF p. 86 · Shear Startup** — State explicitly that convergence of the shear-startup response as N→∞ remains an open question and qualify any interpretation.  
  Source: [`chapters/Fatigue/chapter.tex:182`](chapters/Fatigue/chapter.tex#L182)

- [ ] **C26 · PDF p. 88 · Oscillatory shear results** — Explain whether the conclusions depend on Gaussian tails and why a Gaussian initial distribution is appropriate.  
  Source: [`chapters/Fatigue/chapter.tex:208`](chapters/Fatigue/chapter.tex#L208)

- [ ] **C27 · PDF p. 94 · Oscillatory shear results** — Reword the claim about long-lived failing trajectories so it agrees with the plotted absorption and yielding cycle counts.  
  Source: [`chapters/Fatigue/chapter.tex:264`](chapters/Fatigue/chapter.tex#L264)

- [ ] **C28 · PDF p. 95 · Oscillatory shear results** — Define the survival function before first using it.  
  Source: [`chapters/Fatigue/chapter.tex:266`](chapters/Fatigue/chapter.tex#L266)

- [ ] **C29 · PDF p. 95 · Oscillatory shear results** — Move the formal definition of the survival function to its first mention.  
  Source: [`chapters/Fatigue/chapter.tex:278`](chapters/Fatigue/chapter.tex#L278)

- [ ] **C30 · PDF p. 99 · Robustness to $$ and $N$** — Add a legend identifying the curves for each post-hop width l_w.  
  Source: [`chapters/Fatigue/chapter.tex:310`](chapters/Fatigue/chapter.tex#L310)

- [x] **C31 · PDF p. 101 · Robustness to $$ and $N$** — Add a legend identifying the curves for each system size N.  
  Source: [`chapters/Fatigue/chapter.tex:328`](chapters/Fatigue/chapter.tex#L328) — appears addressed in the current source; verify in rebuilt PDF

- [ ] **C32 · PDF p. 103 · Robustness to $$ and $N$** — Qualify the N→∞ extrapolation and state that the limited system-size range makes 0.78 unreliable.  
  Source: [`chapters/Fatigue/chapter.tex:370`](chapters/Fatigue/chapter.tex#L370)

- [ ] **C33 · PDF p. 105 · Path to a Single Active Element** — State the value of γ₀ corresponding to each decay curve.  
  Source: [`chapters/Fatigue/chapter.tex:393`](chapters/Fatigue/chapter.tex#L393)

- [ ] **C34 · PDF p. 105 · Path to a Single Active Element** — Check why all plotted curves appear to end at C*=200 and extend or explain the y-axis range.  
  Source: [`chapters/Fatigue/chapter.tex:393`](chapters/Fatigue/chapter.tex#L393)

- [ ] **C35 · PDF p. 108 · Path to a Single Active Element** — Elaborate on the condition under which an element yields again on the next half-cycle.  
  Source: [`chapters/Fatigue/chapter.tex:434`](chapters/Fatigue/chapter.tex#L434)

- [ ] **C36 · PDF p. 108 · Path to a Single Active Element** — Explain the evolution of the local strain over a full cycle, first for zero post-hop noise and then with noise; state when one or both half-cycles yield and when absorption occurs.  
  Source: [`chapters/Fatigue/chapter.tex:434`](chapters/Fatigue/chapter.tex#L434)

- [ ] **C37 · PDF p. 113 · The Dilute Model** — Describe how the dilute-model data in Fig. 3.15 were generated, including simulation procedure and parameters.  
  Source: [`chapters/Fatigue/chapter.tex:494`](chapters/Fatigue/chapter.tex#L494)

- [x] **C38 · PDF p. 114 · The Dilute Model** — Clarify that the full-model curves include only trajectories ending in absorption, if that is the case.  
  Source: [`chapters/Fatigue/chapter.tex:506`](chapters/Fatigue/chapter.tex#L506) — appears addressed in the current source; verify in rebuilt PDF

## Ultradelayed Fracture After Step Strain

- [x] **C39 · PDF p. 122 · Introduction** — Broaden the motivation with an example of long-delayed failure from materials science, such as environmental stress cracking in polymers.  
  Source: [`chapters/UltraDelayedFracture/chapter.tex:43`](chapters/UltraDelayedFracture/chapter.tex#L43) — appears addressed in the current source; verify in rebuilt PDF

- [ ] **C40 · PDF p. 122 · Introduction** — State the network preparation method and coordination z used throughout the chapter.  
  Source: [`chapters/UltraDelayedFracture/chapter.tex:34`](chapters/UltraDelayedFracture/chapter.tex#L34)

- [x] **C41 · PDF p. 125 · Introduction** — Replace or supplement the SGR citation with existing literature on thermally activated bond-breaking models; avoid implying SGR is the primary origin.  
  Source: [`chapters/UltraDelayedFracture/chapter.tex:52`](chapters/UltraDelayedFracture/chapter.tex#L52) — appears addressed in the current source; verify in rebuilt PDF

- [ ] **C42 · PDF p. 126 · Rate Dependent Fracture** — Optionally note that a Gillespie-style event-driven algorithm could improve computational efficiency.  
  Source: [`chapters/UltraDelayedFracture/chapter.tex:126`](chapters/UltraDelayedFracture/chapter.tex#L126)

- [ ] **C43 · PDF p. 127 · Rate Dependent Fracture** — Explain that parameters are tuned to access a narrow non-trivial regime, while most parameter choices give rapid failure or no failure.  
  Source: [`chapters/UltraDelayedFracture/chapter.tex:134`](chapters/UltraDelayedFracture/chapter.tex#L134)

- [ ] **C44 · PDF p. 128 · Stress Response** — State the network preparation method and z value for these results.  
  Source: [`chapters/UltraDelayedFracture/chapter.tex:139`](chapters/UltraDelayedFracture/chapter.tex#L139)

- [ ] **C45 · PDF p. 132 · Stress Response** — Write log(t*)∼1/T or, dimensionally, t*∼exp(A/T) with an activation parameter A.  
  Source: [`chapters/UltraDelayedFracture/chapter.tex:184`](chapters/UltraDelayedFracture/chapter.tex#L184)

- [ ] **C46 · PDF p. 133 · Stress Response** — Consider extracting and reporting an apparent activation energy from the temperature dependence.  
  Source: [`chapters/UltraDelayedFracture/chapter.tex:189`](chapters/UltraDelayedFracture/chapter.tex#L189)

- [ ] **C47 · PDF p. 135 · Low Strain Regime** — Check panel (d): relabel it as the number of broken bonds if it is not a fraction.  
  Source: [`chapters/UltraDelayedFracture/chapter.tex:213`](chapters/UltraDelayedFracture/chapter.tex#L213)

- [ ] **C48 · PDF p. 144 · Direction of Fracture Propagation** — Do not call this a failure mechanism until the mechanism has been explained; rephrase or add the missing explanation.  
  Source: [`chapters/UltraDelayedFracture/chapter.tex:349`](chapters/UltraDelayedFracture/chapter.tex#L349)

- [ ] **C49 · PDF p. 145 · Direction of Fracture Propagation** — Swap panel labels (a) and (b); consider adding affinely deformed-state panels showing maximally stretched bond directions and their perpendiculars.  
  Source: [`chapters/UltraDelayedFracture/chapter.tex:354`](chapters/UltraDelayedFracture/chapter.tex#L354)

- [ ] **C50 · PDF p. 146 · Conclusion** — Add any defensible qualitative or quantitative comparison with Lockwood et al. beyond the generic observation of delayed fracture.  
  Source: [`chapters/UltraDelayedFracture/chapter.tex:368`](chapters/UltraDelayedFracture/chapter.tex#L368)

## Toughness of Double-Network Materials

- [ ] **C51 · PDF p. 156 · Toughness of Double Network Hydrogels** — Reframe the chapter against fracture-toughness literature: compare the double network with both constituent single networks and discuss crack-tip damage zones and missing multiscale crack propagation.  
  Source: [`chapters/DoubleNetworkFracture/chapter.tex:4`](chapters/DoubleNetworkFracture/chapter.tex#L4)

- [ ] **C52 · PDF p. 160 · Packing-Derived Double Networks** — Explain what was done operationally to “ensure a homogeneous distribution”, or remove “taking care”.  
  Source: [`chapters/DoubleNetworkFracture/chapter.tex:40`](chapters/DoubleNetworkFracture/chapter.tex#L40)

- [ ] **C53 · PDF p. 165 · Stress-Strain Response** — Correct the comparison: double networks can have greater toughness and failure strain than either constituent single network.  
  Source: [`chapters/DoubleNetworkFracture/chapter.tex:90`](chapters/DoubleNetworkFracture/chapter.tex#L90)

- [ ] **C54 · PDF p. 167 · Stress-Strain Response** — Revisit criterion I against Ref. 28 and the much larger experimental failure strains of double networks.  
  Source: [`chapters/DoubleNetworkFracture/chapter.tex:126`](chapters/DoubleNetworkFracture/chapter.tex#L126)

- [ ] **C55 · PDF p. 171 · Stress Propagation** — Explain why the double network is tougher than a matrix-only single network, not only why it outperforms the sacrificial network.  
  Source: [`chapters/DoubleNetworkFracture/chapter.tex:182`](chapters/DoubleNetworkFracture/chapter.tex#L182)

- [ ] **C56 · PDF p. 173 · Stress Propagation** — Include the matrix-only single network in the stress-propagation comparison or explain the limitation.  
  Source: [`chapters/DoubleNetworkFracture/chapter.tex:202`](chapters/DoubleNetworkFracture/chapter.tex#L202)

- [ ] **C57 · PDF p. 177 · Conclusion** — Reframe the conclusion around why the double network outperforms the matrix-only network as well as the sacrificial network.  
  Source: [`chapters/DoubleNetworkFracture/chapter.tex:251`](chapters/DoubleNetworkFracture/chapter.tex#L251)

- [ ] **C58 · PDF p. 177 · Conclusion** — Discuss whether moving from two to three dimensions is expected to alter the conclusions.  
  Source: [`chapters/DoubleNetworkFracture/chapter.tex:253`](chapters/DoubleNetworkFracture/chapter.tex#L253)

- [ ] **C59 · PDF p. 178 · Conclusion** — Discuss how entropic elasticity in real gels may change the model predictions.  
  Source: [`chapters/DoubleNetworkFracture/chapter.tex:255`](chapters/DoubleNetworkFracture/chapter.tex#L255)

- [ ] **C60 · PDF p. 180 · Conclusion** — Qualify the claim that the model isolates the “key” fracture mechanisms and relate it to pre-notched fracture-toughness tests and large crack-tip damage zones.  
  Source: [`chapters/DoubleNetworkFracture/chapter.tex:274`](chapters/DoubleNetworkFracture/chapter.tex#L274)

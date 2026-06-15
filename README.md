[![DOI](https://zenodo.org/badge/1231940751.svg)](https://doi.org/10.5281/zenodo.20073076)
# Sci Cave Diving Planner

A robust, conservative gas management dive planning tool designed specifically for scientific cave diving operations. Decompression calculations for each dive must be supplemented with these calculations. This project provides both an R script (`bt_S4_Eng.R`) and a standalone Web App (`.html`) to calculate critical gas management metrics, ascent profiles, and turn pressures.

It is specifically tailored for scenarios where penetration speeds are significantly slower than exit speeds due to sampling or scientific data collection tasks (Strategy 4, Cave sampling).

## 1. Variables Dictionary

### Input Parameters
The following parameters are required to generate a dive profile:

| Variable | Definition | Unit |
| :--- | :--- | :--- |
| **Tvol** | Cylinder capacity / internal volume. | Litres |
| **Fp** | Fill pressure of the cylinder before the dive. | BAR |
| **Dmax** | Maximum depth of the dive. | Metres (m) |
| **Dad** | Average bottom depth. Defaults to **Dmax** for maximum conservatism if unknown. | Metres (m) |
| **Pn** | Penetration distance (the furthest linear distance into the cave). | Metres (m) |

### Constants & Safety Margins
These values are established to ensure a high safety margin during scientific operations:

| Variable | Definition | Value / Unit |
| :--- | :--- | :--- |
| **SCR** | Standard Surface Consumption Rate (relaxed breathing). | 20 L/min |
| **SCRs** | Stressed Surface Consumption Rate (emergency/panic breathing). | 30 L/min |
| **vh** | Cave exit swimming speed. | 0.5 m/s |
| **vd** | Descent rate. Standard recreational/technical reference value. |18 m/min |

### Output Metrics
Results provided for the execution of the dive plan:

| Variable | Definition | Unit | Strategies |
| :--- | :--- | :--- | :--- |
| **Stop Half Depth** | The halfway depth where ascent speed transitions from 9 m/min to 3 m/min. | Metres (m) | All |
| **MG** | Minimum Gas. The absolute reserve required for two divers to safely ascend. | BAR | All |
| **UG** | Usable Gas. Total gas available before touching the minimum reserve. | BAR | All |
| **TP** | Turn Pressure. The gauge pressure at which the diver must exit. | BAR | All |
| **Tb** | Bottom Time. Maximum time allowed before starting ascent. | Minutes (min) | All |
| **Tw** |Working Time. Effective sampling time inside the cave, after subtracting descent and exit travel times from Bottom Time. | Minutes (min) | Cave sampling only |
| **Tas** | Total Ascent Time from starting ascent to the surface. | Minutes (min) | All |

---

## 2. Penetration Strategies

* **Strategy 1 (All Available Gas):** Uses all gas down to the Minimum Gas limit. **Not suitable for overhead environments**.
* **Strategy 2 (Rule of Halves):** 50% for the first leg, 50% for the return leg. **Not suitable for cave diving**.
* **Strategy 3 (Rule of Thirds - GUE Standard):** Standard cave protocol adhering to the Global Underwater Explorers (GUE) mathematical framework. It calculates a pure third of the total cylinder pressure for penetration. If this third does not leave sufficient gas to cover the absolute Minimum Gas emergency reserve, the algorithm dynamically switches to the Rule of Halves on the usable gas, guaranteeing symmetric inbound and outbound phases without compromising emergency reserves.
* **Strategy 4 (Cave Sampling):** Specifically designed for scientific cave diving. Accounts for slow inbound penetration (data collection) and faster direct exit. Calculates Turn Pressure based on actual exit distance and emergency gas-sharing scenarios, and provides Working Time to estimate effective sampling duration.

---

## 3. Mathematical Foundations

The planner employs a conservative algorithmic approach. All calculations are performed in **Absolute Atmosphere (ATA)** before conversion to **BAR**.

### 3.1. Pressure Constants
* **Max Pressure ($P_{max}$):** $(D_{max}/10) + 1$
* **Average Bottom Pressure ($P_{ad}$):** $(D_{ad}/10) + 1$
* **Average Ascent Pressure ($P_{av}$):** $\left((D_{max} / 2) / 10\right) + 1$

### 3.2. Ascent Profile: Stop Half Depth
The ascent manages off-gassing by transitioning speeds at the **Stop Half Depth** ($D_{shd}$), half of the maximum dive depth:
$$D_{shd} = \lceil (D_{max} / 2) / 3 \rceil \times 3$$
*This value is rounded up to the nearest multiple of 3 metres for conservatism and ease of procedure*.

* **Phase 1 (Bottom to $D_{shd}$):** Ascent at **9 m/min**. $t_{stop1} = \lceil (D_{max} - D_{shd}) / 9 \rceil$
* **Phase 2 ($D_{shd}$ to Surface):** Ascent at **3 m/min**. $t_{surface} = D_{shd} / 3$
* **Total Ascent Time ($T_{as}$):** $\lceil t_{stop1} + t_{surface} \rceil$

### 3.3. Gas Reserves and Availability
* **Minimum Gas ($MG$):** Reserve for two divers sharing air under stress from the start of the ascent to the surface.
    $$mG = \frac{SCR_s \times P_{av} \times T_{as} \times 2}{T_{vol}}$$
    *Rounded up to the nearest 10 BAR*.

* **Usable Gas ($UG$):** $F_p - mG$.
    *Rounded down to the nearest 10 BAR*.

### 3.4. Turn Pressure ($TP$) Logic

For **Strategy 3 (Rule of Thirds - GUE Standard)**, the algorithm evaluates the safety of a geometric third:
1. **Pure Thirds Check:** Calculate one third of the total fill pressure ($F_p / 3$).
2. **Turn Pressure:** * If $(F_p / 3) \geq MG$, then $TP = \lceil F_p - (F_p / 3) \rceil_{10}$. 
   * If $(F_p / 3) < MG$, it falls back to the Rule of Halves on the usable gas: $TP = \lceil F_p - ((F_p - MG) / 2) \rceil_{10}$.

For **Strategy 4 (Cave Sampling)**, $TP$ accounts for the specific exit requirements:
1. **Exit Gas Consumption ($sG$):** Gas for two divers to swim distance $P_n$ at speed $v_h$.
    $$sG = \frac{ \left(\frac{P_n}{v_h \times 60}\right) \times SCR_s \times P_{ad} }{T_{vol}}$$
2. **Turn Pressure:**
    $$TP = \lceil \frac{1}{3}UG + MG + 2 \times sG \rceil_{10}$$
    *This ensures enough gas for an emergency for two divers sharing gas at the furthest point*.

### 3.5. Bottom Time ($T_b$) and Working Time ($T_w$)

**Bottom Time** is defined as the time elapsed from the start of descent until the diver reaches the Turn Pressure. It is the operationally relevant time for decompression table calculations and is consistent across all four strategies:

$$T_b = \left\lfloor \frac{(F_p - TP) \times T_{vol}}{SCR \times P_{ad}} \right\rfloor$$

**Working Time** (Strategy 4 only) is the effective time available for sampling inside the cave, after subtracting the time required to descend to depth and to exit from the point of maximum penetration:

$$T_w = \max\left(0,\ T_b - T_{descent} - T_{exit}\right)$$

Where:
* $T_{descent} = \lceil D_{max} / v_d \rceil$ — time to descend to maximum depth at $v_d = 18$ m/min.
* $T_{exit} = \lceil (P_n / v_h) / 60 \rceil$ — time to swim from maximum penetration to the cave entrance at exit speed $v_h$.

A Working Time of 0 indicates that the dive profile is operationally marginal — the cylinder size or fill pressure should be increased, or the penetration distance reduced.


### 3.6. Dive Viability Assessment

After computing the Turn Pressure and Bottom Time, the planner automatically evaluates whether the planned profile is operationally viable. The assessment applies three sequential checks, in order of severity. Checks 2 and 3 apply only to confined-environment strategies (Rule of Thirds and Cave sampling); they are not applied to Strategies 1 and 2, which are designed for open-water dives where no cave penetration is involved.

**Check 1 — Turn Pressure exceeds fill pressure ($TP > F_p$):**
The computed Turn Pressure is greater than the available gas. This occurs when the penetration distance or depth is too large for the cylinder size and fill pressure. The profile is **not viable** regardless of strategy.

**Check 2 — Turn Pressure within minimum gas reserve ($TP \leq MG$, Strategies 3–4 only):**
The Turn Pressure falls at or below the emergency ascent reserve. There is no usable inbound gas. The profile is **not viable**.

**Check 3 — Descent gas exceeds inbound gas ($G_{descent} \geq F_p - TP$, Strategies 3–4 only):**
The gas consumed during the descent to maximum depth equals or exceeds the gas available for the inbound phase. The diver would reach Turn Pressure before arriving at the bottom of the cave, making sampling impossible. This is the most operationally relevant check for deep caves with large penetration distances.

$$G_{descent} = \frac{SCR \times P_{ad} \times T_{descent}}{T_{vol}}$$

If $G_{descent} \geq (F_p - TP)$, the profile is **not viable**.

**Viability classification:**

| Verdict | Condition | Recommended action |
| :--- | :--- | :--- |
| ✅ **Viable** | All checks pass and inbound gas fraction $\geq$ 25% of usable gas | Proceed with the planned profile |
| ⚠️ **Viable, but very restrictive** | All checks pass but inbound gas fraction $<$ 25% of usable gas | Consider a larger cylinder or higher fill pressure |
| ❌ **Not viable** | Any of the three checks above fails | Do not attempt this profile with the current equipment |

The 25% threshold for the inbound gas fraction is defined as:

$$\text{Inbound fraction} = \frac{F_p - TP}{F_p - MG}$$

When this fraction falls below 0.25, the diver has less than one quarter of the usable gas available for the inbound phase, which is operationally insufficient for meaningful scientific cave sampling.

---

## 4. Usage
This planner is provided for research and educational purposes. Always verify your plans with alternative calculations and combine these results with decompression tables. 

### Web App Portability
The tool includes a standalone HTML web app designed for maximum flexibility in field research environments:

* **Cross-Platform:** The app runs on desktop computers, laptops, tablets, and smartphones.
* **Offline Access:** It is designed to function entirely without an internet connection. This makes it ideal for use on dive boats or remote field sites where connectivity is unavailable.
* **Mobile Execution:** To use it on a mobile device, simply download the file `scicavedive_planner_v1_0_0.html` to your device's storage. You can open the file directly using any standard web browser (e.g., Chrome, Safari, Firefox) without needing mobile data or Wi-Fi.
* **Pre-Dive Planning:** Its offline nature allows for quick, last-minute adjustments to the dive plan at the water's edge or on the vessel just before the immersion.

**Developed by:** Yeray Gonzalez-Marrero
[![DOI](https://zenodo.org/badge/1231940751.svg)](https://doi.org/10.5281/zenodo.20073076)
# Sci Cave Dive Planner

A robust, conservative dive planning tool designed specifically for scientific cave diving operations. This project provides both an R script (`bt_S4_Eng.R`) and a standalone Web App (`.html`) to calculate critical gas management metrics, ascent profiles, and turn pressures.

It is specifically tailored for scenarios where penetration speeds are significantly slower than exit speeds due to sampling or scientific data collection tasks.

## 1. Variables Dictionary

### Input Parameters
The following parameters are required to generate a dive profile:

| Variable | Definition | Unit |
| :--- | :--- | :--- |
| **Tvol** | Tank capacity / internal volume. | Litres |
| **Fp** | Fill pressure of the tank before the dive. | BAR |
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

### Output Metrics
Results provided for the execution of the dive plan:

| Variable | Definition | Unit |
| :--- | :--- | :--- |
| **Stop Half Depth** | The halfway depth where ascent speed transitions from 9 m/min to 3 m/min. | Metres (m) |
| **MG** | Minimum Gas. The absolute reserve required for two divers to safely ascend. | BAR |
| **UG** | Usable Gas. Total gas available before touching the minimum reserve. | BAR |
| **TP** | Turn Pressure. The gauge pressure at which the diver must exit. | BAR |
| **Tb** | Bottom Time. Maximum time allowed before reaching Turn Pressure. | Minutes (min) |
| **Tas** | Total Ascent Time. | Minutes (min) |

---

## 2. Penetration Strategies

* **Strategy 1 (All Available Gas):** Uses all gas down to the Minimum Gas limit. **Not suitable for overhead environments.**
* **Strategy 2 (Rule of Halves):** 50% for penetration, 50% for exit. **Not suitable for cave diving.**
* **Strategy 3 (Rule of Thirds):** Standard cave protocol (1/3 in, 1/3 out, 1/3 reserve). Assumes equal speeds.
* **Strategy 4 (Sampling Strategy):** Specifically for scientific diving. It accounts for slow penetration (sampling) and faster emergency exits. It calculates turn pressure based on distance and emergency scenarios.

---

## 3. Mathematical Foundations

The planner employs a conservative algorithmic approach. All calculations are performed in **Absolute Atmosphere (ATA)** before conversion to **BAR**.

### 3.1. Pressure Constants
* **Max Pressure ($P_{max}$):** $(D_{max}/10) + 1$
* **Average Bottom Pressure ($P_{ad}$):** $(D_{ad}/10) + 1$
* **Average Ascent Pressure ($P_{av}$):** $\left((D_{max} / 2) / 10\right) + 1$

### 3.2. Ascent Profile: Stop Half Depth
The ascent manages off-gassing by transitioning speeds at the **Stop Half Depth** ($D_{shd}$):
$$D_{shd} = \lceil (D_{max} / 2) / 3 \rceil \times 3$$
*This value is rounded up to the nearest multiple of 3 metres for conservatism and ease of procedure.*

* **Phase 1 (Bottom to $D_{shd}$):** Ascent at **9 m/min**. $t_{stop1} = \lceil (D_{max} - D_{shd}) / 9 \rceil$
* **Phase 2 ($D_{shd}$ to Surface):** Ascent at **3 m/min**. $t_{surface} = D_{shd} / 3$
* **Total Ascent Time ($T_{as}$):** $\lceil t_{stop1} + t_{surface} \rceil$

### 3.3. Gas Reserves and Availability
* **Minimum Gas ($MG$):** Reserve for two divers sharing air under stress.
    $$mG = \frac{SCR_s \times P_{av} \times T_{as} \times 2}{T_{vol}}$$
    *Rounded up to the nearest 10 BAR.*

* **Usable Gas ($UG$):** $F_p - mG$.
    *Rounded down to the nearest 10 BAR.*

### 3.4. Turn Pressure ($TP$) Logic
For **Strategy 4 (Sampling)**, $TP$ accounts for the specific exit requirements:
1. **Exit Gas Consumption ($sG$):** Gas for two divers to swim distance $P_n$ at speed $v_h$.
    $$sG = \frac{ \left(\frac{P_n}{v_h \times 60}\right) \times SCR_s \times P_{ad} }{T_{vol}}$$
2. **Turn Pressure:**
    $$TP = \lceil \frac{1}{3}UG + MG + 2 \times sG \rceil_{10}$$
    *This ensures enough gas for an emergency (air loss + lost guideline) at the furthest point.*

---

## 4. Usage
This planner is provided for research and educational purposes. Always verify your plans with established decompression tables and secondary software.

### Web App Portability
The tool includes a standalone HTML web app designed for maximum flexibility in field research environments:

* **Cross-Platform:** The app runs on desktop computers, laptops, tablets, and smartphones.
* **Offline Access:** It is designed to function entirely without an internet connection. This makes it ideal for use on dive boats or remote field sites where connectivity is unavailable.
* **Mobile Execution:** To use it on a mobile device, simply download the file `scicavedive_planner_v1_0_0.html` to your device's storage. You can open the file directly using any standard web browser (e.g., Chrome, Safari, Firefox) without needing mobile data or Wi-Fi.
* **Pre-Dive Planning:** Its offline nature allows for quick, last-minute adjustments to the dive plan at the water's edge or on the vessel just before the immersion.

**Developed by:** Yeray Gonzalez-Marrero  


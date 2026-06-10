#!/usr/bin/env Rscript
# BOTTOM TIME
# Goal: Calculates the bottom time for a given tank volume, tank fill pressure, max bottom depth, average bottom depth and penetration strategy.

rm(list=ls()) # Clear workspace  
graphics.off() 
# Libraries
library(dplyr)

# ── Helper: safe readline wrapper ──────────────────────────────────────────
# readline() fails when called via source() in RStudio because the connection
# is not interactive. This wrapper falls back to readLines(con = stdin(), n = 1)
# which works in both interactive and sourced contexts.
safe_readline <- function(prompt = "") {
  cat(prompt)
  if (interactive()) {
    return(readline(""))
  } else {
    return(readLines(con = stdin(), n = 1))
  }
}

cat("SCIENTIFIC CAVE DIVE PLANNING\n")
Tvol      <- safe_readline("What is the tank capacity (litres)? ")
Fp        <- safe_readline("What is the tank fill pressure (BAR)? ")
Dmax      <- safe_readline("What is the maximum depth of the dive (m)? ")
ask_depth <- safe_readline("Do you know the average depth of the bottom profile? (Yes/No) ")

if (tolower(trimws(ask_depth)) %in% c("no", "n")) {
  Dad <- Dmax
} else {
  Dad <- safe_readline("Enter the average depth of the bottom profile (m): ")
}

Pn <- safe_readline("What is the maximum penetration distance (m) into the dive? ")

# Transformations -------------------------------------------------------
Tvol <- as.numeric(Tvol)
Fp   <- as.numeric(Fp)
Dmax <- as.numeric(Dmax)
Dad  <- as.numeric(Dad)
Pn   <- as.numeric(Pn)

# Input validation -------------------------------------------------------
if (Dad > Dmax) {
  stop(paste0(
    "ERROR: Average bottom depth (", Dad, " m) cannot be greater than ",
    "maximum depth (", Dmax, " m). ",
    "Please re-run the script and enter a valid average depth."
  ))
}

# VARIABLES ---------------------------------------------------------------
S <- 4 # Strategy S=4 cave with sampling; S=3 cave where penetration speed equals exit speed.

Pmax <- (Dmax/10)+1
Pad  <- (Dad/10)+1

SCR  <- 20  # Surface consumption rate (litres/min). Can be adjusted for a specific diver.
SCRs <- 30  # Stressed consumption rate (litres/min). Can be adjusted for a specific diver.
vh   <- 0.5 # Cave exit speed (m/s)
vd   <- 18  # Descent rate (m/min) — standard recreational/technical reference value

Pav <- ((Dmax/2)/10) + 1

# Time
t_stamp <- timestamp()

# Rounding down function (nearest 10)
floor_10 <- function(x, level=-1) ifelse(x %% 10 == 0, x, (round(x - 5*10^(-level-1), level)))
# Rounding up function (nearest 10)
ceil_10  <- function(x, level=-1) ifelse(x %% 10 == 0, x, (round(x + 5*10^(-level-1), level)))
# Rounding up to multiples of 3
round_any.numeric <- function(x, accuracy, f = round) { 
  f(x / accuracy) * accuracy
}

# Calculate Average depth  
Dav <- (Dmax/2)

# Stops -----------------------------------------------------------------
Dstop1 <- round_any.numeric(Dav, 3, ceiling) # Round up Dav to a multiple of 3.
tstop1 <- ceiling((Dmax - Dstop1) / 9)       # Time from bottom to half-depth stop (9 m/min)

b   <- Dstop1 / 3                              # Ascent time from stop to surface (3 m/min)
Tas <- ceiling(tstop1 + b)                    # Total ascent time

D_stop <- 3 # Depth change between stops
I_stop <- 1 # Time increment between stops

# Gas calculations --------------------------------------------------------

# Minimum gas calculation in BAR — round UP immediately and propagate rounded value
# (consistent with HTML: MG is used in all downstream calculations for safety)
mG_exact <- (SCRs * Pav * Tas * 2) / Tvol
MG       <- ceil_10(mG_exact, -1)  # MG = rounded-up mG (used in all downstream calcs)

# Usable gas in BAR — uses rounded MG to be conservative
uG_exact <- Fp - mG_exact           # exact (for reference only)
UG       <- floor_10(Fp - MG, -1)  # UG = floor(Fp - MG), consistent with HTML

# Turn pressure 
if (S==1 || S==2 || S==3) {
  TP <- ceil_10(Fp - (UG / S))
} else {
  # Consumption in BAR to exit the cave
  sG <- (((Pn/vh)/60)*SCRs*Pad)/Tvol
  # TP is less conservative than the rule of thirds because penetration time is greater
  # than return time (sampling is done on the way in, exit is just leaving). 
  # Calculated to allow two divers to exit to the surface with a single tank during an accident
  # in the maximum penetration zone, plus adding one third of usable gas (rule of thirds).
  # Scenario for 2 problems: out of air diver + e.g., lost guideline.
  # NOTE: If penetration speed = exit speed (normal caving), set S=3
  TP <- ceil_10(1/3 * UG + MG + 2 * sG)
}

# Bottom Time: time from start of descent to start of ascent (= time until Turn Pressure)
# Calculated as the time to consume (Fp - TP) BAR at SCR at average depth
Tb <- floor(((Fp - TP) * Tvol) / (SCR * Pad))

# Working Time (S=4 only): effective sampling time inside the cave
# T_working = Tb - T_descent - T_exit
# T_descent = time to reach Dmax at vd m/min
# T_exit    = time to swim from max penetration to cave entrance at vh m/s
T_descent <- ceiling(Dmax / vd)  # always calculated for reference
if (S == 4) {
  T_exit    <- ceiling((Pn / vh) / 60)         # minutes to exit from max penetration
  T_working <- max(0, Tb - T_descent - T_exit) # effective working time (cannot be negative)
} else {
  T_exit    <- NA
  T_working <- NA
}

# Dive viability assessment -----------------------------------------------
# Zone classification based on where TP falls relative to mG and Fp
if (TP > Fp || Tb < 0) {
  viability <- "NOT VIABLE: Turn Pressure exceeds fill pressure. Use a larger cylinder, higher fill pressure, or reduce penetration distance."
  viability_flag <- "IMPOSSIBLE"
} else if (TP <= MG) {
  viability <- "NOT VIABLE: Turn Pressure falls within the minimum gas reserve. Use a larger cylinder, higher fill pressure, or reduce penetration distance."
  viability_flag <- "IMPOSSIBLE"
} else {
  inbound_gas      <- Fp - TP
  total_usable_gas <- Fp - MG
  inbound_fraction <- inbound_gas / total_usable_gas
  if (inbound_fraction >= 0.25) {
    viability      <- "Viable dive."
    viability_flag <- "VIABLE"
  } else {
    viability      <- "Viable dive, but very restrictive. Consider a larger cylinder or higher fill pressure."
    viability_flag <- "RESTRICTIVE"
  }
}

# Print viability immediately so the diver sees it before the full results table
cat("\n")
cat("=== DIVE VIABILITY ASSESSMENT ===\n")
cat(viability, "\n")
if (S == 4 && viability_flag != "IMPOSSIBLE") {
  cat("Estimated working time:", T_working, "min\n")
}
cat("=================================\n\n")

# Stop execution for impossible profiles to prevent misleading output
if (viability_flag == "IMPOSSIBLE") {
  stop("Dive profile is not viable with the current equipment. See viability message above.")
}

# 1/3 of Usable Gas
terc_UG <- round(UG/3, 0)

if (S==1) {
  strategy_name <- "All available gas"
} else if (S==2) {
  strategy_name <- "Rule of halves"
} else if (S==3) {
  strategy_name <- "Rule of thirds"
} else if (S==4) {
  strategy_name <- "Cave with sampling"
}

## Parameters matrix
p <- matrix(c(t_stamp, Fp, Dmax, Dad, Pn, strategy_name, SCR, SCRs, vd), ncol=9, byrow=TRUE)
rownames(p) <- c("Parameters")
colnames(p) <- c("Date/Time", "Fill pressure (BAR)", "Max depth (m)", "Average bottom depth (m)",
                 "Penetration depth (m)", "Strategy", "SCR (litres/min)",
                 "Stressed SCR (litres/min)", "Descent rate (m/min)")

# Results matrix — includes Working Time for S=4, NA otherwise
if (S == 4) {
  res <- matrix(c(Tb, T_working, MG, TP, UG, terc_UG, Tas, Dstop1, tstop1, D_stop, I_stop), ncol=11, byrow=TRUE)
  rownames(res) <- c("Results")
  colnames(res) <- c("Bottom time (min)", "Working time (min)",
                     "Minimum gas (BAR)", "Turn pressure (BAR)", "Usable gas (BAR)",
                     "Third of usable gas (BAR)", "Total ascent time (min)",
                     "Stop 1 depth (m)", "Time to stop 1 (min)",
                     "Delta stops depth (m)", "Delta stops time (min)")
} else {
  res <- matrix(c(Tb, MG, TP, UG, terc_UG, Tas, Dstop1, tstop1, D_stop, I_stop), ncol=10, byrow=TRUE)
  rownames(res) <- c("Results")
  colnames(res) <- c("Bottom time (min)",
                     "Minimum gas (BAR)", "Turn pressure (BAR)", "Usable gas (BAR)",
                     "Third of usable gas (BAR)", "Total ascent time (min)",
                     "Stop 1 depth (m)", "Time to stop 1 (min)",
                     "Delta stops depth (m)", "Delta stops time (min)")
}

final_results <- cbind(p, res)

print(res)



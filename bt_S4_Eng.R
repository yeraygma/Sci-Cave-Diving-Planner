#!/usr/bin/env Rscript
# BOTTOM TIME
# Goal: Calculates the bottom time for a given tank volume, tank fill pressure, max bottom depth, average bottom depth and penetration strategy.

rm(list=ls()) # Clear workspace  
graphics.off() 
# Libraries
library(dplyr)

cat("SCIENTIFIC CAVE DIVE PLANNING\n")
Tvol <- readline("What is the tank capacity (litres)? ")
Fp <- readline("What is the tank fill pressure (BAR)? ")
Dmax <- readline("What is the maximum depth of the dive (m)? ")
ask_depth <- readline("Do you know the average depth of the bottom profile? (Yes/No) ")

if(ask_depth == "No" || ask_depth == "NO" || ask_depth == "no" || ask_depth == "n" || ask_depth == "N"){
  Dad = Dmax
} else {
  Dad = readline("Enter the average depth of the bottom profile (m): ")
}

Pn <- readline("What is the penetration depth (m) at the end of the dive? ")

# Transformations -------------------------------------------------------
Tvol <- as.numeric(Tvol)
Fp <- as.numeric(Fp)
Dmax <- as.numeric(Dmax)
Dad <- as.numeric(Dad)
Pn <- as.numeric(Pn)

# VARIABLES ---------------------------------------------------------------
S <- 4 # Strategy S=4 cave with sampling; S=3 cave where penetration speed equals exit speed.

Pmax <- (Dmax/10)+1
Pad <- (Dad/10)+1

SCR <- 20 # Default value. Can be adjusted for a specific diver
SCRs <- 30 # Default value. Can be adjusted for a specific diver

vh <- 0.5 # Cave exit speed in m/s

Pav <- ((Dmax/2)/10) + 1

# Time
t_stamp <- timestamp()

# Rounding down function (nearest 10)
floor_10 <- function(x, level=-1) ifelse(x %% 10 == 0, x, (round(x - 5*10^(-level-1), level)))
# Rounding up function (nearest 10)
ceil_10 <- function(x, level=-1) ifelse(x %% 10 == 0, x, (round(x + 5*10^(-level-1), level)))
# Rounding up to multiples of 3
round_any.numeric <- function(x, accuracy, f = round) { 
  f(x / accuracy) * accuracy
}

# Calculate Average depth  
Dav <- (Dmax/2)

# Stops -----------------------------------------------------------------
Dstop1 = round_any.numeric(Dav, 3, ceiling) # Round up Dav to a multiple of 3.
tstop1 <- ceiling(Dstop1/9) # Time to the first stop from the bottom. 

b  <- (Dstop1)/3 # Ascent time from the first stop to the surface
Tas = ceiling(tstop1 + b) # Total ascent time

D_stop <- 3 # Depth change between stops
I_stop <- 1 # Time increment between stops

# Gas calculations --------------------------------------------------------

# Minimum gas calculation in BAR
mG <- (SCRs*Pav*Tas*2)/Tvol
MG <- ceil_10(mG, -1)

# Usable gas in BAR
uG <- (Fp-mG) # Exact usable gas
UG <- floor_10(uG, -1) # Usable gas rounded down, to be conservative

# Turn pressure 
if(S==1 || S==2 || S==3) {
  TP <- Fp-(uG/S)
  TP <- ceil_10(TP)
} else {
  # Consumption in BAR to exit the cave
  sG <- (((Pn/vh)/60)*SCRs*Pad)/Tvol
  # TP is less conservative than the rule of thirds because penetration time is greater
  # than return time (sampling is done on the way in, exit is just leaving). 
  # Calculated to allow two divers to exit to the surface with a single tank during an accident
  # in the maximum penetration zone, plus adding one third of usable gas (rule of thirds).
  # Scenario for 2 problems: out of air diver + e.g., lost guideline.
  # NOTE: If penetration speed = exit speed (normal caving), set S=3
  TP <- ceil_10(1/3*UG + mG + 2*sG) 
}

# Calculate bottom time
Tb <- (uG*Tvol)/(SCR*Pad)
Tb <- floor(Tb)

# 1/3 of Usable Gas
terc_UG = round(UG/3, 0)

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
p <- matrix(c(t_stamp, Fp, Dmax, Dad, Pn, strategy_name, SCR, SCRs), ncol=8, byrow=TRUE)
rownames(p) <- c("Parameters")
colnames(p) <- c("Date/Time", "Fill pressure (BAR)", "Max depth (m)", "Average bottom depth (m)", "Penetration depth (m)", "Strategy", "SCR (litres/min)", "Stressed SCR (litres/min)")

# Results matrix
res <- matrix(c(Tb, MG, TP, UG, terc_UG, Tas, Dstop1, tstop1, D_stop, I_stop), ncol=10, byrow=TRUE)
rownames(res) <- c("Results")
colnames(res) <- c("Bottom time (min)", "Minimum gas (BAR)", "Turn pressure (BAR)", "Usable gas (BAR)", "Third of usable gas (BAR)", "Total ascent time (min)", "Stop 1 depth (m)", "Time to stop 1 (min)", "Delta stops depth (m)", "Delta stops time (min)")

final_results <- cbind(p, res)

print(res)

# Export the results
write.csv(final_results, paste0("~/storage/downloads/caves_sci_", format(Sys.time(), "%d-%b-%Y_%H%M"), ".csv"))
#!/usr/bin/env Rscript
# BOTTOM TIME
# Goal: calculates the bottom time for a given cylinder volume, fill pressure, max bottom depth, average bottom depth and penetration strategy.

rm(list=ls()) # clear workspace  
graphics.off() 
library(dplyr)

cat("--- SCIENTIFIC CAVE DIVE PLANNER ---\n")
Tvol <- readline("What is the capacity (litres) of the cylinder? ")
Fp <- readline("What is the fill pressure (BAR)? ")
Dmax <- readline("What is the maximum depth of the dive (m)? ")
Dent <- readline("What is the depth of the cave entrance (m)? ")
preg <- readline("Do you know the average bottom depth? (Yes/No) ")

if(preg == "No" || preg == "NO" || preg == "no" || preg == "n" || preg == "N"){
        Dad = Dmax
} else {
        Dad = readline("Please indicate the average bottom depth (m): ")
}

Pn <- readline("What is the maximum penetration distance (m) into the cave? ")

# Data transformations ---------------------------------------------------
Tvol <- as.numeric(Tvol)
Fp <- as.numeric(Fp)
Dmax <- as.numeric(Dmax)
Dent <- as.numeric(Dent)
Dad <- as.numeric(Dad)
Pn <- as.numeric(Pn)

# Strategy selection (4 = Sampling by default)
S <- 4 

Pmax <- (Dmax/10)+1
Pad <- (Dad/10)+1

# Constants
SCR <- 20 # Standard Surface Consumption Rate (L/min)
SCRs <- 30 # Stressed Surface Consumption Rate (L/min)
vh <- 0.5 # Exit swimming speed (m/s)
DescentRate <- 15 # Standard descent rate (m/min)
Pav <- ((Dmax/2)/10) + 1
t <- timestamp()

# Rounding functions
floor_10 <- function(x, level=-1) ifelse(x %% 10 == 0, x, (round(x - 5*10^(-level-1), level)))
ceil_10 <- function(x, level=-1) ifelse(x %% 10 == 0, x, (round(x + 5*10^(-level-1), level)))
round_any.numeric <- function(x, accuracy, f = round) { 
        f(x / accuracy) * accuracy
}

Dav <- (Dmax/2)

# Stops and Ascent Profile -----------------------------------------------
Dstop1 = round_any.numeric(Dav, 3, ceiling) # Stop Half Depth
tstop1 <- ceiling(Dstop1/9) # Time from bottom to Stop Half Depth
b <- (Dstop1)/3 # Time from Stop Half Depth to surface
Tas = ceiling(tstop1 + b) # Total ascent time
Dparad <- 3 # Depth increment between stops
Iparad <- 1 # Time increment between stops

# Gas Calculations -------------------------------------------------------
mG <- (SCRs * Pav * Tas * 2) / Tvol
MG <- ceil_10(mG, -1)

uG <- (Fp - mG) 
UG <- floor_10(uG, -1)

# Turn pressure (TP) Logic -----------------------------------------------
if(S == 1 || S == 2) {
        TP <- ceil_10(Fp - (uG/S))
} else if (S == 3) {
        # GUE DIR Logic for Rule of Thirds
        tercio_Fp <- Fp / 3
        if (tercio_Fp >= MG) {
                TP <- ceil_10(Fp - tercio_Fp)
        } else {
                TP <- ceil_10(Fp - ((Fp - MG) / 2))
        }
} else if (S == 4) {
        # Sampling Strategy
        sG <- (((Pn/vh)/60) * SCRs * Pad) / Tvol
        TP <- ceil_10(1/3 * UG + mG + 2 * sG)
}

# Calculate exact gas for penetration and Bottom Time
GasPen <- Fp - TP
Tb <- floor((GasPen * Tvol) / (SCR * Pad))

# Actual Working Time (AWT) Calculation
AWT <- NA
if (S == 4) {
        DescentTime <- Dent / DescentRate
        ExitTime <- Pn / (vh * 60)
        AWT <- floor(Tb - DescentTime - ExitTime)
}

terc_UG = round(UG/3, 0)

if (S == 1) {
        q <- "All available gas"
} else if (S == 2) {
        q <- "Rule of Halves"
} else if (S == 3) {
        q <- "Rule of Thirds (GUE)"
} else if (S == 4){
        q <- "Sampling Strategy"
}

# Matrices setup
p <- matrix(c(t, Fp, Dmax, Dent, Dad, Pn, q, SCR, SCRs), ncol=9, byrow=TRUE)
rownames(p) <- c("Parameters")
colnames(p) <- c("Date/Time", "Fill Pressure (BAR)", "Max Depth (m)", "Entrance Depth (m)", "Average Depth (m)", "Max Penetration (m)", "Strategy", "SCR (L/min)", "Stressed SCR (L/min)")

res <- matrix(c(Tb, AWT, MG, TP, UG, terc_UG, Tas, Dstop1, tstop1), ncol=9, byrow=TRUE)
rownames(res) <- c("Results")
colnames(res) <- c("Bottom Time (min)", "Working Time (min)", "Minimum Gas (BAR)", "Turn Pressure (BAR)", "Usable Gas (BAR)", "Third of Usable Gas (BAR)", "Total Ascent Time (min)", "Stop Half Depth (m)", "Time to Stop Half Depth (min)")

resultados <- cbind(p, res)
print(res)


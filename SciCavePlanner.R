#!/usr/bin/env Rscript
# BOTTOM TIME
# Goal: Calculates the bottom time for a given cylinder volume, fill pressure, max bottom depth, average bottom depth and penetration strategy.

rm(list=ls()) # clear workspace  
graphics.off() 
library(dplyr)

cat("SCIENTIFIC CAVE DIVE PLANNING\n")
Tvol <- readline("What is the capacity (litres) of the cylinder? ")
Fp <- readline("What is the fill pressure (BAR) of the cylinder? ")
Dmax <- readline("What is the maximum depth of the dive (m)? ")
preg <- readline("Do you know the average bottom depth? (Yes/No) ")

if(preg == "No" || preg == "NO" || preg == "no" || preg == "n" || preg == "N"){
        Dad = Dmax
} else {
        Dad = readline("Indicate the average bottom depth (m): ")
}

Pn <- readline("What is the maximum penetration distance (m) into the cave? ")

# Data transformations ---------------------------------------------------
Tvol <- as.numeric(Tvol)
Fp <- as.numeric(Fp)
Dmax <- as.numeric(Dmax)
Dad <- as.numeric(Dad)
Pn <- as.numeric(Pn)

# VARIABLES --------------------------------------------------------------
S <- 4 # Default strategy S=4 (Cave sampling)

Pmax <- (Dmax/10) + 1
Pad <- (Dad/10) + 1

SCR <- 20 # Standard Surface Consumption Rate (L/min)
SCRs <- 30 # Stressed Surface Consumption Rate (L/min)

vh <- 0.5 # Cave exit swimming speed (m/s)

Pav <- ((Dmax/2)/10) + 1

t <- timestamp()

# Rounding functions
floor_10 <- function(x, level=-1) ifelse(x %% 10 == 0, x, (round(x - 5*10^(-level-1), level)))
ceil_10 <- function(x, level=-1) ifelse(x %% 10 == 0, x, (round(x + 5*10^(-level-1), level)))
round_any.numeric <- function(x, accuracy, f = round) {
        f(x / accuracy) * accuracy
}

Dav <- (Dmax/2)

# Stops ------------------------------------------------------------------
Dstop1 = round_any.numeric(Dav, 3, ceiling) 
tstop1 <- ceiling(Dstop1/9) 

b <- (Dstop1)/3 
Tas = ceiling(tstop1 + b) 

Dparad <- 3 
Iparad <- 1 

# Gas Calculations -------------------------------------------------------
mG <- (SCRs * Pav * Tas * 2) / Tvol
MG <- ceil_10(mG, -1)

uG <- (Fp - mG) 
UG <- floor_10(uG, -1)

# Turn pressure logic 
if(S == 1 || S == 2)  {
        TP <- Fp - (uG/S)
        TP <- ceil_10(TP)
} else if (S == 3) {
        tercio_Fp <- Fp / 3
        if (tercio_Fp >= MG) {
                TP <- ceil_10(Fp - tercio_Fp)
        } else {
                TP <- ceil_10(Fp - ((Fp - MG) / 2))
        }
} else if (S == 4) {
        sG <- (((Pn/vh)/60) * SCRs * Pad) / Tvol
        TP <- ceil_10(1/3 * UG + mG + 2 * sG)
}

GasPen <- Fp - TP
Tb <- (GasPen * Tvol) / (SCR * Pad)
Tb <- floor(Tb)

terc_UG = round(UG/3, 0)

if (S == 1) {
        q <- "All Available Gas"
} else if (S == 2) {
        q <- "Rule of Halves"
} else if (S == 3) {
        q <- "Rule of Thirds (GUE)"
} else if (S == 4) {
        q <- "Cave Sampling"
}

p <- matrix(c(t, Fp, Dmax, Dad, Pn, q, SCR, SCRs), ncol=8, byrow=TRUE)
rownames(p) <- c("Parameters")
colnames(p) <- c("Date/Time", "Fill Pressure (BAR)", "Max Depth (m)", "Average Bottom Depth (m)", "Penetration Distance (m)", "Strategy", "SCR (L/min)", "Stressed SCR (L/min)")

res <- matrix(c(Tb, MG, TP, UG, terc_UG, Tas, Dstop1, tstop1, Dparad, Iparad), ncol=10, byrow=TRUE)
rownames(res) <- c("Results")
colnames(res) <- c("Bottom Time (min)", "Minimum Gas (BAR)", "Turn Pressure (BAR)", "Usable Gas (BAR)", "Third of Usable Gas (BAR)", "Total Ascent Time (min)", "Stop Half Depth (m)", "Time to Stop 1 (min)", "Stop Depth Increment (m)", "Stop Time Increment (min)")

resultados <- cbind(p, res)
print(res)

write.csv(resultados, paste0("~/storage/downloads/caves_sci_", format(Sys.time(), "%d-%b-%Y_%H%M"), ".csv"))
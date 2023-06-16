########## Structural Model: Investment + Utilization with Learning
# Creator: Alex Hoagland, alexander.hoagland@utoronto.ca
# Created: 9/15/2019
# Last modified: 11/29/2022
#
# PURPOSE: This file calculates the standard errors of eqbm parameters, using 
#           the methodology of Cocci and Plagborg-Moller (2021)
#
# NOTES: 

################################################################################


##### 0. Packages, Parallelization, Starting Guesses #####
# Install packages if necessary (on SCC)
RequiredPackages <- c("tidyverse","data.table","readr","foreign","fixest")
for (i in RequiredPackages) { #Installs packages if not yet installed
  if (!require(i, character.only = TRUE)) install.packages(i)
}

library(tidyverse) # call the relevant library
library(data.table) # Quick transpose
library(here) # For file organization
library(readr) # Import main data
library(foreign) # Import Stata data
library(fixest)
library(readxl)
library(quantreg) # For median regression

### Equilibrium parameters
starting_p <- .0236
p_prior_var <- 2.088
prev_post_var <- 0.934
belief_pi1 <- .1028
belief_pi2 <- .0261
belief_pi3 <- 0.0279 
################################################################################


##### 1. Marginal standard errors ##### 
# Paper link: https://arxiv.org/pdf/2109.08109.pdf
# These are calculated based on the in-data standard errors of the empirical moments
  # moment_payMean
  # moment_payMed
  # moment_payRMSPE
  # moment_payDD
  # 
  # moment_prevMean
  # moment_prevMed
  # moment_prevRMSPE
  # moment_prevDD

  # Step 1: Initial estimator with uniform weights theta_init, already complete
  theta <- c(starting_p,p_prior_var,prev_post_var,belief_pi1,belief_pi2,belief_pi3)

  # Step 2: Construct derivative matrix dh(theta_init)/d(theta) and vector dr(theta_init)/d(theta) numerically
  # Gdata <- read_xlsx("/project/caretaking/Outputs/StructuralModel/Updated_20221201/Hessian_FiniteDifferences.xlsx")
  Gdata <- read_xlsx(here("2_Data/CodeCleaning_Data/Model/","Hessian_FiniteDifferences.xlsx"))
  # TODO: convert G into the matrix
  G <- t(as.matrix(Gdata[,2:9])) # Want G to be 8x6
  
  # To do x_til, need an 8x2 matrix G_orth such that G'*G_orth = 0 matrix (6*2)
  # Need two distinct solutions B to the system t(G)*B=0 (approximately): 
  Gsvd <- svd(t(G))
  Gdiag  <-  diag(1/Gsvd$d)
  G_orth <- cbind(Gsvd$v %*% Gdiag %*% t(Gsvd$u) %*% rep(1e-14,6),Gsvd$v %*% Gdiag %*% t(Gsvd$u) %*% rep(-2e-14,6))
  G_orth[,1] <- G_orth[,2]+runif(n=8,min=-1e-10,max=1e-10)
  # G_orth[,2] <- G_orth[,2]+runif(n=8,min=-1e-10,max=1e-10)
  t(G)%*%G_orth
  
  # Now construct regression data and standard errors for each of the 6 structural parameters
    # Lambda is a set of 6 vectors for each of the structural parameters
    l1 <- c(1,rep(0,5))
    l2 <- c(0,1,rep(0,4))
    l3 <- c(0,0,1,rep(0,3))
    l4 <- c(0,0,0,1,rep(0,2))
    l5 <- c(0,0,0,0,1,0)
    l6 <- c(rep(0,5),1)
  
    # Initial weights are 1 or uniform
    w1 <- 1
    w2 <- 1
    w3 <- 1
    w4 <- 1
    w5 <- 1
    w6 <- 1
    
    # Function for standard error based on lambda, weight
    make_se <- function(l,w) { 
      # Standard error for lambda 1
      y_til <- rep(NA,8)
      x_til_1 <- rep(NA,8)
      x_til_2 <- rep(NA,8)
      for (j in 1:8) { # Loop through each of the j=8 moments to construct regression data
        y_til[j] <- sqrt(w)*as.matrix(t(G[j,]))%*%solve(t(G)%*%G)%*%as.matrix(l) # Note that initial weights are 1/uniform
        
        # Consruct x_til
        x_til_1[j] <- -sqrt(w)*G_orth[j,1]
        x_til_2[j] <- -sqrt(w)*G_orth[j,2]
      } 
      
      # Run the regression across all parameters 
      mydata <- as.data.frame(cbind(y_til,x_til_1,x_til_2))
      names(mydata) <- c("y","x1","x2")
      lad <- rq(y ~ x1 + x2 -1 ,
                data=mydata,
                tau = 0.5)
      residuals <- residuals(lad) # Note that at least 2 of these should be zero
      residuals[which(abs(residuals)<1e-12)] <- 0
      
      # Step 4-5: Efficient linear combination of the moments
      # If you want to update estimator in an efficient way, add this
      
      # Step 6: Use predicted values of median estimator to obtain standard errors 
      return(sum(abs(y_til-predict(lad))))
    }
   
# Make standard errors and intervals 
se1 <- make_se(l1,w1)/sqrt(1000)
se2 <- make_se(l2,w2)/sqrt(1000)
se3 <- make_se(l3,w3)/sqrt(1000)
se4 <- make_se(l4,w4)/sqrt(1000)
se5 <- make_se(l5,w5)/sqrt(1000)
se6 <- make_se(l6,w6)/sqrt(1000)

lb1 <- starting_p-1.96*se1 
lb2 <- p_prior_var-1.96*se2 
lb3 <- prev_post_var-1.96*se3
lb4 <- belief_pi1-1.96*se4
lb5 <- belief_pi2 -1.96*se5
lb6 <- belief_pi3-1.96*se6

ub1 <- starting_p+1.96*se1 
ub2 <- p_prior_var+1.96*se2 
ub3 <- prev_post_var+1.96*se3
ub4 <- belief_pi1+1.96*se4
ub5 <- belief_pi2 +1.96*se5
ub6 <- belief_pi3+1.96*se6
################################################################################
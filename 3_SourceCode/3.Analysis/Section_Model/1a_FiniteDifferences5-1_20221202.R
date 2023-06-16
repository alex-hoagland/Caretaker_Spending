########## Structural Model: Investment + Utilization with Learning
# Creator: Alex Hoagland, alexander.hoagland@utoronto.ca
# Created: 9/15/2019
# Last modified: 11/29/2022
#
# PURPOSE: runs a "finite differences model" which predicts differences in predicted moments based on slight changes to struct params.
#
# NOTES: 
 
################################################################################


##### 0. Packages, Parallelization, Starting Guesses #####
# Install packages if necessary (on SCC)
RequiredPackages <- c("tidyverse","parallel","foreach","doParallel","data.table","readr","foreign","brms","purrr","furrr","fixest")
for (i in RequiredPackages) { #Installs packages if not yet installed
    if (!require(i, character.only = TRUE)) install.packages(i)
}

library(tidyverse) # call the relevant library
library(parallel) # Parallelizing drawing shocks
library(foreach)
library(doParallel)
library(data.table) # Quick transpose
# library(here) # For file organization
library(readr) # Import main data
library(foreign) # Import Stata data
library(brms) # For shifted lognormal distribution
library(purrr)
library(furrr) # Parallel processing
library(fixest)
# devtools::install_github("NickCH-K/pmdplyr")
# library(pmdplyr) # Panel dplyr (for panel_fill())
# library(slackr) # Slack message when finished (if running on SCC online)

### Start up parallel backend
# n.cores <- as.numeric(Sys.getenv("NSLOTS")) # for SCC
n.cores <- parallel::detectCores() - 1 # for home machine
if (is.na(n.cores))n.cores= 1
my.cluster <- parallel::makeCluster(
  n.cores, 
  type = "PSOCK"
)
doParallel::registerDoParallel(cl = my.cluster)

### Identify which seeds have not yet been run 
# my_files <- list.files(path="/projectnb/sdoh-mod/IBNR/ModelData/",patt= "BaseModel_SEED_*")
# seeds <-list.files(path="/projectnb/sdoh-mod/IBNR/ModelData/",patt= "Shock_*")
# 
# for (i in 1:length(seeds)) { 
#   my_files[i] <- substr(my_files[i], 16, 20)
#   seeds[i] <- substr(seeds[i],7,11)
# }
# 
# seeds <- setdiff(seeds, my_files) # Haven't run these yet. 
# myseed <- as.numeric(seeds[1])
myseed <- 19394 # For drawing health shock
 # For drawing starting parameters
seed <- as.integer(as.double(Sys.time()) %% 2^15 )
set.seed(seed)

# slackr_setup(channel = "#health-econ-research",
#              token = "xoxb-4202604806071-4202624680791-GjMkVHixVSRgoKuyPJlUGE2G",
#              incoming_webhook_url = "https://hooks.slack.com/services/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")

eps <- 1e-4 # How much to change parameter by to get backward/forward induction 
changed <- 5 # Which did we change? (goes from 0 to 6)
direction <- 1 # Which direction (0, 1 for backward, 2 for forward)

### Starting guesses
starting_p <- .05
p_prior_var <- 2.25
prev_post_var <- 1.5
belief_pi1 <- .095
belief_pi2 <- .035-eps
belief_pi3 <- 0.025 

delta <- .95 # Annual discount rate of .95 (not a guess)
################################################################################


##### 0.1: Functions used ####
payoff <- function(i) { # DEPRECATED Returns single-period utility index 
  # Function of chosen spending + # of preventive visits, i is row index for mydata
  # Allow payoff to vary with s, given backward induction --> eventually, loop over all 5 options here and pick maximizer
  mit <- SMData_20210301[i,]$pay_sim
  lambda <- SMData_20210301[i,]$elambda
  omegai <- SMData_20210301[i,]$omega
  
  ### TODO: endogenous OOP? 
  return((mit-lambda)+1/(2*omegai)*(mit-lambda)^2-SMData_20210301[i,]$tot_oop)  
}

# NOTE: not used any more, see below
make_eui <- function(i,l1,l2) { 
  # Makes EU for each point in the distribution chosen for integration (below) 
  s <- SMData_20210301[i,]$numsignals
  o <- SMData_20210301[i,]$omega
  p <- SMData_20210301[i,]$pred_beliefs
  c1 <- SMData_20210301[i,]$tot_oop
  
  el <- l1 + p * l2
  # Now expected chosen spending + signal (based on initial guess) gives us EV
  m <- SMData_20210301[i,] %>%
    ungroup() %>% 
    mutate(mc_sim = ifelse(el < ded_c, 1, tot_oop/tot_pay),
           pay_sim = el + omega*(1-mc_sim)) %>%
    select(pay_sim)
  m <- min(max(m,0),250000)
  
  return((m -el)+   1/(2*o)*(m -el)^2-prev_meanoop*s) # TODO: endogenous OOP? 
}

integrate_eui <- function(j,df) { 
  # Expectations formed over distributions of lambda_tr and lambda_ch 
  
  # Makes EU for each point in the distribution chosen for integration (below) 
  myout <- 0 # Starting utility is 0
  
  n_points <- 3 # number of points in each dimension -- eventually can make an argument
  for (tr in 1:n_points) { # Loop over transient probabilities/outcomes
    spend_tr <- df %>% ungroup() %>% select(all_of(paste0("spend_",tr,sep=""))) # Vector of spending outcomes
    prob_tr <- df %>% ungroup() %>% select(all_of(paste0("prob_",tr,sep="")))# Vector of weights (probabilities)
    
    for (ch in 1:n_points) { # Loop over chronic probabilities/outcomes
      spend_ch <- df %>% ungroup() %>% select(all_of(paste0("mch_spend",tr,sep=""))) # Vector of spending outcomes
      prob_ch <- df %>% ungroup() %>% select(all_of(paste0("mch_prob",tr,sep="")))# Vector of weights (probabilities)
      
      # Now expected chosen spending + signal (based on initial guess) gives us EV
      m <- df[j,] %>%
        ungroup() %>% 
        mutate(el_j = spend_tr[j,1] + pred_beliefs * spend_ch[j,1], # Expected lambda
               mc_sim = ifelse(el_j < ded_c, 1, tot_oop/tot_pay),
               pay_sim = el_j + omega*(1-mc_sim)) %>%
        mutate(pay_sim = min(max(pay_sim,0),250000)) %>% # Topcode, nonnegative
        mutate(u = (pay_sim-el_j)+1/(2*omega)*(pay_sim-el_j)^2-
                 mc_sim*pay_sim - prev_meanoop*numsignals) %>% # Convert to utility 
        select(u)
      
      myout <- myout + # Cumulative sum 
        (prob_ch[j,1]*prob_tr[j,1])*m # Joint (rescaled) probability of event
      # TODO: endogenous OOP?
    }
  }
  
  return(as.numeric(myout))
}

# Probability means depend on trajectory of health events + individuals' p-bars (signals)
post_mean <- function(df,j) { # Function of number of signals and mean of signals (p-guess)
  # This function returns a draw for p_{it} based on the number of signals, the mean of those signals, and any health events which have occurred
  # j is a row index which captures (enrolid,year,pguess)
  
  # If diagnosed, return 1 immediately
  if(df[j,]$dxd==1) { 
    return(1) 
  }
  
  # If no signals received, return draw from starting value + any discrete changes
  if(df[j,]$numsignals == 0) { 
    
    toadd <- belief_pi1*df[j,]$rs_fam_chronic + belief_pi2*df[j,]$rs_fam_acute + belief_pi3*df[j,]$rs_ind_acute 
    sp <- log((starting_p+toadd)/(1-(starting_p+toadd)))
    # Update this mean discretely according to how many major health events have occurred so far
    
    myout <- rnorm(1,sp,sqrt(p_prior_var)) # Draw a probability
    myout <- max(exp(myout)/(1+exp(myout)),0) # Bound the resulting probability in the unit interval
    myout <- min(myout,1)
    return(myout)
  }
  
  # Update this mean discretely according to how many major health events have occurred so far
  toadd <- belief_pi1*df[j,]$rs_fam_chronic + belief_pi2*df[j,]$rs_fam_acute + belief_pi3*df[j,]$rs_ind_acute 
  
  # Convert beliefs to log-odds
  lpguess <- log(df[j,]$prob_true/(1-df[j,]$prob_true))
  lstart <- log((starting_p+toadd)/(1-starting_p-toadd)) # Include discrete shift here
  
  # Note: 4 visits possible per year * 8 years = 32 signals total possible 
  signals <- rnorm(32, lpguess, sqrt(prev_post_var)) # Each draw from a preventive visit
  mu    <- numeric(32)
  sigma <- numeric(32)
  
  mu[1]    <- (p_prior_var*lstart + (prev_post_var)*0)/(p_prior_var+prev_post_var)
  sigma[1] <- (p_prior_var*prev_post_var)/(p_prior_var+prev_post_var)
  
  mu[1] <- ifelse(toadd>0,mu[1] + log(toadd/(1-toadd)),mu[1])
  
  # Note: i=1 is when there are 0 signals, so need to return the i+1'th element
  s <- (df[j,]$numsignals+1) # Index of vector to return
  
  for (i in 2:s) { # Don't do all 32 iterations if you don't need to
    mu[i]    <- ( sigma[i-1]*signals[i] + (prev_post_var)*mu[i-1] )/(sigma[i-1]+prev_post_var)
    sigma[i] <- ( sigma[i-1]*prev_post_var                  )/(sigma[i-1]+prev_post_var)
  }
  
  myout <- rnorm(1,mu[s],sqrt(sigma[s])) # Draw a probability
  myout <- max(exp(myout)/(1+exp(myout)),0) # Bound the resulting probability in the unit interval
  myout <- min(myout,1)
  
  return(myout)  # Return it back in a probability
}
################################################################################


##### 1. Import and Organize Data ####
# Main data -- load pre-saved version
if (!file.exists("/project/caretaking/Outputs/StructuralModel/Updated_20221201/ModelData_20221201.RData")) {
  SMData_20210301 <- read_csv("2_Data/7.StructuralModel/SMData_20210301.csv")
  
  # Filter poor data rows
  SMData_20210301 <- SMData_20210301 %>% 
    filter(!is.na(tot_pay) & !is.na(tot_oop)) %>%
    filter(tot_pay >= 0 & tot_oop >= 0) 
  
  # Clean up the data a little bit: mch stuff, specific hccs
  tomerge <- SMData_20210301 %>% # mch pay
    select(mch_pay1,mch_pay2,mch_pay3,mch_pay4,mch_pay5,
           mch_pay6,mch_pay7,mch_pay8,mch_pay9,mch_pay10) %>% 
    mutate(mch_pay = rowSums(.,na.rm=T)) %>% 
    select(mch_pay) 
  names(tomerge) <- "mch_pay"
  SMData_20210301 <- cbind(SMData_20210301,tomerge)
  SMData_20210301 <- SMData_20210301 %>% 
    select(-c(mch_pay1,mch_pay2,mch_pay3,mch_pay4,mch_pay5,
              mch_pay6,mch_pay7,mch_pay8,mch_pay9,mch_pay10))
  
  tomerge <- SMData_20210301 %>% # mch oop
    select(mch_oop1,mch_oop2,mch_oop3,mch_oop4,mch_oop5,
           mch_oop6,mch_oop7,mch_oop8,mch_oop9,mch_oop10) %>% 
    mutate(mch_oop = rowSums(.,na.rm=T)) %>% 
    select(mch_oop) 
  names(tomerge) <- "mch_oop"
  SMData_20210301 <- cbind(SMData_20210301,tomerge)
  SMData_20210301 <- SMData_20210301 %>% 
    select(-c(mch_oop1,mch_oop2,mch_oop3,mch_oop4,mch_oop5,
              mch_oop6,mch_oop7,mch_oop8,mch_oop9,mch_oop10))
  
  tomerge <- SMData_20210301 %>% # mch hosp
    select(mch_hosp1,mch_hosp2,mch_hosp3,mch_hosp4,mch_hosp5,
           mch_hosp6,mch_hosp7,mch_hosp8,mch_hosp9,mch_hosp10) %>% 
    mutate(mch_hosp = rowSums(.,na.rm=T)) %>% 
    select(mch_hosp) 
  names(tomerge) <- "mch_hosp"
  SMData_20210301 <- cbind(SMData_20210301,tomerge)
  SMData_20210301 <- SMData_20210301 %>% 
    select(-c(mch_hosp1,mch_hosp2,mch_hosp3,mch_hosp4,mch_hosp5,
              mch_hosp6,mch_hosp7,mch_hosp8,mch_hosp9,mch_hosp10))
  
  # Identify most recent (if any) health event (for predicting lambda_chronic)
  SMData_20210301 <- SMData_20210301 %>% group_by(famid) %>% arrange(famid,enrolid,year) %>% 
    select(-c(hcc4,hcc5,hcc6,hcc7,hcc8,hcc9,hcc10)) %>% 
    fill(hcc1,hcc2,hcc3) %>% 
    ungroup() %>% arrange(enrolid,year)
  # SMData_20210301 <- SMData_20210301 %>% 
  #   select(-c(hcc1,hcc2,hcc3,hcc4,hcc5,
  #             hcc6,hcc7,hcc8,hcc9,hcc10))
  
  # Remove plan choice variables 
  vars_to_drop <- c("choice_noswitch","switchplans","avail1",
                    "avail2","avail3","avail4","avail5","avail6",
                    "copay_1","copay_2","copay_3","copay_4","copay_5","copay_6",
                    "moop_1","moop_2","moop_3","moop_4","moop_5","moop_6",
                    "prem_1","prem_2","prem_3","prem_4","prem_5","prem_6",
                    "ded_1","ded_2","ded_3","ded_4","ded_5","ded_6")
  SMData_20210301 <- SMData_20210301 %>% select(-vars_to_drop)
  
  # Merge in chronic events 
  tomerge <- read.dta(here("2_Data/CodeCleaning_Data","AllChronicEvents_20221122.dta"))
  SMData_20210301 <- SMData_20210301 %>% 
    left_join(tomerge, by=c("enrolid","famid","year"), all.x=T,all.y=F)
  
  # # Merge in annual spending on wellness visits, update pay variable
  # prevcare <- read.dta(here("2_Data/CodeCleaning_Data","NewPreventionMeasures_20221122.dta"))
  # prevcare <- prevcare %>%
  #   left_join(tomerge, by=c("enrolid","famid","year"), all.x=T,all.y=F) %>%
  #   group_by(enrolid) %>%
  #   mutate(dxd = max(ind_chronic_event)) %>%
  #   filter(dxd == 0 | is.na(dxd)) # remove prev care for diagnosed individuals 
  # prevcare <- prevcare %>%  
  #   group_by(enrolid,famid,year) %>% summarize(newprev_pay = sum(newprev_pay),
  #                                      newprev_oop = sum(newprev_oop),
  #                                      newprev_numvisits = sum(newprev_numvisits)) %>%
  #   mutate(newprev_numvisits = ifelse(newprev_numvisits > 20, 20, newprev_numvisits)) # Top-code number of prev visits
  # 
  # SMData_20210301 <- SMData_20210301 %>% 
  #   left_join(prevcare, by=c("enrolid","famid","year"), all.x=T,all.y=F)
  # SMData_20210301 <- SMData_20210301 %>% mutate(tot_pay = ifelse(newprev_pay > 0 & !is.na(newprev_pay), tot_pay - newprev_pay, tot_pay),
  #                                               tot_oop = ifelse(newprev_oop > 0 & !is.na(newprev_oop), tot_oop - newprev_oop, tot_oop))
  # 
  # SMData_20210301 <- SMData_20210301 %>% 
  #   mutate(newprev_pay = ifelse(is.na(newprev_pay),0,newprev_pay),
  #          newprev_oop = ifelse(is.na(newprev_oop),0,newprev_oop),
  #          newprev_numvisits = ifelse(is.na(newprev_numvisits),0,newprev_numvisits)) %>%
  #   filter(tot_pay >= 0 & tot_oop >= 0) # Put in 0s for preventive spending/visits, drop if negative
  
  # Simple Measure of visits (reduce state space)
  prevcare <- read.dta(here("2_Data/CodeCleaning_Data/Model","SimplePrevVisits_20221123.dta"))
  prevcare <- prevcare %>%
    left_join(tomerge, by=c("enrolid","famid","year"), all.x=T,all.y=F) %>%
    group_by(enrolid) %>%
    mutate(dxd = max(ind_chronic_event)) %>%
    filter(dxd == 0 | is.na(dxd)) # remove prev care for diagnosed individuals 
  prevcare <- prevcare %>%  
    group_by(enrolid,famid,year) %>% summarize(simple_visits = sum(newprev_numvisits)) %>%
    mutate(simple_visits = ifelse(simple_visits > 5, 5, simple_visits)) # Top-code number of prev visits
  
  SMData_20210301 <- SMData_20210301 %>% 
    left_join(prevcare, by=c("enrolid","famid","year"), all.x=T,all.y=F) %>% 
    mutate(simple_visits=ifelse(is.na(simple_visits),0,simple_visits))
  
  rm(prevcare)
  gc()
  
  # Calibrated omega (Einav et al. 2013)
  risk_quartiles <- quantile(SMData_20210301$rs)
  SMData_20210301 <- SMData_20210301 %>% 
    mutate(d_rq_2 = ifelse(rs > risk_quartiles[2] & rs <= risk_quartiles[3],1,0),
           d_rq_3 = ifelse(rs > risk_quartiles[3] & rs <= risk_quartiles[4],1,0),
           d_rq_4 = ifelse(rs > risk_quartiles[4],1,0)) %>% 
    mutate(omega = exp(5.31-0.58-0.01*SMData_20210301$age-
                       0.08*SMData_20210301$female+
                       0.13*d_rq_2+1.79*d_rq_3+3.38*d_rq_4)) 
  
  # Merge in shock distribtuions + simulate a health shock 
  shock_parameters <- read.dta(here("2_Data/CodeCleaning_Data/Model","ShockParameters.dta"))
  SMData_20210301 <- SMData_20210301 %>% 
    left_join(shock_parameters[,c("enrolid","year","cell")], all.x=T,all.y=F) # Just to get cell
  age_cuts <- c(0,18,35,45,55,65,1000)
  SMData_20210301 <- SMData_20210301 %>% mutate(age_bin = cut(age,breaks=age_cuts),
                                                fs_dummy_1 = (famsize ==1 ),
                                                fs_dummy_2 = (famsize == 2), 
                                                fs_dummy_3 = (famsize == 3), 
                                                fs_dummy_4 = (famsize == 4), 
                                                fs_dummy_7 = (famsize >= 5))
  SMData_20210301 <- SMData_20210301 %>% ungroup() %>% 
    group_by(age_bin,female,fs_dummy_1,fs_dummy_2,fs_dummy_3,fs_dummy_4,fs_dummy_7,
             d_rq_2,d_rq_3,d_rq_4) %>% mutate(cell = median(cell,na.rm=T))
  shock_parameters <- shock_parameters %>% group_by(cell) %>% 
    summarize(mymean = first(mymean), mysd = first(mysd), myshift = first(myshift))
  SMData_20210301 <- SMData_20210301 %>% 
    left_join(shock_parameters, all.x=T,all.y=F) # Now merging in all parameters
  
  # Pull a health shock based on parameters
  SMData_20210301 <- SMData_20210301 %>% 
    mutate(healthshock = rshifted_lnorm(n=1,meanlog=mymean,sdlog=mysd,shift=myshift))
  
  # Construct the three reference points (mean +/- SD) for integrating EU -- distribution of lambda_tr
  SMData_20210301 <- SMData_20210301 %>% mutate(spend_1 = exp(mymean - mysd)*52,
                                    spend_2 = exp(mymean)*52,
                                    spend_3 = exp(mymean + mysd)*52,
                                    prob_1 = pshifted_lnorm(mymean-mysd,meanlog=mymean,sdlog=mysd,shift=myshift)-
                                               pshifted_lnorm(mymean-mysd-1,meanlog=mymean,sdlog=mysd,shift=myshift),
                                    prob_2 = pshifted_lnorm(mymean,meanlog=mymean,sdlog=mysd,shift=myshift)-
                                               pshifted_lnorm(mymean-1,meanlog=mymean,sdlog=mysd,shift=myshift),
                                    prob_3 = pshifted_lnorm(mymean+mysd,meanlog=mymean,sdlog=mysd,shift=myshift)-
                                                pshifted_lnorm(mymean+mysd-1,meanlog=mymean,sdlog=mysd,shift=myshift))
  SMData_20210301 <- SMData_20210301 %>% mutate(totprob = prob_1 + prob_2 + prob_3) %>%
    mutate(prob_1 = prob_1/totprob,
           prob_2 = prob_2/totprob,
           prob_3 = prob_3/totprob) %>% select(-c(totprob))
  
  # Merge in expected chronic spending at individual level 
  allmch <- read.dta(here("2_Data/CodeCleaning_Data/MCH_EmpiricalDistributions","LogNormalDistributions.dta"))
  allmch <- allmch %>% mutate(spend_1 = exp(mymean - mysd),
                              spend_2 = exp(mymean),
                              spend_3 = exp(mymean + mysd),
                              prob_1 = pshifted_lnorm(mymean-mysd,meanlog=mymean,sdlog=mysd,shift=myshift)-
                                pshifted_lnorm(mymean-mysd-1,meanlog=mymean,sdlog=mysd,shift=myshift),
                              prob_2 = pshifted_lnorm(mymean,meanlog=mymean,sdlog=mysd,shift=myshift)-
                                pshifted_lnorm(mymean-1,meanlog=mymean,sdlog=mysd,shift=myshift),
                              prob_3 = pshifted_lnorm(mymean+mysd,meanlog=mymean,sdlog=mysd,shift=myshift)-
                                pshifted_lnorm(mymean+mysd-1,meanlog=mymean,sdlog=mysd,shift=myshift))
  allmch <- allmch %>% mutate(totprob = prob_1 + prob_2 + prob_3) %>%
    mutate(prob_1 = ifelse(totprob>0,prob_1/totprob,.33),
           prob_2 = ifelse(totprob>0,prob_2/totprob,.33),
           prob_3 = ifelse(totprob>0,prob_3/totprob,.33)) %>% select(-c(totprob))
  
  # Merge these in based on any family history + any diagnosis
  SMData_20210301 <- SMData_20210301 %>% mutate(hcc = ifelse(is.na(hcc1),-9,hcc1),
                                                dxyear = ifelse(type == 1 & ind_chronic_event == 0, 0, 1)) # TODO: think about those with multiple HCCs (2%) 
  tomerge <- allmch %>% select(c("hcc","dxyear","spend_1","spend_2","spend_3","prob_1","prob_2","prob_3")) %>% 
    rename(mch_spend1 = spend_1,mch_spend2 = spend_2,mch_spend3 = spend_3,
           mch_prob1 = prob_1,mch_prob2 = prob_2,mch_prob3 = prob_3)
  SMData_20210301 <- SMData_20210301 %>% left_join(tomerge,by=c("hcc","dxyear"),all.x=T,all.y=F)
  rm(tomerge,allmch)
  gc()
  
  # Merge in predicted probabilities (signals from preventive care)
  tomerge <- read.dta(here("2_Data/CodeCleaning_Data","PredictedProbabilities.dta"))
  SMData_20210301 <- SMData_20210301 %>% 
    left_join(tomerge,by=c("enrolid","year"),all.x=T,all.y=F) 
  SMData_20210301 <- SMData_20210301 %>% 
    group_by(enrolid) %>% 
    mutate(prob_true = ifelse(is.na(prob_true),mean(prob_true,na.rm=T),prob_true))
  SMData_20210301 <- SMData_20210301 %>% filter(!is.na(prob_true))
  
  rm(tomerge)
  gc()
  
  # Calculate indicator for relative T (at household level)
  SMData_20210301 <- SMData_20210301 %>% ungroup() %>% group_by(famid) %>% 
    mutate(nyear = year - min(year)+1)
  
  # Drop individuals only observed in one year 
  SMData_20210301 <- SMData_20210301 %>% ungroup() %>% group_by(enrolid) %>% 
    mutate(lastyear = max(nyear)) %>% 
    filter(lastyear > 1) # Keep the lastyear variable for backward induction
  
  # Drop individuals with gaps in their enrollment
  SMData_20210301 <- SMData_20210301 %>% ungroup() %>% group_by(enrolid) %>%
    mutate(numyears_observed = n(),
           numyears_full = max(year)-min(year)+1) %>% 
    filter(numyears_observed == numyears_full) %>% select(-c("numyears_observed","numyears_full"))
  
  # Indicator for if chronic diagnosis has already happened
  SMData_20210301 <- SMData_20210301 %>% arrange(enrolid,year) %>% group_by(enrolid) %>% 
    mutate(dxd = cumsum(ind_chronic_event)) %>% 
    mutate(dxd = ifelse(dxd > 1, 1, dxd)) %>% 
    mutate(todrop_c = max(dxd)) # This identifies chronic-diagnosed individuals dropped for spillover regressions
  
  # Running indicators of how many diagnoses have occurred in household so far
  SMData_20210301 <- SMData_20210301 %>% arrange(enrolid,year) %>% group_by(enrolid) %>% 
    mutate(rs_fam_chronic = cumsum(fam_chronic_event),
           rs_fam_acute = cumsum(fam_acuteevent),
           rs_ind_acute = cumsum(ind_acuteevent)) %>%
    mutate(treated_post = (rs_fam_chronic > 0)) # Create indicator for post chronic event (for regressions)
  
  # Drop variables you don't need
  vars_to_drop <- c("firm","emprel","choice","age","age2","female","famsize","rs","asinhrs","pe_f","pe_fno","pe_f_notme",
                    "pe_fno_notme","pe_myparent","pe_mychild","pe_mysib","pe_myspouse","pe_anyadult","pe_anykid",
                    "d_year_2006","d_year_2007","d_year_2008","d_year_2009","d_year_2010","d_year_2011","d_year_2012","d_year_2013",
                    "d_firm_6","d_firm_22","d_firm_23","d_firm_25","d_firm_28","d_firm_50","d_firm_56","d_firm_65",
                    "fam_avg_age","fam_avg_rs")
  SMData_20210301 <- SMData_20210301 %>% select(-vars_to_drop)
  rm(vars_to_drop)
  
  # SMData_20210301 <- SMData_20210301 %>% rowwise() %>% 
  #   mutate(healthshock = rshifted_lnorm(n=1,meanlog = mymean,sdlog = mysd,shift=myshift))
  
  # Save this data once finalized, put these steps into an if/else loop
  SMData_20210301 <- SMData_20210301 %>% ungroup() 
  save(SMData_20210301,file=here("2_Data/CodeCleaning_Data","ModelData_20221201.RData"))
}

load(file="/project/caretaking/Outputs/StructuralModel/Updated_20221201/ModelData_20221201.RData")
SMData_20210301 <- SMData_20210301 %>% mutate(todrop_hs = is.na(healthshock)) %>% 
  ungroup() %>% filter(todrop_hs == 0) %>% select(-c("todrop_hs")) # Drops about 134 individuals

# For now, randomly sample 1,000 households (50% treated, 50% control) 
all_treated_fams <- SMData_20210301 %>% filter(fam_chronic_event == 1) %>% select(famid) %>% unique() %>% pull()
all_control_fams <- SMData_20210301 %>% filter(fam_chronic_event == 0) %>% select(famid) %>% unique() %>% pull()
set.seed(123) # Need same families for all of finite differences estimation 
samplefams <- c(sample(all_treated_fams, 100), sample(all_control_fams, 100))
SMData_20210301 <- SMData_20210301 %>% filter(famid %in% samplefams)

# topcode spending
SMData_20210301 <- SMData_20210301 %>% mutate(tot_pay = ifelse(tot_pay > 250000,250000,tot_pay))

# Simulate a new health shock if desired
SMData_20210301$error <- runif(n=nrow(SMData_20210301),min=-500,max=500) # Individual differences
SMData_20210301 <- SMData_20210301 %>% ungroup() %>% 
  mutate(healthshock = 52*rshifted_lnorm(n=1,meanlog=mymean,sdlog=mysd,shift=myshift))

# SMData_20210301 <- SMData_20210301[1:1000,] # For debugging
################################################################################


##### 2. Main model: calculate prediction error from guess ##### 
  # Average (annual) OOP cost of preventive care -- need to merge this in (TODO: fix this) 
  stored <- SMData_20210301
  load(file="/project/caretaking/Outputs/StructuralModel/Updated_20221201/ModelData_20221128.RData")
  tomerge <- SMData_20210301
  SMData_20210301 <- stored
  SMData_20210301 <- SMData_20210301 %>% left_join(tomerge[,c("enrolid","year","newprev_oop")],all.x=T,all.y=F)
  prev_meanoop <- mean(SMData_20210301[which(SMData_20210301$newprev_oop>0),]$newprev_oop)
  
### Solving the model: put this into an iterative function for contraction mapping
  
  # Drop years that are too far away from event (for sub_6 plus)
  # Identify relative time
  SMData_20210301 <- SMData_20210301 %>% group_by(famid) %>% # Construct relative time
    mutate(on = ifelse(ind_chronic_event==1,year, 9999)) %>%
    mutate(on = min(on)) %>% 
    mutate(relyear = ifelse(on < 9999, year - on, NA)) %>% select(-c("on")) %>% 
    ungroup() %>% group_by(enrolid) %>% # Now drop enrollee years if they are > abs(2) for those observed 6 or more years
    mutate(max_year = n()) %>% 
    filter(max_year <= 5 | abs(relyear) <= 2)
    
  
  # Update nyear
  # Calculate indicator for relative T (at household level)
  SMData_20210301 <- SMData_20210301 %>% ungroup() %>% group_by(enrolid) %>% 
    mutate(nyear = year - min(year)+1)

  ## STEP 0: Need to split based on enrollee's number of years (in order to reduce processing time)
  SMData_20210301 <- SMData_20210301 %>% group_by(enrolid) %>% mutate(max_year = n())
  sub_2 <- SMData_20210301[SMData_20210301$max_year == 2, ]
  sub_3 <- SMData_20210301[SMData_20210301$max_year == 3, ]
  sub_4 <- SMData_20210301[SMData_20210301$max_year == 4, ]
  sub_5 <- SMData_20210301[SMData_20210301$max_year == 5, ]
  sub_6 <- SMData_20210301[SMData_20210301$max_year == 6, ]
  sub_7 <- SMData_20210301[SMData_20210301$max_year == 7, ]
  sub_8 <- SMData_20210301[SMData_20210301$max_year == 8, ]
  
  # Drop those with gaps again) 
  sub_2 <- sub_2 %>% group_by(enrolid) %>% 
    mutate(todrop_1 = max(nyear > 2)) %>%
    filter(todrop_1 == 0) %>% select(-c("todrop_1"))
  sub_3 <- sub_3 %>% group_by(enrolid) %>% 
    mutate(todrop_1 = max(nyear > 3)) %>%
    filter(todrop_1 == 0) %>% select(-c("todrop_1"))
  sub_4 <- sub_4 %>% group_by(enrolid) %>% 
    mutate(todrop_1 = max(nyear > 4)) %>%
    filter(todrop_1 == 0) %>% select(-c("todrop_1"))
  sub_5 <- sub_5 %>% group_by(enrolid) %>% 
    mutate(todrop_1 = max(nyear > 5)) %>%
    filter(todrop_1 == 0) %>% select(-c("todrop_1"))
  # sub_6 <- sub_6 %>% group_by(enrolid) %>% 
  #   mutate(todrop_1 = max(nyear > 6)) %>%
  #   filter(todrop_1 == 0) %>% select(-c("todrop_1"))
  # sub_7 <- sub_7 %>% group_by(enrolid) %>% 
  #   mutate(todrop_1 = max(nyear > 7)) %>%
  #   filter(todrop_1 == 0) %>% select(-c("todrop_1"))
  # sub_8 <- sub_8 %>% group_by(enrolid) %>% 
  #   mutate(todrop_1 = max(nyear > 8)) %>%
  #   filter(todrop_1 == 0) %>% select(-c("todrop_1"))
  
  
  ## Now iterate over each of the following steps for each sub
  # Note: currently, there are only <50 individual years for >= 6 years, so can ignore those. Just looping through 5 years and fewer
  
  ### THOSE OBSERVED FOR 2 YEARS ####
      ## STEP 1: Calculate expected utility for all possible paths of s_{it}
      # All possible combinations of prev visits
      allcomb <- expand.grid(c(0,1,2,3,4),c(0,1,2,3,4)) 
      allcomb <- allcomb %>% mutate(num = row_number())
      names(allcomb) <- c("s1","s2","num")
      allcomb <- allcomb %>% 
        mutate(todrop = ifelse(s1-s2>1,1,0)) %>%
        filter(todrop == 0) %>% select(-c("todrop"))
      # Assume that preventive care is sticky going down -- can't reduce by more than one from year to year
      # This is to reduce size of transition state space
      
      # Parallel processing
      clusterEvalQ(my.cluster,c(library(tidyverse),library(furrr))) # Export libraries
      clusterExport(my.cluster, "sub_2")
      clusterExport(my.cluster, "allcomb")
      clusterExport(my.cluster, varlist=c("integrate_eui","post_mean"))
      
      # pb = txtProgressBar(min = 1, max = nrow(allcomb), initial = 1) 
      allouts <- foreach (i = 1:nrow(allcomb)) %dopar% { # Calculate V1,V2,V3 and total V for each combination
        # setTxtProgressBar(pb,i)
        
        tomerge <- allcomb[i,] %>% select(-c("num")) %>% 
          pivot_longer(c("s1","s2"),names_to="nyear",names_prefix="s") %>% 
          mutate(nyear = as.numeric(nyear))
        # Match row to individuals based on nyear
        sub_2 <- sub_2 %>% left_join(tomerge,by=c("nyear"),all.x=T,all.y=F) %>% 
          mutate(numsignals = value)  %>% select(-c("value"))
        sub_2$pred_beliefs <- as.numeric(lapply(seq(from=1, to=nrow(sub_2), by=1),post_mean,df=sub_2))
        
        # Per period utility 
        sub_2 <- sub_2 %>% ungroup() %>% 
          mutate(mc_sim = ifelse(healthshock + pred_beliefs*mch_spend2 < ded_c, 1, tot_oop/tot_pay),
                 pay_sim = healthshock + pred_beliefs*mch_spend2 + omega*(1-mc_sim)) %>%
          mutate(pay_sim = ifelse(pay_sim<0,0,pay_sim)) %>% mutate(pay_sim=ifelse(pay_sim>250000,250000,pay_sim)) %>%
          select(-c(mc_sim)) # Don't need the marginal cost hanging around
        sub_2$u_i <- (sub_2$pay_sim - sub_2$healthshock)+
          1/(2*sub_2$omega)*(sub_2$pay_sim - sub_2$healthshock)^2-
          sub_2$tot_oop-prev_meanoop*sub_2$numsignals # TODO: endogenous OOP? 
        
        # Now per period expected utility (need to integrate over distribution of both shocks)
        sub_2$exp_u <- 1:nrow(sub_2) %>% future_map_dbl(function(x) integrate_eui(x,df=sub_2))
        
        # Sum up expected (discounted) future valuations for V_i
        myout <- sub_2 %>% group_by(enrolid) %>% 
          mutate(V_i = ifelse(!is.na(lead(exp_u,n=2)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2), NA)) %>%
          mutate(V_i = ifelse(!is.na(lead(exp_u,n=1)),u_i + delta*lead(exp_u,1), u_i)) %>% 
          select(c("enrolid","year","V_i")) 
        names(myout) <- c("enrolid","year",paste0("seqV_",allcomb$num[i],sep="")) 
        # Select V_i and rename it manually if parallelizing
        return(myout)
        
        # Store this as its own output -- only if NOT PARALLELIZING
        # sub_3[,paste0("seqV_",allcomb$num[i],sep="")] <- sub_3$V_i
        
      }
      # close(pb)
      
      # Convert lists of columns into data.frames
      allouts <- do.call(cbind, allouts)
      allouts <- allouts %>% select(c("enrolid...1","year...2",matches("seqV")))
      names(allouts)[1] <- "enrolid"
      names(allouts)[2] <- "year"
      
      ## STEP 2: Based on predicted expected utilities, solve by backward induction 
      seq_cols <- allouts %>% ungroup() %>% select(matches("seqV")) %>% names()
      # allouts <- allouts %>% ungroup() %>% mutate(rmax=pmax(!!!rlang::syms(seq_cols)))
      
      # Loop backwards through years, construct optimal sequence for individuals 
      myopts <- allouts %>% select(-c("enrolid","year")) %>% ungroup() %>% 
        mutate(optseq = names(.)[max.col(.)]) %>% 
        select(optseq) %>%
        mutate(optseq = as.numeric(substr(optseq,start=6,stop=nchar(optseq))))
      myopts <- cbind(allouts[,c("enrolid","year")],myopts)
      myopts <- myopts %>% 
        left_join(sub_2[,c("enrolid","year","nyear")], 
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>% 
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>% 
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      
      # If individual has the same optimal sequence throughout, keep it
      myopts <- myopts %>% 
        group_by(enrolid) %>% 
        mutate(opts = ifelse(mean(optseq)==max(optseq),optseq,NA)) %>% 
        mutate(opts = ifelse(is.na(opts) & nyear == n(), optseq,opts))
      
      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>% 
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts) 
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })
      
      # For the rest, backward induction for optimal sequence
      myopts <- myopts %>% group_by(enrolid) %>% mutate(myear = n())
      
      # Year n-1 
      tomerge <- myopts %>% group_by(enrolid) %>% 
        mutate(futurechoice = lead(sample_sstar)) %>% 
        filter(nyear==myear-1 & is.na(sample_sstar)) %>% 
        select(c("enrolid","year","futurechoice"))
      allouts <- allouts %>% left_join(tomerge,all.x=T,all.y=F)
      # Now, want to ignore all payoffs that don't fit this criteria
      
      tomerge <- allouts %>% filter(!is.na(futurechoice))
      for (ind in 3:(ncol(tomerge)-1)) {
        tomerge[,ind] <- 1:nrow(tomerge) %>% 
          future_map_dbl(function(x) {
            if (allcomb[ind-2,2] != tomerge[x,]$futurechoice) { return(NA) } 
            return(as.numeric(tomerge[x,ind]))
          })
      }
      
      tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>% 
        mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>% 
        select(optseq_new) %>%
        mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      myopts <- myopts %>% 
        left_join(tomerge2, 
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>% 
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>% 
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      
      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>% 
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts) 
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })
      
      sub_2 <- sub_2 %>% left_join(myopts[,c("enrolid","year","sample_sstar")])
      # Store sequence, move on to next! 
  ################
      
  #### FOR INDIVIDUALS OBSERVED FOR 3 YEARS ####
      ## STEP 1: Calculate expected utility for all possible paths of s_{it}
      # All possible combinations of prev visits
      allcomb <- expand.grid(c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4))
      allcomb <- allcomb %>% mutate(num = row_number())
      names(allcomb) <- c("s1","s2","s3","num")
      allcomb <- allcomb %>% 
        mutate(todrop = ifelse(s1-s2>1,1,0)) %>%
        mutate(todrop = ifelse(s2-s3>1,1,todrop)) %>%
        filter(todrop == 0) %>% select(-c("todrop"))
      # Assume that preventive care is sticky going down -- can't reduce by more than one from year to year
      # This is to reduce size of transition state space
      
      # Parallel processing
      clusterExport(my.cluster, "sub_3")
      clusterExport(my.cluster, "allcomb")
      
      # TODO: do this separately based on nyear to save on processing time
      # pb = txtProgressBar(min = 1, max = nrow(allcomb), initial = 1) 
      allouts <- foreach (i = 1:nrow(allcomb)) %dopar% { # Calculate V1,V2,V3 and total V for each combination
        # setTxtProgressBar(pb,i)
        
        tomerge <- allcomb[i,] %>% select(-c("num")) %>% 
          pivot_longer(c("s1","s2","s3"),names_to="nyear",names_prefix="s") %>% 
          mutate(nyear = as.numeric(nyear))
        # Match row to individuals based on nyear
        sub_3 <- sub_3 %>% left_join(tomerge,by=c("nyear"),all.x=T,all.y=F) %>% 
          mutate(numsignals = value)  %>% select(-c("value"))
        sub_3$pred_beliefs <- as.numeric(lapply(seq(from=1, to=nrow(sub_3), by=1),post_mean,df=sub_3))
        
        # Per period utility 
        sub_3 <- sub_3 %>% ungroup() %>% 
          mutate(mc_sim = ifelse(healthshock + pred_beliefs*mch_spend2 < ded_c, 1, tot_oop/tot_pay),
                 pay_sim = healthshock + pred_beliefs*mch_spend2 + omega*(1-mc_sim)) %>%
          mutate(pay_sim = ifelse(pay_sim<0,0,pay_sim)) %>% mutate(pay_sim=ifelse(pay_sim>250000,250000,pay_sim)) %>%
          select(-c(mc_sim)) # Don't need the marginal cost hanging around
        sub_3$u_i <- (sub_3$pay_sim - sub_3$healthshock)+
          1/(2*sub_3$omega)*(sub_3$pay_sim - sub_3$healthshock)^2-
          sub_3$tot_oop-prev_meanoop*sub_3$numsignals # TODO: endogenous OOP? 
        
        # Now per period expected utility (need to integrate over distribution of both shocks)
        sub_3$exp_u <- 1:nrow(sub_3) %>% future_map_dbl(function(x) integrate_eui(x,df=sub_3))
        
        # Sum up expected (discounted) future valuations for V_i
        myout <- sub_3 %>% group_by(enrolid) %>% 
          mutate(V_i = ifelse(!is.na(lead(exp_u,n=2)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2), NA)) %>%
          mutate(V_i = ifelse(!is.na(lead(exp_u,n=1)),u_i + delta*lead(exp_u,1), u_i)) %>% 
          select(c("enrolid","year","V_i")) 
        names(myout) <- c("enrolid","year",paste0("seqV_",allcomb$num[i],sep="")) 
        # Select V_i and rename it manually if parallelizing
        return(myout)
        
        # Store this as its own output -- only if NOT PARALLELIZING
        # sub_3[,paste0("seqV_",allcomb$num[i],sep="")] <- sub_3$V_i
        
      }
      # close(pb)
      
      # Convert lists of columns into data.frames
      allouts <- do.call(cbind, allouts)
      allouts <- allouts %>% select(c("enrolid...1","year...2",matches("seqV")))
      names(allouts)[1] <- "enrolid"
      names(allouts)[2] <- "year"
      
      ## STEP 2: Based on predicted expected utilities, solve by backward induction 
      seq_cols <- allouts %>% ungroup() %>% select(matches("seqV")) %>% names()
      # allouts <- allouts %>% ungroup() %>% mutate(rmax=pmax(!!!rlang::syms(seq_cols)))
      
      # Loop backwards through years, construct optimal sequence for individuals 
      myopts <- allouts %>% select(-c("enrolid","year")) %>% ungroup() %>% 
        mutate(optseq = names(.)[max.col(.)]) %>% 
        select(optseq) %>%
        mutate(optseq = as.numeric(substr(optseq,start=6,stop=nchar(optseq))))
      myopts <- cbind(allouts[,c("enrolid","year")],myopts)
      myopts <- myopts %>% 
        left_join(sub_3[,c("enrolid","year","nyear")], 
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>% 
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>% 
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      
      # If individual has the same optimal sequence throughout, keep it
      myopts <- myopts %>% 
        group_by(enrolid) %>% 
        mutate(opts = ifelse(mean(optseq)==max(optseq),optseq,NA)) %>% 
        mutate(opts = ifelse(is.na(opts) & nyear == n(), optseq,opts))
      
      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>% 
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts) 
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })
      
      # For the rest, backward induction for optimal sequence
      myopts <- myopts %>% group_by(enrolid) %>% mutate(myear = n())
      
      # Year n-1 
      tomerge <- myopts %>% group_by(enrolid) %>% 
        mutate(futurechoice = lead(sample_sstar)) %>% 
        filter(nyear==myear-1 & is.na(sample_sstar)) %>% 
        select(c("enrolid","year","futurechoice"))
      allouts <- allouts %>% left_join(tomerge,all.x=T,all.y=F)
      # Now, want to ignore all payoffs that don't fit this criteria
      
      tomerge <- allouts %>% filter(!is.na(futurechoice))
      for (ind in 3:(ncol(tomerge)-1)) {
        tomerge[,ind] <- 1:nrow(tomerge) %>% 
          future_map_dbl(function(x) {
            if (allcomb[ind-2,3] != tomerge[x,]$futurechoice) { return(NA) } 
            return(as.numeric(tomerge[x,ind]))
          })
      }
      
      tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>% 
        mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>% 
        select(optseq_new) %>%
        mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      myopts <- myopts %>% 
        left_join(tomerge2, 
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>% 
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>% 
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      
      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>% 
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts) 
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })
      
      # Year n-2 
      tomerge <- myopts %>% group_by(enrolid) %>% 
        mutate(futurechoice = lead(sample_sstar)) %>% 
        filter(nyear==myear-2 & is.na(sample_sstar)) %>% 
        select(c("enrolid","year","futurechoice"))
      allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # Now, want to ignore all payoffs that don't fit this criteria
      
      tomerge <- allouts %>% filter(!is.na(futurechoice))
      for (ind in 3:(ncol(tomerge)-1)) {
        tomerge[,ind] <- 1:nrow(tomerge) %>% 
          future_map_dbl(function(x) {
            if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
            if (allcomb[ind-2,2] != tomerge[x,]$futurechoice) { return(NA) } 
            return(as.numeric(tomerge[x,ind]))
          })
      }
      
      tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>% 
        mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>% 
        select(optseq_new) %>%
        mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      myopts <- myopts %>% select(-c("optseq_new")) %>% 
        left_join(tomerge2, 
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>% 
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>% 
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      
      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>% 
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts) 
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })
      
      
      sub_3 <- sub_3 %>% left_join(myopts[,c("enrolid","year","sample_sstar")])
      # Store sequence, move on to next! 
  ################
      
  #### FOR INDIVIDUALS OBSERVED FOR 4 YEARS ####
      ## STEP 1: Calculate expected utility for all possible paths of s_{it}
      # All possible combinations of prev visits
      allcomb <- expand.grid(c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4))
      allcomb <- allcomb %>% mutate(num = row_number())
      names(allcomb) <- c("s1","s2","s3","s4","num")
      allcomb <- allcomb %>% 
        mutate(todrop = ifelse(s1-s2>1,1,0)) %>%
        mutate(todrop = ifelse(s2-s3>1,1,todrop)) %>%
        mutate(todrop = ifelse(s3-s4>1,1,todrop)) %>%
        filter(todrop == 0) %>% select(-c("todrop"))
      # Assume that preventive care is sticky going down -- can't reduce by more than one from year to year
      # This is to reduce size of transition state space
      
      # Parallel processing
      clusterExport(my.cluster, "sub_4")
      clusterExport(my.cluster, "allcomb")
      
      # pb = txtProgressBar(min = 1, max = nrow(allcomb), initial = 1) 
      allouts <- foreach (i = 1:nrow(allcomb)) %dopar% { # Calculate V1,V2,V3 and total V for each combination
        # setTxtProgressBar(pb,i)
        
        tomerge <- allcomb[i,] %>% select(-c("num")) %>% 
          pivot_longer(c("s1","s2","s3","s4"),names_to="nyear",names_prefix="s") %>% 
          mutate(nyear = as.numeric(nyear))
        # Match row to individuals based on nyear
        sub_4 <- sub_4 %>% left_join(tomerge,by=c("nyear"),all.x=T,all.y=F) %>% 
          mutate(numsignals = value)  %>% select(-c("value"))
        sub_4$pred_beliefs <- as.numeric(lapply(seq(from=1, to=nrow(sub_4), by=1),post_mean,df=sub_4))
        
        # Per period utility 
        sub_4 <- sub_4 %>% ungroup() %>% 
          mutate(mc_sim = ifelse(healthshock + pred_beliefs*mch_spend2 < ded_c, 1, tot_oop/tot_pay),
                 pay_sim = healthshock + pred_beliefs*mch_spend2 + omega*(1-mc_sim)) %>%
          mutate(pay_sim = ifelse(pay_sim<0,0,pay_sim)) %>% mutate(pay_sim=ifelse(pay_sim>250000,250000,pay_sim)) %>%
          select(-c(mc_sim)) # Don't need the marginal cost hanging around
        sub_4$u_i <- (sub_4$pay_sim - sub_4$healthshock)+
          1/(2*sub_4$omega)*(sub_4$pay_sim - sub_4$healthshock)^2-
          sub_4$tot_oop-prev_meanoop*sub_4$numsignals # TODO: endogenous OOP? 
        
        # Now per period expected utility (need to integrate over distribution of both shocks)
        sub_4$exp_u <- 1:nrow(sub_4) %>% future_map_dbl(function(x) integrate_eui(x,df=sub_4))
        
        # Sum up expected (discounted) future valuations for V_i
        myout <- sub_4 %>% group_by(enrolid) %>% 
          mutate(V_i = ifelse(!is.na(lead(exp_u,n=3)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3), NA)) %>%
          mutate(V_i = ifelse(!is.na(lead(exp_u,n=2)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2), NA)) %>%
          mutate(V_i = ifelse(!is.na(lead(exp_u,n=1)),u_i + delta*lead(exp_u,1), u_i)) %>% 
          select(c("enrolid","year","V_i")) 
        names(myout) <- c("enrolid","year",paste0("seqV_",allcomb$num[i],sep="")) 
        # Select V_i and rename it manually if parallelizing
        return(myout)
        
        # Store this as its own output -- only if NOT PARALLELIZING
        # sub_4[,paste0("seqV_",allcomb$num[i],sep="")] <- sub_4$V_i
        
      }
      # close(pb)
      
      # Convert lists of columns into data.frames
      allouts <- do.call(cbind, allouts)
      allouts <- allouts %>% select(c("enrolid...1","year...2",matches("seqV")))
      names(allouts)[1] <- "enrolid"
      names(allouts)[2] <- "year"
      
      ## STEP 2: Based on predicted expected utilities, solve by backward induction 
      seq_cols <- allouts %>% ungroup() %>% select(matches("seqV")) %>% names()
      # allouts <- allouts %>% ungroup() %>% mutate(rmax=pmax(!!!rlang::syms(seq_cols)))
      
      # Loop backwards through years, construct optimal sequence for individuals 
      myopts <- allouts %>% select(-c("enrolid","year")) %>% ungroup() %>% 
        mutate(optseq = names(.)[max.col(.)]) %>% 
        select(optseq) %>%
        mutate(optseq = as.numeric(substr(optseq,start=6,stop=nchar(optseq))))
      myopts <- cbind(allouts[,c("enrolid","year")],myopts)
      myopts <- myopts %>% 
        left_join(sub_4[,c("enrolid","year","nyear")], 
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>% 
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>% 
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      
      # # Fill in missing years (fill in sequence choice backwards; that is, keep choice from period 4 in period 3 if missing period 3. This won't be added to the merge, just to make sure function doesn't break)
      # myopts <- myopts %>% group_by(enrolid) %>% panel_fill(.i=enrolid,.t=nyear,.set_NA=TRUE) %>% filter(nyear <= 4)
      # myopts <- myopts %>% group_by(enrolid) %>% arrange(enrolid,nyear) %>% mutate(optseq = ifelse(is.na(optseq),lead(optseq),optseq),
      #                                                                              year = ifelse(is.na(year),lead(year)-1,year))
      # myopts <- myopts %>% group_by(enrolid) %>% mutate(todrop=max(is.na(optseq))) %>% filter(todrop == 0) %>% select(-c("todrop"))
      # # Note: this will still drop families missing 2 or more of 4 years, which seems appropriate anyway. 
      # 
      # If individual has the same optimal sequence throughout, keep it
      myopts <- myopts %>% 
        group_by(enrolid) %>% 
        mutate(opts = ifelse(mean(optseq)==max(optseq),optseq,NA)) %>% 
        mutate(opts = ifelse(is.na(opts) & nyear == n(), optseq,opts))
      
      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>% 
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts) 
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })
      
      # For the rest, backward induction for optimal sequence
      myopts <- myopts %>% group_by(enrolid) %>% mutate(myear = n())
    
      # Year n-1 
      tomerge <- myopts %>% group_by(enrolid) %>% 
        mutate(futurechoice = lead(sample_sstar)) %>% 
        filter(nyear==myear-1 & is.na(sample_sstar)) %>% 
        select(c("enrolid","year","futurechoice"))
      allouts <- allouts %>% left_join(tomerge,all.x=T,all.y=F)
      # Now, want to ignore all payoffs that don't fit this criteria
      
      tomerge <- allouts %>% filter(!is.na(futurechoice))
      for (ind in 3:(ncol(tomerge)-1)) {
        tomerge[,ind] <- 1:nrow(tomerge) %>% 
          future_map_dbl(function(x) {
            if (allcomb[ind-2,4] != tomerge[x,]$futurechoice) { return(NA) } 
            return(as.numeric(tomerge[x,ind]))
          })
      }
      
      tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>% 
        mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>% 
        select(optseq_new) %>%
        mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      myopts <- myopts %>% 
        left_join(tomerge2, 
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>% 
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>% 
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      
      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>% 
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts) 
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })
      
      # Year n-2 
      tomerge <- myopts %>% group_by(enrolid) %>% 
        mutate(futurechoice = lead(sample_sstar)) %>% 
        filter(nyear==myear-2 & is.na(sample_sstar)) %>% 
        select(c("enrolid","year","futurechoice"))
      allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # Now, want to ignore all payoffs that don't fit this criteria
      
      tomerge <- allouts %>% filter(!is.na(futurechoice))
      for (ind in 3:(ncol(tomerge)-1)) {
        tomerge[,ind] <- 1:nrow(tomerge) %>% 
          future_map_dbl(function(x) {
            if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
            if (allcomb[ind-2,3] != tomerge[x,]$futurechoice) { return(NA) } 
            return(as.numeric(tomerge[x,ind]))
          })
      }
      
      tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>% 
        mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>% 
        select(optseq_new) %>%
        mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      myopts <- myopts %>% select(-c("optseq_new")) %>% 
        left_join(tomerge2, 
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>% 
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>% 
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      
      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>% 
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts) 
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })
      
      # Year n-3 
      tomerge <- myopts %>% group_by(enrolid) %>% 
        mutate(futurechoice = lead(sample_sstar)) %>% 
        filter(nyear==myear-3 & is.na(sample_sstar)) %>% 
        select(c("enrolid","year","futurechoice"))
      allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # Now, want to ignore all payoffs that don't fit this criteria
      
      tomerge <- allouts %>% filter(!is.na(futurechoice))
      for (ind in 3:(ncol(tomerge)-1)) {
        tomerge[,ind] <- 1:nrow(tomerge) %>% 
          future_map_dbl(function(x) {
            if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
            if (allcomb[ind-2,2] != tomerge[x,]$futurechoice) { return(NA) } 
            return(as.numeric(tomerge[x,ind]))
          })
      }
      
      tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>% 
        mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>% 
        select(optseq_new) %>%
        mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      myopts <- myopts %>% select(-c("optseq_new")) %>% 
        left_join(tomerge2, 
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>% 
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>% 
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      
      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>% 
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts) 
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })
      
      
      sub_4 <- sub_4 %>% left_join(myopts[,c("enrolid","year","sample_sstar")])
      # Store sequence, move on to next! 
  ################
      
  #### FOR INDIVIDUALS OBSERVED FOR 5 YEARS ####
      ## STEP 1: Calculate expected utility for all possible paths of s_{it}
      # All possible combinations of prev visits
      allcomb <- expand.grid(c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4))
      allcomb <- allcomb %>% mutate(num = row_number())
      names(allcomb) <- c("s1","s2","s3","s4","s5","num")
      allcomb <- allcomb %>%
        mutate(todrop = ifelse(s1-s2>1,1,0)) %>%
        mutate(todrop = ifelse(s2-s3>1,1,todrop)) %>%
        mutate(todrop = ifelse(s3-s4>1,1,todrop)) %>%
        mutate(todrop = ifelse(s4-s5>1,1,todrop)) %>%
        filter(todrop == 0) %>% select(-c("todrop"))
      # Assume that preventive care is sticky going down -- can't reduce by more than one from year to year
      # This is to reduce size of transition state space

      # Parallel processing
      clusterExport(my.cluster, "sub_5")
      clusterExport(my.cluster, "allcomb")

      # pb = txtProgressBar(min = 1, max = nrow(allcomb), initial = 1)
      allouts <- foreach (i = 1:nrow(allcomb)) %dopar% { # Calculate V1,V2,V3 and total V for each combination
        # setTxtProgressBar(pb,i)

        tomerge <- allcomb[i,] %>% select(-c("num")) %>%
          pivot_longer(c("s1","s2","s3","s4","s5"),names_to="nyear",names_prefix="s") %>%
          mutate(nyear = as.numeric(nyear))
        # Match row to individuals based on nyear
        sub_5 <- sub_5 %>% left_join(tomerge,by=c("nyear"),all.x=T,all.y=F) %>%
          mutate(numsignals = value)  %>% select(-c("value"))
        sub_5$pred_beliefs <- as.numeric(lapply(seq(from=1, to=nrow(sub_5), by=1),post_mean,df=sub_5))

        # Per period utility
        sub_5 <- sub_5 %>% ungroup() %>%
          mutate(mc_sim = ifelse(healthshock + pred_beliefs*mch_spend2 < ded_c, 1, tot_oop/tot_pay),
                 pay_sim = healthshock + pred_beliefs*mch_spend2 + omega*(1-mc_sim)) %>%
          mutate(pay_sim = ifelse(pay_sim<0,0,pay_sim)) %>% mutate(pay_sim=ifelse(pay_sim>250000,250000,pay_sim)) %>%
          select(-c(mc_sim)) # Don't need the marginal cost hanging around
        sub_5$u_i <- (sub_5$pay_sim - sub_5$healthshock)+
          1/(2*sub_5$omega)*(sub_5$pay_sim - sub_5$healthshock)^2-
          sub_5$tot_oop-prev_meanoop*sub_5$numsignals # TODO: endogenous OOP?

        # Now per period expected utility (need to integrate over distribution of both shocks)
        sub_5$exp_u <- 1:nrow(sub_5) %>% future_map_dbl(function(x) integrate_eui(x,df=sub_5))

        # Sum up expected (discounted) future valuations for V_i
        myout <- sub_5 %>% group_by(enrolid) %>%
          mutate(V_i = ifelse(!is.na(lead(exp_u,n=4)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3)+ delta^4*lead(exp_u,4), NA)) %>%
          mutate(V_i = ifelse(!is.na(lead(exp_u,n=3)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3), NA)) %>%
          mutate(V_i = ifelse(!is.na(lead(exp_u,n=2)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2), NA)) %>%
          mutate(V_i = ifelse(!is.na(lead(exp_u,n=1)),u_i + delta*lead(exp_u,1), u_i)) %>%
          select(c("enrolid","year","V_i"))
        names(myout) <- c("enrolid","year",paste0("seqV_",allcomb$num[i],sep=""))
        # Select V_i and rename it manually if parallelizing
        return(myout)

        # Store this as its own output -- only if NOT PARALLELIZING
        # sub_5[,paste0("seqV_",allcomb$num[i],sep="")] <- sub_5$V_i

      }
      # close(pb)

      # Convert lists of columns into data.frames
      allouts <- do.call(cbind, allouts)
      allouts <- allouts %>% select(c("enrolid...1","year...2",matches("seqV")))
      names(allouts)[1] <- "enrolid"
      names(allouts)[2] <- "year"

      ## STEP 2: Based on predicted expected utilities, solve by backward induction
      seq_cols <- allouts %>% ungroup() %>% select(matches("seqV")) %>% names()
      # allouts <- allouts %>% ungroup() %>% mutate(rmax=pmax(!!!rlang::syms(seq_cols)))

      # Loop backwards through years, construct optimal sequence for individuals
      myopts <- allouts %>% select(-c("enrolid","year")) %>% ungroup() %>%
        mutate(optseq = names(.)[max.col(.)]) %>%
        select(optseq) %>%
        mutate(optseq = as.numeric(substr(optseq,start=6,stop=nchar(optseq))))
      myopts <- cbind(allouts[,c("enrolid","year")],myopts)
      myopts <- myopts %>%
        left_join(sub_5[,c("enrolid","year","nyear")],
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>%
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers

      # If individual has the same optimal sequence throughout, keep it
      myopts <- myopts %>%
        group_by(enrolid) %>%
        mutate(opts = ifelse(mean(optseq)==max(optseq),optseq,NA)) %>%
        mutate(opts = ifelse(is.na(opts) & nyear == n(), optseq,opts))

      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>%
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts)
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })

      # For the rest, backward induction for optimal sequence
      myopts <- myopts %>% group_by(enrolid) %>% mutate(myear = n())

      # Year n-1
      tomerge <- myopts %>% group_by(enrolid) %>%
        mutate(futurechoice = lead(sample_sstar)) %>%
        filter(nyear==myear-1 & is.na(sample_sstar)) %>%
        select(c("enrolid","year","futurechoice"))
      allouts <- allouts %>% left_join(tomerge,all.x=T,all.y=F)
      # Now, want to ignore all payoffs that don't fit this criteria

      tomerge <- allouts %>% filter(!is.na(futurechoice))
      for (ind in 3:(ncol(tomerge)-1)) {
        tomerge[,ind] <- 1:nrow(tomerge) %>%
          future_map_dbl(function(x) {
            if (allcomb[ind-2,5] != tomerge[x,]$futurechoice) { return(NA) }
            return(as.numeric(tomerge[x,ind]))
          })
      }

      tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
        mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
        select(optseq_new) %>%
        mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      myopts <- myopts %>%
        left_join(tomerge2,
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>%
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))

      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>%
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts)
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })

      # Year n-2
      tomerge <- myopts %>% group_by(enrolid) %>%
        mutate(futurechoice = lead(sample_sstar)) %>%
        filter(nyear==myear-2 & is.na(sample_sstar)) %>%
        select(c("enrolid","year","futurechoice"))
      allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # Now, want to ignore all payoffs that don't fit this criteria

      tomerge <- allouts %>% filter(!is.na(futurechoice))
      for (ind in 3:(ncol(tomerge)-1)) {
        tomerge[,ind] <- 1:nrow(tomerge) %>%
          future_map_dbl(function(x) {
            if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
            if (allcomb[ind-2,4] != tomerge[x,]$futurechoice) { return(NA) }
            return(as.numeric(tomerge[x,ind]))
          })
      }

      tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
        mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
        select(optseq_new) %>%
        mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      myopts <- myopts %>% select(-c("optseq_new")) %>%
        left_join(tomerge2,
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>%
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))

      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>%
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts)
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })

      # Year n-3
      tomerge <- myopts %>% group_by(enrolid) %>%
        mutate(futurechoice = lead(sample_sstar)) %>%
        filter(nyear==myear-3 & is.na(sample_sstar)) %>%
        select(c("enrolid","year","futurechoice"))
      allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # Now, want to ignore all payoffs that don't fit this criteria

      tomerge <- allouts %>% filter(!is.na(futurechoice))
      for (ind in 3:(ncol(tomerge)-1)) {
        tomerge[,ind] <- 1:nrow(tomerge) %>%
          future_map_dbl(function(x) {
            if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
            if (allcomb[ind-2,3] != tomerge[x,]$futurechoice) { return(NA) }
            return(as.numeric(tomerge[x,ind]))
          })
      }

      tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
        mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
        select(optseq_new) %>%
        mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      myopts <- myopts %>% select(-c("optseq_new")) %>%
        left_join(tomerge2,
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>%
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))

      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>%
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts)
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })

      # Year n-4
      tomerge <- myopts %>% group_by(enrolid) %>%
        mutate(futurechoice = lead(sample_sstar)) %>%
        filter(nyear==myear-4 & is.na(sample_sstar)) %>%
        select(c("enrolid","year","futurechoice"))
      allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # Now, want to ignore all payoffs that don't fit this criteria

      tomerge <- allouts %>% filter(!is.na(futurechoice))
      for (ind in 3:(ncol(tomerge)-1)) {
        tomerge[,ind] <- 1:nrow(tomerge) %>%
          future_map_dbl(function(x) {
            if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
            if (allcomb[ind-2,2] != tomerge[x,]$futurechoice) { return(NA) }
            return(as.numeric(tomerge[x,ind]))
          })
      }

      tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
        mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
        select(optseq_new) %>%
        mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      myopts <- myopts %>% select(-c("optseq_new")) %>%
        left_join(tomerge2,
                  by=c("enrolid","year"),
                  all.x=T, all.y=F) %>%
        group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
        filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))

      # Now for the matches, pull in optimal sequence
      myopts$sample_sstar <- 1:nrow(myopts) %>%
        future_map_dbl(function(x) {
          myout <- allcomb %>% filter(num == myopts[x,]$opts)
          if (nrow(myout) == 0) { return(NA) }
          c <- myopts[x,]$nyear
          return(as.numeric(myout[,c]))
        })


      sub_5 <- sub_5 %>% left_join(myopts[,c("enrolid","year","sample_sstar")])
      # Store sequence, move on to next!
    ################
      
      # #### FOR INDIVIDUALS OBSERVED FOR 6 YEARS ####
      # ## STEP 1: Calculate expected utility for all possible paths of s_{it}
      # # All possible combinations of prev visits
      # allcomb <- expand.grid(c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4))
      # allcomb <- allcomb %>% mutate(num = row_number())
      # names(allcomb) <- c("s1","s2","s3","s4","s5","s6","num")
      # allcomb <- allcomb %>%
      #   mutate(todrop = ifelse(s1-s2>1,1,0)) %>%
      #   mutate(todrop = ifelse(s2-s3>1,1,todrop)) %>%
      #   mutate(todrop = ifelse(s3-s4>1,1,todrop)) %>%
      #   mutate(todrop = ifelse(s4-s5>1,1,todrop)) %>%
      #   mutate(todrop = ifelse(s5-s6>1,1,todrop)) %>%
      #   filter(todrop == 0) %>% select(-c("todrop"))
      # # Assume that preventive care is sticky going down -- can't reduce by more than one from year to year
      # # This is to reduce size of transition state space
      # 
      # # Parallel processing
      # clusterExport(my.cluster, "sub_6")
      # clusterExport(my.cluster, "allcomb")
      # 
      # # pb = txtProgressBar(min = 1, max = nrow(allcomb), initial = 1)
      # allouts <- foreach (i = 1:nrow(allcomb)) %dopar% { # Calculate V1,V2,V3 and total V for each combination
      #   # setTxtProgressBar(pb,i)
      #   
      #   tomerge <- allcomb[i,] %>% select(-c("num")) %>%
      #     pivot_longer(c("s1","s2","s3","s4","s5","s6"),names_to="nyear",names_prefix="s") %>%
      #     mutate(nyear = as.numeric(nyear))
      #   # Match row to individuals based on nyear
      #   sub_6 <- sub_6 %>% left_join(tomerge,by=c("nyear"),all.x=T,all.y=F) %>%
      #     mutate(numsignals = value)  %>% select(-c("value"))
      #   sub_6$pred_beliefs <- as.numeric(lapply(seq(from=1, to=nrow(sub_6), by=1),post_mean,df=sub_6))
      #   
      #   # Per period utility
      #   sub_6 <- sub_6 %>% ungroup() %>%
      #     mutate(mc_sim = ifelse(healthshock + pred_beliefs*mch_spend2 < ded_c, 1, tot_oop/tot_pay),
      #            pay_sim = healthshock + pred_beliefs*mch_spend2 + omega*(1-mc_sim)) %>%
      #     mutate(pay_sim = ifelse(pay_sim<0,0,pay_sim)) %>% mutate(pay_sim=ifelse(pay_sim>250000,250000,pay_sim)) %>%
      #     select(-c(mc_sim)) # Don't need the marginal cost hanging around
      #   sub_6$u_i <- (sub_6$pay_sim - sub_6$healthshock)+
      #     1/(2*sub_6$omega)*(sub_6$pay_sim - sub_6$healthshock)^2-
      #     sub_6$tot_oop-prev_meanoop*sub_6$numsignals # TODO: endogenous OOP?
      #   
      #   # Now per period expected utility (need to integrate over distribution of both shocks)
      #   sub_6$exp_u <- 1:nrow(sub_6) %>% future_map_dbl(function(x) integrate_eui(x,df=sub_6))
      #   
      #   # Sum up expected (discounted) future valuations for V_i
      #   myout <- sub_6 %>% group_by(enrolid) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=5)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3)+ delta^4*lead(exp_u,4)+ delta^5*lead(exp_u,5), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=4)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3)+ delta^4*lead(exp_u,4), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=3)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=2)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=1)),u_i + delta*lead(exp_u,1), u_i)) %>%
      #     select(c("enrolid","year","V_i"))
      #   names(myout) <- c("enrolid","year",paste0("seqV_",allcomb$num[i],sep=""))
      #   # Select V_i and rename it manually if parallelizing
      #   return(myout)
      #   
      #   # Store this as its own output -- only if NOT PARALLELIZING
      #   # sub_6[,paste0("seqV_",allcomb$num[i],sep="")] <- sub_6$V_i
      #   
      # }
      # # close(pb)
      # 
      # # Convert lists of columns into data.frames
      # allouts <- do.call(cbind, allouts)
      # allouts <- allouts %>% select(c("enrolid...1","year...2",matches("seqV")))
      # names(allouts)[1] <- "enrolid"
      # names(allouts)[2] <- "year"
      # 
      # ## STEP 2: Based on predicted expected utilities, solve by backward induction
      # seq_cols <- allouts %>% ungroup() %>% select(matches("seqV")) %>% names()
      # # allouts <- allouts %>% ungroup() %>% mutate(rmax=pmax(!!!rlang::syms(seq_cols)))
      # 
      # # Loop backwards through years, construct optimal sequence for individuals
      # myopts <- allouts %>% select(-c("enrolid","year")) %>% ungroup() %>%
      #   mutate(optseq = names(.)[max.col(.)]) %>%
      #   select(optseq) %>%
      #   mutate(optseq = as.numeric(substr(optseq,start=6,stop=nchar(optseq))))
      # myopts <- cbind(allouts[,c("enrolid","year")],myopts)
      # myopts <- myopts %>%
      #   left_join(sub_6[,c("enrolid","year","nyear")],
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # 
      # # If individual has the same optimal sequence throughout, keep it
      # myopts <- myopts %>%
      #   group_by(enrolid) %>%
      #   mutate(opts = ifelse(mean(optseq)==max(optseq),optseq,NA)) %>%
      #   mutate(opts = ifelse(is.na(opts) & nyear == n(), optseq,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # For the rest, backward induction for optimal sequence
      # myopts <- myopts %>% group_by(enrolid) %>% mutate(myear = n())
      # 
      # # Year n-1
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-1 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (allcomb[ind-2,6] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-2
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-2 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,5] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-3
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-3 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,4] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-4
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-4 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,3] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-5
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-5 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,2] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # 
      # sub_6 <- sub_6 %>% left_join(myopts[,c("enrolid","year","sample_sstar")])
      # # Store sequence, move on to next!
      # ################
      # 
      # #### FOR INDIVIDUALS OBSERVED FOR 7 YEARS ####
      # ## STEP 1: Calculate expected utility for all possible paths of s_{it}
      # # All possible combinations of prev visits
      # allcomb <- expand.grid(c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4))
      # allcomb <- allcomb %>% mutate(num = row_number())
      # names(allcomb) <- c("s1","s2","s3","s4","s5","s6","s7","num")
      # allcomb <- allcomb %>%
      #   mutate(todrop = ifelse(s1-s2>1,1,0)) %>%
      #   mutate(todrop = ifelse(s2-s3>1,1,todrop)) %>%
      #   mutate(todrop = ifelse(s3-s4>1,1,todrop)) %>%
      #   mutate(todrop = ifelse(s4-s5>1,1,todrop)) %>%
      #   mutate(todrop = ifelse(s5-s6>1,1,todrop)) %>%
      #   mutate(todrop = ifelse(s6-s7>1,1,todrop)) %>%
      #   filter(todrop == 0) %>% select(-c("todrop"))
      # # Assume that preventive care is sticky going down -- can't reduce by more than one from year to year
      # # This is to reduce size of transition state space
      # 
      # # Parallel processing
      # clusterExport(my.cluster, "sub_7")
      # clusterExport(my.cluster, "allcomb")
      # 
      # # pb = txtProgressBar(min = 1, max = nrow(allcomb), initial = 1)
      # allouts <- foreach (i = 1:nrow(allcomb)) %dopar% { # Calculate V1,V2,V3 and total V for each combination
      #   # setTxtProgressBar(pb,i)
      #   
      #   tomerge <- allcomb[i,] %>% select(-c("num")) %>%
      #     pivot_longer(c("s1","s2","s3","s4","s5","s6","s7"),names_to="nyear",names_prefix="s") %>%
      #     mutate(nyear = as.numeric(nyear))
      #   # Match row to individuals based on nyear
      #   sub_7 <- sub_7 %>% left_join(tomerge,by=c("nyear"),all.x=T,all.y=F) %>%
      #     mutate(numsignals = value)  %>% select(-c("value"))
      #   sub_7$pred_beliefs <- as.numeric(lapply(seq(from=1, to=nrow(sub_7), by=1),post_mean,df=sub_7))
      #   
      #   # Per period utility
      #   sub_7 <- sub_7 %>% ungroup() %>%
      #     mutate(mc_sim = ifelse(healthshock + pred_beliefs*mch_spend2 < ded_c, 1, tot_oop/tot_pay),
      #            pay_sim = healthshock + pred_beliefs*mch_spend2 + omega*(1-mc_sim)) %>%
      #     mutate(pay_sim = ifelse(pay_sim<0,0,pay_sim)) %>% mutate(pay_sim=ifelse(pay_sim>250000,250000,pay_sim)) %>%
      #     select(-c(mc_sim)) # Don't need the marginal cost hanging around
      #   sub_7$u_i <- (sub_7$pay_sim - sub_7$healthshock)+
      #     1/(2*sub_7$omega)*(sub_7$pay_sim - sub_7$healthshock)^2-
      #     sub_7$tot_oop-prev_meanoop*sub_7$numsignals # TODO: endogenous OOP?
      #   
      #   # Now per period expected utility (need to integrate over distribution of both shocks)
      #   sub_7$exp_u <- 1:nrow(sub_7) %>% future_map_dbl(function(x) integrate_eui(x,df=sub_7))
      #   
      #   # Sum up expected (discounted) future valuations for V_i
      #   myout <- sub_7 %>% group_by(enrolid) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=6)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3)+ delta^4*lead(exp_u,4)+ delta^5*lead(exp_u,5)+ delta^6*lead(exp_u,6), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=5)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3)+ delta^4*lead(exp_u,4)+ delta^5*lead(exp_u,5), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=4)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3)+ delta^4*lead(exp_u,4), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=3)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=2)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=1)),u_i + delta*lead(exp_u,1), u_i)) %>%
      #     select(c("enrolid","year","V_i"))
      #   names(myout) <- c("enrolid","year",paste0("seqV_",allcomb$num[i],sep=""))
      #   # Select V_i and rename it manually if parallelizing
      #   return(myout)
      #   
      #   # Store this as its own output -- only if NOT PARALLELIZING
      #   # sub_7[,paste0("seqV_",allcomb$num[i],sep="")] <- sub_7$V_i
      #   
      # }
      # # close(pb)
      # 
      # # Convert lists of columns into data.frames
      # allouts <- do.call(cbind, allouts)
      # allouts <- allouts %>% select(c("enrolid...1","year...2",matches("seqV")))
      # names(allouts)[1] <- "enrolid"
      # names(allouts)[2] <- "year"
      # 
      # ## STEP 2: Based on predicted expected utilities, solve by backward induction
      # seq_cols <- allouts %>% ungroup() %>% select(matches("seqV")) %>% names()
      # # allouts <- allouts %>% ungroup() %>% mutate(rmax=pmax(!!!rlang::syms(seq_cols)))
      # 
      # # Loop backwards through years, construct optimal sequence for individuals
      # myopts <- allouts %>% select(-c("enrolid","year")) %>% ungroup() %>%
      #   mutate(optseq = names(.)[max.col(.)]) %>%
      #   select(optseq) %>%
      #   mutate(optseq = as.numeric(substr(optseq,start=6,stop=nchar(optseq))))
      # myopts <- cbind(allouts[,c("enrolid","year")],myopts)
      # myopts <- myopts %>%
      #   left_join(sub_7[,c("enrolid","year","nyear")],
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # 
      # # If individual has the same optimal sequence throughout, keep it
      # myopts <- myopts %>%
      #   group_by(enrolid) %>%
      #   mutate(opts = ifelse(mean(optseq)==max(optseq),optseq,NA)) %>%
      #   mutate(opts = ifelse(is.na(opts) & nyear == n(), optseq,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # For the rest, backward induction for optimal sequence
      # myopts <- myopts %>% group_by(enrolid) %>% mutate(myear = n())
      # 
      # # Year n-1
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-1 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (allcomb[ind-2,7] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-2
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-2 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,6] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-3
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-3 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,5] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-4
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-4 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,4] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-5
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-5 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,3] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # 
      # # Year n-6
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-6 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,2] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # 
      # sub_7 <- sub_7 %>% left_join(myopts[,c("enrolid","year","sample_sstar")])
      # # Store sequence, move on to next!
      # ################
      # 
      # #### FOR INDIVIDUALS OBSERVED FOR 8 YEARS ####
      # ## STEP 1: Calculate expected utility for all possible paths of s_{it}
      # # All possible combinations of prev visits
      # allcomb <- expand.grid(c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4),c(0,1,2,3,4))
      # allcomb <- allcomb %>% mutate(num = row_number())
      # names(allcomb) <- c("s1","s2","s3","s4","s5","s6","s7","s8","num")
      # allcomb <- allcomb %>%
      #   mutate(todrop = ifelse(s1-s2>1,1,0)) %>%
      #   mutate(todrop = ifelse(s2-s3>1,1,todrop)) %>%
      #   mutate(todrop = ifelse(s3-s4>1,1,todrop)) %>%
      #   mutate(todrop = ifelse(s4-s5>1,1,todrop)) %>%
      #   mutate(todrop = ifelse(s5-s6>1,1,todrop)) %>%
      #   mutate(todrop = ifelse(s6-s7>1,1,todrop)) %>%
      #   mutate(todrop = ifelse(s7-s8>1,1,todrop)) %>%
      #   filter(todrop == 0) %>% select(-c("todrop"))
      # # Assume that preventive care is sticky going down -- can't reduce by more than one from year to year
      # # This is to reduce size of transition state space
      # 
      # # Parallel processing
      # clusterExport(my.cluster, "sub_8")
      # clusterExport(my.cluster, "allcomb")
      # 
      # # pb = txtProgressBar(min = 1, max = nrow(allcomb), initial = 1)
      # allouts <- foreach (i = 1:nrow(allcomb)) %dopar% { # Calculate V1,V2,V3 and total V for each combination
      #   # setTxtProgressBar(pb,i)
      #   
      #   tomerge <- allcomb[i,] %>% select(-c("num")) %>%
      #     pivot_longer(c("s1","s2","s3","s4","s5","s6","s7","s8"),names_to="nyear",names_prefix="s") %>%
      #     mutate(nyear = as.numeric(nyear))
      #   # Match row to individuals based on nyear
      #   sub_8 <- sub_8 %>% left_join(tomerge,by=c("nyear"),all.x=T,all.y=F) %>%
      #     mutate(numsignals = value)  %>% select(-c("value"))
      #   sub_8$pred_beliefs <- as.numeric(lapply(seq(from=1, to=nrow(sub_8), by=1),post_mean,df=sub_8))
      #   
      #   # Per period utility
      #   sub_8 <- sub_8 %>% ungroup() %>%
      #     mutate(mc_sim = ifelse(healthshock + pred_beliefs*mch_spend2 < ded_c, 1, tot_oop/tot_pay),
      #            pay_sim = healthshock + pred_beliefs*mch_spend2 + omega*(1-mc_sim)) %>%
      #     mutate(pay_sim = ifelse(pay_sim<0,0,pay_sim)) %>% mutate(pay_sim=ifelse(pay_sim>250000,250000,pay_sim)) %>%
      #     select(-c(mc_sim)) # Don't need the marginal cost hanging around
      #   sub_8$u_i <- (sub_8$pay_sim - sub_8$healthshock)+
      #     1/(2*sub_8$omega)*(sub_8$pay_sim - sub_8$healthshock)^2-
      #     sub_8$tot_oop-prev_meanoop*sub_8$numsignals # TODO: endogenous OOP?
      #   
      #   # Now per period expected utility (need to integrate over distribution of both shocks)
      #   sub_8$exp_u <- 1:nrow(sub_8) %>% future_map_dbl(function(x) integrate_eui(x,df=sub_8))
      #   
      #   # Sum up expected (discounted) future valuations for V_i
      #   myout <- sub_8 %>% group_by(enrolid) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=7)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3)+ delta^4*lead(exp_u,4)+ delta^5*lead(exp_u,5)+ delta^6*lead(exp_u,6)+ delta^7*lead(exp_u,7), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=6)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3)+ delta^4*lead(exp_u,4)+ delta^5*lead(exp_u,5)+ delta^6*lead(exp_u,6), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=5)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3)+ delta^4*lead(exp_u,4)+ delta^5*lead(exp_u,5), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=4)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3)+ delta^4*lead(exp_u,4), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=3)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2)+ delta^3*lead(exp_u,3), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=2)),u_i + delta*lead(exp_u,1) + delta^2*lead(exp_u,2), NA)) %>%
      #     mutate(V_i = ifelse(!is.na(lead(exp_u,n=1)),u_i + delta*lead(exp_u,1), u_i)) %>%
      #     select(c("enrolid","year","V_i"))
      #   names(myout) <- c("enrolid","year",paste0("seqV_",allcomb$num[i],sep=""))
      #   # Select V_i and rename it manually if parallelizing
      #   return(myout)
      #   
      #   # Store this as its own output -- only if NOT PARALLELIZING
      #   # sub_8[,paste0("seqV_",allcomb$num[i],sep="")] <- sub_8$V_i
      #   
      # }
      # # close(pb)
      # 
      # # Convert lists of columns into data.frames
      # allouts <- do.call(cbind, allouts)
      # allouts <- allouts %>% select(c("enrolid...1","year...2",matches("seqV")))
      # names(allouts)[1] <- "enrolid"
      # names(allouts)[2] <- "year"
      # 
      # ## STEP 2: Based on predicted expected utilities, solve by backward induction
      # seq_cols <- allouts %>% ungroup() %>% select(matches("seqV")) %>% names()
      # # allouts <- allouts %>% ungroup() %>% mutate(rmax=pmax(!!!rlang::syms(seq_cols)))
      # 
      # # Loop backwards through years, construct optimal sequence for individuals
      # myopts <- allouts %>% select(-c("enrolid","year")) %>% ungroup() %>%
      #   mutate(optseq = names(.)[max.col(.)]) %>%
      #   select(optseq) %>%
      #   mutate(optseq = as.numeric(substr(optseq,start=6,stop=nchar(optseq))))
      # myopts <- cbind(allouts[,c("enrolid","year")],myopts)
      # myopts <- myopts %>%
      #   left_join(sub_8[,c("enrolid","year","nyear")],
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # 
      # # If individual has the same optimal sequence throughout, keep it
      # myopts <- myopts %>%
      #   group_by(enrolid) %>%
      #   mutate(opts = ifelse(mean(optseq)==max(optseq),optseq,NA)) %>%
      #   mutate(opts = ifelse(is.na(opts) & nyear == n(), optseq,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # For the rest, backward induction for optimal sequence
      # myopts <- myopts %>% group_by(enrolid) %>% mutate(myear = n())
      # 
      # # Year n-1
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-1 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (allcomb[ind-2,8] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-2
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-2 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,7] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-3
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-3 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,6] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-4
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-4 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,5] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-5
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-5 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,4] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # 
      # # Year n-6
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-6 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,3] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # # Year n-7
      # tomerge <- myopts %>% group_by(enrolid) %>%
      #   mutate(futurechoice = lead(sample_sstar)) %>%
      #   filter(nyear==myear-7 & is.na(sample_sstar)) %>%
      #   select(c("enrolid","year","futurechoice"))
      # allouts <- allouts %>% select(-c("futurechoice")) %>% left_join(tomerge,all.x=T,all.y=F)
      # # Now, want to ignore all payoffs that don't fit this criteria
      # 
      # tomerge <- allouts %>% filter(!is.na(futurechoice))
      # for (ind in 3:(ncol(tomerge)-1)) {
      #   tomerge[,ind] <- 1:nrow(tomerge) %>%
      #     future_map_dbl(function(x) {
      #       if (is.na(tomerge[x,ind])) { return(NA) } # Don't need to look again
      #       if (allcomb[ind-2,2] != tomerge[x,]$futurechoice) { return(NA) }
      #       return(as.numeric(tomerge[x,ind]))
      #     })
      # }
      # 
      # tomerge2 <- tomerge %>% select(-c("enrolid","year","futurechoice")) %>% ungroup() %>%
      #   mutate(optseq_new = names(.)[max.col(replace(., is.na(.), -Inf))]) %>%
      #   select(optseq_new) %>%
      #   mutate(optseq_new = as.numeric(substr(optseq_new,start=6,stop=nchar(optseq_new))))
      # tomerge2 <- cbind(tomerge[,c("enrolid","year")],tomerge2)
      # myopts <- myopts %>% select(-c("optseq_new")) %>%
      #   left_join(tomerge2,
      #             by=c("enrolid","year"),
      #             all.x=T, all.y=F) %>%
      #   group_by(enrolid) %>% mutate(todrop = max(is.na(optseq))) %>%
      #   filter(todrop != 1) %>% select(-c("todrop")) # Drop those without maximizers
      # myopts <- myopts %>% mutate(opts = ifelse(is.na(opts),optseq_new,opts))
      # 
      # # Now for the matches, pull in optimal sequence
      # myopts$sample_sstar <- 1:nrow(myopts) %>%
      #   future_map_dbl(function(x) {
      #     myout <- allcomb %>% filter(num == myopts[x,]$opts)
      #     if (nrow(myout) == 0) { return(NA) }
      #     c <- myopts[x,]$nyear
      #     return(as.numeric(myout[,c]))
      #   })
      # 
      # sub_8 <- sub_8 %>% left_join(myopts[,c("enrolid","year","sample_sstar")])
      # # Store sequence, move on to next!
      # ################
  
  ## STEP 3: Once s_{it} is calculated, recalculate pay_sim once more
  # Stack results
  SMData_20210301 <- rbind(sub_2,sub_3,sub_4,sub_5)#,sub_6,sub_7,sub_8) 
  rm(sub_2,sub_3,sub_4,sub_5,sub_6,sub_7,sub_8,tomerge,tomerge2,allcomb,allouts,myopts)
  SMData_20210301 <- SMData_20210301 %>% group_by(enrolid) %>% 
    mutate(todrop = max(is.na(sample_sstar))) %>% filter(todrop == 0) %>% select(-c("todrop"))
  
  # Recalculate m_star
  # Match row to individuals based on nyear
  SMData_20210301$numsignals <- SMData_20210301$sample_sstar
  SMData_20210301$pred_beliefs <- as.numeric(lapply(seq(from=1, to=nrow(SMData_20210301), by=1),post_mean,df=SMData_20210301))
  
  # Per period utility 
  SMData_20210301 <- SMData_20210301 %>% ungroup() %>% 
    mutate(mc_sim = ifelse(healthshock + pred_beliefs*mch_spend2 < ded_c, 1, tot_oop/tot_pay),
           pay_sim = healthshock + pred_beliefs*mch_spend2 + omega*(1-mc_sim)) %>%
    mutate(pay_sim = ifelse(pay_sim<0,0,pay_sim)) %>% mutate(pay_sim=ifelse(pay_sim>250000,250000,pay_sim)) %>%
    select(-c(mc_sim)) # Don't need the marginal cost hanging around
  
  ## STEP 4: Now calculate difference in moments: 
  # RMSPE spending, Predicted mean/median spending, RMSPE prev_visits, predicted mean/median prev visits, DD coefficients on asinh(spending) + asinh(num_visits) 
  
  # RMSPE moments
  moment_payRMSPE <- SMData_20210301 %>% mutate(diff = (pay_sim - tot_pay)^2) %>%
    ungroup() %>% summarize(diff = sqrt(mean(diff,na.rm=T))) %>% as.numeric()
  moment_prevRMSPE <- SMData_20210301 %>% mutate(diff = (sample_sstar - simple_visits)^2) %>%
    ungroup() %>% summarize(diff = sqrt(mean(diff,na.rm=T))) %>% as.numeric()
  
  # Mean/median spending/prev visits
  moment_payMean <- abs(mean(SMData_20210301$tot_pay)-mean(SMData_20210301$pay_sim,na.rm=T))
  moment_payMed <- abs(median(SMData_20210301$tot_pay)-median(SMData_20210301$pay_sim,na.rm=T))
  moment_prevMean <- abs(mean(SMData_20210301$sample_sstar)-mean(SMData_20210301$simple_visits,na.rm=T))
  moment_prevMed <- abs(median(SMData_20210301$sample_sstar)-median(SMData_20210301$simple_visits,na.rm=T))
  
  # DD coefficients on effect of chronic illness on non-diagnosed spending/prev (asinh and poisson)
  coef_pop_pay <- feols(asinh(tot_pay)~treated_post | famid + year, data=SMData_20210301 %>% filter(todrop_c == 0))$coefficients[1]
  coef_samp_pay <- feols(asinh(pay_sim)~treated_post | famid + year, data=SMData_20210301 %>% filter(todrop_c == 0))$coefficients[1]
  moment_payDD <- abs(coef_pop_pay-coef_samp_pay)
  coef_pop_prev <- fepois(simple_visits~treated_post | famid + year, data=SMData_20210301 %>% filter(todrop_c == 0))$coefficients[1]
  coef_samp_prev <- fepois(sample_sstar~treated_post | famid + year, data=SMData_20210301 %>% filter(todrop_c == 0))$coefficients[1]
  moment_prevDD <- abs(coef_pop_prev-coef_samp_prev)
  
  # If these regressions don't work, then prediction is very bad
  if (!exists("moment_payDD")) { moment_payDD <- Inf }
  if (!exists("moment_prevDD")) { moment_prevDD <- Inf }
  moment_payDD <- ifelse(is.na(moment_payDD),Inf,moment_payDD)
  moment_prevDD <- ifelse(is.na(moment_prevDD),Inf,moment_prevDD)
  
  # Rescale all moments and combine into loss function 
  # Scale by SD of tot_pay and sample_sstar
  moment_payMean <- moment_payMean/sd(SMData_20210301$tot_pay, na.rm=T)
  moment_payMed <- moment_payMed/sd(SMData_20210301$tot_pay, na.rm=T)
  moment_payRMSPE <- moment_payRMSPE/sd(SMData_20210301$tot_pay, na.rm=T)
  moment_prevMean <- moment_prevMean/sd(SMData_20210301$simple_visits, na.rm=T)
  moment_prevMed <- moment_prevMed/sd(SMData_20210301$simple_visits, na.rm=T)
  moment_prevRMSPE <- moment_prevRMSPE/sd(SMData_20210301$simple_visits, na.rm=T)
  
  # Scale DD coefficients by SD of asinh(tot_pay) and log(numvisits+1)
  moment_payDD <- moment_payDD / sd(asinh(SMData_20210301$tot_pay),na.rm=T)
  moment_prevDD <- moment_prevDD / sd(log(SMData_20210301$simple_visits+1),na.rm=T)
  # Store Moments into vector 
  outvec <- data.frame(t(c(changed, direction, moment_payMean, moment_payMed, moment_payRMSPE, moment_payDD, moment_prevMean, moment_prevMed, moment_prevRMSPE, moment_prevDD)))
  
  ## STEP 5: Save moments 
  write.table(outvec, file = "/project/caretaking/Outputs/StructuralModel/Updated_20221201/MomentMeasure.csv", append = TRUE,
              quote = TRUE, sep=" , ", row.names = FALSE, col.names = FALSE)

parallel::stopCluster(cl = my.cluster)
################################################################################
#!/bin/bash -l
#
# Name job
#$ -N FiniteDifferences3-2
#
# If you ever get Rmpi package to work, you can use this: #$ -pe mpi_16_tasks_per_node 32
# Request N cores for OMP (1,2,3,4,8,16,28, or 36 -- usually 28)
#$ -pe omp 28
#
# Note: runtime for OMP is limited to 720 hours, and 120 hours for mpi
#$ -l h_rt=3:00:00 
#
# Specify the amount of memory per core (up to 16G? Idk)
# Looks like I need about 221G in memory at once. If using 28 cores, that's close to 8G per core.
#$ -l mem_per_core=4G
#
# Project name
#$ -P econdept
#
# Send an email when the job has begun/ended 
#$ -m e


# Load R 
module load R

R -q --vanilla < /usr3/graduate/alcobe/Caretaking/5.StructuralEstimation/Updated_Model_20221201/1a_FiniteDifferences3-2_20221202.R $NSLOTS

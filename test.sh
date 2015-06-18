#!/bin/bash 
#PBS -N ClassifySubs
#PBS -l nodes=1:ppn=8
#PBS -l mem=8000mb
#PBS -l walltime=72:00:00
#PBS -M emails=t.a.buwalda@rug.nl

cd /home/p256524/
module add matlab
matlab -r 

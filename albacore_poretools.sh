#!/bin/bash
#PBS -P te53
#PBS -q normalbw
#PBS -l walltime=02:00:00
#PBS -l mem=12000MB
#PBS -l ncpus=16
#PBS -N basecaller
#PBS -j oe
#PBS -o /short/projectID/logs/
#PBS -l jobfs=100GB


threads=16
rsync -a $reference* $PBS_JOBFS/
rsync -a $inputfile $PBS_JOBFS/
inputdir_local=$PBS_JOBFS/$dataid

mkdir -p $inputdir_local
cd $inputdir_local
tar xzf $PBS_JOBFS/`basename $inputfile`
cd

module load albacore/1.1.0
read_fast5_basecaller.py \
-i $inputdir_local/ \
-t $threads \
-s $PBS_JOBFS/ \
-c FLO-MIN106_LSK108_linear.cfg
module unload albacore/1.1.0


module load poretools/0.6.0
poretools fasta $PBS_JOBFS/workspace/ >$PBS_JOBFS/$dataid.fasta
poretools fastq $PBS_JOBFS/workspace/ >$PBS_JOBFS/$dataid.fastq
module poretools/0.6.0

module load blast/2.2.28+
blastn -out $PBS_JOBFS/$dataid.blastn -db $PBS_JOBFS/`basename $reference` -query $PBS_JOBFS/$dataid.fasta -evalue 1e-6 -dust no -soft_masking false -outfmt '6 std qlen'
module unload blast/2.2.28+

module load utilities
pigz --force --best --processes $threads $PBS_JOBFS/$dataid.fasta
pigz --force --best --processes $threads $PBS_JOBFS/$dataid.fastq
module unload utilities

###transfer required files back
rsync -a $PBS_JOBFS/$dataid.blastn $outputdir/
rsync -a $PBS_JOBFS/$dataid.fasta.gz $outputdir/
rsync -a $PBS_JOBFS/$dataid.fastq.gz $outputdir/


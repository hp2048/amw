#!/bin/bash
#PBS -P te53
#PBS -q express
#PBS -l walltime=04:00:00
#PBS -l mem=30000MB
#PBS -l ncpus=16
#PBS -N basecaller
#PBS -j oe
#PBS -o /short/te53/logs/
#PBS -l jobfs=300GB

set -x
execute_command () {
	command=("${!1}")
	taskname="$2"
	donefile="$3"
	force="$4"
	outputfile="$5"
	
	JOBID=$PBS_JOBID
	###alter this to suit the job scheduler

	if [ "$force" -eq 1 ] || [ ! -e $donefile ] || [ ! -s $donefile ] || [ "`tail -n1 $donefile | cut -f3 -d','`" != " EXIT_STATUS: 0" ]
	then
		echo COMMAND: "${command[@]}" >> $donefile
		if [ -z "$outputfile" ]
		then
			/usr/bin/time --format='RESOURCEUSAGE: ELAPSED=%e, CPU=%S, USER=%U, CPUPERCENT=%P, MAXRM=%M Kb, AVGRM=%t Kb, AVGTOTRM=%K Kb, PAGEFAULTS=%F, RPAGEFAULTS=%R, SWAP=%W, WAIT=%w, FSI=%I, FSO=%O, SMI=%r, SMO=%s EXITSTATUS:%x' -o $donefile -a -- "${command[@]}"
			ret=$?
		else
			/usr/bin/time --format='RESOURCEUSAGE: ELAPSED=%e, CPU=%S, USER=%U, CPUPERCENT=%P, MAXRM=%M Kb, AVGRM=%t Kb, AVGTOTRM=%K Kb, PAGEFAULTS=%F, RPAGEFAULTS=%R, SWAP=%W, WAIT=%w, FSI=%I, FSO=%O, SMI=%r, SMO=%s EXITSTATUS:%x' -o $donefile -a -- "${command[@]}" >$outputfile
			ret=$?			
		fi
		echo JOBID:$JOBID, TASKNAME:$taskname, EXIT_STATUS:$ret,  TIME:`date +%s`>>$donefile
  	if [ "$ret" -ne 0 ]
  	then
  		echo ERROR_command: $command
  		echo ERROR_exitcode: $taskname failed with $ret exit code.
  		exit $ret
  	fi
	elif [ -e $donefile ]
	then
		echo SUCCESS_command: $command
		echo SUCCESS_message: $taskname has finished with $ret exit code.
	fi
}

threads=16
inputdir_local=$PBS_JOBFS/$dataid

rsync -a $reference* $PBS_JOBFS/
rsync -a $inputfile $PBS_JOBFS/

mkdir -p $inputdir_local
cd $inputdir_local
tar xzf $PBS_JOBFS/`basename $inputfile`
cd

module load python3/3.5.2 albacore/0.8.4
command=(read_fast5_basecaller.py -i $inputdir_local/ -t $threads -s $PBS_JOBFS/ -c FLO-MIN106_LSK108_linear.cfg)
execute_command command[@] $dataid.albacore $outputdir/$dataid.albacore.done 1
module unload python3/3.5.2 albacore/0.8.4

module load python/2.7.11 python/2.7.11-matplotlib poretools/0.6.0
command=(poretools fasta $PBS_JOBFS/workspace/)
execute_command command[@] $dataid.poretoolsfasta $outputdir/$dataid.poretoolsfasta.done 1 "$PBS_JOBFS/$dataid.fasta"
command=(poretools fastq $PBS_JOBFS/workspace/)
execute_command command[@] $dataid.poretoolsfastq $outputdir/$dataid.poretoolsfastq.done 1 "$PBS_JOBFS/$dataid.fastq"
command=(poretools combine -o $outputdir/$dataid.tar.gz $PBS_JOBFS/workspace/)
execute_command command[@] $dataid.poretoolscombine $outputdir/$dataid.poretoolscombine.done 1
module unload python/2.7.11 python/2.7.11-matplotlib poretools/0.6.0

module load blast/2.2.28+

command=(blastn -out "$PBS_JOBFS/$dataid.blastn" -db "$PBS_JOBFS"/`basename $reference` -query "$PBS_JOBFS/$dataid.fasta" -evalue 1e-6 -max_target_seqs 5 -max_hsps_per_subject 5 -outfmt "6 std qlen")
execute_command command[@] $dataid.blastn $outputdir/$dataid.blastn.done 1

module unload blast/2.2.28+

module load utilities
command=(pigz --force --best --processes $threads "$PBS_JOBFS/$dataid.fasta")
execute_command command[@] $dataid.fastazip $outputdir/$dataid.fastazip.done 1

command=(pigz --force --best --processes $threads "$PBS_JOBFS/$dataid.fastq")
execute_command command[@] $dataid.fastqzip $outputdir/$dataid.fastqzip.done 1

module unload utilities

###transfer required files back
rsync -a $PBS_JOBFS/$dataid.blastn $outputdir/
rsync -a $PBS_JOBFS/$dataid.fasta.gz $outputdir/
rsync -a $PBS_JOBFS/$dataid.fastq.gz $outputdir/

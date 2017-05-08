#!/bin/bash
#PBS -q express
#PBS -l walltime=04:00:00
#PBS -l mem=30000MB
#PBS -l ncpus=16
#PBS -N basecaller
#PBS -j oe
#PBS -l jobfs=300GB

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

module load albacore/1.1.0
command=(read_fast5_basecaller.py -i $inputdir_local/ -t $threads -s $PBS_JOBFS/ -c FLO-MIN106_LSK108_linear.cfg)
execute_command command[@] $dataid.albacore $outputdir/$dataid.albacore.done 1
module unload albacore/1.1.0

module load poretools/0.6.0
command=(poretools fasta $PBS_JOBFS/workspace/)
execute_command command[@] $dataid.poretoolsfasta $outputdir/$dataid.poretoolsfasta.done 1 "$PBS_JOBFS/$dataid.fasta"
command=(poretools fastq $PBS_JOBFS/workspace/)
execute_command command[@] $dataid.poretoolsfastq $outputdir/$dataid.poretoolsfastq.done 1 "$PBS_JOBFS/$dataid.fastq"
command=(poretools combine -o $outputdir/$dataid.tar.gz $PBS_JOBFS/workspace/)
execute_command command[@] $dataid.poretoolscombine $outputdir/$dataid.poretoolscombine.done 1
module unload poretools/0.6.0

###transfer required files back
rsync -a $PBS_JOBFS/$dataid.fasta $outputdir/
rsync -a $PBS_JOBFS/$dataid.fastq $outputdir/

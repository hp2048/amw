#!/bin/bash

set -x
execute_command () {
	command=("${!1}")
	taskname="$2"
	donefile="$3"
	force="$4"
	outputfile="$5"
	
	JOBID=$PBS_JOBID
	###alter this to suit the job scheduler

	if [ "$force" -eq 1 ] || [ ! -e $donefile ] || [ ! -s $donefile ] || [ "`tail -n1 $donefile | cut -f3 -d','`" != " EXIT_STATUS:0" ]
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

##copy files to local disc
command=(rsync -a $genome $inputbam $probebed $targetbed $PBS_JOBFS/)
execute_command command[@] $dataid.n2l $PBS_JOBFS/$dataid.n2l.done 1

##run bedcoverage on probe set
module load bedtools/2.26.0

command=(bedtools coverage $PBS_JOBFS/`basename $genome` -f 0.5 -counts -sorted -a $PBS_JOBFS/`basename $probebed` -b $PBS_JOBFS/`basename $inputbam`)
execute_command command[@] $dataid.probecov $outputdir/$dataid.probecov.done 0 $PBS_JOBFS/$dataid.probecov.txt

##run bedcoverage on target set
command=(bedtools coverage $PBS_JOBFS/`basename $genome` -counts -sorted -a $PBS_JOBFS/`basename $targetbed` -b $PBS_JOBFS/`basename $inputbam`)
execute_command command[@] $dataid.targetcov $outputdir/$dataid.targetcov.done 0 $PBS_JOBFS/$dataid.targetcov.txt

module unload bedtools/2.26.0

##run flagstat to get summary stats about mapping
module load samtools/1.4
command=(samtools flagstat $PBS_JOBFS/`basename $inputbam`)
execute_command command[@] $dataid.flagstat $outputdir/$dataid.flagstat.done 0 $PBS_JOBFS/$dataid.flagstat.txt

module unload samtools/1.4

##copy results back to the network drive
command=(rsync -a $PBS_JOBFS/*.txt $outputdir/)
execute_command command[@] $dataid.l2n $outputdir/$dataid.l2n.done 1
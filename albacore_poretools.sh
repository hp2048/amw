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

threads=16
inputdir_local=$PBS_JOBFS/$dataid
outputdir_local=$PBS_JOBFS/results_$dataid

command=(rsync -a $inputfile $PBS_JOBFS/)
execute_command command[@] $dataid.copy2local $outputdir/$dataid.copy2local.done 1

mkdir -p $inputdir_local
mkdir -p $outputdir_local
command=(tar xzf $PBS_JOBFS/`basename $inputfile` -C $inputdir_local)
execute_command command[@] $dataid.untar $outputdir/$dataid.untar.done 1

##run albacore
module load albacore/1.1.2
command=(read_fast5_basecaller.py -i $inputdir_local/ -t $threads -s $outputdir_local/ -o fastq,fast5 -q 10000000000000 -n 10000000000000 -f $flowcell -k $libkit -c $configfile)
execute_command command[@] $dataid.albacore $outputdir/$dataid.albacore.done 1
module unload python3/3.5.2 albacore/1.1.2

##remove input directory
rm -rf $inputdir_local

###fastq files are $outputdir_local/workspace/*.fastq. Normally it should only be 1 fastq file because of very high number for -n parameter above in albacore run
###fast5 files are in $outputdir_local/workspace/0. Normally it should only be 0 because of very high number in -q parameter above in albacore run

### you can add extra commands here for additional analysis of fastq or fast5 files
###You should use $outputdir_local as the output directory for analysis/results. This will ensure that results are compressed and transferred back to the network attached storage.
### There are lots of files generated as a result of analysis and it will exceed you inode quota on NCI so this is the best possible way to get around it.

##tar results folder
command=(tar czf $PBS_JOBFS/$dataid.results.tar.gz -C $PBS_JOBFS/ results_$dataid)
execute_command command[@] $dataid.tar $outputdir/$dataid.tar.done 1


##copy files back to the network attached storage
command=(rsync -a $PBS_JOBFS/$dataid.results.tar.gz $outputdir/)
execute_command command[@] $dataid.copy2nas $outputdir/$dataid.copy2nas.done 1

###once all results are copied back to the network storage then one can extract FASTQ files only as follows:

###tar xvzf $outputdir/$dataid.results.tar.gz results_$dataid/workspace/*.fastq
###the above command will create results_$dataid/workspace/*.fastq file in the current working directory


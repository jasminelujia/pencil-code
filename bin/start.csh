#!/bin/csh
###                       start.csh
###                      -----------
### Run src/start.x (initialising f for src/run.x) with certain
### parameters.
#
# run.csh -- driver for time stepping
#
#PBS -S /bin/csh

if ($?PBS_O_WORKDIR) then
  cd $PBS_O_WORKDIR
endif

# Determine whether this is MPI, how many CPUS etc.
source getconf.csh

#
#  If we don't have a data subdirectory: stop here (it is too easy to
#  continue with an NFS directory until you fill everything up).
#
if (! -d "$datadir") then
  echo ""
  echo ">>  STOPPING: need $datadir directory"
  echo ">>  Recommended: create $datadir as link to directory on a fast scratch"
  echo ">>  Not recommended: you can generate $datadir with 'mkdir $datadir', "
  echo ">>  but that will most likely end up on your NFS file system and be"
  echo ">>  slow"
  echo
  exit 0
endif

# Create list of subdirectories
set subdirs = `printf "%s%s%s\n" "for(i=0;i<$ncpus;i++){" '"data/proc";' 'i; }' | bc`
foreach dir ($subdirs)
  # Make sure a sufficient number of subdirectories exist
  if (! -e $dir) then
    mkdir $dir
  else
    # Clean up
    rm -f $dir/VAR* >& /dev/null
    rm -f $dir/vid* >& /dev/null
    rm -f $dir/*.dat >& /dev/null
    rm -f $dir/*.xy $dir/*.xz >& /dev/null
  endif
end
if (-e $datadir/n.dat && ! -z $datadir/n.dat) mv $datadir/n.dat $datadir/n.`timestr`
rm -f $datadir/*.dat $datadir/*.nml $datadir/param*.pro $datadir/index*.pro >& /dev/null

# Run start.x
date
echo "$mpirun $mpirunops $npops src/start.x"
time $mpirun $mpirunops $npops src/start.x
echo ""
date

# On Horseshoe cluster, copy var.dat back to the data directory
if ($hn =~ s[0-9]*p[0-9]*) then
  echo "Use options for the Horseshoe cluster"
  copy-snapshots -v var.dat
endif

# cut & paste for job submission on the mhd machine
# bsub -n  4 -q 4cpu12h mpijob dmpirun src/start.x
# bsub -n  8 -q 8cpu12h mpijob dmpirun src/start.x
# bsub -n 16 -q 16cpu8h mpijob dmpirun src/start.x

# cut & paste for job submission for PBS
# qsub -l ncpus=64,mem=32gb,walltime=1:00:00 -W group_list=UK07001 -q UK07001 start.csh
# qsub -l ncpus=4,mem=1gb,cput=100:00:00 -q parallel start.csh
# qsub -l nodes=128,mem=64gb,walltime=1:00:00 -q workq start.csh

###################################################################
#
# NAME - process_lock.pm
#
# DESC - Library for common and global process lock functions
#
# FUNCTION LIST
#        - &getlock($file); returns 0 onfail
#
# CREATED - 4-30-2003, Jeffrey Nord
#
# INPUTS: use mm_config.pm
#
# TODO :
#
##################################################################

sub getlock
{
    my $file = shift;
    my $main_pid = shift;
    my $pid = '';

    if( -f $file )
    {
        chomp($pid = `head -1 $file`);

        # Make sure the PID is valid
        if( $pid !~ /^\d+$/ )
        {
            warn "Invalid PID $pid read from lockfile $file\n";
            return 0;
        }

        # Return true if the PID is our pid, This is used to indicate
        # getlock() being called more than once
        return 2 if "$pid" eq "$main_pid";

        # let's check to see if the process is still running
        if( kill(0,$pid) )
        {
            #warn "Process $pid is still running\n";
            return 0;
        }


        # OK we have checked the PID and it isn't ours and there isn't a
        # process with that same PID
    }

    # We want to create our lock file
    # First create a temp file with our PID in it then rename(2) it to
    # the lock file name for Atomicity
    unless( open(TMP,">$file..TMP") )
    {
        warn "Can't create TMP lock file $file..TMP";
        return 0;
    }

    print TMP "$main_pid\n";
    close TMP;

    # get the lock
    unless (rename("$file..TMP", $file) )
    {
        warn "Can't rename TMP lock file to $file";
        return 0;
    }


    # make sure the new file is infact a reference to ourselves
    return 1 if getlock($file,$main_pid) == 2;

    # Else
    warn "Can't confirm we got the lock in $file for PID $main_pid";
    return 0;
}
1;

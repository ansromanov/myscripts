#!/bin/bash

# Backup folder to network share script
# Created by Andrey Romanov '2013

# Paths to programs
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

MOUNT_CMD=$(which mount.smbfs)

# Setting initial variables:
S="$(date +%s)" # start time
UID_ROOT=0 # root uid
server_name=$HOSTNAME
source_path='/etc/' # directory for backuping 
mount_path='/mnt/backup'
mount_server='//server/configuration'
mail_to='user@local'
arch_path="$mount_path/$server_name/"
arch_path_net="$mount_server/$server_name/" # real network path to share
error_log='/tmp/backup_errors.log'
curr_date=$(date +%Y%m%d)
curr_time=$(date +%H%M%S)
bkp_name="$arch_path$curr_date""_$(hostname)_etc_backup_$curr_time.tar.gz"
bkp_name_net="$arch_path_net$curr_date""_$(hostname)_etc_backup_$curr_time.tar.gz" # real network path to backup

echo "$source_path backup script started..."

# Run as super user check
if [ "$UID" -ne "$UID_ROOT" ]; then
	echo "This script need to run with super user privileges"
	logger "$0 - Runned without super user privileges"
	exit 100 # need run with su privileges
fi

# Send current datetime to local log file
echo "" >> $error_log
date >> $error_log

# Mounting network share & creating subdirs if needed
echo "Creating directory $mount_path for mounting network share."

if [ -d $mount_path ]; then
	echo "Already present."
else
	if (mkdir -p $mount_path 2>> "$error_log") then
		echo "Done!"
	else
		echo "Can't create directory $mount_path for mounting.  See /var/log/syslog"
		logger "$0 - Can't create directory $mount_path for mounting (mkdir error)"
		exit 101 # can't create directory for mounting
	fi
fi

echo "Mounting $mount_server in $mount_path."
if !(cat /proc/mounts | grep $mount_server | grep $mount_path > /dev/null 2> /dev/null) then
	if ($MOUNT_CMD -o username=netbackup,password=t4ylx97 $mount_server $mount_path 2>> "$error_log") then
		echo "Done!"
	else
		echo "Cannot mount network share $mount_server to $mount_path.  See /var/log/syslog"
		logger "$0 - Can't mount network share $mount_server to $mount_path (mount.smbfs error)"
		exit 102 # can't mount network share
	
	fi
else
	echo "Already mounted."
fi

echo "Creating $arch_path subdir for backups compressing."
if [ -d $arch_path ]; then
	echo "Already present."
else
	if (mkdir -p $arch_path 2>> "$error_log") then
		echo "Done!"
	else
		echo "Can't create directory $arch_path for backups compressing.  See /var/log/syslog"
		logger "$0 - Can't create directory $arch_path for backups compressing (mkdir error)"
		exit 103 # can't create directory for backups compressing
	fi
fi


# Compressing backup
echo "Compressing $source_path* to $bkp_name_net"
if (tar -vjcf  $bkp_name $source_path 2>> "$error_log") then
	echo "Done!"
else
 	echo "Compression error. See /var/log/syslog"
	logger "$0 - Can't compress $source_path to directory $source_path (tar error)"
	exit 104 # tar compression error
fi

report=$(tar -tf $bkp_name | wc -l)


# Unmounting network share
echo "Unmounting $mount_server."
if !(umount -f $mount_path > /dev/null 2> "$error_log") then
	echo "Error!"
else
	echo "Done!"
fi

S="$(($(date +%s)-S))" # stop time
TimeString=$(printf "%02d hours %02d minutes %02d seconds\n" \
        "$((S/3600))" "$((S/60%60))" "$((S%60))")

# Mail sending
echo "Send mail to $mail_to"
echo "$report files from $source_path archived to $bkp_name_net in $TimeString" | \
	mail -r "$server_name mail daemon <admin@ellis.ru>" -s "$server_name - backup $source_path report" "$mail_to"

exit 0 # without errors

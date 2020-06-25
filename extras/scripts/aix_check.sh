#!/bin/sh

UNAME=$(uname)
separator=""

INFO="
Usage: ./aix_check.sh <check>

Ex. ./aix_check.sh --bpbootlist

Options:

--bpbootlist
--bpfscsipastfail
--bpadapterfail
--bpnmon
--bpimagevalidation
--help
"

# Path

PATH="$PATH:/usr/es/sbin/cluster/utilities/:/usr/lpp/mmfs/bin/mmlspv"
pathCluster="/usr/es/sbin/cluster/utilities/"
pathGpfs="/usr/lpp/mmfs/bin/mmlspv/"

################################################################################
# Function:    formatJson                                                      #
# Description: Escape " \                                                      #
################################################################################

function formatJson {
  escape=$(echo "$*" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
  return "${escape}"
}

################################################################################
# Function:    addError                                                        #
# Description: addError to list at end of Json.                                #
################################################################################

errors=""

function addError {
  if [ "${errors}" = "" ]; then
    errors="\"$1\""
  else
    errors="${errors},\"$1\""
  fi
}

################################################################################
# Function:    bpbootlist                                                      #
# Description: Check if rootvg disks are in bootlist also.                     #
################################################################################

function bpbootlist {
  # Verifica quais discos estao presentes no rootvg
  hdiskRootvg=$(lsvg -p rootvg | grep hdisk | awk '{print $1}' | uniq | sort)

  # Verifica quais discos estão no bootlist
  hdiskBootlist=$(bootlist -m normal -o 2>/dev/null | awk '{print $1}' | uniq | sort)

  if [ "$hdiskRootvg" == "$hdiskBootlist" ]; then
    # print -n "${separator}\"bpbootlist\":{\"status\":\"0\",\"detail\":\"\"}"
    echo "OK"
    return 0
  else
    # print -n "${separator}\"bpbootlist\":{\"status\":\"1\",\"detail\":\"\"}"
    echo "NOK"
    return 1
  fi
}

################################################################################
# Function:    bpFscsiFastFail                                                 #
# Description: Check if ifscsi parameter of interfaces is fast_fail            #
################################################################################

function bpFscsiFastFail {
  $(lsdev | grep fscsi 1> /dev/null)
  if [ $? = 0 ]; then
    for i in $(lsdev | grep fscsi | awk '{print $1}' | sort | uniq); do
      fscsiFast=$(lsattr -El $i | grep fc_err_recov | awk '{print $2}')
    done
    fscsiRes=$(echo $fscsiFast | grep delayed_fail | wc -l)
    if [ $fscsiRes = 0 ]; then
      print -n "${separator}\"bpFscsiFastFail\":{\"status\":\"0\",\"detail\":\"\"}"
      return 0
    else
      print -n "${separator}\"bpFscsiFastFail\":{\"status\":\"1\",\"detail\":\"\"}"
      return 1
    fi
  else
    print -n "${separator}\"bpFscsiFastFail\":{\"status\":\"2\",\"detail\":\"\"}"
    return 2
  fi
}

################################################################################
# Function:    bpAdapterFail                                                   #
# Description: Check adapters in fail state                                    #
################################################################################

function bpAdapterFail {
  if [ -e "/usr/bin/pcmpath" ]; then
    adapterFail=$(pcmpath query adapter | grep fscsi | grep -vi NORMAL | wc -l)
    if [ $adapterFail = 0 ]; then
      print -n "${separator}\"bpAdapterFail\":{\"status\":\"0\",\"detail\":\"\"}"
      return 0
    else
      print -n "${separator}\"bpAdapterFail\":{\"status\":\"1\",\"detail\":\"\"}"
      return 1
    fi
  else
    print -n "${separator}\"bpAdapterFail\":{\"status\":\"2\",\"detail\":\"\"}"
    return 2
  fi
}

################################################################################
# Function:    bpNmon                                                          #
# Description: Check if nmon is runnig                                         #
################################################################################

function bpNmon {
  result=$(ps -elf | grep -v 'grep' | grep 'nmon')
  if [ $? = 0 ]; then
    print -n "${separator}\"bpNmon\":{\"status\":\"0\",\"detail\":\"\"}"
    return 0
  else
    print -n "${separator}\"bpNmon\":{\"status\":\"1\",\"detail\":\"\"}"
    return 1
  fi
}

################################################################################
# Function:    bpImageValidation                                               #
# Description: Check if mksysb has executed and it was sent to TSM.            #
################################################################################

function bpImageValidation {
  ChkMksysbLog=$(ls -tr /so_ibm/log/image/*log /so_ibm/log/image*log 2>/dev/null | tail -n 1)
  if [ -f "$ChkMksysbLog" ]; then
    ChkMksysb=$(cat "$ChkMksysbLog" | grep "Backup Image OK")
    ChkTsm=$(cat "$ChkMksysbLog" | grep "The operation successfully complete.")
    if [ "$ChkMksysb" == "Backup Image OK! (100%)" ]; then
      if [ "$ChkTsm" == "The operation successfully complete." ]; then
        print -n "${separator}\"bpImageValidation\":{\"status\":\"0\",\"detail\":\"\"}"
        return 0
      else
        print -n "${separator}\"bpImageValidation\":{\"status\":\"1\",\"detail\":\"\"}"
        return 1
      fi
    else
      print -n "${separator}\"bpImageValidation\":{\"status\":\"1\",\"detail\":\"\"}"
      return 1
    fi
  else
    print -n "${separator}\"bpImageValidation\":{\"status\":\"1\",\"detail\":\"\"}"
    return 1
  fi
}

if [ $1 = "--bpbootlist" ]; then
  bpbootlist
fi

if [ $1 = "--bpfscsipastfail" ]; then
  bpFscsiFastFail
fi

if [ $1 = "--bpadapterfail" ]; then
  bpAdapterFail
fi

if [ $1 = "--bpnmon" ]; then
  bpNmon
fi

if [ $1 = "--bpimagevalidation" ]; then
  bpImageValidation
fi

if [ $1 = "--help" ]; then
  print -n "$INFO"
fi


# Author: CC
# Date:   2016-09-25
# Compate shell: sh bash ksh
# Unix command: unset set export eval [ getopts local shift echo printf date expr df find pwd 
#               cp mv rm rmdir mkdir chmod chown id grep sed awk head sort cut read cat
# Compatibility OS: UNIX Linux (Tested:Linux/hpux/aix/freebsd)

Install_Path=/bin

USAGE() {
    echo "SYNOPSIS"
    echo "    ${0##*/} [-afhn]  [-d Expire_Day] [-p Install_Path] [-P path1,path2, ...]"
    cat <<- 'eof'
    
    -a                 Install alias
    -d  day            Specify expire day, default 30
    -f                 Init trash and trashlog directory
    -h                 Display this help and exit
    -n                 No prompt
    -p  path           Specify install path, default /bin
    -P  pathlist       Write alias to Shell Config files find in pathlist, default all
                        
eof
}



while getopts "ad:fhnp:P:" Option
do
    case "$Option" in
        a)
            _Install_Alias=yes
            ;;

        d)
            Expire_Day="$OPTARG"
            ;;
        f)
            _Init_Fold=yes
            ;;
        h)
            USAGE
            exit 0
            ;;

        n)
            _No_Print=yes
            ;;
        p)
            Install_Path="$OPTARG"
            ;;
        P)
            Shell_Config_Find_Path=`echo -- "$OPTARG" | sed 's/^--[[:space:]]*//;s#,,*# #g'`
            ;;

        \?)
            USAGE
            exit 1
            ;;
    esac
done

# Set Install_Path
if [ "x$_No_Print" != "xyes" ] ; then
    until [ -w ${Install_Path} ] ; do
        printf "\033[1mYou have no write permission to ${Install_Path}, specify Install path:[/bin]\033[0m"
        unset Install_Path
        read Install_Path
        [ "x$Install_Path" = "x" ] && Install_Path=/bin
    done
else
    if [ ! -w ${Install_Path} ] ; then
        printf "\033[1mYou have no write permission to ${Install_Path}, specify it by -p\033[0m\n"
        exit 1
    fi
fi

# Set Expire_Day
if [ "x$_No_Print" != "xyes" ] ; then
    printf "\033[1mSpecify expiration days of deleted files:[30]\033[0m"
    unset Expire_Day
    read Expire_Day
fi
[ "x${Expire_Day}" = x ] && Expire_Day=30


Def_Path="export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$Install_Path:\$PATH"
sh_path=`find  /bin /sbin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin -name sh 2>/dev/null | head -1`
realrm=`find  /bin /sbin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin -name rm 2>/dev/null | head -1`
Root_Name=` awk -F: '$3 == 0 {print $1}' /etc/passwd | head -1`
Root_Gid=`  awk -F: '$3 == 0 {print $4}' /etc/passwd | head -1`
Root_Group=`awk -F: '$3 == '"$Root_Gid"' {print $1}' /etc/group | head -1`
delete_name=delete


[ -e ${Install_Path}/${delete_name} ] && $realrm -rf ${Install_Path}/${delete_name} 2>/dev/null
#Save as ${Install_Path}/${delete_name}
echo "#! $sh_path"                           >  ${Install_Path}/${delete_name}
cat >> ${Install_Path}/${delete_name} <<- 'eof'

# Author: CC
# Date:   2016-09-25
# Compate shell: sh bash ksh
# Unix command: unset set export eval [ getopts local shift echo printf date expr df find pwd 
#               cp mv rm rmdir mkdir chmod chown id grep sed awk head sort cut read cat
# Compatibility OS: UNIX Linux (Tested:Linux/hpux/aix/freebsd)

eof
echo "realrm=$realrm"                        >> ${Install_Path}/${delete_name}
echo "$Def_Path"                             >> ${Install_Path}/${delete_name}
echo "trashlog_bin=${Install_Path}/trashlog" >> ${Install_Path}/${delete_name}

cat >> ${Install_Path}/${delete_name} <<- 'eof'

_mount=`df -P | awk '$NF != "/" && $NF ~ /^\// {print $NF}'`
# _Mount_Point=`df -P | awk '$NF ~ /^\// {print $NF}'`
export DU_BLOCK_SIZE=512
export BLOCK_SIZE=512
export BLOCKSIZE=512
export POSIXLY_CORRECT=512

USAGE() {
    echo "SYNOPSIS"
    echo "    ${0##*/} [-N | -n] [-F] [-f | -i] [-r | -R] [-h] [--] file ..."
    printf "Description\n"
    printf "    This is an auxiliary scripts of $realrm, povides a function similar to the Recycle Bin\n"
    printf "    Only -N -n -F -h control the actions of this scripts\n"
    printf "    Other variables like -i -f -r -R will be passed to $realrm \n\n"

    cat <<- 'EOF'
    -f                    Ignore nonexistent files, never prompt
    -F                    Use system command "rm"
    -h, --help            Display this help and exit
    -i                    Prompt before every removal
    -r, -R                Remove directories and their contents recursively
    -n                    No prompt
    -N                    Same as -n, but force to move Files to trash directory

EOF
    printf "Warning\n"
    printf "    \033[1m$0 depends on $realrm, can not overwrite or delete $realrm \033[0m\n"  
    printf "    \033[1mFile name is seperated by blank characters\033[0m\n"
    printf "    \033[1mSpecial characters need to escape\033[0m\n"
    echo   '    \~\`\!\@#\$%\^\&\*\(\)_-+\=\{\[\}\]\|\\\:\;\'\''\"\,\<.\>\?'
    printf "\nSEE ALSO: \033[1m\"unrm\"\033[0m to recover or to empty trash directory\n"
    printf "SEE ALSO: \033[1m\"$realrm --help\"\033[0m\n"
}

if [ $# -eq 0 ] ; then
    USAGE
    exit 1
fi

# Get mount point 
unset _Mount_RE
for _Mount_dir in $_mount /tmp; do
    _Mount_RE="$_Mount_RE|""^${_Mount_dir}/*$"
done
_Mount_RE="^/bin/*$|^/sbin/*$|^/usr/*$|^/lib(64)*/*$|\
^/etc/*$|^/boot/*$|^/opt/*$|^/home/*$|\
^/var/*$|^/proc/*$|^/dev/*$|^/cgroup/*$|\
^/tmp/*$|^/root/*$|^/net/*$|^/selinux/*$|\
^/mnt/*$|^/media/*$""${_Mount_RE}"


if echo -- "$@" | sed 's/^--[[:space:]]*//' | grep -qE -- "[[:space:]]*--[[:space:]][[:space:]]*" 2>/dev/null ; then
    ARGV=`echo -- "$@" | sed 's/^--[[:space:]]*//' | sed 's#\([[:space:]]*--\)[[:space:]][[:space:]]*.*#\1#g' 2>/dev/null`
else
    ARGV=`echo -- "$@" | sed 's/^--[[:space:]]*//' |sed  's#[[:graph:]][[:graph:]]*--*[[:graph:]][[:graph:]]*##g'| sed  's#\(.*[[:space:]]*--*[[:alnum:]][[:alnum:]]*\).*#\1#g;s#^[^-]*$##g'`
fi


if echo -- "$ARGV" | sed 's/^--[[:space:]]*//' | grep -iqwE -- "-*h|--help|--he|--hel" ; then
    USAGE
    exit 0
fi

if [ "x${ARGV}" = x ] ; then
    _Del_File="$@"
else
    _Del_File=`echo -- "$@" | sed 's/^--[[:space:]]*//'| sed 's#[[:space:]]*'"$ARGV"'[[:space:]]*##' 2>/dev/null`
fi


_Real_Argv=`echo -- "$ARGV" | sed 's/^--[[:space:]]*//' | sed 's#\([[:space:]]*-\)n\([[:alnum:]][[:alnum:]]*\)#\1\2#g; 
                                s#[[:space:]]*-n\([[:space:]]*\)#\1#g;
                                s#\([[:alnum:]]*\)n#\1#g;
                                s#\([[:space:]]*-\)F\([[:alnum:]][[:alnum:]]*\)#\1\2#g;
                                s#[[:space:]]*-F\([[:space:]]*\)#\1#g;
                                s#\([[:alnum:]]*\)F#\1#g;
                                s#\([[:space:]]*-\)N\([[:alnum:]][[:alnum:]]*\)#\1\2#g;
                                s#[[:space:]]*-N\([[:space:]]*\)#\1#g;
                                s#\([[:alnum:]]*\)N#\1#g
                                '
            `
# Protect mounted partition
for _File_check in $_Del_File ; do
    if echo -- "$_File_check"| sed 's/--[[:space:]]*//' | grep -qE "${_Mount_RE}" 2>/dev/null ; then
        printf "\033[1m$_File_check is preserved, otherwise, please exec:\n  $realrm\033[0m\n"
        printf "OR:\n  \033[1m$0 -F\033[0m\n"
        exit 1
    fi
done


unset _No_Print
if echo -- "$ARGV" | sed 's/^--[[:space:]]*//' | grep -qE -- "n|N" 2>/dev/null; then
    _No_Print=yes
else
    _No_Print=no
fi

if [ "x${_No_Print}" != "xyes" ] ; then
    Print_File_List=`echo -- "$_Del_File" | sed 's/--[[:space:]]*//;s#%#%%#g'`
fi

# Directly delete files
if echo -- "$ARGV" | sed 's/^--[[:space:]]*//' | grep -q "F" 2>/dev/null ; then
    if [ "x${_No_Print}" != "xyes" ] ; then
        printf "\033[1mDirectly delete the specified files[YES/NO]:[NO]\033[0m\a"
        unset reply
        read reply
    fi


    if echo "$reply" | grep -qiE "y|ye|yes" 2>/dev/null || [ "x${_No_Print}" = "xyes" ] ; then
        unset _Result
        $realrm $_Real_Argv $_Del_File && _Result=1
        if [ "x${_No_Print}" != "xyes" ] ; then
            if [ "x$_Result" = "x1" ] ; then
                 printf "Delete $Print_File_List directly succeed\n"
            else
                 printf "\033[1mSome files deleted directly failed\033[0m\n"
            fi
        fi
    fi
    exit $?
fi

if [ "x${_No_Print}" != "xyes" ] ; then
    printf "\033[1mBy default, specified files will be moved to the trash directory\033[0m\n"
    printf "\033[1mUse \"unrm\" to recover or to empty trash directory\033[0m\n"
    printf "\033[1mDirectly delete the specified files[YES/NO]:[NO]\033[0m\a"
    unset reply
    read reply
    echo ""
fi

if echo "$reply" | grep -qiE "y|ye|yes" 2>/dev/null ; then
        unset _Result
        $realrm $_Real_Argv $_Del_File && _Result=1
        if [ "x${_No_Print}" != "xyes" ] ; then
            if [ "x$_Result" = "x1" ] ; then
             printf "Delete $Print_File_List directly succeed\n"
        else
             printf "\033[1mSome files deleted directly failed\033[0m\n"
        fi
    fi
    exit $?
else

    for file in $_Del_File
    do
        if [ "x${_No_Print}" != "xyes" ] ; then
            Print_File=`echo -- "$file" | sed 's/--[[:space:]]*//;s#%#%%#g'`
        fi

        if ls --  $file >/dev/null 2>&1 && [ `du -s -- $file|awk '{print $1}'` -gt 8589934592 ]
        then
            if [ "x${_No_Print}" != "xyes" ] ; then
                printf "\033[1m$Print_File is larger than 4G, deleted directly[YES/NO]:[NO]\033[0m"
                unset reply
                read reply
            fi
            
            if echo "$reply" | grep -qiE "y|ye|yes" 2>/dev/null; then
                unset _Result
                $realrm $_Real_Argv $file && _Result=1
                if [ "x${_No_Print}" != "xyes" ] ; then
                    if [ "x$_Result" = "x1" ] ; then
                         printf "Delete $Print_File directly succeed\n"
                    else
                         printf "\033[1mDelete $Print_File directly failed\033[0m\n"
                    fi
                fi
                continue
            elif echo -- "$ARGV" | sed 's/^--[[:space:]]*//' | grep -qE -- "N" 2>/dev/null; then
                :
            else
                if [ "x${_No_Print}" != "xyes" ] ; then
                    printf "\033[1m$Print_File larger than 4G, specify -F delete directly, -N force to move to trash directory\033[0m\n"
                fi
                continue
            fi
            
        fi

        # Get filename
        now=`date +"%Y-%m-%d %H:%M:%S"`
        # filename=${file##*/}
        filename=`echo -- "$file" | sed 's/--[[:space:]]*//;s#.*/\([^/]*\)/$#\1#g;s#.*/\([^/]*\)$#\1#g'`
        newfilename="${filename}_$(date +"%Y-%m-%d_%H:%M:%S")"

        if [ "x${_No_Print}" != "xyes" ] ; then
            Print_newfilename=`echo -- "$newfilename" | sed 's/--[[:space:]]*//;s#%#%%#g'`
        fi

        # Get fullpath
        unset fullpath
        if echo $file|grep -qE "^/" 2>/dev/null; then
            fullpath=$file
        elif echo $file|grep -qE "^\./" 2>/dev/null ; then
            fullpath="$(pwd)${file#\.}"
        else
            fullpath="$(pwd)/${file}"
        fi
        fullpath=`echo -- "$fullpath" | sed 's/--[[:space:]]*//;s#//*#/#g;s#/$##'`

        if [ "x${_No_Print}" != "xyes" ] ; then
            Print_fullpath=`echo -- "$fullpath" | sed 's/--[[:space:]]*//;s#%#%%#g'`
        fi

        # Get fullpath of parent directory
        unset _Result
        if [ -z ${fullpath%/*} ] ; then
            _fullpath=/
        else
            _fullpath=${fullpath%/*}
        fi
        [ -w ${_fullpath} ] && _Result=1
        if [ "x$_Result" != "x1" ] && [ "x${_No_Print}" != "xyes" ] ; then
            printf "\033[1m$Delete $Print_fullpath failed, permission denied\33[0m\n"
        fi
        [ "x$_Result" != "x1" ] && continue

        # Get trash directory
        unset destpath
        for _path in $_mount /tmp ; do
            if echo $fullpath | grep -q "${_path}" 2>/dev/null ; then
                destpath=${_path}
                break
            fi
        done
        if [ x"$destpath" = x ] ; then
            destpath="/"
        fi

        # if mount point trash dir can not be writened, set bo be basedir of filename 
        [ ! -w ${destpath} ] && destpath=${_fullpath}

        destpath=${destpath%\/}
       
        Mk_Dir() {
            local Par_Dir=$1
            local New_Dir=$2
            local PRV=$3
            local Dir_Num=$4
            local Date=$5
            local Username=$6
            local Num=1
            [ ! -d ${Par_Dir}/${New_Dir} -a -e  ${Par_Dir}/${New_Dir} ] && $realrm -f -- ${Par_Dir}/${New_Dir} 2>/dev/null
            [ ! -d ${Par_Dir}/${New_Dir} ] && mkdir -p ${Par_Dir}/${New_Dir} 2>/dev/null
            if ! [ -d ${Par_Dir}/${New_Dir} -a -w ${Par_Dir}/${New_Dir} \
                   -a \( ! -d ${Par_Dir}/${New_Dir}/$5    -o \( -d ${Par_Dir}/${New_Dir}/$5    -a -w ${Par_Dir}/${New_Dir}/$5 \) \) \
                   -a \( ! -d ${Par_Dir}/${New_Dir}/$5/$6 -o \( -d ${Par_Dir}/${New_Dir}/$5/$6 -a -w ${Par_Dir}/${New_Dir}/$5/$6 \) \) \
                 ] ; then
                _New_Dir=${New_Dir}${Num}
                while [ $Num -le 9 -a ! \( -d ${Par_Dir}/${_New_Dir} -a -w ${Par_Dir}/${_New_Dir} \) \
                        -o ! \( ! -d ${Par_Dir}/${_New_Dir}/$5    -o \( -d ${Par_Dir}/${_New_Dir}/$5    -a -w ${Par_Dir}/${_New_Dir}/$5 \) \) \
                        -o ! \( ! -d ${Par_Dir}/${_New_Dir}/$5/$6 -o \( -d ${Par_Dir}/${_New_Dir}/$5/$6 -a -w ${Par_Dir}/${_New_Dir}/$5/$6 \) \) \
                      ] ; do
                    if [ ! -d ${Par_Dir}/${_New_Dir} ] ; then
                        mkdir -p ${Par_Dir}/${_New_Dir} 2>/dev/null
                        [ $? -eq 0 ] && break
                    fi
                    Num=`expr $Num + 1`
                    _New_Dir=${New_Dir}${Num}
                done
                if [ -d ${Par_Dir}/${_New_Dir} -a -w ${Par_Dir}/${_New_Dir} \
                    -a \( ! -d ${Par_Dir}/${_New_Dir}/$5    -o \( -d ${Par_Dir}/${_New_Dir}/$5    -a -w ${Par_Dir}/${_New_Dir}/$5 \) \) \
                    -a \( ! -d ${Par_Dir}/${_New_Dir}/$5/$6 -o \( -d ${Par_Dir}/${_New_Dir}/$5/$6 -a -w ${Par_Dir}/${_New_Dir}/$5/$6 \) \) \
                    ] ; then
                   eval TMP_Dir${Dir_Num}=${Par_Dir}/${_New_Dir}
                   eval chmod $PRV \$TMP_Dir${Dir_Num} 2>/dev/null
                   eval chmod +t   \$TMP_Dir${Dir_Num} 2>/dev/null
                else
                    if [ "x${_No_Print}" != "xyes" ] ; then
                        printf "\033[1m$Delete $Print_fullpath failed\33[0m\n"
                        continue
                    fi
                fi
            else
                eval TMP_Dir${Dir_Num}=${Par_Dir}/${New_Dir}
                eval chmod $PRV \$TMP_Dir${Dir_Num} 2>/dev/null
                eval chmod +t   \$TMP_Dir${Dir_Num} 2>/dev/null
            fi
        }

        # get trash directory
        unset TMP_Dir1
        Mk_Dir "${destpath}" ".trash" '777' 1 "`date +"%Y%m%d"`" "`id -un`"
        # unset TMP_Dir2
        # Mk_Dir "${TMP_Dir1}" "`date +"%Y%m%d"`" '777' 2
        # unset TMP_Dir3
        # Mk_Dir "${TMP_Dir2}" "`id -un`" '700 3'

        [ ! -d ${TMP_Dir1}/`date +"%Y%m%d"` -a -e ${TMP_Dir1}/`date +"%Y%m%d"` ]          && $realrm -f -- ${TMP_Dir1}/`date +"%Y%m%d"` 2>/dev/null
        [ ! -d ${TMP_Dir1}/`date +"%Y%m%d"`/`id -un` -a -e ${TMP_Dir1}/`date +"%Y%m%d"` ] && $realrm -f -- ${TMP_Dir1}/`date +"%Y%m%d"`/`id -un` 2>/dev/null

        Dest_Trash=${TMP_Dir1}/`date +"%Y%m%d"`/`id -un`
        mkdir -p   ${TMP_Dir1}/`date +"%Y%m%d"`/`id -un` 2>/dev/null
        chmod 777  ${TMP_Dir1}/`date +"%Y%m%d"`          2>/dev/null
        chmod +t   ${TMP_Dir1}/`date +"%Y%m%d"`          2>/dev/null
        chmod 700  ${TMP_Dir1}/`date +"%Y%m%d"`/`id -un` 2>/dev/null
        chmod +t   ${TMP_Dir1}/`date +"%Y%m%d"`/`id -un` 2>/dev/null

        if [ "x${_No_Print}" != "xyes" ] ; then
            Print_Dest_Trash=`echo -- "$Dest_Trash" | sed 's/--[[:space:]]*//;s#%#%%#g'`
        fi

        unset _Result
        mv -f --  $fullpath ${Dest_Trash}/${newfilename} >/dev/null 2>&1 && _Result=1

        if [ "x${_No_Print}" != "xyes" ] ; then
            if [ "x$_Result" = "x1" ] ; then
               printf "$Print_fullpath moved to ${Print_Dest_Trash}/${Print_newfilename} succeed"
            else
               printf "\033[1m$Print_fullpath moved to ${Print_Dest_Trash}/${Print_newfilename} failed\33[0m\n"
            fi
        fi
        if [ "x$_Result" = "x1" ] ; then
           $trashlog_bin "${_No_Print}" "Write_Trash_Log" "Re_Sure_" `id -un` `id -un` $now `date +%s` $fullpath ${Dest_Trash}/$newfilename 
        fi
    done
fi
eof
chmod 555 ${Install_Path}/${delete_name} 2>/dev/null
chown ${Root_Name}:${Root_Group} ${Install_Path}/${delete_name} 2>/dev/null



[ -e ${Install_Path}/trashlog ] && $realrm -rf ${Install_Path}/trashlog 2>/dev/null
# Save as ${Install_Path}/trashlog
echo "#! $sh_path"    >  ${Install_Path}/trashlog
cat >> ${Install_Path}/trashlog <<- 'eof'

# Author: CC
# Date:   2016-09-25
# Compate shell: sh bash ksh
# Unix command: unset set export eval [ getopts local shift echo printf date expr df find pwd 
#               cp mv rm rmdir mkdir chmod chown id grep sed awk head sort cut read cat
# Compatibility OS: UNIX Linux (Tested:Linux/hpux/aix/freebsd)

eof
echo "realrm=$realrm" >> ${Install_Path}/trashlog
echo "$Def_Path"      >> ${Install_Path}/trashlog

cat >> ${Install_Path}/trashlog <<- 'eof'


[ "x${#}" = x0 ] && exit 1

_No_Print=$1
shift

[ "x$1" != "xWrite_Trash_Log" ] && exit 1
shift

[ "x$1" != "xRe_Sure_" ] && exit 1
shift

Mk_Dir() {
           local Par_Dir=$1
           local New_Dir=$2
           local PRV=$3
           local Dir_Num=$4
           local Username=$5
           local Num=1

            _New_Dir=${New_Dir}${Num}
            while [ $Num -le 9 -a ! \( -d ${Par_Dir}/${_New_Dir} -a -w ${Par_Dir}/${_New_Dir} \) \
                   -o ! \( ! -f ${Par_Dir}/${_New_Dir}/$5 -o \( -f ${Par_Dir}/${_New_Dir}/$5 -a -w ${Par_Dir}/${_New_Dir}/$5 \) \) \
                  ] ; do
                if [ ! -d ${Par_Dir}/${_New_Dir} ] ; then
                    mkdir -p ${Par_Dir}/${_New_Dir} 2>/dev/null
                    [ $? -eq 0 ] && break
                fi
                Num=`expr $Num + 1`
                _New_Dir=${New_Dir}${Num}
            done
            if [ -d ${Par_Dir}/${_New_Dir} -a -w ${Par_Dir}/${_New_Dir} -a \( ! -f ${Par_Dir}/${_New_Dir}/$5 -o \( -f ${Par_Dir}/${_New_Dir}/$5 -a -w ${Par_Dir}/${_New_Dir}/$5 \) \) ] ; then
               eval TMP_Dir${Dir_Num}=${Par_Dir}/${_New_Dir}
               # eval chmod $PRV \$TMP_Dir${Dir_Num} 2>/dev/null
               # eval chmod +t   \$TMP_Dir${Dir_Num} 2>/dev/null
            fi

       }


# Get trashlog directory
Home_Dir=`awk -F: '$1=="'"$1"'" {print $6}' /etc/passwd`
for i in /etc $Home_Dir /tmp ; do
    [ ! -d ${i}/.trashlog -a -e ${i}/.trashlog ] && $realrm -f ${i}/.trashlog 2>/dev/null
    mkdir -p ${i}/.trashlog 2>/dev/null
    if [ -d ${i}/.trashlog -a -w ${i}/.trashlog ] ; then
        Logdir=${i}/.trashlog
        break
    else
        unset TMP_Dir1
        Mk_Dir "$i" ".trashlog" '777' 1 $1
        if ! [ "x${TMP_Dir1}" = x ] ; then
            Logdir=${TMP_Dir1}
            break
        fi
    fi
done

if [ "x${_No_Print}" != "xyes" ] ; then
    if [ "x${Logdir}" = x ] ; then
        printf "\033[1m, but write log failed, exec \"cleantrash -R\" with root to rewrite\33[0m\n"
        exit 1
    else
        printf "\n"
    fi
fi

chmod 777 $Logdir 2>/dev/null
chmod +t  $Logdir 2>/dev/null

# Logfile=/etc/trashlog/`id -un`
Logfile=${Logdir}/$1
[ ! -f $Logfile -a -e $Logfile ] && $realrm -rf -- $Logfile 2>/dev/null
shift


echo -- "$@" | sed 's/^--[[:space:]]*//'>> $Logfile 2>/dev/null


# cp -p -- $Logfile ${Logfile}.bak 2>/dev/null

[ -e ${Logfile}.bak ] && $realrm -rf -- ${Logfile}.bak 2>/dev/null
cp -p -- $Logfile ${Logfile}.bak 2>/dev/null

# sed  's/^[[:space:]]*[[:digit:]]*[[:space:]][[:space:]]*//g' $Logfile > ${Logfile}.bak 2>/dev/null

# # perl -i -pe '$_=sprintf "%04d %s",$.,$_' $Logfile
# # awk '{gsub(/^[[:space:]]*[[:digit:]]*[[:space:]][[:space:]]*/,"");printf "%-4d %s\n",NR,$0}' ${Logfile}.bak > $Logfile

sort -r -k2 -k3 -o ${Logfile}.bak ${Logfile}.bak 2>/dev/null

Num_List=`awk ' BEGIN{n=1}
                {for (i=1; i<=NF; i++)
                    {
                        a[i]=(a[i]>=length($i)?a[i]:length($i))
                        n+=1
                    }
                }
                END{for (j=1; j<=n; j++)
                    {
                        if(j<n)
                             printf a[j]" "
                        else
                            print a[j]
                    }
                }' ${Logfile}.bak 2>/dev/null

        `
awk 'BEGIN{
        n=split("'"$Num_List"'",a)
    }
    {for (i=1; i<=n; i++)
        {
            if(i<n)
                {
                    printf "%s", $i
                    for(j=1; j<=a[i]-length($i)+1; j++)
                         printf " "
                 }
             else
                print $i
        }
    }' ${Logfile}.bak > $Logfile 2>/dev/null
#  # _len=$(awk '{ len=(length($1)>a?length($1):a)};END{print len}' $Logfile)
# awk '{printf "%-'"$(cat -- $Logfile 2>/dev/null |wc -l|wc -c )"'d %s\n",NR,$0}'  $Logfile > ${Logfile}.bak 2>/dev/null
# mv -f -- ${Logfile}.bak $Logfile 2>/dev/null

[ -f ${Logfile}.bak ] && $realrm -f -- ${Logfile}.bak 2>/dev/null

chmod 600 ${Logfile} 2>/dev/null
eof
chmod 555 ${Install_Path}/trashlog 2>/dev/null
chown ${Root_Name}:${Root_Group} ${Install_Path}/trashlog 2>/dev/null




[ -e ${Install_Path}/unrm ] && $realrm -rf ${Install_Path}/unrm 2>/dev/null
#Save as ${Install_Path}/unrm
echo "#! $sh_path"    >  ${Install_Path}/unrm
cat >> ${Install_Path}/unrm <<- 'eof'

# Author: CC
# Date:   2016-09-25
# Compate shell: sh bash ksh
# Unix command: unset set export eval [ getopts local shift echo printf date expr df find pwd 
#               cp mv rm rmdir mkdir chmod chown id grep sed awk head sort cut read cat
# Compatibility OS: UNIX Linux (Tested:Linux/hpux/aix/freebsd)

eof
echo "realrm=$realrm" >> ${Install_Path}/unrm
echo "$Def_Path"      >> ${Install_Path}/unrm
cat >> ${Install_Path}/unrm <<- 'eof'


USAGE() {
    echo "SYNOPSIS"
    echo "     ${0##*/} [-h]"
    echo "     ${0##*/} <-d id1,id2 ... | [-c] [-P path] -r id1,id2 ...| -F | -l [-f]>" 
    echo "          [-p path1,path2 ... ] [-n] [-u user1,user2 ...]"
    echo "DESCRIPTION"
    printf "     Recover the deleted files, or delete files from the trash directory\n"
    printf "     Idlist format: \"ID-\",\"-ID\",\"ID1-ID2\",\"ID\"\n\n"
    cat <<- 'EOF'
    -c                 Only use with -r, copy instead of move
    -d idlist          Delete files associated with the idlist, seperated by ","
    -f                 Only use with -l, list filename of history file instead of contents 
    -F                 IF specify -u, will delete the files belong to userlist in
                       trash directory, otherwise, will empyt trash directory
    -h                 Display this help and exit
    -l                 List trash history
    -n                 Never prompt
    -p pathlist        Specify trash history file list
    -P path            Recover destpath, only use with -r
    -r idlist          Recover the files associated with the idlist, seperated by ","
    -u userlist        Specify user to filter the history, seperated by ","                  
                       special user:"all" and "unknow"
                       all:list trash history of all users
                       unknow: deleted files in trash directory, find by "cleantrash"
EOF
}

Get_ID_List() {
    local S_ID_List=$1
    local Hist_List=$2
    local _ID ID1 ID2 i
    unset ID_List
    S_ID_List=`echo -- "$S_ID_List" | sed 's/^--[[:space:]]*//;s/,/ /g'`
    for _ID in $S_ID_List ; do
        if echo -- "$_ID" | sed 's/^--[[:space:]]*//' | grep -qE -- "^[[:digit:]]*-$" 2>/dev/null ; then
            ID1=`echo -- "$_ID" | sed 's/^--[[:space:]]*//' | cut -d- -f1`
            ID2=`awk 'END{print NR}' $Hist_List`

        elif echo -- "$_ID" | sed 's/^--[[:space:]]*//'  | grep -qE -- "^-[[:digit:]]*$" 2>/dev/null ; then
            ID1=1
            ID2=`echo "$_ID" | cut -d- -f2`

        elif echo -- "$_ID" | sed 's/^--[[:space:]]*//'  | grep -qE -- "^[[:digit:]]*-[[:digit:]]*$" 2>/dev/null ; then
            ID1=`echo "$_ID" | cut -d- -f1`
            ID2=`echo "$_ID" | cut -d- -f2`

        elif echo -- "$_ID" | sed 's/^--[[:space:]]*//'  | grep -qE -- "^[[:digit:]]*$" 2>/dev/null ; then
            ID1=$_ID
            ID2=$_ID
        fi

        i=$ID1
        while [ $i -le $ID2 ] ; do
            ID_List="$ID_List"" $i"
            i=`expr $i + 1`
        done
    done
}

Get_Hist_List1()
{
    local _OP=$1
    local _Log=$2
    if [ -s ${_Log} ] ; then
        if [ "x`id -u`" = "x0" ] ; then
            Hist_List="$Hist_List ${_Log}"
        else
            if [ x"$_OP" = x"write" ] ; then
                [ -w ${_Log}   ] && Hist_List="$Hist_List ${_Log}"
                [ ! -w ${_Log} ] && _No_List_Log="$_No_List_Log ${_Log}"
            
            elif [ x"$_OP" = x"read" ] ; then
                [ -r ${_Log}   ] && Hist_List="$Hist_List ${_Log}"
                [ ! -r ${_Log} ] && _No_List_Log="$_No_List_Log ${_Log}"
            fi
        fi
    fi
    return $?
}

Get_Hist_List() 
{   
    local _OP=$1
    local Home_Dir _Home_Dir _Log_Dir _Log
    unset Home_Dir _Home_Dir _Log_Dir _Log  Hist_List _No_List_Log

    [ x"$User_List" = "x" ] && User_List=`id -un`
    [ x"$User_List_Print" = "x" ] && User_List_Print=`id -un`

    # Get Hist_List
    Home_Dir=`awk -F: '$NF !~ /nologin$|false$/ {print $6}' /etc/passwd 2>/dev/null | sort -u | grep -vE "^$"`
    if [ "x$_Hist_List" = x ] ; then
        for _Home_Dir in /etc $Home_Dir /tmp ; do
            [ x"$_Home_Dir" = "x/" ] && _Home_Dir=""
            for _Log_Dir in `ls -A -- ${_Home_Dir} 2>/dev/null | grep "\.trashlog[[:digit:]]*" 2>/dev/null ` ; do
                for _Log in `ls -A -- ${_Home_Dir}/${_Log_Dir} 2>/dev/null` ; do
                    if echo -- ${_Log} | sed 's/^--[[:space:]]*//' | grep -qE "$User_List" 2>/dev/null ; then
                        Get_Hist_List1 $_OP ${_Home_Dir}/${_Log_Dir}/${_Log}
                    fi
                done
            done
        done
    else
        for _Log in $_Hist_List ; do
            Get_Hist_List1 $_OP $_Log
        done
    fi


    Hist_List=`echo "$Hist_List" | sed 's#^[[:space:]]*##g'`
    _No_List_Log=`echo "$_No_List_Log" | sed 's#^[[:space:]]*##g'`
    _No_List=`echo "$_No_List" | sed 's#^[[:space:]]*##g'`

    if [ "x$_No_List" != x ] ; then
        [ "x${_No_Print}" != "xyes" ] && \
        printf "\033[1mWarning: You do not have permission to operate the files deleted by user: $_No_List\033[0m\n\n"
    fi
    if [ "x$_No_List_Log" != x ] ; then
        [ "x${_No_Print}" != "xyes" ] && \
        printf "\033[1mWarning: You do not have permission to operate the files marked in $_No_List_Log\033[0m\n\n"
    fi

    # [ "x${Hist_List}" = x ] && exit 0

    return $?
}

Get_Trashlog_Bak()
{
    unset Trashlog_Bak
    local Trashlog=$1
    shift
    local ParentDir=${Trashlog%/*}
    local Logname=${Trashlog##*/}
    local New_Name=$1
    shift
    local All_Path="$@"

    Home_Dir=`awk -F: '$1=="'"${Logname}"'" {print $6}' /etc/passwd`
    [ "x$All_Path" = "x" ] && All_Path="$ParentDir $Home_Dir /tmp"
    [ "x$New_Name" = "x" ] && New_Name="${Logname}.bak"
  
    for i in $All_Path ; do
        if ! [ -d ${i} -a -w ${i} ] ; then
            continue
        else
            local Num=1
            Trashlog_Bak=${i}/${New_Name}
            if [ ! -e $Trashlog_Bak -o \( -e $Trashlog_Bak -a -w $Trashlog_Bak \) ] ; then
                break
            else
                Trashlog_Bak=${i}/${New_Name}${Num}
                while [ $Num -le 9 -a ! \( ! -e $Trashlog_Bak -o \( -e $Trashlog_Bak -a -w $Trashlog_Bak \) \) ] ; do
                    Num=`expr $Num + 1`
                    Trashlog_Bak=${i}/${New_Name}${Num}
                done

                if [ ! $Num -le 9 -o ! \( ! -e $Trashlog_Bak -o \( -e $Trashlog_Bak -a -w $Trashlog_Bak \) \) ] ; then
                    unset Trashlog_Bak
                else
                    break
                fi
            fi
        fi
    done
}

if [ $# -eq 0 ] || ! echo  -- "$@" | sed 's/^--[[:space:]]*//' | grep -qE -- "-"
then
    USAGE
    exit 1
fi


unset _No_Print Dst_path _Hist_List R_Copy List_Filename User_List User_List_Print _No_List  S_ID_List _Delete _Recover _Empty _List _Help


while getopts "cd:fFhlnp:P:r:u:" Option
do
    case "$Option" in

        c)
            R_Copy=yes
            ;;
        f)
            List_Filename=yes
            ;;
        n)
            _No_Print=yes
            ;;
        P)
            Dst_path=`echo -- "$OPTARG" | sed 's/^--[[:space:]]*//' | sed 's#^.*-P[[:space:]]*\([[:graph:],][[:graph:],]*\).*#\1#'`
            ;;
        p)
            _Hist_List=`echo -- "$OPTARG" | sed 's/^--[[:space:]]*//' | sed 's#^.*-p[[:space:]]*\([[:graph:],][[:graph:],]*\).*#\1#;s#,# #g'`
            ;;
        u)
            # Get User_List

            if echo -- "$OPTARG" | sed 's/^--[[:space:]]*//' | grep -qE -- "all" 2>/dev/null ; then
                if [ "x`id -u`" = "x0" ] ; then
                    User_List=.
                    User_List_Print="all users"
                else
                    User_List=`id -un`
                    User_List_Print=`id -un`
                    # _No_List=`echo -- "$OPTARG"  | sed 's/^--[[:space:]]*//' | sed 's#'\`id -un\`'##g;s#,,*#,#g;s#^,##g;s#,$##g'`
                    _No_List="all users"
                fi
            else
                if [ "x`id -u`" = "x0" ] ; then
                    User_List=`echo -- "$OPTARG" | sed 's/^--[[:space:]]*//' | sed 's#,,*#|#g;s#|$##;s#^|##'`
                    User_List_Print=`echo -- "$OPTARG" | sed 's/^--[[:space:]]*//' | sed 's#,,*#,#g;s#,$##;s#^,##'`

                else
                    User_List=`id -un`
                    User_List_Print=`id -un`
                    _No_List=`echo -- "$OPTARG"  | sed 's/^--[[:space:]]*//' | sed 's#'\`id -un\`'##g;s#,,*#,#g;s#^,##g;s#,$##g'`
                fi
            fi
            
            ;;
        h)
            _Help=yes
            USAGE
            exit 0
            ;;
        d)
            S_ID_List="$OPTARG"
            _Delete=yes

            F_Delete() 
            {
                local S_ID_List=$1
                local _ID _ID_RE _ID_File _ID_Line ID_Line IDS
                unset _ID _ID_RE _ID_File _ID_Line ID_Line IDS

                if [ "x${_No_Print}" != "xyes" ] ; then
                    printf "\033[1mDelete the files specified by idlist which recycled by user: $User_List_Print [YES/NO]:[NO]\033[0m"
                    unset reply
                    read reply
                fi

                if echo $reply | grep -qiE "y|ye|yes" ||  [ "x${_No_Print}" = "xyes" ] ; then

                    # Return ID_List
                    Get_ID_List "$S_ID_List" $Hist_List

                    for _ID in $ID_List ; do
                        _Path=`awk 'NR == '"$_ID"' {print $NF}' $Hist_List 2>/dev/null`
                        if [ "x${_No_Print}" != "xyes" ] ; then
                            _Print_Path=`echo -- "$_Path" | sed 's/--[[:space:]]*//;s#%#%%#g'`
                        fi
                        if [ `echo -- "$_Path" | sed 's/^--[[:space:]]*//' | wc -l` -eq  1 ] && ls -- "$_Path" >/dev/null 2>&1 ; then
                            if $realrm -rf -- "$_Path" >/dev/null 2>&1
                            then
                                if [ `ls -A -- ${_Path%/*} >/dev/null 2>&1 | wc -l` -eq 0 ] ; then
                                    rmdir -- ${_Path%/*} 2>/dev/null
                                fi
                                if [ `ls -A -- ${_Path%/*/*} >/dev/null 2>&1 | wc -l` -eq 0 ] ; then
                                    rmdir -- ${_Path%/*/*} 2>/dev/null
                                fi

                                IDS="${IDS}\n`awk 'NR == '"$_ID"' {print FILENAME":"FNR}' $Hist_List 2>/dev/null`"

                                [ "x${_No_Print}" != "xyes" ]  && \
                                printf "Delete $_Print_Path succeed\n"
                            else
                                [ "x${_No_Print}" != "xyes" ]  && \
                                printf "\033[1mDelete $_Print_Path failed\033[0m\n"
                                continue
                            fi
                        else
                            if [ `ls -A -- ${_Path%/*} >/dev/null 2>&1 | wc -l` -eq 0 ] ; then
                                rmdir -- ${_Path%/*} 2>/dev/null
                            fi
                            if [ `ls -A -- ${_Path%/*/*} >/dev/null 2>&1 | wc -l` -eq 0 ] ; then
                                rmdir --  ${_Path%/*/*} 2>/dev/null
                            fi

                            IDS="${IDS}\n`awk 'NR == '"$_ID"' {print FILENAME":"FNR}' $Hist_List 2>/dev/null`"

                            [ "x${_No_Print}" != "xyes" ]  && printf "Delete $_Print_Path succeed\n"
                        fi
                    done

                    if [ "x${IDS}" = x ] ; then
                        exit 1
                    fi

                    ID_Line=`printf "${IDS}\n" | awk -F: '$0 !~ /^$/ {
                                                            if (Var[$1]=="") 
                                                                Var[$1]=$2
                                                            else 
                                                                Var[$1]=Var[$1]"|"$2
                                                         }
                                                         END{
                                                                for (i in Var) 
                                                                    print i":"Var[i]
                                                            }'
                            `
                    for _ID_Line in $ID_Line ; do
                        _ID_File=`echo $_ID_Line | cut -d: -f1`
                        _ID_RE=`echo $_ID_Line | cut -d: -f2`

                        unset Trashlog_Bak
                        Get_Trashlog_Bak ${_ID_File}

                        if [ "x$Trashlog_Bak" != "x" ] ; then
                            [ -e $Trashlog_Bak ] && $realrm -rf -- $Trashlog_Bak 2>/dev/null
                            cp -p --  $_ID_File  $Trashlog_Bak 2>/dev/null
                            awk 'NR !~ /'"$_ID_RE"'/' $_ID_File > $Trashlog_Bak 2>/dev/null
                            mv -- $Trashlog_Bak $_ID_File  2>/dev/null
                        else
                            printf "\033[1m but write log: $_ID_File failed, perform again with user: root\33[0m\n"
                        fi
                    done
                fi
            }
            ;;
        r)
            S_ID_List="$OPTARG"
            _Recover=yes

            F_Recover() 
            {
                local S_ID_List=$1
                local _ID _ID_RE _ID_File _ID_Line ID_Line IDS
                unset _ID _ID_RE _ID_File _ID_Line ID_Line IDS


                if [ "x${_No_Print}" != "xyes" ] ; then
                    printf "\033[1mRecover the files specified by idlist which recycled by user: $User_List_Print [YES/NO]:[NO]\033[0m"
                    unset reply
                    read reply
                fi

                if echo $reply | grep -qiE "y|ye|yes" ||  [ "x${_No_Print}" = "xyes" ] ; then

                    #return ID_List
                    Get_ID_List "$S_ID_List" $Hist_List
                    
                    for _ID in $ID_List ; do
                        _Path=`awk 'NR == '"$_ID"' {print $NF}' $Hist_List 2>/dev/null`
                        _Spath=`awk 'NR == '"$_ID"' {print $(NF-1)}' $Hist_List 2>/dev/null`
                        _Sfile=${_Path##*/}

                        [ "x${Dst_path}" != x ] && _Spath=${Dst_path}/`echo $_Sfile | sed 's#_[^_]*$##;s#_[^_]*$##'`

                        if [ "x${_No_Print}" != "xyes" ] ; then
                            _Print_Path=`echo -- "$_Path" | sed 's/--[[:space:]]*//;s#%#%%#g'`
                        fi

                        if [ "x${_No_Print}" != "xyes" ] ; then
                            _Print_Spath=`echo -- "$_Spath" | sed 's/--[[:space:]]*//;s#%#%%#g'`
                        fi

                        
                        if [ `echo -- "$_Path" | sed 's/^--[[:space:]]*//' | wc -l` -eq  1 ] && ls -- "$_Path" >/dev/null 2>&1 ; then
                            if [ -e $_Spath ] ; then
                                [ "x${_No_Print}" != "xyes" ] && \
                                printf "\033[1mRecover $_Print_Path failed, $_Print_Spath exists\033[0m\n"
                                continue
                            else
                                if [ "x$R_Copy" != "xyes" ] ; then
                                    if mv -- $_Path $_Spath >/dev/null 2>&1
                                    then
                                        if [ `ls -A -- ${_Path%/*} >/dev/null 2>&1 | wc -l` -eq 0 ] ; then
                                            rmdir -- ${_Path%/*} 2>/dev/null
                                        fi
                                        if [ `ls -A -- ${_Path%/*/*} >/dev/null 2>&1 | wc -l` -eq 0 ] ; then
                                            rmdir -- ${_Path%/*/*} 2>/dev/null
                                        fi

                                        IDS="${IDS}\n`awk 'NR == '"$_ID"' {print FILENAME":"FNR}' $Hist_List 2>/dev/null`"

                                        [ "x${_No_Print}" != "xyes" ] && \
                                        printf "Recover $_Print_Path to $_Print_Spath succeed\n"
                                    else
                                        [ "x${_No_Print}" != "xyes" ] && \
                                        printf "\033[1mRecover $_Print_Path to $_Print_Spath failed\033[0m\n"
                                        continue
                                    fi
                                elif [ "x$R_Copy" = "xyes" ] ; then
                                    if cp -p -- $_Path $_Spath >/dev/null 2>&1
                                    then
                                        [ "x${_No_Print}" != "xyes" ] && \
                                        printf "Copy $_Print_Path to $_Print_Spath succeed\n"
                                    else
                                        [ "x${_No_Print}" != "xyes" ] && \
                                        printf "\033[1mCopy $_Print_Path to $_Print_Spath failed\033[0m\n"
                                        continue
                                    fi
                                fi
                            fi
                        else
                            if [ `ls -A -- ${_Path%/*} >/dev/null 2>&1 | wc -l` -eq 0 ] ; then
                                rmdir -- ${_Path%/*} 2>/dev/null
                            fi
                            if [ `ls -A -- ${_Path%/*/*} >/dev/null 2>&1 | wc -l` -eq 0 ] ; then
                                rmdir -- ${_Path%/*/*} 2>/dev/null
                            fi

                            IDS="${IDS}\n`awk 'NR == '"$_ID"' {print FILENAME":"FNR}' $Hist_List 2>/dev/null`"

                            [ "x${_No_Print}" != "xyes" ] && \
                            printf "\033[1mRecover failed, $_Print_Path not exists, to be delete log item\033[0m\n"
                        fi
                    done

                    if [ "x${IDS}" = x ] ; then
                        exit 1
                    fi
                    ID_Line=`printf "${IDS}\n"|awk -F: '$0!~/^$/{
                                                                       if (Var[$1]=="") 
                                                                           Var[$1]=$2
                                                                       else 
                                                                           Var[$1]=Var[$1]"|"$2
                                                                    }
                                                                    END{
                                                                           for (i in Var) 
                                                                               print i":"Var[i]
                                                                       }'
                           `
                    for _ID_Line in $ID_Line ; do
                       _ID_File=`echo $_ID_Line | cut -d: -f1`
                       _ID_RE=`echo $_ID_Line | cut -d: -f2`

                       unset Trashlog_Bak
                       Get_Trashlog_Bak ${_ID_File}

                       if [ "x$Trashlog_Bak" != "x" ] ; then
                           [ -e $Trashlog_Bak ] && $realrm -rf -- $Trashlog_Bak 2>/dev/null
                           cp -p --  $_ID_File  $Trashlog_Bak 2>/dev/null
                           awk 'NR !~ /'"$_ID_RE"'/' $_ID_File > $Trashlog_Bak 2>/dev/null
                           mv -- $Trashlog_Bak $_ID_File  2>/dev/null
                           # printf "\n"
                       else
                            printf "\033[1m but write log: $_ID_File failed, perform again with user: root\33[0m\n"
                       fi

                    done
                fi
            }
            ;;
        F)
            _Empty=yes

            F_Empty() 
            {
               local _Hist _File _ID _ID_RE
               unset _Hist _File _ID _ID_RE

                if [ "x${_No_Print}" != "xyes" ] ; then
                    printf "\033[1mEmpty the trash directory recycled by user: $User_List_Print [YES/NO]:[NO]\033[0m"
                    unset reply
                    read reply
                fi

                if echo $reply | grep -qiE "y|ye|yes" || [ "x${_No_Print}" = "xyes" ] ; then

                    for _Hist in $Hist_List ; do
                        _ID=0
                        while read line || [ -n "$line" ] ; do
                            # _ID=`echo "$line" | awk '{print $1}'`
                            _ID=`expr $_ID + 1`
                            _File=`echo -- "$line" | sed 's/^--[[:space:]]*//' | awk '{print $NF}'`
                            if [ "x${_No_Print}" != "xyes" ] ; then
                                _Print_File=`echo -- "$_File" | sed 's/--[[:space:]]*//;s#%#%%#g'`
                            fi
                            if ls -- $_File >/dev/null 2>&1 ; then
                                if $realrm -fr -- $_File ; then
                                    if [ `ls -A -- ${_File%/*} >/dev/null 2>&1 | wc -l` -eq 0 ] ; then
                                        rmdir -- ${_File%/*} 2>/dev/null
                                    fi
                                    if [ `ls -A -- ${_File%/*/*} >/dev/null 2>&1 | wc -l` -eq 0 ] ; then
                                        rmdir -- ${_File%/*/*} 2>/dev/null
                                    fi
                                    # _ID_RE="${_ID_RE}\|""^[[:space:]]*$_ID[[:space:]][[:space:]]*"
                                    # _ID_RE="${_ID_RE};/^[[:space:]]*$_ID[[:space:]][[:space:]]*/d"
                                    _ID_RE="${_ID_RE}|_ID"
                                    [ "x${_No_Print}" != "xyes" ] && \
                                    printf "Delete $_Print_File succeed\n"
                                else
                                    [ "x${_No_Print}" != "xyes" ] && \
                                    printf "\033[1mDelete $_Print_File failed\033[0m\n"
                                    continue
                                fi
                            else
                                if [ `ls -A -- ${_File%/*} >/dev/null 2>&1 | wc -l` -eq 0 ] ; then
                                    rmdir -- ${_File%/*} 2>/dev/null
                                fi
                                if [ `ls -A -- ${_File%/*/*} >/dev/null 2>&1 | wc -l` -eq 0 ] ; then
                                    rmdir -- ${_File%/*/*} 2>/dev/null
                                fi
                                # _ID_RE="${_ID_RE}\|""^[[:space:]]*$_ID[[:space:]][[:space:]]*"
                                # _ID_RE="${_ID_RE};/^[[:space:]]*$_ID[[:space:]][[:space:]]*/d"
                                _ID_RE="${_ID_RE}|_ID"
                                [ "x${_No_Print}" != "xyes" ] && \
                                printf "Delete $_Print_File succeed\n"
                            fi
                        done < $_Hist

                        if [ "x${_ID_RE}" = x ] ; then
                            exit 1
                        fi

                        unset Trashlog_Bak
                        Get_Trashlog_Bak $_Hist
                        

                        if [ "x$Trashlog_Bak" != "x" ] ; then
                            [ -e $Trashlog_Bak ] && $realrm -rf -- $Trashlog_Bak 2>/dev/null
                            cp -p -- $_Hist $Trashlog_Bak 2>/dev/null
                            # sed '/'"${_ID_RE#\\|}"'/d;s/^[[:space:]]*[[:digit:]]*[[:space:]][[:space:]]*//g' $_Hist > ${_Hist}.bak
                            # sed ''"${_ID_RE#;}"';s/^[[:space:]]*[[:digit:]]*[[:space:]][[:space:]]*//g' $_Hist > ${_Hist}.bak 2>/dev/null
                            awk 'NR !~ /'"${_ID_RE#[[:space:]]*\|}"'/' $_Hist > $Trashlog_Bak 2>/dev/null

                            if [ ! -s $Trashlog_Bak ] ; then
                                $realrm -f -- $Trashlog_Bak $_Hist 2>/dev/null
                            else
                                # sort -r -k2 -k3 -o ${_Hist}.bak ${_Hist}.bak 2>/dev/null
                                ## _len=$(awk '{ len=(length($1)>a?length($1):a)};END{print len}' ${_Hist}.bak)
                                # awk '{printf "%-'"$(cat -- ${_Hist}.bak 2>/dev/null|wc -l|wc -c )"'d %s\n",NR,$0}'  ${_Hist}.bak > $_Hist 2>/dev/null
                                mv -- $Trashlog_Bak $_Hist 2>/dev/null
                            fi
                        else
                            printf "\033[1m, but write log: $_Hist failed, perform again with user: root\33[0m\n"
                        fi

                    done
                fi
            }
            ;;
        l)
            _List=yes

            F_List()
            {
                if [ "x$List_Filename" = "xyes" ] ; then
                    echo "$Hist_List" | tr " " "\n" | grep -v "^$"
                elif [ "x$List_Filename" != "xyes" ] ; then

                    unset Trashlog_Bak
                    Get_Trashlog_Bak NULL .trashlist_one /tmp
                    Trashlist_One=$Trashlog_Bak

                    unset Trashlog_Bak
                    Get_Trashlog_Bak NULL .trashlist_header /tmp
                    Trashlist_Header=$Trashlog_Bak

                    if [ "x$Trashlist_One" != "x" -a "x$Trashlist_One" != "x"  ] ; then

                        [ -e ${Trashlist_One} ]   && $realrm -rf -- ${Trashlist_One}   2>/dev/null
                        [ -e ${Trashlist_Header} ] && $realrm -rf -- ${Trashlist_Header} 2>/dev/null

                        awk '{$4="";sub(/\/[^\/]*$/,"",$NF);print NR" "$0}' $Hist_List > ${Trashlist_One} 2>/dev/null
                        echo "ID User Date Time SourcePath TrashPath" > ${Trashlist_Header} 2>/dev/null
                        Num_List=`awk ' BEGIN{n=1}
                                    {for (i=1; i<=NF; i++)
                                        {
                                            a[i]=(a[i]>=length($i)?a[i]:length($i))
                                            n+=1
                                        }
                                    }
                                    END{for (j=1; j<=n; j++)
                                        {
                                            if(j<n)
                                                 printf a[j]" "
                                            else
                                                print a[j]
                                        }
                                    }' ${Trashlist_Header} ${Trashlist_One} 2>/dev/null
                                `
                        awk 'BEGIN{
                                n=split("'"$Num_List"'",a)
                            }
                            {for (i=1; i<=n; i++)
                                {
                                    if(i<n)
                                        {
                                            printf "%s", $i
                                            for(j=1;j<=a[i]-length($i)+1;j++)
                                                 printf " "
                                         }
                                     else
                                        print $i
                                }
                            }' ${Trashlist_Header} ${Trashlist_One}  2>/dev/null | more

                        [ -f ${Trashlist_One} ]   && $realrm -f -- ${Trashlist_One}   2>/dev/null
                        [ -f ${Trashlist_Header} ] && $realrm -f -- ${Trashlist_Header} 2>/dev/null
                    else
                        printf "\033[1mYou have no write to /tmp, list failed\33[0m!\n"
                    fi
                fi
            }
            ;;
        \?)
            USAGE
            exit 1
            ;;
    esac
done

if [ "x$_Delete" = "xyes" ] &&  [ "x$R_Copy" = "xyes" -o "x$List_Filename" = "xyes" -o "x$Dst_path" != "x" -o "x$_Empty" = "xyes" -o "x$_Recover" = "xyes" -o "x$_List" = "xyes" ] ; then
    USAGE
    exit 1
fi

if [ "x$_Recover" = "xyes" ] && [ "x$List_Filename" = "xyes" ] ; then
    USAGE
    exit 1
fi

if [ "x$_Empty" = "xyes" ] && [ "x$R_Copy" = "xyes" -o "x$List_Filename" = "xyes" -o "x$Dst_path" != "x" -o "x$_Recover" = "xyes" -o "x$_List" = "xyes" ]              ; then
    USAGE
    exit 1
fi

if [ "x$_Help" = "xyes" ] && [ "x$R_Copy" = "xyes" -o "x$_Delete" = "xyes" -o "x$List_Filename" = "xyes" -o "x$_Empty" = "xyes" -o "x$_Recover" = "xyes" -o "x$User_List" != "x" -o  "x$_Hist_List" != "x"  -o  "x$Dst_path" != "x" -o "x$_No_Print" = "xyes" -o "x$_List" = "xyes" ] ; then
    USAGE
    exit 1
fi
if [ "x$_List" = "xyes" ] && [ "x$R_Copy" = "xyes" -o "x$_Recover" = "xyes" -o "x$Dst_path" != "x" -o "x$_No_Print" = "xyes" ] ; then
    USAGE
    exit 1
fi

if [ "x$_Delete" = "xyes" ] ; then
    unset Hist_List
    # Get Hist_List
    Get_Hist_List write
    [ "x${Hist_List}" = x ] && exit 0

    F_Delete $S_ID_List
    exit $?
fi

if [ "x$_Recover" = "xyes" ] ; then
    unset Hist_List
    # Get Hist_List
    Get_Hist_List write
    [ "x${Hist_List}" = x ] && exit 0

    F_Recover $S_ID_List
    exit $?
fi

if [ "x$_Empty" = "xyes" ] ; then
    unset Hist_List
    # Get Hist_List
    Get_Hist_List write
    [ "x${Hist_List}" = x ] && exit 0

    F_Empty
    exit $?
fi
if [ "x$_List" = "xyes" ] ; then
    unset Hist_List
    # Get Hist_List
    Get_Hist_List read
    [ "x${Hist_List}" = x ] && exit 0

    F_List
    exit $?
fi


eof
chmod 555 ${Install_Path}/unrm 2>/dev/null
chown ${Root_Name}:${Root_Group} ${Install_Path}/unrm 2>/dev/null


[ -e ${Install_Path}/cleantrash ] && $realrm -rf ${Install_Path}/cleantrash 2>/dev/null
#Save as ${Install_Path}/cleantrash
echo "#! $sh_path"                           >  ${Install_Path}/cleantrash
cat >> ${Install_Path}/cleantrash <<- 'eof'

# Author: CC
# Date:   2016-09-25
# Compate shell: sh bash ksh
# Unix command: unset set export eval [ getopts local shift echo printf date expr df find pwd 
#               cp mv rm rmdir mkdir chmod chown id grep sed awk head sort cut read cat
# Compatibility OS: UNIX Linux (Tested:Linux/hpux/aix/freebsd)

eof
echo "realrm=$realrm"                        >> ${Install_Path}/cleantrash
echo "$Def_Path"                             >> ${Install_Path}/cleantrash
echo "Expire_Day=$Expire_Day"                    >> ${Install_Path}/cleantrash
echo "trashlog_bin=${Install_Path}/trashlog" >> ${Install_Path}/cleantrash
echo "unrm_bin=${Install_Path}/unrm"         >> ${Install_Path}/cleantrash

cat >> ${Install_Path}/cleantrash <<- 'eof'



USAGE() {
    echo "SYNOPSIS"
    echo "     ${0##*/} [-h]"
    echo "     ${0##*/} <-r [-d hold_Day] | -R [-P path1,path2 ...]> [-p path1,path2 ...] [-n] [-u user1,user2 ...]"
    echo "DESCRIPTION"
    printf "     Delete expired files or Find deleted files not marked in logfiles\n\n"
    cat <<- 'EOF'
    -d hold_Day        Specify expiration days of deleted files, only use with -r
    -h                 Display this help and exit
    -n                 Never prompt
    -p pathlist        Specify trash history file list
    -P pathlist        Specify trash directory, only use with -R
    -r                 Delete expired files
    -R                 Find deleted files not marked in logfiles
    -u userlist        Specify user to filter the history, seperated by ","                  
                       special user:"all" and "unknow"
                       all:list trash history of all users
                       unknow: deleted files in trash directory, find by "cleantrash"

EOF
}


Get_Hist_List1()
{
    local _OP=$1
    local _Log=$2
    if [ -s ${_Log} ] ; then
        if [ "x`id -u`" = "x0" ] ; then
            Hist_List="$Hist_List ${_Log}"
        else
            if [ x"$_OP" = x"write" ] ; then
                [ -w ${_Log}   ] && Hist_List="$Hist_List ${_Log}"
                [ ! -w ${_Log} ] && _No_List_Log="$_No_List_Log ${_Log}"
            
            elif [ x"$_OP" = x"read" ] ; then
                [ -r ${_Log}   ] && Hist_List="$Hist_List ${_Log}"
                [ ! -r ${_Log} ] && _No_List_Log="$_No_List_Log ${_Log}"
            fi
        fi
    fi
    return $?
}



Get_Hist_List() 
{   
    local _OP=$1
    local Home_Dir _Home_Dir _Log_Dir _Log
    unset Home_Dir _Home_Dir _Log_Dir _Log  Hist_List _No_List_Log

    # [ x"$User_List" = "x" ] && User_List=`id -un`
    # [ x"$User_List_Print" = "x" ] && User_List_Print=`id -un`
    [ x"$User_List" = "x" ] && User_List="."
    [ x"$User_List_Print" = "x" ] && User_List_Print="all users"

    # Get Hist_List
    Home_Dir=`awk -F: '$NF !~ /nologin$|false$/ {print $6}' /etc/passwd 2>/dev/null | sort -u | grep -vE "^$"`
    if [ "x$_Hist_List" = x ] ; then
        for _Home_Dir in /etc $Home_Dir /tmp ; do
            [ x"$_Home_Dir" = "x/" ] && _Home_Dir=""
            for _Log_Dir in `ls -A -- ${_Home_Dir} 2>/dev/null | grep "\.trashlog[[:digit:]]*" 2>/dev/null ` ; do
                for _Log in `ls -A -- ${_Home_Dir}/${_Log_Dir} 2>/dev/null` ; do
                    if echo -- ${_Log} | sed 's/^--[[:space:]]*//' | grep -qE "$User_List" 2>/dev/null ; then
                        Get_Hist_List1 $_OP ${_Home_Dir}/${_Log_Dir}/${_Log}
                    fi
                done
            done
        done
    else
        for _Log in $_Hist_List ; do
            Get_Hist_List1 $_OP $_Log
        done
    fi

    Hist_List=`echo "$Hist_List" | sed 's#^[[:space:]]*##g'`
    _No_List_Log=`echo "$_No_List_Log" | sed 's#^[[:space:]]*##g'`
    _No_List=`echo "$_No_List" | sed 's#^[[:space:]]*##g'`

    if [ "x$_No_List" != x ] ; then
        [ "x${_No_Print}" != "xyes" ] && \
        printf "\033[1mWarning: You do not have permission to operate the files deleted by user: $_No_List\033[0m\n\n"
    fi
    if [ "x$_No_List_Log" != x ] ; then
        [ "x${_No_Print}" != "xyes" ] && \
        printf "\033[1mWarning: You do not have permission to operate the files marked in $_No_List_Log\033[0m\n\n"
    fi

    # [ "x${Hist_List}" = x ] && exit 0

    return $?
}


if [ $# -eq 0 ] || ! echo  -- "$@" | sed 's/^--[[:space:]]*//' | grep -qE -- "-" ; then
    # USAGE
    # exit 1
    set -- "-rn"
fi

unset Expire_Day _No_Print _Hist_List _ID_List _TrashDir User_List User_List_Print _No_List _Recycle _Find _Help


while getopts "d:hnp:P:rRu:" Option
do
    case "$Option" in
        d)
            Expire_Day="$OPTARG"
            ;;
        h)
            _Help=yes
            USAGE
            exit 0
            ;;
        n)
            _No_Print=yes
            ;;
        P)
            _TrashDir=`echo -- "$OPTARG" | sed 's/^--[[:space:]]*//' | sed 's#^.*-P[[:space:]]*\([[:graph:],][[:graph:],]*\).*#\1#'`
            ;;
        p)
            _Hist_List=`echo -- "$OPTARG" | sed 's/^--[[:space:]]*//' | sed 's#^.*-p[[:space:]]*\([[:graph:],][[:graph:],]*\).*#\1#;s#,# #g'`
            ;;
        u)
            # Get User_List

            if echo -- "$OPTARG" | sed 's/^--[[:space:]]*//' | grep -qE -- "all" 2>/dev/null ; then
                if [ "x`id -u`" = "x0" ] ; then
                    User_List=.
                    User_List_Print="all users"
                else
                    User_List=`id -un`
                    User_List_Print=`id -un`
                    # _No_List=`echo -- "$OPTARG"  | sed 's/^--[[:space:]]*//' | sed 's#'\`id -un\`'##g;s#,,*#,#g;s#^,##g;s#,$##g'`
                    _No_List="all users"
                fi
            else
                if [ "x`id -u`" = "x0" ] ; then
                    User_List=`echo -- "$OPTARG" | sed 's/^--[[:space:]]*//' | sed 's#,,*#|#g;s#|$##;s#^|##'`
                    User_List_Print=`echo -- "$OPTARG" | sed 's/^--[[:space:]]*//' | sed 's#,,*#,#g;s#,$##;s#^,##'`

                else
                    User_List=`id -un`
                    User_List_Print=`id -un`
                    _No_List=`echo -- "$OPTARG"  | sed 's/^--[[:space:]]*//' | sed 's#'\`id -un\`'##g;s#,,*#,#g;s#^,##g;s#,$##g'`
                fi
            fi
            
            ;;
        r)
            _Recycle=yes


            F_Recycle()
            {
                local _ID_List
                unset _ID_List
                if [ "x${_No_Print}" != "xyes" ] ; then
                    printf "\033[1mDelete expired files recycled by user: $User_List_Print [YES/NO]:[NO]\033[0m"
                    unset reply
                    read reply
                fi

                if echo $reply | grep -qiE "y|ye|yes" ||  [ "x${_No_Print}" = "xyes" ] ; then

                    _ID_List=`awk '{ "date +%s"|getline N; if ((N-$4)/86400 >= '"$Expire_Day"') printf NR"," } 
                                   END{printf "\n"}'  $Hist_List  2>/dev/null
                             `
                    if [ "x${_ID_List}" != x ] ; then
                        if [ "x${_No_Print}" != "xyes" ] ; then
                            $unrm_bin -nd -u $_ID_List $Hist_List >/dev/null 2>&1
                        else
                            $unrm_bin -d -u $_ID_List $Hist_List >/dev/null 2>&1
                        fi
                    fi
                fi
            }
            ;;


        R)
            _Find=yes

            F_Find()
            {
                local TrashDir
                unset TrashDir
                if [ "x${_No_Print}" != "xyes" ] ; then
                    printf "\033[1mFind deleted files not marked in logfiles [YES/NO]:[NO]\033[0m"
                    unset reply
                    read reply
                fi

                if echo $reply | grep -qiE "y|ye|yes" ||  [ "x${_No_Print}" = "xyes" ] ; then

                    if [ "x$_TrashDir" = x ] ; then 
                        TrashDir=`find  / -type d -name ".trash" 2>/dev/null`
                        TrashDir="$TrashDir `find  / -type d -name ".trash[[:digit:]]" 2>/dev/null`"
                    else
                        TrashDir=$_TrashDir
                    fi

                    # TrashDir=`echo "${TrashDir}" | sed 's#^[[:space:]]*##g'`

                    [ "x${TrashDir}" = x ] && exit 0

                    
                    for _Trash_Dir in $TrashDir  ;do
                        for  _Date_Dir in `ls -A -- $_Trash_Dir 2>/dev/null | grep -v "[^[[:digit:]]" ` ; do
                            for _User_Dir in `ls  -A -- ${_Trash_Dir}/${_Date_Dir} 2>/dev/null | grep -E "$User_List" 2>/dev/null` ; do
                                for _File in `ls  -A -- ${_Trash_Dir}/${_Date_Dir}/${_User_Dir} 2>/dev/null` ; do
                                    if ! grep -qF "${_Trash_Dir}/${_Date_Dir}/${_User_Dir}/${_File}" $Hist_List 2>/dev/null ; then
                                        if [ "x${_No_Print}" != "xyes" ] ; then
                                            Print_filename=`echo -- "${_Trash_Dir}/${_Date_Dir}/${_User_Dir}/${_File}" | sed 's/--[[:space:]]*//;s#%#%%#g'`
                                            printf "Find $Print_filename"
                                        fi
                                        $trashlog_bin "$_No_Print" "Write_Trash_Log" "Re_Sure_" "unknow" "unknow" `date +%Y-%m-%d` `date +%H:%M:%S` `date +%s` "${_File}" "${_Trash_Dir}/${_Date_Dir}/${_User_Dir}/${_File}"
          
                                    fi
                                done
                            done
                        done
                    done
                fi
            }
            ;;
        \?)
            USAGE
            exit 1
            ;;
    esac
done


if [ "x$_Find" = "xyes" ] && [ "x$Expire_Day" != "x" -o "x$_Recycle" = "xyes" ] ; then
    USAGE
    exit 1
fi

if [ "x$_Recycle" = "xyes" ] && [ "x$_TrashDir" != "x" ] ; then
    USAGE
    exit 1
fi

if [ "x$_Help" = "xyes" ] && [ "x$Expire_Day" != "x" -o "x$_No_Print" = "xyes" -o "x$_Hist_List" != "x" -o "x$_TrashDir" != "x" -o "x$_Recycle" = "xyes" -o "x$_Find" = "xyes" -o "x$User_List" != "x" ] ; then
    USAGE
    exit 1
fi

[ "x$_No_Print" != "xyes" ] && _No_Print=no

if [ "x$_Recycle" = "xyes" ] ; then
    unset  Hist_List
    Get_Hist_List write
    [ "x${Hist_List}" = x ] && exit 0

    F_Recycle
    exit $?
fi
if [ "x$_Find" = "xyes" ] ; then
    unset  Hist_List
    Get_Hist_List write
    [ "x${Hist_List}" = x ] && Hist_List=/etc/.trashlog/unknow

    F_Find
    exit $?
fi

eof
chmod 555 ${Install_Path}/cleantrash 2>/dev/null
chown ${Root_Name}:${Root_Group} ${Install_Path}/cleantrash 2>/dev/null





#alias
if [ "x$_Install_Alias" = "xyes" ] ; then

    # User_Home=`awk -F: '$NF ~ /.*sh$/ {print $6}' /etc/passwd|sort -u|grep -vE "^/$|^$"`
    if [ "x$Shell_Config_Find_Path" != "x" ] ; then
        Find_Dir="$Shell_Config_Find_Path"
    else
        User_Home=`awk -F: '$NF !~ /nologin$|false$/ {print $6}' /etc/passwd | sort -u | grep -vE "^/$|^$"`
        Find_Dir="/etc/ $User_Home /.[!.]*"
    fi

    _Profile_List=
    _Profile_List="${_Profile_List} `find $Find_Dir -type f  -name ".*sh*profile"  2>/dev/null`"
    _Profile_List="${_Profile_List} `find $Find_Dir -type f  -name .profile  2>/dev/null`"
    _Profile_List="${_Profile_List} `find $Find_Dir -type f  -name ".*login"    2>/dev/null`"
    _Profile_List="${_Profile_List} `find $Find_Dir -type f  -name ".*[!c]shrc" 2>/dev/null`"
    _Profile_List="${_Profile_List} `find $Find_Dir -type f  -name ".shrc" 2>/dev/null`"
    _Profile_List_Csh=`find $Find_Dir -type f  -name ".*cshrc" 2>/dev/null`
    for _sh_file in $_Profile_List $_Profile_List_Csh /etc/profile; do
        sed  '/^[[:space:]]*alias[[:space:]]*_rm[[:space:]=]*/d;
              /^[[:space:]]*alias[[:space:]]*rm[[:space:]=]*/d;
              /^[[:space:]]*alias[[:space:]]*rF[[:space:]=]*/d;
              /^[[:space:]]*alias[[:space:]]*rl[[:space:]=]*/d;
              /^[[:space:]]*alias[[:space:]]*rla[[:space:]=]*/d;
              /^[[:space:]]*alias[[:space:]]*rd[[:space:]=]*/d;
              /^[[:space:]]*alias[[:space:]]*rr[[:space:]=]*/d;
             ' $_sh_file > /tmp/${_sh_file##*/}
        if echo $_sh_file | grep -q "cshrc" ; then
            cat >> /tmp/${_sh_file##*/} <<- eof
            alias _rm  $realrm
            alias rm   "$delete_name -n"
            alias rF   "$delete_name -F"
            alias rl   'unrm -l'
            alias rla  'unrm -l -u all'
            alias rd   'unrm -d'
            alias rr   'unrm -r'
eof

        else
            cat >> /tmp/${_sh_file##*/} <<- eof
            alias _rm=$realrm
            alias rm="$delete_name -n"
            alias rF="$delete_name -F"
            alias rl='unrm -l'
            alias rla='unrm -l -u all'
            alias rd='unrm -d'
            alias rr='unrm -r'
eof
        fi
        mv -f -- /tmp/${_sh_file##*/} $_sh_file 2>/dev/null
        [ -f /tmp/${_sh_file##*/} ] && $realrm -f /tmp/${_sh_file##*/} 2>/dev/null
    done

else
    if [ "x$_No_Print" != "xyes" ] ; then
    printf "\n\033[1m# Add following lines in your shell profile!\033[0m\n"
    cat <<- eof
    alias _rm=$realrm
    alias rm="$delete_name -n"
    alias rF="$delete_name -F"
    alias rl='unrm -l'
    alias rla='unrm -l -u all'
    alias rd='unrm -d'
    alias rr='unrm -r'
eof
    fi
fi

if [ "x$_Init_Fold" = "xyes" ] ; then
    _mount=`df -P |awk ' $NF ~ /^\//{print $NF}'`
        for _Mount_Point in $_mount ; do
            [ "x$_Mount_Point" = "x/" ] && _Mount_Point=""
            for _Dirname in ${_Mount_Point}/.trash /etc/.trashlog /tmp /tmp/.trashlog /tmp/.trash ; do
                [ ! -d $_Dirname -a -e $_Dirname ] && $realrm -f $_Dirname 2>/dev/null
                [ ! -d $_Dirname  ] && mkdir -p  $_Dirname 2>/dev/null
                chmod 777 $_Dirname 2>/dev/null
                chmod +t  $_Dirname 2>/dev/null
                chown ${Root_Name}:${Root_Group} $_Dirname 2>/dev/null
            done
        done
else
    if [ "x$_No_Print" != "xyes" ] ; then
        printf "\n\033[1m# Execute the following command with root\033[0m\n"
        cat <<- 'eof'
    _mount=`df -P |awk ' $NF ~ /^\//{print $NF}'`
    for _Mount_Point in $_mount ; do
        for _Dirname in ${_Mount_Point}/.trash /etc/.trashlog /tmp /tmp/.trashlog /tmp/.trash ; do
            [ ! -d $_Dirname -a -e $_Dirname ] && $realrm -f $_Dirname 2>/dev/null
            [ ! -d $_Dirname  ] && mkdir -p  $_Dirname 2>/dev/null
            chmod 777 $_Dirname 2>/dev/null
            chmod +t  $_Dirname 2>/dev/null
            chown ${Root_Name}:${Root_Group} $_Dirname 2>/dev/null
        done
    done

eof
    fi
fi

# create crontab
#0 0 * * * $sh_path ${Install_Path}/cleantrash -d 30 -nr
if [ "x$_No_Print" != "xyes" ] ; then
    printf "\n\033[1m# Finally, install following crontab manually\033[0m\n"
    printf "    0 0 * * * $sh_path ${Install_Path}/cleantrash -d 30 -nr\n\n"

    printf "\033[1m# For linux, you can also copy ${Install_Path}/cleantrash to /etc/cron.daily instead\033[0m\n\n"
    printf "\033[1m# For redhat7\033[0m\n"
    cat <<- EOF
    cat > /etc/systemd/system/cleantrash.service <<- eof
    [Unit]
    Description=Clean Trash Can

    [Service]
    Type=simple
    ExecStart=${Install_Path}/cleantrash

eof

    cat > /etc/systemd/system/cleantrash.timer <<- 'eof'
    [Unit]
    Description=Runs cleantrash every week

    [Timer]
    OnCalendar=Sun, 18:00
    Unit=cleantrash.service

    [Install]
    WantedBy=multi-user.target
eof

    systemctl start cleantrash.timer
    systemctl enable cleantrash.timer
EOF
fi

# Scripts end!

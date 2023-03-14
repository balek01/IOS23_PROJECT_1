#! /bin/bash

gflag=0
aflag=0
mflag=0
bflag=0
dflag=0
aval=0000-00-00
bval=9999-99-99
gvalin=''
dir=$(pwd)
tail=1
realmole=$(realpath "$MOLE_RC")


ArgError() {
    if [ "$gflag" -gt 1 ]; then
        err=1
    fi

    if [ "$mflag" -gt 1 ]; then
        err=1
    fi

    if [ "$aflag" -gt 1 ]; then
        err=1
    fi

    if [ "$bflag" -gt 1 ]; then
        err=1
    fi

    if [ "$dflag" -gt 1 ]; then
        err=1
    fi

    #d and g use at the same time
    if [ "$dflag" -gt 0 ] && [ "$gflag" -gt 0 ]; then
        err=1
    fi

    if [ -n "$err" ]; then
        echo "ERROR:"
        exit "$err"
    fi
}

CreateMoleRC() {
    #create mole_rc
    if [[ -z $realmole ]]; then
        echo "MOLE_RC not found"
        exit 1
    fi

    if [[ ! -e $realmole ]]; then
        touch "$realmole"
    fi
}

PrintHelp() {
    echo "Usage:"
    exit 0
}

SetEditor() {
    if [ -n "$EDITOR" ]; then
        editor_path="$EDITOR"

    elif [ -n "$VISUAL" ]; then
        editor_path="$VISUAL"
    else
        editor_path=$(which vi)
    fi
}

IsFile() {
    echo "Given path $givenpath"
    if [ -d "$givenpath" ]; then
        echo "DEBUG: Directory is $givenpath"
    elif [ -f "$givenpath" ]; then
        is_file=1
        echo "DEBUG: File is $givenpath"
    else
        lastchar=${givenpath: -1}
        if [ "$lastchar" == "/" ]; then
            echo "ERROR: NonExisting Directory is $givenpath"
            exit 1
        elif [ -n "$lastchar" ]; then
            is_file=1
            echo "DEBUG: NonExisting File is $givenpath"
        fi
    fi
}

RunEditor() {
    if [ -n "$is_file" ]; then
        "$editor_path" "$givenpath"
    elif [ -n "$path" ]; then
        "$editor_path" "$path"
    else
        echo "Nothing matches given parameters"
        exit 1
    fi
}

GetTimestampDate() {
    date=$(date +'%Y-%m-%d')
    datetime=$(date +'%Y-%m-%d_%H-%M-%S')
    timestamp=$(date +%s)
}

UpdateRow() {
    GetTimestampDate
    IFS=',' read -ra rowarr <<<"$row"
    rowarr[2]="$date"
    rowarr[3]="$timestamp"
    rowarr[6]="$datetime"
    row=$(
        IFS=','
        echo "${rowarr[*]}"
    )
    echo "$row" >>"$realmole"
}

GetAwkRow() {
    AWKROWBASE="cat $realmole | awk -F ',' '\$3 > \"$aval\" && \$3 < \"$bval\" && \$2~g  && \$5~p {print \$0}' g=\"$gval\"  p=\"^$path$\""

    if [ ! "$is_list" ]; then
        if [ "$mflag" -eq 0 ]; then
            #noMflag
            AWKROWTAIL=" | sort -k4 -t ',' -n | tail -$tail| head -n 1"
        else
            AWKROWTAIL=" | sort | uniq -c | sort -rn | head -n 1 | sed -E 's/^ *[0-9]+ //g'"
        fi
    fi
    awkgetrow=$AWKROWBASE$AWKROWTAIL
    echo "$awkgetrow"

    row=$(eval "$awkgetrow")

    if [ -z "$row" ]; then
        echo "Nothing matches given parameters"
        exit 1
    fi

}

GetAwkPath() {
    awkpath="awk -F ',' '{print \$1}'<<< $row"
    path=$(eval "$awkpath")
    echo "$path"
}

SetPath() {
    if [ -z "$givenpath" ]; then
        path=$(pwd)
        path=$(realpath "$path")
        echo "DEBUG: DIR: $path"
    else

        path=$(realpath "$givenpath")

    fi
}

GetGroups() {

    IFS=',' read -ra groups <<<"$gval"
    if [ -z "$gval" ]; then
        gval="^$|"
    else
        gval=""
    fi

    for group in "${groups[@]}"; do

        gval+="^$group$|"
    done
    #always false
    gval+="/(?=a)b/"
}
GetExistingFile() {

    mole_rc_count=$(wc -l "$realmole" | awk '{print $1}')

    if [ "$tail" -eq "$mole_rc_count" ]; then
        echo "Nothing matches "
        exit 1
    fi

    if [ ! -f "$path" ]; then
        echo "File $path does not exist"
        tail=$((tail + 1))
        GetFile
    fi

}
GetFile() {
    SetPath
    GetAwkRow
    GetAwkPath
    GetExistingFile
}
Directory() {
    echo "DEBUG: In directory"
    GetGroups
    GetFile

    UpdateRow
    RunEditor
}

CheckForCommas() {

    if [[ "$gval" == *","* ]]; then
        echo "Commas are not allowed in group name."
        exit 1
    fi
}

AddRow() {
    realpath=$(realpath "$givenpath")
    file=$(basename "$realpath")
    dir=$(dirname "$realpath")
    echo "$realpath,$gvalin,$date,$timestamp,$dir,$file,$datetime" >>"$realmole"
}

File() {
    GetTimestampDate
    CheckForCommas
    AddRow
    RunEditor
}
GetList() {
    list=$(echo "$row" | cut -d ',' -f 2,6 | sort | uniq | awk -F ',' '{
  paths[$2][length(paths[$2])] = $1
} END {
  for (path in paths) {
    count = 0
    printf("%s: ;", path)
    comma = ""

    for (i = 0; i < length(paths[path]); i++) {
      if (paths[path][i] != "") {
        count++
        printf("%s%s", comma, paths[path][i])
        comma = ","
      }
    }

    if (count == 0) {
      printf("-")
    }

    print ""
  }
}' | column -t -s ";" | sed 's/ //1' | sort)
    echo "$list"
}

List() {
    SetPath
    GetGroups
    GetAwkRow
    GetList

}

GetDirectories() {
    count=0
    for directory in "${dirarray[@]}"; do
        count+=1
        real=$(realpath "$directory")
        dirregex+="^$real$|"
    done
    if [ 0 -eq "$count" ]; then
        dirregex="^.*$|"
    fi
    #always false
    dirregex+="/(?=a)b/"
    AWKROWBASE="cat $realmole | awk -F ',' '\$3 > \"$aval\" && \$3 < \"$bval\" && \$5~p {print \$1 \";\" \$7}'  p=\"$dirregex\""

    dirrows=$(eval "$AWKROWBASE")
    if [ -z "$dirrows" ]; then
    echo "ERROR: Nothing matches parameters"
    exit 1
    fi

}

CreateSecretOutput() {
   echo $dirrows
    tozip=$(echo "$dirrows" |sort| awk -F';' '{ dates[$1] = dates[$1] ";" $2 
    } END {
     for (path in dates) {
        sub(/^;/, "", dates[path]); print path ";" dates[path] 
    } 
    }'|sort)

}

Zip(){
    GetTimestampDate
    if [ ! -d "$HOME/.mole/" ]; then
        mkdir -p "$HOME/.mole";
    fi
    $(echo "$tozip" | bzip2 > "$HOME"/.mole/"log_$USER"_"$datetime".bz2)
}
Secret() {
    GetDirectories
    CreateSecretOutput
    Zip
}

Exec() {

    if [ -n "$is_secretlog" ]; then
        Secret
    elif [ -n "$is_list" ]; then

        List
    else
        IsFile
        if [ -n "$is_file" ]; then
            File
        else
            Directory
        fi
    fi
}

GetRealPath() {

    if [ -z "$givenpath" ]; then
        givenpath=$(pwd)
    fi

    givenpath=$(realpath "$givenpath")
    if [ -z "$givenpath" ]; then
        echo "ERROR: $givenpath is not valid path."
        exit 1
    fi
}
if [ "$1" = "list" ]; then
    is_list=1
    shift

fi

if [ "$1" = "secret-log" ]; then
    is_secretlog=1
    shift

fi
while getopts dhg:mb:a: name; do
    case $name in
    h) PrintHelp ;;
    g)
        gflag+=1
        gvalin="$OPTARG"
        gval="$OPTARG"
        ;;
    m)
        mflag+=1
        ;;
    a)
        aflag+=1
        aval="$OPTARG"
        ;;
    b)
        bflag+=1
        bval="$OPTARG"
        ;;
    d)
        dflag+=1
        gval='.*'
        ;;
    ?)
        printf "Usage: %s: [-a] [-b value] args\n" "$0"
        exit 2
        ;;
    esac
done
shift "$((OPTIND - 1))"

if [ -n "$is_secretlog" ]; then
    while [ $# -gt 0 ]; do
        dirarray+=("$1")
        shift
    done
fi
CreateMoleRC
givenpath=$1

GetRealPath

ArgError
SetEditor
echo "DEBUG: Using: $editor_path"
Exec

exit 0

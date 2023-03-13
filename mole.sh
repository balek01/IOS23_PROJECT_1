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
    if [[ -z $MOLE_RC ]]; then
        echo "MOLE_RC not found"
        exit 1
    fi

    if [[ ! -e $MOLE_RC ]]; then
        touch "$MOLE_RC"
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
    timestamp=$(date +%s)
}

UpdateRow() {
    GetTimestampDate
    IFS=',' read -ra rowarr <<<"$row"
    rowarr[2]="$date"
    rowarr[3]="$timestamp"
    row=$(
        IFS=','
        echo "${rowarr[*]}"
    )
    echo "$row" >>"$MOLE_RC"
}

GetAwkRow() {
    AWKROWBASE="cat $MOLE_RC | awk -F ',' '\$3 > \"$aval\" && \$3 < \"$bval\" && \$2~g  && \$5~p {print \$0}' g=\"$gval\"  p=\"^$path$\""

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

    # Loop over the array and print each element
    for group in "${groups[@]}"; do

        gval+="^$group$|"
    done
    #always false
    gval+="/(?=a)b/"
}
GetExistingFile() {

    mole_rc_count=$(wc -l "$MOLE_RC" | awk '{print $1}')

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
    echo "$givenpath,$gvalin,$date,$timestamp,$dir,$file" >>"$MOLE_RC"
}

File() {
    GetTimestampDate
    CheckForCommas
    AddRow
    RunEditor
}
GetUnsortedList() {
    unsorted=$(echo "$row" | cut -d ',' -f 2,6 | sort | uniq | awk -F ',' '{
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
    echo "$unsorted"
}

List() {
    SetPath
    GetGroups
    GetAwkRow
    GetUnsortedList

}
Exec() {
    if [ -n "$is_list" ]; then

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

if [ "$1" = "list" ]; then
    is_list=1
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

CreateMoleRC

shift "$((OPTIND - 1))"

if [ -n "$1" ]; then
    givenpath=$(readlink -f "$1")

fi

ArgError
SetEditor
echo "DEBUG: Using: $editor_path"
Exec

exit 0

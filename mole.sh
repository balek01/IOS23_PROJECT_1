#! /bin/bash

gflag=0
aflag=0
mflag=0
bflag=0
aval=0000-00-00
bval=9999-99-99
gval='.'
dir=$(pwd)

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

    if [ -n "$err" ]; then
        echo "ERROR:"
        exit "$err"
    fi
}

CreateMoleRC() {
    #create mole_rc
    if [[ ! -e $MOLE_RC ]]; then
        touch $MOLE_RC
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
    if [ -d "$path" ]; then
        echo "DEBUG: Directory is $path"
    elif [ -f "$path" ]; then
        is_file=1
        echo "DEBUG: File is $path"
    else
        lastchar=${path: -1}
        if [ "$lastchar" == "/" ]; then
            echo "DEBUG: NonExisting Directory is $path"
            exit 1
        elif [ -n "$lastchar" ]; then
            is_file=1
            echo "DEBUG: NonExisting File is $path"
        fi
    fi
}

Filters() {
    if [ -n "$gflag" ]; then
        #ProcessGroups
        echo
    fi

}
File() {
    date=$(date +'%Y-%m-%d')
    timestamp=$(date +%s)
    dir=$(dirname "$path")
    echo "$path,$gval,$date,$timestamp,$dir" >>$MOLE_RC
    "$editor_path" "$path"
}

Directory() {
    
    awkin="cat $MOLE_RC | awk -F ',' '\$3 > \"$aval\" && \$3 < \"$bval\" && \$2 ~ /$gval/ {print \$0}' | sort -k4 -t ',' -n | tail -1"
    idk=$(eval $awkin)
    echo $idk
    Filters
}
Exec() {
    IsFile
    if [ -n "$is_file" ]; then
        File
    else
        Directory
    fi
}

while getopts hg:mb:a: name; do
    case $name in
    h) PrintHelp ;;
    g)
        gflag+=1
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
    ?)
        printf "Usage: %s: [-a] [-b value] args\n" $0
        exit 2
        ;;
    esac
done

CreateMoleRC
shift "$((OPTIND - 1))"
path=$(readlink -f $1)
ArgError
SetEditor
echo "DEBUG: Using: $editor_path"
Exec

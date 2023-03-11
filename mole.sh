#! /bin/bash

gflag=0
aflag=0
mflag=0
bflag=0
aval=0000-00-00
bval=9999-99-99
gval='^$'
gvalin=''
dir=$(pwd)
path=$(pwd)


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
    if [ "$dflag" -gt 0 ]  && [ "$gflag" -gt 0 ]; then
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

RunEditor() {
    if [ -n "$path" ]; then
        "$editor_path" "$path"
    else
        echo "Nothing matches parameters"
        exit 1
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
    echo "$path,$gvalin,$date,$timestamp,$dir/" >>$MOLE_RC
    "$editor_path" "$path"
}
NoMArg() {
    awkpath="cat $MOLE_RC | awk -F ',' '\$3 > \"$aval\" && \$3 < \"$bval\" && \$2~g  && \$5~p {print \$1}' g="$gval"  p="$path" | sort -k4 -t ',' -n | tail -1"
    awkrow="cat $MOLE_RC | awk -F ',' '\$3 > \"$aval\" && \$3 < \"$bval\" && \$2~g  && \$5~p {print \$0}' g="$gval"  p="$path" | sort -k4 -t ',' -n | tail -1"
    path=$(eval $awkpath)
    row=$(eval $awkrow)
    echo $row >>$MOLE_RC
}

MArg() {
    awkpath="cat $MOLE_RC | awk -F ',' '\$3 > \"$aval\" && \$3 < \"$bval\" && \$2~g  && \$5~p {print \$1}' g="$gval"  p="$path" | sort | uniq -c | sort -rn | head -n 1 | sed -E 's/^ *[0-9]+ //g'"
    awkrow="cat $MOLE_RC | awk -F ',' '\$3 > \"$aval\" && \$3 < \"$bval\" && \$2~g  && \$5~p {print \$0}' g="$gval"  p="$path" | sort | uniq -c | sort -rn | head -n 1 | sed -E 's/^ *[0-9]+ //g'"
    echo $awkpath
    path=$(eval $awkpath)
    row=$(eval $awkrow)
    echo $row >>$MOLE_RC
    echo "$path"
}

Set_Dir() {
    if [ -n "$path" ]; then
        dir=$path
        echo "DEBUG: DIR: $dir"
    fi
}

Directory() {
    echo "DEBUG: In directory"

    Set_Dir

    dir=$path

    if [ "$mflag" -eq 0 ]; then
        NoMArg
    else
        MArg
    fi
    RunEditor

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
        gval='.'
;;
    ?)
        printf "Usage: %s: [-a] [-b value] args\n" $0
        exit 2
        ;;
    esac
done

CreateMoleRC
shift "$((OPTIND - 1))"

#if [ -n "$1" ]; then
# path=$(readlink -f "$1")
path=$1
echo "path je $path"
#fi

ArgError
SetEditor
echo "DEBUG: Using: $editor_path"
Exec

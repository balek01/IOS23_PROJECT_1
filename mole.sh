#! /bin/bash

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

PrintHelp() {
    echo "Usage:"
    exit 0
}

SetEditor() {
    if [ -n "$EDITOR" ]; then
        edit_path="$EDITOR"

    elif [ -n "$VISUAL" ]; then
        edit_path="$VISUAL"
    else

        edit_path=$(which vi)
    fi
}

IsDirectory() {
    if [ -d "$path" ]; then
        is_dir=1
        echo "DEBUG: Directory is $path"
    elif [ -f "$path" ]; then
        is_file=1
        echo "DEBUG: File is $path"
    else
        echo "DEBUG: File or Directory $path does not exist."
        exit 1
    fi
}

File(){
    
}
Exec() {
    IsDirectory

    if [ -n "$is_file" ]; then
        File
    fi
}

gflag=0
aflag=0
mflag=0
bflag=0

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
        ;;
    b)
        bflag+=1
        ;;
    ?)
        printf "Usage: %s: [-a] [-b value] args\n" $0
        exit 2
        ;;
    esac
done

shift "$((OPTIND - 1))"
path=$1
ArgError
SetEditor
echo "DEBUG: Using: $edit_path"
Exec
#create mole_rc
if [[ ! -e $MOLE_RC ]]; then
    touch $MOLE_RC
fi

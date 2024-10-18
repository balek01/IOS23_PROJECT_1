# IOS23_PROJECT_1

evaulation 12/15

---

# Makes One’s Life Easier

`mole` is a command-line utility designed to simplify file management by allowing you to open, group, and filter files quickly and efficiently. 

## Synopsis

```bash
mole -h
mole [-g GROUP] FILE
mole [-m] [FILTERS] [DIRECTORY]
mole list [FILTERS] [DIRECTORY]
```

## Options

### `mole -h`
- Displays help information.

### `mole [-g GROUP] FILE`
- Opens the specified `FILE`.
- `-g GROUP` (optional): Assigns the file to a group named `GROUP`.

### `mole [-m] [FILTERS] [DIRECTORY]`
- Selects a file from `DIRECTORY` to open.
- `-m`: Selects the file that was opened most frequently.
- If no directory is specified, the current directory is assumed.

### `mole list [FILTERS] [DIRECTORY]`
- Displays a list of files that were opened.
- If no directory is specified, the current directory is assumed.

## Filters

The following filters can be applied when using `mole`:

- `-g GROUP1[,GROUP2[,...]]`: Specifies groups. Only files within these groups will be considered.
- `-d`: Shows records of files that have no group assigned. 
  - Note: `-d` and `-g` cannot be used together.
- `-a DATE`: Files opened (edited) before this date will not be considered. The date should be in the format `YYYY-MM-DD`.
- `-b DATE`: Files opened (edited) after this date will not be considered. The date should be in the format `YYYY-MM-DD`.

---

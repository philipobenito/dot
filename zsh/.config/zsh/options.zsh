setopt AUTO_CD           # Auto changes to a directory without typing cd
setopt AUTO_PUSHD        # Push the old directory onto the stack on cd
setopt PUSHD_IGNORE_DUPS # Do not store duplicates in the stack
setopt PUSHD_SILENT      # Do not print the directory stack after pushd or popd

setopt EXTENDED_GLOB     # Extended globbing. Allows using regular expressions with *
setopt NOMATCH           # If a pattern for filename generation has no matches, print an error

setopt LONG_LIST_JOBS    # List jobs in the long format by default
setopt AUTO_RESUME       # Attempt to resume existing job before creating a new process
setopt NOTIFY            # Report status of background jobs immediately

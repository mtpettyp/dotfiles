histgrep ()
{
    grep -r "$@" ~/.history
    history | grep "$@"
}

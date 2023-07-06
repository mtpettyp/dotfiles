function bcrypt() {
    htpasswd -nbBC 10 "" "$@" | tr -d ':\n'
}

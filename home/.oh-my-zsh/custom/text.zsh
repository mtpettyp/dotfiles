function lower() {
    tr '[:upper:]' '[:lower:]'
}

function docx2txt() {
    textutil -convert txt "$@"
}

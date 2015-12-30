function smime-decrypt() {
  openssl smime -decrypt  -inkey ~/.ssh/id_rsa
}

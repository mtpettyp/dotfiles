function read-qr() {
  screencapture -i $TMPDIR/screencapture.bmp && zbarimg -q --raw $TMPDIR/screencapture.bmp
}

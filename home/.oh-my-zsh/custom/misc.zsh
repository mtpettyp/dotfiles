function whatismyip() {
  #curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'  
  #curl ifconfig.me
  curl ifconfig.co
}

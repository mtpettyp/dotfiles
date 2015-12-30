
function startvm() {
   VBoxManage startvm "$1" --type headless
}

function stopvm() {
   VBoxManage controlvm "$1" poweroff
}

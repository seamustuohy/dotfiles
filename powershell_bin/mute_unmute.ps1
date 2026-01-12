# Simple script that mutes/un-mutes
$new_shell = new-object -com wscript.shell
$new_shell.SendKeys([char]173)

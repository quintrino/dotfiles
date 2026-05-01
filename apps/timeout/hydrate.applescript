set focusStatus to do shell script "$HOME/.local/share/bin/focusmode_task"

set myHour to hours of (current date)
set myMinutes to minutes of (current date)
set mySpeak to myHour & " " & myMinutes
say "The time is now " & mySpeak
delay 8
say "Hydrate and get back too" & focusStatus

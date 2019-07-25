-- Hide Slack on unfocus

local wf = hs.window.filter
local wf_slack = wf.new{'Slack'}

function hide_slack()
    hs.appfinder.appFromName("Slack"):hide()
 end

wf_slack:subscribe(wf.windowUnfocused, hide_slack)

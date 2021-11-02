local CATEGORY_NAME = "Voting"  -- Taken from ulx module sh\vote.lua
                                -- Basically the category for ulx commands

function ulx.rtv( ply )
    local check = RTV:AddVote( ply )
    ULib.tsay(nil, string.format("%s voted for a gamemode / map change. Current: %d / %d", ply:Nick(), RTV:TotalVotes(), RTV:RequiredVotes()))
    if (!check) then
        ULib.tsayError(ply, "You already voted to change the gamemode / map")
    end
    RTV:Start()
end

local rtvcmd = ulx.command( CATEGORY_NAME, "ulx rtv", ulx.rtv, "rtv" )
rtvcmd:defaultAccess( ULib.ACCESS_ALL )
rtvcmd:help( "Rock The Vote" )

function ulx.rtv_force( ply, choice )
    choice = string.lower(choice)
    if (choice == "start") then
        RTV:Start(true)
        PrintMessage(3, "Forcing RTV to start")
    elseif (choice == "stop") then
        RTV:End()
        PrintMessage(3, "Stopping RTV")
    else
        ULib.tsayError(ply, "Choice has to be 'start' or 'stop', EX: !frtv start")
    end
end

local rtvforcecmd = ulx.command( CATEGORY_NAME, "ulx frtv", ulx.rtv_force, "!frtv" )
rtvforcecmd:defaultAccess( ULib.ACCESS_SUPERADMIN )
rtvforcecmd:addParam{ type = ULib.cmds.StringArg, hint = "'stop' or 'start'"}
rtvforcecmd:help( "Forces RTV without requiring a vote" )

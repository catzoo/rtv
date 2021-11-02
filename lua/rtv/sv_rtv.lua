local requiredPercentage = CreateConVar("rtv_percentage", 0.66, FCVAR_NOTIFY, "How many percentage of votes is required to start RTV. EX: 0.50 is 50% of total players.", 0, 1.0)
local time = CreateConVar("rtv_time", 30, FCVAR_NOTIFY, "How many seconds the vote will take", 0)

-- Config Values

local DefaultConfig = {
    {
        name = "Sandbox",
        gamemode = "sandbox",
        maps = {},
        prefix = {"gm_"}
    }
}

local config_file = "config.json"
local config_directory = "rtv"

RTV = {}

RTV.gamemodes = {
    -- gamemode_name = {
    --     gamemode = gamemode,
    --     maps = {}
    -- }
}

RTV.votes = {
    -- ply = true / false

    -- if player recently disconnect, don't want to count their vote when they reconnect (false)
    -- Doing it this way because i don't fully understand lua's tables on setting it to nil
    -- Basically, #votes will end on a nil value. So, not sure if its accurate if the top
    -- player in the vote table is nil
}
RTV.voteInProgress = false

RTV.gamemode = nil

function RTV:LoadConfig()
    self.gamemodes = {}
    local config_location = string.format("%s/%s", config_directory, config_file)
    local mapList, _ = file.Find("maps/*.bsp", "GAME")

    -- Making sure the directory / file exists
    if not file.Exists( config_directory, "DATA") then
        file.CreateDir( config_directory )
    end

    if not file.Exists( config_location, "DATA" ) then
        file.Write( config_location, util.TableToJSON(DefaultConfig, true) )
    end

    -- Grabbing the config
    local config = util.JSONToTable( file.Read( config_location, "DATA" ))

    -- Setting up RTV.gamemodes
    for _, v in ipairs(config) do
        local gamemode = v["gamemode"]
        local maps = v["maps"] or {}
        local prefix = v["prefix"] or {}

        for _, pre in ipairs(prefix) do
            for _, map in ipairs(mapList) do
                -- Checking if the map has the prefix and its not already added
                if string.StartWith(map, pre) and not table.HasValue(maps, map) then
                    -- Remove .bsp and add it
                    map = string.Replace(map, ".bsp", "")
                    table.insert(maps, map)
                end
            end
        end

        self.gamemodes[v["name"]] = {
            gamemode = gamemode,
            maps = maps
        }
    end
end

function RTV:TotalVotes()
    local count = 0
    for ply, v in pairs(self.votes) do
        -- Making sure the player didn't disconnect
        if IsValid(ply) and v then
            count = count + 1
        else
            -- Player disconnected, set it to false just incase they reconnect
            RTV.votes[ply] = false
        end
    end
    return count
end

function RTV:RequiredVotes()
    return math.Round(#player.GetAll() * requiredPercentage:GetFloat())
end

function RTV:CheckVotes()
    return self:TotalVotes() >= self:RequiredVotes() and self.voteInProgress == false
end

function RTV:AddVote(ply)
    if RTV.votes[ply] == true then
        return false
    else
        RTV.votes[ply] = true
        return true
    end
end

function RTV:Start(forced)
    local check = forced or self:CheckVotes()
    if not check then
        return
    end

    self.voteInProgress = true

    local choices = {}
    for gm, _ in pairs(self.gamemodes) do
        table.insert(choices, gm)
    end

    MapVote:Start(choices, time:GetInt(), function(choice)
        local gm = self.gamemodes[choice]
        -- TODO: Use pcall for RunConsoleCommand. If error, remove choice and try again (if no choices left, stop the vote)
        RunConsoleCommand("gamemode", gm["gamemode"])
        local maps = gm["maps"]

        MapVote:Start(maps, time:GetInt(), function(choice)
            RunConsoleCommand("changelevel", choice)
            self.voteInProgress = false
        end)
    end)
end

function RTV:End()
    self.voteInProgress = false
    self.votes = {}
    MapVote:End()
end

RTV:LoadConfig()

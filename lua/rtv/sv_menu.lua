util.AddNetworkString("rtv_startvote")
util.AddNetworkString("rtv_updatevote")
util.AddNetworkString("rtv_endvote")
util.AddNetworkString("rtv_vote")

--[[

------- To Client -------

rtv_startvote
	Float	 - endTime
	UInt(16) - amount of choices
	---------- (for each choice)
	UInt(16) - ChoiceID
	String	 - Choice Value

rtv_updatevote
	UInt(16) - ChoiceID
	Entity	 - Player

rtv_endvote
    Bool     - Flash
    --------- (if flash == true)
    UInt(16) - ChoiceID


------- To Server -------

rtv_vote
	UInt(16) - ChoiceID
]]

local TIMER_NAME = "rtv_endVote"

MapVote.choices = {
    -- id: value
}
MapVote.votes = {
    -- ply: ChoiceID
}
MapVote.callback = nil

net.Receive("rtv_vote", function(len, ply)
    choiceID = net.ReadUInt(16)
    MapVote:Vote(ply, choiceID)
end)

function MapVote:Start(choices, time, callback)
    if #choices == 1 then
        -- Only one choice, don't need to start voting
        if callback ~= nil then
            callback(choices[1])
        end
        return
    end

    if timer.Exists(TIMER_NAME) then
        timer.Remove(TIMER_NAME)
    end

    self.callback = callback
    self.choices = choices
    self.votes = {}

    -- Telling clients a new vote has started
    net.Start("rtv_startvote")
    net.WriteFloat(CurTime() + time)
    net.WriteUInt(#choices, 16)

    for k, v in pairs(choices) do
        net.WriteUInt(k, 16)
        net.WriteString(v)
    end

    net.Broadcast()

    -- Creating the timer to end the vote
    timer.Create(TIMER_NAME, time + 1, 0, function()
        local choiceID = self:GetWinningChoiceID()
        self:End(choiceID)
    end)
end

function MapVote:End(choiceID)
    if timer.Exists(TIMER_NAME) then
        timer.Remove(TIMER_NAME)
    end

    net.Start('rtv_endvote')

    if choiceID ~= nil then
        net.WriteBool(true)
        net.WriteUInt(choiceID, 16)

        -- Setting up the timer for callback
        -- Clients will "flash" the winning vote. Just need
        -- to make sure its done before calling callback
        if self.callback ~= nil then
            timer.Simple(2, function()
                local choice = self.choices[choiceID]
                self.callback(choice)
            end)
        end
    else
        -- No choiceID meaning it was forced to end
        net.WriteBool(false)
    end

    net.Broadcast()
end

function MapVote:GetWinningChoiceID()
    local count = {
        -- choiceID = numOfVotes
    }
    local choices = {}  -- Choices that equal the highest vote
    local highest = 0   -- Highest vote count

    for ply, choice in pairs(self.votes) do
        if IsValid(ply) then
            -- Increasing the count
            if count[choice] == nil then
                count[choice] = 1
            else
                count[choice] = count[choice] + 1
            end
            -- Checking if the choice is higher
            if count[choice] == highest then
                -- Count is equal, insert it into choices
                table.insert(choices, choice)
            elseif count[choice] > highest then
                -- Count is higher, reset choices and highest
                choices = {choice}
                highest = count[choice]
            end
        end
    end
    if #choices == 0 then
        return math.random(1, #self.choices)
    end
    return choices[math.random(1, #choices)]
end

function MapVote:Vote(ply, choiceID)
    -- Checking to make sure the vote is valid
    if not IsValid(ply) or MapVote.choices[choiceID] == nil then
        return
    end

    -- Setting the vote
    self.votes[ply] = choiceID
    -- Updating everyone on the new vote
    net.Start("rtv_updatevote")
    net.WriteUInt(choiceID, 16)
    net.WriteEntity(ply)
    net.Broadcast()
end

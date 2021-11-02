surface.CreateFont("RAM_VoteFont", {
    font = "Trebuchet MS",
    size = 19,
    weight = 700,
    antialias = true,
    shadow = true
})

surface.CreateFont("RAM_VoteFontCountdown", {
    font = "Tahoma",
    size = 32,
    weight = 700,
    antialias = true,
    shadow = true
})

local TIMER_NAME = "rtv_failsafe"

MapVote.panel = nil

net.Receive("rtv_startvote", function()
	--[[
		Float	 - endTime
		UInt(16) - amount of choices
		---------- (for each choice)
		UInt(16) - ChoiceID
		String	 - Choice Value
	]]
	if MapVote.panel then
		MapVote.panel:Remove()
	end

	if timer.Exists(TIMER_NAME) then
		timer.Remove(TIMER_NAME)
	end

	local endTime = net.ReadFloat()
	local amt = net.ReadUInt(16)
	local choices = {}

	for i=1, amt do
		local choiceID = net.ReadUInt(16)
		local value = net.ReadString()
		choices[choiceID] = value
	end

	MapVote.panel = vgui.Create("RTV_MainPanel")
	MapVote.panel.endTime = endTime
	MapVote.panel:SetChoices(choices)
end)

net.Receive("rtv_updatevote", function()
	--[[
		UInt(16) - ChoiceID
		Entity	 - Player
	]]
	if MapVote.panel then
		local choiceID = net.ReadUInt(16)
		local ply = net.ReadEntity()
		if IsValid(ply) then
			MapVote.panel:SetVote(ply, choiceID)
		end
	end
end)

net.Receive("rtv_endvote", function()
	--[[
		Bool     - Flash
		--------- (if flash == true)
		UInt(16) - ChoiceID
	]]
	if MapVote.panel then
		local flash = net.ReadBool()

		if flash then
			-- Grab the choiceID and flash
			local choiceID = net.ReadUInt(16)
			MapVote.panel:Flash(choiceID)
			-- Remove the panel after 10 seconds, just incase something happened
			-- on the server side
			timer.Create(TIMER_NAME, 10.0, 0, function()
				if MapVote.panel and MapVote.panel.flashed then
					MapVote.panel:Remove()
					MapVote.panel = nil
				end
			end)
		else
			-- Its forced, just remove the panel
			MapVote.panel:Remove()
			MapVote.panel = nil
		end
	end
end)


local PANEL = {}

function PANEL:Init()
	self.voters = {
		-- Player: AvatarImage()
	}

	-- Not used, idea was to make PANEL:Think faster
	-- by only updating the panel when needed
	-- TODO: Might need to remove self.update if its unused
	self.update = false
	-- If the Panel is minimized or not
	self.minimize = false
	-- Server time of when the vote ends
	self.endTime = nil
	-- Helps keep track when ALT was pressed
	self.keyDown = false
	-- If the panel flashed the winning choice
	self.flashed = false

	self:ParentToHUD()
	self:MakePopup()
	self:SetKeyboardInputEnabled(false)
	-- self:SetVisible(false) -

	self.canvas = vgui.Create("DFrame", self)
	self.canvas:SetDeleteOnClose(false)
	self.canvas:SetDraggable(false)
	self.canvas:SetTitle("")

	self.canvas.Close = function()
		self:SetMinimize()
	end

	function self.canvas:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
	end

	self.scroll = vgui.Create("DScrollPanel", self.canvas)

	self.choices = vgui.Create("DGrid", self.scroll)
	self.choices:SetCols(2)

	-- Taken this from cl_mapvote.lua
	local extra = math.Clamp(300, 0, ScrW() - 640)

	self.choices:SetColWide(285 + (extra / 2))
	self.choices:SetRowHeight(25)

	self.timer = vgui.Create("DLabel", self.canvas)
	self.timer:SetFont("RAM_VoteFontCountdown")
	self.timer:SetText("")

	self.helpText = vgui.Create("DLabel", self.canvas)
	self.helpText:SetFont("RAM_VoteFont")
	self.helpText:SetText("Press ALT to return to the vote")
	self.helpText:SetTextColor(Color(16, 160, 255))
	self.helpText:SetVisible(false)
end

function PANEL:PerformLayout(width, height)
	self:SetPos(0, 0)

	self.canvas:SetPos(0, 0)
	self.canvas:CenterHorizontal()

	self.scroll:SetPos(0, 60)
	self.scroll:CenterHorizontal()

	self.timer:CenterHorizontal()

	local _, height = self.timer:GetTextSize()
	self.helpText:SetPos(0, height)
	self.helpText:CenterHorizontal()
end

function PANEL:Resize()
	-- Call PerformLayout to get self.scroll.y
	self:InvalidateLayout(true)

	local items = #self.choices:GetItems()
	local height = items * self.choices:GetRowHeight()
	local width = self.choices:GetColWide() * self.choices:GetCols() + 25
	local max_height = ScrH() - self.scroll.y

	if height > max_height then
		height = max_height
	end

	if self.minimize then
		self:SetSize( ScrW(), self.scroll.y )
		self.canvas:SetSize(width, self.scroll.y)
		self.canvas:ShowCloseButton(false)
		self:SetMouseInputEnabled(false)
		self.helpText:SetVisible(true)
	else
		self:SetSize( ScrW(), ScrH() )
		self.canvas:SetSize( width, ScrH() )
		self.canvas:ShowCloseButton(true)
		self:SetMouseInputEnabled(true)
		self.helpText:SetVisible(false)
	end
	self.scroll:SetSize(width, height)

	width, height = self.timer:GetTextSize()
	self.timer:SetSize(width, height)

	width, height = self.helpText:GetTextSize()
	self.helpText:SetSize(width, height)
	-- self.choices automatically resize. Just need to have the canvas resize with it
end

function PANEL:SetMinimize(value)
	if value == nil then
		if self.minimize then
			value = false
		else
			value = true
		end
	end
	self.minimize = value
	self:Resize()
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(0, 0, w, h)
end

function PANEL:SendVote(choiceID)
	net.Start("rtv_vote")
	net.WriteUInt(choiceID, 16)
	net.SendToServer()
end

function PANEL:SetChoices(choices)
	local width = self.choices:GetColWide() - 5
	local height = self.choices:GetRowHeight() - 3

	for k, v in RandomPairs(choices) do
		local button = vgui.Create("DButton")

		button.choiceID = k
		button.totalVotes = 0
		button.iconHovered = {}

		button:SetText(v)
		button:SetSize(width, height)
		button:SetFont("RAM_VoteFont")

		button:SetPaintBackground(false)
		button:SetTextColor(color_white)

		button:SetContentAlignment(4)
		button:SetTextInset(4, 0)

		local paint = button.Paint

		button.Paint = function(s, w, h)
			local color = Color(255, 255, 255, 10)

			if button.bgColor then
				color = button.bgColor
			end

			draw.RoundedBox(0, 0, 0, w, h, color)
			paint(s, w, h)
		end

		button.DoClick = function()
			self:SendVote(button.choiceID)
		end

		function button:Think()
			if (self:IsHovered() or not table.IsEmpty(self.iconHovered)) and self.bgColor == nil then
				self:SetTextColor( Color(16, 160, 255) )
			else
				self:SetTextColor(color_white)
			end
		end

		self.choices:AddItem(button)
	end
	self:Resize()
	self.update = true
end

function PANEL:GetChoice(choiceID)
	local choice = nil
	for k, v in pairs(self.choices:GetItems()) do
		if v.choiceID == choiceID then
			choice = v
			break
		end
	end
	return choice
end

function PANEL:AddVoter(ply)
	if self.voters[ply] then
		return
	end

	local icon = vgui.Create("AvatarImage", self.choices)
	icon.choice = -1
	icon:SetPlayer(ply)
	icon:SetSize(16, 16)
	icon:SetPos(-16, 0)
	icon:SetCursor("hand")

	icon.OnMouseReleased = function(keycode)
		self:SendVote(icon.choice)
	end

	icon.Think = function()
		local choice = self:GetChoice(icon.choice)
		if choice ~= nil then
			if icon:IsHovered() then
				choice.iconHovered[ply] = 1
			else
				choice.iconHovered[ply] = nil
			end
		end
	end

	self.voters[ply] = icon
end

function PANEL:SetVote(ply, choiceID)
	self:AddVoter(ply)
	local voter = self.voters[ply]

	if voter.choice ~= -1 then
		local oldChoice = self:GetChoice(voter.choice)
		oldChoice.totalVotes = oldChoice.totalVotes - 1
	end

	if choiceID ~= -1 then
		local choice = self:GetChoice(choiceID)
		choice.totalVotes = choice.totalVotes + 1
	end

	voter.choice = choiceID
	self.update = true
end

function PANEL:RemoveVoter(ply)
	local voter = self.voters[ply]
	if voter then
		self:SetVote(ply, -1)

		voter:Remove()
		self.voters[ply] = nil
	end
end

function PANEL:SetIconPadding()
	local iconWidth = 21
	for _, choice in pairs(self.choices:GetItems()) do
		local available = choice:GetWide() - (choice:GetTextSize() + iconWidth)
		local taken = iconWidth * choice.totalVotes

		if taken > available then
			choice.padding = available / choice.totalVotes
		else
			choice.padding = iconWidth
		end

		choice.votes = 0
	end
end

function PANEL:Think()
	-- Checking if the user pressed ALT
	if input.IsKeyDown(KEY_LALT) then
		if self.keyDown == false then
			self:SetMinimize()
		end
		self.keyDown = true
	else
		self.keyDown = false
	end

	if self.update then
		self.update = true
		self:SetIconPadding()

		for ply, icon in pairs(self.voters) do
			if not IsValid(ply) then
				-- Player isn't valid, remove the vote
				self.update = true
				self:RemoveVoter(ply)

			elseif icon.choice ~= -1 then
				local choice = self:GetChoice(icon.choice)

				choice.votes = choice.votes + 1
				icon:SetZPos(choice:GetZPos() + choice.votes)

				-- Getting the position
				local x, y = choice:GetPos()
				x = (x + choice:GetWide()) - choice.votes * choice.padding
				y = y + (choice:GetTall() / 2) - (icon:GetTall() / 2)

				if choice.padding < icon:GetWide() then
					x = x - (icon:GetWide() - choice.padding)
				end

				local curPos = Vector(x, y)

				-- Moving the icon if needed
				if not icon.curPos or icon.curPos ~= curPos then
					icon:MoveTo(curPos.x, curPos.y, 0.3)
					icon.curPos = curPos
				end
			end
		end
	end

	-- Grabbing the time
	if self.endTime ~= nil then
		local time = self.endTime - CurTime()
		local text = self.timer:GetText()

		time = math.ceil(time)

		if time < 0 then
			time = 0
		end

		time = string.format("%02d", time)
		self.timer:SetText(time)

		if string.len(text) ~= string.len(time) then
			-- Resizing if the text changed size. Basically, make sure its centered
			self:Resize()
		end
	end
end

function PANEL:Flash(choiceID)
	self.flashed = true

	local choice = self:GetChoice(choiceID)

	self:SetMinimize(false)
	self.scroll:ScrollToChild(choice)

	local function colorOn()
		-- Making sure the panel is valid. Had a small bug when the panel is removed
		-- and flashing timers are still active
		if IsValid(choice) then
			choice.bgColor = Color(16, 160, 255)
			surface.PlaySound("hl1/fvox/blip.wav")
		end
	end

	local function colorOff()
		if IsValid(choice) then
			choice.bgColor = nil
		end
	end

	local i = 0
	while i < 1.0 do
		timer.Simple(i, colorOn)
		timer.Simple(i + 0.2, colorOff)
		i = i + 0.4
	end
end

vgui.Register("RTV_MainPanel", PANEL, "DPanel")

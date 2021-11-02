MapVote = {}

if SERVER then
    AddCSLuaFile("rtv/cl_menu.lua")
    include("rtv/sv_rtv.lua")
    include("rtv/sv_menu.lua")
else
    include("rtv/cl_menu.lua")
end

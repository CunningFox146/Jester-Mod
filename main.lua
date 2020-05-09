local MOBS_LIST = GetModConfigData("mobs") or {moose = true}
local GLOMMER_DAYS = GetModConfigData("glommer") or 100

local menv = env
GLOBAL.setfenv(1, GLOBAL)

if not menv.MODROOT:find("workshop-") then
	CHEATS_ENABLED = true
end

local function IsAdmin(id)
	local data = TheNet:GetClientTableForUser(id)
	return data and data.admin 
end

local function SetDirty(netvar, val)
	netvar:set_local(val)
	netvar:set(val)
end

menv.AddPrefabPostInit("player_classified", function(inst)
	inst.jester_tint = net_entity(inst.GUID, "jester.tint", "jester_tint_dirty")
	inst.jester_data = net_string(inst.GUID, "jester.data", "jester_data_dirty")
	
	if not TheNet:IsDedicated() then
		inst:ListenForEvent("jester_tint_dirty", function(inst)
			local ent = inst.jester_tint:value()
			if ent and ent.AnimState then
				if ent.c_task then
					ent.c_task:Cancel()
					ent.c_task = nil
				end
			
				if not ent._c then
					ent._c = {ent.AnimState:GetMultColour()}
				end
				
				ent.AnimState:SetMultColour(1, 0, 1, 1)
				ent.c_task = ent:DoTaskInTime(1, function(ent) ent.AnimState:SetMultColour(unpack(ent._c)) end)
			end
		end)
	end
end)

menv.AddModRPCHandler("JESTER", "BUTTON", function(inst, ent)
	if not inst or not ent or not IsAdmin(inst.userid) then
		return
	end
	
	local ic = ent.components
	if ic and ic.jester_protector then
		ic.jester_protector:ChangeProtecion()
		
		if inst.player_classified then
			SetDirty(inst.player_classified.jester_tint, ent)
		end
	end
end)

menv.AddModRPCHandler("JESTER", "GET_DATA", function(inst, item)
	if not inst or not item or not IsAdmin(inst.userid) then
		return
	end
	
	local ic = item.components
	if ic and inst.player_classified then
		if not ic.jester_protector then
			inst.player_classified.jester_data:set("")
			return
		end
		
		inst.player_classified.jester_data:set(ic.jester_protector.isprotected and "Защищено" or "Не защищено")
	end
end)

if not TheNet:IsDedicated() then 
	menv.AddPlayerPostInit(function(inst)
		inst:DoTaskInTime(0, function()
			if not inst == ThePlayer then
				return 
			end
			
			if ThePlayer then
				ThePlayer.lock = true
			end
		end)
	end)
	
	local function IsDefaultScreen()
		return ThePlayer and ThePlayer.HUD and not ThePlayer.HUD:HasInputFocus()
	end
	
	TheInput:AddKeyUpHandler(KEY_P, function()
		if not IsDefaultScreen() or (ThePlayer and ThePlayer.lock) then return end
		SendModRPCToServer(MOD_RPC.JESTER.BUTTON, TheInput:GetWorldEntityUnderMouse())
	end)
	
	TheInput:AddKeyUpHandler(KEY_END, function()
		if not IsDefaultScreen() or not ThePlayer or not IsAdmin(ThePlayer.userid) then return end
		ThePlayer.lock = not ThePlayer.lock
		if ThePlayer.components.talker then
			ThePlayer.components.talker:Say(not ThePlayer.lock and "Включено" or "Выключено")
		end
	end)
	
	menv.AddClassPostConstruct("widgets/hoverer", function(hoverer)
		local _SetString = hoverer.text.SetString
		hoverer.text.SetString = function(text,str)
			if ThePlayer and IsAdmin(ThePlayer.userid) and not ThePlayer.lock then
				local target = TheInput:GetWorldEntityUnderMouse()
				
				if target ~= nil then
					local p = ThePlayer
					if p and p.player_classified then
						local data = p.player_classified.jester_data:value()
						if #data > 0 then
							str = str.."\n"..data
						end
					end
					
					SendModRPCToServer(MOD_RPC.JESTER.GET_DATA, target)
				end
			end
			return _SetString(text, str)
		end
	end)
end

if not TheNet:GetIsServer() then
	return
end

local function UpdateAge(inst)
	if not inst._days then
		return
	end
	
	if inst._days >= GLOMMER_DAYS then
		inst:AddTag("wants_to_die")
		if inst.components.health then
			inst.components.health:Kill()
		else
			inst:Remove()
		end
	end
end

menv.AddPrefabPostInit("glommer", function(inst)
	inst._days = 0
	
	inst:WatchWorldState("cycles", function()
		inst._days = inst._days + 1
		UpdateAge(inst)
	end)
	
	local _OnSave, _OnLoad = inst.OnSave, inst.OnLoad
	inst.OnSave = function(inst, data, ...)
		if data then
			data.days = inst._days
		end
		return _OnSave(inst, data, ...)
	end
	
	inst.OnLoad = function(inst, data, ...)
		if data and data.days then
			inst._days = data.days
		end
		return _OnLoad(inst, data, ...)
	end
end)

menv.AddPrefabPostInitAny(function(inst)
	if inst:HasTag("player") then
		return
	end

	local ic = inst.components
	if ic and (ic.burnable or ic.workable) then
		inst:AddComponent("jester_protector")
	end
end)

menv.AddPrefabPostInit("cave_entrance_open", function(inst)
	local _canspawn =  inst.components.childspawner.canspawnfn
	inst.components.childspawner.canspawnfn = function(inst, ...)
		local old = _canspawn(inst, ...)
		
		if old then
			local x, y, z = inst.Transform:GetWorldPosition()
			return #TheSim:FindEntities(x, 0, z, 30, {"multiplayer_portal"}) < 1				
		end
		return old
	end
end)

local function AnnounceDeath(inst, cause, afflicter)
	if not inst or not inst.name or not inst.prefab or
	not (STRINGS.NAMES[string.upper(inst.prefab)] or inst.name) or
	not afflicter or not afflicter.name or not afflicter.prefab or
	(not MOBS_LIST[inst.prefab] and not inst:HasTag("epic") and inst.prefab ~= "glommer") --[[or
	(not afflicter:HasTag("player") and not STRINGS.NAMES[string.upper(afflicter.prefab)])]] then
		return
	end
	
	if inst.prefab == "glommer" and inst:HasTag("wants_to_die") then
		print("[DEATH] Glommer've died of old age")
		return
	end
	
	local killer = afflicter:HasTag("player") and "Игрок" or "Моб"
	local killer_name = afflicter:HasTag("player") and afflicter.name or (STRINGS.NAMES[string.upper(afflicter.prefab)] or (cause and STRINGS.NAMES[string.upper(cause)]))
	local target = STRINGS.NAMES[string.upper(inst.prefab)] or inst.name
	
	TheNet:Announce(string.format("%s %s убил %s", killer, killer_name, target, nil, nil, "death"))
end

local function onentitydeath(world, data)
	printwrap("killed", data)
	if data and data.inst and not data.inst:HasTag("player") then
		AnnounceDeath(data.inst, data.cause, data.afflicter)
	end
end

menv.AddPrefabPostInit("world", function(inst)
	inst:ListenForEvent("entity_death", onentitydeath)
end)

--Добавляем овнершип на лодку
local ownershiptag = 'uid_private'

local function MakeOwnershipable(inst, noevent)
	local function onbuilt(inst, doer)
		inst.ownerlist = {}
		if doer.userid then
			inst:AddTag(ownershiptag)
			inst:AddTag('uid_'..doer.userid)
			inst.ownerlist[1] = ownershiptag
			inst.ownerlist[2] = 'uid_'..doer.userid
		end
	end
	
	--Да, жутко, но клеевцы не запускают вообще ничего для мачты.
	if noevent then
		inst:DoTaskInTime(0, function(inst)
			if inst:HasTag(ownershiptag) then
				return
			end
			local pos = inst:GetPosition()
			local player = TheSim:FindEntities(pos.x, 0, pos.z, 2, {"player"}, {"playerghost"})[1]
			if player then
				onbuilt(inst, player)
			end
		end)
	else
		inst:ListenForEvent("onbuilt", function(inst, data)
			if not data or not data.builder then
				return
			end
			onbuilt(inst, data.builder)
		end)
	end
	
	local _OnSave = inst.OnSave or function() end
	local _OnLoad = inst.OnLoad or function() end
	
	function inst:OnSave(data)
		if data and inst.ownerlist then
			data.ownerlist = inst.ownerlist
		end
		return _OnSave(inst, data)
	end
	
	function inst:OnLoad(data)
		if data and data.ownerlist then
			inst.ownerlist = data.ownerlist
			for i, ownertag in ipairs(data.ownerlist) do
				inst:AddTag(ownertag)
			end
		end
		return _OnLoad(inst, data)
	end
end

--nil если без овнершипа, true если владелец, иначе false
local function TestOwnership(inst, doer)
	if not inst:HasTag(ownershiptag) then
		return nil
	end
	return (doer and doer.userid) and inst:HasTag('uid_'..doer.userid)
end

local function OwnershipAction(act_name)
	local _fn = ACTIONS[act_name].fn
	ACTIONS[act_name].fn = function(act, ...)
		-- print("RUN", act_name)
		if act.target and act.doer and TestOwnership(act.target, act.doer) == false then
			return false
		end
		return _fn(act, ...)
	end
end

menv.AddComponentPostInit("anchor", function(self)
	MakeOwnershipable(self.inst)
	
	local _AddAnchorRaiser = self.AddAnchorRaiser
	function self:AddAnchorRaiser(doer, ...)
		if TestOwnership(self.inst, doer) == false then
			return false
		end
		return _AddAnchorRaiser(self, doer, ...)
	end
end)

menv.AddComponentPostInit("steeringwheel", function(self)
	MakeOwnershipable(self.inst)
end)

menv.AddComponentPostInit("boat", function(self)
	MakeOwnershipable(self.inst)
end)

menv.AddComponentPostInit("mast", function(self)
	MakeOwnershipable(self.inst, true)
	
	local _AddSailFurler = self.AddSailFurler
	function self:AddSailFurler(doer, ...)
		if TestOwnership(self.inst, doer) == false then
			return false
		end
		return _AddSailFurler(self, doer, ...)
	end
end)

OwnershipAction("STEER_BOAT")
OwnershipAction("RAISE_SAIL")
OwnershipAction("LOWER_SAIL")
OwnershipAction("LOWER_SAIL_BOOST")
-- OwnershipAction("LOWER_SAIL_FAIL")

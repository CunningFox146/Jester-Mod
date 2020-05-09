local SmokeEmitter = Class(function(self, inst)
	self.inst = inst
    self.smoketrail = nil
	self.time_since_last_puff = 0
	self.duration = 0
end)

function SmokeEmitter:Enable(duration)
	if not self.smoketrail then
		self.smoketrail = SpawnPrefab("smoketrail")
		self.inst:AddChild(self.smoketrail)
		if self.inst.smoke_emitter_offset then
			self.smoketrail.entity:SetParent(self.inst.entity)
			self.smoketrail.entity:AddFollower()
			self.smoketrail.Follower:FollowSymbol(self.inst.GUID, "symbol0",
				self.inst.smoke_emitter_offset.x, self.inst.smoke_emitter_offset.y, 0)
		else
			self.smoketrail.Transform:SetPosition(0, 1, 0)
		end
	end
end

function SmokeEmitter:Disable()
	if self.smoketrail then
		self.smoketrail:CancelAllPendingTasks()
		self.smoketrail:DoTaskInTime(5, function(inst)
			self.inst:RemoveChild(inst)
			inst:Remove()
		end)
		self.smoketrail = nil
		self.inst:StopUpdatingComponent(self)
	end
end

return SmokeEmitter
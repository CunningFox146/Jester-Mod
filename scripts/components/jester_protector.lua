local Protector = Class(function(self, inst)
    self.inst = inst
	
	self.isprotected = false
	self.inst:DoTaskInTime(0, function() 
		self:ChangeProtecion(true)
	end)
end)

function Protector:ChangeProtecion(init)
	if not init then
		self.isprotected = not self.isprotected
	end
	
	local workable = self.inst.components.workable
	local burnable = self.inst.components.burnable
	
	if workable then
		workable.workable = not self.isprotected
	end
	
	if burnable then
		burnable.canlight = not self.isprotected
	end
end

function Protector:OnSave()
	return {
		isprotected = self.isprotected or false
	}
end

function Protector:OnLoad(data)
	if data then
		self.isprotected = data.isprotected or false
	end
end

return Protector

-- Standard OOP (with Constructor parameters added.)
_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s s:initialise(...) return o end, initialise = function() end }

---
---				Scene Base Class
---

local Scene = Base:new()

function Scene:initialise()
	self.isCreated = false 																	-- no scene created yet.
	self.viewGroup = nil 																	-- there is no new group.
	self.owningManager = nil 																-- it is not owned by a scene manager.
	self.allowGarbageCollection = true 														-- true if can be garbage collected.
end

function Scene:setManagerInstance(manager) self.owningManager = manager end 				-- set the manager instance.
function Scene:getViewGroup() return self.viewGroup end 									-- get the view group for this scene.
function Scene:setVisible(isVisible) self.viewGroup.isVisible = isVisible end 				-- set view group (scene in practice) visibility
function Scene:gotoScene(scene) self.owningManager:gotoScene(scene) end 					-- helper function

function Scene:initialiseScene()
	if not self.isCreated then 																-- if not created
		if self.viewGroup == nil then self.viewGroup = display.newGroup() end 				-- create a view group, if needed.
		self.isCreated = true 																-- mark as created.
		self:create() 																		-- call the creation routine.
	end
	self:setVisible(false) 																	-- hide the scene, we don't actually want it yet.
end

function Scene:deleteScene() 													
	if self.allowGarbageCollection then
		if self.isCreated then self:destroy() end 											-- destroy if created
		self.isCreated = false 																-- mark as 'not created' so it will recreate if needed again.
		if self.viewGroup ~= nil then display.remove(self.viewGroup) end 					-- remove view group if not created
		self.viewGroup = nil 																-- mark that as nil.
	end
	return self.allowGarbageCollection 														-- return true if was garbage collected.
end

function Scene:getTransitionType() return "fade" end 										-- override this to change the transition (defined by target scene)
function Scene:getTransitionTime() return 500 end

function Scene:create() end 																-- default methods caused to create etc. scenes
function Scene:preOpen() end
function Scene:postOpen() end
function Scene:preClose() end
function Scene:postClose() end
function Scene:destroy() end

---
---				Scene Manager Class.
---

local SceneManager = Base:new()

SceneManager.transitionInProgress = false 													-- used to lock out gotoScreen when one is in progress.

function SceneManager:initialise(transitionManager)
	assert(transitionManager ~= nil,"No instance of Transition Manager provided") 			-- check transition manager here.
	self.transitionManager = transitionManager 												-- save transition manager reference.
	self.sceneStore = {} 																	-- hash of scene name -> scene event.object1
	self.currentScene = nil 																-- No current scene.
end

function SceneManager:append(sceneName,sceneInstance)
	sceneName = sceneName:lower() 															-- make it lower case.
	assert(self.sceneStore[sceneName] == nil,"Scene "..sceneName.." has been redefined") 	-- check it is not a duplicate.
	assert(sceneInstance ~= nil,"No scene instance provided.") 								-- check instance is provided.
	self.sceneStore[sceneName] = sceneInstance 												-- store the instance.
	sceneInstance:setManagerInstance(self) 													-- tell the scene who its parent is.
	return self
end

function SceneManager:gotoScene(scene)
	if SceneManager.transitionInProgress then return end									-- cannot do a transition when one is happening.
	SceneManager.transitionInProgress = true

	if type(scene) == "string" then 														-- you can do it by reference or by name
		scene = scene:lower() 																-- lower case names
		assert(self.sceneStore[scene] ~= nil,"Scene "..scene.." is not known")				-- check it is known
		scene = self.sceneStore[scene] 														-- now it's a reference.
	end
	assert(type(scene) == "table","Bad parameter to gotoScene()")							-- check we have a table.

	scene:initialiseScene() 																-- create scene, if necessary.
	scene:preOpen() 																		-- and we are about to open the new scene as part of the transition.
	self.newScene = scene 																	-- save a reference to the new scene

	if self.currentScene ~= nil then
		self.currentScene:preClose() 														-- call pre-close (i.e. about to fade out the scene)
	end


	local currentViewGroup = nil 															-- get current scene's view group, if there is one.
	if self.currentScene ~= nil then currentViewGroup = self.currentScene:getViewGroup() end

	self.transitionManager:execute(scene:getTransitionType(),self, 							-- do the transition.
									currentViewGroup,scene:getViewGroup(),
									scene:getTransitionTime())

end

function SceneManager:transitionCompleted()
	if self.currentScene ~= nil then 														-- if there is a scene we are leaving.
		self.currentScene:postClose() 														-- call the post close scene
		self.currentScene:setVisible(false) 												-- and hide it.
	end

	self.currentScene = self.newScene 														-- update the current scene member variable
	SceneManager.transitionInProgress = false 												-- transition no longer in progress.
	self.newScene:postOpen()  																-- about to open (which can call goto Scene)


end

return { SceneManager = SceneManager, Scene = Scene }

-- TODO: Check that scene can in fact gotoScene on postOpen()
-- TODO: Ticked scene.
-- TODO: Overlay scene.

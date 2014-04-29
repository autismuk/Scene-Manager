-- Standard OOP (with Constructor parameters added.)
_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s s:initialise(...) return o end, initialise = function() end }

--- ************************************************************************************************************************************************************************
---
---																					Scene Base Class
---
--- ************************************************************************************************************************************************************************

local Scene = Base:new()

function Scene:initialise()
	self.isCreated = false 																	-- no scene created yet.
	self.viewGroup = nil 																	-- there is no new group.
	self.owningManager = nil 																-- it is not owned by a scene manager.
	self.allowGarbageCollection = true 														-- true if can be garbage collected.
end

function Scene:setManagerInstance(manager) self.owningManager = manager return self end 	-- set the manager instance.
function Scene:getViewGroup() return self.viewGroup end 									-- get the view group for this scene.
function Scene:setVisible(isVisible) self.viewGroup.isVisible = isVisible return self end 	-- set view group (scene in practice) visibility
function Scene:gotoScene(scene) self.owningManager:gotoScene(scene) end 					-- helper function
function Scene:insert(object) self.viewGroup:insert(object) return self end 				-- helper function
function Scene:protect() self.allowGarbageCollection = false return self end 				-- set the garbage collection protection flag.

function Scene:_initialiseScene()															-- creates scene if necessary.
	if not self.isCreated then 																-- if not created
		if self.viewGroup == nil then self.viewGroup = display.newGroup() end 				-- create a view group, if needed.
		self.isCreated = true 																-- mark as created.
		self:create() 																		-- call the creation routine.
	end
	self:setVisible(false) 																	-- hide the scene, we don't actually want it yet.
end

function Scene:_garbageCollectScene() 														-- destroy scene (can be created) if allowed - freeing up space		
	if self.allowGarbageCollection then
		if self.isCreated then self:destroy() end 											-- destroy if created
		self.isCreated = false 																-- mark as 'not created' so it will recreate if needed again.
		if self.viewGroup ~= nil then display.remove(self.viewGroup) end 					-- remove view group if not created
		self.viewGroup = nil 																-- mark that as nil.
	end
	return self.allowGarbageCollection 														-- return true if was garbage collected.
end

function Scene:_destroyScene() 																-- murderdeathkill scene destroyer, just destroys it.
	self.allowGarbageCollection = true 														-- we are deleting this whatever.
	self:_garbageCollectScene() 															-- tidy up the view part
	self.owningManager = nil 																-- remove the reference to the owning manager, the whole thing is going.
end


function Scene:getTransitionType() return "fade" end 										-- override this to change the transition (defined by target scene)
function Scene:getTransitionTime() return 500 end 											-- obviously these are independent.

function Scene:create() end 																-- default methods caused to create etc. scenes
function Scene:preOpen() end
function Scene:postOpen() end
function Scene:preClose() end
function Scene:postClose() end
function Scene:destroy() end

--- ************************************************************************************************************************************************************************
---
---												Scene which transitions automatically to another after a specified time.
---
--- ************************************************************************************************************************************************************************

local DelayScene = Scene:new()

function DelayScene:enterFrame(e,elapsed) 
	if elapsed > self:sceneDelay() then  													-- if delay time has elapsed
		self:gotoScene(self:nextScene()) 													-- go to the next scene.
	end
end

function DelayScene:nextScene() error "DelayScene is an abstract class." end 				-- default target scene
function DelayScene:sceneDelay() return 1000 end 											-- default time.

--- ************************************************************************************************************************************************************************
---
---																				  Overlay Scene
---
--- ************************************************************************************************************************************************************************

local OverlayScene = Scene:new()

OverlayScene.isOverlay = true 																-- return true if operates as overlay.

function OverlayScene:closeOverlay() self.owningManager:_closeOverlay() end 				-- passes close overlay to scene manager.
function OverlayScene:isModal() return false end

local ModalOverlayScene = OverlayScene:new()												-- same thing but modal overlay.
function ModalOverlayScene:isModal() return true end

--- ************************************************************************************************************************************************************************
---
---																				Scene Manager Class.
---
--- ************************************************************************************************************************************************************************

local SceneManager = Base:new()

SceneManager.transitionInProgress = false 													-- used to lock out gotoScreen when one is in progress.

function SceneManager:initialise(transitionManager)
	assert(transitionManager ~= nil,"No instance of Transition Manager provided") 			-- check transition manager here.
	self.transitionManager = transitionManager 												-- save transition manager reference.
	self.sceneStore = {} 																	-- hash of scene name -> scene event.object1
	self.currentScene = nil 																-- No current scene.
	self.isEnterFrameEventEnabled = false 													-- true if enter frame event on.
end

function SceneManager:destroy()
	self:_setEnableEnterFrameEvent(false) 													-- disable enter frame runtime listener if on.
	if self.currentScene ~= nil then 														-- If there is a current scene 
		self.currentScene:preClose() 														-- run the shutdown sequence in a peremptory manner
		self.currentScene:setVisible(false)
		self.currentScene:postClose()
		self.currentScene = nil 															-- remove the references
		self.previousScene = nil
	end
	for _,ref in pairs(self.sceneStore) do self.sceneStore[ref]:_destroyScene() end 		-- destroy all the scenes completely.
	self.sceneStore = nil 																	-- and remove remaining references
	self.transitionManager = nil
end

function SceneManager:_setEnableEnterFrameEvent(newStatus) 									-- turn enter-frame off and on.
	if self.newStatus ~= self.isEnterFrameEventEnabled then 								-- status changed.
		self.isEnterFrameEventEnabled = newStatus 											-- update status
		if newStatus then  Runtime:addEventListener( "enterFrame", self )					-- add or remove event listener accordingly.
		else 			   Runtime:removeEventListener( "enterFrame", self )
		end
	end
end

function SceneManager:enterFrame(e) 														-- handle enter frame listener owned by Scene Manager.
	if self.currentScene ~= nil and self.isEnterFrameEventEnabled and 						-- if a scene, enterFrame is on, no transition is happening
	   not SceneManager.transitionInProgress and self.currentScene.enterFrame ~= nil then 	-- and there's an enterFrame function then call it.
			self.currentScene:enterFrame(e,e.time-self.sceneStartTime)
	end
end

function SceneManager:append(sceneName,sceneInstance)
	sceneName = sceneName:lower() 															-- make it lower case.
	assert(self.sceneStore[sceneName] == nil,"Scene "..sceneName.." has been redefined") 	-- check it is not a duplicate.
	assert(sceneInstance ~= nil,"No scene instance provided.") 								-- check instance is provided.
	self.sceneStore[sceneName] = sceneInstance 												-- store the instance.
	sceneInstance:setManagerInstance(self) 													-- tell the scene who its parent is.
	if sceneInstance.enterFrame ~= nil then self:_setEnableEnterFrameEvent(true) end 		-- enable tick if a scene has enterFrame method
	return self
end

function SceneManager:gotoScene(scene)
	if SceneManager.transitionInProgress then return end									-- cannot do a transition when one is happening.
	SceneManager.transitionInProgress = true

	if self.currentScene ~= nil then 
		assert(not self.currentScene.isOverlay,"Cannot transition when overlay visible") 	-- can't do a gotoScene() when current scene is overlay.
	end

	if type(scene) == "string" then 														-- you can do it by reference or by name
		scene = scene:lower() 																-- lower case names
		assert(self.sceneStore[scene] ~= nil,"Scene "..scene.." is not known")				-- check it is known
		scene = self.sceneStore[scene] 														-- now it's a reference.
	end
	assert(type(scene) == "table","Bad parameter to gotoScene()")							-- check we have a table.

	scene:_initialiseScene() 																-- create scene, if necessary.
	scene:preOpen() 																		-- and we are about to open the new scene as part of the transition.
	self.newScene = scene 																	-- save a reference to the new scene

	local currentViewGroup = nil 															-- get current scene's view group, if there is one.
	if self.currentScene ~= nil and not scene.isOverlay then 								-- if there is a scene and we are not transitioning to an overlay
		self.currentScene:preClose() 														-- call pre-close (i.e. about to fade out the scene)
		currentViewGroup = self.currentScene:getViewGroup()
	end

	self.transitionManager:execute(scene:getTransitionType(),self, 							-- do the transition.
									currentViewGroup,scene:getViewGroup(),
									scene:getTransitionTime())

end

function SceneManager:_closeOverlay()
	if SceneManager.transitionInProgress then return end									-- cannot do a transition when one is happening.
	SceneManager.transitionInProgress = true
	assert(self.currentScene ~= nil and self.currentScene.isOverlay,"Overlay is not present")
	self.currentScene:preClose()															-- send pre close to overlay.
	self.transitionManager:execute(self.currentScene:getTransitionType(),self,				-- start a transition to close the overlay.
									self.currentScene:getViewGroup(),nil,
									self.currentScene:getTransitionTime())
end

function SceneManager:transitionCompleted()													-- this is called when a transition has completed.

	if self.currentScene ~= nil and self.currentScene.isOverlay then 						-- currently in overlay
		self.currentScene:postClose() 														-- post close to overlay
		self.currentScene:setVisible(false) 												-- and hide it.
		self.currentScene = self.previousScene 												-- go to the previous scene.
		self.newScene = nil
	else
		if self.currentScene ~= nil and not self.newScene.isOverlay then 					-- if there was a scene we are leaving.
			self.currentScene:postClose() 													-- call the post close scene
			self.currentScene:setVisible(false) 											-- and hide it.
		end

		self.previousScene = self.currentScene 												-- save previous scene
		self.currentScene = self.newScene 													-- update the current scene member variable
		self.newScene = nil 																-- remove the reference to the new scene.
		self.currentScene:postOpen()  														-- about to open, send that message.
		self.sceneStartTime = system.getTimer() 											-- remember when this scene started.
	end
	SceneManager.transitionInProgress = false 												-- transition no longer in progress.
end

return { SceneManager = SceneManager, Scene = Scene, DelayScene = DelayScene, OverlayScene = OverlayScene, ModalOverlayScene = ModalOverlayScene }

-- TODO: Overlay scene modality.
-- TODO: Storage as part of a scene.
-- TODO: Clean up (GC) via Scene Manager, NOT the current scene obviously.

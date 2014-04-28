-- Standard OOP (with Constructor parameters added.)
_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s s:initialise(...) return o end, initialise = function() end }

--
--		Class encapsulating a single transition, which can perform a transition on a display object or (eventually) my View Scene class.
--
local Transition = Base:new()

function Transition:set(description,option)
	self.description = description 														-- Save the description
	self.option = option or {} 															-- Save the options table
	return self 																		-- Allow chaining
end

function Transition:execute(displayGroup,timerPeriod,completionTarget)								
	self.completionTarget = completionTarget 											-- remember where completed message is being sent.
	displayGroup.x = self.description.xStart or Transition.defaults.xStart				-- set display views start values
	displayGroup.y = self.description.yStart or Transition.defaults.yStart	
	displayGroup.rotation = self.description.rotationStart or Transition.defaults.rotationStart
	displayGroup.alpha = self.description.alphaStart or Transition.defaults.alphaStart
	displayGroup.xScale = self.description.xScaleStart or Transition.defaults.xScaleStart
	displayGroup.yScale = self.description.yScaleStart or Transition.defaults.yScaleStart

	transition.to(displayGroup, { time = timerPeriod,  									-- transition to the end values.
								  transition = self.option.transition or easing.linear,	-- which transition to use, what to do at the end
								  onComplete = function (e) self:completed(displayGroup) end,	
								  x = self.description.xEnd, y = self.description.yEnd, -- the transitions to make.
								  rotation = self.description.rotationEnd,
								  alpha = self.description.alphaEnd,
								  xScale = self.description.xScaleEnd, yScale = self.description.yScaleEnd })
end

function Transition:completed(displayGroup)
	displayGroup.x,displayGroup.y = Transition.defaults.xEnd,Transition.defaults.yEnd 	-- on exit, set everything back to the defaults.
	displayGroup.rotation = Transition.defaults.rotationEnd 							-- the transition manager hides or shows it, this just does the transition.
	displayGroup.alpha = Transition.defaults.alphaEnd
	displayGroup.xScale,displayGroup.yScale = Transition.defaults.xScaleEnd,Transition.defaults.yScaleEnd 
	self.completionTarget:transitionCompletedMessage() 									-- tell the completion target it's completed.
	self.completionTarget = nil 														-- clear the external reference.
end

Transition.defaults = { alphaStart = 1.0, alphaEnd = 1.0,								-- List of transition default values
					   xScaleStart = 1.0,xScaleEnd = 1.0,yScaleStart = 1.0,yScaleEnd = 1.0,
					   xStart = 0,yStart = 0,xEnd = 0,yEnd = 0, 
					   rotationStart = 0,rotationEnd = 0}

--
--		Class managing transitions. We return an singleton instance of this.
--
local TransitionManager = Base:new()

function TransitionManager:initialise()
	self.transitionList = {} 															-- Clear the list of known transitions.
end

function TransitionManager:add(name,fromTransition,toTransition)
	name = name:lower() 																-- all transition names are case insensitive
	assert(self.transitionList[name] == nil,"Duplicate transition "..name) 				-- check for duplicates, which should not happen.
	self.transitionList[name] = { from = fromTransition, to = toTransition } 			-- and store the transition.
end

function TransitionManager:execute(transitionName,target,fromScene,toScene,time)
	time = time or 500 																	-- default time is 0.5s
	transitionName = transitionName:lower() 											-- transition names are lower case, check it exists.
	assert(self.transitionList[transitionName] ~= nil,"Transition '"..transitionName.."'unknown")
	self.transition = self.transitionList[transitionName]								-- keep reference to transition.
	assert(fromScene ~= nil or toScene ~= nil,"Nothing to transition to/from")			-- check there is at least one scene passed.
	self.launchCount = 0 																-- number of transitions started.

	self.isConcurrent = fromScene ~= nil and toScene ~= nil and 						-- check to see if a pair of concurrent transitions
													self.transition.from.option.concurrent
	self:makeVisible(fromScene,true) 													-- make sure from scene is visible and to scene is not
	self:makeVisible(toScene,false) 						

	self.sceneInfo = { fromScene = fromScene,toScene = toScene, 						-- save parameters, we will need them.
										transitionName = transitionName, time = time, target = target}

	self.secondLaunch = false 															-- flag is true if we have done the second launch.

	if self.isConcurrent then  															-- concurrency ?
		self:makeVisible(toScene,true)													-- then make both scenes visible.
		self:launch(fromScene,self.transition.from)										-- then launch both at the same time. 
		self:launch(toScene,self.transition.to)
	elseif fromScene ~= nil then 														-- else if there is a from, run that first.
		self:launch(fromScene,self.transition.from) 
	else  																				-- if there is only a 'to' scene, run that.
		self:makeVisible(toScene,true) 													-- make it visible first
		self:launch(toScene,self.transition.to)
	end
end

function TransitionManager:launch(scene,transition)
	self.launchCount = self.launchCount + 1 											-- increment the launch count.
	transition:execute(scene,self.sceneInfo.time,self) 									-- start the transition and notify
end

function TransitionManager:makeVisible(scene,isVisible) 								-- set visibility state - allows use of different objects.
	if scene ~= nil then 																-- if there is a scene, then 
		scene.isVisible = isVisible 													-- set its visibility state.
		scene:toFront() 																-- move to the top of the stack
	end
end

function TransitionManager:transitionCompletedMessage()
	self.launchCount = self.launchCount - 1 											-- decrement the launch count.
	if self.launchCount == 0 then 														-- has the launch count reached zero ? 

		if not self.secondLaunch and self.sceneInfo.fromScene ~= nil and 				-- if we have not done the second launch, there is a from 
		   self.sceneInfo.toScene ~= nil and (not self.isConcurrent) then  				-- and to scene, and we didn't launch concurrently, there's another one to do first
		   	self.secondLaunch = true 													-- mark having launched the second transition
		   	self:makeVisible(self.sceneInfo.fromScene,false) 							-- make the first invisible, and the second visible.
		   	self:makeVisible(self.sceneInfo.toScene,true)
		   	self:launch(self.sceneInfo.toScene,self.transition.to) 						-- and launch the second transition, which must be 'to' obviously.
		end
	end

	if self.launchCount == 0 then 														-- have we actually finished now ?
		self:makeVisible(self.sceneInfo.fromScene,true) 								-- make the from scene visible again, so both are visible on exit.
		self:makeVisible(self.sceneInfo.toScene,true) 									-- make to scene visible, so it comes on top.
		local target = self.sceneInfo.target 											-- get the message target
		self.sceneInfo = nil 															-- remove any references we do not want.
		if target ~= nil then 								 							-- and tell the target we are done.
			assert(target.transitionCompleted ~= nil,"target message class does not have a transitionCompleted() method")
			target:transitionCompleted() 
		end
	end
end

--
--	This will be the instance of transition manager that we work with.
--
local manager = TransitionManager:new()
--
--	Helper Function for defining transitions
--
local function defineTransition(transitionName,fromTransition,toTransition,options)
	local fto = Transition:new():set(fromTransition,options or {}) 						-- create a from-transition object
	local tto = Transition:new():set(toTransition,options or {}) 						-- create a to-transition object
	manager:add(transitionName,fto,tto) 												-- add to the transition manager instance
end

--
--	Helper locals, required for the transitions.
--
local displayW = display.contentWidth
local displayH = display.contentHeight

--
--	Define transitions. Two transitions, in/out plus options.
--
-- 	hideOnOut 				Hide the disappearing transition on exit, ignore this
-- 	concurrent				Do both transitions at the same time.
-- 	sceneAbove 				Should be top-most scene, ignore this.

defineTransition("fade",
		{ alphaStart = 1.0, alphaEnd = 0 }, 
		{ alphaStart = 0, alphaEnd = 1.0 })

defineTransition("zoomoutin",
		{ xEnd = displayW*0.5, yEnd = displayH*0.5, xScaleEnd = 0.001, yScaleEnd = 0.001 }, 
		{ xScaleStart = 0.001, yScaleStart = 0.001, xScaleEnd = 1.0, yScaleEnd = 1.0, xStart = displayW*0.5, yStart = displayH*0.5, xEnd = 0, yEnd = 0 }, 
		{ hideOnOut = true })

defineTransition("zoomoutinfade",		
		{ xEnd = displayW*0.5, yEnd = displayH*0.5, xScaleEnd = 0.001, yScaleEnd = 0.001, alphaStart = 1.0, alphaEnd = 0 }, 
		{ xScaleStart = 0.001, yScaleStart = 0.001, xScaleEnd = 1.0, yScaleEnd = 1.0, xStart = displayW*0.5, yStart = displayH*0.5, xEnd = 0, yEnd = 0, alphaStart = 0, alphaEnd = 1.0 }, 
		{ hideOnOut = true })

defineTransition("zoominout",		
		{ xEnd = -displayW*0.5, yEnd = -displayH*0.5, xScaleEnd = 2.0, yScaleEnd = 2.0 }, 
		{ xScaleStart = 2.0, yScaleStart = 2.0, xScaleEnd = 1.0, yScaleEnd = 1.0, xStart = -displayW*0.5, yStart = -displayH*0.5, xEnd = 0, yEnd = 0 }, 
		{ hideOnOut = true })

defineTransition("zoominoutfade",
		{ xEnd = -displayW*0.5, yEnd = -displayH*0.5, xScaleEnd = 2.0, yScaleEnd = 2.0, alphaStart = 1.0, alphaEnd = 0 }, 
		{ xScaleStart = 2.0, yScaleStart = 2.0, xScaleEnd = 1.0, yScaleEnd = 1.0, xStart = -displayW*0.5, yStart = -displayH*0.5, xEnd = 0, yEnd = 0, alphaStart = 0, alphaEnd = 1.0 }, 
		{ hideOnOut = true })

defineTransition("flip",
		{ xEnd = displayW*0.5, xScaleEnd = 0.001 }, 
		{ xScaleStart = 0.001, xScaleEnd = 1.0, xStart = displayW*0.5, xEnd = 0 })

defineTransition("flipfadeoutin",		
		{ xEnd = displayW*0.5, xScaleEnd = 0.001, alphaStart = 1.0, alphaEnd = 0 }, 
		{ xScaleStart = 0.001, xScaleEnd = 1.0, xStart = displayW*0.5, xEnd = 0, alphaStart = 0, alphaEnd = 1.0 })

defineTransition("zoomoutinrotate",
		{ xEnd = displayW*0.5, yEnd = displayH*0.5, xScaleEnd = 0.001, yScaleEnd = 0.001, rotationStart = 0, rotationEnd = -360 }, 
		{ xScaleStart = 0.001, yScaleStart = 0.001, xScaleEnd = 1.0, yScaleEnd = 1.0, xStart = displayW*0.5, yStart = displayH*0.5, xEnd = 0, yEnd = 0, rotationStart = -360, rotationEnd = 0 }, 
		{ hideOnOut = true })

defineTransition("zoomoutinfaderotate",
 		{ xEnd = displayW*0.5, yEnd = displayH*0.5, xScaleEnd = 0.001, yScaleEnd = 0.001, rotationStart = 0, rotationEnd = -360, alphaStart = 1.0, alphaEnd = 0 }, 
 		{ xScaleStart = 0.001, yScaleStart = 0.001, xScaleEnd = 1.0, yScaleEnd = 1.0, xStart = displayW*0.5, yStart = displayH*0.5, xEnd = 0, yEnd = 0, rotationStart = -360, rotationEnd = 0, alphaStart = 0, alphaEnd = 1.0 }, 
 		{ hideOnOut = true })

defineTransition("zoominoutrotate",	
		{ xEnd = displayW*0.5, yEnd = displayH*0.5, xScaleEnd = 2.0, yScaleEnd = 2.0, rotationStart = 0, rotationEnd = -360 }, 
		{ xScaleStart = 2.0, yScaleStart = 2.0, xScaleEnd = 1.0, yScaleEnd = 1.0, xStart = displayW*0.5, yStart = displayH*0.5, xEnd = 0, yEnd = 0, rotationStart = -360, rotationEnd = 0 }, 
		{ hideOnOut = true })
	
defineTransition("zoominoutfaderotate",		
		{ xEnd = displayW*0.5, yEnd = displayH*0.5, xScaleEnd = 2.0, yScaleEnd = 2.0, rotationStart = 0, rotationEnd = -360, alphaStart = 1.0, alphaEnd = 0 }, 
		{ xScaleStart = 2.0, yScaleStart = 2.0, xScaleEnd = 1.0, yScaleEnd = 1.0, xStart = displayW*0.5, yStart = displayH*0.5, xEnd = 0, yEnd = 0, rotationStart = -360, rotationEnd = 0, alphaStart = 0, alphaEnd = 1.0 }, 
		{ hideOnOut = true })
	
defineTransition("fromright",
 		{ xStart = 0, yStart = 0, xEnd = 0, yEnd = 0, transition = easing.outQuad }, 
 		{ xStart = displayW, yStart = 0, xEnd = 0, yEnd = 0, transition = easing.outQuad }, 
 		{ concurrent = true, sceneAbove = true })
	

defineTransition("fromleft",
		{ xStart = 0, yStart = 0, xEnd = 0, yEnd = 0, transition = easing.outQuad }, 
		{ xStart = -displayW, yStart = 0, xEnd = 0, yEnd = 0, transition = easing.outQuad }, 
		{ concurrent = true, sceneAbove = true })

defineTransition("fromtop",
		{ xStart = 0, yStart = 0, xEnd = 0, yEnd = 0, transition = easing.outQuad }, 
		{ xStart = 0, yStart = -displayH, xEnd = 0, yEnd = 0, transition = easing.outQuad }, 
		{ concurrent = true, sceneAbove = true })

defineTransition("frombottom",
		{ xStart = 0, yStart = 0, xEnd = 0, yEnd = 0, transition = easing.outQuad }, 
		{ xStart = 0, yStart = displayH, xEnd = 0, yEnd = 0, transition = easing.outQuad }, 
		{ concurrent = true, sceneAbove = true })

defineTransition("slideleft",
		{ xStart = 0, yStart = 0, xEnd = -displayW, yEnd = 0, transition = easing.outQuad }, 
		{ xStart = displayW, yStart = 0, xEnd = 0, yEnd = 0, transition = easing.outQuad }, 
		{ concurrent = true, sceneAbove = true })

defineTransition("slideright",
 		{ xStart = 0, yStart = 0, xEnd = displayW, yEnd = 0, transition = easing.outQuad }, 
 		{ xStart = -displayW, yStart = 0, xEnd = 0, yEnd = 0, transition = easing.outQuad }, 
 		{ concurrent = true, sceneAbove = true })

defineTransition("slidedown",
 		{ xStart = 0, yStart = 0, xEnd = 0, yEnd = displayH, transition = easing.outQuad }, 
 		{ xStart = 0, yStart = -displayH, xEnd = 0, yEnd = 0, transition = easing.outQuad }, 
 		{ concurrent = true, sceneAbove = true })

defineTransition("slideup",		
		{ xStart = 0, yStart = 0, xEnd = 0, yEnd = -displayH, transition = easing.outQuad }, 
		{ xStart = 0, yStart = displayH, xEnd = 0, yEnd = 0, transition = easing.outQuad }, 
		{ concurrent = true, sceneAbove = true })

defineTransition("crossfade",		
		{ alphaStart = 1.0, alphaEnd = 0, }, 
		{ alphaStart = 0, alphaEnd = 1.0 }, 
		{ concurrent = true })

return TransitionManager 
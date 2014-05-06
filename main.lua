--- ************************************************************************************************************************************************************************
---
---				Name : 		main.lua
---				Purpose :	Scene Manager Test
---				Created:	30 April 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************

--
--	This creates three scenes. Scene 1 and 3 are the same (except for the visible sign). Scene 2 is an automatic scene that displays "and now"
--	Scenes 1 and 3 both can popup an overlay, and both display the number of 'enterFrame' events they have received.
--
display.setStatusBar( display.HiddenStatusBar )

sm = require("system.scenemanager")
smgr = sm.SceneManager																				-- acquire a reference to scene manager instance.

--//	This is a very simple class that is a bodge, basically. It is a Q+D way of creating easily distinguishable scenes for testing purposes

SimpleSceneClass = sm.Scene:new() 																			

--//	Constructor which gives the scene an 'ID' - just so you can tell which is which, and a target - where we go from here.
--//	@id 	[number]		number to display on scene
--//	@tgt 	[string]		string identifying scene where we go next.

function SimpleSceneClass:initialise(id,tgt) 
	self.id = id 
	self.tgt = tgt return self 
end

--//	Called when Scene created.

function SimpleSceneClass:create()
	local vg = self:getViewGroup() 																	-- access scenes view group
	self.r = display.newRect(10,10,display.contentWidth-20,display.contentHeight-20)				-- draw a rectangle and neaten it up
	self.r.anchorX, self.r.anchorY = 0,0
	self.r:setFillColor( 0.4,0,0 ) self.r.strokeWidth = 42 self.r:setStrokeColor(0,0,1)

	self.text = display.newText("Scene "..self.id,display.contentWidth/2,							-- create text saying "Scene <number>"
											display.contentHeight/4,native.systemFont,32) 			-- so we can see what Scene it is.
	self.text:addEventListener( "tap", self ) 														-- redirect taps.

	self.textCount = display.newText("?",display.contentWidth/2,									-- for the counter. Each scene has an enterFrame
										display.contentHeight*3/4,native.systemFont,24) 			-- counter which counts every enterFrame event.

	self.ovButton = display.newCircle(display.contentWidth/2,display.contentHeight/2,22) 			-- a round 'button'. tapping this brings up the overlay.
	self.ovButton:setFillColor( 0,1,1 )
	self.ovButton:addEventListener( "tap", self )

	self:insert(self.r):insert(self.textCount):insert(self.text):insert(self.ovButton) 				-- put everything in the viewgroup
	self.item = 0 																					-- clear the counter of enterFrames.
end

--//	Called on tap event
--//	@event [event object]	standard tap object

function SimpleSceneClass:tap(event)
	if event.target == self.text then 																-- did we tap the 'Scene n' text
		self:gotoScene(self.tgt)																	-- if so , go to this scene.
	else
		self:gotoScene("over1") 																	-- otherwise, go to the overlay screen
	end
	return true
end

--//	The manager does this for us. You do not have to add an eventListener to get this. 
--//	@e 	[event] 	enterFrame event object
--//	@elapsed [number] ms elapsed since it opened.

function SimpleSceneClass:enterFrame(e,elapsed)
	self.item = self.item + 1 																		-- bump the count of enterFrames by one.
	self.textCount.text = self.item 																-- update the text
end


--
--		These are all just for information, printing out the messages scenes received. You do not need to implement these.
--

function SimpleSceneClass:preOpen() print("Scene "..self.id.." pre-open") end
function SimpleSceneClass:postOpen() print("Scene "..self.id.." post-open") end
function SimpleSceneClass:preClose() print("Scene "..self.id.." pre-close") end
function SimpleSceneClass:postClose() print("Scene "..self.id.." post-close") end
function SimpleSceneClass:destroy() print("Scene "..self.id.." destroy") end

--//	Override the Scenes 1 and 3 so you 'flip' into them. The transition is the one used when your scene is a target.

function SimpleSceneClass:getTransitionType() return "flip" end

--//	A short display class which just displays 'And now ....' (Scene 2)

ShortDisplayClass = sm.DelayScene:new()

function ShortDisplayClass:create()
	self:insert(display.newText("And now ...",														-- create the display objects for this scene
					display.contentWidth/2,display.contentHeight/2,native.systemFont,24))
end
function ShortDisplayClass:nextScene() return "thirdscene" end 										-- when it's finished, we go to the scene called 'thirdscene'
function ShortDisplayClass:sceneDelay() return 2500 end 											-- after 2500 seconds.


--//	This is the modal overlay class

DemoOverlayClass = sm.ModalOverlayScene:new()

function DemoOverlayClass:create()
	local c = display.newCircle( display.contentWidth/2,display.contentHeight/2,100 ) 				-- we draw a big green circle
	c:setFillColor( 0,1,0 )
	c.strokeWidth = 2
	self:insert(c) 																					-- add it to the view
	c:addEventListener( "tap", self )																-- and listen for it.
end

function DemoOverlayClass:tap(e)
	self:closeOverlay() 																			-- when the circle is tapped, we close the overlay.
	return true
end

function DemoOverlayClass:preOpen() print("Scene Overlay pre-open") end 							-- these are more debugging things to help see what's going on.
function DemoOverlayClass:postOpen() print("Scene Overlay post-open") end 							-- you don't need to define these.
function DemoOverlayClass:preClose() print("Scene Overlay pre-close") end
function DemoOverlayClass:postClose() print("Scene Overlay post-close") end
function DemoOverlayClass:destroy() print("Scene Overlay destroy") end

--		This means we zoom into the transaction.  Note that overlays use the same transaction
-- 		for in and out, because it's not actually entering the scene when it closes.

function DemoOverlayClass:getTransitionType() return "zoomInOut" end

scene1inst = SimpleSceneClass:new("One","secondscene") 												-- we create three instance. The parameters are the identifier
scene2inst = ShortDisplayClass:new() 																-- and the target scene. So tapping the text on scene1inst goes to 
scene3inst = SimpleSceneClass:new("3","firstscene") 												-- "secondscene"

ovinst = DemoOverlayClass:new() 																	-- and we have an instance of our overlay class.

smgr:append("firstscene",scene1inst):append("secondscene",scene2inst)								-- we now tell the scene manager all about them.
smgr:append("thirdscene",scene3inst):append("over1",ovinst)

-- you could right smgr:append("firstscene",SimpleSceneClass:new("One","secondscene"))

smgr:gotoScene("firstScene") 																		-- and go to the first scene.





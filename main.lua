--[[

																			Scene Manager Test
--]]

display.setStatusBar( display.HiddenStatusBar )

sm = require("system.scenemanager")
smgr = sm.SceneManager.getInstance()																		-- acquire the scene manager instance.

SimpleSceneClass = sm.Scene:new() 																			

function SimpleSceneClass:create()
	local vg = self:getViewGroup()
	self.r = display.newRect(10,10,display.contentWidth-20,display.contentHeight-20)
	self.r.anchorX, self.r.anchorY = 0,0
	self.r:setFillColor( 0.4,0,0 ) self.r.strokeWidth = 42 self.r:setStrokeColor(0,0,1)
	self.text = display.newText("Scene "..self.id,display.contentWidth/2,display.contentHeight/4,native.systemFont,32)
	self.text:addEventListener( "tap", self )
	self.textCount = display.newText("?",display.contentWidth/2,display.contentHeight*3/4,native.systemFont,24)
	self.ovButton = display.newCircle(display.contentWidth/2,display.contentHeight/2,22)
	self.ovButton:addEventListener( "tap", self )
	self.ovButton:setFillColor( 0,1,1 )
	self:insert(self.r):insert(self.textCount):insert(self.text):insert(self.ovButton)
	self.item = 0
	print("Scene "..self.id.." create")
end

function SimpleSceneClass:tap(event)
	if event.target == self.text then 
		self:gotoScene(self.tgt)
	else
		self:gotoScene("over1")
	end
	return true
end

function SimpleSceneClass:enterFrame(a,b,c)
	self.item = self.item + 1
	self.textCount.text = self.item
end

function SimpleSceneClass:setup(id,tgt) self.id = id self.tgt = tgt return self end

function SimpleSceneClass:preOpen() print("Scene "..self.id.." pre-open") end
function SimpleSceneClass:postOpen() print("Scene "..self.id.." post-open") end
function SimpleSceneClass:preClose() print("Scene "..self.id.." pre-close") end
function SimpleSceneClass:postClose() print("Scene "..self.id.." post-close") end
function SimpleSceneClass:destroy() print("Scene "..self.id.." destroy") end

function SimpleSceneClass:getTransitionType() return "flip" end

ShortDisplayClass = sm.DelayScene:new()

function ShortDisplayClass:create()
	self:insert(display.newText("And now ...",display.contentWidth/2,display.contentHeight/2,native.systemFont,24))
end
function ShortDisplayClass:nextScene() return "thirdscene" end
function ShortDisplayClass:sceneDelay() return 2500 end

DemoOverlayClass = sm.ModalOverlayScene:new()

function DemoOverlayClass:create()
	local c = display.newCircle( display.contentWidth/2,display.contentHeight/2,100 )
	c:setFillColor( 0,1,0 )
	c.strokeWidth = 2
	self:insert(c)
	c:addEventListener( "tap", self )
end

function DemoOverlayClass:tap(e)
	self:closeOverlay()
	return true
end

function DemoOverlayClass:preOpen() print("Scene Overlay pre-open") end
function DemoOverlayClass:postOpen() print("Scene Overlay post-open") end
function DemoOverlayClass:preClose() print("Scene Overlay pre-close") end
function DemoOverlayClass:postClose() print("Scene Overlay post-close") end
function DemoOverlayClass:destroy() print("Scene Overlay destroy") end

function DemoOverlayClass:getTransitionType() return "zoomInOut" end

s1inst = SimpleSceneClass:new():setup("One","secondscene")
s2inst = ShortDisplayClass:new()
s3inst = SimpleSceneClass:new():setup("3","firstscene")
ovinst = DemoOverlayClass:new()

smgr:append("firstscene",s1inst):append("secondscene",s2inst):append("thirdscene",s3inst):append("over1",ovinst)
smgr:gotoScene("firstScene")


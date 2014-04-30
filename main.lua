--[[

																			Scene Manager Test
--]]

display.setStatusBar( display.HiddenStatusBar )
sm = require("system.scenemgr")
smgr = sm.SceneManager:new()																				-- create a new scene manager

SceneClass = sm.Scene:new() 																				-- create a new scene.

function SceneClass:create()
	local vg = self:getViewGroup()
	self.r = display.newRect(10,10,display.contentWidth-20,display.contentHeight-20)
	self.r.anchorX, self.r.anchorY = 0,0
	self.r:setFillColor( 0.4,0,0 ) self.r.strokeWidth = 42 self.r:setStrokeColor(0,0,1)
	self.text = display.newText("Scene "..self.id,display.contentWidth/2,display.contentHeight/4,native.systemFont,32)
	self.text:addEventListener( "tap", self )
	self.textCount = display.newText("?",160,400,native.systemFont,24)
	self.ovButton = display.newCircle(160,360,22)
	self.ovButton:addEventListener( "tap", self )
	self.ovButton:setFillColor( 0,0,1 )
	self:insert(self.r):insert(self.textCount):insert(self.text):insert(self.ovButton)
	self.item = 0
	print("Scene "..self.id.." create")
end

function SceneClass:tap(event)
	if event.target == self.text then 
		self:gotoScene(self.tgt)
	else
		self:gotoScene("over1")
	end
	return true
end

function SceneClass:enterFrame(a,b,c)
	self.item = self.item + 1
	self.textCount.text = self.item
end

function SceneClass:setup(id,tgt) self.id = id self.tgt = tgt return self end

function SceneClass:preOpen() print("Scene "..self.id.." pre-open") end
function SceneClass:postOpen() print("Scene "..self.id.." post-open") end
function SceneClass:preClose() print("Scene "..self.id.." pre-close") end
function SceneClass:postClose() print("Scene "..self.id.." post-close") end
function SceneClass:destroy() print("Scene "..self.id.." destroy") end

function SceneClass:getTransitionType() return "flip" end

AutoClass = sm.DelayScene:new()

function AutoClass:create()
	self:insert(display.newText("And now ...",160,320,native.systemFont,24))
end
function AutoClass:nextScene() return "thirdscene" end
function AutoClass:sceneDelay() return 2500 end

OvScClass = sm.ModalOverlayScene:new()

function OvScClass:create()
	local c = display.newCircle( 160,240,100 )
	c:setFillColor( 0,1,0 )
	c.strokeWidth = 2
	self:insert(c)
	c:addEventListener( "tap", self )
end

function OvScClass:tap(e)
	self:closeOverlay()
	return true
end

function OvScClass:preOpen() print("Scene Overlay pre-open") end
function OvScClass:postOpen() print("Scene Overlay post-open") end
function OvScClass:preClose() print("Scene Overlay pre-close") end
function OvScClass:postClose() print("Scene Overlay post-close") end
function OvScClass:destroy() print("Scene Overlay destroy") end

function OvScClass:getTransitionType() return "zoomInOut" end

s1inst = SceneClass:new():setup("One","secondscene")
s2inst = AutoClass:new()
s3inst = SceneClass:new():setup("3","firstscene")
ovinst = OvScClass:new()

smgr:append("firstscene",s1inst):append("secondscene",s2inst):append("thirdscene",s3inst):append("over1",ovinst)
smgr:gotoScene("firstScene")


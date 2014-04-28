--[[

																			Scene Manager Test
--]]
display.setStatusBar( display.HiddenStatusBar )
transitionMgr = require("transitions")
sm = require("scenemgr")
print(transitionMgr)
smgr = sm.SceneManager:new(transitionMgr)																	-- create a new scene manager

SceneClass = sm.Scene:new() 																					-- create a new scene.

function SceneClass:create()
	local vg = self:getViewGroup()
	self.r = display.newRect(10,10,display.contentWidth-20,display.contentHeight-20)
	self.r.anchorX, self.r.anchorY = 0,0
	self.r:setFillColor( 0.4,0,0 ) self.r.strokeWidth = 42 self.r:setStrokeColor(0,0,1)
	vg:insert(self.r)
	self.text = display.newText("Scene "..self.id,display.contentWidth/2,display.contentHeight/2,native.systemFont,32)
	vg:insert(self.text)
	self.text:addEventListener( "tap", self )
	print("Scene "..self.id.." create")
end

function SceneClass:tap(e)
	self:gotoScene(self.tgt)
	return true
end

function SceneClass:setup(id,tgt) self.id = id self.tgt = tgt return self end

function SceneClass:preOpen() print("Scene "..self.id.." pre-open") end
function SceneClass:postOpen() print("Scene "..self.id.." post-open") end
function SceneClass:preClose() print("Scene "..self.id.." pre-close") end
function SceneClass:postClose() print("Scene "..self.id.." post-close") end
function SceneClass:destroy() print("Scene "..self.id.." destroy") end

function SceneClass:getTransitionType() return "slideright" end

s1inst = SceneClass:new():setup("One","secondscene")
s2inst = SceneClass:new():setup("Second one","firstscene")

smgr:append("firstscene",s1inst):append("secondscene",s2inst)
smgr:gotoScene("firstScene")


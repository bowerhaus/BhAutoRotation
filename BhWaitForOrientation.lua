--[[ 
BhWaitForOrientation.lua

If the device is not in the requested orientation, puts up a rotation indicating that it should be rotated.
Ignores other events until the correct orientation is assumed, then a supplied completion function and dismisses
itself from the screen.
 
MIT License
Copyright (C) 2012. Andy Bower, Bowerhaus LLP

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]
require "BhAutoRotation"
require "BhHelpers"

Event.ORIENTATION_CORRECT="orientationCorrect"

BhWaitForOrientation=Core.class(Sprite)

function BhWaitForOrientation:cancel()
	-- Dismiss from screen. Does not call completion function.
	self.orientator:removeEventListener(Event.ORIENTATION_CHANGED, self.onOrientationChanged, self)
	self:removeEventListener(Event.MOUSE_DOWN, self.onIgnoreTouches, self)
	self:removeEventListener(Event.TOUCHES_BEGIN, self.onIgnoreTouches, self)
	self:removeFromParent()
	collectgarbage()
end

function BhWaitForOrientation:onOrientationChanged(event)
	if event.orientation==self.requestedOrientation then
		-- The correct orientation has been assumed. Call the completion function and dismiss.
		self.callback(self.target)
		self:cancel()
	else	
		self:showGraphic(event.orientation)
	end
end

function BhWaitForOrientation:onIgnoreTouches(event)
	event:stopPropagation()
end

function BhWaitForOrientation:onMouseDown(event)
	if not (self:hitTestPoint(event.x, event.y)) then
		self:cancel()
	end
	event:stopPropagation()
end

local rotationOps=
	{
	portrait={ landscapeRight="rotateRightToLandscape", landscapeLeft="rotateLeftToLandscape", portraitUpsideDown="rotateRightToPortrait" },
	portraitUpsideDown= { landscapeRight="rotateLeftToLandscape", landscapeLeft="rotateRightToLandscape", portrait="rotateRightToPortrait" },
	landscapeLeft= { portrait="rotateRightToPortrait", portraitUpsideDown="rotateLeftToPortrait", landscapeRight="rotateRightToLandscape"} ,
	landscapeRight= { portrait="rotateLeftToPortrait", portraitUpsideDown="rotateRightToPortrait", landscapeLeft="rotateRightToLandscape" },
	}
	
function BhWaitForOrientation:showGraphic(currentOrientation)
	print (currentOrientation, self.requestedOrientation)
	local rotationMode=rotationOps[currentOrientation][self.requestedOrientation]
	local rotationGraphic=self.rotationImages[rotationMode]
	if self.image then	
		self.image:removeFromParent()
	end

	self.image=Bitmap.bhLoad(rotationGraphic)
	self.image:setAnchorPoint(0.5, 0.5)
	self.image:setPosition(application:getContentWidth()/2, application:getContentHeight()/2)
	self:addChild(self.image)
end

function BhWaitForOrientation:init(requestedOrientation, orientator, callback, target, optGraphics )
	self.requestedOrientation=requestedOrientation
	self.callback=callback
	self.target=target
	self.orientator=orientator
	self.orientator:addEventListener(Event.ORIENTATION_CHANGED, self.onOrientationChanged, self)
	
	-- Check if existing orientation is correct?
	local currentOrientation=application:getOrientation()
	if currentOrientation==requestedOrientation then
		self.callback(self.target)
		self:cancel()
		return
	end
	
	-- Default graphics images if not supplied
	if optGraphics==nil then optGraphics= {
			rotateRightToPortrait="Images/BhRotateRightToPortrait",
			rotateLeftToPortrait="Images/BhRotateLeftToPortrait",
			rotateRightToLandscape="Images/bhRotateRightToLandscape",
			rotateLeftToLandscape="Images/bhRotateLeftToLandscape"}
	end
	self.rotationImages=optGraphics
	self:showGraphic(currentOrientation)
	
	self:addEventListener(Event.MOUSE_DOWN, self.onMouseDown, self)
	self:addEventListener(Event.TOUCHES_BEGIN, self.onIgnoreTouches, self)
	
	stage:addChild(self)
end
--[[ 
BhAutoRotation.lua

A class that uses the accelerometer to detect the orientation of the device and uses this
to change the orientation of the application.

Example usage:
	BhAutoRotation.new(0.6, 0.1)
 
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

BhAutoRotation = Core.class(Sprite)

function BhAutoRotation:getContentSize()
	local cw, ch=application:getContentWidth(), application:getContentHeight()
	local max=math.max(cw, ch)
	local min=math.min(cw, ch)
	local orientation=self:getGenericOrientation()
	if orientation==Application.PORTRAIT then
		return min, max
	else
		return max, min
	end
end

function BhAutoRotation:getContentCenter()
	local cx, cy=self:getContentSize()
	return cx/2, cy/2
end

function BhAutoRotation:genericOrientationFor(actualOrientation)
	if actualOrientation==Application.LANDSCAPE_LEFT or 
		actualOrientation==Application.LANDSCAPE_RIGHT then
		return Application.LANDSCAPE
	end
	return Application.PORTRAIT
end

function BhAutoRotation:getGenericOrientation()
	-- Return a suitable generic orientation (i.e. "portrait" or "landscape" that represents
	-- the current state of the device. 
	
	-- First try to get the real orientation. If the device is flat this may be nil.
	local current=self:getCurrentOrientation()
	if current then
		-- Use the real orientation
		return self:genericOrientationFor(current)
	end
	
	-- Work out a suitable default for when the device is held flat.
	if application:getContentHeight()>application:getContentWidth() then
		return Application.PORTRAIT
	end
	return Application.LANDSCAPE
end

function BhAutoRotation:getCurrentOrientation()
	local x, y, z=application:getAccelerometer()	

	-- Take 30 period exponential moving avg of x and y accelerations
	-- a=2/(n+1)
	if self.xavg==0 then self.xavg=x end
	if self.yavg==0 then self.yavg=y end
	self.xavg=self.xavg+0.645*(x-self.xavg)
	self.yavg=self.yavg+0.645*(y-self.yavg)
	
	local thisOrientation
	if math.abs(self.xavg)<(self.threshold-self.hysteresis) then
		if self.yavg>self.threshold then
			thisOrientation=Application.PORTRAIT_UPSIDE_DOWN
		end
		if self.yavg<-self.threshold then
			thisOrientation=Application.PORTRAIT
		end
	end
	if math.abs(self.xavg)>(self.threshold+self.hysteresis) then
		if self.xavg>self.threshold then
			thisOrientation=Application.LANDSCAPE_RIGHT
		end
		if self.xavg<-self.threshold then
			thisOrientation=Application.LANDSCAPE_LEFT
		end
	end
	return thisOrientation
end

function BhAutoRotation:onEnterFrame()	
	local newOrientation=self:getCurrentOrientation()	
	if self.count==0 then		
		if newOrientation and newOrientation ~= self.currentOrientation then
			-- IMPORTANT call the actual change of orientation on the device BEFORE we ask
			-- our observers to adapt.
			application:setOrientation(newOrientation)
			
			local e=Event.new(Event.ORIENTATION_CHANGED)
			e.orientation=newOrientation
			e.genericOrientation=self:genericOrientationFor(newOrientation)
			e.source=self
			self:dispatchEvent(e)
			self.currentOrientation=newOrientation
		end
		self.count=10
	end
	self.count=self.count-1
end

function BhAutoRotation:start()
	-- Restart orientation monitoring after a stop()
	self:addEventListener(Event.ENTER_FRAME, self.onEnterFrame, self)
	
	-- Force a reorientation
	self.count=0
	self.currentOrientation=nil
end

function BhAutoRotation:stop()
	-- Call stop() to fix current orientation.
	-- Also call if you wish to release the BhAutoRotation object
	self:removeEventListener(Event.ENTER_FRAME, self.onEnterFrame, self)
end

function BhAutoRotation:init(threshold, hysteresis)
	-- The (threshold) should be a number between 0 and 1. The lower the value the more sensitive the object
	-- will be to a tilt. Higher values will be less sensitive but also may require the device to be held
	-- more upright in order to detect an orientation change. The threshold defaults to 0.5 if not explicitly
	-- supplied. (hysteresis) is an optional parameter providing an hysteresis factor either size of threshold.
	-- It is set to 0.1 if not explicitly defined.
	
	if threshold==nil then	
		threshold=0.5
	end
	self.threshold=threshold
	if hysteresis==nil then	
		hysteresis=0.1
	end
	self.hysteresis=hysteresis

	self.xavg=0
	self.yavg=0
	self.count=0
	
	Event.ORIENTATION_CHANGED="orientationChanged"
	Application.LANDSCAPE="landscape"
	
	self:start()
end
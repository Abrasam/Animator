Element = {}

function Element:new(x, y, tex, w, h)
	local fields = {x=x,y=y,w=w or (tex ~= nil and tex:getWidth() or nil),h=h or tex ~= nil and tex:getHeight() or nil,tex=tex,children={},inside=false,enabled=true}
	self.__index = self
	return setmetatable(fields, self)
end

function Element:update(dt)
	if not self.enabled then return end
	local mx,my = love.mouse.getPosition()
	if  mx < self.x + self.w and mx > self.x and my < self.y + self.h and my > self.y then
		if not self.inside then
			self:enter()
			self.inside = true
		end
	else
		if self.inside then
			self.inside = false
			self:exit()
		end
	end
end

function Element:draw()
	--print(self.enabled)
	if not self.enabled then return end
	if self.tex then
		love.graphics.draw(self.tex,self.x,self.y)
	end
end

function Element:enter()
	--print("enter")
end

function Element:exit()
	--print("exit")
end

function Element:clicked(x,y,b)
	if x > self.x and x < self.x+self.w and y > self.y and y < self.y+self.h then
		return true
	end
	return false
end

function Element:unclicked(x,y,b)
	if x > self.x and x < self.x+self.w and y > self.y and y < self.y+self.h then
		return true
	end
	return false
end

function Element:key(k)

end

function Element:enable()
	self.enabled = true
	for i=1,#self.children do
		self.children[i]:enable()
	end
end

function Element:disable()
	self.enabled = false
	for i=1,#self.children do
		self.children[i]:disable()
	end
end

Button = Element:new()

function Button:new(x, y, tex, callback)
	local fields = Element.new(self, x,y,tex)
	fields.callback=callback
	self.__index = self
	return setmetatable(fields, self)
end

function Button:clicked(x,y,b) --b = mouse button
	if Element.clicked(self,x,y,b) then
		self.callback(b,self)
		return true
	end
	return false
end

function Button:draw()
	if self.inside then
		love.graphics.setColor(0.5, 0.5, 0.5)
	else
		love.graphics.setColor(0.7, 0.7, 0.7)
	end
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	love.graphics.setColor(1,1,1)
	Element.draw(self)
end

Slider = Element:new()

function Slider:new(label, x, y, min, max, step, default, w, h)
	local fields = Element.new(self, x, y, nil, w or 128, h or 32)
	fields.min = min
	fields.max = max
	fields.step = step
	fields.value = default and (default-min)/(max-min) or 0
	fields.text = love.graphics.newText(font, label)
	return fields
end

function Slider:update(dt)
	if love.mouse.isDown(1) then
		local mx,my = love.mouse.getPosition()
		if Element.clicked(self, mx, my, 1) then
			self.value = (mx - self.x)/self.w
		end
	end
	Element.update(self, dt)
end

function Slider:clicked(x, y, b)
	if Element.clicked(self, x, y, b) then
		if b == 2 then
			self.value = 0
		end
	end
end

function Slider:draw()
	if self.inside then
		love.graphics.setColor(0.6,0.6,0.6)
	else
		love.graphics.setColor(0.5,0.5,0.5)
	end
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	love.graphics.setColor(0.2,0.2,0.2)
	love.graphics.rectangle("fill", self.x, self.y, self.value*self.w, self.h)
	love.graphics.setColor(0,0,0)
	local value = self.value*(self.max-self.min)+self.min
	love.graphics.print(self.step and math.floor(value+0.5) or string.format("%.2f",value),self.x+self.w,self.y)
	love.graphics.setColor(1,1,1)
	love.graphics.draw(self.text, self.x+4, self.y+4)
end

function Slider:get()
	local value = self.value*(self.max-self.min)+self.min
	return self.step and math.floor(value+0.5) or value
end

function Slider:set(value)
	self.value = (value-self.min)/(self.max-self.min)
end

Canvas = Element:new()

function Canvas:new(x, y, tex)
	local fields = Element.new(self, x, y, tex)
	fields.origin = {x=tex:getWidth()/2,y=tex:getHeight()/2}
	fields.drag = nil
	return fields
end

function Canvas:clicked(x,y,b)
	if b == 1 then --left -> drag
		self.drag = {x=x-self.x,y=y-self.y}
	elseif b == 2 then -- right -> origin
		self.origin = {x=x-self.x,y=y-self.y}
	end
end

function Canvas:unclicked(x,y,b)
	if b == 1 then --left -> drag
		if self.drag then
			local rel = {x=x-self.x,y=y-self.y}
			local min = {x=math.min(self.drag.x,rel.x),y=math.min(self.drag.y,rel.y)}
			local max = {x=math.max(self.drag.x,rel.x),y=math.max(self.drag.y,rel.y)}
			table.insert(sprites, 1, {origin={x=self.origin.x-min.x,y=self.origin.y-min.y}, quad=love.graphics.newQuad(min.x,min.y,max.x-min.x,max.y-min.y, self.tex:getWidth(), self.tex:getHeight())})
			self.drag = nil
		end
	end
end

function Canvas:draw()
	mouseX,mouseY = love.mouse.getPosition()
	Element.draw(self)
	love.graphics.setColor(1,0,0)
	love.graphics.circle("fill", self.x+self.origin.x,self.y+self.origin.y,5)
	if self.drag then
		love.graphics.setColor(0,0,1,0.5)
		local dragX,dragY = self.x + self.drag.x, self.y + self.drag.y
		love.graphics.rectangle("fill", dragX ,dragY, mouseX-dragX, mouseY-dragY)
	end
	love.graphics.setColor(0,0,0)
		love.graphics.printf("(Left Click + Drag) Select Sprite\t(Right Click) Set Origin\t(Up/Down) Cycle Sprites",0,love.graphics.getHeight()-font:getHeight(),love.graphics.getWidth())
	love.graphics.setColor(1,1,1)
end

List = Element:new()

function List:new(x,y,quads)
	local fields = Element.new(self,x,y,nil,0,0)
	fields.quads = quads
	fields.index = 1
	return fields
end

function List:draw()
	if #self.quads <= 0 then return end
	love.graphics.draw(source, self.quads[self.index].quad, self.x, self.y)
	love.graphics.setColor(0,1,0)
	love.graphics.circle("fill", self.x+self.quads[self.index].origin.x, self.y+self.quads[self.index].origin.y, 5)
	love.graphics.setColor(1,1,1)
end

function List:key(k)
	if #self.quads <= 0 then return end
	if k == "up" then
		self.index = self.index + 1
		while self.index > #self.quads do
			self.index = self.index - #self.quads
		end
	elseif k == "down" then
		self.index = self.index - 1
		while self.index < 1 do
			self.index = self.index + #self.quads
		end
	end
end

function List:current()
	return self.quads[self.index]
end

Component = {}

function Component:new(quad, x, y, parent, xosc, yosc, tosc, xamp, yamp, tamp, xpha, ypha, tpha) --nil parent means absolute position, t=theta
	local fields = {quad=quad, x=x,y=y, parent=parent, xosc=xosc or 0, yosc=yosc or 0, tosc=tosc or 0, xamp=xamp or 0, yamp=yamp or 0, tamp=tamp or 0, xpha=xpha or 0, ypha=ypha or 0, tpha=tpha or 0}
	self.__index = self
	return setmetatable(fields, self)
end

function Component:clicked(x, y, size)
	--x,y = x-size/2,y-size/2
	local cx,cy,w,h = self.quad.quad:getViewport()
	x,y = x+self.quad.origin.x,y+self.quad.origin.y
	if x >= self:getX()+size/2 and x < self:getX()+size/2 + w and y >= self:getY()+size/2 and y < self:getY()+size/2 + h then
		local rx,ry = x-self:getX()-size/2,y-self:getY()-size/2
		local _,_,_,a = sourcedata:getPixel(cx+rx,cy+ry)
		return a > 0
	end

	--[[print(x,y,self:getX(),self:getY(),w,h)
	if self:getX() - w/2 <= x and x < self:getX() + w/2 and self:getY() - h/2 <= y and y < self:getY() + h/2 then
		local rx,ry = x - self:getX(), y - self:getY()
		print(rx,ry)
		local _,_,_,a = sourcedata:getPixel(cx+rx,cy+ry)
		return a > 0
	end]]
	return false
end

function Component:getX()
	return self.parent and self.parent:getX() + self.x or self.x
end

function Component:getY()
	return self.parent and self.parent:getY() + self.y or self.y
end

function Component:anim(t)
	local parentx,parenty,parentrot = 0,0,0
	if self.parent then
		parentx,parenty,parentrot = self.parent:anim(t)
	end
	local rx,ry = rot(self.x+harmonic(t,duration,self.xosc,self.xpha,self.xamp),self.y+harmonic(t,duration,self.yosc,self.ypha,self.yamp),parentrot)
	self.drawx,self.drawy,self.drawrot = parentx+rx, parenty+ry, parentrot+harmonic(t,duration,self.tosc,self.tpha,self.tamp)
	return self.drawx,self.drawy,self.drawrot
end

Animation = Element:new()

function Animation:new(x, y, list)
	local fields = Element.new(self, x, y, nil, 512, 512)
	fields.components = {}
	fields.list = list
	fields.size = 256
	fields.selected = nil
	return fields
end

function Animation:key(k)
	if k == "return" then
		local comp = Component:new(self.list:current(), 0, 0, self.selected)
		table.insert(self.components, 1, comp)
		self.selected = comp
	elseif (k == "w" or k == "a" or k == "s" or k == "d") and self.selected then
		if k == "a" then
			self.selected.x = self.selected.x - (love.keyboard.isDown("lshift") and 10 or 1)
		elseif k == "d" then
			self.selected.x = self.selected.x + (love.keyboard.isDown("lshift") and 10 or 1)
		elseif k == "w" then
			self.selected.y = self.selected.y - (love.keyboard.isDown("lshift") and 10 or 1)
		elseif k == "s" then
			self.selected.y = self.selected.y + (love.keyboard.isDown("lshift") and 10 or 1)
		end
	elseif (k == "left" or k == "right") and self.selected then
		local i = tableFind(self.components, self.selected)
		if k == "right" then
			if i > 1 then
				table.remove(self.components, i)
				table.insert(self.components, i-1, self.selected)
			end
		else --k == "left" by elimination
			if i < #self.components then
				table.remove(self.components, i)
				table.insert(self.components, i+1, self.selected)
			end
		end
	elseif k == "]" then
		self.size = self.size * 2
	elseif k == "[" then
		self.size = self.size / 2
	elseif k == "delete" then
		if self.selected then
			local i = tableFind(self.components, self.selected)
			if i ~= -1 then
				table.remove(self.components, i)
			end
		end
	end
end

function Animation:clicked(x, y, b)
	for i=1,#self.components do
		if self.components[i]:clicked(x-self.x, y-self.y, self.size) then
			if b == 1 then
				self.selected = self.components[i]
				xosc:set(self.selected.xosc)
				xamp:set(self.selected.xamp)
				xpha:set(self.selected.xpha)
				yosc:set(self.selected.yosc)
				yamp:set(self.selected.yamp)
				ypha:set(self.selected.ypha)
				tosc:set(self.selected.tosc)
				tamp:set(self.selected.tamp)
				tpha:set(self.selected.tpha)
			elseif b == 2 then
				if self.components[i] ~= self.selected then
					self.selected.parent = self.components[i]
				else
					self.selected.parent = nil
				end
			end
			return
		end
	end
end

function Animation:draw()
	love.graphics.print({{0,0,0},"Size: "..self.size.."x"..self.size},self.x,self.y-font:getHeight())
	if not playing then
		for i=#self.components,1,-1 do
			if self.selected == self.components[i] then
				love.graphics.setColor(0,1,0)
			end
			love.graphics.draw(source, self.components[i].quad.quad, self.size/2 + self.x + self.components[i]:getX(), self.size/2 + self.y + self.components[i]:getY(), 0, 1, 1, self.components[i].quad.origin.x, self.components[i].quad.origin.y)
			love.graphics.setColor(1,1,1)	
		end
	else
		for i=1,#self.components do
			local leaf = true
			for j=1,#self.components do
				if self.components[j].parent == self.components[j] then
					leaf = false
				end
			end
			if leaf then
				self.components[i]:anim(t)
			end
		end
		for i=#self.components,1,-1 do
			love.graphics.draw(source, self.components[i].quad.quad, self.size/2 + self.x + self.components[i].drawx, self.size/2 + self.y + self.components[i].drawy, self.components[i].drawrot, 1, 1, self.components[i].quad.origin.x, self.components[i].quad.origin.y)
		end
	end
	love.graphics.setColor(0,0,0)
	love.graphics.rectangle("line", self.x, self.y, self.size, self.size)
	love.graphics.printf("(Enter) Add Entity\t(Left) Move Back\t(Right) Move Forward\t(Delete) Remove Item\t(Square Brackets) Change Canvas Size\t(WASD) Move\n(Shift) Fast Move\t(Left Click) Select\t (Right Click) Reparent\t (Up/Down) Cycle Sprites",0,love.graphics.getHeight()-font:getHeight()*2,love.graphics.getWidth())
	love.graphics.setColor(1,1,1)	
end

function Animation:update(dt)
	if self.selected then
		duration = time:get()
		self.selected.xosc = xosc:get()
		self.selected.xamp = xamp:get()
		self.selected.xpha = xpha:get()
		self.selected.yosc = yosc:get()
		self.selected.yamp = yamp:get()
		self.selected.ypha = ypha:get()
		self.selected.tosc = tosc:get()
		self.selected.tamp = tamp:get()
		self.selected.tpha = tpha:get()
	end
	Element.update(self, dt)
end

function Animation:save()
	local FPS = 30
	local dim = smollest(time:get()*FPS)
	local dx,dy = dim,time:get()*FPS/dim
	local canvas = love.graphics.newCanvas(dx*self.size,dy*self.size)
	love.graphics.setCanvas(canvas)
	for f=0,time:get()*FPS-1 do
		local t = f/FPS
		for i=1,#self.components do
			local leaf = true
			for j=1,#self.components do
				if self.components[j].parent == self.components[j] then
					leaf = false
				end
			end
			if leaf then
				self.components[i]:anim(t)
			end
		end
		local offX,offY=f%dx,math.floor(f/dx)
		for i=#self.components,1,-1 do
			love.graphics.draw(source, self.components[i].quad.quad, self.size/2 + offX*self.size + self.components[i].drawx, self.size/2 + offY*self.size + self.components[i].drawy, self.components[i].drawrot, 1, 1, self.components[i].quad.origin.x, self.components[i].quad.origin.y)
		end
	end
	love.graphics.setCanvas()
	canvas:newImageData():encode("png", "out.png")
end
require "util"
require "ui"

function love.load()
	font = love.graphics.newFont("Sofija.ttf",32)
	fontsmall = love.graphics.newFont("Sofija.ttf",16)
	love.filesystem.write("readme.txt","Save source.png in this folder.")
	love.graphics.setFont(font)
	changeMode("main")
	t = 0
end

function changeMode(new)
	mode = new
	if new == "main" then
		source = nil
		elements = {
						Button:new(64, 64, love.graphics.newText(font, {{0,0,0},"Import 'source.png'"}), function() changeMode("extract") end)
					}
	elseif new == "extract" then
		if not love.filesystem.getInfo("source.png") then
			changeMode("main")
			return
		end
		local data = love.filesystem.newFileData("source.png")
		sourcedata = love.image.newImageData(data)
		source = love.graphics.newImage(sourcedata)
		sprites = {}
		elements = {
						Button:new(64, 64, love.graphics.newText(font, {{0,0,0},"Animate"}), function() changeMode("animate") end),
						Canvas:new(64, 128, source),
						List:new(love.graphics.getWidth()-512,love.graphics.getHeight()/2-256, sprites, source)
					}
	elseif new == "animate" then
		local list = List:new(love.graphics.getWidth()-512,love.graphics.getHeight()/2-256, sprites, source)
		local i = 2
		time = Slider:new("time", 64, 128+i*32, 1, 10, true, 1) i = i + 1
		xosc = Slider:new("xosc", 64, 128+i*32, 0, 10, true) i = i + 1
		xamp = Slider:new("xamp", 64, 128+i*32, 0, 256, false) i = i + 1
		xpha = Slider:new("xpha", 64, 128+i*32, 0, 1, false) i = i + 1
		yosc = Slider:new("yosc", 64, 128+i*32, 0, 10, true) i = i + 1
		yamp = Slider:new("yamp", 64, 128+i*32, 0, 256, false) i = i + 1
		ypha = Slider:new("ypha", 64, 128+i*32, 0, 1, false) i = i + 1
		tosc = Slider:new("tosc", 64, 128+i*32, 0, 10, true) i = i + 1
		tamp = Slider:new("tamp", 64, 128+i*32, 0, 2*math.pi, false) i = i + 1
		tpha = Slider:new("tpha", 64, 128+i*32, 0, 1, false) i = i + 1
		local anim = Animation:new(256, 256, list)
		elements = {
						Button:new(64, 64, love.graphics.newText(font, {{0,0,0},"Save"}), function () anim:save() end),
						Button:new(64, 128, love.graphics.newText(font, {{0,0,0},"Play/Pause"}), function () playing = not playing end),
						anim,
						list,
						time,
						xosc,xamp,xpha,
						yosc,yamp,ypha,
						tosc,tamp,tpha,
					}
		selected = nil
	end
end

function love.keypressed(k)
	for i=1,#elements do
		elements[i]:key(k)
	end
end

function love.mousepressed(x, y, button)
	for i=1,#elements do
		if elements[i]:clicked(x,y,button) then
			return
		end
	end
end

function love.mousereleased(x, y, button)
	for i=1,#elements do
		if elements[i]:unclicked(x,y,button) then
			return
		end
	end
end

function love.update(dt)
	t = t + dt
    for i=1,#elements do
    	elements[i]:update(dt)
    end
end

function love.draw()
	love.graphics.clear(1,1,1,1)
    for i=1,#elements do
    	elements[i]:draw()
    end
end
-- Lua storyboard handler
-- Part of Live Simulator: 2
-- See copyright notice in main.lua

local AquaShine = AquaShine
local love = love
local StoryboardBase = require("storyboard_base")
local LuaStoryboard = {}

-- Used to isolate function and returns table of all created global variable
local function isolate_globals(func)
	local env = {}
	local created_vars = {}
	
	for n, v in pairs(_G) do
		env[n] = v
	end
	
	setmetatable(env, {
		__newindex = function(a, b, c)
			created_vars[b] = c
			rawset(a, b, c)
		end
	})
	setfenv(func, env)
	func()
	
	return created_vars
end

-- List of whitelisted libraries for storyboard
local allowed_libs = {
	JSON = require("JSON"),
	tween = require("tween"),
	EffectPlayer = require("effect_player"),
	luafft = isolate_globals(love.filesystem.load("luafft.lua")),
	string = string,
	table = table,
	math = math,
	coroutine = coroutine,
	bit = require("bit"),
	os = {
		time = os.time,
		clock = os.clock
	}
}

local function setup_env(story, lua)
	AquaShine.Log("LuaStoryboard", "Initializing environment")
	
	-- Copy environment
	local env = {
		LoadVideo = function(path)
			if story.BeatmapDir then
				local _, x = pcall(AquaShine.LoadVideo, story.BeatmapDir..path)
				
				if _ then
					story.VideoList[#story.VideoList + 1] = x
					
					return x
				end
			end
			
			return nil
		end,
		LoadImage = function(path)
			if story.AdditionalData[path] then
				return love.graphics.newImage(story.AdditionalData[path])
			end
			
			if story.BeatmapDir then
				local _, x = pcall(love.graphics.newImage, story.BeatmapDir..path)
				if _ then return x end
			end
			
			return nil
		end,
		ReadFile = function(path)
			if story.AdditionalData[path] then
				return story.AdditionalData[path]:getString()
			end
			
			if story.BeatmapDir then
				return love.filesystem.read(story.BeatmapDir..path), nil
			end
			
			return nil
		end,
		DrawObject = love.graphics.draw,
		LoadShader = love.graphics.newShader,
		LoadFont = function(path, size)
			if not(path) then
				return AquaShine.LoadFont("MTLmr3m.ttf", size or 14)
			end
			
			if story.BeatmapDir then
				local _, x = pcall(love.graphics.newFont, story.BeatmapDir..path, size or 12)
				
				if _ then
					return x
				end
				
			end
			
			return nil
		end
	}
	
	for n, v in pairs(_G) do
		env[n] = v
	end
	
	if story.AdditionalFunctions then
		for n, v in pairs(story.AdditionalFunctions) do
			env[n] = v
		end
	end
	
	-- Isolated love
	env.love = {
		graphics = {
			arc = love.graphics.arc,
			circle = love.graphics.circle,
			clear = function(...)
				assert(love.graphics.getCanvas() ~= AquaShine.MainCanvas, "love.graphics.clear on real screen is not allowed!")
				love.graphics.clear(...)
			end,
			draw = love.graphics.draw,
			ellipse = love.graphics.ellipse,
			line = love.graphics.line,
			points = love.graphics.points,
			polygon = love.graphics.polygon,
			print = love.graphics.print,
			printf = love.graphics.printf,
			rectangle = love.graphics.rectangle,
			
			newCanvas = love.graphics.newCanvas,
			newFont = env.LoadFont,
			newImage = RelativeLoadImage,
			newMesh = love.graphics.newMesh,
			newParticleSystem = love.graphics.newParticleSystem,
			newShader = love.graphics.newShader,
			newSpriteBatch = love.graphics.newSpriteBatch,
			newQuad = love.graphics.newQuad,
			newVideo = RelativeLoadVideo,
			
			setBlendMode = love.graphics.setBlendMode,
			setCanvas = function(canvas)
				love.graphics.setCanvas(canvas or AquaShine.MainCanvas)
			end,
			setColor = love.graphics.setColor,
			setColorMask = love.graphics.setColorMask,
			setLineStyle = love.graphics.setLineStyle,
			setLineWidth = love.graphics.setLineWidth,
			setScissor = love.graphics.setScissor,
			setShader = love.graphics.setShader,
			setFont = love.graphics.setFont,
			
			pop = function()
				if story.PushPopCount > 0 then
					love.graphics.pop()
					story.PushPopCount = story.PushPopCount - 1 
				end
			end,
			push = function()
				love.graphics.push()
				story.PushPopCount = story.PushPopCount + 1
			end,
			rotate = love.graphics.rotate,
			scale = love.graphics.scale,
			shear = love.graphics.shear,
			translate = love.graphics.translate
		},
		math = love.math,
		timer = love.timer
	}
	
	-- Remove some datas
	env._G = env
	env.io = nil
	env.os = nil
	env.debug = nil
	env.loadfile = nil
	env.dofile = nil
	env.package = nil
	env.file_get_contents = nil
	env.arg = nil
	env.AquaShine = nil
	env.NoteImageCache = nil
	env.dt = nil
	env.gcinfo = nil
	env.module = nil
	env.jit = nil
	env.collectgarbage = nil
	env.getfenv = nil
	env.require = function(libname)
		return (assert(allowed_libs[libname], "require is limited in storyboard lua script"))
	end
	env.print = function(...)
		local a = {}
		
		for n, v in ipairs({...}) do
			a[#a + 1] = tostring(v)
		end
		
		AquaShine.Log("storyboard", table.concat(a, "\t"))
	end
	
	setfenv(lua, env)
	
	-- Call state once
	AquaShine.Log("LuaStoryboard", "Initializing Lua script storyboard")
	local luastate = coroutine.wrap(lua)
	luastate()
	AquaShine.Log("LuaStoryboard", "Lua script storyboard initialized")
	
	if env.Initialize then
		AquaShine.Log("LuaStoryboard", "Lua script storyboard initialize function call")
		env.Initialize()
		AquaShine.Log("LuaStoryboard", "Lua script storyboard initialize function called")
	end
	
	story.StoryboardLua = {
		luastate,							-- The lua storyboard
		env,								-- The global variables
		env.Update or env.Initialize,		-- New DEPLS2 storyboard or usual DEPLS storyboard
	}
end

local function storyboard_draw(this, deltaT)
	love.graphics.push("all")
	
	local status, msg
	if this.StoryboardLua[3] then
		status, msg = pcall(this.StoryboardLua[2].Update, deltaT)
	else
		status, msg = pcall(this.StoryboardLua[1], deltaT)
	end
	
	-- Rebalance push/pop
	for i = 1, this.PushPopCount do
		love.graphics.pop()
	end
	this.PushPopCount = 0
	
	-- Cleanup
	love.graphics.pop()
	
	if status == false then
		AquaShine.Log("LuaStoryboard", "Storyboard Error: %s", msg)
	end
end

local function storyboard_setfiles(this, datas)
	this.AdditionalData = assert(type(datas) == "table" and datas, "bad argument #1 to 'SetAdditionalFiles' (table expected)")
end

local function storyboard_cleanup(this)
	for i = 1, #this.VideoList do
		this.VideoList[i]:pause()
	end
	
	this.VideoList = nil
	this.StoryboardLua = nil
end

local function storyboard_callback(this, name, ...)
	local callback_name = "On"..name
	
	if this.StoryboardLua[3] and this.StoryboardLua[2][callback_name] then
		local a, b = pcall(this.StoryboardLua[2][callback_name], ...)
		
		if a == false then
			AquaShine.Log("LuaStoryboard", "Storyboard Error %s: %s", callback_name, b)
		end
	end
end

local function storyboard_initialize(this, export)
	this.AdditionalFunctions = export
	
	setup_env(this, this.Lua)
end

function LuaStoryboard.LoadString(str, dir, export)
	local story = StoryboardBase.CreateDummy()
	local lua = type(str) == "function" and str or loadstring(str)
	
	-- Set functions
	story.Initialize = storyboard_initialize
	story.Draw = storyboard_draw
	story.SetAdditionalFiles = storyboard_setfiles
	story.Cleanup = storyboard_cleanup
	story.Callback = storyboard_callback
	
	story.Lua = lua
	story.BeatmapDir = dir
	story.AdditionalData = {}
	story.AdditionalFunctions = export
	story.VideoList = {}
	story.PushPopCount = 0
	
	return story
end

function LuaStoryboard.Load(file, export)
	return LuaStoryboard.LoadString(love.filesystem.load(file), file:sub(1, file:find("[^/]+$") - 1), export)
end

return LuaStoryboard
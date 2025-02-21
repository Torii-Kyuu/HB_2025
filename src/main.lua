-- С днём рождения ((upd: очень) прошедшим, ауч, сори)
--[[
	Луа забавный язык
	и в качестве подарка
	будет поделка на нём
--]]

-- это один из тех языков где все числа это даблы ^-^

BULLET_SPEED = 300


--[[
	ВЕКТОР (2)
	потому что без него как-то грустно

	какие-то 3rd party есть но хотелось свой
--]]

Vec2 = {} -- Объекты тут примерно как в жабоскрипте

function Vec2:new(x, y)
	local newObj = {x=x, y=y, length=math.sqrt(x*x+y*y)}
	self.__index = self -- self здесь это Vec2, но в теории это может быть его наследник..
	return setmetatable(newObj, self)
end

function Vec2:xy()
	return self.x, self.y
end

-- перегрузка операторов как в питоне хехе
Vec2.__add = function(a, b) return Vec2:new(a.x+b.x, a.y+b.y) end
Vec2.__sub = function(a, b) return Vec2:new(a.x-b.x, a.y-b.y) end
Vec2.__mul = function(scale, a) return Vec2:new(scale*a.x, scale*a.y) end
Vec2.__div = function(a, div_scale) return Vec2:new(a.x/div_scale, a.y/div_scale) end
Vec2.LEFT = Vec2:new(-1, 0)
Vec2.RIGHT = Vec2:new(1, 0)
Vec2.UP = Vec2:new(0, -1)
Vec2.DOWN = Vec2:new(0, 1)

--[[
	ПУЛЯ
--]]

Bullet = {}

function Bullet:new(x, y, direction, speed)
	newObj = {x=x, y=y, direction=direction, speed=speed, r = 10, color={1, 1, 1}}
	self.__index = self
	return setmetatable(newObj, self)
end

function Bullet:update(dt)
	self.x = self.x + direction.x * self.speed * dt
	self.y = self.y + direction.y * self.speed * dt
end

function Bullet:isInvisible() -- чтобы удалять когда она выходит за пределы экрана
	if  self.x + self.r < 0 or self.x - self.r > love.graphics.getWidth() or
		self.y + self.r < 0 or self.y - self.r > love.graphics.getHeight() then
			return true
	end
	return false
end

function Bullet:draw()
	-- вместо круга тут 64-гранник хехе, т.к. он маленький у меня этого хватает для жизни

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.circle("fill", self.x, self.y, self.r, 64)

	local r, g, b = self.color -- списки можно распаковывать
	love.graphics.setColor(r, g, b, 1)
	love.graphics.circle("line", self.x, self.y, self.r, 64)
end


--[[
	ТРЕУГОЛЬНИК
	но не в целом, а конкретно для фрактала
--]]

Triangle = {}

function Triangle:new(x, y, a, direction, level)
	direction = direction or Vec2.UP
	h = math.sqrt(3)/2*a
	local p1 = Vec2:new(x, y)
	local p2 = p1 + h*direction + a/2*Vec2.LEFT
	local p3 = p1 + h*direction + a/2*Vec2.RIGHT
	newObj = {p1=p1, p2=p2, p3=p3, a=a, h=h, level=level or 0}

	self.__index = self
	return setmetatable(newObj, self)
end

function Triangle:draw(noFill)
	local x1, y1 = self.p1:xy()
	local x2, y2 = self.p2:xy()
	local x3, y3 = self.p3:xy()

	if noFill then 
		-- с основным треугольником не надо ничего делать, для него исключение
		love.graphics.setColor(1, 1, 1, 1)

		love.graphics.polygon("line", x1, y1, x2, y2, x3, y3)
		return
	end
	
	local r, g, b = HSV(math.fmod(self.level/(fractal_level + 1)+2/3, 1), 1, 1)
	love.graphics.setColor(r, g, b, 1)

	mode = "line"
	for _, bullet in ipairs(bullets) do
		if not self:isInsideDown(bullet.x, bullet.y) then 
			goto continue -- ЛОЛ тут есть goto вот прям вот так
			-- НО нет continue как ключевого слова. break есть, continue нету
		end

		if bullet.triangle == self then
			goto continue
		end

		-- здесь мы нашли пулю которая внутри нас и не знает об этом

		bullet.triangle = self -- теперь знает

		local sound = bynk:clone()
		sound:setPitch(notes[1 + math.fmod(self.level*13, #notes)])
		sound:setVolume((self.level + 1)/(fractal_level + 1))
		sound:play() -- быньк соответствующий уровню

		bullet.speed = (1 - self.level/(fractal_level + 1)) * BULLET_SPEED
		bullet.color = {r, g, b}
		mode = "fill"
		::continue::
	end
	love.graphics.polygon(mode, x1, y1, x2, y2, x3, y3)
end

function Triangle:isInsideDown(x, y)
	-- штука работает только для равносторонних треугльников направленных вниз..
	local down = self.p1.y
	local up = down - self.h
	if y < up or y > down then return false end

	local left = self.p2.x + (y - self.p2.y)/math.sqrt(3)
	local right = self.p3.x - (y - self.p3.y)/math.sqrt(3)
	if x < left or x > right then return false end

	return true
end

-- Серпинский
function buildFractal(level, x, y, a)
	local h = math.sqrt(3)/2*a
	local fractal = {Triangle:new(x, y + h, a/2, Vec2.UP, level)}
	if level == 0 then
		return fractal
	end

	local part = {}
	local starts = {
		Vec2:new(x, y),
		Vec2:new(x - a/4, y + h/2),
		Vec2:new(x + a/4, y + h/2),
	} -- этот "список"
	-- это объект с ключами 1,2,3
	-- отсчёт не с 0, а с 1, да

	for _, vec in ipairs(starts) do
		part = buildFractal(level - 1, vec.x, vec.y, a/2)
		table.move(part, 1, #part, #fractal + 1, fractal) -- приятная штука, прям мув
	end

	return fractal
end


function love.load() 
	love.window.setFullscreen(true)
	width, height = love.graphics.getWidth(), love.graphics.getHeight()

	love.graphics.setFont(love.graphics.newFont("Fira Code Light Nerd Font Complete Mono.ttf"))

	-- быньк. Делает быньк.
	bynk = love.audio.newSource("быньк.mp3", "static")

	-- пингвиньчик
	ava = love.graphics.newImage("ava.png")
	length = 90
	ava_pos = Vec2:new(length, length)/2
	speed = 300

	-- пули
	bullets = {}
	direction = Vec2:new(1,0) -- направление одно на всех ^-^

	-- фрактальчик
	fractal_level = 0
	start = {x = width/2, y=100, a=(height-100)}
	fractal = buildFractal(fractal_level, start.x, start.y, start.a)

	-- Пентатонический scale, на 3 октавы
	notes = {}
	for _, note in ipairs({0, 2, 4, 7, 9}) do
		table.insert(notes, math.pow(2, note/12))
		table.insert(notes, math.pow(2, note/12 - 1))
		table.insert(notes, math.pow(2, note/12 + 1))
	end
end

function love.draw()
	-- перестраиваем фрактал под количество пуль если надо
	if fractal_level ~= math.min(8, #bullets) then
		fractal_level = math.min(8, #bullets)
		fractal = buildFractal(fractal_level, start.x, start.y, start.a)
	end

	-- немного геометрии для определение направление от пингвина к мыши
	local from = ava_pos
	local mouse = Vec2:new(love.mouse.getPosition())
	direction = mouse - from
	direction = direction / direction.length
	local to = from + length * direction
	love.graphics.setColor(1,1,1,1)
	love.graphics.line(from.x, from.y, to.x, to.y)

	-- сам пингвин
	love.graphics.draw(ava, ava_pos.x-length/2, ava_pos.y-length/2)

	-- основной треугольник внутри которого фрактал
	Triangle:new(start.x, start.y, start.a, Vec2.DOWN):draw(true)

	for _, triangle in ipairs(fractal) do
		triangle:draw() -- рисуем фрактал по одному треугольнику
	end

	for _, bullet in pairs(bullets) do
		bullet:draw() -- поверх пули
	end


end



function love.update(dt)
	i = 1
	-- убираем все пули которые вышли за пределы экрана
	while true do
		if i > #bullets then break end
		bullets[i]:update(dt)
		if bullets[i]:isInvisible() then
			table.remove(bullets, i) -- это сдвигает все пули после этой на 1 назад
		else
			i = i + 1
		end			
	end

	-- классиеское управление у тебя есть 4 стороны в равными скоростями которые просто суммируются
	controls = {
		w = Vec2:new(0, -1),
		s = Vec2:new(0, 1),
		a = Vec2:new(-1, 0),
		d = Vec2:new(1, 0),
	}

	for key, direction in pairs(controls) do
		if love.keyboard.isDown(key) then
			ava_pos = ava_pos + speed * dt * direction
		end
	end
end

function love.mousepressed(x, y, button, istouch, presses)
	-- любоенажатие мышкой сделает быньк с частотой зависящей от горизонтального положения
	local sound = bynk:clone()
	sound:setPitch(2*x/width)
	sound:play()
end

function love.keypressed(key, scancode, isrepeat) 
	-- на пробел добавляем пулю
	if key == "space" then 
		table.insert(bullets, Bullet:new(ava_pos.x, ava_pos.y, direction, BULLET_SPEED))
	end
end

-- честно скопипащена
function HSV(h, s, v)
    if s <= 0 then return v,v,v end
    h = h*6
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0, 0, 0
    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return r+m, g+m, b+m
end
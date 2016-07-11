-- FIXME shifting is poorly handled; should check for collisions

require("code.Vector")
require("code.Square")

Tetromino = {}
Tetromino.__index = Tetromino
Tetromino.length = 8

function Tetromino.new(squares, center, grid, color)
    return setmetatable(
        {
            squares = squares,
            center = center,    -- one of the squares
            grid = grid,
            color = color or { 40, 40, 40 }
        },
    Tetromino)
end

setmetatable(Tetromino, { __call = function (t, ...) return Tetromino.new(...) end })

-- private
function Tetromino:forEachSquare(f)
    for _, sq in ipairs(self.squares) do
        f(sq)
    end
end

-- private
function Tetromino:map(f)
    local result = {}
    for _, sq in ipairs(self.squares) do
        table.insert(result, f(sq))
    end
    return result
end

-- private
function Tetromino:someSquare(p)
    for _, sq in ipairs(self.squares) do
        if p(sq) then
            return true
        end
    end
    return false
end

-- private
function Tetromino:allSquares(p)
    return not self:someSquare(not p)
end

function Tetromino:isBlocked(direction, frozenSquares)
    local function isBlocked(sq)
        return sq:isBlocked(direction, frozenSquares)
    end
    return self:someSquare(isBlocked)
end

function Tetromino:draw()
    local function drawSquare(sq)
        sq:draw(self.grid)
    end
    love.graphics.setColor(self.color)
    self:forEachSquare(drawSquare)
end

-- private
function Tetromino:translate(vector)
    local function translateSquare(sq)
        sq:translate(vector)
    end
    self:forEachSquare(translateSquare)
end

function Tetromino:moveDown()
    self:translate(directions.down)
end

-- private
function Tetromino:shift(d1, d2)    --FIXME should check for collisions
    if math.random() < 1/2 then
        self:translate(d1 / 2)
    else
        self:translate(d2 / 2)
    end
end

local function notAnInteger(x)
    return x ~= math.floor(x)
end

function Tetromino:align()
    if(notAnInteger(self.squares[0].position.x)) then
        self:shift(directions.left, directions.right)
    end
    if(notAnInteger(self.squares[0].position.y)) then
        self:shift(directions.up, directions.down)
    end
end

--[[ useless?

local function getSquareOrdinate(sq)
    return sq.position.y
end

local function getSquareAbscissa(sq)
    return sq.position.x
end

function Tetromino:height()
    local ordinates = self:map(getSquareOrdinate)
    return math.max(ordinates) + 1 - math.min(ordinates)
end

function Tetromino:width()
    local abscisses = self:map(getSquareAbscissa)
    return math.max(abscisses) + 1 - math.min(abscisses)
end

local function vectorSum(vectors)
    local result = Vector(0, 0)
    for _, v in vectors do
        result = result + v
    end
    return result
end

-- private
function Tetromino:center()
    return vectorSum(self:map(Square.getCenter)) / #squares
end
]]

-- private
function Tetromino:center()
    return self.center:getCenter()
end

-- private
function Tetromino:rotate()
    local tetrominoCenter = self:center()
    local function rotateSquare(sq)
        local posRelativeToTetrominoCenter = sq:getCenter() - tetrominoCenter
        posRelativeToTetrominoCenter:rotateCounterclockwise()
        sq:setCenter(posRelativeToTetrominoCenter + tetrominoCenter)
    end
    self:forEachSquare(rotateSquare)
    --[[ DEBUGGING
    local function isInteger(coord)
        return coord == math.floor(coord)
    end
    local function hasIntegerCoords(sq)
        return sq.position:allCoordinates(isInteger) 
    end
    assert(self:allSquares(hasIntegerCoords))
    --]]
end

local function copy(a)
    if type(a) == "table" then
        result = {}
        for k, v in pairs(a) do
            result[k] = copy(v)
        end
        return result
    else
        return a
    end
end

function Tetromino:rotateIfPossible(frozenSquares)
    local new = Tetromino(copy(self.squares))
    new:rotate()
    if new:collidesWith(frozenSquares) then
        return false
    else
        self.squares = new.squares
        return true
    end
end

function Tetromino:collidesWith(frozenSquares)
    function collides(sq)
        return frozenSquares[sq.y][sq.x]
    end
    return self:someSquare(collides)
end

function Tetromino:freezeInto(frozenSquares)
    function freeze(sq)
        frozenSquares:add(sq.position, self.color)
    end
    self:forEachSquare(freeze)
end

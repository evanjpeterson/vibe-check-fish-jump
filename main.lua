-- Simple Love2D platformer game with platforms and victory condition
-- With jumping mechanics and gravity physics

-- Define background pattern
local background = {
    squareSize = 40,       -- Size of each checkerboard square
    colors = {
        { 0.3, 0.3, 0.4 }, -- Light square
        { 0.2, 0.2, 0.3 }  -- Dark square
    }
}

-- Define the player (fish)
local player = {
    x = 150,                          -- starting x position
    y = 300,                          -- starting y position (will be adjusted to sit on the surface)
    width = 60,                       -- fish width
    height = 30,                      -- fish height
    speed = 300,                      -- horizontal movement speed (pixels per second)
    yVelocity = 0,                    -- vertical velocity
    jumpPower = -600,                 -- jump strength (negative because y-axis goes down)
    isJumping = false,                -- tracking if player is in the air
    canDoubleJump = false,            -- ability to perform a second jump
    hasDoubleJumped = false,          -- tracking if player has used double jump
    gravity = 1800,                   -- gravity acceleration (pixels per second^2)
    direction = -1,                   -- 1 for right, -1 for left (reversed now)
    bobTimer = 0,                     -- Timer for bobbing animation
    bobAmount = 3,                    -- How much to bob up and down
    colorTimer = 0,                   -- Timer for color strobing effect
    currentColor = { 0.2, 0.4, 1.0 }, -- Default blue color
    blinkTimer = 0,                   -- Timer for blinking
    blinkDuration = 0.15,             -- How long the blink lasts in seconds
    blinkInterval = 3,                -- Base time between blinks in seconds
    nextBlinkTime = 3,                -- Time until next blink
    isBlinking = false                -- Whether the fish is currently blinking
}

-- Camera system that follows the player with spring delay
local camera = {
    x = 0,           -- horizontal offset
    y = 0,           -- vertical offset
    targetX = 0,     -- target horizontal position
    targetY = 0,     -- target vertical position
    smoothSpeed = 4, -- how quickly camera follows target (higher = faster)
    worldWidth = 800 -- total width of the game world
}

-- Define the platforms (including the main surface)
local platforms = {
    -- Main surface
    { x = 0,   y = 550,   width = 800, height = 10 },
    -- Lower platforms
    { x = 200, y = 450,   width = 150, height = 10 },
    { x = 400, y = 380,   width = 150, height = 10 },
    { x = 150, y = 320,   width = 150, height = 10 },
    { x = 450, y = 250,   width = 150, height = 10 },
    { x = 300, y = 180,   width = 150, height = 10 },
    { x = 100, y = 120,   width = 150, height = 10 },
    -- Additional platforms reaching higher
    { x = 350, y = 50,    width = 150, height = 10 },
    { x = 200, y = -20,   width = 150, height = 10 },
    { x = 400, y = -90,   width = 150, height = 10 },
    { x = 150, y = -160,  width = 150, height = 10 },
    { x = 450, y = -230,  width = 120, height = 10 },
    { x = 250, y = -300,  width = 150, height = 10 },
    { x = 350, y = -370,  width = 150, height = 10 },
    { x = 180, y = -440,  width = 150, height = 10 },
    { x = 400, y = -510,  width = 120, height = 10 },
    { x = 250, y = -580,  width = 150, height = 10 },
    { x = 100, y = -650,  width = 150, height = 10 },
    { x = 300, y = -720,  width = 120, height = 10 },
    { x = 450, y = -790,  width = 150, height = 10 },
    { x = 200, y = -860,  width = 150, height = 10 },
    { x = 350, y = -930,  width = 150, height = 10 },
    { x = 150, y = -1000, width = 200, height = 10 },
    { x = 330, y = -1070, width = 150, height = 10 }
}

local surface = platforms[1]

-- Define the victory flag (on the topmost platform)
local flag = {
    x = 400,
    y = -1120,
    width = 10,
    height = 50,
    color = { 1, 0, 0 }, -- Red
    reached = false
}

-- Confetti for victory effect
local confetti = {
    particles = {},
    active = false,
    timer = 0,
    duration = 5 -- seconds for the victory effect to last
}

-- Screen shake effect
local screenShake = {
    active = false,
    duration = 1.0, -- how long the shake lasts (seconds)
    timer = 0,
    intensity = 8   -- maximum shake displacement
}

-- Create a single confetti particle
local function createConfettiParticle()
    local colors = {
        { 1, 0,   0 }, -- red
        { 0, 1,   0 }, -- green
        { 0, 0,   1 }, -- blue
        { 1, 1,   0 }, -- yellow
        { 1, 0,   1 }, -- magenta
        { 0, 1,   1 }, -- cyan
        { 1, 0.5, 0 }  -- orange
    }

    -- Generate particles in screen space, not world space
    local width, height = love.graphics.getDimensions()
    return {
        x = love.math.random(0, width),
        y = -10,
        width = love.math.random(5, 15),
        height = love.math.random(5, 15),
        xVel = love.math.random(-100, 100),
        yVel = love.math.random(100, 300),
        rotation = love.math.random() * math.pi * 2,
        rotationSpeed = love.math.random(-5, 5),
        color = colors[love.math.random(1, #colors)]
    }
end

-- Load function runs once at the beginning
function love.load()
    -- Position the player to sit on top of the surface
    player.y = surface.y - player.height * 2

    -- Seed the random number generator for blinking
    love.math.setRandomSeed(os.time())
    -- Set first blink time with some randomness
    player.nextBlinkTime = player.blinkInterval + love.math.random(-1, 1)
end

-- Check collision between two rectangles
local function checkCollision(a, b)
    return a.x < b.x + b.width and
        b.x < a.x + a.width and
        a.y < b.y + b.height and
        b.y < a.y + a.height
end

-- Trigger victory effect
local function triggerVictory()
    confetti.active = true
    confetti.timer = 0
    -- Create initial batch of confetti
    for i = 1, 200 do
        table.insert(confetti.particles, createConfettiParticle())
    end

    -- Activate screen shake
    screenShake.active = true
    screenShake.timer = 0
end

-- Update function runs every frame
function love.update(dt)
    -- Handle horizontal movement (always allowed)
    if love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
        player.direction = 1 -- Reversed: face right when moving left
    end
    if love.keyboard.isDown("right") then
        player.x = player.x + player.speed * dt
        player.direction = -1 -- Reversed: face left when moving right
    end

    -- Apply gravity
    player.yVelocity = player.yVelocity + player.gravity * dt
    player.y = player.y + player.yVelocity * dt

    -- Update camera target position to follow player
    -- Center the player horizontally and keep them in the lower portion vertically
    local screenWidth, screenHeight = love.graphics.getDimensions()
    camera.targetX = -player.x + screenWidth * 0.5
    -- Keep the player in the lower third of the screen (for vertical scrolling)
    camera.targetY = -player.y + screenHeight * 0.7

    -- Constrain horizontal camera to keep world in view
    camera.targetX = math.min(0, math.max(-camera.worldWidth + screenWidth, camera.targetX))

    -- Smooth camera movement with spring delay
    local cameraXDiff = camera.targetX - camera.x
    local cameraYDiff = camera.targetY - camera.y
    camera.x = camera.x + cameraXDiff * math.min(dt * camera.smoothSpeed, 1)
    camera.y = camera.y + cameraYDiff * math.min(dt * camera.smoothSpeed, 1)

    -- Check for collision with platforms
    player.isJumping = true -- Assume falling until proven otherwise
    for _, platform in ipairs(platforms) do
        -- Only check collision if player is above or on the platform and falling
        if player.yVelocity >= 0 and
            player.y + player.height <= platform.y + 5 and
            player.y + player.height + player.yVelocity * dt > platform.y and
            player.x + player.width > platform.x and
            player.x < platform.x + platform.width then
            player.y = platform.y - player.height
            player.yVelocity = 0
            player.isJumping = false
            player.canDoubleJump = false   -- Reset double jump when landing
            player.hasDoubleJumped = false -- Reset double jump flag
            break
        end
    end

    -- Check for collision with the flag
    if not flag.reached and checkCollision(player, flag) then
        flag.reached = true
        -- Reset color timer when victory is achieved
        player.colorTimer = 0
        triggerVictory()
    end

    -- Update screen shake effect
    if screenShake.active then
        screenShake.timer = screenShake.timer + dt
        if screenShake.timer >= screenShake.duration then
            screenShake.active = false
        end
    end

    -- Keep the player within the world bounds (horizontally)
    player.x = math.max(0, math.min(player.x, camera.worldWidth - player.width))

    -- Update bob animation when not jumping
    if not player.isJumping then
        player.bobTimer = player.bobTimer + dt * 5 -- Control bob speed
        -- No need to reset the timer, we're using sine which repeats
    end

    -- Update color strobing if victory is achieved
    if flag.reached then
        player.colorTimer = player.colorTimer + dt * 5 -- Control color change speed

        -- Create rainbow cycling effect
        local r = math.sin(player.colorTimer) * 0.5 + 0.5
        local g = math.sin(player.colorTimer + 2) * 0.5 + 0.5
        local b = math.sin(player.colorTimer + 4) * 0.5 + 0.5

        player.currentColor = { r, g, b }
    end

    -- Update blinking animation
    player.blinkTimer = player.blinkTimer + dt

    -- Handle blinking state
    if player.isBlinking then
        -- If blink duration is over, stop blinking
        if player.blinkTimer >= player.blinkDuration then
            player.isBlinking = false
            player.blinkTimer = 0
            -- Set next blink with random variation
            player.nextBlinkTime = player.blinkInterval + love.math.random(-1, 1)
        end
    else
        -- If it's time for the next blink, start blinking
        if player.blinkTimer >= player.nextBlinkTime then
            player.isBlinking = true
            player.blinkTimer = 0
        end
    end

    -- Update confetti
    if confetti.active then
        confetti.timer = confetti.timer + dt

        -- Add new confetti particles occasionally
        if confetti.timer < confetti.duration and love.math.random() < 0.1 then
            for i = 1, 5 do
                table.insert(confetti.particles, createConfettiParticle())
            end
        end

        -- Update existing particles
        for i = #confetti.particles, 1, -1 do
            local p = confetti.particles[i]
            p.x = p.x + p.xVel * dt
            p.y = p.y + p.yVel * dt
            p.rotation = p.rotation + p.rotationSpeed * dt

            -- Remove particles that are off-screen
            local width, height = love.graphics.getDimensions()
            if p.y > height + 50 then
                table.remove(confetti.particles, i)
            end
        end

        -- Stop creating new confetti after duration, but don't reset game state
        if confetti.timer > confetti.duration and #confetti.particles == 0 then
            confetti.active = false
        end
    end
end

-- Handle key presses
function love.keypressed(key)
    -- Jump when spacebar is pressed
    if key == "space" then
        if not player.isJumping then
            -- First jump
            player.yVelocity = player.jumpPower
            player.isJumping = true
            player.canDoubleJump = true -- Enable double jump
        elseif player.canDoubleJump and not player.hasDoubleJumped then
            -- Double jump in mid-air
            player.yVelocity = player.jumpPower * 0.8 -- Slightly weaker second jump
            player.hasDoubleJumped = true
            player.canDoubleJump = false
        end
    end

    -- Restart the game with R key
    if key == "r" then
        player.x = 100
        player.y = 450
        player.yVelocity = 0
        camera.x = 0
        camera.y = 0
        camera.targetX = 0
        camera.targetY = 0
        flag.reached = false
        confetti.active = false
        confetti.particles = {}
    end

    -- Quit the game with Escape key
    if key == "escape" then
        love.event.quit()
    end
end

-- Draw function for rendering
function love.draw()
    -- Save current state for UI elements
    love.graphics.push()

    -- Apply screen shake if active
    if screenShake.active then
        local shakeFactor = math.max(0, 1 - screenShake.timer / screenShake.duration)
        local dx = love.math.random(-screenShake.intensity, screenShake.intensity) * shakeFactor
        local dy = love.math.random(-screenShake.intensity, screenShake.intensity) * shakeFactor
        love.graphics.translate(dx, dy)
    end

    -- Apply camera transformation
    love.graphics.translate(camera.x, camera.y)

    -- Draw checkered background
    local width, height = love.graphics.getDimensions()
    local visibleTilesX = math.ceil(width / background.squareSize) + 2
    local visibleTilesY = math.ceil(height / background.squareSize) + 2

    local startX = math.floor(-camera.x / background.squareSize)
    local startY = math.floor(-camera.y / background.squareSize)

    for y = startY, startY + visibleTilesY do
        for x = startX, startX + visibleTilesX do
            -- Determine which color to use (alternating pattern)
            local colorIndex = ((x + y) % 2) + 1
            love.graphics.setColor(background.colors[colorIndex])

            -- Draw the square
            love.graphics.rectangle(
                "fill",
                x * background.squareSize,
                y * background.squareSize,
                background.squareSize,
                background.squareSize
            )
        end
    end

    -- Draw the platforms
    love.graphics.setColor(0.8, 0.8, 0.8)
    for _, platform in ipairs(platforms) do
        love.graphics.rectangle("fill", platform.x, platform.y, platform.width, platform.height)
    end

    -- Draw the flag pole
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", flag.x, flag.y, flag.width, flag.height)

    -- Draw the flag
    love.graphics.setColor(flag.color)
    love.graphics.polygon("fill",
        flag.x + flag.width, flag.y,
        flag.x + flag.width + 30, flag.y + 15,
        flag.x + flag.width, flag.y + 30
    )

    -- Draw the player fish with current color
    love.graphics.setColor(player.currentColor)

    -- Save the current transformation state
    love.graphics.push()

    -- Calculate bob offset when not jumping
    local bobOffset = 0
    if not player.isJumping then
        bobOffset = (math.sin(player.bobTimer) - 1) * player.bobAmount
    end

    -- Move to fish position and flip if needed
    love.graphics.translate(player.x + player.width / 2, player.y + player.height / 2 + bobOffset)
    love.graphics.scale(player.direction, 1)

    -- Fish body (oval)
    love.graphics.ellipse("fill", 0, 0, player.width / 2, player.height / 2)

    -- Fish tail
    love.graphics.polygon("fill",
        player.width / 2 - 5, 0,
        player.width / 2 + 15, -player.height / 2,
        player.width / 2 + 15, player.height / 2
    )

    -- Fish eye (with blinking)
    if player.isBlinking then
        -- Closed eye (just a small line)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)
        love.graphics.line(
            -player.width / 4 - 4, -player.height / 6,
            -player.width / 4 + 4, -player.height / 6
        )
    else
        -- Open eye
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", -player.width / 4, -player.height / 6, 5)
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", -player.width / 4, -player.height / 6, 2)
    end

    -- Draw crown if victory is achieved
    if flag.reached then
        -- Crown in gold color
        love.graphics.setColor(1, 0.84, 0)

        -- Crown base
        love.graphics.rectangle("fill", -15, -player.height / 2 - 12, 30, 6)

        -- Crown points
        love.graphics.polygon("fill",
            -15, -player.height / 2 - 12,
            -10, -player.height / 2 - 12,
            -12.5, -player.height / 2 - 20
        )

        love.graphics.polygon("fill",
            -5, -player.height / 2 - 12,
            5, -player.height / 2 - 12,
            0, -player.height / 2 - 25
        )

        love.graphics.polygon("fill",
            15, -player.height / 2 - 12,
            10, -player.height / 2 - 12,
            12.5, -player.height / 2 - 20
        )

        -- Crown jewels
        love.graphics.setColor(1, 0, 0) -- Red jewel
        love.graphics.circle("fill", -12.5, -player.height / 2 - 15, 2)

        love.graphics.setColor(0, 0, 1) -- Blue jewel
        love.graphics.circle("fill", 0, -player.height / 2 - 17, 3)

        love.graphics.setColor(0, 1, 0) -- Green jewel
        love.graphics.circle("fill", 12.5, -player.height / 2 - 15, 2)
    end

    -- Restore the transformation state
    love.graphics.pop()

    -- End camera transformation
    love.graphics.pop()

    -- Draw screen-space UI elements (not affected by camera)

    -- Draw the confetti particles (in screen space)
    for _, p in ipairs(confetti.particles) do
        love.graphics.setColor(p.color)
        love.graphics.push()
        love.graphics.translate(p.x + p.width / 2, p.y + p.height / 2)
        love.graphics.rotate(p.rotation)
        love.graphics.rectangle("fill", -p.width / 2, -p.height / 2, p.width, p.height)
        love.graphics.pop()
    end

    -- Draw instructions and status
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Left/Right: Move   Space: Jump/Double-Jump   R: Restart   Escape: Quit", 10, 10)

    -- Display victory message
    if flag.reached then
        love.graphics.setColor(1, 1, 0)
        local message = "Victory! You reached the flag!"
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(message)
        love.graphics.print(message, (love.graphics.getWidth() - textWidth) / 2, 50)
    end
end

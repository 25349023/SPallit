-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- functions for debugging
local logging = {
    debug = function(msg, title)
        title = title or ''
        print('\n======== DEBUG: ' .. title .. ' =========')
        print(msg)
        print('======== DEBUG End =========\n')
    end
}



-- Setup something 

local physics = require('physics')
physics.start()
physics.setGravity(0, 40)

math.randomseed(os.time())

display.setStatusBar(display.HiddenStatusBar)

-- forward declaration of some variables

local deltaTime = 0.06  -- sec

local backGroup
local mainGroup
local uiGroup

local cloudsOptions = {
    frames = {
        {
            x = 1, y = 1,
            width = 238, height = 81
        },
        {
            x = 239, y = 1,
            width = 154, height = 57
        },
        {
            x = 1, y = 82,
            width = 194, height = 63
        },
        {
            x = 195, y = 82,
            width = 149, height = 55
        }
    }
}
local cloudsSheet = graphics.newImageSheet('clouds.png', cloudsOptions)

local groundsOptions = {
    frames = {
        {   -- 1) ground 1
            x = 0, y = 0,
            width = 895, height = 341
        },
        {   -- 2) ground 1 L
            x = 897, y = 0,
            width = 895, height = 341
        },
        {   -- 3) ground 1 R
            x = 897, y = 343,
            width = 895, height = 341
        },
        {   -- 4) ground 1 LR
            x = 0, y = 343,
            width = 895, height = 341
        },
        {   -- 5) ground 2
            x = 0, y = 686,
            width = 412, height = 341
        },
        {   -- 6) ground 2 L
            x = 414, y = 686,
            width = 412, height = 341
        },
        {   -- 7) ground 2 R
            x = 1242, y = 686,
            width = 412, height = 341
        },
        {   -- 8) ground 2 LR
            x = 828, y = 686,
            width = 412, height = 341
        }
    }
}
local groundsSheet = graphics.newImageSheet("grounds.png", groundsOptions)

-- display objects
local clouds = {}
local grounds = {}
local ball
local lArrow
local rArrow

-- state variables
local xStartOffset
local maxXCoordinate
local dire = 0  -- used only in key event
local viewIndex = 0
local maxViewIndex
local kindOfGrounds
local ballXEdge = 410
local viewEdgeDistance = 200
local scrollAmount = display.contentWidth - (ballXEdge + viewEdgeDistance)
local reachEnd = false

-- display
backGroup = display.newGroup()
mainGroup = display.newGroup()
uiGroup = display.newGroup()

local background = display.newImageRect(backGroup, 'Sky.png', 1024, 768)
background.x = display.contentCenterX
background.y = display.contentCenterY

--[[ create Grounds ]]
xStartOffset = math.random(50, 150)
kindOfGrounds = {}
for i = 1, 3 do
    local num = (math.random(1, 10000) % 2) * 4 + 1
    kindOfGrounds[#kindOfGrounds + 1] = num
    
    grounds[i] = display.newImageRect(backGroup, groundsSheet, num,
        groundsOptions.frames[num].width, groundsOptions.frames[num].height)
    grounds[i].y = display.contentHeight - 280
    
    if i == 1 then
        grounds[i].x = -xStartOffset
    else
        grounds[i].x = grounds[i-1].x + grounds[i-1].width
    end
    maxXCoordinate = grounds[i].x + grounds[i].width
    grounds[i].anchorX = 0
    grounds[i].anchorY = 0
    
    physics.addBody(grounds[i], 'static', { bounce=0 })
end
maxViewIndex = math.ceil((maxXCoordinate - display.contentWidth) / scrollAmount)


local function generateClouds(cnt) 
    for i = 1, cnt do
        table.insert(clouds, display.newImageRect(backGroup, cloudsSheet, 
                math.random(1, 10000) % 4 + 1, 160, 60))
        local t = #clouds
        
        clouds[t].x = 180 * i - 30
        if i == 1 then
            clouds[t].y = 75 * (math.random(1, 1000) % 2 + 2)
        elseif clouds[t-1].y == 75 then
            clouds[t].y = clouds[t-1].y + 75 * (math.random(1, 10000) % 3 + 1)
        elseif clouds[t-1].y == 300 then
            clouds[t].y = clouds[t-1].y - 75 * (math.random(1, 10000) % 3 + 1)
        else
            clouds[t].y = clouds[t-1].y + 75 * (math.random(1, 10000) % 2 == 1 and 1 or -1)
        end
        clouds[t].alpha = 0.01 * math.random(70, 85)
        
        physics.addBody(clouds[i], "kinematic", { isSensor=true })
    end
end

generateClouds(5)

ball = display.newImageRect(mainGroup, 'baseball.png', 64, 64)
ball.x = 500
ball.y = 300
physics.addBody(ball, "dynamic", { radius=32, bounce=0 })
ball.dire = 'N'  -- N: None, R: Right, L: Left
ball.jump = false
ball.tag = 'player'

lArrow = display.newImageRect(uiGroup, 'left_arrow.png', 104, 120)
lArrow.x = 100
lArrow.y = display.contentHeight - 100
lArrow.tag = 'L'
rArrow = display.newImageRect(uiGroup, 'right_arrow.png', 104, 120)
rArrow.x = display.contentWidth - 100
rArrow.y = display.contentHeight - 100
rArrow.tag = 'R'
uArrow = display.newImageRect(uiGroup, 'jump_circle.png', 110, 110)
uArrow.x = display.contentWidth - 260
uArrow.y = display.contentHeight - 100
uArrow.tag = 'J'


--[[local function onKeyEvent(event)
    local vx, vy = ball:getLinearVelocity()
    if event.phase == 'down' then
        if event.keyName == 'space' then
            ball:setLinearVelocity(vx, -600)
        end

        if event.keyName == 'left' then
            ball.dire = 'L'
            ball.linearDamping = 0
            ball:setLinearVelocity(-360, vy)
        end
        if event.keyName == 'right' then
            ball.dire = 'R'
            ball.linearDamping = 0
            ball:setLinearVelocity(360, vy)
        end
    elseif event.phase == 'up' then
        if event.keyName == 'left' and ball.dire == 'L' then
            ball.dire = 'N'
            ball.linearDamping = 2
        end
        if event.keyName == 'right' and ball.dire == 'R' then
            ball.dire = 'N'
            ball.linearDamping = 2
        end
    end
    
    return false
end
]]
-- Runtime:addEventListener("key", onKeyEvent)


local function moveCloud(level, d)
    level = 4 - level 
    if level == 4 then
        for i = 1, #clouds do
            clouds[i]:setLinearVelocity(0, 0)
        end
    else
        for i = 1, #clouds do
            if clouds[i].y / 75 > level then
                clouds[i]:setLinearVelocity(100 * d, 0)
            end
        end
    end
end


local function pressUIButton(event)
    local btn = event.target
    local phase = event.phase
    local vx, vy = ball:getLinearVelocity()
    ball.linearDamping = 0
    if phase == 'began' then
        display.currentStage:setFocus(btn)
        btn.alpha = 0.7
        
        if btn.tag == 'L' then
            ball:setLinearVelocity(-380, vy)
            moveCloud(1, 1)
        elseif btn.tag == 'R' then
            ball:setLinearVelocity(380, vy)
            moveCloud(1, -1)
        elseif btn.tag == 'J' and ball.onGround then
            ball:setLinearVelocity(vx, -700)
            ball.jump = true
            ball.onGround = false
        end
    elseif phase == 'ended' or phase == 'cancelled' then
        btn.alpha = 1
        display.currentStage:setFocus(nil)
        
        if btn.tag == 'L' or btn.tag == 'R' then
            ball:setLinearVelocity(0, vy)
            moveCloud(0)
        elseif btn.tag == 'J' then
            ball.jump = false
        end
    end
    return true
end

lArrow:addEventListener('touch', pressUIButton)
rArrow:addEventListener('touch', pressUIButton)
uArrow:addEventListener('touch', pressUIButton)


local function nextView()
    viewIndex = viewIndex + 1
    sa = scrollAmount
    if viewIndex == maxViewIndex and not reachEnd then
        sa = (maxXCoordinate - display.contentWidth) % sa
        reachEnd = true
    end
    
    transition.moveBy(ball, 
        { time=750, x=-sa, transition=easing.outSine })
    for i = 1, #grounds do
        transition.moveBy(grounds[i], 
            { time=750, x=-sa, transition=easing.outSine })
    end
end

local function prevView()
    viewIndex = viewIndex - 1
    sa = scrollAmount
    if viewIndex == 0 and reachEnd then
        sa = (maxXCoordinate - display.contentWidth) % sa
        reachEnd = false
    end
    
    transition.moveBy(ball, 
        { time=750, x=sa, transition=easing.outSine })
    for i = 1, #grounds do
        transition.moveBy(grounds[i], 
            { time=750, x = sa, transition=easing.outSine })
    end
end


local function gameLoop()
    local vx, vy = ball:getLinearVelocity()
    
    local _, gy = physics.getGravity()
    if math.abs(vy) < 1e-5 and not ball.onGround then  -- on ground
        ball.onGround = true
    elseif vy > 0 then  -- falling down
        ball:setLinearVelocity(vx, vy + 2500 * deltaTime)
    elseif vy < 0 and not ball.jump then  -- rising
        ball:setLinearVelocity(vx, vy + 900 * deltaTime)
    end
    
    vx, vy = ball:getLinearVelocity()
    if ball.x < 0 then
        ball.x = 0
        ball:setLinearVelocity(0, vy)
    elseif ball.x < viewEdgeDistance and viewIndex ~= 0 then
        prevView()
    elseif ball.x > display.contentWidth - viewEdgeDistance and viewIndex ~= maxViewIndex then
        nextView()
    elseif viewIndex == maxViewIndex and ball.x > display.contentWidth then
        ball.x = display.contentWidth
        ball:setLinearVelocity(0, vy)
    end
    
    
end

gameloopTimer = timer.performWithDelay(deltaTime * 1000, gameLoop, 0)

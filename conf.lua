function love.conf(t)
    t.title = "Fish Jump"      -- The title of the window
    t.version = "11.4"         -- The LÖVE version this game was made for
    t.window.width = 800       -- The window width
    t.window.height = 600      -- The window height
    t.window.resizable = false -- Let the window be resizable?
    t.window.vsync = true      -- Enable vertical sync

    -- For debugging
    t.console = false -- Attach a console for print statements

    -- Modules configuration
    t.modules.joystick = false -- No joystick needed for this game
    t.modules.physics = true   -- Enable physics for our platformer
    t.modules.video = false    -- No video playback needed
end

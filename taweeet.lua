-- Taweeet v0.0.7
-- Because birdsong is beautiful
-- Click on Key3 to start
---------------------
-- Within Taweeet:
--   key1 = param menu
--   key2 = new species
--   key3 = new image & audio

-- Include nornsLib using the full include file manually copied from nornsLib
include "lib/fullNornsLibInclude"

-- All other includes
include "lib/splash"
include "lib/intro"
include "lib/species"
include "lib/get"
include "lib/util"
include "lib/cache"
include "lib/softcutUtil"
taweet_params = include "lib/parameters"


debug_mode = true

-- So can play a simple sound
--engine.name = "TestSine"


function init()
  util.tprint("=============== Initing Taweeet... ===============")
  
  -- Display splash screen as soon as possible during startup
  displaySplashScreen()

  -- Startup softcut
  softcut_init()

  taweet_params.init()

  -- Initialize sound engine
  --engine.hz(40)
  
  --Load in a species
  select_random_species()
end


function redraw()
  -- Display splash screen, and do so for min of 3.0 seconds. If did indeed
  -- display splash screen then don't need to continue to display image of
  -- current species.
  if displaySpashScreenOnceViaRedraw(1.5) then return end
  
  util.debug_tprint("Redrawing via redraw()")
  startIntro()
  
  if false then
    -- Always start by clearing screen
    screen.clear()
    
    -- Determine how to draw image of species in middle of screen
    png_width = global_species_data.width
    png_height = global_species_data.height
    local png_y = (64-png_height)/2
    local png_x = (128-png_width)/2
    
    -- Actually draw the image buffer
    screen.display_image(global_species_data.image_buffer, png_x, png_y)
    
    -- update so that drawing actually visible
    screen.update()
  
    util.debug_tprint("Done with redraw()")
  end
end
  

function key(n, down)
  if n == 1 and down == 0 then
    -- Need to halt intro if it is running. Otherwise the intro 
    -- clock could cause the the into to overwrite the menu screen.
    haltIntro()
    
    -- Key1 up so jump to edit params directly. Don't require it
    -- to be a short press so that it is easier. And use key up
    -- event if used key down then the subsequent key1 up would 
    -- switch back from edit params menu to the application screen.
    jump_to_edit_params_screen()
  end
  
  -- When key2 pressed select another species randomly
  if n == 2 and down == 1 then
    util.debug_tprint("---Key2--- pressed")
    select_random_species()
  end
  
  -- When key3 pressed select a PNG and a WAV file for the species randomly
  if n == 3 and down == 1 then
    util.debug_tprint("---Key3--- pressed")
    select_random_png()
    select_random_wav()
  end
  
  -- For testing sinewave audio engine, when key2 pressed 
  if n == 2 then
    -- Change the signwave being played
    -- engine.hz(100 + 100*down)
  end
end


function enc(n, delta)
  print("n=" .. n .. " delta=" .. delta)
end



-- Taweeet v0.0.8
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

clip_audio = include "lib/clipAudio"


-- So can play a simple sound
--engine.name = "TestSine"


function init()
  -- While developing code enable log.debugging
  log.enable_debug(false)

  -- Display splash screen as soon as possible during startup
  display_splash_screen()

  -- Startup softcut
  softcut_init()

  taweet_params.init()

  -- Initialize sound engine
  --engine.hz(40)
end


local graph_y_pos = 14

-- Draws the custom audio graph 
function draw_audio_graph()
  screen.clear()
  
  -- Draw custom part of the audio graph screen towards the top
  screen.move(screen.WIDTH/2, graph_y_pos-3)
  screen.level(screen.levels.HIGHLIGHT)
  screen.font_face(6)
  screen.font_size(12)
  screen.aa(1) -- Since font size 12 or greater
  screen.text_center("Custom UI")
  
  -- Draw horizontal line at bottom of the custom area
  screen.level(12) -- Use lighter line so don't get incorrect other faint line beneath it
  screen.line_width(1.0)
  screen.aa(0)
  screen.move(10, graph_y_pos-1)
  screen.line (118, graph_y_pos-1)
  screen.stroke()
  
  -- Draw the actual audio graph, which will go below graph_y_pos
  clip_audio.draw_audio_graph()
  
  screen.update()
end


function redraw()
  -- If in clip audio mode then display custom audio clip screen
  if clip_audio.enabled() then
    draw_audio_graph()
    return
  end
  
  -- Display splash screen, and do so for min of 1.0 seconds. If did indeed
  -- display splash screen then don't need to continue to display image of
  -- current species.
  if display_splash_screen_once_via_redraw(1.0) then return end
  
  log.debug("Redrawing via taweeet.lua redraw()")
  startIntro()
end
  

function key(n, down)
  -- If in clip audio mode then use clip_adui.key() to handle key press
  if clip_audio.enabled() then
    clip_audio.key(n, down)
    return
  end
  
  if n == 1 and down == 0 then
    -- Need to halt intro if it is running. Otherwise the intro 
    -- clock could cause the the into to overwrite the menu screen.
    haltIntro()
    
    -- Key1 up so jump to edit params directly. Don't require it
    -- to be a short press so that it is easier. And use key up
    -- event if used key down then the subsequent key1 up would 
    -- switch back from edit params menu to the application screen.
    parameterExt.jump_to_edit_params_screen()
  end
  
  -- When key2 pressed select another species randomly
  if n == 2 and down == 1 then
    log.debug("Taweeet Key2 pressed")

    -- Clear screen so user knows something is happening
    screen.clear()
    screen.update()
    
    -- Select and display whole new species
    select_random_species()
  end
  
  -- When key3 pressed select a PNG and a WAV file for the species randomly
  if n == 3 and down == 1 then
    log.debug("Taweeet Key3 pressed")

    -- Clear screen so user knows something is happening
    screen.clear()
    screen.update()
    
    -- Display new random image and audio
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
  --log.debug("Taweeet encoder changed n=" .. n .. " delta=" .. delta)
  
  -- Enable clip_audio mode if encoder 2 or 3 are turned, and currently not enabled
  if n ~= 1 and not clip_audio.enabled() then
    -- Make sure not in intro anymore
    haltIntro()
    
    -- Switch to the audio clip screen
    local duration = clip_audio.wav_file_duration(get_species_wav_filename())
    clip_audio.enable(graph_y_pos, duration)
    
    -- Don't want the initial encoder turn to acctually change values
    -- so simply return
    return
  end
  
  -- If in clip_audio mode then pass encoder update to it
  if n ~= 1 and clip_audio.enabled() then
    clip_audio.enc(n, delta)
    return
  end
end

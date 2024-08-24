-- Taweeet
-- Because birdsong is beautiful
-- 0.0.6 attempt
--
-- Click on K3 to start

-- Include nornsLib using the full include file manually copied from nornsLib
include "lib/fullNornsLibInclude"

-- All other includes
include "lib/species"
include "lib/get"
include "lib/util"
include "lib/cache"
include "lib/softcutUtil"
include "lib/parameters"


debug_mode = true
current_count = 0 -- incremented every clock tick

-- So can play a simple sound
--engine.name = "TestSine"



-- Note: the metro timers are globals so that they can be reused. But
-- this means that the event functions need to already be declared at
-- this point. Otherwise would just be passing in nil function.

-- Animates the intro by updating the global current_count while calling redraw() 
-- repeatedly
function intro_tick(count)
  current_count = count
  redraw(true)
end

-- Timer for doing intro animation
intro_counter = metro.init(intro_tick, 0.05, -1)


function init()
  print("Initing Taweeet...")
  
  -- Startup softcut
  softcut_init()

  parameters_init()

  -- Initialize sound engine
  --engine.hz(40)
  
  --Load in a species
  select_random_species()
end


function redraw(called_from_clock_tick)
  -- If called be the system then the png and wav files might not
  -- yet be ready. So only continue if called by intro_tick()
  if not called_from_clock_tick then return end
  
  --if debug_mode then print("in redraw()") end
  
  -- Always start by clearing screen
  screen.clear()
  
  -- Draw moving image. Have it scroll left to right until it is in the middle of screen
  png_width = global_species_data.width
  png_height = global_species_data.height
  
  local png_y = (64-png_height)/2
  local png_x = -png_width + 6*current_count
  if png_x > (128-png_width)/2 then 
    -- Reached desired horizontal position so don't increase png_x anymore
    --if debug_mode then print("png centered!") end
    png_x = (128-png_width)/2
  end
  
  -- Actually draw the image buffer
  screen.display_image(global_species_data.image_buffer, png_x, png_y)
  
  -- Draw some vertically moving name of the species.
  -- First draw a darker rectangle so text will be readable. And to
  -- do that first need to figure out proper font size for the species name.
  screen.font_face(7)
  local font_size = 15 -- Will actually start with font 14
  local horiz_padding = 4
  repeat  
    font_size = font_size - 1
    screen.font_size(font_size)
    text_width = screen.text_extents(global_species_data.speciesName)
  until (text_width <= 128)
  
  -- rectangle_x is static and easy to determine
  local rectangle_x = (128 - text_width - 2*horiz_padding) / 2
  
  -- Since moving downwards but pausing at certain height, rectanble_y is more difficult
  local rectangle_y_pause = 58 -- Where rectangle should pause
  local pause_ticks = 60       -- How long to pause there
  local rectangle_y = current_count - font_size - 1
  if current_count > rectangle_y_pause and current_count <= rectangle_y_pause + pause_ticks then
    rectangle_y = rectangle_y_pause - font_size - 1
  elseif current_count > rectangle_y_pause + pause_ticks then
    rectangle_y = current_count - pause_ticks - font_size - 1
  end
  
  -- Draw rectangle on screen so that text shows up better
  screen.level(3)
  screen.rect(rectangle_x, rectangle_y, text_width + 2*horiz_padding, font_size+1)
  screen.fill()
  
  -- Draw species name on screen over the rectangle
  screen.level(15)
  screen.aa(1) -- Found that font 7 Roboto-Bold at large size looks better with anti-aliasing
  screen.move(rectangle_x + horiz_padding, rectangle_y - 2 + font_size)
  screen.text(global_species_data.speciesName)
  
  -- update so that drawing actually visible
  screen.update()
  
  --if debug_mode then print("Done with redraw()") end
  
  if rectangle_y > 64 then
    intro_counter:stop()
  end
  
end
  

function key(n, down)
  if n == 1 and down == 0 then
    -- Key1 up so jump to edit params directly. Don't require it
    -- to be a short press so that it is easier. And use key up
    -- event if used key down then the subsequent key1 up would 
    -- switch back from edit params menu to the application screen.
    jump_to_edit_params_screen()
  end
  
  -- When key2 pressed select another species randomly
  if n == 2 and down == 1 then
    util.debug_tprint("Key2 pressed")
    select_random_species()
  end
  
  -- When key3 pressed select a PNG and a WAV file for the species randomly
  if n == 3 and down == 1 then
    util.debug_tprint("Key3 pressed")
    select_random_png()
    select_random_wav()
  end
  
  -- When key2 pressed
  if n == 2 then
    -- Change the signwave being played
    -- engine.hz(100 + 100*down)
  end
end


function enc(n, delta)
  print("n=" .. n .. " delta=" .. delta)
end



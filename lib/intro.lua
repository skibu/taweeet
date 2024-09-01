-- Displays the graphical intro for the selected species


-- Animates the intro by updating the global current_count while calling
-- displayIntroForSpeciesCallback repeatedly
function introTick(count)
  displayIntroForSpeciesCallback(count)
end


-- Timer for doing intro animation. To start the animation call
-- intro_clock:start()
local intro_clock = metro.init(introTick, 0.05, -1)


-- Initiates the display of the visual introduction for the species, 
-- but only does so if the PNG is ready. To be called by redraw(). If PNG
-- not yet ready then the intro will be initiated by the completino of
-- getting the PNG in png_file_exists_callback() in species.lua
function startIntro()
  if png_ready() then
    util.debug_tprint("startIntro() Starting intro since png now ready")
    intro_clock:start()
  end
end


-- Initiates the display of the visual introduction for the species, 
-- but only does so if in app mode instead of menu mode. To be called
-- by the callback when PNG fully loaded. If in menu mode then the
-- intro will be initiated by redraw()
function startIntroIfInAppMode()
  if not _menu.mode then
    util.debug_tprint("startIntroIfInAppMode Starting intro since in app mode instead of menu mode")
    intro_clock:start()
  end
end


-- Stops the intro counter. Useful for when jumping to parameter menu.
-- Okay to call even if intro not currently running.
function haltIntro()
  util.debug_tprint("Halting intro in intro.haltIntro()")
  intro_clock:stop()
end


function displayNewIntroCallback(current_count)
  --util.debug_tprint("Redrawing via displayIntroForSpeciesCallback()")
  
  -- To make sure that no longer have problem when hit k2 twice, the second time 
  -- before the first intro finished
  if not png_ready() then
    util.tprint("Error: png not ready but tried to display intro displayIntroForSpeciesCallback()")
    return
  end
  
    -- Always start by clearing screen
  screen.clear()
  
  -- FIXME the graphics for the new intro go here
  --
  --
  
  
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
  
  --util.debug_tprint("Done with displayIntroForSpeciesCallback()")
  
  if rectangle_y > 64 then
    util.debug_tprint("Stopping intro clock because done with animation")
    intro_clock:stop()
  end
  
  -- FIXME only returning true for developing this intro
  return true
end


-- Called every clock tick when displaying the visual intro for the species
function displayIntroForSpeciesCallback(current_count)
  -- FIXME just for developing new, fancier intro
  if displayNewIntroCallback(current_count) then return end
  
  --util.debug_tprint("Redrawing via displayIntroForSpeciesCallback()")
  
  -- To make sure that no longer have problem when hit k2 twice, the second time 
  -- before the first intro finished
  if not png_ready() then
    util.tprint("Error: png not ready but tried to display intro displayIntroForSpeciesCallback()")
    return
  end
  
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
  
  --util.debug_tprint("Done with displayIntroForSpeciesCallback()")
  
  if rectangle_y > 64 then
    util.debug_tprint("Stopping intro clock because done with animation")
    intro_clock:stop()
  end
end


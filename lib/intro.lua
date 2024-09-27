-- Displays the graphical intro for the selected species


-- Parameters used to affect the intro animation
local screen_width = 128     -- Standard norns screen width
local screen_height = 64     -- Standard norns screen height
local initial_radius = 50.   -- Number of pixels animation should start from center of screen
local animation_ticks = 70   -- How many ticks for the swirling animation of the image
local rectangle_y_pause = 58 -- Where species name text rectangle should pause
local pause_ticks = 30       -- How long to pause there


-- Draws filter. To be called via screen.draw_to() so that the drawing will occur
-- on the specified image. The image is assumed to be full screen, which is
-- 128x64.
local function draw_filter(dark_level) 
  log.debug("Drawing to image using dark_level="..tostring(dark_level))
  
  -- Make the whole image dark
  screen.level(dark_level)  
  screen.rect(0, 0, screen_width, screen_height)
  screen.fill()
  
  -- Draw two level 15 circles to make it sort of look like a view through binoculars
  screen.level(15)
  local r = (screen_height / 2) - 3
  local y = 32
  screen.circle(32, y, r)
  screen.fill()
  screen.circle(96, y, r)
  screen.fill()
  
  screen.current_point() -- FIXME Trying to sync things
  
  screen.save() -- FIXME Trying to sync things
end


local filter_cache = nil

-- Creates and returns an image that can serve as a filter for displaying only a
-- select part of the screen and everything else will be drawn at maximum of the 
-- dark_level. By using different dark levels the background can be faded in slowly.
local function create_filter_image(dark_level)
  if filter_cache ~= nil then return filter_cache end
  
  -- Create new image
  local image = screen.create_image(screen_width, screen_height)
  
  -- Draw filter to the image using draw_filter()
  screen.draw_to(image, draw_filter, dark_level)
  
  filter_cache = image
  
  return image
end


-- Returns x,y coordinatess of the corner of the intro image to be displayed.
-- The current_count specifies how far along the animation should be, and 
-- should come from the intro clock. The offset_degrees parameter is so can
-- use use this function for all four portions of the intro image to be displayed.
-- 0 for x axis, 90 for y axis, 180 for -x, and 270 for -y. The x,y location 
-- returned is for screen coordinates where, confusingly, y increases going downwards.
local function get_x_y(current_count, offset_degrees)
  -- If done with animation then just return center of screen
  if current_count > animation_ticks then
    return screen_width/2, screen_height/2
  end
  
  -- Decreasing radius and increasing angle
  radius = initial_radius * (1 - current_count/animation_ticks)
  angle_degrees = offset_degrees + (current_count / (animation_ticks/2)) * 360
  angle_rads = math.rad(angle_degrees)
  
  -- For the axis vector (x, y, -x, -y) determinined by offset_degrees
  x = screen_width/2 + radius * math.cos(angle_rads)
  y = screen_height/2 - radius * math.sin(angle_rads)
  
  return x, y
end


-- Called every clock click for animating introduction. Displays the image of the 
-- current species by dividing the image into 4 sequares and swirling them around
-- the center of the screen until they are full sized and in proper place. Also
-- scrolls from top to bottom the text of the name of the current species.
local function swirling_intro_callback(current_count)
  --log.debug("Redrawing via swirling_intro_callback()")
  
  -- To make sure that no longer have problem when hit k2 twice, the second time 
  -- before the first intro finished
  if not png_ready() then
    log.debug("Error: png not ready but tried to display intro displayIntroForSpeciesCallback()")
    return
  end
  
    -- Always start by clearing screen
  screen.clear()

  local image_width = global_species_data.width
  local image_height = global_species_data.height
  local image_buffer = global_species_data.image_buffer
  
  width = (image_width/2) * math.min(current_count, animation_ticks)/animation_ticks
  height = (image_height/2) * math.min(current_count, animation_ticks)/animation_ticks
  
  -- top left, tied to left axis
  x, y = get_x_y(current_count, 180.0)
  screen.display_image_region (image_buffer, 0, 0, width, height, x-width, y-height)

  -- bottom left, tied to down axis
  x, y = get_x_y(current_count, 270.0)
  --screen.display_image_region (test_buffer, 0, 32, 61, 32, 3, 32)
  --screen.display_image_region (image, left, top, width, height, x, y)
  screen.display_image_region(image_buffer, 0, image_height-height, width, height, x-width, y)

  -- bottom right, tied to right axis
  x, y = get_x_y(current_count, 0.0)
  screen.display_image_region(image_buffer, image_width-width, image_height-height, width, height, x, y)

  -- top right, tied to right axis
  x, y = get_x_y(current_count, 90.0)
  screen.display_image_region(image_buffer, image_width-width, 0, width, height, x, y-height)

  -- Draw the filterr so that it hopefully looks as if looking through binoculars
  local filter = create_filter_image(0)
  screen.blend_mode("Darken") -- FIXME
  screen.current_point() -- FIXME possibly needed since display_image() is not a queued event so might happen before the other stuff is actually written to the screen
  screen.display_image(filter, 0, 0)
  screen.blend_mode("Over")
  
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
  local rectangle_y = current_count - font_size - 1
  if current_count > rectangle_y_pause and current_count <= rectangle_y_pause + pause_ticks then
    rectangle_y = rectangle_y_pause - font_size - 1
  elseif current_count > rectangle_y_pause + pause_ticks then
    rectangle_y = current_count - pause_ticks - font_size - 1
  end
  
  -- Draw small rectangle on screen so that text shows up better
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
  
  -- Done if text rectangle disappeared and done with image animation
  if rectangle_y > 64 and current_count >= animation_ticks and intro_clock ~= nil then
    log.debug("Stopping intro clock because done with animation current_count="..current_count.." and animation_ticks="..animation_ticks)
    intro_clock:stop()
  end
end


-- Deprecated.
-- The original animation which just scrolls the image from left to right.
-- To be called every clock tick when displaying the visual intro for the species.
local function original_scroll_image_intro_callback(current_count)
  log.debug("Redrawing via original_scroll_image_intro_callback()")
  
  -- To make sure that no longer have problem when hit k2 twice, the second time 
  -- before the first intro finished
  if not png_ready() then
    log.error("png not ready but tried to display intro displayIntroForSpeciesCallback()")
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
  
  -- Draw small rectangle on screen so that text shows up better
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
  
  log.debug("Done with original_scroll_image_intro_callback()")
  
  if rectangle_y > 64 then
    log.debug("Stopping intro clock because done with animation count="..current_count)
    intro_clock:stop()
  end
end


-- Animates the intro by updating the global current_count while calling
-- swirling_intro_callback repeatedly
function intro_tick(count)
  swirling_intro_callback(count)
  
  -- Trying to collect garbage of the many image buffers created for the intro
  -- collectgarbage() -- FIXME
end


-- Timer for doing intro animation. The animation intro clock runs until it is
-- stopped. To start the animation call intro_clock:start()
local intro_clock = metro.init(intro_tick, 0.04, -1)


-- Initiates the display of the visual introduction for the species, 
-- but only does so if the PNG is ready. To be called by redraw(). If PNG
-- not yet ready then the intro will be initiated by the completino of
-- getting the PNG in png_file_exists_callback() in species.lua
function startIntro()
  if png_ready() then
    log.print("Starting graphical intro since image now available")
    intro_clock:start()
  end
end


-- Initiates the display of the visual introduction for the species, 
-- but only does so if in app mode instead of menu mode. To be called
-- by the callback when PNG fully loaded. If in menu mode then the
-- intro will be initiated by redraw()
function startIntroIfInAppMode()
  if not _menu.mode then
    log.debug("startIntroIfInAppMode() Starting intro since in app mode, not menu mode")
    intro_clock:start()
  end
end


-- Stops the intro counter. Useful for when jumping to parameter menu.
-- Okay to call even if intro not currently running.
function haltIntro()
  log.debug("Halting intro if still running")
  intro_clock:stop()
end


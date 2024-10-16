-- Displays the graphical intro for the selected species


-- Parameters used to affect the intro animation
local screen_width = 128     -- Standard norns screen width
local screen_height = 64     -- Standard norns screen height
local initial_radius = 50    -- Number of pixels swirling animation should start from center of screen
local swirling_ticks = 60    -- How many ticks for the swirling animation of the image
local slide_ticks = 30       -- Number of ticks after swirling for pic to slide horizontally
local rectangle_y_pause = 58 -- Where species name text rectangle should pause
local pause_ticks = 30       -- How long to pause there
local mask_extra_width = 20  -- extra width so can make binoculars pan a bit horizontally
local initial_x_offset = 8   -- How far to slide image horizontally after swirling completed
local binocs_start_fading_ticks = swirling_ticks + slide_ticks
local binocs_ticks_per_cycle = 70 
local binocs_swing_from_center = 4 -- must be less than or equal to mask_extra_width/2
local binocs_fade_ticks = 80 -- Number of ticks to take to fade out binoculars


-- Timer for doing intro animation. Once started, the animation intro clock runs until
-- it is stopped. To start the animation call intro_clock:start(). The clock is initted
-- lower down in this file.
local intro_clock


-- Draws mask onto image buffer. To be called via screen.draw_to() so that the drawing
-- will occur on the specified image buffer. The image is assumed to be full screen, which is
-- 128x64.
local function draw_binoc_mask_on_image(dark_level) 
  -- Draw the whole image at the dark level
  screen.level(dark_level)  
  screen.rect(0, 0, screen_width + mask_extra_width, screen_height)
  screen.fill()
  
  -- Draw the left and right edges of mask, where won't cover the species image, 
  -- as black since don't want them to get light when fading out the binoculars.
  local image_width = get_species_image_width()
  if image_width < screen_width then
    -- Draw left black rectanble
    screen.level(screen.levels.DARK)
    screen.rect(0, 0, (screen_width + mask_extra_width - image_width)/2, screen_height)
    screen.fill()
    
    -- Draw right black rectanble
    screen.rect(screen_width + mask_extra_width - (screen_width + mask_extra_width - image_width)/2, 0, 
      (screen_width - image_width)/2, screen_height)
    screen.fill()
  end
  
  -- Draw two screen.levels.LIGHT (level 15) circles to make it sort of look like a view 
  -- through binoculars
  screen.level(screen.levels.LIGHT)
  local r = (screen_height / 2) - 6
  local y = screen_height / 2
  screen.circle(screen_width/4 + mask_extra_width/2, y, r)
  screen.fill()
  screen.circle(3*screen_width/4 + mask_extra_width/2, y, r)
  screen.fill()
end


-- Creates and returns an image that can serve as a mask for displaying only a
-- select part of the screen and everything else will be drawn at maximum of the 
-- dark_level. By using different dark levels the background can be faded in slowly.
local function create_binoc_mask_image(dark_level)
  -- Create new image
  local image = screen.create_image(screen_width + mask_extra_width, screen_height)
  
  -- Draw mask to the image buffer using draw_binoc_mask_on_image()
  screen.draw_to(image, draw_binoc_mask_on_image, dark_level)
  
  return image
end


local done_with_swishing_binocs = false

-- Draw the binocular mask onto the screen so that it (hopefully) looks as if looking 
-- through binoculars. The binoculars swing back and forth by binocs_swing_from_center
-- and based on the current_count
local function draw_binocular_mask(current_count)
  -- x_offset is how far horizontally from center the binoculars should be drawn.
  -- By using current_count to affect x_offset, the binoculars will hopefully
  -- appear to be scanning left and right.
  if current_count == 1 then done_with_swishing_binocs = false end
  local x_offset = 0
  if not done_with_swishing_binocs then
    -- Use a sine wave to smoothly move binocs back and forth
    local minus_1_to_1 = math.sin(math.rad(current_count*360/binocs_ticks_per_cycle))
    -- Make binocs stay more at the ends by using square root of minus_1_to_1.
    -- Nevermind, found this was too jerky so removed it
    --minus_1_to_1 = (minus_1_to_1 < 0 and -1 or 1) * math.sqrt(math.abs(minus_1_to_1))
    
    -- Determine the offset in pixels
    x_offset = binocs_swing_from_center * minus_1_to_1
    if math.floor(x_offset + 0.5) == 0 and current_count >= binocs_start_fading_ticks then
      done_with_swishing_binocs = true
    end
  end
  
  -- Determine the dark level for the mask. Using a dark level of 0 masks using black. 
  -- If dark level is 15 or greater then there is no need to draw a mask so return true.
  local dark_level = current_count < binocs_start_fading_ticks and 0 
                      or 15 * (current_count - binocs_start_fading_ticks) / binocs_fade_ticks 
  dark_level = math.floor(dark_level + 0.5) -- levels usually need to be integers
  if dark_level >= 15 then return true end

  -- Create the binocular mask. And use "darken" blend mode so that white parts of mask indicate
  -- what can be seen of image, and dark parts will be dark.
  local mask = create_binoc_mask_image(dark_level)
  screen.blend_mode("darken")

  -- Overlay the mask so species image will be seen through binoculars
  -- the params are display_image_region(image, left, top, width, height, x, y)
  screen.display_image_region(mask, 
    mask_extra_width/2 + x_offset, 0, screen_width, screen_height, 
    0, 0)
  
  -- Restore to default mode
  screen.blend_mode("default")

  -- Return false to indicate not done with binocular animation. Binoc mask hasn't 
  -- fully faded out yet.
  return false 
end


-- Returns x,y coordinatess of the corner of the intro image to be displayed.
-- The current_count specifies how far along the animation should be, and 
-- should come from the intro clock. The offset_degrees parameter is so can
-- use use this function for all four portions of the intro image to be displayed.
-- 0 for x axis, 90 for y axis, 180 for -x, and 270 for -y. The x,y location 
-- returned is for screen coordinates where, confusingly, y increases going downwards.
local function get_x_y(current_count, offset_degrees)
  -- If done with animation then just return center of screen
  if current_count > swirling_ticks then
    return screen_width/2, screen_height/2
  end
  
  -- Decreasing radius and increasing angle
  radius = initial_radius * (1 - current_count/swirling_ticks)
  angle_degrees = offset_degrees + (current_count / (swirling_ticks/2)) * 360
  angle_rads = math.rad(angle_degrees)
  
  -- For the axis vector (x, y, -x, -y) determinined by offset_degrees
  x = screen_width/2 + radius * math.sin(angle_rads)
  y = screen_height/2 - radius * math.cos(angle_rads)
  
  return x, y
end


-- Draw current frame of species image swirling around.
-- Returns true when done with animation.
local function draw_frame_of_swirling_image(current_count)
  local image_width = get_species_image_width()
  local image_height = get_species_image_height()
  local image_buffer = get_species_image_buffer()
  
  local x_offset = 0
  if current_count < swirling_ticks then
    -- Still swirling so use a constant offset
    x_offset = initial_x_offset
  elseif current_count < swirling_ticks + slide_ticks then
    -- Slide from right to left till x_offset is 0
    x_offset = initial_x_offset * (1 - (current_count - swirling_ticks)/slide_ticks)
  end
  
  width = (image_width/2) * math.min(current_count, swirling_ticks)/swirling_ticks
  height = (image_height/2) * math.min(current_count, swirling_ticks)/swirling_ticks
  
  -- top left, tied to left axis
  x, y = get_x_y(current_count, 180.0)
  screen.display_image_region(image_buffer, 0, 0, width, height, x-width+x_offset, y-height)

  -- bottom left, tied to down axis
  x, y = get_x_y(current_count, 270.0)
  screen.display_image_region(image_buffer, 0, image_height-height, width, height, x-width+x_offset, y)

  -- bottom right, tied to right axis
  x, y = get_x_y(current_count, 0.0)
  screen.display_image_region(image_buffer, image_width-width, image_height-height, width, height, x+x_offset, y)

  -- top right, tied to right axis
  x, y = get_x_y(current_count, 90.0)
  screen.display_image_region(image_buffer, image_width-width, 0, width, height, x+x_offset, y-height)
  
  -- Return true if done with the animation
  local done = current_count >= swirling_ticks and math.floor(x_offset + 0.5) == 0
  return done
end


-- Draw vertically moving name of the species.
-- Retuns true if done with animating the species name, when the
-- display of the name is fully below the screen.
local function draw_vertically_moving_species_name(current_count)
  -- First draw a darker rectangle so text will be readable. And to
  -- do that first need to figure out proper font size for the species name.
  screen.font_face(7)
  local font_size = 15 -- Will actually start with font 14
  local horiz_padding = 4
  repeat  
    font_size = font_size - 1
    screen.font_size(font_size)
    text_width = screen.text_extents(get_species_name())
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
  screen.level(screen.levels.LIGHT)
  screen.aa(1) -- Found that font 7 Roboto-Bold at large size looks better with anti-aliasing
  screen.move(rectangle_x + horiz_padding, rectangle_y - 2 + font_size)
  screen.text(get_species_name())
  
  -- Return true if done with species name animation, when it has dropped below the screen
  local done = rectangle_y > screen_height
  return done
end


-- Called every clock click for animating introduction. Displays the image of the 
-- current species by dividing the image into 4 sequares and swirling them around
-- the center of the screen until they are full sized and in proper place. Also
-- scrolls from top to bottom the text of the name of the current species.
local function swirling_intro_callback(current_count)
  -- To make sure that no longer have problem when hit k2 twice, the second time 
  -- before the first intro finished
  if not png_ready() then
    log.debug("Error: png not ready but tried to display intro displayIntroForSpeciesCallback()")
    return
  end
  
  -- Always start by clearing screen
  screen.clear()
  
  -- Since using a draw mode of "darken" for the mask, need the pixels to 
  -- actually be black, not just cleared. Otherwise the result will include
  -- white parts of the mask since they are the darkest of the images
  -- being combined.
  screen.level(screen.levels.DARK)
  screen.rect(0, 0, screen.WIDTH, screen.HEIGHT)
  screen.fill()

  -- Draw frame of swirling species image
  local done_with_animation = draw_frame_of_swirling_image(current_count)
  
  -- Draw the mask so that it (hopefully) looks as if looking through binoculars
  local done_with_binoculars = draw_binocular_mask(current_count)
  
  -- Draw vertically moving name of the species.
  local done_with_species_name = draw_vertically_moving_species_name(current_count)
  
  -- update so that drawing actually visible
  screen.update()
  
  -- Done if text rectangle disappeared and done with image animation
  if done_with_species_name and 
      done_with_animation and 
      done_with_binoculars and 
      intro_clock ~= nil then
    log.debug("Stopping intro clock because done with all intro animation. current_count="..
      current_count.." and swirling_ticks="..swirling_ticks)
    intro_clock:stop()
  end
end


-- Animates the intro by updating the global current_count while calling
-- swirling_intro_callback repeatedly
function intro_tick(count)
  swirling_intro_callback(count)
end


-- Timer for doing intro animation. Once started, the animation intro clock runs until
-- it is stopped. To start the animation call intro_clock:start()
intro_clock = metro.init(intro_tick, 0.04, -1)


-- Initiates the display of the visual introduction for the species, 
-- but only does so if the PNG is ready. To be called by redraw(). If PNG
-- not yet ready then the intro will be initiated by the completino of
-- getting the PNG in png_file_exists_callback() in species.lua
function start_intro()
  if png_ready() then
    log.print("Starting graphical intro since image fully available")
    intro_clock:start()
  end
end


-- Initiates the display of the visual introduction for the species, 
-- but only does so if in app mode instead of menu mode. To be called
-- by the callback when PNG fully loaded. If in menu mode then the
-- intro will be initiated by redraw()
function start_intro_if_in_app_mode()
  if not _menu.mode then
    log.debug("start_intro_if_in_app_mode() Starting intro since in app mode, not menu mode")
    intro_clock:start()
  end
end


-- Stops the intro counter. Useful for when jumping to parameter menu.
-- Okay to call even if intro not currently running.
function halt_intro()
  log.print("Halting intro if still running")
  intro_clock:stop()
end


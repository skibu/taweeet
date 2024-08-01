-- Taweeet
-- Because birdsong is beautiful
-- 0.0.6 attempt
--
-- Click on K3 to start

include "lib/get"
include "lib/util"
include "lib/cache"
include "lib/softcutUtil"

debug = false
current_count = 0 -- incremented every clock tick

-- So can play a simple sound
-- FIXME engine.name = "TestSine"


local global_species_name, global_png_filename, global_png_width, global_png_height = nil, nil, nil, nil

-- Set the globals for the species at once
local function set_species_globals(species_name, png_filename, png_width, png_height)
  global_species_name = species_name
  global_png_filename = png_filename
  global_png_width = png_width
  global_png_height = png_height
end


-- Gets list of species and picks one randomely. Then loads in all the info
-- for the species. Returns table containing all of the data associated with the
-- selected species.
local function initRandomSpecies()
  print("Determining a random species to use...")
  
  -- Get list of species
  local species_list = getSpeciesList()

  -- Pick a species name by random
  local idx = math.random(1, #species_list)
  local random_species_name = species_list[idx]
  print("Using species "..random_species_name)
  
  -- Load in config for the species
  species_data = getSpeciesData(random_species_name)

  -- Pick random png url for the species
  local image_data_list = species_data.imageDataList
  local image_idx = math.random(1, #image_data_list)
  local image_data_tbl = image_data_list[image_idx]
  local png_url = image_data_tbl.image_url
  local png_filename = getPng(png_url, random_species_name)
  local png_width, png_height = extents(screen.load_png(png_filename))
    
  -- Pick random wav file url for the species
  --get url from species_data
  local audio_data_list = species_data.audioDataList
  local audio_idx = math.random(1, #audio_data_list)
  local audio_data = audio_data_list[audio_idx]
  local wav_url = audio_data.audio_url
  wav_filename = getWav(wav_url, random_species_name)

  -- Keep track of the info needed to display the species image and name on the screen
  set_species_globals(random_species_name, png_filename, png_width, png_height)
  
  print("Finished initing for species="..random_species_name)
  
  -- Play the wav file
  softcut_setup_stereo(wav_filename, 1, 2) 
end


function init()
  print("initing...")
  
  -- Startup softcut
  softcut_init()

  -- Initialize sound engine
  -- FIXME engine.hz(300)
  
  --Load in a species
  initRandomSpecies()
      
  -- Start up the timer
  intro_counter = metro.init(tick, 0.05, -1)
  intro_counter:start()
end


-- Called everytime the metro clock ticks
function tick(count)
  current_count = count
  if debug then print("current_count="..current_count) end
  redraw()
end


function redraw()
  if debug then print("in redraw()") end
  
  -- Always start by clearing screen
  screen.clear()
  
  -- Draw moving image. Have it scroll left to right until it is in the middle of screen
  --screen.display_png(global_png_filename, (128-global_png_width)/2, (64-global_png_height)/2)
  local png_y = (64-global_png_height)/2
  local png_x = -global_png_width + 6*current_count
  if png_x > (128-global_png_width)/2 then 
    -- Reached desired horizontal position so don't increase png_x anymore
    if debug then print("png centered!") end
    png_x = (128-global_png_width)/2
  end
  screen.display_png(global_png_filename, png_x, png_y)

  -- Draw some vertically moving name of the species.
  -- First draw a darker rectangle so text will be readable. And to
  -- do that first need to figure out proper font size for the species name.
  screen.font_face(4)
  local font_size = 15 -- Will actually start with font 14
  local horiz_padding = 4
  repeat  
    font_size = font_size - 1
    screen.font_size(font_size)
    text_width = screen.text_extents(global_species_name)
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
  screen.level(5)
  screen.rect (rectangle_x, rectangle_y, text_width + 2*horiz_padding, font_size+1)
  screen.fill()
  
  -- Draw species name on screen over the rectangle
  screen.level(15)
  screen.aa(1)
  screen.move(rectangle_x + horiz_padding, rectangle_y - 2 + font_size)
  screen.text(global_species_name)
  
  -- update so that drawing actually visible
  screen.update()
  
  if debug then print("Done with redraw()") end
  
  if rectangle_y > 64 then
    intro_counter:stop()
  end
  
end
  

function key(n, down)
  if n == 3 and down == 1 then
    print("button 3 down")
  end
  
  if n == 2 then
    -- FIXME engine.hz(100 + 100*down)
  end
end

function enc(n, delta)
  print("n=" .. n .. " delta=" .. delta)
end



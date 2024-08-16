-- Taweeet
-- Because birdsong is beautiful
-- 0.0.6 attempt
--
-- Click on K3 to start

-- Include nornsLib using the full include file manually copied from nornsLib
include "lib/fullNornsLibInclude"

-- All other includes
include "lib/get"
include "lib/util"
include "lib/cache"
include "lib/softcutUtil"
include "lib/parameters"


debug_mode = false
current_count = 0 -- incremented every clock tick

-- So can play a simple sound
engine.name = "TestSine"


global_species_data = nil

-- Called everytime the metro clock ticks. Waits for png file to exist. Once
-- it does the intro is started, which scrolls the image across the screen.
function wait_for_png_file(count)
  if debug_mode then util.tprint("in wait_for_png_file()") end

  if util.file_exists(global_species_data.png_filename) then
    util.tprint("PNG file loaded so using it. "..global_species_data.png_filename)
      
    -- png file exists so create the image buffer and determine width and height
    global_species_data.image_buffer = screen.load_png(global_species_data.png_filename)
    global_species_data.width, global_species_data.height = 
        screen.extents(global_species_data.image_buffer)
    
    -- Done waiting
    png_file_timer:stop()
    
    -- Start the intro animation
    intro_counter:start()
  else
    if debug_mode then util.tprint("Waiting for png file "..global_species_data.png_filename) end
  end
end


-- Called every 0.2 sec bu wav_file_timer. Once wav file exists
-- it is played
local function wait_for_wav_file()
  if util.file_exists(global_species_data.wav_filename) then
    util.tprint("WAV file loaded so playing it. ".. global_species_data.wav_filename)
    
    -- Done waiting
    wav_file_timer:stop()
    
    -- Play the wav file
    softcut_setup_stereo(global_species_data.wav_filename, 1, 2)
  else
    if debug_mode then util.tprint("Waiting for wav file "..global_species_data.wav_filename) end
  end
end


-- Animates the intro by updating the global current_count while calling redraw() 
-- repeatedly
function intro_tick(count)
  current_count = count
  redraw(true)
end


-- Note: the metro timers are globals so that they can be reused. But
-- this means that the event functions need to already be declared at
-- this point. Otherwise would just be passing in nil function.

-- Timer for waiting until png file is ready. Only wait up to 10 seconds.
png_file_timer = metro.init(wait_for_png_file, 0.2, 50)

-- Timer for waiting until wav file is ready. Only wait up to 20 seconds.
wav_file_timer = metro.init(wait_for_wav_file, 0.4, 50)

-- Timer for doing intro animation
intro_counter = metro.init(intro_tick, 0.05, -1)


function select_species(species_name)
  print("Initing select_species(species_name) species="..species_name)
  
  -- Load in config for the species
  global_species_data = getSpeciesData(species_name)
  global_species_data.species_name = species_name
  
  -- Pick random png url for the species
  local image_data_list = global_species_data.imageDataList
  local image_idx = math.random(1, #image_data_list)
  local image_data_tbl = image_data_list[image_idx]
  local png_url = image_data_tbl.image_url
  global_species_data.png_filename = getPng(png_url, species_name)
    
  -- Waits for png file to be loaded and then initiates the intro
  png_file_timer:start()

  -- Pick random wav file url for the species
  local audio_data_list = global_species_data.audioDataList
  local audio_idx = math.random(1, #audio_data_list)
  local audio_data = audio_data_list[audio_idx]
  local wav_url = audio_data.audio_url
  global_species_data.wav_filename = getWav(wav_url, species_name)
  
  -- Start timer for playing wav file once it is ready
  wav_file_timer:start()
end


-- Gets list of species and picks one randomely. Then loads in all the info
-- for the species. Returns table containing all of the data associated with the
-- selected species.
local function init_random_species()
  print("Determining a random species to use...")
  
  -- Get list of all species
  local species_list = getAllSpeciesList()

  -- Pick a species name by random
  local idx = math.random(1, #species_list)
  local random_species_name = species_list[idx]
  print("Using species "..random_species_name)
  
  select_species(random_species_name)
end


function init()
  print("Initing Taweeet...")
  
  -- Startup softcut
  softcut_init()

  parameters_init()

  -- Initialize sound engine
  engine.hz(40)
  
  --Load in a species
  init_random_species()
end


function redraw(called_from_clock_tick)
  -- If called be the system then the png and wav files might not
  -- yet be ready. So only continue if called by intro_tick()
  if not called_from_clock_tick then return end
  
  if debug_mode then print("in redraw()") end
  
  -- Always start by clearing screen
  screen.clear()
  
  -- Draw moving image. Have it scroll left to right until it is in the middle of screen
  png_width = global_species_data.width
  png_height = global_species_data.height
  
  local png_y = (64-png_height)/2
  local png_x = -png_width + 6*current_count
  if png_x > (128-png_width)/2 then 
    -- Reached desired horizontal position so don't increase png_x anymore
    if debug_mode then print("png centered!") end
    png_x = (128-png_width)/2
  end
  
  -- Actually draw the image buffer
  screen.display_image(global_species_data.image_buffer, png_x, png_y)
  
  -- Draw some vertically moving name of the species.
  -- First draw a darker rectangle so text will be readable. And to
  -- do that first need to figure out proper font size for the species name.
  screen.font_face(3)
  local font_size = 15 -- Will actually start with font 14
  local horiz_padding = 4
  repeat  
    font_size = font_size - 1
    screen.font_size(font_size)
    text_width = screen.text_extents(global_species_data.species_name)
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
  screen.aa(0)
  screen.move(rectangle_x + horiz_padding, rectangle_y - 2 + font_size)
  screen.text(global_species_data.species_name)
  
  -- update so that drawing actually visible
  screen.update()
  
  if debug_mode then print("Done with redraw()") end
  
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
  
  if n == 3 and down == 1 then
    print("button 3 down")
  end
  
  if n == 2 then
    engine.hz(100 + 100*down)
  end
end

function enc(n, delta)
  print("n=" .. n .. " delta=" .. delta)
end



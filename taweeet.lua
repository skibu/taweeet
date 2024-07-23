-- Taweeet
-- Because birdsong is beautiful
-- 0.0.3 attempt
--
-- Click on N3 to start

include "lib/get"
include "lib/util"


debug = false

species_table = nil
species = nil
current_count = 0 -- incremented every clock tick
png_filename, png_width, png_height = nil, nil, nil

-- So can play a simple sound
engine.name = "TestSine"


-- Called everytime the metro clock ticks
function tick(count)
  current_count = count
  if debug then print("current_count="..current_count) end
  redraw()
end


function init()
  print("initing...")
  
  -- Initialize sound engine
  engine.hz(300)
  
  -- Get list of species
  species_table = getSpeciesTable()
  print("Species table size=" .. #species_table)
  
  -- Pick a species by random
  local idx = math.random(1, #species_table)
  species = species_table[idx]
  print("In init species="..species)
  
  -- Get species by category so that can reduce size of the lists
  species_by_category = getSpeciesByCategoryTable()
  print("Read in "..#species_by_category.." categories of species")
  
  -- Load in wav file for species
  print("about to call getSpeciesWavFile()...")
  wav_url = "https://cdn.download.ams.birds.cornell.edu/api/v2/asset/72059761/mp3"
  catalog = "ML72059761" -- FIXME
  wav_filename = getSpeciesWavFile(wav_url, species, catalog)
    
  -- Load random png for species
  print("Getting random png for species "..species.."...")
  png_filename, png_width, png_height = storeRandomPng(species)
  print("png_width="..png_width.." png_height="..png_height.." png_filename="..png_filename)
  
  -- Start up the timer
  intro_counter = metro.init(tick, 0.05, -1)
  intro_counter:start()
end


function redraw()
  if debug then print("in redraw()") end
  
  -- Always start by clearing screen
  screen.clear()
  
  -- Draw some vertically moving text just for fun
  if debug then
    screen.level(15)
    screen.aa(1)
    screen.font_face(4)
    screen.font_size(10)
    screen.move(0,current_count)
    screen.text("vertical text ".. current_count)
  end
  
  -- Draw moving image. Have it scroll left to right until it is in the middle of screen
  --screen.display_png(png_filename, (128-png_width)/2, (64-png_height)/2)
  local png_y = (64-png_height)/2
  local png_x = -png_width + 6*current_count
  if png_x > (128-png_width)/2 then 
    -- Reached desired horizontal position so don't increase png_x anymore
    if debug then print("png centered!") end
    png_x = (128-png_width)/2
  end
  screen.display_png(png_filename, png_x, png_y)

  -- Draw some vertically moving name of the species.
  -- First draw a darker rectangle so text will be readable. And to
  -- do that first need to figure out proper font size for the species name.
  screen.font_face(4)
  local font_size = 15 -- Will actually start with font 14
  local horiz_padding = 4
  repeat  
    font_size = font_size - 1
    screen.font_size(font_size)
    text_width = screen.text_extents(species)
  until (text_width <= 128)
  
  -- rectangle_x is static and easy to determine
  local rectangle_x = (128 - text_width - 2*horiz_padding) / 2
  
  -- Since moving downwards but pausing at certain height, rectanble_y is more difficult
  local rectangle_y_pause = 58 -- Where rectangle should pause
  local pause_ticks = 20       -- How long to pause there
  local rectangle_y = current_count - font_size - 1
  if current_count > rectangle_y_pause and current_count <= rectangle_y_pause + pause_ticks then
    rectangle_y = rectangle_y_pause - font_size - 1
  elseif current_count > rectangle_y_pause + pause_ticks then
    rectangle_y = current_count - pause_ticks - font_size - 1
  end
  
  screen.level(5)
  screen.rect (rectangle_x, rectangle_y, 
    text_width + 2*horiz_padding, font_size+1)
  screen.fill()
  
  screen.level(15)
  screen.aa(1)
  screen.move(rectangle_x + horiz_padding, rectangle_y - 2 + font_size)
  screen.text(species)
  
  -- update so that drawing actually visible
  screen.update()
  
  if debug then print("Done with redraw()") end
  
  if rectangle_y > 64 then
    intro_counter:stop()
    print("Done with intro so intro_counter stopped")
  end
  
end
  

function key(n, down)
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



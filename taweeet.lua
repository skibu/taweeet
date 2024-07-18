-- taweeet
-- 0.0.1 attempt

include "lib/get"
include "lib/util"

-- Audio = require "audio"

util = require 'util'

-- So can play a simple sound
engine.name = "TestSine"

image_buffer_to_display = nil
species_table = nil
species = nil


function init()
  print("initing...")
  
  -- Initialize sound engine
  engine.hz(300)
  
  -- Init screen
  screen.level(15)
  
  -- Get list of species
  species_table = getSpeciesTable()
  print("Species table size=" .. #species_table)
  
  -- Pick a species by random
  local idx = math.random(1, #species_table)
  species = species_table[idx]
  print("In init species="..species)
end


function redraw()
  print("in redraw new()")
  -- Always start by clearing screen
  screen.clear()
  
  if image_buffer_to_display ~= nil then
    print("updating screen...")
    print(image_buffer_to_display)
    w, h = extents(image_buffer_to_display)
    print("====> w="..w.." h="..h)
    screen.display_image(image_buffer_to_display, (128-w)/2, (64-h)/2)
    print("updated screen")
  end

  -- update so that drawing actually visible
  screen.update()
end
  

function key(n, down)
  print("down="..down)
  
  if down == 1 then
    print("about to call getSpeciesWavFile()...")
    wav_url = "https://cdn.download.ams.birds.cornell.edu/api/v2/asset/72059761/mp3"
    -- FIXME species = "American Avocet"
    catalog = "ML72059761" -- FIXME
    full_filename = getSpeciesWavFile(wav_url, species, catalog)
    
    print("Getting random png for species "..species.."...")
    image_buffer_to_display = getPngBuffer(species)
    
    -- Now that have image loaded need to redraw
    redraw()
  end
  
  if n == 3 then
    engine.hz(100 + 100*down)
  end
end

function enc(n, delta)
  print("n=" .. n .. " delta=" .. delta)
end



-- taweeet
-- first attempt

include "lib/get"

-- Audio = require "audio"

util = require 'util'

-- So can play a simple sound
engine.name = "TestSine"

function init()
  print("initing...")
  engine.hz(300)
end

function key(n, down)
  print("down="..down)
  
  if down == 1 then
    print("about to call getSpeciesWavFile()...")
    species = "American Avocet"
    catalog = "ML72059761"
    full_filename = getSpeciesWavFile(
      "https://cdn.download.ams.birds.cornell.edu/api/v2/asset/72059761/mp3", 
      species, catalog)
    
    tbl = getSpeciesTable()
    print("Species table size=" .. #tbl)
  end
  
  
  if n == 3 then
    engine.hz(100 + 100*down)
  end
end

function enc(n, delta)
  print("n=" .. n .. " delta=" .. delta)
end



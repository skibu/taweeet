-- taweeet
-- first attempt

include "lib/files"

util = require 'util'

-- So can play a simple sound
engine.name = "TestSine"

function init()
  print("initing...")
  engine.hz(300)
end

function key(n, down)
  print("about to call os_capture()...")
  ret = getFile("https://httpbin.org/robots.txt", "wav")
  print("ret=" .. ret)

  if n == 3 then
    engine.hz(100 + 100*down)
  end
end

function enc(n, delta)
  print("n=" .. n .. " delta=" .. delta)
end

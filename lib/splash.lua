-- For displaying splash screen at startup

-- Note: for creating splash image as Norns png can put an image on google 
-- drive and then get a link to it, and then call Imager/getPng() to convert 
-- the image. If need to encode the url can use https://www.urlencoder.org/.
-- And if you put an image onto google drive then you can use
-- https://sites.google.com/site/gdocs2direct/ to get a link directly to the 
-- image so that Imager can access it and convert it into a Norns compatible PNG.

local splash_screen_displayed_via_redraw = false
local display_time = 0

-- Intended to be called from redraw(). This is important because redraw() 
-- will otherwise erase any splash screen displayed at startup. But redraw()
-- is called multiple times, like everytime transition from menu windows 
-- back to the application window. Don't want splash screen to show up again
-- for when switching back to app window. 
-- min_time: minimum time in seconds that splash screen should be displayed for
-- returns: true if splash screen displayed
function display_splash_screen_once_via_redraw(min_time)
  -- If already displayed via redraw then don't need to do it again
  if splash_screen_displayed_via_redraw then return false end

  -- If want to make sure splash screen displayed for minimum amount of time.
  -- Need to determine sleep_time before display_splash_screen() is called since
  -- that will overwrite the display_time.
  local sleep_time = 0
  if min_time ~= nil then
    local elapsed_time = util.time() - display_time
    sleep_time = min_time - elapsed_time
  end
  
  -- Remember that was displayed once via redraw so can avoid doing it again
  splash_screen_displayed_via_redraw = true

  -- If still want splash screen, initiated at startup, to be displayed longer 
  -- then display it and sleep
  if sleep_time > 0 then  
    -- Need to display it
    display_splash_screen()
    
    -- Now that splash screen displayed again, sleep so that it is up desired amount of time
    util.debug_tprint("Sleeping ".. string.format("%.2f", sleep_time)..
        " sec to make sure splash screen displayed for min_time="..min_time.." sec")
    util.sleep(sleep_time)
    util.debug_tprint("Done sleeping for splash screen")
  end
end

  
-- Can be called directly from init() to display splash screen before get to redraw().
-- This way splash screen is displayed immediately.
function display_splash_screen()
  -- Splash image is from git so it is in the app's code directory
  local filename = norns.state.path .. "images/splash.png"
  local width, height = screen.extents(filename)
  
  -- Display splash image
  screen.clear()
  screen.display_png(filename, (128-width)/2, (64-height)/2)
  screen.update()
  
  -- Remember when first displayed in case want to make sure it is displayed
  -- for at least a minimum of time
  display_time = util.time()
  util.debug_tprint("Splash screen displayed")
end
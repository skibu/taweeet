-- Provides UI so that user can change the start and stop time of a looping
-- soundclip. The UI provides a display of the amplitude of the sound clip
-- versus time.


local ClipAudio = {
  is_enabled = false
}


-- Converts the audio in Softcut buffer into arrays that can be graphed
function ClipAudio.process_audio_data()
  log.debug("Processing audio data")
  
  softcut.event_phase(function(i,x)
    print(i,x)
    current_pos[i]=x
  end)


end


-- Does the actual drawing. Separate from clip_audio_redraw() in case script
-- wants to create other buttons in the interface.
function ClipAudio.draw_clip_ui(y)
  log.debug("In draw_clip_ui() and y="..y)
  screen.move(2, y)
  screen.level(screen.levels.HIGHLIGHT)
  screen.font_face(6)
  screen.font_size(16)
  screen.aa(1) -- Since font size 12 or greater
  screen.text("Clip Audio UI")
  screen.move(2, y+18)
  screen.text("Coming soon!")
  
  screen.move(2, 62)
  screen.level(screen.levels.HELP)
  screen.font_face(1)
  screen.font_size(8)
  screen.aa(0)
  screen.text("Press Key2 to exit")
end


function ClipAudio.exit()
  log.debug("Exiting clip audio UI")
  ClipAudio.enable(false)
  redraw()
end


function ClipAudio.enable(bool)
  ClipAudio.is_enabled = bool == nil or bool
  log.debug("In ClipAudio.enable() and enabled="..tostring(ClipAudio.is_enabled))
  
  -- Call redraw to display the special audio clip UI
  if ClipAudio.enabled() then 
    -- Get the raw data from softcut buffer
    ClipAudio.process_audio_data()
    
    -- Draw the graph
    redraw() 
  end
end


function ClipAudio.enabled()
  return ClipAudio.is_enabled ~= nil and ClipAudio.is_enabled
end


function ClipAudio.redraw()
  log.debug("In ClipAudio.redraw() and will call draw_clip_ui()")
  screen.clear()
  ClipAudio.draw_clip_ui(26)
  screen.update()
end


function ClipAudio.key(n, down)
  log.debug("ClipAudio key pressed n=" .. n .. " delta=" .. down)
  
  -- If key2 hit then exit clip audio mode
  if n == 2 then
    ClipAudio.exit()
  end
end


function ClipAudio.enc(n, delta)
  log.debug("ClipAudio encoder changed n=" .. n .. " delta=" .. delta)
end

return ClipAudio
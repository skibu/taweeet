-- Provides UI so that user can change the start and stop time of a looping
-- soundclip. The UI provides a display of the amplitude of the sound clip
-- versus time.


local ClipAudio = {
  is_enabled = false,
  data_v1 = nil, -- where data = {start, duration, sec_per_sample, samples, normalized_samples, largest_sample}
  data_v2 = nil,
  voice_duration = nil,
  loop_begin,
  loop_duration,
  graph_y_pos = nil
}


local LEFT = 14
local WIDTH = 100

local function draw_audio_channel(channel_data, up)
  local LEVEL_MIN = 5  -- screen level for smallest amplitude 
  local LEVEL_MAX = 11 -- screen level for largest amplitude
  local duration_per_pixel = ClipAudio.loop_duration / WIDTH
  local y_height_per_channel = math.floor((screen.HEIGHT - ClipAudio.graph_y_pos) / 2)
  local up_or_down = up and -1 or 1
  screen.line_width(1)
  screen.aa(0)
  
  -- FIXME draw a little line at y
  if false then
    local y_for_test_line = screen.HEIGHT - y_height_per_channel
    screen.level(5)
    screen.move(0, y_for_test_line)
    screen.line(LEFT-1, y_for_test_line)
    screen.stroke()
    
    screen.move(1, y_for_test_line+2)
    screen.line(LEFT-1, y_for_test_line+2)
    screen.stroke()
  end
  
  log.print("+++ In draw_audio_channel() and duration_per_pixel="..duration_per_pixel.." up_or_down="..up_or_down.." y_height_per_channel="..y_height_per_channel)
  
  -- For each vertical line (which corresponds to a time range)
  for line_x_cnt = 1, WIDTH do
    local ampl_line_end_time = ClipAudio.loop_begin + line_x_cnt*duration_per_pixel
    local ampl_line_begin_time = ampl_line_end_time - duration_per_pixel
    
    -- Determine which samples should be included in the timeslot for the pixel
    local sample_index_begin = math.floor(ampl_line_begin_time / channel_data.sec_per_sample) + 1
    local sample_index_end = math.floor(ampl_line_end_time / channel_data.sec_per_sample)
    
    local max_amplitude = 0 -- will be between 0 and 1.0
    local number_of_samples = 0
    for sample_index = sample_index_begin, sample_index_end do
      local amplitude = channel_data.normalized_samples[sample_index]
      if amplitude > max_amplitude then max_amplitude = amplitude end
      number_of_samples = number_of_samples + 1
    end
    
    -- Determine location of the amplitude line
    local x = LEFT + line_x_cnt
    local y = screen.HEIGHT - y_height_per_channel
    
    -- Determine color/level for the amplitude line. The idea is to use the ability to have
    -- different levels to highlight the larger amplitudes.
    local level_for_amplitude = math.floor(LEVEL_MIN + max_amplitude * (LEVEL_MAX - LEVEL_MIN) + 0.5)
    local length_of_line = max_amplitude * y_height_per_channel
    local length_of_line_in_pixels = math.floor(length_of_line)
    local remainder = length_of_line - length_of_line_in_pixels
    local end_of_line_y = y + up_or_down*length_of_line_in_pixels
    -- Draw max amplitude line if it is at least 1 pixel long
    if length_of_line_in_pixels >= 1 then
      -- Actually draw the amplitude line
      screen.level(level_for_amplitude)
      screen.move(x, y)
      screen.line(x, end_of_line_y)
      screen.stroke()
    end
    
    -- Draw single pixel at end of line, using level to indicate how much beyond the 
    -- line it should go. The pixel should be at a level proportional to the fractional
    -- value of the average amplitude. 
    local pixel_level = level_for_amplitude * remainder
    local pixel_x
    local pixel_y
    if pixel_level > 1.0 then
      screen.level(pixel_level)
      -- Note: for pixel() pixel_x, pixel_y are the actual pixel coordinate
      pixel_x = x - 1
      pixel_y = end_of_line_y
      if up then pixel_y = pixel_y -1 end
      screen.pixel(pixel_x, pixel_y) 
      screen.fill()
    end
    
    -- If at beginning or end of the active audio area then draw vertical line as a y axis.
    -- The line starts just above the audio amplitude line, with a 1 pixel gap to indicate
    -- the difference.
    if line_x_cnt == 1 or line_x_cnt == WIDTH then
      screen.level(4)
      screen.move(x, end_of_line_y + 2*up_or_down)
      screen.line(x, y + up_or_down*y_height_per_channel)
      screen.stroke()
    end
    
    -- For debugging
    --log.print("=== line_x_cnt="..line_x_cnt.." max_amplitude="..string.format("%.4f", max_amplitude).." length_of_line="..string.format("%.2f", length_of_line) .." length_of_line_in_pixels="..length_of_line_in_pixels.." number_of_samples="..number_of_samples.." level_for_amplitude="..level_for_amplitude)
    --log.print("--- x="..x.." y="..y.." end_of_line_y="..end_of_line_y.." pixel_level="..string.format("%.2f", pixel_level).." pixel_x="..tostring(pixel_x).." pixel_y="..tostring(pixel_y))
  end
end


--- Does the actual drawing of the audio clip. Separate from ClipAudio.redraw() in 
-- case script wants to create other buttons in the interface. Does not do 
-- screen.clear() nor screen.update(). Those need to be done by the custom redraw()
-- function that draws the other UI elements on the screen.
function ClipAudio.draw_audio_graph()
  log.debug("In draw_audio_graph() and ClipAudio.graph_y_pos="..ClipAudio.graph_y_pos)
  
  -- debugging
  -- data = {start, duration, sec_per_sample, samples}
  local d1 = ClipAudio.data_v1
  if d1 ~= nil then
    log.debug("d1.start="..d1.start.." d1.duration="..d1.duration.." #d1.samples="..#d1.samples..
      " d1.largest_sample="..d1.largest_sample)
  end
  
  local d2 = ClipAudio.data_v2
  if d2 ~= nil then
    log.debug("d2.start="..d2.start.." d2.duration="..d2.duration.." #d2.samples="..#d2.samples..
      " d2.largest_sample="..d2.largest_sample)
  end
  
  -- Display the duration at top of audio display, just below the custom display area
  screen.move(screen.WIDTH/2, ClipAudio.graph_y_pos + 6)
  screen.level(8)
  screen.font_face(1)
  screen.font_size(8)
  screen.aa(0)
  screen.text_center(string.format("<- %.2fs ->", ClipAudio.loop_duration))
  
  -- Display loop begin time in lower left corner
  screen.text_rotate (LEFT-2, screen.HEIGHT, string.format("%.2fs", ClipAudio.loop_begin), -90)

  -- Display loop end time in lower right corner
  screen.text_rotate (LEFT + WIDTH + 7, screen.HEIGHT, 
    string.format("%.2fs", ClipAudio.loop_begin+ ClipAudio.loop_duration), -90)
  
  -- Add help info to bottom
  screen.move(screen.WIDTH/2, screen.HEIGHT-2)
  screen.level(screen.levels.HELP)
  screen.font_face(1)
  screen.font_size(8)
  screen.aa(0)
  screen.text_center("Press Key2 to exit")
  
  -- Draw each channel, if have data for them
  if d1 ~= nil then draw_audio_channel(d1, true) end
  if d2 ~= nil then draw_audio_channel(d2, false) end
end


-- Returns duration of the wav file in seconds
function ClipAudio.wav_file_duration(filename)
  -- Determine and return audio length
  local ch, samples, samplerate = audio.file_info(filename)
  local duration = samples/samplerate
  log.debug("In wav_file_duration() and duration="..duration.." for filename="..filename)
  return duration
end


--- Called via softcut.event_phase(callback) at the update rate specified by 
-- softcut.phase_quant(rate)
-- @tparam number voice which voice
-- @tparam number position the current position in the voice, in seconds
local function new_audio_position_callback(voice, position)
  --log.print("New audio position. voice="..voice.." position="..position)
end


--- Called via softcut.event_render(callback) when softcut.render_buffer() is called
-- and the data has been processed. Used to convert a voice into a smaller sample rate
-- so that the data can be used to visualize the amplitude of the audio clip.
local function buffer_content_processed_callback(ch, start, sec_per_sample, samples)
  log.debug("In buffer_content_processed_callback() ch="..ch.." start="..start..
    " sec_per_sample="..sec_per_sample.." #samples="..#samples)

  -- Want to normalize the samples so that the largest absolute value is 1.0.
  -- This way the audio graph will be as tall as possible.
  local largest_sample = 0
  for _, sample in ipairs(samples) do
    if math.abs(sample) > largest_sample then largest_sample = math.abs(sample) end
  end
  
  local normalized_samples = {}
  for _, sample in ipairs(samples) do
    table.insert(normalized_samples, math.abs(sample) / largest_sample)
  end

  -- Store the data so that it can be drawn
  local data = {
    start = start,
    duration = sec_per_sample * #samples,
    sec_per_sample = sec_per_sample,
    samples = samples,
    normalized_samples = normalized_samples,
    largest_sample = largest_sample
  }
  
  if ch == 1 then
    ClipAudio.data_v1 = data
  else
    ClipAudio.data_v2 = data
  end
  
  -- Since have processed data should draw the audio graphs
  ClipAudio.draw_audio_graph()
  screen.update()
end


-- Converts the audio in Softcut buffer into data arrays that can be graphed. 
-- buffer_content_processed_callback() is called when the data has finished
-- being processed.
-- @tparam number voice_duration length in seconds of the voice
function ClipAudio.initiate_audio_data_processing(voice_duration)
  log.debug("Processing audio data and voice_duration="..tostring(voice_duration))
  
  -- register callbacks that handles the resampled audio data.
  -- And then initiate the resampling
  softcut.event_render(buffer_content_processed_callback)
  for ch=1,2 do
    local start = 0
    local max_samples = 200 * voice_duration -- 200 samples per second
    softcut.render_buffer(ch, start, voice_duration, max_samples)
  end
  
  -- Configure so that new_audio_position_callback() is called every update_rate
  -- seconds. This allows an indicator to be drawn that shows where in clip we are.
  local update_rate = 0.1 -- seconds
  softcut.phase_quant(1, update_rate)
  softcut.phase_quant(2, update_rate)
  softcut.event_phase(new_audio_position_callback)
  softcut.poll_start_phase()
end


--- Called automatically when key2 is hit by user to exit the page
function ClipAudio.exit()
  log.debug("Exiting clip audio UI")
   
  -- Stop polling of audio phase since it takes resources
  softcut.poll_stop_phase()
  
  -- Mark as disabled
  ClipAudio.disable()
  
  -- Clear the other params
  ClipAudio.data_v1 = nil
  ClipAudio.data_v2 = nil
  ClipAudio.voice_duration = nil
  ClipAudio.graph_y_pos = nil
  
  -- Call the app's redraw since exiting the audio graph screen
  redraw() 
end


function ClipAudio.disable()
  log.debug("In ClipAudio.disable()")
  ClipAudio.is_enabled = false
end


--- Used to setup audio clip screen and switch to it.
-- @tparam number graph_y_pos y pixel value, below which can be used for displaying audio
-- @tparam number voice_duration length of the voice in seconds
-- @tparam number loop_begin Where in voice the loop begin is. If nil then will use beginning of voice
-- @tparam number loop_duration Where in voice the loop ends. If nil then will use end of voice
function ClipAudio.enable(graph_y_pos, voice_duration, loop_begin, loop_duration)
  log.debug("In ClipAudio.enable() and graph_y_pos="..tostring(graph_y_pos)..
    " voice_duration="..tostring(voice_duration))
  
  -- Keep track of params
  ClipAudio.is_enabled = true
  ClipAudio.graph_y_pos = graph_y_pos
  ClipAudio.voice_duration = voice_duration
  ClipAudio.loop_begin = loop_begin ~= nil and loop_begin or 0
  ClipAudio.loop_duration = loop_duration ~= nil and loop_duration 
                                                  or (voice_duration - ClipAudio.loop_begin)
  
  -- Get the raw data from softcut buffer
  ClipAudio.initiate_audio_data_processing(voice_duration)
    
  -- Call redraw to display the special audio clip screen
  redraw()
end


--- Returns true if clipAudio screen is currently enabled
function ClipAudio.enabled()
  return ClipAudio.is_enabled ~= nil and ClipAudio.is_enabled
end


--- Does full drawing of the audio clip.
-- Includes doing screen.clear() at beginning and screen.update() at end.
-- If want to add other UI elements then should create own redraw function
-- that does the clear(), outputs the custom UI, calls ClipAudio.draw_audio_graph(26)
-- to draw the audio graph, and then calls update().
function ClipAudio.redraw()
  log.debug("FIXME NOT NEEDED! In ClipAudio.redraw() and will call draw_audio_graph()")
  screen.clear()
  ClipAudio.draw_audio_graph(26)
  screen.update()
end


-- If k3 is down then use fine resolution mode for ehcoders
local k3_down = false

local function encoder_increment()
  return k3_down and 0.05 or 0.5
end


function ClipAudio.key(n, down)
  log.debug("ClipAudio key pressed n=" .. n .. " delta=" .. down)
  
  -- If key2 hit then exit clip audio mode
  if n == 2 then
    ClipAudio.exit()
  end
  
  -- If it is key3 then update variable k3_down
  if n == 3 then
    k3_down = (down == 1)
  end
end


local MIN_LOOP_DURATION = 0.1

function ClipAudio.enc(n, delta)
  log.debug("ClipAudio encoder changed n=" .. n .. " delta=" .. delta)
  
  if n == 2 then
    -- encoder 2 turned so adjust loop begin time
    ClipAudio.loop_begin = util.clamp(ClipAudio.loop_begin + encoder_increment() * delta, 
      0, ClipAudio.voice_duration - MIN_LOOP_DURATION)
    log.debug("ClipAudio.loop_begin=" .. string.format("%.2f", ClipAudio.loop_begin))
    
    -- Make sure the loop_duration is still valid
    if ClipAudio.loop_begin + ClipAudio.loop_duration > ClipAudio.voice_duration then
      ClipAudio.loop_duration = ClipAudio.voice_duration - ClipAudio.loop_begin
    end
    
    redraw()
  elseif n ==3 then
    -- encoder 3 turned so adjust loop duration
    ClipAudio.loop_duration = util.clamp(ClipAudio.loop_duration + encoder_increment() * delta, 
      MIN_LOOP_DURATION, ClipAudio.voice_duration - ClipAudio.loop_begin)
    
    log.debug("ClipAudio.loop_duration=" .. string.format("%.2f", ClipAudio.loop_duration))
    redraw()
  end
end

return ClipAudio
-- Startup
function softcut_init()
    softcut.buffer_clear()
end
  

-- Simple setup of looping a single mono channel using buffer1 and voice1   
function softcut_setup(filename, buffer_index, voice_index) 
  local buffer = softcut_load_file_mono(filename, buffer_index)

  softcut_reset_voice(voice_index, buffer_index, buffer.length)
end


local buffer1
local buffer2


-- Loads left channel of wav file into a buffer.
function softcut_load_file_mono(filename, buffer_index)
  print("Loading into buffer ".. buffer_index .. " wav file="..filename)
  
  softcut.buffer_read_mono(filename,
    0,  -- start at beginning of file
    0,  -- load into beginning of buffer
    -1, -- duration. -1 means read as much as possible
    1,  -- Load just channel 1. If want stereo then use buffer_read_stereo(), but uses both buffers
    buffer_index)
  
  local buffer = {index=buffer_index, filename=filename, length=wav_file_length(filename) }

  -- Set the globals so all info will be maintained
  if buffer_index == 1 then
    buffer1 = buffer
  else
    buffer2 = buffer
  end

  return buffer
end


-- Resets a voice to default values where will loop through an audio buffer
function softcut_reset_voice(voice_index, buffer_index, length)
  print("softcut_reset_voice() Resetting voice ".. voice_index .. 
    " and buffer_index "..buffer_index.." and length="..length)

  -- Enable voice by setting it to 1
  softcut.enable(voice_index, 1)

  -- Which buffer should be used (1 or 2)
  softcut.buffer(voice_index, buffer_index)

  -- Full audio level
  softcut.level(voice_index, 1.0)

  -- Set to loop continuouslyl
  softcut.loop(voice_index, 1)

  -- Start loop at beginning, 0.0 seconds
  softcut.loop_start(voice_index, 0.0)

  -- Play till end of loop, length of loop seconds
  softcut.loop_end(voice_index, length)

  -- Where to stop playing, in seconds
  softcut.position(voice_index, 0.0)

  -- Playback speed. 1.0 is normal speed
  softcut.rate(voice_index, 1.0)

  -- Sets to play status, which presumably means to start playinug the clip
  softcut.play(voice_index, 1)
end


-- Returns length of the wav file
function wav_file_length(filename)
  local ch, samples, samplerate = audio.file_info(filename)
  return samples/samplerate
end


-- Displays info for the specified wav file. Useful for seeing that 
-- the wav file has proper format.
function print_wav_file_info(filename)
  if util.file_exists(filename) == true then
    local ch, samples, samplerate = audio.file_info(filename)
    local duration = samples/samplerate
    print("For file: "..filename)
    print("  channels:\t"..ch)
    print("  samples:\t"..samples)
    print("  sample rate:\t"..samplerate.."hz")
    print("  duration:\t"..duration.." sec")
  else 
    print "read_wav(): file not found" 
  end
end

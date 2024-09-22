-- Startup
function softcut_init()
  softcut.buffer_clear()
end
  

-- Simple setup of looping two stereo channels using buffers 1 & 2 and voice1   
function softcut_setup_stereo(filename, voice_index_l, voice_index_r) 
  log.print("softcut_setup_stereo() buffers 1 & 2"..
    " voice_index_l="..voice_index_l.." voice_index_r="..voice_index_r..
    " filename="..filename)
  local buffer = softcut_load_file_stereo(filename)

  softcut_setup_voices_stereo(voice_index_l, voice_index_r, buffer.length)
end


-- Simple setup of looping a single mono channel using buffer1 and the voice specified  
function softcut_setup_mono(filename, buffer_index, voice_index) 
  log.debug("softcut_setup_mono() buffer_index="..buffer_index.." voice_index="..voice_index..
    " filename="..filename)
  local buffer = softcut_load_file_mono(filename, buffer_index)

  softcut_setup_voice_mono(voice_index, buffer_index, buffer.length)
end


local buffer_mono_1
local buffer_mono_2
local buffer_stereo


-- Loads both channels of wav file into two buffers so that can play stereo
function softcut_load_file_stereo(filename)
  log.debug("Loading into stereo buffers wav file="..filename)
  
  softcut.buffer_read_stereo(
    filename,
    0,  -- start at beginning of file
    0,  -- load into beginning of buffer 
    -1) -- duration. -1 means read as much as possible

  buffer_stereo = {filename=filename, length=wav_file_length(filename) }

  return buffer_stereo
end


-- Sets up two voices for a stereo channel
function softcut_setup_voices_stereo(voice_index_l, voice_index_r, length) 
  log.debug("Setting up stereo voices" ..
    " voice_index_l=".. voice_index_l .. 
    " voice_index_r=".. voice_index_r .. 
    " length="..length.."s")

  -- Setup left channel
  buffer_index_l = 1
  softcut_setup_voice_mono(voice_index_l, 1, length)
  softcut.pan(voice_index_l, -1)
  
  -- Setup right channel
  buffer_index_r = 2
  softcut_setup_voice_mono(voice_index_r, 2, length)
  softcut.pan(voice_index_l, 1)
end


-- Loads left channel of wav file into a buffer.
local function softcut_load_file_mono(filename, buffer_index)
  log.debug("Loading into mono buffer ".. buffer_index .. " wav file="..filename)
  
  softcut.buffer_read_mono(
    filename,
    0,  -- start at beginning of file
    0,  -- load into beginning of buffer 
    -1, -- duration. -1 means read as much as possible
    1,  -- Load just channel 1. If want stereo then use buffer_read_stereo(), but uses both buffers
    buffer_index) -- Destination
  
  local buffer = {index=buffer_index, filename=filename, length=wav_file_length(filename) }

  -- Set the globals so all info will be maintained
  if buffer_index == 1 then
    buffer_mono_1 = buffer
  else
    buffer_mono_2 = buffer
  end

  return buffer
end


-- Resets a mono voice to default values where will loop through an audio buffer
function softcut_setup_voice_mono(voice_index, buffer_index, length)
  log.debug("Setting up mono voice ".. voice_index .. 
    " and buffer_index "..buffer_index.." and length="..length.."s")

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

  -- Where to start playing, in seconds
  softcut.position(voice_index, 0.0)

  -- Playback speed. 1.0 is normal speed
  softcut.rate(voice_index, 1.0)

  -- Sets to play status, which presumably means to start playinug the clip
  softcut.play(voice_index, 1)
end


-- Returns length of the wav file in seconds
function wav_file_length(filename)
  -- Determine and return audio length
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
    print("  duration:\t"..duration.."s")
  else 
    print "read_wav(): file not found" 
  end
end

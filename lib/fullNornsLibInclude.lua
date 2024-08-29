-- This file shows how nornsLib can be included. It is recommended that the 
-- application developer copy this file to their application, modify as needed,
-- and then include it. 

-- If nornsLib doesn't exist on user's Norns device then clone it from GitHub
if not util.file_exists(_path.code.."nornsLib") then
  os.execute("git clone https://github.com/skibu/nornsLib.git ".._path.code.."nornsLib")
end

-- Include this file if app should auto update nornsLib to pick up the latest
-- greatest version
--include "nornsLib/updateLib"

-- Include the appropriate nornsLib extensions. Or more easily, just load all of them
-- using includeAllExt.
include "nornsLib/includeAllExt"
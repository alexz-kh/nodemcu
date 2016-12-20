-- this lib copy-pasted from https://github.com/SergSlipushenko/espinaca/blob/master/core/

--ftr = require 'futures'

ldfile = function(fname, m)
    if m then return m
    else if file.exists(fname) then return dofile(fname) end end
end

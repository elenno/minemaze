local lsocket = require "lsocket"
local utils = require "utils"

local socket = {}
local fd
local message

socket.error = setmetatable({}, { __tostring = function() return "[socket error]" end } )

function socket.connect(addr, port)
	assert(fd == nil)
	fd = lsocket.connect(addr, port)
	if fd == nil then
		error(socket.error)
	end

	lsocket.select(nil, {fd})
	local ok, errmsg = fd:status()
	if not ok then
		error(socket.error)
	end

	message = ""
end

function socket.isconnect(ti)
	local rd, wt = lsocket.select(nil, { fd }, ti)
	return next(wt) ~= nil
end

function socket.close()
	fd:close()
	fd = nil
	message = nil
end

function socket.read(ti)
	while true do
	    --local ok, buf_head, buf_body, ch_end = pcall(string.unpack, ">s2s2c1", message)
		local ok, msg, n = pcall(string.unpack, ">s2", message)
		utils.print("socket reading... ")
		if not ok then
			local rd = lsocket.select({fd}, ti) 
			if not rd then
				return nil
			end
			if next(rd) == nil then
				return nil
			end
			local p = fd:recv()
			if not p then
				error(socket.error)
			end
			message = message .. p
		else
			message = message:sub(n)
			utils.print("socket read succ, msg=" .. msg .. " len=" .. n)
			return msg
		end
	end
end

-- function socket.read(ti)
-- 	while true do
-- 		local ok, msg, n = pcall(string.unpack, ">s2", message)
-- 		utils.print("msg sds= " .. message)
-- 		if not ok then
-- 			local rd = lsocket.select({fd}, ti) 
-- 			if not rd then
-- 				return nil
-- 			end
-- 			if next(rd) == nil then
-- 				return nil
-- 			end
-- 			local p = fd:recv()
-- 			if not p then
-- 				error(socket.error)
-- 			end
-- 			message = message .. p
-- 		else
-- 			message = message:sub(n)
-- 			return msg
-- 		end
-- 	end
-- end

function socket.write(msg)
	local pack = msg
	repeat
		local bytes = fd:send(pack)
		--error("send bytes:" .. bytes)
		if not bytes then
			error(socket.error)
		end
		pack = pack:sub(bytes+1)
	until pack == ""
end

return socket

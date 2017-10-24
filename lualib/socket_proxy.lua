local skynet = require "skynet"
local log = require "log"
local utils = require "utils"

local proxyd

skynet.init(function()
	proxyd = skynet.uniqueservice "socket_proxyd"
end)

local proxy = {}
local map = {}

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	pack = function(text) return text end,
	unpack = function(buf, sz) return skynet.tostring(buf,sz) end,
	--unpack = function(buf, sz) return buf, sz end,
}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	pack = function(buf, sz) return buf, sz end,
}

local function get_addr(fd)
	if (map[fd] == nil) then
		log("map[fd=%d] dit not subscribe, return empty string")
		return ''
	end
	return assert(map[fd], "subscribe first")
end

function proxy.subscribe(fd)
	local addr = map[fd]
	if not addr then
		addr = skynet.call(proxyd, "lua", fd)
		map[fd] = addr
	end
end

function proxy.read(fd)
	local ok,msg,sz = pcall(skynet.rawcall , get_addr(fd), "text", "R")
	if ok then
		utils.print("sz=" .. sz)
		return msg,sz
	else
		map[fd] = nil
		error "disconnect"
	end
end

function proxy.write(fd, msg, sz)
	--log("proxy.write msg: " .. msg)
	utils.print("proxy.write = " .. msg .. " len = " .. sz)
	skynet.send(get_addr(fd), "client", msg, sz)
end

function proxy.close(fd)
	log("proxy.close")
	skynet.send(get_addr(fd), "text", "K")
	log("skynet send K")
end

function proxy.info(fd)
	return skynet.call(get_addr(fd), "text", "I")
end

return proxy




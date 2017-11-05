local skynet = require "skynet"
local proxy = require "socket_proxy"
--local sprotoloader = require "sprotoloader"
local log = require "log"
local service = require "service"
local protopack = require "protopack"
local utils = require "utils"

local client = {}
local host
local sender
local handler = {}

function client.handler()
	return handler
end

function client.dispatch( c )
	local fd = c.fd
	proxy.subscribe(fd)
	local manager_service = skynet.uniqueservice "manager"
	skynet.call(manager_service, "lua", "bind_client", fd)
	local ERROR = {}
	while true do
		local msg, sz = proxy.read(fd)
		local msg_str = skynet.tostring(msg, sz)
		utils.print("msg_str=" .. msg_str)
		local name, args = protopack.unpack(msg_str)
		--local type, name, args, response = host:dispatch(msg, sz)
		assert(name)
		if c.exit then
			return c
		end
		local f = handler[name]
		if f then
			-- f may block , so fork and run
			-- todo  这里不一定要fork  可能会出现后面的请求比前面的请求更早被处理
			skynet.fork(function()
				local ok, code, name, msg = pcall(f, c, args) --todo 改协议的返回哦  返回 { code = xxx, name = xxx, msg = xxx }
				if ok then
					local msg_proto, msg_len = protopack.pack(code, name, msg)
					utils.print("msg_name = " .. name ..  " msg_proto=" .. msg_proto .. " msg_len=" .. msg_len)
					proxy.write(fd, msg_proto, msg_len)	

					--local test_pbname, test_pbbody = protopack.unpack(msg_proto)
					--utils.print("test unpack=", test_pbname, test_pbbody)	
				else
					utils.print("client.dispatch pcall failed, name=" .. name)
				end
			end)
		else
			-- unsupported command, disconnected
			error ("Invalid command " .. name)
		end

		--todo update (5s or 10s one time is ok)
	end
end

function client.close(fd)
	proxy.close(fd)
	skynet.call(service.manager, "lua", "unbind_client", fd)
end

function client.push(c, t, data)
	local msg_proto, msg_len = protopack.pack(0, t, data)
	proxy.write(c.fd, msg_proto, msg_len)
end

function client.init(name)
		log("client.init pbc")
		pbc = skynet.uniqueservice("pbc")
    	protopack.pbc = pbc
		-- local protoloader = skynet.uniqueservice "protoloader"
		-- local slot = skynet.call(protoloader, "lua", "index", name .. ".c2s")
		-- host = sprotoloader.load(slot):host "package"
		-- local slot2 = skynet.call(protoloader, "lua", "index", name .. ".s2c")
		-- sender = host:attach(sprotoloader.load(slot2))
end

return client
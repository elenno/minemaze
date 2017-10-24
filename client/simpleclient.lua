local PATH,IP = ...

IP = IP or "127.0.0.1"

package.path = string.format("%s/client/?.lua;%s/skynet/lualib/?.lua", PATH, PATH)
package.cpath = string.format("%s/skynet/luaclib/?.so;%s/lsocket/?.so", PATH, PATH)

local socket = require "simplesocket"
local message = require "simplemessage"

message.register()

message.peer(IP, 5678)
message.connect()

local event = {}

message.bind({}, event)

function event:SCError(args)
	print("error", args.what, args.err)
end

function event:ping()
	print("ping")
	--message.request "ping"
end

function event:SCSignin(resp)
	print("signin!!!", resp.name, resp.ok)
	-- if resp.ok then
	-- 	message.request "ping"	-- should error before login
	-- 	message.request "login"
	-- else
	-- 	-- signin failed, signup
	-- 	message.request("signup", { userid = "alice" })
	-- end
end

function event:signup(resp)
	print("signup", resp.ok)
	if resp.ok then
		message.request("signin", { userid = "alice" })
	else
		error "Can't signup"
	end
end

function event:login(resp)
	print("login", resp.ok)
	if resp.ok then
		message.request "ping"
	else
		error "Can't login"
	end
end

function event:push(args)
	print("server push", args.text)
end

function event:test(resp)
	--print("resp test args= %d %d %s %d", resp.param1, resp.param2, resp.param3, resp.param4)
	--print("req test args= %d %d %s %d", req.param1, req.param2, req.param3, req.param4)
end

function event:upload_maze(args)
	print("upload maze")
end

function event:player_info(args)
	print("player_info 111" .. args.player_name)
end

message.request("CSSignin", { name = "alice" })
--message.request("test", { param1 = 1, param2 = 2, param3 = "test123", param4 = 3})
--[[
	message.request("upload_maze", {
	maze_name = "test_name",
		maze_height = 4,
		maze_width = 4,
		maze_map = "0000111100001111",
		start_pos_x = 0,
		start_pos_y = 0,
		end_pos_x = 1,
		end_pos_y = 1,
		head_line = "this is headline",
		head_line_remark = "this is remark",
		maze_setting_flag = 0
})
--]]

while true do
	message.update()
end

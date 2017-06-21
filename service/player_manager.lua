local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"
local Player = require "player"

local cli = client.handler()

local player_map = {}

local function on_login(userid) 
	
	
	--记录当前登录时间
	--下发相关数据（关卡等信息）
	
end

local function on_logout(userid) 

end

local function get_player(userid) 
	if not player_map[userid] then 
		--从数据库取数据到缓存

		--todo 暂时填简单的数据
		player_tmp = Player.new()
		player_tmp.role_id = 1
		player_tmp.role_name = "测试账号"
		player_tmp.userid = userid
		player_tmp.last_login_time = 0

		player_map[userid] = player_tmp
	end
		
	return player_map[userid]
end

local function save_player(userid, player)
	player_map[userid] = player

	--todo 写到数据库里
end
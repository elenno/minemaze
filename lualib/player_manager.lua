local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"
local Player = require "player"
local mongo_manager = require "mongo_manager"
local cli = client.handler()

TEST_PLAYER_ID = 1  --todo 测试用player_id

local player_map = {}
local player_manager = {}

function player_manager.on_login(player_id) 
	local player = player_manager.get_player(player_id)
	player.last_login_time = os.time()
	player_manager.save_player(player_id, player)
	--记录当前登录时间
	--下发相关数据（关卡等信息）
	
end

function player_manager.on_logout(player_id) 
	local player = player_manager.get_player(player_id)
	player.last_logout_time = os.time()
	player_manager.save_player(player_id, player)
end

function player_manager.get_player(player_id) 
	if not player_map[player_id] then 
		--从数据库取数据到缓存
		local player = mongo_manager.get_data("player", {player_id = player_id})
		if player then
			player_map[player_id] = player
		else
			--todo 暂时填简单的数据
			player_tmp = {}
			player_tmp.player_id = player_id
			player_tmp.player_name = "测试账号"
			player_tmp.last_login_time = 0
			player_tmp.last_logout_time = 0
			player_map[player_id] = player_tmp
		end
		
	end
		
	return player_map[player_id]
end

function player_manager.save_player(player_id, player)
	player_map[player_id] = player

	--todo 写到数据库里
	mongo_manager.save_data("player", {player_id = player_id}, player)
end

return player_manager
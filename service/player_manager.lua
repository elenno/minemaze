local skynet = require "skynet"
local service = require "service"
local log = require "log"
local mongo_manager = require "mongo_manager"
local ZZMathBit = require "tools/bit"

local player_map = {}
local player_manager = {}

function player_manager.on_login(player_id, net_id) 
	log("player_manager on_login   player_id:%d", player_id)
	local player_info = player_manager.get_player(player_id)
	player_info.last_login_time = os.time()
	player_info.net_id = net_id
	player_manager.save_player(player_id, player_info)
	--记录当前登录时间
	--下发相关数据（关卡等信息）
	
	player_manager.send_player_info(player_id, player_info)

	return player
end

function player_manager.on_logout(player_id) 
	local player_info = player_manager.get_player(player_id)
	player_info.last_logout_time = os.time()
	player_info.net_id = -1
	player_manager.save_player(player_id, player_info)
end

function player_manager.get_player(player_id) 
	if not player_map[player_id] then 
		--从数据库取数据到缓存
		local player = mongo_manager.get_data("player", {player_id = player_id})
		if player then
			player_map[player_id] = player
		else
			--todo 暂时填简单的数据
			local player_tmp = {}
			player_tmp.player_id = player_id
			player_tmp.player_name = "测试账号"
			player_tmp.last_login_time = 0
			player_tmp.last_logout_time = 0
			player_tmp.story_record = 0 -- 用位运算，去表示7个故事关卡的完成情况
			player_tmp.challenging_maze_type = -1 -- 正在挑战的迷宫类型
			player_tmp.challenging_maze_id = -1 -- 正在挑战的迷宫id
			player_tmp.face_direction = 0 -- 朝向（ 0 1 2 3 ）
			player_tmp.cur_pos_x = -1
			player_tmp.cur_pos_y = -1
			player_tmp.net_id = -1
			player_map[player_id] = player_tmp
		end
		
	end
		
	return player_map[player_id]
end

function player_manager.save_player(player_id, player)
	player_map[player_id] = player

	--写到数据库里
	mongo_manager.save_data("player", {player_id = player_id}, player)
end

function player_manager.send_player_info(player_id, player_info)
	local proto = {}
	proto.player_id = player_info.player_id
	proto.player_name = player_info.player_name
	proto.story_record = player_info.story_record
	proto.challenging_maze_type = player_info.challenging_maze_type
	proto.challenging_maze_id = player_info.challenging_maze_id
	proto.face_direction = player_info.face_direction
	proto.cur_pos_x = player_info.cur_pos_x
	proto.cur_pos_y = player_info.cur_pos_y

	--调用某方法把proto传出去

	local manager_service = skynet.uniqueservice "manager"
	skynet.call(manager_service, "lua", "push_proto", player_info.net_id, "player_info", proto)
end

function player_manager.start_challenge(player_id, maze_type, maze_id)
	local player_info = player_manager.get_player(player_id)
	if not player_info then
		return
	end

	player_info.challenging_maze_type = maze_type
	player_info.challenging_maze_id = maze_id
	--player_info.face_direction = 0   todo  根据maze_type读取该地图

	player_manager.send_player_info(player_id, player_info)
end

function player_manager.finish_challenge(player_id, maze_type, maze_id)
	local player_info = player_manager.get_player(player_id)
	if not player_info then
		return false
	end

	if player_info.challenging_maze_type ~= maze_type then
		return false 
	end

	if player_info.challenging_maze_id ~= maze_id then
		return false 
	end

	--todo 检测maze_type maze_id合法性 配合配置

	player_info.challenging_maze_type = -1
	player_info.challenging_maze_id = -1
	player_info.face_direction = 0
	player_info.cur_pos_x = -1
	player_info.cur_pos_y = -1

	if maze_type == 0 then --todo 判断是否故事模式
		player_info.story_record = player_info.story_record + ZZMathBit.orOp(1, maze_id)
	end

	player_manager.send_player_info(player_id, player_info)
end

service.init {
	command = player_manager,
	info = player_map,
}
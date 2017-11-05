--给客户端请求的返回码

local ret_arr = {
    UNKNOWN_ERROR = -1,                             --未知错误
    OK = 0,                                         --成功
    
    --登录
    LOGIN_GUEST_REGISTER_FAIL = 201,                --游客用户创建失败
    LOGIN_PLATFORM_ERROR = 202,                     --平台编号错误
    LOGIN_GUEST_MUST_SIGNUP_FIRST = 203,            --游客需要先注册
    USER_NAME_ALREADY_BEEN_REGISTERED = 204,        --用户名已被注册
    
}

return ret_arr
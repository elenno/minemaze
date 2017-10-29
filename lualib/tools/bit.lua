--与   同为1，则为1  
   
--或   有一个为1，则为1    
  
--非   true为 false，其余为true  
  
--异或 相同为0，不同为1  
  
local ZZMathBit = {}  
  
function ZZMathBit.__andBit(left,right)    --与  
    return (left == 1 and right == 1) and 1 or 0  
end  
  
function ZZMathBit.__orBit(left, right)    --或  
    return (left == 1 or right == 1) and 1 or 0  
end  
  
function ZZMathBit.__xorBit(left, right)   --异或  
    return (left + right) == 1 and 1 or 0  
end  
  
function ZZMathBit.__base(left, right, op) --对每一位进行op运算，然后将值返回  
    if left < right then  
        left, right = right, left  
    end  
    local res = 0  
    local shift = 1  
    while left ~= 0 do  
        local ra = left % 2    --取得每一位(最右边)  
        local rb = right % 2     
        res = shift * op(ra,rb) + res  
        shift = shift * 2  
        left = math.modf( left / 2)  --右移  
        right = math.modf( right / 2)  
    end  
    return res  
end  
  
function ZZMathBit.andOp(left, right)  
    return ZZMathBit.__base(left, right, ZZMathBit.__andBit)  
end  
  
function ZZMathBit.xorOp(left, right)  
    return ZZMathBit.__base(left, right, ZZMathBit.__xorBit)  
end  
  
function ZZMathBit.orOp(left, right)  
    return ZZMathBit.__base(left, right, ZZMathBit.__orBit)  
end  
  
function ZZMathBit.notOp(left)  
    return left > 0 and -(left + 1) or -left - 1  
end  
  
function ZZMathBit.lShiftOp(left, num)  --left左移num位  
    return left * (2 ^ num)  
end  
  
function ZZMathBit.rShiftOp(left,num)  --right右移num位  
    return math.floor(left / (2 ^ num))  
end  
  
function ZZMathBit.test()  
    print( ZZMathBit.andOp(65,0x3f))  --65 1000001    63 111111  
    print(65 % 64)  
    print( ZZMathBit.orOp(5678,6789))  
    print( ZZMathBit.xorOp(13579,2468))  
    print( ZZMathBit.rShiftOp(16,3))  
    print( ZZMathBit.notOp(-4))  
  
    print(string.byte("abc",1))  
end 

return ZZMathBit
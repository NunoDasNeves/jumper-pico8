pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- whacker

#include util.lua

-- 
dbg = false

-- player
p = {}
p.x = 64
p.y = 64
p.faceright = true
p.vx = 0
p.vy = 0
p.air = true
p.frame = 0 -- displayed frame offset
p.fcount = 0 -- counter for advancing frame
p.s = 64 -- first sprite of current animation
-- constants
p.spr = 64 -- base of sprite row
-- animations - s = offset from spr, f = num frames
p.s_wlk = {['s']=0, ['f']=2}
p.s_jmp = {['s']=2, ['f']=5}
p.footwidth = 4
p.w = 8
p.h = 8
p.ax = 1
p.max_vx = 3
p.min_vx = 0.01
p.g = 0.5
p.max_vy = 5
p.j_vy = -6

-- disable btnp repeating
poke(0x5f5c, 255)

function collplat(x,y)
 local mx = x/8
 local my = y/8
 local val = mget(mx,my)

 if (fget(val,2)) then
  return true
 end
 	return false
end

function collwall(x,y)
 local mx = x/8
 local my = y/8
 local val = mget(mx,my)

 if (fget(val,1)) then
  return true
 end
 	return false
end

function p_update()
 -- change direction
 if (btnp(⬅️) or
     btn(⬅️) and not btn(➡️)) then
  p.faceright = false
 elseif (btnp(➡️) or
     btn(➡️) and not btn(⬅️)) then
  p.faceright = true
 end
 if (btn(⬅️) and not p.faceright) then
 	-- accel left
 	p.vx -= p.ax
 elseif (btn(➡️) and p.faceright) then
 	-- accel right
 	p.vx += p.ax
 end
 if (not btn(⬅️) and not btn(➡️)) then
  p.vx -= p.vx/3
 end
 p.vx = clamp(p.vx, -p.max_vx, p.max_vx)
 if (abs(p.vx) < p.min_vx) then
  p.vx = 0
 end

 local newx = p.x + p.vx
 if (collwall(newx,p.y)) then
  p.vx = -p.vx
  newx = p.x + p.vx
 end
 p.x = newx

 -- vy - jump and land
	if (btn(🅾️) and not p.air) then
		 p.vy += p.j_vy
		 p.air = true
		 -- start jump anim
		 p.s = p.spr + p.s_jmp.s
   p.frame = 0
   p.fcount = 0
	end
	p.vy += p.g
	p.vy = clamp(p.vy, -p.max_vy, p.max_vy)

 local newy = p.y + p.vy

 if (p.vy > 0) then
  if (collplat(p.x,newy) and
      -- need both checks!
      (not p.air or
      rounddown(p.y,8) < rounddown(newy,8))) then
			newy = rounddown(newy, 8)
	  p.vy = 0
	  p.air = false
	 else
	  -- fall off platform
	  if (not p.air) then
		  p.air = true
		  -- start fall anim
			 p.s = p.spr + p.s_jmp.s
	   p.frame = 3
	   p.fcount = 0
		 end
	 end
 end
 p.y = newy
 
 if (p.y > 128) then
  -- todo: dead
 end

 -- animate player
 if (not p.air) then
  -- walk anim
  if (btnp(➡️) or btnp(⬅️)) then
   p.s = p.spr + p.s_wlk.s
   p.frame = 0
  end
  if (btn(➡️) or btn(⬅️)) then
  	if (p.fcount > 2) then
	 		p.frame = (p.frame + 1) % p.s_wlk.f
	 		p.fcount = 0
	 	end
	 else
   p.s = p.spr + p.s_wlk.s
	  p.frame = 0
	 end
 else
  -- jump anim
  if (p.fcount > 2) then
			p.frame += 1
			-- loop last 2 frames
			if (p.frame >= p.s_jmp.f) then
			 p.frame -= 2
			end
			p.fcount = 0
 	end
 end
 p.fcount += 1
end

function _update()
	p_update()
end

function _draw()
	cls(0)
	map(0,0,0,0,128,64)
	spr(p.s + p.frame,
	    flr(p.x-p.w/2),
	    flr(p.y-p.h),
	    1, 1,
	    not p.faceright)
	if (dbg) then
		print(p.x..' '..p.y,8,0,7)
		print(mget(p.x/8,p.y/8),8,8,7)
		print(collplat(p.x,p.y),8,16,7)
	--print(collwall(p.x,p.y),10,30,7)
	end
end

__gfx__
0000000000000000dddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000dddddd00dddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000101101011111110111111110111111100000000000000000000000000000000111111111111111111111111000000000000000000000000
00000000000000000111111010101010000000000101010100000000000000000000000000000000111111111111111111111111000000000000000000000000
00000000000000000000000011101110011001100111011100000000000000000000000000000000101010100000000001010101000000000000000000000000
00000000000000000000000000000001111111111000000000000000000000000000000000000000111011100000000001110111000000000000000000000000
00000000000000000000000001010100000000000010101000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000010101011111111110101010000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000010101000100000000101010000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000010101000100000000101010000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000010101000000000000101010000000000000000000000000
dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000010101011111111110101010000000000000000000000000
dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000010101000000100000101010000000000000000000000000
11111111111111111111111100000000000000000000000000000000000000000000000000000000010101000000100000101010000000000000000000000000
11111111111111111111111100000000000000000000000000000000000000000000000000000000010101000000000000101010000000000000000000000000
1d1d1d1dd1ddddddd1d1d1d100000000000000000000000000000000000000000000000000000000010101000000000000101010000000000000000000000000
1d1d1d1dd1ddddddd1d1d1d100000000000000000000000000000000000000000000000000000000010101001111111100101010000000000000000000000000
1d1d1d1dd1ddddddd1d1d1d100000000000000000000000000000000000000000000000000000000111111101111111101111111000000000000000000000000
1d1d1d111111111111d1d1d100000000000000000000000000000000000000000000000000000000111111100000000001111111000000000000000000000000
1d1d1d1ddddd1dddd1d1d1d100000000000000000000000000000000000000000000000000000000100000100100100101000001000000000000000000000000
1d1d1d1ddddd1dddd1d1d1d100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d1d1ddddd1dddd1d1d1d100000000000000000000000000000000000000000000000000000000111111111111111111111111000000000000000000000000
1d1d1d111111111111d1d1d100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d1d1dddddddddd1d1d1d100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d11111dddddddddddd11111d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1dd111dd111dd111dd111dd100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022200000222000002220000d0d200000000000022220000222200000000000000000000000000000000000000000000000000000000000000000000000000
00221120002211200022222000222220000222000022112000221120000000000000000000000000000000000000000000000000000000000000000000000000
00211120002111200022211200222222022122200221112002211122000000000000000000000000000000000000000000000000000000000000000000000000
022111200221112002221122022222222111222d0221122202211222000000000000000000000000000000000000000000000000000000000000000000000000
02222220022222200222122002222222222222200222222202222220000000000000000000000000000000000000000000000000000000000000000000000000
0222222002222220022222d0022222222222222d0222222022222220000000000000000000000000000000000000000000000000000000000000000000000000
222222002222220000222d000022222002222222222220d0022220d0000000000000000000000000000000000000000000000000000000000000000000000000
00d00d000005d00000020d0000000000002220000220d0000020d000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000040404040000000000000000000000000000000000000000000000000000020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2200000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2200000000000000000000000304042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2200000000000000000000001a1b1b2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
220405000000000000000000021b1b2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
221b1c0000000000000000001a1b1b2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
221b1c0000000304040500001a1b1b2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
221b1c0000001a1b1b1c00002a2b2b2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
221b1c0000021a1b1b1c00030404042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
221b1c0000001a1b1b1c001a1b1b1b2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
221b1c0200001a1b1b1c001a1b1b1b2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222b2c0000001a1b1b1c021a021b1b2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2203040404051a1b1b1c001a1b1b1b2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
221a1b1b1b1c1a1b1b1c001a0304042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
221a1b1b03051a1b1b1c001a1a1b1b2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222a2b2b1a1c2a2b2b2c001a1a1b1b2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3204040404040404040404040404043000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

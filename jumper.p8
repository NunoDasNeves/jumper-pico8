pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- jumper

#include util.lua

-- 
dbg = true
dbgstr = ''

-- disable btnp repeating
poke(0x5f5c, 255)

room = {
 i = 0,
 x = 0,
 y = 0,
 sz = 16*8,
 old = {}, -- for restore
 fcnt = 0,
 max_i = 8*3 - 1
}

-- one lantern per room
-- for now
-- room index+1 -> lit
lantern = {}
curr_lantern = 4

function get_curr_lantern()
 return lantern[curr_lantern]
end

function init_lantern()
 -- todo this properly
 for i=0,room.max_i do
  local l = {}
  local r = get_room_xy(i)
  local rmapx = r.x \ 8
	 local rmapy = r.y \ 8
	 local rmapr=rmapx+15
	 local rmapb=rmapy+15
	 for y=rmapy,rmapb do
  	for x=rmapx,rmapr do
   	local val = mget(x,y)
   	if (val == 82) then
   	 l.x = x*8
   	 l.y = y*8
   	 l.lit = false
   	end
   end
  end
  add(lantern, l)
 end
 -- initial spawn
 lantern[curr_lantern].lit = true
end

function collmap(x,y,f)
 local val = mget(x\8,y\8)

 return (fget(val,f))
end

function restore_room()
 for t in all(room.old) do
  mset(t.x,t.y,t.val)
 end
end

function get_room_i(x,y)
 x \= room.sz
 y \= room.sz
 return x % 8 + y * 8
end

function get_room_xy(i)
 return {
  x = (i % 8) * room.sz,
  y = (i \ 8) * room.sz
 }
end

function in_room(x,y)
 if (x<room.x or x>room.x+room.sz) then
  return false
 end
 if (y<room.y or y>room.y+room.sz) then
  return false
 end
 dbgstr='true'
 return true
end

function move_room(x,y)
 room.i = get_room_i(x,y)
 local r = get_room_xy(room.i)
 room.x = r.x
 room.y = r.y
end

function update_room()
 local oldi = room.i
 local px = p.x + p.w/2
 local py = p.y + p.h/2
 move_room(px,py)
 if (oldi != room.i) then
  camera(room.x, room.y)
  fireball = {}
  restore_room()
  spawn_room()
 end
end

-- spawn thangs in current room
-- save room
function spawn_room()
 local rmapx = room.x \ 8
 local rmapy = room.y \ 8
 local rmapr=rmapx+15
 local rmapb=rmapy+15
 thang = {}
 max_z = 0
 room.old = {}
 for y=rmapy,rmapb do
  for x=rmapx,rmapr do
   local val = mget(x,y)
   if (fget(val,4)) then
    add(room.old, {x=x,y=y,val=val})
   	local t = spawn_thang(val,x*8,y*8)
    max_z = max(t.z, max_z)
    mset(x,y,t.replace)
   end
  end
 end
end

function _update()
 dbgstr = ''
 update_room()
	update_p()
	for t in all(thang) do
	 t:update()
	end
	for p in all(fireball) do
	 p:update()
	end
end

function _init()
	camera(0,0)
 init_thang_dat()
 init_lantern()
	spawn_room()
	local l = get_curr_lantern()
	spawn_p(l.x,l.y - p_dat.h)
end

-->8
-- draw

function draw_thang(t)
 local flp = false
 if (not (t.rght == nil)) then
  flp = not t.rght
 end
 spr(t.s+t.fr,t.x,t.y,1,1,flp)
end

function draw_smol_thang(f)
	local sp = f.s + f.fr
 local sx = (f.sfr % 2) * 4
 local sy = (f.sfr \ 2) * 4
 sspr((sp % 16) * 8 + sx,
				 	(sp \ 16) * 8 + sy,
					 4,4,
  	   f.x,
   	  f.y,
   	  4,4,
    	 f.xflip,
    	 f.yflip)
end

function _draw()
	cls(0)

	map(0,0,0,0,128,64)

 -- draw one layer at a time!
	for z=max_z,0,-1 do
		for t in all(thang) do
	  if (t.z == z) then
			 t:draw()
			end
		end
	end

	spr(p.s + p.fr,
	    p.x,
	    p.y,
	    1, 1,
	    not p.rght)

	for f in all(fireball) do
	 f:draw()
	end

	if (dbg) then
	 local txtx = room.x + 8
		print(dbgstr,txtx,room.y,7)
		print(p.x..' '..p.y,txtx,room.y+8,7)
		print(mget(p.x\8,p.y\8),txtx,room.y+16,7)
	end
end
-->8
--thang - entity/actor

thang = {}

-- number of layers to draw
max_z = 0

function init_thang_dat()
thang_dat = {
	[82] = { -- lantern
		lit = false,
		init = init_lantern_thang,
		update = update_lantern,
		burn = burn_lantern,
		replace = 82 + 3,
		z = 1
	},
	[96] = { -- bat
		update = update_bat,
		burn = burn_bat,
		w = 7,
		h = 6,
		range = 8*8,
		dircount = 0,
		xspeed = 0.5,
		yspeed = 0.4,
		randdir = {x=1,y=1},
		cx = 0,
		cy = 0,
		cw = 7,
		ch = 6,
	},
	[100] = { -- thrower
	 update = update_thrower,
	 burn = burn_thrower,
	 w = 8,
	 h = 8,
	 hp = 3,
	 goingrght = true, -- going to go after throwing
	 burning = false,
	 -- coll dimensions
	 -- todo same as player..
		ftw = 0.99,
		ftx = 3,
		ch = 6.99,
		cw = 5.99,
		cx = 1,
		cy = 1,
		shcount = 0, -- throw stuff at player
		range = 8*6, -- only throw at player in this range
	},
	[107] = { -- icepick
	 init = init_icepick,
	 update = update_icepick,
	 burn = kill_icepick,
	 draw = draw_smol_thang,
	 w = 4,
	 h = 4,
	 vx = 1.5,
	 vy = -4,
	 g = 0.3,
	 max_vy = 4,
	 sfr = 0,
	 xflip = false,
	 yflip = false,
	}
}
end

function init_lantern_thang(l)
 l.lit = lantern[room.i+1].lit
 if (l.lit) then
  l.s = l.i + 1
  curr_lantern = room.i+1
 end
end

function init_icepick(t)
	if (p.x < t.x) then
		t.rght = false
		t.vx = -t.vx
	else
		t.rght = true
	end
end

function kill_icepick(t)
	if (t.alive) then
	 t.vx = 0
 	t.vy = 0
	 t.alive = false
	 t.fr = 1
	 t.sfr = 0
	 t.fcnt = 0
	end
end

function update_icepick(t)
 if (not t.alive) then
	 t.y += 0.5
	 t.fcnt += 1
	 if (t.fcnt & 1 == 0) then
	 	t.sfr += 1
	 end
	 if (t.fcnt == 8) then
		 del(thang, t)
		end
  return
 end
 -- spin around 'ax'is
 if (t.fcnt > 0 and t.fcnt % 2 == 0) then
  if (t.fcnt == 2) then
   t.x += 2
   t.y += 1
  elseif (t.fcnt == 4) then
   t.x -= 1
  	t.y += 2
  elseif (t.fcnt == 6) then
  	t.x -= 2
  	t.y -= 1
  elseif (t.fcnt == 8) then
			t.x += 1
			t.y -= 2
			t.fcnt = 0
  end
 	if (t.sfr >= 3) then
 	 t.sfr = 0
 	else
	 	t.sfr += 1
	 end
 end
 t.fcnt += 1
 t.vy += t.g
 t.vy = clamp(t.vy,-t.max_vy,t.max_vy)
 t.x += t.vx
 t.y += t.vy

 if (--collmap(f.x,f.y,0) or
     collmap(t.x+2,t.y,1) or
     collmap(t.x+2,t.y,2)) then
 	kill_icepick(t)
 end

	if (p.alive and hit_p(t.x,t.y,t.w,t.h)) then
		kill_p()
		kill_icepick(t)
	end
end

function burn_thrower(t)
 if (not t.burning) then
  t.hp -= 1
  t.s = t.i + 3
  t.fr = 0
  t.fcnt = 0
  t.burning = true
  if (t.hp <= 0) then
	  t.alive = false
	 end
	end
end

function update_thrower(t)
 if (not t.alive) then
  if (loop_anim(t,2,4)) then
   del(thang, t)
  end
  return
 end

 if (t.burning) then
  t.throwing = false
  if (t.fcnt >= 4) then
   t.burning = false
   t.fcnt = 0
   t.fr = 0
   t.s = t.i
  else
	  t.fcnt += 1
	  return
	 end
 end

 if (t.throwing) then
  if (p.x < t.x) then
  	t.rght = false
  else
   t.rght = true
  end
  t.fr = 2
	 if (t.fcnt >= 20) then
	  t.throwing = false
	  spawn_thang(107,t.x+4,t.y+4)
	  t.fcnt = 0
	  t.fr = 0
	 else
	  t.fcnt += 1
	 end

 else
	 -- remember which way we were going
	 t.rght = t.goingrght
	 if (t.rght) then
	  t.vx = 0.75
	 else
	  t.vx = -0.75
	 end
	 local newx = t.x + t.vx
	 local pushx = coll_walls(t,newx)
	 if (pushx != newx) then
	  t.rght = not t.rght
	 end
	 newx = pushx
	 if (coll_edge(t,newx,t.y+t.h) or
	 	   coll_room_border(t)) then
	  t.rght = not t.rght
	 end

		t.goingrght = t.rght 
		t.x = newx
		loop_anim(t,3,2)

	 if (t.shcount <= 0) then
		 if (dist(p.x,p.y,t.x,t.y) <= t.range) then
	 	 t.throwing = true
	 	 t.fcnt = 0
	 	end
	 	t.shcount = 30
	 else
	  t.shcount -= 1
	 end
 end

	if (p.alive and hit_p(t.x,t.y,t.w,t.h)) then
		kill_p()
	end
end

function burn_bat(b)
 if (b.alive) then
	 b.alive = false
	 b.s += 2
	 b.vy = 0.6
	 b.deadf = 20
	end
end

function loop_anim(t,speed,frames)
 -- t = {
 --   s -- starting frame
 --   fr -- current frame
 --   fcnt -- frame counter
 -- }
 -- return true if looped
 local ret = false
 if (t.fcnt >= speed) then
  t.fcnt = 0
  t.fr += 1
  if (t.fr >= frames) then
   ret = true
   t.fr = 0
  end
 end
	t.fcnt += 1
	return ret
end

function update_bat(b)
 if (not b.alive) then
  b.deadf -= 1
  if (b.deadf == 0) then
   del(thang, b)
  end
  loop_anim(b,4,2)
  b.x += b.vx
	 b.y += b.vy
	 return
 end

	-- b.alive
 loop_anim(b,4,2)

	local v = {x=p.x-b.x,y=p.y-b.y}
	local l = vlen(v)
	local following = false
	if (l > b.range) then
	 if (b.dircount == 0) then
		 -- pick random direction		
		 v.x=rnd(2)-1
		 v.y=rnd(2)-1
		 b.randdir = {x=v.x,y=v.y}
	 	b.dircount = 60
	 else
	 	v.x = b.randdir.x
	 	v.y = b.randdir.y
	 	b.dircount -= 1
	 end
	 l = vlen(v)
	else
		following = true
	end

	v.x *= b.xspeed/l
	v.y *= b.yspeed/l
	b.vx = v.x
	b.vy = v.y
	if (b.vx > 0) then
  b.rght = true
 else
  b.rght = false
	end

	-- bounce
	-- todo un-jank
	if (b.fr == 0) then
	 b.vy += 0.5
	else
  b.vy -= 0.5
 end
 
 --local newpos = move_coll(b)
	
 --b.x = newpos.x
 --b.y = newpos.y
 if (coll_room_border(b)) then
 	b.dircount = 0
		b.vx = 0
		b.vy = 0
 end
 b.x += b.vx
 b.y += b.vy

	if (p.alive and
	    hit_p(b.x,b.y,b.w,b.h)) then
		kill_p()
	end
end

function burn_lantern(l)
 if (not l.lit) then
	 l.lit = true
	 l.s += 1
 	lantern[room.i+1].lit = true
 	curr_lantern = room.i+1
 end
end

function update_lantern(l)
 if (l.lit) then
  loop_anim(l,5,2)
 end
end

function spawn_thang(i,x,y)
 local t = {}
	t.i = i
	t.x = x
	t.y = y
	t.vx = 0
	t.vy = 0
	t.s = i
	t.fr = 0
 t.fcnt = 0
 t.draw = draw_thang
 t.replace = 0
 t.w = 8
 t.h = 8
 t.z = 0
 t.rght = true
 t.alive = true
 for k,v in pairs(thang_dat[i]) do
 	t[k] = v
 end
	if (t.init != nil) then
	 t:init()
	end
 add(thang,t)
	return t
end

-->8
-- player

p_dat = {
	i = 64, -- base of sprite row
	--  animations - s = offset from spr, f = num frames
	s_wlk =  {s=0, f=2},
	s_jmp =  {s=2, f=5},
	s_die =  {s=7, f=5},
	s_spwn = {s=12, f=4},
	w = 8,
	h = 8,
	
	--  physics
	--  coll dimensions
	ftw = 0.99, -- < min platform width
	ftx = 3,
	ch = 6.99, -- < min wall height
	cw = 5.99,
	cx = 1,
	cy = 1,
	-- hurtbox dimensions
	hx = 2,
	hy = 2,
	hw = 3.99,
	hh = 3.99,
	-- physics
	ax = 1, -- accel
	max_vx = 2,
	min_vx = 0.01, -- stop threshold
	g = 0.5, -- gravity
	max_vy = 5,
	j_vy = -6, -- jump accel
}

function spawn_p(x,y)

 p = {}
	p.x = x
	p.y = y
	p.rght = true -- facing
	p.vx = 0
	p.vy = 0
	p.air = false
	p.fr = 0 -- displayed frame offset
	p.fcnt = 0 -- counter for advancing frame
	p.shcount = 0 -- shoot counter
	p.teeter = false
	p.alive = true
	p.spawn = true
	for k,v in pairs(p_dat) do
		p[k] = v
	end
	p.s = p.i + p.s_spwn.s

end

function kill_p()
 p.alive = false
 p.s = p.i + p.s_die.s 
 p.fr = 0
 p.fcnt = 0
end

function hit_p(x,y,w,h)
	return aabb(
 									 x,y,w,h,
 									 p.x+p.hx,p.y+p.hy,
 									 p.hw,p.hh)
end

function update_p()
 if (p.spawn or not p.alive) then
  respawn_update_p()
  return
 end

 -- change direction
 if (btnp(⬅️) or
     btn(⬅️) and not btn(➡️)) then
  p.rght = false
 elseif (btnp(➡️) or
     btn(➡️) and not btn(⬅️)) then
  p.rght = true
 end
 if (btn(⬅️) and not p.rght) then
 	-- accel left
 	p.vx -= p.ax
 elseif (btn(➡️) and p.rght) then
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

 local pushedx = coll_walls(p, newx)
 if (pushedx != newx) then
  p.vx = 0
 end
 newx = pushedx

 -- vy - jump and land
 local oldair = p.air
	if (btnp(🅾️) and not p.air) then
		 p.vy += p.j_vy
		 p.air = true
	end
	p.vy += p.g
	p.vy = clamp(p.vy, -p.max_vy, p.max_vy)

 local newy = p.y + p.vy
 local fty = newy + p.h
 local ftxl = newx + p.ftx
 local ftxr = ftxl + p.ftw

 if (p.vy > 0) then
  if ((collmap(ftxl,fty,0) or
			   collmap(ftxr,fty,0))
      and
      -- need both checks!
      (not p.air or
      rounddown(p.y,8) < rounddown(newy,8))) then
			newy = rounddown(newy, 8)
	  p.vy = 0
	  p.air = false
	 else
	  -- fall off platform
	  if (not p.air) then
	   -- only fall if holding dir
	   if ((btn(⬅️) and p.vx < 0) or
	       (btn(➡️) and p.vx > 0)) then
	   	p.air = true
	   else
	    p.vx = 0
	    newx = p.x
	   end
		 end
	 end

	 p.teeter = coll_edge(p,newx,fty)
	            and not p.air
	-- p.vy < 0
 else
  -- ceiling
 	if (p.air and (collmap(ftxl,newy,2) or
 	    collmap(ftxr,newy,2))) then
 	 p.vy = -p.vy/3
 	end
 end

 p.x = newx
 p.y = newy
 
 -- hit spikes
 local hl = p.x + p.hx
 local hr = hl + p.hw
 local ht = p.y + p.hy
 local hb = ht + p.hh
 if (collmap(hl,ht,3) or
     collmap(hr,ht,3) or
     collmap(hl,hb,3) or
     collmap(hr,hb,3)) then
 	kill_p()
 	respawn_update_p()
 	return
 end
 
 if (p.shcount == 0) then
  if (btnp(❎)) then
   p.shcount = 10
   make_fireball()
  end
 else
 	p.shcount -= 1
 end
 
 -- animate
 if (not p.air) then
  -- walk anim
  p.s = p.i + p.s_wlk.s
  if (btnp(➡️) or btnp(⬅️)) then
   p.fr = 0
   p.fcnt = 0
  end
  if (btn(➡️) or btn(⬅️)) then
   loop_anim(p,3,p.s_wlk.f)
	 elseif (p.teeter) then
	  p.fr = 1
	 else
	  p.fr = 0
	 end
 else
	 p.s = p.i + p.s_jmp.s
  if (not oldair) then	 
   p.fr = 0
   p.fcnt = 0
   -- fell, not jumped
   if (not btn(🅾️)) then
   	p.fr = 5
   end
  end
  -- jump anim
  if (p.fcnt > 2) then
			p.fr += 1
			-- loop last 2 frames
			if (p.fr >= p.s_jmp.f) then
			 p.fr -= 2
			end
			p.fcnt = 0
 	end
 	p.fcnt += 1
 end
end

function respawn_update_p()
	if (not p.alive) then
  if (loop_anim(p,2,p.s_die.f)) then
	  local l = get_curr_lantern()
   spawn_p(l.x,l.y - p.h)
   -- todo reset room!
  end

 elseif (p.spawn) then
  if (loop_anim(p,2,p.s_spwn.f)) then
   p.fr = 0
   p.fcnt = 0
   p.s = p.i + p.s_wlk.s
   p.spawn = false
  end
	end
end
-->8
-- fireball
fireball = {}

function make_fireball()
 local f = {}
 f.w = 4
 f.h = 4
 f.x = p.x + (p.w - f.w)/2
 f.y = p.y + (p.h - f.h)/2
 f.s = 80
 f.alive = true
 f.fcnt = 0
 f.speed = 3
 f.fr = 0
 f.draw = draw_smol_thang
 f.update = update_fireball
 local ydir = 0
 local xdir = 0
 if (btn(⬆️)) then
  ydir = -1
 elseif (btn(⬇️)) then
  ydir = 1
 end
 if (p.rght) then
  xdir = 1
 else
  xdir = -1
 end
 -- straight up or down
 if (not btn(⬅️) and
     not btn(➡️) and
     ydir != 0) then
   xdir = 0
 end
 if (xdir == 0 or ydir == 0) then
  f.vx = xdir * f.speed
  f.vy = ydir * f.speed
 else
  f.vx = xdir * 0.7071 * f.speed
  f.vy = ydir * 0.7071 * f.speed
 end

 f.sfr = 0 -- sub-frame
	if (ydir == 0) then
  f.sfr = 1
 elseif (xdir == 0) then
  f.sfr = 2
 else
  f.sfr = 3
 end
 f.xflip = false
 f.yflip = false
 if (f.vy < 0) then
  f.yflip = true
 end
 if (f.vx < 0) then
  f.xflip = true
 end
 add(fireball, f)
end

function kill_fireball(f)
	f.alive = false
	f.yflip = false
	f.sfr = 0
	f.fr = 1
	f.fcnt = 0
end

function update_fireball(f)
 if (not f.alive) then
  f.y -= 0.5
	 f.fcnt += 1
	 if (f.fcnt & 1 == 0) then
	 	f.sfr += 1
	 end
	 if (f.fcnt == 8) then
		 del(fireball, f)
		end
  return
 end
 f.x += f.vx
 f.y += f.vy
 -- hit stuff
 for t in all(thang) do
 	if (aabb(
 									 t.x,t.y,t.w,t.h,
 									 f.x,f.y,4,4)) then
 	 t:burn()
 	 -- don't stop on lanterns
 	 if (t.i != 82) then
	 	 kill_fireball(f)
	 	 return
 		end
 	end
 end
 if (--collmap(f.x,f.y,0) or
     collmap(f.x+2,f.y+2,1) or
     collmap(f.x+2,f.y+2,2)) then
 	f.vx = 0
 	f.vy = 0
 	kill_fireball(f)
 end
end

-->8
-- collision

function coll_edge(t,newx,fty)
 -- t = {
 --   ftx -- foot x offset
 --   ftw -- foot width
 -- }
 -- fty = foot y
 -- return true if 1 px from edge
 local tftxl = newx + t.ftx
 local tftxr = tftxl + t.ftw
 if (not (collmap(tftxl-1,fty,0) and
		   collmap(tftxr+1,fty,0))) then
	 return true
	end
 return false
end

function coll_walls(t,newx)
 -- t = {
 --   y  -- coord
 --   cx -- coll x offset
 --   cw -- coll width
 --   cy -- coll y offset
 --   ch -- coll height
 --   vx -- x vel
 -- return newx pushed out of wall
 local cl = newx + t.cx
 local cr = cl + t.cw
 local ct = t.y + t.cy
 local cb = ct + t.ch
 -- only check left or right
 local cx = cr
 if (t.vx < 0) then
  cx = cl
 end
 if ((t.vx != 0)
     and
     (collmap(cx,ct,1) or
 	    collmap(cx,cb,1))
 	  ) then
   -- push out of wall
   if (cx == cl) then
   	newx = roundup(cx, 8) - t.cx-- - 1
   else
   	newx = rounddown(cx, 8) - t.cw - t.cx + 1
   end
 end
 return newx
end

function move_coll(t)
	-- t = {
	--	  x  -- coord
 --   y  -- coord
 --   cx -- coll x offset
 --   cw -- coll width
 --   cy -- coll y offset
 --   ch -- coll height
 --   vx -- x vel
 --	  vy -- y vel
 -- }
 -- return {x, y} pushed out of wall
	
	local newx = t.x + t.vx
	local newy = t.y + t.vy
 local cl = newx + t.cx
 local cr = cl + t.cw
 local ct = newy + t.cy
 local cb = ct + t.ch

 -- only check corner in direction of vx,vy
 local cx = cl
 if (t.vx > 0) then
  cx = cr
 end

 local cy = ct
 if (vy > 0) then
  cy = cb
  -- platform
  if (collmap(cx,cy,0)) then
  	newy = rounddown(cy,8) - t.ch - t.cy - 1
  end
 elseif (vy < 0) then
		-- ceiling
		if (collmap(cx,cy,2)) then
			newy = roundup(cy,8) - t.cy
		end
 end

	-- todo cx

	return {x=newx,y=newy}
end

function coll_room_border(t)
 -- t = {
 --	  x  -- coord
 --   y  -- coord
 --   cx -- coll x offset
 --   cw -- coll width
 --   cy -- coll y offset
 --   ch -- coll height
 --   vx -- x vel
 --	  vy -- y vel
 -- }
 -- apply vx, vy, and
 -- return true if moving into edge of room
 local newx = t.x + t.vx
 local newy = t.y + t.vy
 local cl = newx + t.cx
 local cr = cl + t.cw
 local ct = newy + t.cy
 local cb = ct + t.ch
 -- only check left or right
 local cx = cr
 if (t.vx < 0) then
  cx = cl
 end
 if ((t.vx != 0)
     and
     (not in_room(cx,ct) or
 	    not in_room(cx,cb))
 	  ) then
   return true
 end

 local cy = cb
 if (t.vy < 0) then
  cy = ct
 end
 if ((t.vy != 0)
     and
     (not in_room(cl,cy) or
 	    not in_room(cr,cy))
 	  ) then
   return true
 end

 return false
end

__gfx__
00000000dddddddddddddddddddddddddddddddd0000000000000000000000000000000000000000310100130101011000000000000000000000000000000000
000000000dddddd00dddddddddddddddddddddd00000000000000000000000000000000000000000310111101001103300000000000000000000000000000000
00000000011111100111111000000000011111100011110000000000001111000000000000000000010110101001133300000000000000000000000000000000
00000000011001100110011111111111111001100110011011111111011001100000000000000000010110131011131000000000000000000000000000000000
00000000010000100100001000000000010000100100001000000000010000100000000000000000010111131111001300000000000000000000000000000000
00000000001111000111111001100110011111100111111001100110011111100000000000000000010101100101001300000000000000000000000000000000
00000000000000000100001111111111110000100100001011111111010000100000000000000000010111103301011000000000000000000000000000000000
00000000000000000100001000000000010000100100001000000000010000100000000000000000110110100301011300000000000000000000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddd11111111dddddddd0000000000000000010100100101011000000000000000000000000000000000
0dddddddddddddddddddddddddddddd00dddddd00dddddd0001000000dddddd00000000000000000330100103101011000000000000000000000000000000000
01111111111111111111111111111110011111100111111000100000011111100000000000000000333100133301011300000000000000000000000000000000
011ddd11111111111111111111ddd110011dd1100110011000000000011dd1100000000000000000013100010101011000000000000000000000000000000000
01ddddd1ddddd1dddd1dd1dd1ddddd1001dddd10010000101111111101dddd100000000000000000010110010101011000000000000000000000000000000000
01111111ddddd1ddddd1d1dd11111110011111100111111000000100011111100000000000000000310110100101011000000000000000000000000000000000
01d1d1d1ddddd1dddddd11dd1d1d1d1001dddd10010000100000010001dddd100000000000000000010111100101011000000000000000000000000000000000
01d1d1d111111111111111111d1d1d1001dddd100100001000000000011111100000000000000000010111100101011000000000000000000000000000000000
01d1d1d1dd1ddddddd1ddddd1d1d1d1001dddd100100001000000000dddddddddddddddd00000000010101100101011001010110dddddddd0000000000000000
01d1d1d1dd1ddddddd1ddddd1d1d1d1001dddd1001000010111111110dddddddddddddd0000000003101011031010110310101100dddddd00000000000000000
01d1d1d1dd1ddddddd1ddddd1d1d1d1001dddd100100001011111111011111111111111000000000310101133101011331010113011111100000000000000000
01d1d1d111111111111111111d1d1d1001dddd100100001000000000011ddd1111ddd11000000000010101100111011101010111011dd1100000000000000000
01d1d1d1ddddd1ddddddd1dd1d1d1d1001dddd10010000100110011001ddddd11ddddd100000000001010110011101110101011101dddd100000000000000000
01d1d1d1ddddd1ddddddd1dd1d1d1d1001dddd100100001000000000011111111111111000000000013131303101011031013113011111100303003003030030
01d1d1d1ddddd1ddddddd11d1d1d1d1001dddd10010000101111111101d1d1d11d1d1d100030300303310110013131300131331331dd3d133003303330033033
01d1d1d111111111111111111d1d1d1001dddd100100001000000000011111111111111030330033333313133331331333333333331333333033330333333333
01d1d1d1dd1d1ddddd1ddddd1d1d1d1001dddd10010000100000000001d1ddddd1dddd10155555555555555555555555555555555555555555555551dd1d1ddd
01d1d1d1dd1dd11ddd1ddddd1d1d1d1001dddd10010000101101111101d1ddddd1dddd10d1555551111111111555555111111111155555511555551ddd1dd11d
01d1d1d1dd1dddd1dd1ddddd1d1d1d10011dd110011001101101111101d1ddddd1dddd10d1111515551115555511151555111555551115155511151ddd1dddd1
01d1d1d111111111111111111d1d1d1001d11d100101101011111111011111111111111015551111555111555555111155511155555511115555111111111111
011ddd11ddddd1ddddddd1dd11ddd11001dddd1001000010000000001ddddd1ddddd1dd1d15555515555111155555551555511115555555155555551ddddd1dd
dd11111dddddd1dddddd11ddd11111dd1d1111d110111101111110111ddddd1ddddd1dd1d1111155111115111111115511111511111111551111111dddddd1dd
1dddddddddddd1ddddd1d1dddddddddd1dddddd110000001111110111ddddd1ddddd1dd111111555551115151111155555111515111115551111151dddddd1dd
11111111111111111111111111111111111111111111111111111111111111111111111111111111555555551111111155555555111111111111111111111111
00022200000222000000000000505200000000000022220000222200002220000002000000200020000000000000000000000000000000000000000000000000
00221120002211200222222000222220000222000022112000221120022120000022200000220200002000000002000000000000000007000000700000002200
0021112000211120222222220022222202212220022111200221112222111200022120002022222000220200002200000000000000072000009aa70000021120
022111200221112022222222022222222111222502211222022112222211122022112020022122200222200000122000000000000a02a2a0021999a007217170
02222220022222205222111202222222222222200222222202222220222222202221122002111220002120000001100000a007000a7a7a0009a2a8000a72aa20
02222220022222200222212002222222222222250222222022222220022222220222222000211200000110000000100000070a00009a9800029a9290029a2990
22222200222222005222220000222220022222222222250002222500022220500222225000021000000000000000000000a99000008988000089892000a99800
00500500000550000000000000000000002220000220500000205000002050000022500000000000000000000000000000088000000890000008890000988500
bbbb0980070a7070dddddddddddddddddddddddddddddddd0000000000000000000000000000000000000000c000000000000000000000000000000000000000
bbbba7987a99a7a7002222000022220000222200000000000000000000000000000000000000000000000000c00c000000000000000000000000000000000000
bbbba798099a0890021001200210012002100120000000000000000000000000000000000000000000000000ccc0000000000000000000000000000000000000
bbbb0980008000000210712002a0712002170120000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000
0aa007a0070770a0201001022017a102207aa1020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
97797a98099a09902010010220189102201891020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8998a998008000000211112002111120021111200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08800880000000002222222222222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5500050000000000007000700700070000066600000666000006660000ee0000000700000000000000000000cccc000cc7c70c0000000000000060000ffff000
055055000000000008a707a009a707a0000611600006116000c611600ee7e0000000a70000000700000070000c000ccc0c70c7c7000000000696c666ffff0000
0055500000055000009a0a80008a0a9000661160006611600c6611600ee77e00707aaaa000707a00000a70000c00c00c777c077c00000000666cc55600fff00f
00050000055555000008a9000009a80006c66160066c6160cc6661600eee7e500aa999a0000aa9700009000000c0000cc0c70c00000000000ccccc560fffff0f
0000000055000550000098000000890006cc6660066cc660056666650cceee0000a9a90000a99000000000000c00c000c00c000c0000000065cccc55f0ffffff
000000005000005000000000000000000566c66506566c6000c66660c0eeeee008998900000800000000000000c0c00cc70707000000000055cccc05f0f0fff0
00000000000000000000000000000000c06666000c66660000666600050eeee000088000000000000000000000c0ccc00000700700000000505c55000000f0f0
0000000000000000000000000000000000500500000550000050050000c50050000000000000000000000000ccccc0000c70000000000000000505000000f0f0
06006000d006000000670001dddddddd00000600dddddddd000000000000000000000000000000000000000000000000000000000000000000666000dddddddd
06007000d1600000000066d101d11d100060070001d111d0000000000000000000000000000000000000000000000000000000000000000006c6e6600dddddd0
00706006dd16676000000dd106111160007006000611160000000000000000000000000000000000000000000000000000000000000000000666e56600222200
60606007d110000067666d11600606060060600706060070000000000000000000000000000000000000000000000000000000000000000000eece5602444420
07006060d116600000000dd1700606006060600670060606000000000000000000000000000000000000000000000000000000000000000006eecc5624444442
006ddd60dd100676007606d10060070006dddd6060060700000000000000000000000000000000000000000000000000000000000000000005eece6c02222f2f
0ddd1dd0d1600000660070d1007006000dd11dd0000700600000000000000000000000000000000000000000000000000000000000000000000e5c0000555550
11111111d00670000006000100600000111111110006006000000000000000000000000000000000000000000000000000000000000000000005050005050505
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111121112111111111111111112111211111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000131000000000000000000000000000001
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000121212120000000232000000000000000000000000000002
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003100000000000000120000000000000232000000000000000000000000000002
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003200000000000000120000000000000232000000000000000000000000000002
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003200000000000000120000002222120232000000000000000000000000000002
00000000000000000000000000000000000000000000000000000000000000424200000000000000000000000000004242000000000000000000000000000000
42000000000000000000000000000000000000000000000000000000000000003200000000000000220000000000000232000000000000000000000000000002
42000000000000000000000000000042420000000000000000000000000000424200000000000000000000000000004242000000000000000000000000000042
42000000000000000000000000000042000000000000000000000000000000423200000000000000220000000000000232000000000000000000000000000002
42000000000000000000000000000042420000000000000000000000000000424200000000000000000000000000004242000000000000000000000000000042
42000000000000000000000000000042000000000000000000000000000000423200000000000022222222220000000232000000000000000000000000000002
42000000000000000000000000000042420000000000000000000000000000424200000000000000000000000000004242000000000000000000000000000042
42000000000000000000000000000042330000000000000000000000000000423200000000000000122222220000000232000000000000000000000000000002
42000000000000000000000000000042420000000000000000000000000000424200000000000000000000000000004242000000000000000000000000000042
42000000000000000000000000000042330000000000001000001000000000003222222222222212120000000000000232000000000000000000000000250002
00000000000000000000000000000042420000000000000000000000000000000000000000000000000000000000000042000000000000000000000000000000
00000000000000000000000000000042000000000000005700005700100000003200000000000012120000002222220232000000000000000000000072218202
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000570020303200000000000012220000000000000232000000000000000000007173138302
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000720000000057000052003200000000000000220000000000000333000000000000000000717323228302
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000720000720000000052003300000000000000222121212500000000000000460000000071731322128303
12121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212
12121212121212121212121212121212121212121212121212121212121212121111111111211111111111112111111111112111211111211111111111211111
__gff__
0001010101010001010100000000000007070707070100070000000000000000070707070700000707000000000700000707070707000007070707070707070700000000000000000000000000000000000011010101000000000000000000001000000010000000101010000000000008080808080800000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
31212121212121212121212121212121212121212121212121312121212121211a1b1b0b000b001b1a1b001a0b0021212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121000000000000
13000000600000000000600000000010130000000000000000000000000000001b1a1a1b001b001b1a1a001a1b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23000000000000000000000000000020230000000000000000000000000000001a0a0a1b001b001a1b0b000b0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23030400600000000000000015060620230000000000000000000000000000000b1a0b1b000b001a1b1b000a1b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23162500000000000000600025161620230000000000000000000000000000001a0b1a1a000a001b1b0a001a1b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23162500000002030304000025161620230000006000000000000000000000001b0a0b1a001b000a1b0a000b1b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23162560000025161625005235262620230000000000000000000060000072271b1a1b1a001b000a1b1b001a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23162500000125161625000203030320237100000000000000000000000072201a1b0b0a000a000a0a1b001a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23162500000025161625002516161620230606060606060606062712280000301b1a1a1b001b001b1b1b001b1a0000202200000000000000000000000000002022000000000000000000000000000020220000000000000000000000000000202200000000000000000000000000002022000000000000000000000000000020
23162501000025161625002516161630331616161616161616163722380203040a1b0a0b001b000a1b1b000a1a0000203200000000000000000000000000002032000000000000000000000000000020320000000000000000000000000000203200000000000000000000000000002032000000000000000000000000000020
23263500000025161625002501161616161616161652161616167573252525001a0a1a1b000b000b1b0a000a1b0000300000000000000000006400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23020303030425161625002516161616161616161615161616162525353535001b1b1b0a001b001b1b1b001a0b0000000000000000000027111111280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2325161616252516162501251012121313161616162516161616253527122810280b0a0a001a001b1a1a000a1b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232516160204251616250025202121232316161616351616161425272121382012281b0b000a520a1a1b001a0b0000000000000000000000640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333526263535352670350035302121333374707414271228163435372121383022382b2a642b2d2b2b2a2e2a2b0000000000520017006400170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21212121212121212121212121212121212121212121212121212121212121212131393c3d3c3d3d3c3c3d3d3e1111111212121212111212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121

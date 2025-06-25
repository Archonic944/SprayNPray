pico-8 cartridge // http://www.pico-8.com
version 42
__lua__


	-- objs is all objects
	-- bodies are objs w/ collision
local objs,ents,bodies,

	-- funcs that run every frame
	-- timers with new_timer are loops
loops,

	-- logs for debug
logs,
	-- queue for obj deletion
del_que,
	-- id counter for giving each obj a unique id
id_cnt
=
{},{},{},

{},
{},
{},
0

	-- make layers
for i=1,8 do
	add(objs,{})
end


	-- utilities by ms. mouse
local function compose(a, b)
	return function(...)return a(b(...))end
end

local function bind_front(f,v)
	return function(...)
		return f(v, ...)
	end
end


local function with_arrspl(fn, str)
	local res={}
	foreach(split(str, '|'),
		compose(bind_front(fn, res), split))
	return res
end

local deep_split,split_arr=
bind_front(with_arrspl,add),
bind_front(with_arrspl,function(res,sarr)
	res[sarr[1]]=sarr
end)


	-- add log
local function log(l,i)
	logs[i or 1]=l or "false"
end


	-- create loop that runs every frame
local function new_loop(func)
	return add(loops,func)
end
	-- new layer loop, useful for drawing, just a token optimization
function new_l_loop(func,l,x,y)
	return new_obj({
		_,
		func,
	},l,x,y)
end

	-- delete obj
local function del_obj(o)
	add(del_que,o).del=true
	return o
end



	-- delete loop
local del_loop
=
bind_front(del,loops)



	-- new timer, if loop is true it will repeat
local function new_timer(am,func,loop)
	am=am&-1
	local org_am,timer=am
	
	timer=function()
		if am==0do
			am=org_am
			func()
			if(not loop)del_loop(timer)
		else
			am-=1
		end
	end
	
	return new_loop(timer)
end


	-- token optimization
function set_meta(o)
	return setmetatable(o,{__index=_ENV})
end
	-- create new object
function new_obj(no,l,x,y)
	local o=set_meta{
		loops={},objs={},
		init=no[1],upd=no[2],
		l=l,id=id_cnt
	}
	
	
	id_cnt+=.001
	
	
	o.new_loop,o.del_loop,o.new_timer,
	o.new_l_loop,o.del_obj
	
	=
	function(func)
		return add(o.loops,new_loop(function()func(o)end))
	end,
	
 compose(bind_front(del,o.loops),del_loop),
 compose(bind_front(add,o.loops),new_timer),
 compose(bind_front(add,o.objs),new_l_loop),
 compose(bind_front(del,o.objs),del_obj)
	

	if(x)o.x,o.y=x,y
	if(o.init)o:init()
	
	return add(objs[o.l],o)
end
-->8
-- buildings

next_building = 0 --x-coordinate
buildings = {}
--list of map segments that are copy-pasted to make buildings
building_templates = { --{inclusive map boundaries: {mapx1, mapy1, mapx2, mapy2}, {...template indices feasibly generated after this one (self-referential indexes)}}
	{{4,4,6,7}, {3,5,6,7,9,11,12,13,14,15}}, --mid wide (1)
	{{8,2,9,7}, {1,3,4,5,6,7,8,9,10,11,12,13,14,15,16}}, --tall skinny (2)
	{{11,5,18,7}, {1,6,7,9,11,14}}, -- low wide (market) (3)
	{{21,1,27,7}, {1,3,5,6,7,9,10,11,12,13,14}}, -- tall wide (aaa!) (4)
	{{28,2,29,7}, {1,2,3,6,7,8,9,10,11,12,13,14,15,16}}, --mid skinny (5)
	{{31,5,32,7}, {1,3,7,11,12,14}}, --low skinny (6)
	{{34,4,35,7}, {1,3,5,6,9,11,12,13,14}}, --a-little-taller-than-low skinny (7)
	{{37,1,45,7}, {1,3,6,7,9,11,12,14}}, --tall then low (factory) (8)
	{{48,2,53,7}, {1,3,4,5,6,7,8,10,11,12,13,14,15,16}}, --idk at this point (9)
	{{55,1,58,7}, {1,2,3,5,6,7,9,10,11,12,13,14,15,16}}, --mid-height mid-wide (10)
	{{60,5,63,7}, {1,3,6,7,9,11,14}}, --low wide horizontal girder (11)
	{{65,4,69,7}, {1,3,5,6,7,9,10,11,12,13,14}}, --mid wide horizontal girder (12)
	{{71,3,73,7}, {1,2,3,5,6,7,9,10,11,12,13,14,15,16}}, --mid skinny horizontal girder (13)
	{{75,6,76,7}, {3,6,11}}, --low skinny hori girder (14)
	{{78,0,82,7}, {1,3,6,7,9,11,14}}, --double girder mid (15)
	{{84,1,88,7}, {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}} --the T (16)
}
--make inclusive
for t in all(building_templates) do
	t[1][4] += 1
	t[1][3] += 1
end

function add_random_building()
	local possibilities = buildings[#buildings].template[2]
	new_building(rnd(possibilities))
end

function new_building(template_index) --tacks a new building on to the list of buildings
	next_building += 8 --margin
	local temp = building_templates[template_index]
	add(buildings, new_obj({
		function(_ENV)
			template_id = template_index --todo potential issue with env
			template = building_templates[template_index]
		end,
		function(_ENV)
			map(template[1][1], template[1][2], x, template[1][2]*8, template[1][3]-template[1][1], template[1][4]-template[1][2])
		end
	}, 2, next_building, 0))
	next_building += ((temp[1][3] - temp[1][1]) * 8)
end

function delete_building() --deletes the building at index 1
	buildings[1]:del_obj()
	deli(buildings, 1)
end

-- gets a sprite at a world location, for collision. assumes buildings is sorted by x
function get_sprite(x,y)
    
    -- safety check
    if #buildings == 0 then return nil end
    
    -- find the building at this x position
    local b_inside = nil
    for b in all(buildings) do
        if x >= b.x then 
            b_inside = b 
        else 
            break 
        end
    end
    
    -- if we found no building (shouldn't happen) or we're before first building
    if b_inside == nil then return nil end
    
    -- get width of this building (calculate from template)
    local template = b_inside.template[1]
    local width = (template[3] - template[1]) * 8
    
    -- check if we're past the end of the building
    if x >= (b_inside.x + width) then return nil end
    
    -- local coords within building
    local lx = x - b_inside.x
    local ly = 64-y --dont ask
    
    -- early out if outside bounds
    if lx < 0 or ly < 0 then return nil end
    
    -- map tile coords
    local tx1 = template[1]
    local ty1 = template[2]
    local tx2 = template[3]
    local ty2 = template[4]
    
    local map_x = tx1 + flr(lx/8)
    local map_y = ty1 + flr(ly/8)
    
    -- bounds check
    if map_x < tx1 or map_x >= tx2 or map_y < ty1 or map_y >= ty2 then
        return nil
    end
    
    return mget(map_x, map_y)
end

--adds to account for isometric view
function is_colliding(x,y)
    local spr = get_sprite(x,y+2)
    return spr and fget(spr,0) or false
end

new_obj({ --builder (invisible)
		function(_ENV)
			--populate buildings initially
			new_building(1)
			for i=1,6 do
				add_random_building()
			end
		end,
		
		
		function(_ENV)
			if next_building - player.x < 128 then
				delete_building()
				add_random_building()
			end
		end
	},
		-- layer
	4
)
-->8
-- player and enemies

local function anim(o,i,str)
	o.del_loop(o.anim)
	
	o.anim_i=_
	if i do
		local a,t=o.anims[i],str or 2
		local al=#a
		o.spri,o.anim_i=a[1],i
		
		o.anim=o.new_timer(a[al-1],function()
			if(t~=al-1)o.spri=a[t]
			t+=1
			
			if	a[al]==0 do
				if(t~=al)return
				t=1
				
				if(o.nex_st)state(o,o.nex_st)o.nex_st=_
				o.del_loop(o.anim)
				check_nex_anim(o)
			elseif t==al-1do
				t=1
				check_nex_anim(o)
			end
		end,true)
	end
end

function check_nex_anim(_ENV)
	if(nex_anim)anim(_ENV,nex_anim) nex_anim=_
end


local function anim_init(_ENV,str,f)
	anims=deep_split(str)
	if(f)anim(_ENV,f)
end

grav = 0.4
player = new_obj({
	function(_ENV)
		anim_init(_ENV,[[
			48,49,50,51,4,1|
			52,53,54,55,56,57,1,1|
		]],2)
		
		dx,dy,airframes=0,0,0
	end,
	
	function(_ENV)
		spr(spri,x,y,1,1,flipx)
		--update air time
		--update velocities
		if ➡️ do
			dx+=.4
			flipx=_
		end
		if ⬅️ do
			dx-=.4
			flipx=true
		end
		-- a basic jump for testing
		local hxx,hxy,hyx,hyy = x + (4*sgn(dx)) + dx + 4, y+7, x+4, y + (4*sgn(dy)) + dy + 4
		if (🅾️ and airframes < 10) dy -= 3
		if is_colliding(hxx, hxy) then pset(hxx, hxy, 8)
		else pset(hxx, hxy, 11) end
		if is_colliding(hyx, hyy) then pset(hyx, hyy, 8)
		else pset(hyx, hyy, 11) end
		if(not is_colliding(hxx, hxy)) x+=dx
		if (not is_colliding(hyx, hyy)) y += dy
		if is_colliding(hyx,hyy) then airframes=0 else airframes+=1 end --update airframes
		dx*=.8
		dy += grav
		dy*=.8
		if(dy < 0.1) dy=0
	end
}, 5, 8, 0)

-- debug object draws circle of collision points
collision_debug = new_obj({
	function(_ENV) end,
	function(_ENV)
		x = player.x
		y = player.y
		
		-- draw debug info
		print("x:"..x.." y:"..y, x-24, y-32, 7)
		
		-- draw collision circle 
		local r = 24
		for a=0,1,0.05 do
			local px = x + cos(a) * r
			local py = y + sin(a) * r
			local col = is_colliding(px, py) and 8 or 11
			pset(px, py, col) -- screen coords
		end
	end
}, 7, player.x, player.y)

-->8
	-- game loop, faster than _update()
--palt(0, false)
--palt(1, true)
poke(0x5f2c, 3) --low rez mode
camx,camy = 0,0

-- debug function to visualize building bounds
function debug_draw_buildings()
  -- draw each building bounds
  for b in all(buildings) do
    local template = b.template[1]
    local w = (template[3] - template[1]) * 8  -- width in pixels
    local h = (template[4] - template[2]) * 8  -- height in pixels
    local x,y = b.x,64  -- screen coords
    
    -- building frame
    rect(x,y, x+w-1,y-h-1, 12)
    
    -- id and position
    print(b.template_id, x+2, y+2, 64)
  end
end

::_:: -- game loop begin
cls(0)

	-- easy input vars
⬅️,➡️,⬆️,⬇️,🅾️,❎
=
btn(0),btn(1),btn(2),btn(3),btn(4),btn(5)



	-- update all object layers
for a=1,8 do
	for _,o in pairs(objs[a])do
		o:upd()
	end
end


for _,l in pairs(loops) do
	l()
end


	-- obj deletion queue
for _,o in pairs(del_que) do
	del(objs[o.l],o)
	
	if o.body then
		del(bodies,o)
	end
	
	foreach(o.objs,o.del_obj)
	foreach(o.loops,o.del_loop)

	del(del_que,o)
end

-- adjust camera
camx,camy=player.x-28,2
camera(camx, camy)

-- draw building debug info
debug_draw_buildings()

	-- print logs
for i,l in pairs(logs) do
	?l,camx,10*(i-1)+camy,8
end

flip()goto _
-->8
-- physics
local function add_col_pnt(_ENV,x,y)
	add(col_pnts,{x,y})
end
local function gen_col_pnts(_ENV)
	w_pnts,h_pnts,col_pnts
	=
	ceil(w/8),ceil(h/8),{}
	
	if w>3 do
		for ow=0,w_pnts do 
			local wp=ow*(w/w_pnts)-hw 
			add_col_pnt(_ENV,wp,hh)
			add_col_pnt(_ENV,wp,-hh)
		end 
		
		for oh=1,h_pnts-1 do
			local hp=oh*(h/h_pnts)-hh 
			add_col_pnt(_ENV,-hw,hp)
			add_col_pnt(_ENV,hw,hp)
		end
	else add_col_pnt(_ENV,hw,hh) end
end



local function phys_init(_ENV,nb_func,is_b)
	dx,dy,c_id,
	body,g,b_func,
	ent_col
	=
	0,1,is_b and is_b~=true and is_b or id,
	is_b,.3,nb_func,
	bind_front(col_check,_ENV)
	
	if(w)gen_col_pnts(_ENV)
	if(is_b)add(bodies,_ENV)
	return _ENV
end


function pnt_col(ox,oy,bods,f)
	local nx,ny,m=ox/8,oy/8
	m=mget(nx,ny)
		
	if (fget(m,f or 0)or oy<0)return 1
	if bods do
		local bx,by
		
	 for i,_ENV in next,bodies do
	  if w do
		  if(c_id~=bods)bx,by=dist(ox,x),dist(oy,y-dy) if(bx<hw and by<hh)return 1
		end
	 end
	end
	
	return
end

function o_pnt_col(_ENV,ox,oy,bods,f)
	return pnt_col(x+ox,y+oy,bods,f)
end



function map_col(_ENV,ox,oy,f)
	local tile
	
	for i,p in next,col_pnts do
		tile=o_pnt_col(_ENV,p[1]+ox,p[2]+oy,_,f)
		if(tile)break
	end
	return tile
end


function body_col_check(_ENV,vx,vy)
 local ox,oy=0
 for i,b in next,bodies do
	if(b.w)if(b.c_id~=c_id)ox,oy=dist(x+vx,b.x),dist(y+vy,b.y-b.dy) if(ox<hw+b.hw and oy<hh+b.hh)return b
	end
end


function col_check(_ENV,f) -- alt flag
	local mapx,bodx,mapy,body,
	mapxy,bodxy
	=
	map_col(_ENV,dx,0)
	or
	map_col(_ENV,dx,0,f),
	
	body_col_check(_ENV,dx,0),

	map_col(_ENV,0,dy)
	or 
	map_col(_ENV,0,dy,f),
	
	body_col_check(_ENV,0,dy),
	
	map_col(_ENV,dx,dy),
	body_col_check(_ENV,dx,dy)
	
	
	if not (mapx or bodx or mapy or body) and (mapxy or bodxy)do
		x+=dx
		y-=1
		b_func(_ENV,true)
		b_func(_ENV)
		coly=true
		return
	end
	
	if not mapx and not bodx do
		x+=dx
		colx=_
		
	else
		if(bodx)bodx.b_func(bodx,true,_ENV) b_func(_ENV,true,body) else b_func(_ENV,true)
			colx=true
		end
	
	
	if not mapy and not body do
		y+=dy
		coly=_
		
	else
		if body do
			body.b_func(body,_,_ENV)
			b_func(_ENV,_,body)
			
			--if(not body.coly and not coly)dy=body.dy
			if(not body.colx and not colx)dx+=(body.x-body.x+body.dx)*.2
		else
			b_func(_ENV)
		end
		coly=true
	end
end


local function snap_8(i,m)
 return (i&0xfff8)-m 
end

local function ent_snap(_ENV,ox)
	if(climb)return
	if ox do
		dx*=.5
	else
		py,y,dy,coly
		=
		dy,snap_8(y,-4),1
		
		if(map_col(_ENV,0,2,6)and not o_pnt_col(_ENV,4,0,true)and lever_on)x+=.67 if(not global)set_global(_ENV)
	end
end

local function ent_fall(_ENV)
	dy+=g
	dy*=.97
	prey=dy
end
__gfx__
00000000111111111002000000000001000000001111111111111111111111111111111111111111100500001000000011111111222222222222222211111111
00000000111111111049210000122101001221001000000000000001000000001000000000000001010500000100000000000000200000000000000200000001
0070070011111111104a941001499411014994101000000055555501555555551000550000055001001500000010000000005500200000000000000200005001
0007700011111111109a7920029a7921029a79201005000000000501500000001005005000500501000500000001000000000500200000000000000205550501
0007700011111111109a7920029a7921029a79201000500055055501555055501000500505005001000510000000100000500550200002200220000200505001
007007001111111110147920029a7921029a79201005000005505501555505551005000050000501000501000000010005500000200000200020000200505001
00000000111111111001442002444421024444201000500000000501500000001000500050005001000500100000001000050000200000200020000200500501
00000000111111111000110000111101001111001005000055555501555555551005000050000501000500010000000150000000200000000000000200055001
00111110000002100000100000011100000000001000000000000000000110011111111111111111111111110000000111111111111511110005000010000000
02888882001128810202820001288821001111101012210000000000001881011122222222222222000000010000000100000000000500000005000010000000
18888882028888821828881001888821028888821149941000000000008888011211222121212121000000010000000100000000000500000005000010000000
1821821018888820188828108888210018218210129a792000000000008888011212111212121212000000010000000100000000000500000005000010000000
1821821018221110188828102888210018888882129a792000000000002882011222222121221221000000010000000100000000000500000005000010000000
1888888218888820182888100188882118218210129a792000000000000220011211121212121212000000010000000100000000000500000005000010000000
02888882028888200212820000288821028888821244442000000000001881011222212121212121000000010000000100000000000500000005000010000000
00111110001111000100100000011100001111101011110000000000001281011122222222222222111111110000000100000000000500000005000010000000
11111111000000001111111111111111111111111111111110000001111111111111111111111111100000005555511111111111111111110002000000000000
11111111009999900000000000000001100000000000000010000001222222111111111111111111010000001111511110000000110000000049210000099000
111111110090009000000000000000011000000000000000100aa00112221121111111111111111100100000555551111000000010100000004a941000099000
1111111100900000aa00aa00aa00aa0110aa00aa00aa00aa100aa00121112121111111111111111100050000111155551000000010010000009a792000099099
1111111100000009aa00aa00aa00aa0110aa00aa00aa00aa1000000112222221111111111111111100051000111151111000000010001000009a792000999999
11111111000009900000000000000001100000000000000010000001212111211111111111111111000501001155511110000000100000000014792000990990
111111110000900000000000000000011000000000000000100aa001121222211111111111111111000500101111511110000000100000100001442000099900
111111110000000011111111111111111111111111111111100aa001222222111111111111111111000500011111511110000000100000000000110000000000
00077000000000000000000000077000000770000000000000000000000000000000000000077000000000000000000000000000000000000000000000011100
00070700000770000007700000070700000707000007700000077000000770000007700000070700000000000000000000000000000000000000000000167610
00077700000707000007070000077700000777000007070000070700000707000007070000077700000000000000000000000000000000000000000001677761
00777000007777000007770000077000007770000777770000777700007777000007770000777000000000000000000000000000000000000000000001d67671
007777000077770000777000007770000707777070077077070777000077770000077000007777000000000000000000000000000000000000000000015d6761
0077770000777700007777000077770000077700000770000707707000777700000777000077777000000000000000000000000000000000000000000015d610
00077000000770000077770000777700077000700077070000077000000770000007770000700000000000000000000000000000000000000000000000011100
00077000000770000007700000077000000000000000070000007000000700000070000007000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c00c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c00c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c00000cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc000cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010101010101010101010101010101010101010100010101010101010001010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002d1c1c1c0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000002d1c1c1c1c1c0b0000000000000000002d1c0b0000000000000000000000000000002d1c1c0b000000000000000000000000000000000000001f2121211b002d1c1c1c0b000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000002d0b00000000000000000000001f11121012141700000000000000000002040300000000000000000000000000000002040403000000000000000000000000000000000000002a2121211b001f0400041b000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000001f1b00000000000000000000000221212121211b2d0b0000000000000002040300000000000000000000002d1c0b00020404030000000000000000000000002d1c0b000000001e1d1d1d1d000b04040003000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002d1c0b00020300000000000000000000001f0404210421031f1b000000002d0b000204041c1c1c1c1c0b00002d1c1c1b040300020404030000000000002d1c1c1c0b00020403000000001e1e1e1e1e00002c151b1c000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000020003001f1b002d1c1c1c1c1c1c0b0000020421042104030203002d0b0002030002040404040404040300000204040404030002040403002d1c1c0b00020404040300020403000000002d1d1c1d0a0000021f0300000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001f041b00020300021012111214111700000221042104041b0203001f1b0002030002040404141304040300000204040404030002040403000204040300020404040300020403002d0b001f2121211b00001f151b00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000020403001f1b00020421040421041b0000020421040421031f1b000203001f1b00020404040d0e04040300000204040404030002040403000204040300020404040300020403000203001f2121211b0000021f0300000000000000000000000000000000000000000000000000000000000000000000000000000000

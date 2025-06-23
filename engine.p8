pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- reunion
-- by virtuavirtue
-- music by archonic

-- contributors:
-- ms mouse


-- object system

	-- ⧗ token tipz ⧗ --
-- replace for loops with foreach
-- += on a bunch is less than 1,2=1+1,2+2
-- use ox,oy more

-- make local function versions of globals to remove extra o param
-- make saving a function?
-- remove the other fade version


 -- todo

-- rolling into walls trips you
-- unique animation

-- tripwire function

-- grass not unloading
-- suspension for bridge

-- sustain velocity jumping from conveyor


--[[ tile objects
	duplicates replace dif tiles

 64/65/66|player 
 15|box (put near rope)
 35/127|box stop rails
 78|spear
 103|enemy 81/82|running enemies
	90|rope 93|hang rope 88|fail rope
	86|checkpoint
	219|breakable glass
	
	89|prop corpse
	108|hung corpse (put near rope)
	
	255|grass
	79|conveyor belt
	240|switch
	45|tripwire
]]



local function compose(a, b)
	return function(...) return a(b(...)) end
end

local function bind_front(f, v)
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


local function arr_2d(x,y)
	local arr={}
	for i=1,x do
		add(arr,{})
		for j=1,y do
			add(arr[i],{
				objs={},
				cache={}
			})
		end
	end
	return arr
end

local function add_lim_arr(arr,o)
	if(#arr>300)return del_obj(o)
	return add(arr,o)
end



cartdata("reunion_monolith")
local DEBUG,
startx,starty,

objs,ents,
bodies,targs,loops,
logs,del_que,id_cnt,
camx,camy,scx,scy,mus_pri,

tile_cache,roomx,roomy,
bg_gore,gore,

pre_amb,fade_i,cur_pal,

map_layers
=
true, -- disable debug
--2,1,
dget(0),dget(1), -- set spawn room!


{},{},
{},{},{},
{},{},0,
0,0,0,0,0,

arr_2d(8,3),1,1, -- tile cache
{},{},

0,0,1, --set start color

	-- map layer | flag hex
split_arr'2,2|4,32|7,4'


local function log(l,i)
	logs[i or 1]=l or "false"
end


local function new_loop(func)
	return add(loops,func)
end
function new_l_loop(func,l,x,y)
	return new_obj({
		_,
		func,
	},l,x,y)
end

local function del_obj(o)
	add(del_que,o).del=true
	return o
end

local function to_arr(s)
	return type(s)=="string"and split(s)or(type(s)~="table"and {s}or s)
end

local del_loop,rnds
=
bind_front(del,loops),compose(rnd,to_arr)



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


function new_obj(no,l,x,y)
	local o=setmetatable({
		loops={},objs={},
		init=no[1],upd=no[2],
		l=l,id=id_cnt
	},{__index=_ENV})
	
	id_cnt+=.001
	
	o.new_loop,o.del_loop,o.new_timer,
	o.new_obj,o.del_obj
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
	
	return add_lim_arr(objs[o.l],o)
end


	-- string param
 -- size x,y, sprite offset x,y
local function box_init(_ENV,str,col)
	c,w,h,sx,sy -- sprite scale
	=
	to_arr(col),unpack(split(str))
		
	hw,hh,cl
	=
	w*.5,h*.5,#c	
	return _ENV
end



--local function rnd_bool()return rnd()<.5end

--[[local function get_params(lh,h)
	local lm,m
	if (h) lm,m=lh,h else lh=to_arr(lh) lm,m=lh[1],lh[2]
	return lm,m
end]]

--[[local function rndi(lh,h)
	local lm,m=get_params(lh,h)
	return (rnd(m+1-lm)&-1)+lm
end]]

local function rndf(lh,h)
	if(not h and type(lh)=="number")return lh
	local lm,m
	if(h)lm,m=lh,h else lh=to_arr(lh) lm,m=lh[1],lh[2]
	return rnd(m-lm)+lm
end


local function rnd_obj_pos(o,x,y)
	x,y=x or 0,y or 0
	return rndf(o.x-o.hw,o.x+o.hw)+x,rndf(o.y-o.hh,o.y+o.hh)+y
end



local function state_init(_ENV,arr,i)
	states,state_func
	=
	arr,arr[i or 1]
end

local function state(_ENV,st)
	state_func=states[st]
end

local function upd_state(_ENV)
	state_func()
end
-->8
-- math/physics

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


local function x_rng(_ENV,r)
	return abs(dx)>abs(r)
end
local function y_rng(_ENV,r)
	return abs(dy)>abs(r)
end

local function d_rng(o,r)
	return x_rng(o,r)or y_rng(o,r)
end

local function dist(a,b)
	return abs(a-b)
end
local function rng(a,_ENV)
 local dx,dy=dist(x,a.x),dist(y,a.y)
 return dx>dy and dx+dy*.5or dy+dx*.5
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


local function near_arr(_ENV,r,arr)
	local id,last_rng,near_b,cur_rng
	=
	id,r
	
	foreach(arr,function(cur_b)
		cur_rng=rng(_ENV,cur_b)
		if(cur_b.id~=id and cur_rng<last_rng)near_b,last_rng=cur_b,cur_rng
	end)
	return near_b
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
end -- todo - inline if only 3 used

--local snap_8=bind_front(band,0xfff8)
 -- todo - use instead if not inline?

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


local function lerp(a,b,t)
	return a+t*(b-a)
end


local function norm(x,y)
	local th=atan2(x,y)
	return cos(th), sin(th)
end


	-- todo env
local function new_spr(b1,b2,range,stf)
	local dx,dy,d2,d3,x,y
	
	return new_loop(function()
		dx,dy
		=
		b1.x-b2.x,b1.y-b2.y
		d2=sqrt(dx*dx+dy*dy)
		d3=(d2-range)/d2
		
		x,y
		=
		.5*dx*d3*stf,
		.5*dy*d3*stf
		
		b1.dx,b1.dy
		=
		mid(-5,b1.dx-x,5),mid(-5,b1.dy-y,5)
		b2.dx+=x
		b2.dy+=y
	end)
end



	-- todo _env
local function wire(ox,oy,seg_am,c,size,str,offx)
	local segs,
	seg1,seg2,p,oox,ooy
	=
	{}
 
	return new_obj({
		function(o)
			box_init(o,"3,0,0,1","6,7,14")
			
			o.set_grav,o.par_wire
			=
			function()
				foreach(segs,function(s) -- note - _env
					s.g=0
				end)
				return o
			end,
			function(par,nox,noy)
				p,oox,ooy=par,nox,noy
				return o
			end
			
			
			
			for i=1,seg_am do
				seg1={g=.3,x=ox+offx,y=oy+i*size*1.25,dx=0,dy=0,col=i==1and to_arr(c)[1]or rnds(c)}
				
				add(segs,seg1)
				if(i~=1)add(o.loops,new_spr(segs[i-1],seg1,size,str,5))else seg1.locked=true
			end
			o.je,o.segs=segs[seg_am],segs
		end,
		
		
		function(o)
			if(p)seg1=segs[1] seg1.x,seg1.y=p.x+p.sx*.5+oox,p.y+p.sy*.5+ooy
			o.je.dx-=rnd(.1) -- wind
			
			for i,seg1 in next,segs do
				if(not seg1.locked)ent_fall(seg1) seg1.dx*=.98 seg1.x+=seg1.dx seg1.y+=seg1.dy else seg1.dx,seg1.dy=0,0
				if(i~=seg_am)seg2=segs[i+1] line(seg1.x,seg1.y,seg2.x,seg2.y,seg1.col)
			end
		end
	},5,ox,oy)
end
-->8
-- visuals/sfx



	-- hd fade levels for gray
	
 -- gray,green,red,inverse
 
--[[
0x0302.0100,0x0706.0504,0x0b0a.0908,0x100e.0d0c|
]]

local palettes,
snds,
fades
=
deep_split[[0x0000.0000,0x0000.0000,0x0000.0000,0x0000.0000|
	0x0000.0000,0x0000.0000,0x0080.0000,0x0080.0000|
	0x0000.0000,0x8000.0000,0x8082.8000,0x0082.0000|
	0x8000.0000,0x8280.0000,0x8102.8280,0x0085.0080|
	0x8100.0000,0x8582.0080,0x0188.0282,0x0005.8081|
	0x0180.0000,0x0585.8082,0x8389.8802,0x0086.8201|
	0x8382.8000,0x8605.8284,0x0309.8988,0x0006.858c|

	0x0302.8000,0x0686.8504,0x0b0a.0908,0x0007.050c|
	0x0302.8100,0x8b03.0104,0x0b0a.0908,0x008a.830c|
	0x0302.8000,0x8904.8204,0x0b0a.0908,0x0009.840c|
	0x0302.8a07,0x8101.0304,0x0b09.8908,0x0000.830c|
]],


--[[stop loop 1
	grab item 2
	climb 3
	slide/push 4
	
	soft hit 5
	roll 6
	drop item 7
	
	big hit 8
	small hit 9
	boing 10 (unused, invalid)
	
	shatter glass 11
	respawn 12
	grab rope 13
	
	ply land 14
	ply jump 15
	ply footstep 16
	
	grab ledge 17
	wind sway 18
	spear throw 19
	item notify 20
	
	climbing rope 21
	grass 22
]]

	-- pattern,priority,start,len
deep_split[[-1,9|
	2,8,5,4|
	6,5,18,7|
	5,9,17|
	
	6,10,6,4|
	0,9,0,22|
	6,7,10,3|
	
	1,9,6,10|
	1,8,0,6|
	5,2,0,9|
	
	5,9,0,17|
	7,10,0,10|
	6,5,25,2|
	
	2,3,0,3|
	0,5,21|
	2,1,2,4|
	
	6,5,17,1|
	2,2,19,10|
	6,8,0,6|
	6,2,27,3|
	
	6,3,31|
	2,4,9,10
]],


	-- fade for all palettes
	-- todo end fade to white?
deep_split[[
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0|
	0,0,0,0,0,0,0,0,0,0,0,0,0,1,0|
	0,0,0,0,0,0,1,0,0,0,0,0,0,5,0|
	0,0,0,0,0,1,5,0,0,2,0,1,0,13,0|
	0,0,0,0,0,5,13,0,2,4,2,5,1,6,0|
	0,0,2,2,1,13,6,2,4,9,3,13,5,7,0|
	1,2,3,4,5,6,7,8,9,10,11,12,13,14,0
]]


local function draw_pal(ind,state)
	local p=palettes[ind+7]
	
	poke4(state==0 and 24320 or 24336,
		unpack(p)
	)
end



local function fade(m,g)
	new_timer(5,function()
		fade_i+=m
		draw_pal(fade_i-7)
		if(fade_i~=g)fade(m,g)
	end)
end

local function quick_fade()
	new_timer(3,function()
		fade_i+=1
		pal(fades[fade_i])
		if(fade_i~=#fades)quick_fade()
	end)
end



local function spr_draw(_ENV)
	spr(spri,x-(sx or 0),y-(sy or 0),1,1,flipx)--,o.flipy)
end



local function prt_init(
		_ENV,am,p,ox,oy,
		c,dx,dy,r
	)
	
	prts_que,prts,x,y,
	del_prt,check_prts
	=
	{},{},ox,oy,
	function(p)
		add(prts_que,p)
	end,
	function()
		foreach(prts_que,function(prt)
			del(prts,prt)
			deli(prts_que,1)
		end)
		
		if(#prts==0)del_obj(_ENV)
	end
	
	
	for j=1,am do
		prt=setmetatable({
			r=r and rndf(r)or rndf(p.w*.4,p.w*.7),
			c=rnds(c),
			dx=dx and rndf(dx)or rndf(-p.w*.3,p.w*.3),
			dy=dy and rndf(dy)or rndf"-1.5,1"
		},{__index=_ENV})
		
		add(prts,prt)
		if(p)prt.x,prt.y=rnd_obj_pos(p,x,y) else prt.x,prt.y=rndf(x),rndf(y)
	end
end

local function prt_draw(_ENV)
	circfill(x,y,r,c)
end
local function upd_prt(_ENV)
	x+=dx
	y+=dy
	prt_draw(_ENV)
end


 -- basic shrinking moving particle
local function basic_prt(ny,am,p,x,y)
	return new_obj({
			-- init
		function(_ENV)
			prt_init(_ENV,am,p,x,y,p.c)
		end,
			-- upd
		function(_ENV)
			foreach(prts,function(_ENV)
				r-=.1
				dx*=.9
				if(ny)dy+=ny else dy*=.9
				
				upd_prt(_ENV)
				if(r<.001)del_prt(prt)
			end)
			check_prts()
		end
	},7)
end



local prts={
		-- dust 1
	bind_front(basic_prt,_),
	
	
		-- gore 2
	function(am,p,ox,oy)
		return new_obj({
				-- init
			function(_ENV)
				prt_init(_ENV,am,p,ox,oy,2,"-1,1","-3,5",0)
			end,
				-- upd
			function(_ENV)
				foreach(prts,function(_ENV)
					if pnt_col(x,y+dy)do
						dy*=.7
						r=lerp(r,rndf".2,4",.1)
						if(dy<.05)add_lim_arr(gore,_ENV)del_prt(_ENV)
					else
						dy+=.3
					end
					
					if(pnt_col(x+dx,y))dx*=.8
					upd_prt(_ENV)
				end)
				check_prts()
			end
		},6)
	end,
	
	
	
		-- flies 3
	function(am,p,ox,oy)
		local ti,fdy
		return new_obj({
				-- init
			function(_ENV)
				prt_init(_ENV,am,_,ox,oy,p or"6,7,14","-10,10","4,10","-1,1")
			end,
				-- upd
			function(_ENV)
				ti=t()*.5
				
				foreach(prts,function(_ENV)
					fdy=dy+ti*sgn(r)
					x,y,dx
					=
					ox+cos(fdy)*(dx+6),
					oy+sin(fdy)*(dx),
					lerp(dx,rndf"-30,30",.05)
					
					pset(x,y,c)
				end)
			end
		},7)
	end,
	
	
		-- flying dust 4
	function(am,p)
		return new_obj({
				-- init
			function(_ENV)
				prt_init(_ENV,am,_,
					{0+camx,128+camx},{0+camy,128+camy},
					"6,7,14","-8,-2","0,1",0
				)
			end,
				-- upd
			function(_ENV)
				foreach(prts,function(_ENV)
					upd_prt(_ENV)
					
					if x-camx<0do
						x+=128
						y=rndf(camy,camy+128)
					elseif y-camy>128do
						y+=128
					end
				end)
			end
		},7)
	end,
	
	
		-- dirt/glass 5
	bind_front(basic_prt,.1)
}


	-- p,x,y
local function new_prt(am,ind,...)
	return prts[ind](am,...)
end

local function imp_prt(o,amm,x,y)
	new_prt(amm or 4,1,o,x,y)
end


function shake(str)
	local off,str=.1,str or .95
	local off_loop=new_loop(function()
		local offx,offy
		=
		16-rndf'0,32',16-rndf'0,32'
		
		offx*=off
		offy*=off
		
		camera(camx+offx,camy+offy)
		off*=str
		if off<.05 then
			camera(camx,camy)
			del_loop(off_loop)
		end
	end)
end

function impact(o,v,p_am,p)
	if(not p)imp_prt(o,p_am,0,4)
	if(v>5)play_sfx(8)shake()else play_sfx(9)
end


local function fake_gore(x,y)
	for i=1,20do
		add_lim_arr(bg_gore,{x=x+rndf"-4,9",y=y+rndf"-5,12",r=rndf"1,3",c=2})
	end
	
	new_l_loop(function()
		spr(89,x,y+2)
	end,5)
end


--[[local function log_out(s,x,y,c,o)
	color(o)
	?'\-f'..s..'\^g\-h'..s..'\^g\|f'..s..'\^g\|h'..s,x,y
	?s,x,y,c
end

local function cen_textx(s)
	return camx+65-#s*2
end]]



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



function star_draw()
	local stars={}
	return new_l_loop(function()
		local r_c,b=0
		foreach(stars,function(_ENV)
	  b=c&-1
	  if(c-b<.5)pset(camx+x,camy+y,c)
	  c+=.005
	  r_c+=1
		end)
		
		if(r_c==0)stars={}
		if(r_c<128)b={x=rnd(128),y=rnd(64),c=1+rnd(12)} add(stars,b)
	end,1)
end





local function set_music(pri,id,t)
	if pri>=mus_pri and id~=cur_mus do
		music(-1,t) 
		new_timer((stat(54)~=-1and stat(54)~=id)and t*.03or 0,function()
			if(cur_mus~=id)return
			music(id,t)
		end)
		
		mus_pri,cur_mus=pri,id
	end
end


 -- no param = stop loops
function play_sfx(i)
	local s=snds[i or 1]
	
	if(s[2]>=pre_amb or stat(46)==-1)pre_amb=s[2] sfx(s[1],0,s[3],s[4])
	if(not i)pre_amb=0
end
-->8
-- ai
local function add_gore(o,amm)
	new_prt(amm or 4,2,o)
end



local function ai_init(_ENV,funcs)
	kill,long_fall,fall_chck,
	throw
	=
	function(boom)
		if(dead or not boom and safe)return
		dead,itemy=true,3
		
		del(bodies,_ENV)
		del(ents,_ENV)
		funcs[1](boom)
	end,
	
	
	funcs[2],
	

	function()
		if prey>2.5 do
			imp_prt(_ENV,8,0,4) 
			if prey>4do
				play_sfx(5) shake(.98) kill() return true
			elseif not ⬇️ or not x_rng(_ENV,1.2)do
				long_fall(15)return true 
			end
		end
		
		prey=0
	end,
	
	funcs[3]
end




local function ent_stop(_ENV,x)
	if(d_rng(_ENV,2)and imp)impact(_ENV,d_rng(_ENV,5)and 8or 4)
	if(x)dx*=-.5else dy=0
end


 -- todo env
local function new_arm(p,ox,oy,c)
	local targ_x,targ_y
	=
	0,0
	
	
	return new_obj(
		{
			function(o)
				--box_init(o,0,c)
				
				o.ox,o.oy,o.id,o.spd,
				o.wire
				=
				ox,oy,p.id,.4,
				
				wire(
					p.x,p.y,3,c,p.w,1,0
				).set_grav(0).par_wire(p,0,0)
				
				state_init(o,{
						-- ply
					function()
						--mx,my=o.move_x,o.move_y
						--o.move_x=btn(⬅️)and mx-dw or(btn(➡️)and mx+dw or mx)
						--o.move_y=btn(⬆️)and my-dh or(btn(⬇️)and my+dh or my)
					end
				})
			end,
			
				-- update
			function(o)
				o.move_x,o.move_y
				=
				p.x+o.ox,p.y+o.oy
				upd_state(o)
				
				if o.off or rng(o,p)>6*p.w or not pnt_col(o.x,o.y)do
					o.col,targ_x,targ_y
					=
					_,o.move_x,o.move_y
				elseif not o.col do
					o.col=true
				end
				
				
				o.x,o.y
				=
				lerp(o.x,targ_x,o.spd),
				lerp(o.y,targ_y,o.spd)
				
				o.wire.je.x,o.wire.je.y
				=
				targ_x,targ_y--o.x,o.y
				--pset(o.x,o.y,14)
			end
		},6,p.x,p.y)
end



local function rope_upd(_ENV)
	local seg
	foreach(bodies,function(ob)
		if(not ob.tog_rope or(ob.box and not can_box))return
		
		if not ob.seg do
			for j=2,#segs do
				seg=segs[j]
				
				if rng(seg,ob)<4do
					ob:tog_rope(_ENV,seg,j)
					
					if p==3do
						set_global(_ENV)
						del_loop(upd_loop)
						new_timer(10,function()
							seg=segs[1]
							seg.locked=_
							
							impact(_ENV,3,3)
							play_sfx(5)
							
							if(ob.seg)ob.dy=2 ob.tog_rope()
							
							new_timer(100,function()
								del_obj(_ENV)
							end)
						end)
					end
				end
			end
		end
	end)
end



local function item_init(_ENV,funcs)
	add(targs,_ENV)
	pickup,use,drop
	=
	unpack(funcs)
end


local function ent_init(_ENV,is_ent)
	prey,itemy,dir,
	pickup,drop,use
	=
	0,1,1,
	
	function(new_item,p1,p2)
		if(new_item.user)new_item.user.drop()
		item,new_item.user
		=
		new_item,_ENV
		
		new_item.pickup(p1,p2)
	end,
	
	function(fx)
		if(not item)return
		item.drop()
		if(not fx)play_sfx(7)
		item.user,item=_
	end,
	
	function()
		if(item.use)item.use()
	end
	
	if(is_ent)add(ents,_ENV)
end
-->8
-- game
local function get_room()
	return tile_cache[roomx+1][roomy+1]
end

function set_global(_ENV)
	global=true
	del(get_room().cache,ind)
	del(get_room().objs,_ENV)
end

function undo_global(_ENV)
	global=_
	add(get_room().cache,ind)
	add(get_room().objs,_ENV)
end

local function gen_ind(_ENV,id,p)
	ind={id,x,y,p}
end

local function oanim_and_ostate(o)
	return bind_front(anim,o),bind_front(state,o)
end -- note - can be removed and use _env?



local ents={
		-- ply 1
	function(ox,oy,p)
		local spd,gnd_spd,on_flr,
		pcamx,pcamy,
		
		pd,cd,climb,input,
		stepped,rolling,
		near_item,pre_near,prex,preu,
		targx,targy,no_ctr,can_jump,
		
		seg,seg_spr,
		dir,rope,
		slideflag -- static for tokens
		=
		.35,.35,true,
		startx*128,starty*128
		
		
		return new_obj({
			function(o)
				box_init(o,"3.5,7,3.5,2","6,7")
				phys_init(o,ent_snap,"e")
				ent_init(o,true)
				
				local oanim,ostate
				=
				oanim_and_ostate(o)
				
				
				ai_init(o,{
					function(viol)
						music(60)
						oanim(6)
						ostate(3)
						o.del_loop(seg_spr)
						o.drop()
						
						add_gore(o,10)
						
						if(viol)add_gore(o,10)
						
						new_timer(80,function()
							run()
						end)
					end,
					
					
					function(amm)
						no_ctr=true
						ostate(2)
						oanim(4)
						
						if(o.prey>3.2)shake()
						
						if o.prey>3.5do
					 	o.trip()
					 else
					 	new_timer(amm,function()
								no_ctr=_
							end)
						end
					end,
					
					
					function() -- note - throwing token optimize?
						o.long_fall(5)
						oanim(15)
					end
				})
				
					-- last 2 params - speed and loop
					--[[ 
						idle,
						run,
						dodge 3,
						
						crouch,
						stand,
						die 6,
						
						climb,
						hang,
						walk_back 9,
						
						climb down,
						swing left,
						swing right 12,
						
						slide,
						revive,
						spear throw,
						
						trip 16,
						trip recover
					]]
				anim_init(o,
				[[64,65,66,67,4,1|
				80,81,82,83,84,1,1|
				96,97,98,99,100,101,102,70,71,67,1,0|
				
				71,70,1,0|
				71,67,1,0|
				71,86,115,87,88,116,89,0,0|
				
				90,91,92,93,70,71,64,2,1|
				74,109,90,109,5,1|
				84,83,82,81,80,1,1|
				
				93,92,91,109,90,91,92,3,1|
				90,109,74,2,0|
				109,90,110,2,0|
				
				71,91,74,90,109,110,1,0|
				89,89,89,89,116,88,87,115,86,86,86,70,70,70,70,70,86,86,70,70,86,70,86,70,70,70,71,67,3,0|
				92,93,70,71,1,0|
				96,115,88,116,89,1,0|
				116,88,87,115,86,70,71,3,0
				]])
				
				
				
					-- local funcs 1
				local function slide_col(r,ret)
					pd=r and 3or 4
					if o_pnt_col(o,1,-1,_,pd)
					or o_pnt_col(o,-1,0,_,pd)do
						if(ret)return true
						o.dx,o.dy,o.flipx
						=
						r and 1or-1,0,not r
						
						o.dir,cd,slideflag=o.dx,o.dx*.1,r
						
						ostate(7)
						oanim(13)
						play_sfx(4)
					end
				end
				
				
				local function climb_upd() -- climb rope
					o.dx,o.dy
					=
					(seg.x-ox)*.5,
					(seg.y-oy)*.12
					
					if rng(o,seg)>10or not rope do
						o.del_loop(seg_spr)
						o.tog_rope()
						
					elseif dist(oy,seg.y)<1do
						o.del_loop(seg_spr)
						if(o.seg_i~=#rope.segs and not ⬆️ or o.seg_i==2)o.nex_anim=8
						
						climb,seg_spr,o.dx,o.dy
						=
						_,
						add(o.loops,new_spr(o,seg,0,.5)),
						0,0
					end
				end
				
				
				local function recover_loop(ani)
					o.rec_loop
					=
					o.new_loop(function()
						if(not ⬆️ or cur_pal<1)return
						o.del_loop(o.rec_loop)
						oanim(ani)
						o.nex_st,seg_spr,no_ctr=1
					end)
				end
				
				
				local function swing_dir(way) -- swing in a direction
					cd,input,o.nex_anim=way<0and(dir>0and 11or 12)or(dir>0and 12or 11),way
					if o.anim_i~=cd do
						seg.dy+=.4
						oanim(cd)
						play_sfx(18)
						seg.dx+=.5*way
					end
					seg.dx+=.03*way
					seg.dy-=.1
				end
				
				local function trip_state()
					ostate(2)
					no_ctr,rolling=true
					recover_loop(17)
				end
				
				
				
				
					-- member functions
				o.spri,o.coly,
				o.tog_push,o.trip
				=
				89,true,
				
				function(tog)
					spd,o.push
					=
					tog and.18or.35,tog
					gnd_spd=spd
				end,
				function() -- trip
					play_sfx(5)
					oanim(16)
					shake()
					
					trip_state()
					o.drop()
				end
				
				
				
				function o:tog_rope(r,s,i) -- toggle rope
					if r do
						if(rope==r and preu or o.anim_i==7or o.coly or climb or seg_spr or rolling or o.push)return
						play_sfx(13)
						
						oanim(8)
						ostate(6)
						o.b_func,seg_spr,preu
						=
						ent_stop,add(o.loops,new_spr(o,s,0,.5)),
						⬆️
					else
						o.del_loop(seg_spr)
						
						ostate(1)
						
						o.flipx=⬅️ or(not ➡️ and o.dx<0)
						
						o.dir,o.b_func,
						o.spri,preu,
						climb,seg_spr
						=
						o.flipx and -1 or 1,ent_snap,
						80,true
						
						o.dx=o.dir*1.5
					end
					
					o.seg,seg,rope,o.seg_i
					=
					s,s,r or rope,i
				end
				
				
				
				
					-- local funcs 2
				local function check_slide()
					slide_col()
					slide_col(true)
				end
				
				local function roll()
					play_sfx(6)
					oanim(3)
					o.dx*=2.5
					o.prey,o.safe,rolling,cd,pd
					=
					0,true,true
				end
				
				local function item_upd(throw)
					near_item=near_arr(o,10,targs)
					
					if not o.item do
						if near_item do
							if(pre_near~=near_item)play_sfx(20)
							if(❎ and not prex)o.pickup(near_item)prex=true
						end
					elseif throw and ❎ and not prex do
						o.use()
						prex=true
					
					elseif 🅾️ do
						o.drop()
					end
					
					pre_near=near_item
					
					if(prex and not ❎)prex=_
				end
				
				local function climb_col(x,y)
					return not no_ctr and not o_pnt_col(o,5*dir,-y,"e")
					and not o_pnt_col(o,7*dir,-7,"e")
					and o_pnt_col(o,x*dir,-2,"e")
				end
				
				local function move_in_dir(inp)
					o.dx+=spd*inp
					if(on_flr and not o.push)o.flipx,o.dir=⬅️,inp
					
					if(on_flr and input and input~=inp and x_rng(o,.6))o.long_fall(5)
					input=inp
				end
				
				local function start_climb(ani,nex_i)
					play_sfx(21)
					o.del_loop(seg_spr)
					if(o.anim_i~=ani)oanim(ani)
					
					o.seg_i+=nex_i
					seg=rope.segs[o.seg_i]
					
					o.seg,o.dx,o.dy,climb,
					seg_spr,o.nex_anim
					=
					seg,0,0,true,
					o.new_loop(climb_upd)
				end
				
				
				local function jump_and_roll_chck()
					if ⬆️ do
						if not preu and not o_pnt_col(o,0,-5-o.dy,true)do
							if(o.push)o.drop(true)
							o.dy,can_jump=-1.5
							o.dx*=1.1
							play_sfx(15)
						end
					elseif not slideflag do
						preu=_with_env
					
						if cd do
							if o.spri==82do
								if(not stepped)play_sfx(16)
								stepped=true
							else
								stepped=_
							end
						end
							
						if ⬇️ do
							if x_rng(o,1)and dir==sgn(o.dx)do
								roll()
							else
								oanim(4)
								o.nex_st,o.itemy=_,3
								ostate(2)
							end
						end
					end
				end




						-- states
				state_init(o,
				
						-- basic 1
					{function()
						o.ent_col()
						ox,oy,dir
						=
						o.x,o.y,o.dir
												
						if not rolling do
							if ⬅️ do
								move_in_dir(-1)
							elseif ➡️ do
								move_in_dir(1)
							else
								input=_
							end
							
							if o.coly do
								if not on_flr do
									preu,spd,on_flr
									=
									⬆️,gnd_spd,true
									if(o.prey>2)play_sfx(14)
									if(o.fall_chck())return
								end
								
								can_jump,cd,pd
								=
								true,
								x_rng(o,.5)and input and not o.colx,
								o.push and sgn(o.dx)~=dir
								
								if not no_ctr and o.anim_i~=(pd and 9or 2)and cd do
									oanim(2)
									if(pd)oanim(9)
								elseif o.anim_i~=1and not cd do
									oanim(1)
									o.dx*=.2
								end
								o.dx*=.8
								
								jump_and_roll_chck()
								
								
							else
								if on_flr do -- fall
									oanim()
									spd,on_flr=.1
									new_timer(2,function()
										can_jump=_
									end)
								elseif o.dy>0do
									check_slide()o.spri=81
								else
									o.spri=80
								end
								
								ent_fall(o)
								o.dx*=.93
								
								if(can_jump)jump_and_roll_chck()
								if(climb_col(3,5))play_sfx(17) ostate(4)oanim(8)targx,targy,o.dx,o.dy,o.y=ox+6.5*dir,snap_8(oy,4),0,0,snap_8(o.y,-3)
							end
							
							
						else -- rolling state
							o.dx*=.85
							if o.spri==70do
								
									-- crouch
								if(o.coly and ⬇️)rolling=_ ostate(2)oanim()
							elseif o.spri==67do
								rolling,o.safe
								=
								_
							end
							
							if(not o.coly)ent_fall(o)else o.fall_chck()
							check_slide()
						end
						
						item_upd(not rolling)
					end,
					
					
					
						-- crouch 2
					function()
						o.ent_col()
						ent_fall(o)
						o.dx*=.85
						
						if(no_ctr)return
						
						if(not o.coly)ostate(seg and 6or 1)o.nex_anim=seg and 8 return
						if not ⬇️ do
							if(not o.nex_st)o.nex_st,o.itemy=1,1 oanim(5)
						
						
							-- climb down
						elseif	not o_pnt_col(o,6*dir,10,"e")
						and not o_pnt_col(o,1*dir,5,"e")
						and not o_pnt_col(o,5*dir,0,"e")do
							o.dir,o.flipx,o.itemy,
							targx,targy,o.dx,o.dy,cd
							=
							-dir,not o.flipx,1,
							ox+3*dir,oy+7.5,0,0
							
							ostate(5)oanim(10)
							play_sfx(3)
						end
						
						item_upd(true)
					end,
					
					
					
						-- die 3
					function()
						o.ent_col()
						ent_fall(o)
						o.dx*=.8
						for i=1,5do
							poke(rnd(0x2000),rnd(0x2000))
						end
						shake()
					end,
					
					
					
						-- hang 4
					function()
						if ⬇️ or not climb_col(6,6)do
							ostate(1)
							o.spri,no_ctr,can_jump=81,true
							
							new_timer(5,function()
								no_ctr=_
							end)
						elseif ⬆️ do
							cd=true play_sfx(3)
							ostate(5)oanim(7)
						end
					end,
					
					
						-- climb ledge 5
					function()
						o.climb,o.x,o.y=true,lerp(ox,targx,.2),lerp(oy,targy,cd and.21or.26)
						
						if(dist(oy,targy)<.1)on_flr,spd,o.dy,o.climb=true,.35,.5 ostate(cd and 1or 4)oanim(cd and 1or 8)if(not cd)targx,targy=ox+6.5*dir,oy-7.3
					end,
					
					
					
						-- hang/swing on rope 6
					function()
						o.ent_col()
						
						
						if ⬅️ do
							swing_dir(-1)
							
						elseif ➡️ do
							swing_dir(1)
							
						else
							seg.dy+=.1input=_
						end
						
						if ⬆️ do
							if(preu)return
								
							if input do
								play_sfx(15)
								o.tog_rope()oanim()
								o.dy-=1
							elseif not climb and o.seg_i>2 do
								start_climb(7,-1)
							end
							
							
						elseif ⬇️ and not climb do
							if(o.seg_i==#rope.segs)o.tog_rope()o.dx,preu,climb=0,true return
							start_climb(10,1)
						else
							preu=_
							item_upd(true)
						end
						
						
						if(not rope)o:tog_rope()
					end,
					
					
					
							-- sliding 7
					function()
						o.ent_col()
						o.dx+=cd
						
						local fx=o.flipx and 4or 3
						
						if o_pnt_col(o,0,3,_,fx)
						or o_pnt_col(o,0,6,_,fx)do
							del_loop(pre_near)
							o.dy,can_jump,pre_near=abs(o.dx),true
							
							pd+=1
							if(pd%2==0)imp_prt(o,2,0,2)
							
							elseif not slide_col(slideflag,true)and o.coly do play_sfx()
							if(x_rng(o,1))o.dx,slideflag=1.5*sgn(cd) imp_prt(o,8,0,4) if(⬇️)ostate(1)roll() else o.trip()
						
						elseif not slide_col(slideflag,true)do
							if(not pre_near)pre_near=new_timer(5,function()can_jump=_ end)
							
							slide_col(not slideflag)
							o.dy+=.25
							o.dx*=.9
						end
						
						if(⬆️ and can_jump)ostate(1)play_sfx()jump_and_roll_chck()o.dx*=1.3
					end,
					
					
						-- nothing 8
					function()end
					},
				
				8)
				
				if p do
					trip_state()
				elseif DEBUG and save==10 do -- debug
					seg_spr,o.nex_anim
					=
					1,1
					
					recover_loop(14)
				else
					ostate(1)
				end
			end,
			
				-- main update
			function(_ENV)
				ox,oy,dir=x,y,dir
				upd_state(_ENV)
				
				--camera(ox-64,oy-64) debug
				
				if(inv_pal)pal(14,0)pal(0,14) spr_draw(_ENV) pal(14,14) pal(0,0) else spr_draw(_ENV)
				
				if(dead)return
				
					-- new room
				pcamx,pcamy
				=
				ox\128*128,oy\128*128
				
				if(pcamx~=camx or pcamy~=camy)load_room(pcamx/8,pcamy/8)
			end
		},6,ox,oy)
	end,
	
	
	
	
	
		-- spear 2
	function(ox,oy)
		local normx,normy,loop,kill_loop,
		prex,prey,targ,use
		=
		rndf"-.5,.5",1
		
		return new_obj({
			function(_ENV)
				box_init(_ENV,"3,1,0,1","6,7")
				phys_init(_ENV,ent_stop,"e")
				
				 -- todo combine with locals
				spear,imp=true,true
				
				item_init(_ENV,{
					function(die,snd)
						set_global(_ENV)
						
						use,loop,dx,dy
						=
						user,
						new_loop(
							function()
								x,y,normy
								=
								lerp(x,use.x,.8),
								lerp(y,use.y+use.itemy,.8),
								lerp(normy,-.5*use.dir,.2)
							end
						),0,0
						
						if(not die)normx,normy=1,.5 if(not snd)play_sfx(2)
					end,
					
					function()
						play_sfx(19)
						
						dx+=5*use.dir
						dy-=2-use.dy
						use.throw()
						
						id=use.id
						
						use.drop(true)
						
						kill_loop=new_loop(function()
							targ=near_arr(_ENV,4,ents)
							
							if targ do
								del_loop(kill_loop)
								targ.kill()
								
								if(targ.dead)targ.pickup(_ENV,true) play_sfx(5)
								id_cnt+=.001
								id=id_cnt
								
							elseif coly or colx do
								del_loop(kill_loop)
								id_cnt+=.001
								id=id_cnt
							end
						end)
					end,
					
					function()
						dx+=use.dx
						del_loop(loop)
					end
				})
			end,
			
			function(_ENV)
				if not user do
				 ent_col()
				 prex,prey=norm(dx,dy)
				 if(prex~=0)normx,normy=prex,prey
				 if(not coly)ent_fall(_ENV) else dx*=.8
				end
				
				line(x-2.5*normx,y+2-2.5*normy,x+2.5*normx,y+2+2.5*normy,13)
			end
		},7,ox,oy)
	end,
		
	
	
	
	
		-- enemy 3
	function(ox,oy,idea) -- behavior
		local dir,ox,oy
		
		return new_obj({
			function(o)
				local ci,oanim,ostate,
				targ,jump,pretarg,
				near_item,item_cool,on_flr
				=
				idea==1,
				oanim_and_ostate(o)
				
				box_init(o,"4,7,3,2","6,7")
				phys_init(o,ent_snap,"e")
				ent_init(o,true)
				
					-- idle,run,attack,die
				anim_init(o,[[
					64,65,66,67,4,1|
					80,81,82,83,84,1,1|
					103,104,105,106,107,108,81,1,0|
					71,86,115,87,88,116,89,0,0
				]])
				
				if(ci)o.dx=1 oanim(2) new_timer(80,function() del_obj(o) end)
				
				
						-- local functions
					-- await using item
				local function do_item_cool()
					item_cool=true
					new_timer(15,function()
						item_cool=false
					end)
				end
				
				local function do_jump()
					if(item_cool)return
					do_item_cool()
					o.dy-=4 oanim()
					o.spri,on_flr=80
				end
				
				local function item_upd()
					if not o.item do
						near_item=near_arr(o,10,targs)
						
						if(near_item and near_item.spear)o.pickup(near_item,_,true) do_item_cool()
						elseif targ and not targ.dead and sgn(targ.x-ox)==dir and dir==(o.flipx and -1or 1)and dist(oy,targ.y)<5do
						o.use()
						do_item_cool()
					end
				end
				
				
				ai_init(o,{
					function()
						oanim(4)
						ostate(2)
						
						add_gore(o,10)
					end
				})
				
				state_init(o,
				
						-- basic
					{function()
						if o.coly do
							if not on_flr do
								on_flr=true oanim(ci and 2or 1)
							elseif o.colx do
								do_jump()
							end
						
						elseif not o_pnt_col(o,dir*4,4)and on_flr do
							do_jump()
						end
						
						if(ci)o.dx+=.3
					end,
					
					
						-- dead
					function()
						-- add stuff here
					end
					}
				)
			end,
			
			function(_ENV)
				ox,oy,dir=x,y,dir
				
				ent_fall(_ENV)
				ent_col()
				upd_state(_ENV)
				dx*=.8
				
				pal(14,0)
				spr_draw(_ENV)
				pal(14,14)
			end
		
		},6,ox,oy)
	end,
	
	
	

	
		-- box 4
	function(ox,oy)
		local loop,use,rope_loop
		
		return new_obj({
			function(_ENV)
				box_init(_ENV,"7.5,6.1,4,2","6,7")
				
				
				phys_init(_ENV,
					function(_,is_x,b)
						if is_x do
							if(stat(46)==5and dx~=0)dx*=.2 play_sfx(5)
							dx*=.1
						else
							if(dy>1.5)if(b and not b.dead and b.kill)b.kill(true) add_gore(b,30) dy*=2 spri=75 impact(_ENV,8,8,true) else impact(_ENV,8,8)
							ent_snap(_ENV)
						end
					end,
				true)
				
				ent_init(_ENV)
				
				item_init(_ENV,{
					function()
						use=user
						if(use.seg or use.y<y-5 or use.y>y+5 or use.dir<0and use.x<x or use.dir>0and use.x>x)use.drop() return
						play_sfx(2)
						use.dx*=.5
						set_global(_ENV)
						
						use.push,loop
						=
						true,new_loop(function()
							dx=lerp(dx,use.x+use.dir*12-x,.2)
							
							if x_rng(_ENV,.2)and not x_rng(_ENV,.9)and not colx do
								imp_prt(use,1,use.dx*7+use.dir*12,4)
								
								if(stat(46)~=5and stat(46)==-1)play_sfx(4)
								elseif stat(50)==31do
									play_sfx()
								end
							
							if(rng(_ENV,use)>20)use.drop(true)play_sfx()
						end)
						
						use.tog_push(true)
					end,
					
					
					_,
					
					
					function()
						use.tog_push()
						use.push=_
						del_loop(loop)
						play_sfx()
					end
				})
				
				spri,box
				=
				15,true
				
				function tog_rope(r,nseg,i)
					if r do
						if(rope_loop)return
						rope_loop,seg
						=
						add(loops,new_spr(o,nseg,0,1)),
						true
					else
						del_loop(rope_loop)
					end
				end
			end,
			
			
			function(_ENV)
				spr_draw(_ENV)
				dx*=.8
				ent_fall(_ENV)
				ent_col(7)
				
				if(not coly and not global)set_global(_ENV)
			end
		
		},5,ox,oy)
	end,
	
	
	
	
	
		-- rope 5
	function(x,y,p)
		local o,s,near,os
		=
			-- color 14 more likely
		wire(x,y,7,'7,14,14',4,2,-p)
		
		o.upd_loop,o.p,o.can_box
		=
		o.new_loop(rope_upd),p,true
		
		new_timer(5,function()
			o.can_box=_
		end)
		
			-- enemies can knock down
		if p==6and not saved_event(2)do -- object needed
			for i=0,6do
				s=o.segs[i+1]
				s.y-=i*5
				s.x+=i*1.5
			end
			
			os=o.je
			os.locked,s
			=
			true,
			o.new_loop(function()
				near=near_arr(o,20,bodies)
				if(near and near.spear)play_sfx(5)o.del_loop(s)os.locked,os.dx,os.dy=false,0,0 save_event(2)
			end)
		end
		
		return o
	end,
	
	
	
		-- glass 6
	function(x,y)
		local ox,oy,i,o
		=
		x/8,y/8,0
		
		local function glass_break(dir,start,new_tile)
			i=start
			while mget(ox+i,oy)==235do
				mset(ox+i,oy,6)
				new_prt(20,5,o,i*8,2)
				i+=dir
			end
			
			mset(ox+i-dir,oy,new_tile)
		end
		
		
		o=new_l_loop(function()
			local ob=near_arr(o,6,bodies)
			
			if ob and ob.box do
				del_obj(o)
				impact(o,6,10) play_sfx(11)
				glass_break(1,0,220)
				glass_break(-1,-1,219)
				ob.dy=0
			end
			if(mget(ox,oy)~=235)del_obj(o)
		end,5,x,y)
		
		box_init(o,"3,0,0,1","6,7,14")
		
		return o
	end,
	
	
	
	 -- light/flies 7
	function(x,y,p)
		local o,r,i,stats
		=
		new_prt(5,3,p and"0,1,5",x,y),10,0,
		deep_split'1.1,.75,.55|5,13,6'
		if(p)return o
		
		local s1,s2=stats[1],stats[2]
		o.new_obj(function()
			i+=rndf'0,.1'
			r=lerp(r,sin(i)*rnd(9)+9,.1)
			for i=1,3do
			
				circfill(x-.5,y-.5,r*s1[i],s2[i])
			end
		end,3)
		
		return o
	end,
	
	
		-- flying dust 8
	function(x,y)
		return new_prt(15,4,_,x,y)
	end,
	
	
		-- guard rail/tripwires 9
	function(x,y,p)
		return new_l_loop(function()
			spr(p,x,y+(p==45 and 3or 2))
		end,5,x,y)
	end,
	
	
		-- hanging body 10
	function(x,y)
		local rope
		return new_obj({
			function(o)
				o.spri=108
				phys_init(o,ent_stop,1)
				function o:tog_rope(r,seg)
					if(rope)return
					rope=new_loop(function()
						o.x,o.y=seg.x-3,seg.y
					end)
				end
			end,
			spr_draw
		},5,x,y)
	end,
	
	
		-- conveyor belt 11
	function(x,y)
		return new_l_loop(function()
			if lever_on do
				if(t()/.1%1>.5)spr(79,x,y,1,1,true)
			end
		end,5)
	end,
	
	
		-- grass 12
	function(x,y)
		local frame,oy,cur_ent=0,0
		
		return new_l_loop(function()
			oy=lerp(oy,0,.2)
			foreach(ents,function(e)
				if dist(e.x,x+4)<7and dist(e.y,y+4)<3do
					if(stat(46)~=2and (x_rng(e,.2)or cur_ent~=e))play_sfx(22)
					e.prey,frame,oy,
					cur_ent,e.grass
					=
					min(e.prey,4),5,lerp(oy,3,.5),
					e,true
					
				elseif cur_ent do
					cur_ent,cur_ent.grass=_
				end
			end)
			
			frame=lerp(frame,
				sin((x-camx)*.03+t()*.5)*3,
			.2)
  	sspr(120,120,8,8,x-frame,y+oy,10+frame,8)
		end,7,x,y)
	end,
	
	
	
		-- lever 13
	function(x,y)
		return new_l_loop(function(o)
			line()
		end,5,x,y)
	end
}





	-- cached ents reload with room
	-- global ents never delete
function new_ent(
	ind,x,y,
	global,no_cache, -- dont del, dont cache
	p -- special property
	)
	
	local e,t
	=
	ents[ind](x,y,p),get_room()
	
	if global do
		e.global=true
	elseif t do
		gen_ind(e,ind,p)
		add(t.objs,e)
		if(no_cache)return
		add(t.cache,e.ind)
	end
	return e
end
-->8
-- rooms
local function set_env(pa,amb,id)
	if(cur_mus~=amb)set_music(1,amb,1000)
	if env~=id do
		if(env_txt)del_obj(env_txt)
		
		env=id
		if(pa)cur_pal,inv_pal=pa,pa==4 draw_pal(pa)
		if(env_fx)del_obj(env_fx)
		
		return true
	end
end

function saved_event(i)
	local s
	if(i)s=dget(save)==i else s=dget(save)~=0
	return s
end
function save_event(val)
	dset(save,val)
end


	-- functions when tile loaded
	-- new_ent can be a new object
	-- (do this if basic)
	-- or entry in ent table
tile_funcs,tiles
=
{
		-- ply 1
	function(x,y,p)
		if(ply)return
		ply=new_ent(1,x+8,y+4,true,_,p)
	end,
		-- spear 2
	function(x,y)
		new_ent(2,x+4,y+8)
	end,
		-- enemy 3
	function(x,y,p)
		if p==1 do
			if(saved_event())return
			mark_room=true
		end
		
		new_ent(3,x+4,y+4,true,_,p)
	end,
		-- box 4
	function(x,y)
		new_ent(4,x+4,y+4)
	end,
		-- rope 5
	function(x,y,p)
		new_ent(5,x+4,y-5,p==6,_,p)
	end,
		-- checkpoint 6
	function(x,y)
			-- 86 no bg, 87 grey bg
		startx,starty=x,y
		dset(0,roomx) dset(1,roomy)
		
		if(not ply)tile_funcs[1](x,y,1)
	end,
		-- glass 7
	function(x,y)
		new_ent(6,x+4,y,_,true)
	end,
		-- saw 8
	function(x,y,p)
		new_ent(7,x+4,y+4,true,_,p)
	end,
	
	
	function() -- empty 9
		set_env(1,-1,0)
	end,
	function(x,y) -- outside 10
		if(set_env(1,63,1))env_fx=star_draw()
		new_ent(8,x,y,_,true)
	end,
	function() -- lush 11
		set_env(2,-1,2)
	end,
	function(x,y) -- light 12
		set_env(_,62,-1)
		new_ent(7,x+4,y+2,_,true)
	end,
	function(x,y) -- furnace 13
		set_env(3,59,4)
		new_ent(8,x,y,_,true)
	end,
	
	
	function(x,y) -- corpse 14
		fake_gore(x,y)
		new_ent(7,x+3,y+8,_,_,1)
	end,
	
	function(x,y) -- grass 15
		new_ent(12,x,y)
	end,
	
	
	function(x,y,p) -- lady 16
		if(saved_event())return
		
		local thresh,rndo,o
		=
		0,1
		
		mark_room=true
		
		o=new_l_loop(function()
			rndo=rndf"1,4"
			if(rndo>thresh)spr(0,x,y)
			if ⬆️ and thresh==0and cur_pal>0do
				thresh=.5
			elseif thresh>0do
				thresh+=.05
				
				if(thresh>2.5)del_obj(o)
			end
		end,6)
		o.new_obj(function()
			if(rndo>thresh)circfill(x+3,y+4,7,1)
		end,1)
	end,
	
	
	function(x,y,p) -- guard rails/tripwires 17
		new_ent(9,x,y,_,_,p)
	end,
	
	function(x,y) -- hanging body 18
		new_ent(10,x,y)
	end,
	
	function(x,y) -- conveyor belt 19
		new_ent(11,x,y)
	end,
	
	function() -- forest 20
		set_env(4,61,5)
	end
},



	-- tile|func|new tile|param
split_arr[[64,1,199|65,1,0|66,6,3|
	92,2,3|
	103,3,3|81,3,0,1|82,3,3,1|
	15,4,3|
	90,5,6,0|93,5,3,6|88,5,3,3|
	235,7|
	
	239,9|251,10|95,11|
	215,12|
	57,13|14,20|
	
	89,14,113|86,6,0|
	243,16,0|
	
	35,17,123,35|127,17,123,127|
	45,17,3,45|
	
	108,18,3|79,19|
	255,15,3
]]



function load_room(x_s,y_s,no_cut)
	local room,cur_tile,item,pcamx,pcamy
	=
	get_room()
	foreach(room.objs, del_obj)
	
	
	roomx,roomy,room.objs,
	room
	=
	x_s/16,y_s/16,{},
	get_room()
	
	
	foreach(room.cache,function(o)
		new_ent(o[1],o[2],o[3],_,_,o[4])
		del(room.cache,o)
	end)
	
	
	save,
	pcamx,pcamy,camx,camy,scx,scy
	=
	10+roomx+roomy*8,
	camx,camy,x_s*8,y_s*8,x_s,y_s
	
	for x=x_s,x_s+15do
		for y=y_s,y_s+15do
			cur_tile=mget(x,y)
			item=tiles[cur_tile]
			if(item)tile_funcs[item[2]](x*8,y*8,item[4]) if(item[3])mset(x,y,item[3])
		end
	end
	
	if mark_room do
		save_event(1)
		mark_room=_
	end
	
	camera(camx,camy)
	if(camx==pcamx and camy==pcamy)return
	
	if(no_cut)return
	local cls_loop=new_l_loop(function()
		cls(inv_pal and 14)
	end,8)
	del_obj(cls_loop)
end
-->8
-- game loop

for i=1,8 do
	add(objs,{})
end

	-- init
palt(0)
palt(15,true)
poke(0x5f36,0x2)

load_room(startx*16,starty*16,true)

menuitem(1,"new game",function()
	memset(0x5e00,0,0xff)
	run()
end)


if false and DEBUG do
	draw_pal(-6)
	
	new_timer(20,function()
		if save==10do -- debug
			fade(1,8)
		else
			draw_pal(cur_pal)
			pal(fades[1])
			quick_fade()
		end
	end)
else
	draw_pal(cur_pal)
end



function _update()
	cls()
	
	⬅️,➡️,⬆️,⬇️,🅾️,❎
	=
	btn(0),btn(1),btn(2),btn(3),btn(4),btn(5)
	
	
	foreach(loops,function(l)
		l()
	end)
	
	
	for a=1,8 do
		foreach(objs[a],function(o) o:upd() end)
		
		if(map_layers[a])map(scx,scy,camx,camy,16,16,map_layers[a][2])
		if(a==2or a==6)foreach(a==2and bg_gore or gore,prt_draw)
	end
	
	for i=1,#del_que do
		l_o=del_que[1]
		del(objs[l_o.l],l_o)
		
		del(ents,
			del(targs,
				del(bodies,l_o)
			)
		)
		
		foreach(l_o.objs,l_o.del_obj)
		foreach(l_o.loops,l_o.del_loop)

		deli(del_que,1)
	end
	
	
	if(inv_pal)for i=1,2do rect(camx-i,camy-i,camx+127+i,camy+127+i,14)end
	for i=1,#logs do
		?logs[i],camx,10*(i-1)+camy,8
	end
end
__gfx__
ffffffffeeeeeeee7666666666666666d5555555111111115555555551111111fffffff1111111111fffffff1ffffffffffffffffffffff1000b0000d7eeee7d
ff0008ffeeeeeeee7766666666666666dd555555111111155555555555111111fffffff1111111111ffffffff11fffffffffffffffffff1f00bb000b6dddddd6
f000008feeeeeeee7777666666666666ddd55555111111155555555555511111ffffff111111111111fffffffff11ffffffffffffff111ff0bbb0b0b7d666dd7
fe0e000feeeeeeeee7777666666666666dd55555111111555555555555111111ffffff1111111111111ffffffffff111ffffffff111fffffbbbb0b0b7677d667
f000000feeeeeeeeee777666666666666ddddd55111555555555555555511111fffff11111111111111fffffffffffff11111111ffffffffbbbb0b0b767d6767
ff00000feeeeeeeeee77777666666666666dd555111155555555555555551111fff11111111111111111ffffffffffffffffffffffffffff0bbb0b0b76d67767
ff000fffeeeeeeeeeee777776666666666dddd55115555555555555555555511f1111111111111111111111fffffffffffffffffffffffff00bb000b7d6666d7
ff0000ffeeeeeeeeeeeee777666666666666ddd5555555555555555555555555111111111111111111111111ffffffffffffffffffffffff000b000067777776
7eeeeeee555d6d5567777766eeeeeee7677777767666666677eeeeee5555555555d67655ffffffff1111111555511111fffff111111fffff666666d66777676d
7eeeeeee55d6765577777777eeeeeee76677777776666666d6777eee5555555555677655ffffffff1111155555555551fff1111111111fff6777776d76777676
eeeeeeee55d6765577777776eeeeee7677777777676666665d7d67ee555d6776677d6d55ffffffff1115555555555511ff111111111111ff7777777677777777
eeeeeeee55567d557eee7777eeeeee7d677eeee766ee66665571167e55d676777666d555ffffffff1155555555555551ff111111111111117777776676777677
eeeeeeee55dd6655eeeeee77eeeeee7d77eeeeee6666ee7755655d7e55d67d666d6d55551f1f1f1f1115555555555551f11111111111111f667777666d777d76
eeeeeeee55d67655eeeeeee7eeeeee7d77eeeeee6666666655d5516755d676dddddd55551111111115555555555555551111111111111111666776766d666d66
eeeeeeee55567655eeeeeee7eeeeee767eeeeeee66666666555555d755d66d5dd55655551f1f1f111555555555555555111111111111111166dd6776d666d66d
eeeeeeee555d6d55eeeeeeeeeeeeeee77eeeeeee666666665555555655dd665d5d65555511f1f1f155555555555555551111111111111111dd66776d5dddddd5
1d666d5167676d6655555555fffdeeff6666666755dd6d55555555550000000011111111ee76510055555ddddddd55d551111111ffffffff111111155d66776d
56777765777676d6555555d5ffd7f5ef6666666755d67655d5d5d5d50000000e11111111e76500005555dddddddddd5551111111ffffffff11111115d6677776
d7eeee7d77777766555d666dfffffd7f6666667655d67d6d6666666d000000ee11111111765100005dddddd66dddddd551111111ffffffff11111115d6677776
67eeee7677767766555551d6fd7fd7ef6666ee6655d6d677d1d1d1d60000eeee515151516510000055ddd6666666dddd15111111fffffffd11111115d6677776
67eeee76677d7666555d5d16fd7d757f77ee6666555dd666d6565616000eeee755555555650000005dd66666666666dd15111111fffffee611111151dd67777d
d7eeeee7666d66665555d1d1fd77fd7f666666665555ddddd16565d600eee7765151515550000000dd666666666666dd11511111dffee66d11111551d6d676d6
56777eee66d666d655dd5655fd7f66ff6666666655555d55d656d65d0eee76655515151510000000dd6666666666666d111551116ee66fff11555151d6677776
15d667eedddddd665dddd56dfd76ffff6666666655555555dd6d666d0ee765515151515500000000d66666666666666d11111555d66fffff551111115d66776d
66777766666666dddd666666d66666666666666d555555555555555555555555d555d555000800005555555d66666666666666666d5110d10d1155d6dddddddd
777777776666666dd66666661ddd666666666dd1115555555555551155555555d55565550088000855555ddd66666dddddd666666d51ddddddd655d6dddddddd
7777777766666666666666665551d666666dd11511115555555551116776777665556555088808085555ddd6666dd555555dd6666d5dd6d11d6665d6666ddddd
e777ee77666666666666666655551d6666d115551115555555511111767767776555d555888808085555dd6666d5d61111dd5d6666ddddd11d66dd66666ddddd
eeeeeeee666666666666666655555d6666d555551111155551111111dd66d66d655d555588880808555ddd6666dd66d11d66dd6666d5dd5555dd5d6666d6dddd
eeeeeeee6666666666666666555551d66d155555111111555511111155dd6dd5d5565555088808085dddd6666d5d66600d6665d6666dd555555dd666dd66dddd
eeeeeeee66666666666666665555551dd15555551111111551111111dd555d5d5d65555500880008ddd666666d51dd6dd6d655d666666dddddd666666666dddd
eeeeeeee66666666666666665555555dd555555511111115511111115d555d555555555500080000dd6666666d51d0d51d1155d666666666666666666666dddd
fff000fffffffffffffffffffff000ff66777777eeeeeeeeffffffffffffffff6666666666666667ffffff0f7eeeeee755511111eeeeeeee00000000d6d6d6d6
ff0000fffff000fffff000ffff0000ff77777777eeeeeeeefffffffffff000ff6666666666666667fff0000fe5ddd25255555111eeeeeeee0000000067676767
ff0e0effff0e0effff0000ffff0000ff77777777eeeeeeeeffff000fff0000ff6d6776d666666677ff0e0e0f2d6265d255555511eeeeeeee0000000067676767
ff0000ffff0000ffff0e0effff0e0effe7e7777eeeeeeeeefff0000fff0000ff66ddd7666666677eff0000ff2672526255555551eeeeeeee00000000d6d6d6d6
ff000fffff0000ffff0000ffff000fffeee7eeeeeeeeeeeefff0000fff0e0eff67d67d766667777eff0000ff1272222255555551eeeeeeee000000006e6e6e6e
ff000fffff000fffff000fffff000fffeeeeeeeeeeeeeeeeff00e0efff0000ff6767d676667777eeff000fff12d2211255555551eeeeeeee00000000eeeeeeee
ff000fffff000fffff000fffff000fffeeeeeeeeee7777eeff00000fff000f0f667d6d666777eeeef0ff0fff1121211155555555eeeeeeee00000000e77ee77e
ff0f0fffff0f0fffff0f0fffff0f0fffeeeeeeee776dd677f0fff0f0ff0ff0ff6d6776d677eeeeeefff0ffff1111111155555555eeeeeeee00000000eeeeeeee
fff000fffff000fffffffffffffffffffff000ff00000000fffffffffffffffffffffffffffffffffff0000fffffffffffffffffffffffff5555555533363333
ff0000ffff0000fffff000fffff000ffff0000ff00000000ffffffffffffffffffffffffffffffffff0e0e0ffff000ffffff000fffff000f5555555533663336
ff0e0effff0000ffff0000ffff0000ffff0e0eff00000000ffff000ffffff00fffffffffffffffffff0000ffff0000fffff0000ffff0000f5555555136663636
ff0000ffff0e0effff0e0effff0e0effff0000ff00000000fff0000fffff0000ffff000fffffffffff0000ffff0e0e0ffff0000ffff0000f5555555166663636
ff000fffff000fffff0000ffff0000ffff0000ff00000000fff0000ffff00000fff00000ffffffffff000fffff00000ffff0e0effff0e0ef5555551166663636
ff000fffff000fffff000fffff000fffff000fff00000000ff00000fff00000fff000000fff0000fff000fffff0000ffff00000fff00000f5555551136663636
ff0000fff0000fffff000fffff000fffff000fff00000000ff00000fff00000fff00000ff0000000ff0ff0ffff000fffff000000ff00000f5555111133663336
f0fffffffffff0ffffff0ffffff0ffffff0fffff00000000f0fff0f0f000f0f0f00000f000000000fffff0ffff0f0fffff0ffffff0fffff05511111133363333
ffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000fffffffffff0000fff0fffff7eeeeeee
ffff000fffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000ff700fffff0e0e0fff0f000f67eeeeee
fff0000fffffffffffffffffffffffffffff0f0fffffffffffffffff0000000000000000000000000000000000000000fe0000ffff0000fffff0e0efd7eeeeee
ff00000fffff000ffffffffff0f0ffffff0000fffffe0efffff0000f0000000000000000000000000000000000000000fe0000ffff0000fffff0000fd7eeeeee
ff00e0effff0000ff0f000ffff000ffff000000fff00000fff00e0ef0000000000000000000000000000000000000000f07007ffff000ffffff0000fd7eeeeee
f0000ff00000000f0f00000ff00000fff000000ff000000fff00000f0000000000000000000000000000000000000000f00eefffff000ffffff000ff67eeeeee
0ff0f0ffff00e0eff000000ff00000fff00000fff0000000ff00000f0000000000000000000000000000000000000000f000ffffff0f0fffffff0f0f7eeeeeee
ffffffffffff0ff0ff00000ff0000fffff000fffff0000fff00f00f000000000000000000000000000000000000000000f0fffffffff0ffffffff0f07eeeeeee
0000000066666666ff1ffff1ffffffffffffffffeeeeeee7d677776d1111111111111111611551555dd1116166666666000000001d1111d155555555ffe7dfff
0000000066226666ff1ffff1ffffffffffffffffeeeeeee7d67776761115d615d611111111111155d66d161166666666000000001d1111d155555555fe5fedff
0000000062222666ff1ffff1fffff00fffffffffeeeeeeeedd66677611115d6ddd6111111111115d66d1d611666666660000000011d111d155555555fedff7df
0000000062222226ff1fff1ffff0000fffffffffeeeeeeeed6777767111155d6666d11111111155d66d11611666666660000000011d1115155555555f77df7df
0000000066222222fff1ff1ffff0000fffff000feeeeeeeed6677d77111555d6d6d61161111115ddd6d11611666666660000000011d1151155555555fe57d7df
0000000062222222fff1ff1fff00000ffff00000eeeeeeeed66dd666111555d66d6611611111555ddd6d1d11666666660000000011511d1155555555f7dff7df
0000000062222226ffff11ffff00000fff000000eeeeeeee5dd66666111155d6d6d611611155ddd66ddd66d166667666000000001115d11155555555ff66f7df
0000000022222222fffffffff00ff0f000000000eeeeeeeed5dddddd16d1155d666d1161155555dd66666ddd66767666000000001111111155555555ffff67df
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10101010101010101010101010101010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
10000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010
00000000000000000000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
0000567eeeeeeeeee76500000000567eeeeeeeeefffffffff15d667eee766d51d55555555555555d55555555555555555555555511111111111111115555dd6d
0000567eeeeeeeeee76500000000567eeeeeeeee1fffffffff15d667eee766d5d55555555555555d555555551555555555555555111111111111111155dd6666
0000567eeeeeeeeee76500000000567eeeeeeeee51fffffffff15d667eee766d5d555555555555d555555555155555555555555111111111111111115dd66666
0000567e77777777e76500000000567e7777777ed51fffffffff15d667eee76655d6555555556655555555551155555555555551f1111111111111f15dd66666
0000567e66666666e76500005555567e6666667e6d51fffffffff15d667eee765555d66dd66d5555555555551555555555555511ff111111111111f15dd66666
0000567e55555555e76500006666667e5555567e66d51fffffffff15d667eee75555555555555555d666d6dd1111555555551111ffff111111111ff15dd66666
0000567e00000000e76500007777777e0000567e766d51fffffffff15d667eee5555555555555555555555551115555555555111fff111111111f11f55dd6666
0000567e00000000e7650000eeeeeeee0000567ee766d51fffffffff15d667ee5555555555555555555555551111115555111111ffffff1111ffffff5555ddd6
0000567e00000000e7650000e7650000eeeeeeeed666666d00000000f15dd51f7eeeeeee55555555d5d66666ed15555555555dddeeeeeee711111111dddd5555
0000567e00000000e7650000e7650000eeeeeeee67e7e7e600000000f7eeee7fd77eeeeed5d555555d6677766e61555555511166eeeeeee7ff1111116666dd55
00005d670000000076d50000e7650000eeeeeeee67e7e7e600000000ff7ee7ff6dd77eeed66d5555dd67777766ee65555555e6eeeeeeee7dffff111166666dd5
000015d6000000006d510000e7650000e7777777d666666d00000000ffffffff6666d7eed1d5d555dd677777ee6dd1555511de6eeeeeee76fff1111166666dd5
000001555555555555100000e7655555e7666666eeeeeeee00000000ffffffff66666d7edd555555d6d777776ed1115555111de7eeeeeee7ffffff1166666dd5
000000016666666610000000e7666666e7655555e777777700000000ffffffff6666667ed1655555d66677767e775555555777e7eeeeeee7fffffff166666dd5
000000007777777700000000e7777777e7650000e766666600000000ffffffff66666667dd565655d6676666d6ddd555511ddd6d7eeee77dfffffff16666dd55
00000000eeeeeeee00000000eeeeeeeee7650000e765555500000000ffffffff66666667d5d5d5ddd66777761111115551111111d77776d5ffffffff6ddd5555
00000000ffff15df000000007eeeeeee66666666ddd555ddd666666666666666eeeeeee11eeeeeeeeeeeeee7dddeeddedd6777765555555511111111000f0000
00000000fff1567d000000007eeeeeee66666666ddddddddd66666666666666deeeeeeeeeeeeeeeeeeeeeee7666ee66ed6d7777dd5d555d51111111f00ff000f
00000000fff15d65000000007eeeeeee6666666666ddddd6d66666666666666deeeeeeeeeeeeeeeeeeeeeee766ee66e6667666d66666666d11111fff0fff0f0f
00000000fff11551000000007eeeeeee666666666666d6d6d6666666666666d57777777ee7777777eeeeee7d77ee77e767777776d1d1d1d61111ffffffff0f0f
00000011ffff111f110000006eeeeeee666666666666d666d6666666666666d56666666776666666eeeee7766ee66e667d777766dd56565611111fffffff0f0f
0000015dffffffffd5100000d7eeeeee66666666666666665d666666666666d55555555665555555eeee7d767ee77e7766dd666dd161556111ffffff0fff0f0f
000015d6ffffffff6d510000d67eeeee666dddd6666666665d666666666666d50000001551000000e777d6e666dd6ddd6666ddd5d6d5d65611ffffff00ff000f
00001d67ffffffff76d100005d67ee766dd1551d66666666d66666666666666d00000001100000007dd77e6611111111dddddd5ddd6d555d1fffffff000f0000
666666661566dd55ddddddddff0008ffff0008ffffffffffeeeeee77dd66776d5555555566666661eeeeeeeeff1222ffd6666666eeeeeee71d665555ffffffff
66d7776655515655666ddd66f000008ff000008fff0008ffeeee77d6d667777655555555666666657eeeeeeef128992fd6666666eeeee7761d515d55ffffffff
6d767676dd66d65566666666fe0e000ff000000ff000008feee7dd66dd67777d6776d555666666d57eeeeeee1289aa921d666666eee7776ddd66d655ffffffff
6d7676761d515d5566666666f000000ffe0e000ffe0e000fee7d6666d6d777d667676d55666666d57eeeeeee1289aa92dd666666ee7667d51d515655ff7fffff
6d7676761d65555566666666ff00000fff00000ff000000fee766666d666666666d67d5566666d1d7eeeeeee128899825dd66666e766d6551d66d655fff7f7ff
6d767676dd555d5566666666ff00000fff00000fff00000fe7d66666d666776ddd667d5566666d16d77eeeee112888215d1d6666e7d61d55dd515d557ffeff7f
66d777661d66d65566666666ff000fffff000ffff0000fffe76666666d6666d655dd6655666dd1566767eeeef112221f5651ddd67d1655551d655555fe7e7fe7
666666661d515d5566666666ff0f0ffff0ff00fff0f000ff766666666666666655d67d55ddd15d656d6d7777ff1111ff556d551dd55d55551d555555eeeeeeee
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000hhhhhhhlllllll5555mmmmmm
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000hhhhhhhlllllll5555mmmmmmm
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000hhhhhhhlllllll55mmmmmmmmm
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000hhhhhhhlllllll55mmmmmmmmmm
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000hh00000hhhhhhhlllllll555mmmmmmmmmm
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000hl5000hhhhhhhhllllll5555mmmmmmmmmmm
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000hl5m0hhhhhhhhlllllll555mmmmmmmmmmmmm
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000h5m6hhhhhhhhllllllll55mmmmmmmmmmmmmm
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000lm67777777777777777777777777mmmmmmmm
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000lm67777777777777777777777777mmmmmmmm
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000l5m6777777777777777777777777mmmmmmmm
00000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000hl5m666666666666666666666667mmmmmmmm
0000000000000000000000hhllllllllllllllllllllllllllllllllllllllllllllllllhh0000000000000000000hllmmmmmmmmmmmmmmmmmmmmmm67mmmmmmmm
000000000000000000000hl5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm5lh0000000000000000000hhlllllllllllllllllllllm67mmmmmmmm
00000000000000000000hl5m666666666666666666666666666666666666666666666666m5lh0000000000000000000000000000000000000000lm67mmmmmmmm
00000000000000000000h5m67777777777777777777777777777777777777777777777776m5h0000000000000000000000000000000000000000lm67mmmmmmmm
000000000000000000000000hhhhhhhlllllll5mlll5755l55llllllllll7lll55mm66m576ml0000000000000000000000000000000000000000lm67mmmmmmmm
00000000000000000000000hhhhhhhllllllll5mm677776m55llllllllll7lll5mm6666m76ml0000000000000000000000000000000000000000lm67mmmmmmmm
00000000000000000000000hhhhhhhllllllll5m6m6776mm55ll6lllllll7lll5mm6666m76ml0000000000000000000000000000000000000000lm67mmmmmmmm
0000000000000000000000hhhhhhhlllllllll55mmmmmmm555llllllllll7lll5mm6666m76ml0000000000000000000000000000000000000000lm67mmmmmmmm
00000000000000hh00000hhhhhhhllllllllll55mmmmmmm555llllllllll7lll55m6666576ml0000000000hhlllllllllllllllllllllllllllllm67mmmmmmmm
0000000000000hl5000hhhhhhhhllllllllllll555mmm5555llllllllll77lll5m5m6mmm76ml000000000hl5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmm67mmmmmmmm
000000000000hl5m0hhhhhhhhlllllllllllllll55555555lllllllllll7llll5mm6666m76ml00000000hl5m66666666666666666666666666666667mmmmmmmm
000000000000h5m6hhhhhhhhlllllllllllllllll555555llllllllllll7llll55mm66m576ml00000000h5m677777777777777777777777777777777mmmmmmmm
000000000000lm67hhhhhhhhlllllllllllll557mmmmmmmm57lllllllll7llll55mm66m576ml00000000lm67hhhhhhhlhhhhhhhlllllll75mmmmmmm7mmmmmmmm
000000000000lm67hhhhhhhhllllllllll555mmmmmmmmmmmmm555llllll7llll5mm6666m76ml00000000lm67hhhhhhhlhhhhhhlllllll575mmmmmmm7mmmmmmmm
000000000000lm67hhhhhhhhhllllllll55mmmmm56777765mmmm55lllll7llll5mm6666m76ml00000000lm67hhhhhhhlhhhhhhlllllll75mmmmmmmm7mmmmmmmm
000000000000lm670hhhhhhhhhllllll55mmmmmm65555556mmmmm55llll7llll5mm6666m76ml00000000lm67hhhhhhhlhhhhhlllllll57mmmmmmmmm7mmmmmmmm
000000000000lm670hhhhhhhhlllllll55mmmmmm65mmm556mmmmm55llll7llll55m6666576mllllllllllm67hhhhhhlhhhhhlllllll575mmmmmmmmmm7mmmmmmm
000000000000lm6700hhhhhhhhhhllll55mmmmmm6m665mm6mmmmm55llll7llll5m5m6mmm76mmmmmmmmmmmm67hhhhllhhhhhllllll5557mmmmmmmmmmm7mmmmmmm
000000000000lm67000h0hhhhhhllllll55mmmmm6m65m6m6mmmm55lllll7llll5mm6666m7666666666666667llllhlhhhlllllll555mmmmmmmmmmmmm7mmmmmmm
000000000000lm67000000hhhhhhhlllll5555mm6m5m66m6mm555llllll7llll55mm66m57777777777777777hhhhhlhhllllllll55mm7mmmmmmmmmm77mmmmmmm
000000000000lm67777777777777777777777777m5mmmm5m77777777m6676m6m5mm6666mllll7llllhhhhhhhhhhhhhhlllllll55ll5mm7m5m6666m6777777777
000000000000lm67777777777777777777777777mm6666mm7777777766676666mmm6666mllll7lllllhhhhhhhhhhhhlllllll555l5mm676m6666666777777777
000000000000l5m6777777777777777777777777777777777777777766676666m66m6665llll7llllllhhhhhhhhhhhlllllll55m5mm666766776667677777777
000000000000hl5m666666666666666666666666666666666666666766676666m666mmmmllll7llllllhhhhhhhhhhlllllll55mm5mm666777677777676666666
0000000000000hllmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm67m6676m6m6m66666mllll7lllllllhhhhhhhhlllllll555mm5mmm6666m6666m6m76mmmmmm
00000000000000hhlllllllllllllllllllllllllllllllllllllm67mmm7m5mm66mm66m5lll77lllllllllhhhhhllllll5555mmm5mmm6666mmmmm5mm76mlllll
0000000000000000000000000000000000000000000000000000lm67mmm75mmmmmmmmm5mlll7lllllllllllhhlllllll555mmmmm5mm6m66mmmm55mmm76ml0000
0000000000000000000000000000000000000000000000000000lm675557555mm5m555mmlll7llllllllllllllllllll55mmmmmm5mm66mmm5555555m76ml0000
0000000000000000000000000000000000000000000000000000lm67hhh7hhhlll55m5lllll7llllllllllllllllll55mmmmmmmm55mm66m5mmmmmmm676ml0000
0000000000000000000000000000000000000000000000000000lm67hhh7hhllll5m6mlllll7lllllllllllllllll555mmmmmmmm5mm6666mmmmmmmm676ml0000
00000000000000000000000000000000000000m0000000000000lm67hhh7hhllll5m6mlllll7lllllllllllllllll55mm5m66m5m5mm6666mmmmmmmm676ml0000
0000000000000000000000000000000000000000600000000000lm67hhh7hlllll5mm5lllll7llllllllllllllll55mmmm6555mm5mm6666mmmmmmm6m76ml0000
00000000000000hhlllllllllllllllllllllllllllllllllllllm67hhh7llllll55mmlllll7lllllllllllllll555mmm656mm6m55m66665mmmmm6mm76ml0000
0000000000000hl5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm67hh7lllllll5m6mlllll7lllllllllllll5555mmmm6m56m6m5m5m6mmmmmm76mmm76ml0000
000000000000hl5m6666666666666666666666666666666666666667hl7lllllll5m6mlllll7llllllllllll555mmmmmmmmm56mm5mm6666m777mmmmm76ml0000
000000000000h5m67777777777777777777777777777777777777777ll7lllllll55m5lllll7llllllllllll55mmmmmmm5m66m5m55mm66m5mmmmmmmm76ml0000
000000000000000000000000hhhhlll7lll5655l55mm66m5llllllllllllllllll5m55lllll7llllll5mmmm5m6666m6mm6666m6mm6666m6mm6666m6m76ml0000
00000000000000000000000hhhhhlll5m677776m5mm6666mllllllllllllllllllm6m5lllll7lllll5mm666m6666666666666666666666666666666676ml0000
00000000000000000000000hhhhhlll5mm6676mm5mm6666m5mm5mm555mm5mm555mm6m5lllll7llll5mm666666666666666666666666666666666666676ml0000
0000000000000000000000hhhhhhlll5mmmmmmmm5mm6666mmm66m66mmm66m66mm66m5llllll7llll5mm666666666666666666666666666666666666676ml0000
000000000000000000000hhhhhhhllll5mmmmmm655m6666555mm5mm555mm5mm55mm55llllll7llll5mmm6666m6666m6mm6666m6mm6666m6mm6666m6m76ml0000
0000000000000000000hhhhhhhhlllll55mmmm555m5m6mmm55555555555555555555lllllll7llll5mmm6666mmmmm5mmmmmmm5mmmmmmm5mmmmmmm5mm76ml0000
00000000000000000hhhhhhhhlllllllll5555ll5mm6666mlllll5lllllll5lllll5lllllll7llll5mm6m66mmmm55mmmmmm55mmmmmm55mmmmmm55mmm76ml0000
0000000000000000hhhhhhhhllllllllllllllll55mm66m5lllll5lllllll5lllllllllllll7llll5mm66mmm5555555m5555555m5555555m5555555m76ml0000
0000000000000000hhhhhhhlllllllllll5mmm655mm6666mlllllllllllllllllllllllllll7ll5555mm66m5mmmmmmmm6mmmmmmm55mm66m5mmmmmmm576ml0000
000000000000000hhhhhhhlllllllllll5mm666mmmm6666mlllllllllllllllllllllllllll7l5555mm6666mmmmmmmmm6mmmmmmm5mm6666mmmmmmm5l76ml0000
000000000000000hhhhhhhllllllllll5mm66666m66m6665lllllllllllllllllllllllllll7l55m5mm6666mmmmmmmmm6mmmmmmm5mm6666mmmm555ll76ml0000
00000000000000hhhhhhhlllllllllll5mm66666m666mmmmlllllllllllllllllllllllllll755mm5mm6666mmmmmmmmmm6mmmmmm5mm6666mmm55llll76ml0000
0000000000000hhhhhhhllllllllllll5mmm66666m66666mlllllllllllllllllllllllllll755mm55m66665mmmmmmmmm6mmmmmm55m66665mm5lllll76ml0000
00000000000hhhhhhhhlllllllllllll5mmm666666mm66m5lllllllllllllllllllllllll5755mmm5m5m6mmmmmmmmmmmmm67mmmm5m5m6mmmm55lllll76ml0000
000000000hhhhhhhhlllllllllllllll5mm6m66mmmmmmm5mllllllllllllllllllllllll557mmmmm5mm6666mmmmmmmmmmmmm66775mm6666m55llllll76ml0000
00000000hhhhhhhhllllllllllllllll5mm66mmmm5m555mmllllllllllllllllllllllll557mmmmm55mm66m5mmmmmmmmmmmmmmmm55mm66m55lllllll76ml0000
00000000hhhhhhhhlllllllllllll5555mmm66m5mmmmmmmm55lllllllllllllllllll55555mmmmmm5mmm66m5mmmmmmmmmmmmmmmm5mmm66m555llllll76ml0000
00000000hhhhhhhhllllllllll555mmm5mm6666mmmmmmmmmmm555lllllllllllll555mmm5mmmmmmm5mm6666mmmmmmmmmmmmmmmmm5mm6666mmm555lll76ml0000
00000000hhhhhhhhhllllllll55mmmmm5mmm66mmmmmmmmmmmmmm55lllllllllll55mmmmmmmmmmmmm5mmm66mmmmmmmmmmmmmmmmmm5mmm66mmmmmm55ll76ml0000
0000000000hhhhhhhhllllll55mmmmmmm5mmmmmmmmmmmmmmmmmmm55lllllllll55mmmmmmmmmmmmmmm5mmmmmmmmmmmmmmmmmmmmmmm5mmmmmmmmmmm55l76ml0000
0000000000hhhhhhhlllllll55mmmmmmmmmmmmmmmmmmmmmmmmmmm55lllllllll55mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm55l76ml0000
0000000707hhhhhhhhhhllll55mmmmmmmmmmmmmmmmmmmmmmmmmmm55lllllllll55mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm55l76ml0000
00000000000h0hhhhhhllllll55mmmmmmmmmmmmmmmmmmmmmmmmm55lllllllllll55mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm55ll76ml0000
00000000000000hhhhhhhlllll5555mmmmmmmmmmmmmmm5mmmm555lllllllllllll5555mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm555lll76ml0000
000000000000lm677777777777777777777777777777577777777777777777777777777777777777777777777777777777777777777777777777777776ml0000
000000000000lm677777777777777777777777777777577777777777777777777777777777777777777777777777777777777777777777777777777776ml0000
000000000000l5m6777777777777777777777777777577777777777777777777777777777777777777777777777777777777777777777777777777776m5l0000
000000000000hl5m66666666666666666666666666656666666666666666666666666666666666666666666666666666666666666666666666666666m5lh0000
0000000000000hllmmmmmmmmmmmmmmmmmmmmmmmmmm5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmllh00000
00000000000000hhllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllhh000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000hhlllllllllllllmllllllllllhh0000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000hl5mmmmmmmmmmmmmmmmmmmmmmmm5lh000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000hl5m666666666666666666666666m5lh00000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000h5m67777777777777777777777776m5h00000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000hhhhhhhlllllll5mlll5l55l55lllllllhhhhhhh0000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000hhhhhhhllllllll5mm677776m55llllllllhhhhhhhh00000000000000
00000000000000000000000000000000000000000000000000000000000000000000000hhhhhhhllllllll57mm67766m55lllllllllhhhhhhhh0000000000000
0000000000000000000000000000000000000000000000000000000000000000000000hhhhhhhlllllllll55mmmmmmmm55lllllllllhhhhhhhh0000000000000
000000000000000000000000000000000000000000000000000000000000000000000hhhhhhhllllllllll55mmmmmm7555llllllllllhhhhhhhh000000000000
0000000000000000000000000000000000000000000000000000000000000000000hhhhhhhhllllllllllll555mmm5555lllllllllllllhhhhhhhh0000000000
00000000000000000000000000000000000000000000000000000000000000000hhhhhhhhlllllllllllllll555555m5lllllllllllllllhhhhhhhh000000000
0000000000000000000000000000000000000000000000000000000000000000hhhhhhhhlllllllllllllllll555555lllllllllllllllllhhhhhhhh00000000
0000000000000000000000000000000000000000000000000000000000000000hhhhhhhllllllllllllllllllllllllllllllllllllllllllhhhhhhh00000000
000000000000000000000000000000000000000000000000000000000000000hhhhhhhllllllllllllllllllllllllllllllllllllllllllllhhhhhhhh000000
000000000000000000000000000000000000000000000000000000000000000hhhhhhhlllllllllllllllllllllllllllllllllllllllllllllhhhhhhhh00000
00000000000000000000000000000000000000000000000000000000000000hhhhhhhllllllllllllllllllllllllllllllllllllllllllllllhhhhhhhh00000
0000000000000000000000000000000000000000000000000000000000000hhhhhhhllllllllllllllllllllllllllllllllllllllllllllllllhhhhhhhh0000
00000000000000000000000000000000000000000000000000000000000hhhhhhhhlllllllllllllllllllllllllllllllllllllllllllllllllllhhhhhhhh00
000000000000000000000000000000000000000000000000000000000hhhhhhhhllllllllllllllllllllllllllllllllllllllllllllllllllllllhhhhhhhh0
00000000000000000000000000000000000000000000000000000000hhhhhhhhllllllllllllllllllllllllllllllllllllllllllllllllllllllllhhhhhhhh
00000000000000000000000000000000000000000000000000000000hhhhhhhhlllllllllllll555mmmmmmmmmmmmmmmmmmmmmmmm55llllllllllllllhhhhhhhh
00000000000000000000000000000000000000000000000000000000hhhhhhhhllllllllll555mmmmmmmmmmmmmmmmmmmmmmmmmmmmm555lllllllllllhhhhhhhh
00000000000000000000000000000000000000000000000000000000hhhhhhhhhllllllll55mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm55llllllllllhhhhhhhh
000000000000000000000000000000000000000000000000000000000hhhhhhhhhllllll5000mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm55llllllllhhhhhhhh0
000000000000000000000000000000000000000000000000000000000hhhhhhhhlllllll0000mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm55llllllllhhhhhh000
0000000000000000000000000000000000000000000000000000000000hhhhhhhhhhllll0000mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm55llllllhhhhhhhhh00
00000000000000000000000000000000000000000000000000000000000h0hhhhhhlllll0000mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm55llllllllhhhhhhh000
00000000000000000000000000000000000000000000000000000000000000hhhhhhhlll000555mmmmmmmmmmmmmmmmmmmmmmmmmmmm555lllllllhhhhhhh00000
000000000000000000000000000000000000000000000000000000000000lm677777777700077777777777777777777777777777777777777777777776ml0000
000000000000000000000000000000000000000000000000000000000000lm677777777777077777777777777777777777777777777777777777777776ml0000
000000000000000000000000000000000000000000000000000000000000l5m6777777777777777777777777777777777777777777777777777777776m5l0000
000000000000000000000000000000000000000000000000000000000000hl5m66666666666666666666666666666666666666666666666666666666m5lh0000
0000000000000000000000000000000000000000000000000000000000000hllmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmllh00000
00000000000000000000000000000000000000000000000000000000000000hhllllllllllllllllllllllllllllllllllllllllllllllllllllllllhh000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
00050a2002020202020202020202000302020303030202020202020202022020022020820202201202122002020202200302200202020220020020020202020200000000030300002012000302040061000000000000000000000000000002000000000000000000000000000000000300200200000202020202028200020282
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000321212121020202020202020202022021212121212121040220200202020220210221020220202003032003202002e002022002000002200202020202020202
__map__
00000000000000000000000000000000000000000000000000000000000000d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6e008053a32d80102761f1f1f1ef136ee7200000000000000de35c8c936093533033433d801c0345ad3d1c3152458d3d1d1d1d1d1d101010101010101010101010101010101
00000000000000000000000000000000000000000000000000000000000000d6e0d1d1d1d1d1d1d1d1d1d1d1d1d1e2d6d6d6e0d1d1d1d1d1d1e2d6d0c1c1c40333fa75443044122ff109000000fb00000000fb00cdcb062828283ae71737da01c006063a230f0303343836ee0072080500000000000000000000000000000001
00000000000000000000000000000000000000000000000000000000000000d6c01a2518381106d72f2fc976ec1bc2d6d6e0080506d7065a2fc2e0d1d1d1c30317e6fadd1601132ffe091919e1001c1d00e100191c05da1f1f1f1f1e18382f6fc00636d4c1c403340636ee00f308053a00000000000000000000000000000001
000000000000000000000000000000000000000000d6d6d6d6d6d6d6d6d6d6d6c0cf0f23df25da1fec2fcf42f2dfc2d6d6c0cdcbcf0fdf062fd3c3082f3a5d031f1f1f1e3a6f13ecfe2809090b0c09090b0c0d091ada2f1f1f1f212f222a2ffac30609d2e0c3340636ee0b0dd0c1c1c101000000000000000000000000000001
000000000000000000000000000000000000000000d6d6d6e0d1d1d1d1d1e2d6c3cbd4c4c8ed2fd926761fd4c4ccd3e2d6d0c1c1c1c1c41fec5a07052f1f1e03e51242f7324d4de7f1cc09ce0b0dde090a0000cd062f2fedd92a032ff232f7483104070a081a0636ee000000e0d1d1d100000000000000000000000000000001
d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6e00b0d0805d7070a720000ded3c3cf23f7f20f7fdfd3c3ee720000e0d1d1d1d1c30511c8ca3a2f482fd444753012244d4de73609090a191c0909091d1c05062ff7f2e50352f748031444c1c435071a0636ee0b0c0c0d08055ad500000000000000000000000000000001
d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6e0d1d1c3000805060606070a000000001ccbd4c1c1c1c4cc1d0000000000000805d72f37371806da1f1f1fecc20101011303faeaf928282828280909282828280606f74944121f143044301001d6d0c4060636ee00ef0027c1c41737d301000000000000000000000000000001
d60000000000000020c500ef000000000000000805d7070acdcbcf42dfccce00000008eee9d2d6d6d6d0e8de0a00000000080506daecc938063a2f322f34c8c201f6fa011524e722ed262626d91b1a22ed26edd93a491045ea1ffa45010101010ad6d0c436ee0000002729e0c31838d501000000000000000000000000000001
d600000020c50000c6c7c5000000000000000805060606070ad4c1c1c1c1d2d6d0c4ee0000e0d1d1d1d1e200de0a000000cdcbcff74223dfcf32f75cf7df06c21303e46f020303f2e5f2e4e4f22b2af2e4f2e5f24910f634113833da6f010101070ad6d0c40000002729e0c35ada1fd301000000000000000000000000000001
d600d600c6c7c50000c6c7c5000000000000cdcbcf0fdfcccec2d6d6d6d6d6d6d6d0d2d6000805d7070a000000de0ae2d6d0c1c1c1c1c1c1c1c1c1c1c1c1c1d2ea34c80175020303341136cbfc030334363533e7e3fde6042537daecfa45450106070ad6d0000b0d29e0c3761fecc9d501000000000000000000000000000001
d600d60000c640c5f300c6d4d2d6d6d6d6d6d0c1c1c1c1c1c1d2d6d6d6d6d6d6d6d6d6d6d0c4cff2df070a000000dec2d6d6d6d6d6d6d6d6d6e0d1d1d1e2d6d6f9c8c94d4d7502e73718282806e6e70628282ae75a2a3231e52bf73b3c032f030406070a7200000072080511c83836c201000000000000000000000000000001
d600d6d6d6d0c1c1d2d6d0d2d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6000000000000d6d6d6d0c1c1c1c1c1c1d2d6d0d2d600000000000000000805d7070a00001f1f1f6f4d4d75312b06da1f1f487b2b1737e6da1f217b1412e7333d3e52f77f42df06070a000000080517180636eed201000000000000000000000000000001
d600000000d6d6d6d6d6d6d6d6d600000000000000000000000000000000000000000000d6d6d6d6d6d6d6d6d6d6d6d6d6000000000000000805060606070a0004112a6f0101ea03e7ed2fd92a1412e7da1f1f1f1e03141013e7c8da21144430c1c4cb06070a0008050625f836ee00d601000000000000000000000000000001
d6d6d6d600d6d6d6d6d6d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000510000cdcbcf03dfccce0031f2141001130f0348e5f7e5326f137bf732032f2f030101010fe5f714100101d6d0c40606070905060606d4c1d2d6d601000000000000000000000000000001
d600000000d6d60000000000d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d6d0c1c1c1c1c1d2d6304410f6d87544441214443044104544443012f7f7036f01130f480f6f010101d6d6c0ebebebebebebebebc2d6d6d6d601000000000000000000000000000001
d600d6d6d6d6d60000000000d600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001011315246f010101010101f63433d80101751214441001754430441001010100d6d0062af2e5f2f22b06d2d6d6d6d601010101010101010101010101010101
d600e0d1d1d1e20000000000d60000000101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000101010000010101010101010101010100000000000000000000000000000000edd9062207090909090909350607ce3901010101010101010101010101010101
d6000805d7070a0000d6d6d6d60000000100000000000000000000000000000101010101010101010101010101010101000000000000000000000000000000000100000000000000000000000000000100000000000000000000000000000000f22b2af2041b28282828090906cc1d0801000000000000000000000000000001
d60805060606070a00d6000000000000010000000000000000000000000000010101010101010101010101010101010100000000000000000000000000005f000100000000000000000000000000000100000000000000000000000000000000441214023104060606cc2c280628282801000000000000000000000000000001
d6cdcbcf03dfccce00d6000000000000010000000000000000000000000000010101010101010101010101010101010100000000000000000000000000000000010000000000000000000000000000010000000000000000000000000000000045eafa7502310406360905060622edd901000000000000000000000000000001
00d0c1c1c1c1c1d2d6d600000000000001000000000000000000000000000001010101010101010101010101014545ea000000000000000000000000000000000100000000000000000000000000000100000000000000000000000000000000380633d875023104070522d92af27bf201000000000000000000000000000001
0000000000000000000000000000000001000000000000000000000000000001010101010101010145010101f6e45df90000000000000000000000000000000001000000000000000000000000000001000000000000000000000000000000002e3517e6d87502e7063ae52b1444304401000000000000000000000000000001
0000000000000000000000000000000001000000000000000000000000000001fa0145010145011358d801ea343836350000000000000000000000000000000001000000000000000000000000000001000000000000000000000000000000002c2e11da1e16dd343a324912fa45ea6f01000000000000000000000000000001
0000000000000000000000000000000001000000000000000000000000000001152458d801246fea152413f93606cd090000000000000000000000000000000001000000000000000000000000000001000000000000000000000000000000001b052576ecf8383a324910fd335815fa01000000000000000000000000000001
000000000000000000000000000000000100000000000000000000000000000103e733036f49f603e4036fcccd0641de0e00000000000000000000000000000001000000000000000000000000000001000000000000000000000000000000002bd906da1e183a324910f63737da1f1f01000000000000000000000000000001
0000000000000000000000000000000001000000000000000000000000000001f903c9e64df634e638e6131b1d060a000000000000000000000000000000000001000000000000000000000000000001000000000000000000000000000000000ff22b2f2f2b334910f63104172f143010000000000000000000000000000001
000000000000000000000000000000000100000000000000000000000000000138e6c8e64de73a34c8e64d2b0706090a09090909090909090909090909090909010000000000000000000000000000010000000000000000004f4f4f4f4f4f4f4f4f032f2f310416fde6f031daec6f0101000000000000000000000000000001
0000000000000000000000000000000001000000000000000000000000000001e5e73a034d3132042a034d31e5040705060606060606060606060606060606060100000000000000000000000000000100000000000000000000000000000000010103762f1f1ee5da214203f7036f0101000000000000000000000000000001
0000000000000000000000000000000001000000000000000000000000000001ffff14440112033103034d030331f2e5e5f2e5f2f2e5e5e5f2e5f2f2f2f2e5f201000000000000000000000000000001000000000000000000000000000000000113595cf748f748f70f14301214100101000000000000000000000000000001
000000000000000000000000000000000100000000000000000000000000000101010101017512ffff140112ffffffffffffffffffffffffffffffffffffffff0100000000000000000000000000000100000000000000000000000000000000017530443044121430126f010101450101000000000000000000000000000001
0000000000000000000000000000000001000000000000000000000000000001010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000001000000000000000000000000000000000145dd16010101454545010101fd33d801000000000000000000000000000001
000000000000000000000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000131ef8da6f01f6343833d801131f1e2401010101010101010101010101010101
__sfx__
a5030000016140a6311064112641126310f6210b6210662105621046210563106631086410c6511265113641106310f6210c611086110261500605016210d63117641136310e6310862104621016110061500601
980700002b67318475114631f6430743316615005053f673356712d661256611e653194430f631076210060108601046030460301605006030060000000000000000000000000000000000000000000000000000
9c0800000317301533000040677300065001030043402150021450260000614006210162102631036310263102621016210161500103006140162104621096311463108631046210162100615000000000000000
944000200763006631056310563106631086310a6310e631146311a6311f6311e631166310c631066310464105641086411264116641146410c6410764105641056410764110641186311a631176310c63107631
943200200075200751007510075100741007410074100751007410074200741007410075100751007510075100761007620076100761007610076100762007510075100751007420074200741007520075200751
a40a11203f675386712d67128675226653e065176753e0553e035086213e01502611006113e0151963317623116130c6140c6210c6310c6410c6410c6510c6510c6510c6510c6510b6410b6410b6310b6210b625
9c080000066113f64121621166210b611026150a00329673196430b623006030116500051006040060100605001030b1431362409621046210261100611006150010306173050550560007074050650900003065
04200000006140161101611026210362104631066310a64113651266613a671266000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
945a0020006073f516006140162102621016210061100615006073f5163f00700614016110261102611016110061101611036210462104621026210061100615006073f516006140162102621016210061100615
929600200650600000007733f6143f6113f6153f6050013400017001042f605007733f6243f6213f6113f6113f6153f60000154001530550603000000000000007105007733f6143f6113f6113f6153f60001003
924b002000650006510065100651006510166103661066610a6610c6610f6610f6610c66109661076610365102651006410064100641016410265102651036610366104661046610366102661016510065100650
543c000007164071620716207162071620716208164081640a1640a1620a1620a1620816108162081620816207161071620716207162071620716207164071640516405162051620516203161031620316203165
553c00000016400162001620016200162001620016400164001640016200162001620016200162001640016400164001620016200162001620016200164001640016400162001620016200162001620016400164
c41e00200016500165001650016500165001650016500165001650016500165001650016500165001650016501165011650116501165011650116501165011650116501165011650116501165011650116501165
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c42300000070500700007000070000705007050070000700007000070000700007000070000700007000070000700007000070000000000000000000000000000000000000000000000000000000000000000000
__music__
01 0a094a45
00 0b0d4346
02 0c094445
02 41424446
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 414a090a
04 41424307
03 41424308
03 41424304
03 41424303


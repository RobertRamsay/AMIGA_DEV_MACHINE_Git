//draw_set_alpha(fade)

if fade!=0
	{
	draw_sprite_ext(spr_MainLogo,0,x,y,1,1,0,c_white,fade);
	draw_sprite_ext(spr_MainLogo,1,x,y,1,1,0,c_white,flash);
	}

flash+=flashrate
if flash>=1.6 flashrate=-0.1
if flash<0  flash=0;

if fadeTimer>timeToFade
	{
	if fade>0 fade-=fadespeed;
	}
if flash==0 and flashrate<0 fadeTimer++

if fade<0 
{
fade=0;

}
	
	draw_sprite_ext(spr_ADM_SmallLogo,0,1550,-2,.6,.6,0,c_white,1-fade);
	draw_set_alpha(1-fade);
	draw_text(1625,22,"VERSION: "+string(GM_version));
	draw_text(1625,38,"POLYTRICITY (C)2026");
	
	draw_set_alpha(1);
	

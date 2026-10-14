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

// The small logo, copyright, version and FPS now sit in the footer of the
// compiled program preview (obj_amiga_manager Draw), fading in with 1 - fade;
// in the toolbar they overlapped the TOUR and machine buttons.

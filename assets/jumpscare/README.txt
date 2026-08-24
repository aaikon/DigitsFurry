Drop-in jumpscare assets
========================

The random jumpscare system (autoload/Jumpscare.gd) looks for a frame
sequence here and a scream sound in the sfx folder. Neither is
included in the repo -- add your own and it activates automatically.
If they're missing, the feature just stays off (a warning prints to
the console, nothing breaks).

1. assets/jumpscare/frames/frame_0001.png, frame_0002.png, ...
   A chroma-keyed (real alpha, no green box) PNG frame sequence,
   played back as an AnimatedSprite2D -- this is how transparency
   works, since Godot's video formats don't support an alpha channel.

   Extract + key your clip with ffmpeg's chromakey filter (adjust the
   color to match your source, and the two numbers -- similarity,
   blend -- to taste; higher similarity keys out more of the
   background, higher blend softens the edge):

	 ffmpeg -i your_clip.webm -vf "chromakey=0x00FF00:0.10:0.03,format=rgba" \
	   assets/jumpscare/frames/frame_%04d.png

   Frame filenames just need to sort correctly (zero-padded numbers
   work) -- the count doesn't matter, Jumpscare.gd picks up however
   many are there. FRAME_FPS at the top of that script controls
   playback speed; match it to your source clip's framerate.

2. assets/audio/sfx/jumpscare_scream.ogg
   The scare sound, played at the same time as the animation.
   Optional -- the animation still plays silently if this is missing.

Tuning: MIN_INTERVAL / MAX_INTERVAL at the top of autoload/Jumpscare.gd
control how often it can fire (currently set to 1s/1s for testing --
dial this back up, e.g. 45-120s, once you're happy with how it looks).

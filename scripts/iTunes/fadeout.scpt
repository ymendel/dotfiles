JsOsaDAS1.001.00bplist00�Vscript_iTunes = Application("iTunes")

if (iTunes.playerState() == "playing")
{
  var origVolume = iTunes.soundVolume()
  
  for (var volume = origVolume; volume > 0; volume -= 5)
  {
    iTunes.soundVolume = volume
	delay(0.05)
  }
  
  iTunes.pause()
  iTunes.soundVolume = origVolume
}                              / jscr  ��ޭ
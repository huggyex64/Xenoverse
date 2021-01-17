#require 'net/http'

#uri = URI('https://www.weedleteam.com/request.php')
#res = Net::HTTP.post_form(uri, 'type' => 'getGifts', 'code' => 'lMvKh4HwLJeeRltm0r4jaPlac3lciIR1')
#font = Font.new
#font.name = "Barlow Condensed"

# Use system to spawn new exes, exec will replace main process
#a = Thread.new{system("Game.exe")}
require 'Data/Scripts/004_Win32API.rb'
require 'Data/Scripts/006_DebugConsole.rb'
Graphics.frame_rate = 60
Console.setup_console
b = Bitmap.new(512*14, 200)
b.font.name = "Barlow Condensed"
b.font.size = 30
b.font.color = Color.new(255,255,255)
#defined?(Shader).to_s
#Font.instance_methods[0].to_s
fs = ""
for v in Font.methods
    fs+=v+", "
end
b.draw_text(b.rect, "Method defined: " + fs, 1)
s = Sprite.new
s.bitmap = b
loop { Graphics.update; Input.update 
    if (Input.press?(Input::RIGHT))
        s.x-=3
    end
    if (Input.press?(Input::LEFT))
        s.x+=3
    end
}
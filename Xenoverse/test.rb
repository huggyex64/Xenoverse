require 'net/http'

uri = URI('https://www.weedleteam.com/request.php')
res = Net::HTTP.post_form(uri, 'type' => 'getGifts', 'code' => 'lMvKh4HwLJeeRltm0r4jaPlac3lciIR1')
b = Bitmap.new(200, 100)
b.font.name = "Kimberley"
b.draw_text(b.rect, "Hello World", 1)
s = Sprite.new
s.bitmap = b
loop { Graphics.update; Input.update }
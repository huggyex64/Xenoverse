b = Bitmap.new(200, 100)
b.font.name = "Kimberley"
b.draw_text(b.rect, "Hello World", 1)
s = Sprite.new
s.bitmap = b
loop { Graphics.update; Input.update }
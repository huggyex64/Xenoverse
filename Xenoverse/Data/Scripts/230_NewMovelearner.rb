class MoveRelearnerScene
  VISIBLEMOVES = 4
	
	def fadeOut(s)
		if s
			for cmd in s.values
				cmd.fade(0,15) if defined?(cmd.fade)
			end
			15.times do
				for cmd in s.values
					cmd.update
				end
				Graphics.update
			end
		end
	end
	
  def pbDisplay(msg,brief=false)
    UIHelper.pbDisplay(@sprites["msgwindow"],msg,brief) { pbUpdate }
  end

  def pbConfirm(msg)
    @viewport3 = Viewport.new(0,0,512,384)
		@viewport3.z = @viewport2.z+1
		@s={}
		path = "Graphics/Pictures/BagNew/"
		anchor = 496
		
		@s["box"] = EAMSprite.new(@viewport3)
		@s["box"].z = 100
		@s["box"].bitmap = pbBitmap(path + "SelectBox").clone
		@s["box"].bitmap.font = SUMMARYITEMFONT
		@s["box"].bitmap.font.size = 24
		
		drawTextExH(@s["box"].bitmap,45,314,434,2,msg,Color.new(24,24,24),Color.new(24,24,24,0),22)
		@s["box"].opacity = 0
		b = pbBitmap(path + "scoption")
		bmp = Bitmap.new(88,38)
		bmp.blt(0,0,b,Rect.new(0,0,22,38))
		bmp.blt(22,0,b,Rect.new(22,0,44,38))
		bmp.blt(88-22,0,b,Rect.new(148-22,0,22,38))
		bmp.font = SUMMARYITEMFONT
		bmp.font.size = 26
		@s["yes"] = EAMSprite.new(@viewport3)
		@s["yes"].bitmap = bmp.clone
		@s["yes"].ox = @s["yes"].bitmap.width
		@s["yes"].x = anchor
		@s["yes"].y = 266-40
		@s["yes"].z = 102
		@s["yes"].opacity = 0
		@s["no"] = EAMSprite.new(@viewport3)
		@s["no"].bitmap = bmp.clone
		@s["no"].ox = @s["no"].bitmap.width
		@s["no"].x = anchor
		@s["no"].y = 266
		@s["no"].z = 102
		@s["no"].opacity = 0
		
		
		
		pbDrawTextPositions(@s["yes"].bitmap,[[_INTL("Yes"),44,5,2,Color.new(24,24,24)]])
		pbDrawTextPositions(@s["no"].bitmap,[[_INTL("No"),44,5,2,Color.new(24,24,24)]])
		id = true
		
		@s["box"].fade(255,10)
		@s["yes"].fade(255,10)
		@s["no"].fade(175,10)
		
		loop do
			Graphics.update
			Input.update
			pbUpdate
			@s.values.each{|s| s.update}
			@s["yes"].move(anchor,226,7,:ease_out_cubic) if @s["yes"].y<=216
			@s["no"].move(anchor,266,7,:ease_out_cubic) if @s["no"].y<=256
			if Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
				id = !id
				if id==true
					@s["yes"].fade(255,10)
					@s["no"].fade(175,10)
					@s["yes"].move(anchor,216,3,:ease_out_cubic)
				else
					@s["yes"].fade(175,10)
					@s["no"].fade(255,10)
					@s["no"].move(anchor,256,3,:ease_out_cubic)
				end
			end
			
			if Input.trigger?(Input::C)
				fadeOut(@s)
				pbDisposeSpriteHash(@s)
				return id
			end
			
			if Input.trigger?(Input::B)
				fadeOut(@s)
				pbDisposeSpriteHash(@s)
				return false
			end
		end
  end

# Update the scene here, this is called once each frame
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
		pbUpdateSpriteHash(@moves)
		if @sprites["abg"]
			@sprites["abg"].ox+=1
			@sprites["abg"].oy-=1
		end
  end
	
	def evaluateIcon(pokemon)
		bitmap = Bitmap.new(75,74)
		bmp =""
		bmp += "Graphics/Pictures/DexNew/Icon/#{pokemon.species}"
		if pokemon.gender==1 && pbResolveBitmap(bmp+"f")
			bmp+="f"
		end
		if pokemon.form>0
			if pokemon.isDelta?
				bmp+="d"
			else
				bmp+="_#{pokemon.form}"
			end
		end
		bitmap = pbBitmap(bmp).clone
		return bitmap
	end
	
  def pbStartScene(pokemon,moves)
    @pokemon=pokemon
    @pastmoves=moves
    moveCommands=[]
    moves.each{|i| moveCommands.push(PBMoves.getName(i)) }
    # Create sprite hash
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
		@path = "Graphics/Pictures/Movelearner/"
    @sprites={}
    #addBackgroundPlane(@sprites,"bg","reminderbg",@viewport)
		@sprites["bg"] = EAMSprite.new(@viewport)
		@sprites["bg"].bitmap = pbBitmap(@path + "bg")
		
		#typebmp = pbBitmap("Graphics/Pictures/types2"+(pbGetLanguage() == 4 ? "_ita" : "_eng"))
		
		@sprites["abg"]=AnimatedPlane.new(@viewport)
		@sprites["abg"].bitmap = pbBitmap(@path + "animbg")
		@sprites["abg"].opacity = 125
		
		@sprites["ui"]=EAMSprite.new(@viewport)
		@sprites["ui"].bitmap = pbBitmap(@path + "ui")
		 
		@sprites["arrows"] = EAMSprite.new(@viewport)
		@sprites["arrows"].bitmap = pbBitmap(@path + "arrows") 
		
    @sprites["pokeicon"]=EAMSprite.new(@viewport)#PokemonIconSprite.new(@pokemon,@viewport)
		@sprites["pokeicon"].bitmap = evaluateIcon(pokemon)
		@sprites["pokeicon"].ox = @sprites["pokeicon"].bitmap.width/2
		@sprites["pokeicon"].oy = @sprites["pokeicon"].bitmap.height/2
    @sprites["pokeicon"].x=333
    @sprites["pokeicon"].y=102
		
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["overlay"].bitmap.font = Font.new
		@sprites["overlay"].bitmap.font.name = "Barlow Condensed"
		@sprites["overlay"].bitmap.font.size = 22
		
		##drawing the types
		#@sprites["overlay"].bitmap.blt(370,110,typebmp,Rect.new(0,((22)*pokemon.type1),typebmp.width,22))
		#if pokemon.type1 != pokemon.type2
		#	@sprites["overlay"].bitmap.blt(370+84,110,typebmp,Rect.new(0,((22)*pokemon.type2),typebmp.width,22))
		#end
		textpos = []
		#header
		textpos.push([_INTL("Teach which move to {1}?",pokemon.name),256,10,2,Color.new(248,248,248)])
		#pokemon info
		textpos.push([_INTL("{1}",pokemon.name),368,72,0,Color.new(48,48,48)])
		textpos.push([sprintf("%3d/%3d",pokemon.hp,pokemon.totalhp),368,96,0,Color.new(48,48,48)])
		textpos.push([sprintf("Lv.%3d",pokemon.level),438,96,0,Color.new(48,48,48)])
		pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
		
		@sprites["overlay"].bitmap.font.size = 24
		textpos=[]
		textpos.push([_INTL("Category"),333,154,2,Color.new(248,248,248)])
		textpos.push([_INTL("Power"),333,179,2,Color.new(248,248,248)])
		textpos.push([_INTL("Accuracy"),333,204,2,Color.new(248,248,248)])
		pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
		
		textpos=[]
		#close button
		textpos.push([_INTL("Close"),476,354,1,Color.new(248,248,248)])
		@sprites["overlay"].bitmap.font.bold = true
		
		pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
    @sprites["moveoverlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["moveoverlay"].bitmap.font = SUMMARYITEMFONT
		@sprites["moveoverlay"].bitmap.font.size = 24
    pbDrawMoveList
		
		drawMoveInfo(0)
    pbDeactivateWindows(@sprites)
    # Fade in all sprites
    pbFadeInAndShow(@sprites) { pbUpdate }
  end
	
	def drawMoveInfo(index)
		@sprites["moveoverlay"].bitmap.clear
		moveid = @pastmoves[index]
		movedata=PBMoveData.new(moveid)
    basedamage=movedata.basedamage
    type=movedata.type
    category=movedata.category
    accuracy=movedata.accuracy
		move=moveid
		textpos=[]
		#values
		@sprites["moveoverlay"].bitmap.blt(376,(category==0? 154 : 156),pbBitmap("Graphics/Pictures/SummaryNew/cat#{category}"),Rect.new(0,0,27,23))
		textpos.push([(basedamage<=1 ?(basedamage==1 ? "???" : "---" ): sprintf("%d",basedamage)),378,179,0,Color.new(48,48,48)])
		textpos.push([accuracy==0 ? "---" : sprintf("%d",accuracy)+"%",378,204,0,Color.new(48,48,48)])
		@sprites["moveoverlay"].bitmap.font.size = 24
		pbDrawTextPositions(@sprites["moveoverlay"].bitmap,textpos)
		
		movedesc = pbGetMessage(MessageTypes::MoveDescriptions,moveid)
		@sprites["moveoverlay"].bitmap.font.size = 20
		drawTextExH(@sprites["moveoverlay"].bitmap,301,230,192,4,movedesc,Color.new(48,48,48),Color.new(48,48,48,0),18)
	end
	
  def pbDrawMoveList
		@viewport2=Viewport.new(24,60,238,266)
    @viewport2.z=99999
		bmp = pbBitmap("Graphics/Pictures/EBS/Xenoverse/casellemosse_rs")
		@moves={}
		
		for i in @pastmoves
			md = PBMoveData.new(i)
			if md
				@moves["m#{i}"]=EAMSprite.new(@viewport2)
				@moves["m#{i}"].bitmap = Bitmap.new(232,25)
				@moves["m#{i}"].bitmap.blt(0,0,bmp,Rect.new(0,md.type*25,232,25))
				@moves["m#{i}"].bitmap.font.name = $MKXP ? "Kimberley" : "Kimberley Bl"
				@moves["m#{i}"].bitmap.font.size = 18
				dark = getDarkerColor(@moves["m#{i}"].bitmap.get_pixel(50,13),0.35)
				pbDrawTextPositions(@moves["m#{i}"].bitmap,[[PBMoves.getName(i),35,3,0,Color.new(248,248,248),dark,true]]) #outlined
				@moves["m#{i}"].y=28*@pastmoves.index(i)
			end
		end
  end
	
	def setSelectedMove(index)
		for m in @moves.keys
			if m=="m#{@pastmoves[index]}"
				@moves[m].move(0,@moves[m].y,4,:ease_out_cubic)
				@moves[m].fade(255,8,:ease_out_cubic)
			else
				@moves[m].move(6,@moves[m].y,4,:ease_out_cubic)
				@moves[m].fade(155,8,:ease_out_cubic)
			end
		end
	end
	
	def scrollMoves(index)
		if @moves["m#{@pastmoves[index]}"].y>240
			for m in @pastmoves
				ypos = 28*@pastmoves.index(m)-(28*(index-8))
				echoln ypos
				
				if m==@pastmoves[index]
					@moves["m#{m}"].move(0,ypos,4,:ease_out_cubic)
				else
					@moves["m#{m}"].move(6,ypos,4,:ease_out_cubic)
				end
					
			end
		elsif @moves["m#{@pastmoves[index]}"].y<0
			for m in @pastmoves
				ypos = 28*@pastmoves.index(m)-(28*(index))
				echoln ypos
				if m==@pastmoves[index]
					@moves["m#{m}"].move(0,ypos,4,:ease_out_cubic)
				else
					@moves["m#{m}"].move(6,ypos,4,:ease_out_cubic)
				end
			end
		end
	end
	
# Processes the scene
  def pbChooseMove
		index=0
		setSelectedMove(index)
		drawMoveInfo(index)
		maxIndex = @moves.length-1
		loop do 
			Graphics.update
			Input.update
			pbUpdate
			scrollMoves(index)
			if index==0
				@sprites["arrows"].src_rect=Rect.new(0,192,512,192)  #only lower arrow
				@sprites["arrows"].y = 192
			elsif index==maxIndex
				@sprites["arrows"].src_rect=Rect.new(0,0,512,192)  #only upper arrow
				@sprites["arrows"].y = 0
			else
				@sprites["arrows"].src_rect=Rect.new(0,0,512,384)  #both arrows
				@sprites["arrows"].y = 0
			end
			
			if Input.trigger?(Input::DOWN)
				index = index+1>maxIndex ? index : index+1
				setSelectedMove(index)
				drawMoveInfo(index)
			end
			if Input.trigger?(Input::UP)
				index = index-1<0 ? index : index-1
				setSelectedMove(index)
				drawMoveInfo(index)
			end
			
			if Input.trigger?(Input::C) 
				return @pastmoves[index]
			end
			if Input.trigger?(Input::B)
				return 0
			end
		end
    #~ oldcmd=-1
    #~ pbActivateWindow(@sprites,"commands"){
       #~ loop do
         #~ oldcmd=@sprites["commands"].index
         #~ Graphics.update
         #~ Input.update
         #~ pbUpdate
         #~ if @sprites["commands"].index!=oldcmd
           #~ @sprites["background"].x=0
           #~ @sprites["background"].y=78+(@sprites["commands"].index-@sprites["commands"].top_item)*64
           #~ pbDrawMoveList
         #~ end
         #~ if Input.trigger?(Input::B)
           #~ return 0
         #~ end
         #~ if Input.trigger?(Input::C)
           #~ return @moves[@sprites["commands"].index]
         #~ end
       #~ end
    #~ }
  end

# End the scene here
  def pbEndScene
		merged = @sprites.merge(@moves)
    pbFadeOutAndHide(merged) { pbUpdate } # Fade out all sprites
    pbDisposeSpriteHash(merged) # Dispose all sprites
    @viewport.dispose # Dispose the viewport
		@viewport2.dispose # Dispose the viewport
  end
end
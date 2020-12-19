class PokeSelectionPlaceholderSprite < SpriteWrapper
  attr_accessor :text

  def initialize(pokemon,index,viewport=nil)
    super(viewport)
    xvalues=[0,231,0,231,0,231]
    yvalues=[20,26,116,122,212,218]
    self.bitmap=Bitmap.new(1,1)#@pbitmap.bitmap
    self.x=xvalues[index]
    self.y=yvalues[index]
    @text=nil
  end

  def update
    super
    self.bitmap=Bitmap.new(1,1)
  end

  def selected
    return false
  end

  def selected=(value)
  end

  def preselected
    return false
  end

  def preselected=(value)
  end

  def switching
    return false
  end

  def switching=(value)
  end

  def refresh
  end

  def dispose
    super
  end
end


class PokeSelectionSprite < SpriteWrapper
	include EAM_Sprite
	
	attr_reader :selected
	attr_reader :preselected
	attr_reader :switching
	attr_reader :pokemon
	attr_reader :active
	attr_accessor :text
	
	def initialize(pokemon,index,selcursor,viewport=nil)
		super(viewport)
		@index=index
		@pokemon=pokemon
		active=(index==0)
		@active=active
		@cursor = selcursor
		
		#created to avoid dirtying the bitmap with text
		@overlay = EAMSprite.new(viewport)
		@overlay.bitmap = Bitmap.new(147,147)
		
		
		
		@dir=["Graphics/Pictures/Party/",
			"Graphics/Pictures/Party/dx",
			"Graphics/Pictures/Party/sx",]
		@path = "Graphics/Pictures/PartyNew/"
		@healthbar=EAMSprite.new(viewport)
		@healthbar.bitmap = pbBitmap(@path+"healthbar")#PartyPanel.new(@path+"healthbar")
		
		@item = EAMSprite.new(viewport)
		@item.bitmap = pbBitmap(@path+"item_icon")
		
		@spriteXOffset=10
		@spriteYOffset=-14
		@pokeballXOffset=10
		@pokeballYOffset=0
		@pokenameX=10                        #RIGHT ALIGNED
		@pokenameY=85
		@levelX=14
		@levelY=111
		@statusX=80
		@statusY=55
		@genderX=224
		@genderY=32
		@hpX=106                             #CENTER ALIGNED
		@hpY=126
		@hpbarX=136
		@hpbarY=38
		@gaugeX=128
		@gaugeY=52
		@itemXOffset=62
		@itemYOffset=38
		@annotX=30
		@annotY=126
		
		xvalues=[23,182,341,23,182,341]
		yvalues=[19,19,19,181,181,181]
		@text=nil
		@statuses=AnimatedBitmap.new(_INTL("Graphics/Pictures/statuses"))
		@hpbar=AnimatedBitmap.new("Graphics/Pictures/partyHP")
		@hpbarfnt=AnimatedBitmap.new("Graphics/Pictures/partyHPfnt")
		@hpbarswap=AnimatedBitmap.new("Graphics/Pictures/partyHPswap")
		@pokeballsprite=ChangelingSprite.new(0,0,viewport)
		@pokeballsprite.addBitmap("pokeballdesel","Graphics/Pictures/partyBall")
		@pokeballsprite.addBitmap("pokeballsel","Graphics/Pictures/partyBallSel")
		@pkmnsprite=Sprite.new(@viewport)#PokemonIconSprite.new(pokemon,viewport)
		
		
		@spriteX=xvalues[index]
		@spriteY=yvalues[index]
		@refreshBitmap=true
		@refreshing=false 
		@preselected=false
		@switching=false
		@pkmnsprite.z=self.z+2 # For compatibility with RGSS2
		#@itemsprite.z=self.z+3 # For compatibility with RGSS2
		@pokeballsprite.z=self.z+1 # For compatibility with RGSS2
		@slotbg = pbBitmap(@path+"SlotBg")
		self.selected=false
		
		@blank = EAMSprite.new(viewport)
		@blank.zoom_x = 0
		@blank.bitmap = pbBitmap("Graphics/Pictures/PartyNew/Blank")
		@blank.ox = @blank.bitmap.width/2
		
		@blackScreen=EAMSprite.new(viewport)
		@blackScreen.bitmap = Bitmap.new(512,384)
		@blackScreen.bitmap.fill_rect(0,0,512,384,Color.new(0,0,0))
		@blackScreen.opacity = 0
		@blackScreen.z = 20
		
		@fcIcon = EAMSprite.new(viewport)
		@fcIcon.zoom_x = 0
		@fcIcon.zoom_y = 0
		@fcIcon.ox = 54
		@fcIcon.oy = 47
		@fcIcon.opacity = 0
		@fcIcon.z = 21
		
		
		
		self.ox = @slotbg.width/2
		self.x=@spriteX+self.ox
		self.y=@spriteY
		@blank.x = self.x
		@blank.y = self.y
		@fcIcon.x = self.x
		@fcIcon.y = @slotbg.height/2 + self.y
		@fcIcon.setZoomPoint(@fcIcon.ox,@fcIcon.oy)
		
		@overlay.x = self.x - self.ox
		@overlay.y = self.y
		@healthbar.x = self.x + 56 - self.ox
		
		@healthbar.y = self.y + 115
		@item.x = self.x + 120 - self.ox
		
		@item.y = self.y - 4
		#Console::setup_console if $DEBUG
		echoln "#{@item.x} #{self.x}"
		echoln "#{@item.y} #{self.y}"
		@item.z = 12
		
		drawText	
		
		refresh
	end
	
	def changeForm(form = 1)
		@fcIcon.bitmap = pbBitmap("Graphics/Pictures/PartyNew/tform") if form == 1
		@fcIcon.bitmap = pbBitmap("Graphics/Pictures/PartyNew/xform") if form == 2
		@fcIcon.bitmap = Bitmap.new(1,1) if pokemon.form == 0
		hideInfo
    pbSEPlay("party1",100)
		zoom(0,1,10)
		10.times do
			update
			Graphics.update
		end
		@blank.zoom(1,1,10)
		10.times do
			@blank.update
			Graphics.update
		end
		@fcIcon.zoom(1,1,40,:ease_in_cubic)
		@fcIcon.fade(255,10)
    pbSEPlay("party2",100)
		i = 0
		30.times do
			@blackScreen.fade(175,5) if i == 25
			@blackScreen.update
			@fcIcon.update
			Graphics.update
			i+=1
		end
		@fcIcon.zoom(1.4,1.4,4)
		4.times do
			@fcIcon.update
			Graphics.update
		end
		@fcIcon.zoom(1,1,10)
		10.times do
			@fcIcon.update
			Graphics.update
		end
		@blackScreen.fade(0,4)
		4.times do
			@blackScreen.update
			Graphics.update
		end
	end
	
	def restoreSlot
		@fcIcon.zoom(0,1,10)
    pbSEPlay("party1",100)
		@blank.zoom(0,1,10)
		10.times do
			@fcIcon.update
			@blank.update
			Graphics.update
		end
		self.bitmap.clear
		#self.bitmap.zoom_x = oldzx if self.bitmap.zoom_x != oldzx
		self.bitmap.blt(0,0,@slotbg,Rect.new(0,0,@slotbg.width,@slotbg.height))
		evaluateIconPath
		self.bitmap.blt(53,113,pbBitmap(@path+"healthbar_bg"),Rect.new(0,0,86,11))
		self.bitmap.blt(33,10,pbBitmap(@iconpath),Rect.new(0,0,75,74))
		zoom(1,1,10)
		@fcIcon.zoom_y = 0
		10.times do
			update
			Graphics.update
		end
		begin
			yield if block_given?
		ensure
			showInfo
		end
	end
	
	
	def hideInfo
		@overlay.fade(0,10)
		@healthbar.fade(0,10)
		@item.fade(0,10)
		10.times do			
			@overlay.update
			@healthbar.update
			@item.update
			Graphics.update
		end
	end
	
	def showInfo
		@overlay.fade(255,10)
		@healthbar.fade(255,10)
		@item.fade(255,10)
		10.times do			
			@overlay.update
			@healthbar.update
			@item.update
			Graphics.update
		end
	end
	
	def evaluateIconPath
    if @pokemon.isEgg?
			@iconpath = "Graphics/Pictures/DexNew/Icon/Egg"
			return
		end
		@iconpath = "Graphics/Pictures/DexNew/Icon/" + "#{@pokemon.species}"#+ sprintf("%03d",@pokemon.species)
		@iconpath = @iconpath+(@pokemon.form>0 && pbResolveBitmap(@iconpath + "_#{@pokemon.form}") ? "_#{@pokemon.form}" : "")
    @iconpath = @iconpath+(@pokemon.isDelta? && pbResolveBitmap(@iconpath + "d") ? "d" : "" )
    @iconpath = @iconpath+(@pokemon.gender==1 && pbResolveBitmap(@iconpath + "f") ? "f" : "" )
  end
	
	def dispose
		@healthbar.dispose
		#@selbitmap.dispose
		#@statuses.dispose
		@hpbar.dispose
		@item.dispose
		@overlay.dispose
		self.bitmap.dispose
		super
	end
	
	def selected=(value)
		@selected=value
		@refreshBitmap=true
		refresh
	end
	
	def text=(value)
		@text=value
		@refreshBitmap=true
		refresh
	end
	
	def pokemon=(value)
		@pokemon=value
		if @pkmnsprite && !@pkmnsprite.disposed?
			@pkmnsprite.bitmap = Bitmap.new(1,1)#pokemon=value
		end
		@refreshBitmap=true
		refresh
	end
	
	def preselected=(value)
		if value!=@preselected
			@preselected=value
			refresh
		end
	end
	
	def switching=(value)
		if value!=@switching
			@switching=value
			refresh
		end
	end
	
	def color=(value)
		super
		@overlay.color=value
		@healthbar.color=value
		@item.color = value
		refresh
	end
	
	def x=(value)
		super
		@overlay.x=value
		@healthbar.x=value+ 56
		@item.x = value + 120
		refresh
	end
	
	def y=(value)
		super
		@overlay.y=value
		@healthbar.y=value+115
		@item.y = value - 4
		refresh
	end
	
	def opacity=(value)
		super
		@overlay.opacity=value
		@healthbar.opacity=value
		@item.opacity = value
		refresh
	end
	
	def hp
		return @pokemon.hp
	end
	
	def drawText
		oldo = @overlay.opacity
		@overlay.bitmap.clear
		@overlay.opacity = oldo if @overlay.opacity != oldo
		
		base=Color.new(248,248,248)
		shadow=Color.new(40,40,40)
		darkblue = Color.new(18,54,83)
		#pbSetSystemFont(self.bitmap)
		pbSetFont(self.bitmap,"Kimberley Bl",16)
		pbSetFont(@overlay.bitmap,"Kimberley Bl",16)
		pokename=@pokemon.name
		textpos=[[pokename,@pokenameX,@pokenameY,0,darkblue,nil]]
		
		if !@pokemon.isEgg?
      if @pokemon.gender==0
        b = pbBitmap(@path+"MALE")
        @overlay.bitmap.blt(104,82,b,Rect.new(0,0,12,17)) 
      elsif @pokemon.gender==1
        b = pbBitmap(@path+"FEMALE")
        @overlay.bitmap.blt(104,82,b,Rect.new(0,0,11,18)) 
      end
			if !@text || @text.length==0
				tothp=@pokemon.totalhp
				textpos2=[[_ISPRINTF("{1: 3d}/{2: 3d}",@pokemon.hp,tothp),
						@hpX,@hpY,2,base,shadow]]
				percentage=@pokemon.hp/100
				barbg=(@pokemon.hp<=0) ? @hpbarfnt : @hpbar
				barbg=(self.preselected || (self.selected && @switching)) ? @hpbarswap : barbg
				#self.bitmap.blt(@hpbarX,@hpbarY,@healthbar.bitmap,Rect.new(0,0,(self.hp*@healthbar.bitmap.width/@pokemon.totalhp),@healthbar.bitmap.height))
				hpgauge=@pokemon.totalhp==0 ? 0 : (self.hp*96/@pokemon.totalhp)
				hpgauge=1 if hpgauge==0 && self.hp>0
				hpzone=0
				hpzone=1 if self.hp<=(@pokemon.totalhp/2).floor
				hpzone=2 if self.hp<=(@pokemon.totalhp/4).floor
				hpcolors=[
					Color.new(24,192,32),Color.new(96,248,96),   # Green
					Color.new(232,168,0),Color.new(248,216,0),   # Orange
					Color.new(248,72,56),Color.new(248,152,152)  # Red
				]
				# fill with HP color
				#self.bitmap.fill_rect(@gaugeX,@gaugeY,hpgauge,2,hpcolors[hpzone*2])
				#self.bitmap.fill_rect(@gaugeX,@gaugeY+2,hpgauge,4,hpcolors[hpzone*2+1])
				#self.bitmap.fill_rect(@gaugeX,@gaugeY+6,hpgauge,2,hpcolors[hpzone*2])
				#if @pokemon.hp==0 || @pokemon.status>0
				#	status=(@pokemon.hp==0) ? 5 : @pokemon.status-1
				#	statusrect=Rect.new(0,16*status,44,16)
				#	self.bitmap.blt(@statusX,@statusY,@statuses.bitmap,statusrect)
				#end
			end
		end
		#self.bitmap.blt(@hpbarX,@hpbarY,@healthbar.bitmap,Rect.new(0,0,(self.hp*@healthbar.width/@pokemon.totalhp),@healthbar.height)) if @pokemon
		pbDrawTextPositions(@overlay.bitmap,textpos)
		pbSetFont(self.bitmap,"Kimberley Bl",18)
		#pbDrawTextPositions(@overlay.bitmap,textpos2) if textpos2
		if !@pokemon.isEgg?
			b = Bitmap.new(500,20)
			b2 = Bitmap.new(500,20)
			pbSetFont(self.bitmap,"Kimberley Bl",7)
			pbSetFont(b,"Kimberley Bl",14)
			pbSetFont(b2,"Kimberley Bl",14)
			#@levelX,@levelY
			tothp=@pokemon.totalhp
			textpos2=[[_ISPRINTF("{1: 3d}/{2: 3d}",@pokemon.hp,tothp),100,0,2,base]]
			leveltext=[([_INTL("Lv.{1}",@pokemon.level),0,0,0,base])]
			#pbDrawTextPositions(@overlay.bitmap,leveltext)
			pbDrawTextPositions(b,leveltext)
			if !@text
				pbDrawTextPositions(b2,textpos2)
			end
			@overlay.bitmap.stretch_blt(Rect.new(@levelX,@levelY,500,20),b,Rect.new(0,0,500,20))
			@overlay.bitmap.stretch_blt(Rect.new(@hpX-100,@hpY,500,20),b2,Rect.new(0,0,500,20))
		end
		if @text && @text.length>0
			#pbSetSystemFont(@overlay.bitmap)
			#@overlay.bitmap
			b = Bitmap.new(500,20)
			pbSetFont(b,"Kimberley Bl",14)
			#@annotY
			annotation=[[@text,0,0,0,base]]
			pbDrawTextPositions(b,annotation)
			@overlay.bitmap.stretch_blt(Rect.new(@annotX,@annotY,500,20),b,Rect.new(0,0,500,20))
		end
		
	end
	
	def refresh
		return if @refreshing
		return if disposed?
		@refreshing=true
		if !self.bitmap || self.bitmap.disposed?
			self.bitmap=BitmapWrapper.new(147,147)
		end
		if @pokeballsprite && !@pokeballsprite.disposed?
			@pokeballsprite.x=self.x+@pokeballXOffset
			@pokeballsprite.y=self.y+@pokeballYOffset
			@pokeballsprite.color=self.color
			@pokeballsprite.changeBitmap(self.selected ? "pokeballsel" : "pokeballdesel")
		end
		if !@switching
			if self.preselected
				self.opacity = 170
			else
				self.opacity = 255
			end
		end
		if @refreshBitmap
			@item.visible = (@pokemon.item>0)
			base=Color.new(248,248,248)
			@refreshBitmap=false
			if self.selected
				@cursor.x = self.x - 16 - self.ox
				@cursor.y = self.y - 3
			end
			drawText
			@slotbg = pbBitmap(@path+"SlotBg")
			self.bitmap.clear
			self.bitmap.blt(0,0,@slotbg,Rect.new(0,0,@slotbg.width,@slotbg.height))
			evaluateIconPath
			self.bitmap.blt(53,113,pbBitmap(@path+"healthbar_bg"),Rect.new(0,0,86,11))
			self.bitmap.blt(33,10,pbBitmap(@iconpath),Rect.new(0,0,75,74))
			if !(RETRODEX.include?(pokemon.species) && pokemon.isShiny?)
				self.bitmap.blt(10,10,pbBitmap("Graphics/Pictures/SummaryNew/Retro"),Rect.new(0,0,21,21)) if RETRODEX.include?(pokemon.species)
				self.bitmap.blt(10,10,pbBitmap("Graphics/Pictures/SummaryNew/Shiny"),Rect.new(0,0,21,21)) if pokemon.isShiny?
			else
				self.bitmap.blt(19,12,pbBitmap("Graphics/Pictures/SummaryNew/Retro"),Rect.new(0,0,21,21)) if RETRODEX.include?(pokemon.species)
				self.bitmap.blt(6,6,pbBitmap("Graphics/Pictures/SummaryNew/Shiny"),Rect.new(0,0,21,21)) if pokemon.isShiny?
			end
			if pokemon.status != 0 && pokemon.hp>0
				statusindex = pokemon.status-1
				self.bitmap.blt(121,81,pbBitmap("Graphics/Pictures/EBS/Xenoverse/STATUS"),Rect.new(19*statusindex,0,19,19))	
			end
			if pokemon.hp <=0
				self.color=Color.new(73,51,51,40)
      else
        self.color=Color.new(0,0,0,0)
      end
    	percentage=@pokemon.hp/(@pokemon.totalhp*1.0)#80.0
			@healthbar.src_rect=Rect.new(0,0,80*percentage,7)
		end
		@refreshing=false
	end
	
	def update
		super
		@pokeballsprite.update if @pokeballsprite && !@pokeballsprite.disposed?
		if @pkmnsprite && !@pkmnsprite.disposed?
			@pkmnsprite.update
		end
	end
end

################################################################################
class PokemonScreen_Scene
	def pbStartScene(party,starthelptext,annotations=nil,multiselect=false)
		pbCheckBremandForms
		@sprites={}
		@party=party
		echoln "Party length is #{party.length}"
		@viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
		@viewport.z=99999
    @viewport.z+=600 if @addPriority
		#@viewport.z=100000
		@multiselect=multiselect
		#addBackgroundPlane(@sprites,"partybg","partybg",@viewport)
		@sprites["bg"]=Sprite.new(@viewport)
		@sprites["bg"].bitmap=pbBitmap("Graphics/Pictures/PartyNew/bg")
    @sprites["abg"]=AnimatedPlane.new(@viewport)
    @sprites["abg"].bitmap = pbBitmap(Dex::PATH + "animbg")
		@sprites["box"]=Sprite.new(@viewport)
		@sprites["box"].bitmap=Bitmap.new(300,48)
		@sprites["box"].x=6
		@sprites["box"].y=Graphics.height-@sprites["box"].bitmap.height-8
		@sprites["messagebox"]=Window_AdvancedTextPokemon.new("")
		@sprites["helpwindow"]=Window_UnformattedTextPokemon.new(starthelptext)
		@sprites["messagebox"].viewport=@viewport
		@sprites["messagebox"].visible=false
		@sprites["messagebox"].letterbyletter=true
		@sprites["helpwindow"].viewport=@viewport
		@sprites["helpwindow"].visible=false
		@sprites["helpwindow"].baseColor=Color.new(240,240,240,0)
		@sprites["helpwindow"].shadowColor=Color.new(40,40,40,0)
		@sprites["helpwindow"].windowskin=nil
		@sprites["helpoverlay"]=Sprite.new(@viewport)
		@sprites["helpoverlay"].bitmap = Bitmap.new(512,384)
		@sprites["helpoverlay"].z=12
		@sprites["helpoverlay"].bitmap.font.name = "Barlow Condensed"
		@sprites["helpoverlay"].bitmap.font.size = 25
		@sprites["overlay"]=Sprite.new(@viewport)
		@sprites["overlay"].bitmap = Bitmap.new(512,384)
		@sprites["overlay"].z = 12
		@sprites["overlay"].bitmap.font.name = "Barlow Condensed"
		@sprites["overlay"].bitmap.font.bold = true
		@sprites["overlay"].bitmap.font.size = 25
		if @multiselect
			@sprites["confirm"]=Sprite.new(@viewport)
			@sprites["confirm"].y = 345
			@sprites["confirm"].z = 20
			@sprites["confirm"].bitmap = Bitmap.new(200,34)
			@sprites["confirm"].bitmap.blt(200-34,0,pbBitmap("Graphics/Pictures/PartyNew/ConfirmButton"),Rect.new(0,0,34,34))
			@sprites["confirm"].bitmap.font.name = "Barlow Condensed"
			@sprites["confirm"].bitmap.font.bold = true
			@sprites["confirm"].bitmap.font.size = 25
			pbDrawTextPositions(@sprites["confirm"].bitmap,[[_INTL("Confirm"),200-38,3,1,Color.new(248,248,248)]])
		end
		pbDrawTextPositions(@sprites["overlay"].bitmap,[[_INTL("Close"),464,348,1,Color.new(248,248,248)],
				[_INTL("Select"),332,348,1,Color.new(248,248,248)]])
		pbDrawTextPositions(@sprites["helpoverlay"].bitmap,[[starthelptext,10,348,0,Color.new(248,248,248)]])
		@sprites["selcursor"]=Sprite.new(@viewport)
		@sprites["selcursor"].bitmap = pbBitmap("Graphics/Pictures/PartyNew/Selection")
		@sprites["selcursor"].z = 10
		@sprites["lowerbanner"]=Sprite.new(@viewport)
		@sprites["lowerbanner"].bitmap = pbBitmap("Graphics/Pictures/PartyNew/LowerBanner")
		@sprites["lowerbanner"].y = 345
		pbBottomLeftLines(@sprites["messagebox"],2)
		pbBottomLeftLines(@sprites["helpwindow"],1)
		@sprites["helpwindow"].y-=10
		pbSetHelpText(starthelptext)
		# Add party Pokémon sprites
		for i in 0...6
			if @party[i]
				@sprites["pokemon#{i}"]=PokeSelectionSprite.new(
					@party[i],i,@sprites["selcursor"],@viewport)
			else
				@sprites["pokemon#{i}"]=PokeSelectionPlaceholderSprite.new(
					@party[i],i,@viewport)
			end
			if annotations
				@sprites["pokemon#{i}"].text=annotations[i]
			end
		end
		#~ if @multiselect
		#~ @sprites["pokemon6"]=PokeSelectionConfirmSprite.new(@viewport)
		#~ @sprites["pokemon7"]=PokeSelectionCancelSprite2.new(@viewport)
		#~ else
		#~ @sprites["pokemon6"]=PokeSelectionCancelSprite.new(@viewport)
		#~ end
		
		# Select first Pokémon
		@activecmd=0
		@sprites["pokemon0"].selected=true
		pbFadeInAndShow(@sprites) { update }
	end
	alias update_old update unless self.method_defined?(:update_old)
  def update
    update_old
    if @sprites["abg"]
			@sprites["abg"].ox+=Dex::ANIMBGSCROLLX
			@sprites["abg"].oy+=Dex::ANIMBGSCROLLY
		end		
  end
  
  def pbHardRefresh
    oldtext=[]
    lastselected=-1
    for i in 0...6
      oldtext.push(@sprites["pokemon#{i}"].text)
      lastselected=i if @sprites["pokemon#{i}"].selected
      @sprites["pokemon#{i}"].dispose
    end
    lastselected=@party.length-1 if lastselected>=@party.length
    lastselected=0 if lastselected<0
    for i in 0...6
      if @party[i]
        @sprites["pokemon#{i}"]=PokeSelectionSprite.new(
        @party[i],i,@sprites["selcursor"],@viewport)
      else
        @sprites["pokemon#{i}"]=PokeSelectionPlaceholderSprite.new(
        @party[i],i,@viewport)
      end
      @sprites["pokemon#{i}"].text=oldtext[i]
    end
    pbSelect(lastselected)
  end
	
	def pbSelect(item)
    @activecmd=item
    numsprites=(@multiselect) ? 8 : 7
    for i in 0...6#numsprites
      @sprites["pokemon#{i}"].selected=(i==@activecmd)
    end
  end
  
	def pbChoosePokemon(switching=false,multiple =false)
		for i in 0...6
			@sprites["pokemon#{i}"].preselected=(switching&&i==@activecmd)
			@sprites["pokemon#{i}"].switching=switching
		end
		
		pbRefresh
		loop do
			Graphics.update
			Input.update
			self.update
			oldsel=@activecmd
			key=-1
			key=Input::DOWN if Input.repeat?(Input::DOWN)
			key=Input::RIGHT if Input.repeat?(Input::RIGHT)
			key=Input::LEFT if Input.repeat?(Input::LEFT)
			key=Input::UP if Input.repeat?(Input::UP)
			if key>=0
				@activecmd=pbChangeSelection(key,@activecmd)
			end
			if @activecmd!=oldsel # Changing selection
				pbPlayCursorSE()
				numsprites=(@multiselect) ? 8 : 7
				for i in 0...numsprites
					next if !@sprites["pokemon#{i}"]
					@sprites["pokemon#{i}"].selected=(i==@activecmd)
				end
			end
			if Input.trigger?(Input::B)
				return -1
			end
			if Input.trigger?(Input::C)
				pbPlayDecisionSE()
				cancelsprite=(@multiselect) ? 7 : 6
				return (@activecmd==cancelsprite) ? -1 : @activecmd
			end
			if multiple
				if Input.trigger?(Input::A) #Confirming if multiple selection
					pbPlayDecisionSE()
					return 6
				end
			end
		end
		
		
	end
	
	def pbChangeSelection(key,currentsel)
		numsprites=(@multiselect) ? 8 : 7 
		case key
		when Input::LEFT
			begin
				currentsel-=1
			end while currentsel>0 && currentsel<@party.length && !@party[currentsel]
			if currentsel>=@party.length && currentsel<6
				currentsel=@party.length-1
			end
			currentsel=@party.length-1 if currentsel<0
		when Input::RIGHT
			begin
				currentsel+=1
			end while currentsel<@party.length && !@party[currentsel]
			if currentsel>=@party.length
				currentsel=0
			end
		when Input::UP
			if currentsel>=6
				begin
					currentsel-=1
				end while currentsel>0 && !@party[currentsel]
			else
				begin
					currentsel-=3
				end while currentsel>0 && !@party[currentsel]
			end
			if currentsel>=@party.length && currentsel<6
				currentsel=@party.length-1
			end
			if currentsel<0
				currentsel=3 if currentsel==-3
				currentsel=4 if currentsel==-2
				currentsel=5 if currentsel==-1
				if currentsel>=@party.length && currentsel<6
					currentsel=@party.length-1
				end
			end
		when Input::DOWN
			if currentsel>=5
				currentsel=2
			else
				currentsel+=3
				currentsel=5 if currentsel<5 && !@party[currentsel]
			end
			if currentsel>=@party.length && currentsel<6
				currentsel=@party.length-1
			elsif currentsel>=@party.length
				currentsel=0 if currentsel==6
				currentsel=1 if currentsel==7
				currentsel=2 if currentsel==8
				if currentsel>=@party.length && currentsel<6
					currentsel = @party.length-1
				end
			end
		end
		return currentsel
	end
	
	def pbSwitchBegin(oldid,newid)
		oldsprite=@sprites["pokemon#{oldid}"]
		newsprite=@sprites["pokemon#{newid}"]
		#oldsprite.opacity=255
		#newsprite.opacity=255
		oldsprite.fade(0,21)
		newsprite.fade(0,21)
		22.times do
			#oldsprite.opacity-= (255/21) 
			#newsprite.opacity-= (255/21) 
			oldsprite.update
			newsprite.update
			Graphics.update
			Input.update
			self.update
		end
	end
	
	def pbSwitchEnd(oldid,newid)
		oldsprite=@sprites["pokemon#{oldid}"]
		newsprite=@sprites["pokemon#{newid}"]
		oldsprite.pokemon=@party[oldid]
		newsprite.pokemon=@party[newid]
		oldsprite.fade(255,21)
		newsprite.fade(255,21)
		22.times do
			#oldsprite.opacity+=(255/21)
			#newsprite.opacity+=(255/21)
			oldsprite.update
			newsprite.update
			Graphics.update
			Input.update
			self.update
		end
		for i in 0...6
			@sprites["pokemon#{i}"].preselected=false
			@sprites["pokemon#{i}"].switching=false
		end
		pbRefresh
	end
	
	def commandsUpdate
		@frameskip +=1
		@frame+=1 if @frameskip ==1
		@frameskip = 0 if @frameskip == 2
		@frame = 0 if @frame>=@framecount
		for i in 0...@size
			@cmds["cmd#{i}"].update if defined?(@cmds["cmd#{i}"].update)
		end
		
		@actualBitmap.clear# = Bitmap.new(@pokemonBitmap.height,@pokemonBitmap.height)
		#@actualBitmap.fill_rect(0,0,30,30,Color.new(255,0,0))#debug
		@actualBitmap.blt(0,0,@pokemonBitmap,Rect.new(@pokemonBitmap.height*@frame,0,@pokemonBitmap.height,@pokemonBitmap.height))
		#@actualBitmap = @actualBitmap.clone
		@actualBitmap.add_outline(Color.new(248,248,248),1)
		@cmds["sprite"].bitmap = @actualBitmap if @cmds["sprite"] && @actualBitmap
	end
	
	def updateCmds
		for i in 0...@size
			@cmds["cmd#{i}"].fade(175,10) if @index != i
			@cmds["cmd#{i}"].fade(255,10) if @index == i
		end
	end
	
	def fadeOut(hash,frames=20)
		r= 255
		frames.times do
			Graphics.update
			commandsUpdate
			r-=255/(frames-1)
			for value in hash.values
				value.opacity = r
			end
		end
	end
	
	def fadeIn(hash,frames=20)
		r=0
		frames.times do
			Graphics.update
			commandsUpdate
			r+=255/(frames-1)
			for value in hash.values
				value.opacity = r if !value.is_a?(EAMSprite)
				
			end
		end
	end
	
	
	
	alias pbShowCommands_old pbShowCommands unless self.method_defined?(:pbShowCommands_old)
	def pbShowCommands(helptext,commands,y=nil,index=0,pkmn=nil,x=0)
		ret=-1
		return ret if pkmn==nil
		@cmds={}
		@cmds["bg"]=Sprite.new(@viewport)
		@cmds["bg"].bitmap = pbBitmap("Graphics/Pictures/PartyNew/gradient")
		@cmds["bg"].y = 384-292
		@cmds["bg"].z = 20
    if !pkmn.isEgg?
      last = ""
      if pkmn.isDelta?
        last = "d"
      else
        last = (pkmn.form>0 ? "_#{pkmn.form}" : "")
      end
      add=""
      add = "Female/" if pkmn.gender==1 && pbResolveBitmap("Graphics/Battlers/Front/Female/"+sprintf("%03d",pkmn.species)+last)
      @pokemonBitmap = pbBitmap((pkmn.isShiny? ? "Graphics/Battlers/FrontShiny/" : "Graphics/Battlers/Front/")+add+sprintf("%03d",pkmn.species) + last )
      @frameskip = 0
      @frame = 0
      @framecount = @pokemonBitmap.width/@pokemonBitmap.height
      
      @actualBitmap = Bitmap.new(@pokemonBitmap.height,@pokemonBitmap.height)
      @actualBitmap.blt(0,0,@pokemonBitmap,Rect.new(0,@pokemonBitmap.height*@frame,@pokemonBitmap.height,@pokemonBitmap.height+2))
      #@actualBitmap = @actualBitmap.clone
      #@actualBitmap.fill_rect(0,0,30,30,Color.new(255,0,0))
      @actualBitmap.add_outline(Color.new(248,248,248),1)
    else
      @frameskip = 0
      @frame = 0
      @framecount = 1
      @pokemonBitmap = pbBitmap("Graphics/Battlers/egg")
      @actualBitmap = Bitmap.new(@pokemonBitmap.height,@pokemonBitmap.height)
      @actualBitmap.blt(0,0,@pokemonBitmap,Rect.new(0,0,@pokemonBitmap.height,@pokemonBitmap.height+2))
      @actualBitmap.add_outline(Color.new(248,248,248),1)
    end
		@cmds["sprite"]=Sprite.new(@viewport)
		@cmds["sprite"].bitmap = @actualBitmap# @pokemonBitmap.clone
		
    #@cmds["sprite"].create_outline(Color.new(248,248,248),1)
		#@cmds["sprite"].bitmap.add_outline(Color.new(248,248,248),1)
		@cmds["sprite"].ox = @pokemonBitmap.height/2
		@cmds["sprite"].z = 40
		@cmds["sprite"].oy = pbGetSpriteBase(@pokemonBitmap)+1
		#@cmds["sprite"].src_rect = Rect.new(0,@pokemonBitmap.height*@frame,@pokemonBitmap.height,@pokemonBitmap.height+2)
		@cmds["sprite"].zoom_x = 2
		@cmds["sprite"].zoom_y = 2
    if pkmn.isEgg?
      @cmds["sprite"].zoom_x = 1
      @cmds["sprite"].zoom_y = 1
    end
		@cmds["sprite"].x = 111
		@cmds["sprite"].y = 331#331
		
		@buttonBitmap = pbBitmap("Graphics/Pictures/PartyNew/Button")
		
		@cmds["overlay"] = Sprite.new(@viewport)
		@cmds["overlay"].z = 22
		@cmds["overlay"].bitmap = Bitmap.new(512,384)
		@cmds["overlay"].bitmap.font.name = "Barlow Condensed"
		@cmds["overlay"].bitmap.font.bold = true
		@cmds["overlay"].bitmap.font.size = 25
		
		pbDrawTextPositions(@cmds["overlay"].bitmap,[[helptext,30,348,0,Color.new(248,248,248)]])
		@startY = 374-34*commands.length
		@index = 0
		@size = commands.length
		for i in 0...@size
			@cmds["cmd#{i}"] = EAMSprite.new(@viewport)
			if x==0
				@cmds["cmd#{i}"].bitmap = @buttonBitmap.clone
			else
				@cmds["cmd#{i}"].bitmap = Bitmap.new(@buttonBitmap.width+x*3,@buttonBitmap.height)
				@cmds["cmd#{i}"].bitmap.blt(0,0,@buttonBitmap,Rect.new(0,0,30,34))
				@cmds["cmd#{i}"].bitmap.blt(@cmds["cmd#{i}"].bitmap.width-30,0,@buttonBitmap,Rect.new(@cmds["cmd#{i}"].bitmap.width-30,0,30,34))
				@cmds["cmd#{i}"].bitmap.blt(30,0,@buttonBitmap,Rect.new(30,0,86,34))
				@cmds["cmd#{i}"].bitmap.blt(30+86,0,@buttonBitmap,Rect.new(30,0,x*3,34))
			end
			@cmds["cmd#{i}"].z = 22
			@cmds["cmd#{i}"].y = @startY+34*i
			@cmds["cmd#{i}"].x = 357  - (x>0 ? x*3 : 0)
			@cmds["cmd#{i}"].fade(175,10) if @index != i
			@cmds["cmd#{i}"].bitmap.font.name = "Barlow Condensed"
			@cmds["cmd#{i}"].bitmap.font.size = 21
			@cmds["cmd#{i}"].bitmap.font.bold = true
			pbDrawTextPositions(@cmds["cmd#{i}"].bitmap,[[commands[i],@cmds["cmd#{i}"].bitmap.width/2,7,2,Color.new(18,54,83)]])
		end
		for s in @cmds.values
			s.opacity = 0
		end
		updateCmds
		fadeIn(@cmds,10)
		loop do
			Graphics.update
			Input.update
			commandsUpdate
			
			if Input.trigger?(Input::DOWN)
				@index+=1
				if @index>=commands.length
					@index = 0
				end
				updateCmds
			elsif Input.trigger?(Input::UP)
				@index-=1
				if @index<0
					@index = commands.length-1
				end
				updateCmds
			end
			
			if Input.trigger?(Input::C)
				ret = @index
				fadeOut(@cmds,2)
				pbDisposeSpriteHash(@cmds)
				break
			end
			
			if Input.trigger?(Input::B)
				fadeOut(@cmds)
				pbDisposeSpriteHash(@cmds)
				break
			end
		end
		return ret
	end
	
end

class PokemonScreen_Scene
	alias pbStartFormChange_old pbStartFormChange unless self.method_defined?(:pbStartFormChange_old)
	def pbStartFormChange(i)
		if [PBSpecies::TRISHOUT,PBSpecies::SHYLEON,PBSpecies::SHULONG,PBSpecies::SABOLT].include?($Trainer.party[i].species)
			viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
			viewport.z = 100010
			@sprites["pokemon#{i}"].changeForm($Trainer.party[i].form == 2 ? 2 : 1)
			time = 40
			#pbSEPlay("anello",80)
			pbWait(20)
			@sprites["pokemon#{i}"].restoreSlot { pbRefreshSingle(i) }
			Input.update
			pbDisplay(_INTL("{1} ha cambiato forma!", @party[i].name))
		else
			pbStartFormChange_old(i)
		end
	end
end

class PokemonScreen
  
  def pbChooseMove(pokemon,helptext)
    movenames=[]
    for i in pokemon.moves
      break if i.id==0
      if i.totalpp==0
        movenames.push(_INTL("{1} (PP: ---)",PBMoves.getName(i.id),i.pp,i.totalpp))
      else
        movenames.push(_INTL("{1} (PP: {2}/{3})",PBMoves.getName(i.id),i.pp,i.totalpp))
      end
    end
    return @scene.pbShowCommands(helptext,movenames,nil,0,pokemon,24)
  end
  
	def pbPokemonScreen
		oldframerate = Graphics.frame_rate
		Graphics.frame_rate = 60
		@scene.pbStartScene(@party,
			@party.length>1 ? _INTL("Scegli un Pokémon.") : _INTL("Scegli un Pokémon o esci."),nil)
		loop do
			@scene.pbSetHelpText(
				@party.length>1 ? _INTL("Scegli un Pokémon.") : _INTL("Scegli un Pokémon o esci."))
			pkmnid=@scene.pbChoosePokemon
			if pkmnid<0
				break
			end
			pkmn=@party[pkmnid]
			commands=[]
			cmdSummary=-1
			cmdSwitch=-1
			cmdItem=-1
			cmdDebug=-1
			cmdMail=-1
			# Build the commands
			commands[cmdSummary=commands.length]=_INTL("Statistiche")
			if $DEBUG
				# Commands for debug mode only
				commands[cmdDebug=commands.length]=_INTL("Debug")
			end
			cmdMoves=[-1,-1,-1,-1]
			#for i in 0...pkmn.moves.length
			#	move=pkmn.moves[i]
			#	# Check for hidden moves and add any that were found
			#	if !pkmn.isEgg? && (
			#			isConst?(move.id,PBMoves,:MILKDRINK) ||
			#			isConst?(move.id,PBMoves,:SOFTBOILED) ||
			#			HiddenMoveHandlers.hasHandler(move.id)
			#		)
			#		commands[cmdMoves[i]=commands.length]=PBMoves.getName(move.id)
			#	end
			#end
			commands[cmdSwitch=commands.length]=_INTL("Ordina") if @party.length>1
			if !pkmn.isEgg?
				if pkmn.mail
					commands[cmdMail=commands.length]=_INTL("Mail")
				else
					commands[cmdItem=commands.length]=_INTL("Oggetti")
				end
			end
			commands[commands.length]=_INTL("Chiudi")
			command=@scene.pbShowCommands(_INTL("Do what with {1}?",pkmn.name),commands,nil,0,pkmn)
			havecommand=false
			for i in 0...4
				if cmdMoves[i]>=0 && command==cmdMoves[i]
					havecommand=true
					if isConst?(pkmn.moves[i].id,PBMoves,:SOFTBOILED) ||
						isConst?(pkmn.moves[i].id,PBMoves,:MILKDRINK)
						if pkmn.hp<=pkmn.totalhp/5
							pbDisplay(_INTL("Not enough HP..."))
							break
						end
						@scene.pbSetHelpText(_INTL("Use on which Pokémon?"))
						oldpkmnid=pkmnid
						loop do
							@scene.pbPreSelect(oldpkmnid)
							pkmnid=@scene.pbChoosePokemon(true)
							break if pkmnid<0
							newpkmn=@party[pkmnid]
							if newpkmn.isEgg? || newpkmn.hp==0 || newpkmn.hp==newpkmn.totalhp || pkmnid==oldpkmnid
								pbDisplay(_INTL("This item can't be used on that Pokémon."))
							else
								pkmn.hp-=pkmn.totalhp/5
								hpgain=pbItemRestoreHP(newpkmn,pkmn.totalhp/5)
								@scene.pbDisplay(_INTL("{1}'s HP was restored by {2} points.",newpkmn.name,hpgain))
								pbRefresh
							end
						end
						break
					elsif Kernel.pbCanUseHiddenMove?(pkmn,pkmn.moves[i].id)
						@scene.pbEndScene
						if isConst?(pkmn.moves[i].id,PBMoves,:FLY)
							scene=PokemonRegionMapScene.new(-1,false)
							screen=PokemonRegionMap.new(scene)
							ret=screen.pbStartFlyScreen
							if ret
								$PokemonTemp.flydata=ret
								return [pkmn,pkmn.moves[i].id]
							end
							@scene.pbStartScene(@party,
								@party.length>1 ? _INTL("Scegli un Pokémon.") : _INTL("Scegli un Pokémon."))
							break
						end
						return [pkmn,pkmn.moves[i].id]
					else
						break
					end
				end
			end
			next if havecommand
			if cmdSummary>=0 && command==cmdSummary
				@scene.pbSummary(pkmnid)
			elsif cmdSwitch>=0 && command==cmdSwitch
				@scene.pbSetHelpText(_INTL("Move to where?"))
				oldpkmnid=pkmnid
				pkmnid=@scene.pbChoosePokemon(true)
				if pkmnid>=0 && pkmnid!=oldpkmnid
					pbSwitch(oldpkmnid,pkmnid)
					$PokemonTemp.dependentEvents.refresh_sprite(true)
				end
			elsif cmdDebug>=0 && command==cmdDebug
				pbPokemonDebug(pkmn,pkmnid)
			elsif cmdMail>=0 && command==cmdMail
				command=@scene.pbShowCommands(_INTL("Do what with the mail?"),[_INTL("Read"),_INTL("Take"),_INTL("Cancel")])
				case command
				when 0 # Read
					pbFadeOutIn(99999){
						pbDisplayMail(pkmn.mail,pkmn)
					}
				when 1 # Take
					pbTakeMail(pkmn)
					pbRefreshSingle(pkmnid)
				end
			elsif cmdItem>=0 && command==cmdItem
				commands=[_INTL("Dai"),_INTL("Prendi"),_INTL("Chiudi")]
				command=@scene.pbShowCommands(_INTL("Cosa devi fare con questo oggetto?"),commands,296,0,pkmn)
				case command
				when 0 # Give
					item=@scene.pbChooseItem($PokemonBag)
					if item>0
						form = pkmn.form
						pbGiveMail(item,pkmn,pkmnid)
						if form != pkmn.form
							pbStartFormChange(pkmnid)
							$PokemonTemp.dependentEvents.refresh_sprite(true)
						else
							pbRefreshSingle(pkmnid)
							$PokemonTemp.dependentEvents.refresh_sprite(true)
						end
					end
				when 1 # Take
					form = pkmn.form
					pbTakeMail(pkmn)
					if form != pkmn.form
						pbStartFormChange(pkmnid)
						$PokemonTemp.dependentEvents.refresh_sprite(true)
					else
						pbRefreshSingle(pkmnid)
						$PokemonTemp.dependentEvents.refresh_sprite(true)
					end
				end
			end
		end
		@scene.pbEndScene
		Graphics.frame_rate = 40 if oldframerate <60
		return nil
	end  
	
	def pbPokemonDebug(pkmn,pkmnid)
		command=0
		loop do
			command=@scene.pbShowCommands_old(_INTL("Che fare con {1}?",pkmn.name),[
					_INTL("HP/Status"),
					_INTL("Livello"),
					_INTL("Species"),
					_INTL("Mosse"),
					_INTL("Genere"),
					_INTL("Abilità"),
					_INTL("Nature"),
					_INTL("Shininess"),
					_INTL("Form"),
					_INTL("Happiness"),
					_INTL("EV/IV/pID"),
					_INTL("Pokérus"),
					_INTL("Ownership"),
					_INTL("Nickname"),
					_INTL("Poké Ball"),
					_INTL("Ribbons"),
					_INTL("Egg"),
					_INTL("Shadow Pokémon"),
					_INTL("Make Mystery Gift"),
					_INTL("Duplicate"),
					_INTL("Delete"),
					_INTL("Chiudi")
				],command)#0,pkmn)
			case command
				### Cancel ###
			when -1, 21
				break
				### HP/Status ###
			when 0
				$scene=nil
				### Level ###
			when 1
				$scene=nil
				### Species ###
			when 2
				$scene=nil
				### Moves ###
			when 3
				$scene=nil
				### Gender ###
			when 4
				$scene=nil
				### Ability ###
			when 5
				$scene=nil
				### Nature ###
			when 6
				$scene=nil
				### Shininess ###
			when 7
				$scene=nil
				### Form ###
			when 8
				$scene=nil
				### Happiness ###
			when 9
				$scene=nil
				### EV/IV/pID ###
			when 10
				$scene=nil
				### Pokérus ###
			when 11
				$scene=nil
				### Ownership ###
			when 12
				$scene=nil
				### Nickname ###
			when 13
				$scene=nil
				### Poké Ball ###
			when 14
				$scene=nil
				### Ribbons ###
			when 15
				$scene=nil
				### Egg ###
			when 16
				$scene=nil
				### Shadow Pokémon ###
			when 17
				$scene=nil
				### Make Mystery Gift ###
			when 18
				$scene=nil
				### Duplicate ###
			when 19
				$scene=nil
				### Delete ###
			when 20
				$scene=nil
			end
		end
	end
	
	
	
	def pbChooseMultiplePokemon(number,validProc)
		annot=[]
		statuses=[]
		ordinals=[
			_INTL("INELIGIBLE"),
			_INTL("NOT ENTERED"),
			_INTL("BANNED"),
			_INTL("FIRST"),
			_INTL("SECOND"),
			_INTL("THIRD"),
			_INTL("FOURTH"),
			_INTL("FIFTH"),
			_INTL("SIXTH")
		]
		ret=nil
		addedEntry=false
		for i in 0...@party.length
			if validProc.call(@party[i])
				statuses[i]=1
			else
				statuses[i]=2
			end  
		end
		for i in 0...@party.length
			annot[i]=ordinals[statuses[i]]
		end
		@scene.pbStartScene(@party,_INTL(""),annot,true)
		loop do
			realorder=[]
			for i in 0...@party.length
				for j in 0...@party.length
					if statuses[j]==i+3
						realorder.push(j)
						break
					end
				end
			end
			for i in 0...realorder.length
				statuses[realorder[i]]=i+3
			end
			for i in 0...@party.length
				annot[i]=ordinals[statuses[i]]
			end
			@scene.pbAnnotate(annot)
			#if realorder.length==number && addedEntry
			#  @scene.pbSelect(6)
			#end
			@scene.pbSetHelpText(_INTL("Choose Pokémon and confirm."))
			pkmnid=@scene.pbChoosePokemon(false,true)
			addedEntry=false
			if pkmnid==6
				if realorder.length>0 # Confirm was chosen
					ret=[]
					for i in realorder
						ret.push(@party[i])
					end
					error=[]
					break
				else
					Kernel.pbMessage(_INTL("You need to choose at least one Pokémon to confirm."))
				end
			end
			if pkmnid<0 # Canceled
				break
			end
			cmdEntry=-1
			cmdNoEntry=-1
			cmdSummary=-1
			commands=[]
			if (statuses[pkmnid] || 0) == 1
				commands[cmdEntry=commands.length]=_INTL("Entry")
			elsif (statuses[pkmnid] || 0) > 2
				commands[cmdNoEntry=commands.length]=_INTL("No Entry")
			end
			pkmn=@party[pkmnid]
			commands[cmdSummary=commands.length]=_INTL("Info")
			commands[commands.length]=_INTL("Chiudi")
			command=@scene.pbShowCommands(_INTL("Che fare con {1}?",pkmn.name),commands,nil,0,pkmn) if pkmn
			if cmdEntry>=0 && command==cmdEntry
				if realorder.length>=number && number>0
					pbDisplay(_INTL("No more than {1} Pokémon may enter.",number))
				else
					statuses[pkmnid]=realorder.length+3
					addedEntry=true
					pbRefreshSingle(pkmnid)
				end
			elsif cmdNoEntry>=0 && command==cmdNoEntry
				statuses[pkmnid]=1
				pbRefreshSingle(pkmnid)
			elsif cmdSummary>=0 && command==cmdSummary
				@scene.pbSummary(pkmnid)
			end
		end
		@scene.pbEndScene
		return ret
	end
	
end


class PokeBattle_Scene
	def pbSwitch(index,lax,cancancel)
		party=@battle.pbParty(index)
		partypos=@battle.partyorder
		ret=-1
		# Fade out and hide all sprites
		visiblesprites=pbFadeOutAndHide(@sprites)
		pbShowWindow(BLANK)
		pbSetMessageMode(true)
		modparty=[]
		for i in 0...6
			modparty.push(party[partypos[i]]) if party[partypos[i]] != nil
		end
		scene=PokemonScreen_Scene.new
		@switchscreen=PokemonScreen.new(scene,modparty)
		@switchscreen.pbStartScene(_INTL("Choose a Pokémon."),
			@battle.doublebattle && !@battle.fullparty1)
		loop do
			scene.pbSetHelpText(_INTL("Choose a Pokémon."))
			activecmd=@switchscreen.pbChoosePokemon
			if cancancel && activecmd==-1
				ret=-1
				break
			end
			if activecmd>=0
				commands=[]
				cmdShift=-1
				cmdSummary=-1
				pkmnindex=partypos[activecmd]
				commands[cmdShift=commands.length]=_INTL("Switch In") if !party[pkmnindex].isEgg?
				commands[cmdSummary=commands.length]=_INTL("Summary")
				commands[commands.length]=_INTL("Cancel")
				command=scene.pbShowCommands(_INTL("Do what with {1}?",party[pkmnindex].name),commands,nil,0,party[pkmnindex])
				if cmdShift>=0 && command==cmdShift
					canswitch=lax ? @battle.pbCanSwitchLax?(index,pkmnindex,true) :
					@battle.pbCanSwitch?(index,pkmnindex,true)
					if canswitch
						ret=pkmnindex
						break
					end
				elsif cmdSummary>=0 && command==cmdSummary
					scene.pbSummary(activecmd)
				end
			end
		end
		@switchscreen.pbEndScene
		@switchscreen=nil
		pbShowWindow(BLANK)
		pbSetMessageMode(false)
		# back to main battle screen
		pbFadeInAndShow(@sprites,visiblesprites)
		return ret
	end
end



################################################################################
# Sprite utilities for pokemons in UI
################################################################################
def pbGetSpriteBase(bitmap)
	srcbitmap = Bitmap.new(bitmap.height,bitmap.height)
	srcbitmap.blt(0,0,bitmap,Rect.new(0,0,bitmap.height,bitmap.height))
	found = false
	ybase = 0
	for y in (0...bitmap.height).to_a.reverse
		for x in 0...bitmap.height
			found = true if srcbitmap.get_pixel(x,y).alpha != 0
			break if found
		end
		ybase = y if found
		break if found
	end
	return ybase
end
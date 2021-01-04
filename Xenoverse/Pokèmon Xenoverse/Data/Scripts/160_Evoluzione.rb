#===============================================================================
# ■ Evolution Scene by KleinStudio V1.0
#===============================================================================
class PokemonEvolutionScene
  private

  def pbGenerateMetafiles(s1x,s1y,s2x,s2y)
    sprite=SpriteMetafile.new
    sprite2=SpriteMetafile.new
    sprite.opacity=255
    sprite2.opacity=0
    sprite.ox=s1x
    sprite.oy=s1y
    sprite2.ox=s2x
    sprite2.oy=s2y
    for j in 0...26
      sprite.color.red=128
      sprite.color.green=0 
      sprite.color.blue=0
      sprite.color.alpha=j*10
      sprite.color=sprite.color
      sprite2.color=sprite.color
      sprite.update
      sprite2.update
    end
    anglechange=0
    sevenseconds=Graphics.frame_rate*7
    for j in 0...sevenseconds
      sprite.angle+=anglechange
      sprite.angle%=360
      anglechange+=1 if j%2==0
      if j>=sevenseconds-50
        sprite2.angle=sprite.angle
        sprite2.opacity+=6
      end
      sprite.update
      sprite2.update
    end
    sprite.angle=360-sprite.angle
    sprite2.angle=360-sprite2.angle
    for j in 0...sevenseconds
      sprite2.angle+=anglechange
      sprite2.angle%=360
      anglechange-=1 if j%2==0
      if j<50
        sprite.angle=sprite2.angle
        sprite.opacity-=6
      end
      sprite.update
      sprite2.update
    end
    for j in 0...26
      sprite2.color.red=128
      sprite2.color.green=0 
      sprite2.color.blue=0
      sprite2.color.alpha=(26-j)*10
      sprite2.color=sprite2.color
      sprite.color=sprite2.color
      sprite.update
      sprite2.update
    end
    @metafile1=sprite
    @metafile2=sprite2
  end

# Starts the evolution screen with the given Pokemon and new Pokemon species.
  public

  def pbStartScreen(pokemon,newspecies)
    @sprites={}
    
    @bgviewport=Viewport.new(0,0,Graphics.width,DEFAULTSCREENHEIGHT)
    @bgviewport.z=99999
    
    @viewport=Viewport.new(0,0,Graphics.width,DEFAULTSCREENHEIGHT)
    @viewport.z=99999
    
    @viewports=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewports.z=999999

    @pokemon=pokemon
    @newspecies=newspecies
    @evoanimfinished=false
       
    @sprites["bg"]=Sprite.new(@bgviewport)
    @sprites["bg"].bitmap=BitmapCache.load_bitmap("Graphics/Pictures/evolutionbg")

    rsprite1=PokemonSprite.new(@viewport)
    rsprite2=PokemonSprite.new(@viewport)

    rsprite1.setPokemonBitmap(@pokemon,false)
    rsprite1.ox=rsprite1.bitmap.width/2
    rsprite1.oy=rsprite1.bitmap.height/2
    rsprite1.x=DEFAULTSCREENWIDTH/2
    rsprite1.y=DEFAULTSCREENHEIGHT/2

    rsprite2.setPokemonBitmapSpecies(@pokemon,@newspecies,false)
    rsprite2.ox=rsprite2.bitmap.width/2
    rsprite2.oy=rsprite2.bitmap.height/2
    rsprite2.tone=Tone.new(255,255,255,0)
    rsprite2.x=DEFAULTSCREENWIDTH/2
    rsprite2.y=DEFAULTSCREENHEIGHT/2
    rsprite2.zoom_x=0
    rsprite2.zoom_y=0

    @sprites["rsprite1"]=rsprite1
    @sprites["rsprite2"]=rsprite2
    @sprites["msgwindow"]=Kernel.pbCreateMessageWindow(@viewport)
    pbFadeInAndShow(@sprites)
  end

  def closeViewport(vel=4)
    while @bgviewport.rect.y<110
      Graphics.update
      @bgviewport.rect.y+=1*vel
      @bgviewport.rect.height-=2*vel
      @sprites["bg"].y=-@bgviewport.rect.y
    end
  end
  
  def openViewport(vel=4)
    while @bgviewport.rect.y>0
      @bgviewport.rect.y-=1*vel
      @bgviewport.rect.height+=2*vel
      @sprites["bg"].y=-@bgviewport.rect.y
    end
  end
  
  def evoAnimHelper(more, vel)
    return if @makeCancel
    poke1=@sprites["rsprite1"]
    poke2=@sprites["rsprite2"]
  if !more
    loop do
      break if @makeCancel
      pbUpdate
      poke1.zoom_x-=vel
      poke1.zoom_y-=vel
      poke1.zoom_x=0 if poke1.zoom_x<0
      poke1.zoom_y=0 if poke1.zoom_y<0

      poke2.zoom_x+=vel
      poke2.zoom_y+=vel
      poke2.zoom_x=1 if poke2.zoom_x>1
      poke2.zoom_y=1 if poke2.zoom_y>1
      break if poke2.zoom_x==1 && poke1.zoom_x==0
    end
  else
    loop do
      break if @makeCancel
      pbUpdate
      poke2.zoom_x-=vel
      poke2.zoom_y-=vel
      poke2.zoom_x=0 if poke2.zoom_x<0
      poke2.zoom_y=0 if poke2.zoom_y<0

      poke1.zoom_x+=vel
      poke1.zoom_y+=vel
      poke1.zoom_x=1 if poke1.zoom_x>1
      poke1.zoom_y=1 if poke1.zoom_y>1
      break if poke1.zoom_x==1 && poke2.zoom_x==0
    end
  end
end

  def evoAnimation
    poke1=@sprites["rsprite1"]
    poke2=@sprites["rsprite2"]
    fcolor=0
    tonescreen=0
    
    loop do
      pbUpdate
      fcolor+=10 if fcolor < 255
      poke1.tone=Tone.new(fcolor,fcolor,fcolor,0)
      break if fcolor>=255
    end  
    
    evoAnimHelper(false,0.025)
    evoAnimHelper(true,0.025)
    evoAnimHelper(false,0.05)
    evoAnimHelper(true,0.05)
    evoAnimHelper(false,0.05)
    evoAnimHelper(true,0.1)
    evoAnimHelper(false,0.1)
    evoAnimHelper(true,0.1)
    evoAnimHelper(false,0.1)
    evoAnimHelper(true,0.1)
    evoAnimHelper(false,0.1)
    evoAnimHelper(true,0.1)
    evoAnimHelper(false,0.1)
    evoAnimHelper(true,0.1)
    evoAnimHelper(false,0.1)
    evoAnimHelper(true,0.2)
    evoAnimHelper(false,0.2)
    evoAnimHelper(true,0.2)
    evoAnimHelper(false,0.2)
    evoAnimHelper(true,0.3)
    evoAnimHelper(false,0.3)
    evoAnimHelper(true,0.3)
    evoAnimHelper(false,0.3)
    evoAnimHelper(true,0.3)
    evoAnimHelper(false,0.3)
    evoAnimHelper(true,0.3)
    evoAnimHelper(false,0.3)
    evoAnimHelper(true,0.3)
    evoAnimHelper(false,0.3)
    evoAnimHelper(true,0.3)
    evoAnimHelper(false,0.4)
    evoAnimHelper(true,0.4)
    evoAnimHelper(false,0.4)
    evoAnimHelper(true,0.4)
    evoAnimHelper(false,0.4)
    evoAnimHelper(true,0.4)
    evoAnimHelper(false,0.4)
    evoAnimHelper(true,0.4)
    evoAnimHelper(false,0.4)
    evoAnimHelper(true,0.4)
    evoAnimHelper(false,0.4)
    evoAnimHelper(true,0.4)
    evoAnimHelper(false,0.4)
    evoAnimHelper(true,0.4)
    evoAnimHelper(false,0.4)
    evoAnimHelper(true,0.4)
    evoAnimHelper(false,0.4)
    evoAnimHelper(true,0.4)
    evoAnimHelper(false,0.4)
    evoAnimHelper(true,0.4)
    evoAnimHelper(false,0.4)

    loop do
      pbUpdate
      tonescreen+=10*2 if tonescreen < 255
      @viewports.tone.set(tonescreen,tonescreen,tonescreen,0)
      break if tonescreen>=255
    end  
    pbWait(10)
    openViewport
    loop do
      pbUpdate
      poke2.tone=Tone.new(0,0,0,0) if !@makeCancel
      if @makeCancel
        poke2.visible=false
        poke1.zoom_x=1
        poke1.zoom_y=1
        poke1.tone=Tone.new(0,0,0,0)
      end
      tonescreen-=5*2 if tonescreen > 0
      @viewports.tone.set(tonescreen,tonescreen,tonescreen,0)
      break if tonescreen<=0
    end  

    @evoanimfinished=true
  end
# Closes the evolution screen.
  def pbEndScreen
    Kernel.pbDisposeMessageWindow(@sprites["msgwindow"])
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
    @viewports.dispose
    @bgviewport.dispose
  end

  def pbUpdate
    Graphics.update
    Input.update
    pbUpdateSpriteHash(@sprites)
    
    if Input.trigger?(Input::B)
      @makeCancel=true
    end
  end
  
# Opens the evolution screen
  def pbEvolution(cancancel=true)
    metaplayer1=SpriteMetafilePlayer.new(@metafile1,@sprites["rsprite1"])
    metaplayer2=SpriteMetafilePlayer.new(@metafile2,@sprites["rsprite2"])
    metaplayer1.play
    metaplayer2.play
    pbBGMStop()
    pbPlayCry(@pokemon)
    Kernel.pbMessageDisplay(@sprites["msgwindow"],
       _INTL("\\se[]What?\r\n{1} is evolving!\\^",@pokemon.name))
    Kernel.pbMessageWaitForInput(@sprites["msgwindow"],100,true)
    pbPlayDecisionSE()
    closeViewport
    oldstate=pbSaveSpriteState(@sprites["rsprite1"])
    oldstate2=pbSaveSpriteState(@sprites["rsprite2"])
    pbBGMPlay("evolv")
    canceled=false
    evoAnimation

  if @evoanimfinished
    if canceled || @makeCancel
      pbBGMStop()
      pbPlayCancelSE()
      Kernel.pbMessageDisplay(@sprites["msgwindow"],
         _INTL("Huh?\r\n{1} stopped evolving!",@pokemon.name))
       else
      frames=pbCryFrameLength(@newspecies)
      pbBGMStop()
      pbPlayCry(@newspecies)
      frames.times do
        pbUpdate
      end
      pbMEPlay("004-Victory04")
      newspeciesname=PBSpecies.getName(@newspecies)
      oldspeciesname=PBSpecies.getName(@pokemon.species)
      Kernel.pbMessageDisplay(@sprites["msgwindow"],
         _INTL("\\se[]Congratulations!  Your {1} evolved into {2}!\\wt[80]",@pokemon.name,newspeciesname))
      @sprites["msgwindow"].text=""
      removeItem=false
      createSpecies=pbCheckEvolutionEx(@pokemon){|pokemon,evonib,level,poke|
         if evonib==PBEvolution::Shedinja
           if $PokemonBag.pbQuantity(getConst(PBItems,:POKEBALL))>0
             next poke
           end
           next -1
         elsif evonib==PBEvolution::TradeItem ||
               evonib==PBEvolution::DayHoldItem ||
               evonib==PBEvolution::NightHoldItem
           if poke==@newspecies
             removeItem=true  # Item is now consumed
           end
           next -1
         else
           next -1
         end
      }
      @pokemon.setItem(0) if removeItem
      @pokemon.species=@newspecies
      $Trainer.seen[@newspecies]=true
      $Trainer.owned[@newspecies]=true
      pbSeenForm(@pokemon)
      @pokemon.firstmoves=[]
      @pokemon.name=newspeciesname if @pokemon.name==oldspeciesname
      @pokemon.calcStats
      # Check moves for new species
      movelist=@pokemon.getMoveList
      for i in movelist
        if i[0]==@pokemon.level          # Learned a new move
          pbLearnMove(@pokemon,i[1],true)
        end
      end
      if createSpecies>0 && $Trainer.party.length<6
        newpokemon=@pokemon.clone
        newpokemon.iv=@pokemon.iv.clone
        newpokemon.ev=@pokemon.ev.clone
        newpokemon.species=createSpecies
        newpokemon.name=PBSpecies.getName(createSpecies)
        newpokemon.setItem(0)
        newpokemon.clearAllRibbons
        newpokemon.markings=0
        newpokemon.ballused=0
        newpokemon.calcStats
        newpokemon.heal
        $Trainer.party.push(newpokemon)
        $Trainer.seen[createSpecies]=true
        $Trainer.owned[createSpecies]=true
        pbSeenForm(newpokemon)
        $PokemonBag.pbDeleteItem(getConst(PBItems,:POKEBALL))
        end
      end
    end
  end
end
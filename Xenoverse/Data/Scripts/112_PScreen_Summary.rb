class MoveSelectionSprite < SpriteWrapper
  attr_reader :preselected
  attr_reader :index

  def initialize(viewport=nil,fifthmove=false)
    super(viewport)
    @movesel=AnimatedBitmap.new("Graphics/Pictures/summarymovesel")
    @frame=0
    @index=0
    @fifthmove=fifthmove
    @preselected=false
    @updating=false
    @spriteVisible=true
    refresh
  end

  def dispose
    @movesel.dispose
    super
  end

  def index=(value)
    @index=value
    refresh
  end

  def preselected=(value)
    @preselected=value
    refresh
  end

  def visible=(value)
    super
    @spriteVisible=value if !@updating
  end

  def refresh
    w=@movesel.width
    h=@movesel.height/2
    self.x=240
    self.y=92+(self.index*64)
    self.y-=76 if @fifthmove
    self.y+=20 if @fifthmove && self.index==4
    self.bitmap=@movesel.bitmap
    if self.preselected
      self.src_rect.set(0,h,w,h)
    else
      self.src_rect.set(0,0,w,h)
    end
  end

  def update
    @updating=true
    super
    @movesel.update
    @updating=false
    refresh
  end
end



class PokemonSummaryScene
  def pbPokerus(pkmn)
    return pkmn.pokerusStage
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(party,partyindex)
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=140000
    @party=party
    @partyindex=partyindex
    @pokemon=@party[@partyindex]
    @sprites={}
    @typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    @sprites["background"]=IconSprite.new(0,0,@viewport)
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["pokemon"]=PokemonSprite.new(@viewport)
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokemon"].mirror=false
    @sprites["pokemon"].color=Color.new(0,0,0,0)
    pbPositionPokemonSprite(@sprites["pokemon"],40,144)
    @sprites["pokeicon"]=PokemonBoxIcon.new(@pokemon,@viewport)
    @sprites["pokeicon"].x=14
    @sprites["pokeicon"].y=52
    @sprites["pokeicon"].mirror=false
    @sprites["pokeicon"].visible=false
    @sprites["movepresel"]=MoveSelectionSprite.new(@viewport)
    @sprites["movepresel"].visible=false
    @sprites["movepresel"].preselected=true
    @sprites["movesel"]=MoveSelectionSprite.new(@viewport)
    @sprites["movesel"].visible=false
    @page=0
    drawPageOne(@pokemon)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartForgetScene(party,partyindex,moveToLearn)
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=100000
    @party=party
    @partyindex=partyindex
    @pokemon=@party[@partyindex]
    @sprites={}
    @page=3
    @typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    @sprites["background"]=IconSprite.new(0,0,@viewport)
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["pokeicon"]=PokemonBoxIcon.new(@pokemon,@viewport)
    @sprites["pokeicon"].x=14
    @sprites["pokeicon"].y=52
    @sprites["pokeicon"].mirror=false
    @sprites["movesel"]=MoveSelectionSprite.new(@viewport,moveToLearn>0)
    @sprites["movesel"].visible=false
    @sprites["movesel"].visible=true
    @sprites["movesel"].index=0
    drawSelectedMove(@pokemon,moveToLearn,@pokemon.moves[0].id)
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @viewport.dispose
  end

  def drawMarkings(bitmap,x,y,width,height,markings)
    totaltext=""
    oldfontname=bitmap.font.name
    oldfontsize=bitmap.font.size
    oldfontcolor=bitmap.font.color
    bitmap.font.size=24
    bitmap.font.name="Arial"
    PokemonStorage::MARKINGCHARS.each{|item| totaltext+=item }
    totalsize=bitmap.text_size(totaltext)
    realX=x+(width/2)-(totalsize.width/2)
    realY=y+(height/2)-(totalsize.height/2)
    i=0
    PokemonStorage::MARKINGCHARS.each{|item|
       marked=(markings&(1<<i))!=0
       bitmap.font.color=(marked) ? Color.new(72,64,56) : Color.new(184,184,160)
       itemwidth=bitmap.text_size(item).width
       bitmap.draw_text(realX,realY,itemwidth+2,totalsize.height,item)
       realX+=itemwidth
       i+=1
    }
    bitmap.font.name=oldfontname
    bitmap.font.size=oldfontsize
    bitmap.font.color=oldfontcolor
  end

  def drawPageOne(pokemon)
		echoln("Disegno pagina")
    if pokemon.isEgg?
      drawPageOneEgg(pokemon)
      return
    end
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/Pictures/summary1")
    imagepos=[]
    if pbPokerus(pokemon)==1 || pokemon.hp==0 || @pokemon.status>0
      status=6 if pbPokerus(pokemon)==1
      status=@pokemon.status-1 if @pokemon.status>0
      status=5 if pokemon.hp==0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    if pokemon.isShiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])
    end
    if isConst?(pokemon.species,PBSpecies,:ELEKIDX)
      imagepos.push([sprintf("Graphics/Pictures/delta"),0,130,0,0,-1,-1])
    end
    if isConst?(pokemon.species,PBSpecies,:DELTASHARPEDO)
      imagepos.push([sprintf("Graphics/Pictures/delta"),0,130,0,0,-1,-1])
    end
    if pbPokerus(pokemon)==2
      imagepos.push([sprintf("Graphics/Pictures/summaryPokerus"),176,100,0,0,-1,-1])
    end
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/Pictures/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    if (pokemon.isShadow? rescue false)
      imagepos.push(["Graphics/Pictures/summaryShadow",224,240,0,0,-1,-1])
      shadowfract=pokemon.heartgauge*1.0/PokeBattle_Pokemon::HEARTGAUGESIZE
      imagepos.push(["Graphics/Pictures/summaryShadowBar",242,280,0,0,(shadowfract*248).floor,-1])
    end
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,255)
    shadow=Color.new(104,104,104)
    pbSetSystemFont(overlay)
    numberbase=(pokemon.isShiny?) ? Color.new(248,56,32) : Color.new(64,64,64)
    numbershadow=(pokemon.isShiny?) ? Color.new(224,152,144) : Color.new(176,176,176)
    publicID=pokemon.publicID
    speciesname=PBSpecies.getName(pokemon.species)
    itemname=pokemon.hasItem? ? PBItems.getName(pokemon.item) : _INTL("None")
    growthrate=pokemon.growthrate
    startexp=PBExperience.pbGetStartExperience(pokemon.level,growthrate)
    endexp=PBExperience.pbGetStartExperience(pokemon.level+1,growthrate)
    pokename=@pokemon.name
    textpos=[
       [_INTL("INFO"),26,16,0,base,shadow],
       [pokename,46,62,0,base,shadow],
       [pokemon.level.to_s,46,92,0,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("Oggetto"),16,320,0,base,shadow],
       [itemname,16,352,0,Color.new(248,248,255),Color.new(104,104,104)],
       [_ISPRINTF("Dex Num."),238,80,0,base,shadow],
       [sprintf("%03d",pokemon.species),435,80,2,base,shadow],
       [_INTL("Specie"),238,112,0,base,shadow],
       [speciesname,435,112,2,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("Tipo"),238,144,0,base,shadow],
       [_INTL("OT"),238,176,0,base,shadow],
       [_INTL("ID Num."),238,208,0,base,shadow],
    ]
    if (pokemon.isShadow? rescue false)
      textpos.push([_INTL("Heart Gauge"),238,240,0,base,shadow])
      heartmessage=[_INTL("The door to its heart is open! Undo the final lock!"),
                    _INTL("The door to its heart is almost fully open."),
                    _INTL("The door to its heart is nearly open."),
                    _INTL("The door to its heart is opening wider."),
                    _INTL("The door to its heart is opening up."),
                    _INTL("The door to its heart is tightly shut.")
                    ][pokemon.heartStage]
      memo=sprintf("<c3=404040,B0B0B0>%s\n",heartmessage)
      drawFormattedTextEx(overlay,238,304,276,memo)
    else
      textpos.push([_INTL("Punti Exp."),238,240,0,base,shadow])
      textpos.push([sprintf("%d",pokemon.exp),488,272,1,Color.new(248,248,255),Color.new(104,104,104)])
      textpos.push([_INTL("Al prossimo Lv."),238,304,0,base,shadow])
      textpos.push([sprintf("%d",endexp-pokemon.exp),488,336,1,Color.new(248,248,255),Color.new(104,104,104)])
    end
    idno=(pokemon.ot=="") ? "?????" : sprintf("%05d",publicID)
    textpos.push([idno,435,208,2,Color.new(248,248,255),Color.new(104,104,104)])
    if pokemon.ot==""
      textpos.push([_INTL("RENTAL"),435,176,2,Color.new(255,215,0),Color.new(255,215,0)])
    else
      ownerbase=Color.new(64,64,64)
      ownershadow=Color.new(176,176,176)
      if pokemon.otgender==0 # male OT
        ownerbase=Color.new(255,215,0)
        ownershadow=Color.new(104,104,104)
      elsif pokemon.otgender==1 # female OT
        ownerbase=Color.new(255,215,0)
        ownershadow=Color.new(104,104,104)
      end
      textpos.push([pokemon.ot,435,176,2,ownerbase,ownershadow])
    end
    if pokemon.isMale?
      textpos.push([_INTL("♂"),178,62,0,Color.new(24,112,216),Color.new(136,168,208)])
    elsif pokemon.isFemale?
      textpos.push([_INTL("♀"),178,62,0,Color.new(248,56,32),Color.new(224,152,144)])
    end
    pbDrawTextPositions(overlay,textpos)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
    type1rect=Rect.new(0,pokemon.type1*28,64,28)
    type2rect=Rect.new(0,pokemon.type2*28,64,28)
    if pokemon.type1==pokemon.type2
      overlay.blt(402,146,@typebitmap.bitmap,type1rect)
    else
      overlay.blt(370,146,@typebitmap.bitmap,type1rect)
      overlay.blt(436,146,@typebitmap.bitmap,type2rect)
    end
    if pokemon.level<PBExperience::MAXLEVEL
      overlay.fill_rect(362,372,(pokemon.exp-startexp)*128/(endexp-startexp),2,Color.new(72,120,160))
      overlay.fill_rect(362,374,(pokemon.exp-startexp)*128/(endexp-startexp),4,Color.new(24,144,248))
    end
  end

  def drawPageOneEgg(pokemon)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/Pictures/summaryEgg")
    imagepos=[]
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/Pictures/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    pbSetSystemFont(overlay)
    itemname=pokemon.hasItem? ? PBItems.getName(pokemon.item) : _INTL("None")
    textpos=[
       [_INTL("TRAINER MEMO"),26,16,0,base,shadow],
       [pokemon.name,46,62,0,base,shadow],
       [_INTL("Item"),16,320,0,base,shadow],
       [itemname,16,352,0,Color.new(64,64,64),Color.new(176,176,176)],
    ]
    pbDrawTextPositions(overlay,textpos)
    memo=""
    if pokemon.timeReceived
      month=pbGetAbbrevMonthName(pokemon.timeReceived.mon)
      date=pokemon.timeReceived.day
      year=pokemon.timeReceived.year
      memo+=_INTL("<c3=F8F8F8,686868>{1} {2}, {3}\n",month,date,year)
    end
    mapname=pbGetMapNameFromId(pokemon.obtainMap)
    if (pokemon.obtainText rescue false) && pokemon.obtainText!=""
      mapname=pokemon.obtainText
    end
    if mapname && mapname!=""
      memo+=_INTL("<c3=F8F8F8,686868>A mysterious Pokémon Egg received from <c3=F8F8F8,686868>{1}<c3=F8F8F8,686868>.\n",mapname)
    end
    memo+="<c3=F8F8F8,686868>\n"
    memo+=_INTL("<c3=F8F8F8,686868>\"The Egg Watch\"\n")
    eggstate=_INTL("It looks like this Egg will take a long time to hatch.")
    eggstate=_INTL("What will hatch from this?  It doesn't seem close to hatching.") if pokemon.eggsteps<10200
    eggstate=_INTL("It appears to move occasionally.  It may be close to hatching.") if pokemon.eggsteps<2550
    eggstate=_INTL("Sounds can be heard coming from inside!  It will hatch soon!") if pokemon.eggsteps<1275
    memo+=sprintf("<c3=F8F8F8,686868>%s\n",eggstate)
    drawFormattedTextEx(overlay,232,78,276,memo)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
  end

  def drawPageTwo(pokemon)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/Pictures/summary2")
    imagepos=[]
    if pbPokerus(pokemon)==1 || pokemon.hp==0 || @pokemon.status>0
      status=6 if pbPokerus(pokemon)==1
      status=@pokemon.status-1 if @pokemon.status>0
      status=5 if pokemon.hp==0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    if pokemon.isShiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])
    end
    if isConst?(pokemon.species,PBSpecies,:ELEKIDX)
      imagepos.push([sprintf("Graphics/Pictures/delta"),0,130,0,0,-1,-1])
    end
    if isConst?(pokemon.species,PBSpecies,:DELTASHARPEDO)
      imagepos.push([sprintf("Graphics/Pictures/delta"),0,130,0,0,-1,-1])
    end
    if pbPokerus(pokemon)==2
      imagepos.push([sprintf("Graphics/Pictures/summaryPokerus"),176,100,0,0,-1,-1])
    end
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/Pictures/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,255)
    shadow=Color.new(104,104,104)
    pbSetSystemFont(overlay)
    naturename=PBNatures.getName(pokemon.nature)
    itemname=pokemon.hasItem? ? PBItems.getName(pokemon.item) : _INTL("None")
    pokename=@pokemon.name
    textpos=[
       [_INTL("TRAINER MEMO"),26,16,0,base,shadow],
       [pokename,46,62,0,base,shadow],
       [pokemon.level.to_s,46,92,0,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("Item"),16,320,0,base,shadow],
       [itemname,16,352,0,Color.new(248,248,255),Color.new(104,104,104)],
    ]
    if pokemon.isMale?
      textpos.push([_INTL("♂"),178,62,0,Color.new(24,112,216),Color.new(136,168,208)])
    elsif pokemon.isFemale?
      textpos.push([_INTL("♀"),178,62,0,Color.new(248,56,32),Color.new(224,152,144)])
    end
    pbDrawTextPositions(overlay,textpos)
    memo=""
    shownature=(!(pokemon.isShadow? rescue false)) || pokemon.heartStage<=3
    if shownature
      memo+=_INTL("<c3=ee5439,404040>{1}\n",naturename)
    end
    if pokemon.timeReceived
      month=pbGetAbbrevMonthName(pokemon.timeReceived.mon)
      date=pokemon.timeReceived.day
      year=pokemon.timeReceived.year
      memo+=_INTL("<c3=FFFFFF,404040>{1} {2}, {3}\n",month,date,year)
    end
    mapname=pbGetMapNameFromId(pokemon.obtainMap)
    if (pokemon.obtainText rescue false) && pokemon.obtainText!=""
      mapname=pokemon.obtainText
    end
    if mapname && mapname!=""
      memo+=sprintf("<c3=ee5439,404040>%s\n",mapname)
    else
      memo+=_INTL("<c3=FFFFFF,404040>Faraway place\n")
    end
    if pokemon.obtainMode
      mettext=[_INTL("Met at Lv. {1}.",pokemon.obtainLevel),
               _INTL("Egg received."),
               _INTL("Traded at Lv. {1}.",pokemon.obtainLevel),
               "",
               _INTL("Had a fateful encounter at Lv. {1}.",pokemon.obtainLevel)
               ][pokemon.obtainMode]
      memo+=sprintf("<c3=FFFFFF,404040>%s\n",mettext)
      if pokemon.obtainMode==1 # hatched
        if pokemon.timeEggHatched
          month=pbGetAbbrevMonthName(pokemon.timeEggHatched.mon)
          date=pokemon.timeEggHatched.day
          year=pokemon.timeEggHatched.year
          memo+=_INTL("<c3=404040,B0B0B0>{1} {2}, {3}\n",month,date,year)
        end
        mapname=pbGetMapNameFromId(pokemon.hatchedMap)
        if mapname && mapname!=""
          memo+=sprintf("<c3=ee5439,404040>%s\n",mapname)
        else
          memo+=_INTL("<c3=ee5439,404040>Faraway place\n")
        end
        memo+=_INTL("<c3=FFFFFF,404040>Egg hatched.\n")
      else
        memo+="<c3=FFFFFF,404040>\n"
      end
    end
    if shownature
      bestiv=0
      tiebreaker=pokemon.personalID%6
      for i in 0...6
        if pokemon.iv[i]==pokemon.iv[bestiv]
          bestiv=i if i>=tiebreaker && bestiv<tiebreaker
        elsif pokemon.iv[i]>pokemon.iv[bestiv]
          bestiv=i
        end
      end
      characteristic=[_INTL("Loves to eat."),
                      _INTL("Often dozes off."),
                      _INTL("Often scatters things."),
                      _INTL("Scatters things often."),
                      _INTL("Likes to relax."),
                      _INTL("Proud of its power."),
                      _INTL("Likes to thrash about."),
                      _INTL("A little quick tempered."),
                      _INTL("Likes to fight."),
                      _INTL("Quick tempered."),
                      _INTL("Sturdy body."),
                      _INTL("Capable of taking hits."),
                      _INTL("Highly persistent."),
                      _INTL("Good endurance."),
                      _INTL("Good perseverance."),
                      _INTL("Likes to run."),
                      _INTL("Alert to sounds."),
                      _INTL("Impetuous and silly."),
                      _INTL("Somewhat of a clown."),
                      _INTL("Quick to flee."),
                      _INTL("Highly curious."),
                      _INTL("Mischievous."),
                      _INTL("Thoroughly cunning."),
                      _INTL("Often lost in thought."),
                      _INTL("Very finicky."),
                      _INTL("Strong willed."),
                      _INTL("Somewhat vain."),
                      _INTL("Strongly defiant."),
                      _INTL("Hates to lose."),
                      _INTL("Somewhat stubborn.")
                      ][bestiv*5+pokemon.iv[bestiv]%5]
      memo+=sprintf("<c3=FFFFFF,404040>%s\n",characteristic)
    end
    drawFormattedTextEx(overlay,232,78,276,memo)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
  end

  def drawPageThree(pokemon)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/Pictures/summary3")
    imagepos=[]
    if pbPokerus(pokemon)==1 || pokemon.hp==0 || @pokemon.status>0
      status=6 if pbPokerus(pokemon)==1
      status=@pokemon.status-1 if @pokemon.status>0
      status=5 if pokemon.hp==0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    if pokemon.isShiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])
    end
    if isXSpecies?(pokemon.species)
      imagepos.push([sprintf("Graphics/Pictures/delta"),0,130,0,0,-1,-1])
    end
    if pbPokerus(pokemon)==2
      imagepos.push([sprintf("Graphics/Pictures/summaryPokerus"),176,100,0,0,-1,-1])
    end
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/Pictures/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    statshadows=[]
    for i in 0...5; statshadows[i]=shadow; end
    if !(pokemon.isShadow? rescue false) || pokemon.heartStage<=3
      natup=(pokemon.nature/5).floor
      natdn=(pokemon.nature%5).floor
      statshadows[natup]=Color.new(136,96,72) if natup!=natdn
      statshadows[natdn]=Color.new(64,120,152) if natup!=natdn
    end
    pbSetSystemFont(overlay)
    abilityname=PBAbilities.getName(pokemon.ability)
    abilitydesc=pbGetMessage(MessageTypes::AbilityDescs,pokemon.ability)
    itemname=pokemon.hasItem? ? PBItems.getName(pokemon.item) : _INTL("None")
    pokename=@pokemon.name
    textpos=[
       [_INTL("SKILLS"),26,16,0,base,shadow],
       [pokename,46,62,0,base,shadow],
       [pokemon.level.to_s,46,92,0,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("Item"),16,320,0,base,shadow],
       [itemname,16,352,0,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("HP"),292,76,2,base,shadow],
       [sprintf("%3d/%3d",pokemon.hp,pokemon.totalhp),462,76,1,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("Attack"),248,120,0,base,statshadows[0]],
       [sprintf("%d",pokemon.attack),456,120,1,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("Defense"),248,152,0,base,statshadows[1]],
       [sprintf("%d",pokemon.defense),456,152,1,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("Sp. Atk"),248,184,0,base,statshadows[3]],
       [sprintf("%d",pokemon.spatk),456,184,1,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("Sp. Def"),248,216,0,base,statshadows[4]],
       [sprintf("%d",pokemon.spdef),456,216,1,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("Speed"),248,248,0,base,statshadows[2]],
       [sprintf("%d",pokemon.speed),456,248,1,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("Ability"),224,284,0,base,shadow],
       [abilityname,362,284,0,Color.new(248,248,255),Color.new(104,104,104)],
    ]
    if pokemon.isMale?
      textpos.push([_INTL("♂"),178,62,0,Color.new(24,112,216),Color.new(136,168,208)])
    elsif pokemon.isFemale?
      textpos.push([_INTL("♀"),178,62,0,Color.new(248,56,32),Color.new(224,152,144)])
    end
    pbDrawTextPositions(overlay,textpos)
    drawTextEx(overlay,224,316,282,2,abilitydesc,Color.new(248,248,255),Color.new(104,104,104))
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
    if pokemon.hp>0
      hpcolors=[
         Color.new(24,192,32),Color.new(0,144,0),     # Green
         Color.new(248,184,0),Color.new(184,112,0),   # Orange
         Color.new(240,80,32),Color.new(168,48,56)    # Red
      ]
      hpzone=0
      hpzone=1 if pokemon.hp<=(@pokemon.totalhp/2).floor
      hpzone=2 if pokemon.hp<=(@pokemon.totalhp/4).floor
      overlay.fill_rect(360,110,pokemon.hp*96/pokemon.totalhp,2,hpcolors[hpzone*2+1])
      overlay.fill_rect(360,112,pokemon.hp*96/pokemon.totalhp,4,hpcolors[hpzone*2])
    end
  end

  def drawPageFour(pokemon)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/Pictures/summary4")
    @sprites["pokemon"].visible=true
    @sprites["pokeicon"].visible=false
    imagepos=[]
    if pbPokerus(pokemon)==1 || pokemon.hp==0 || @pokemon.status>0
      status=6 if pbPokerus(pokemon)==1
      status=@pokemon.status-1 if @pokemon.status>0
      status=5 if pokemon.hp==0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    if pokemon.isShiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])
    end
    if isConst?(pokemon.species,PBSpecies,:ELEKIDX)
      imagepos.push([sprintf("Graphics/Pictures/delta"),0,130,0,0,-1,-1])
    end
    if isConst?(pokemon.species,PBSpecies,:DELTASHARPEDO)
      imagepos.push([sprintf("Graphics/Pictures/delta"),0,130,0,0,-1,-1])
    end
    if pbPokerus(pokemon)==2
      imagepos.push([sprintf("Graphics/Pictures/summaryPokerus"),176,100,0,0,-1,-1])
    end
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/Pictures/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    pbSetSystemFont(overlay)
    itemname=pokemon.hasItem? ? PBItems.getName(pokemon.item) : _INTL("None")
    pokename=@pokemon.name
    textpos=[
       [_INTL("MOVES"),26,16,0,base,shadow],
       [pokename,46,62,0,base,shadow],
       [pokemon.level.to_s,46,92,0,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("Item"),16,320,0,base,shadow],
       [itemname,16,352,0,Color.new(248,248,255),Color.new(104,104,104)],
    ]
    if pokemon.isMale?
      textpos.push([_INTL("♂"),178,62,0,Color.new(24,112,216),Color.new(136,168,208)])
    elsif pokemon.isFemale?
      textpos.push([_INTL("♀"),178,62,0,Color.new(248,56,32),Color.new(224,152,144)])
    end
    pbDrawTextPositions(overlay,textpos)
    imagepos=[]
    yPos=98
    for i in 0...pokemon.moves.length
      if pokemon.moves[i].id>0
        imagepos.push(["Graphics/Pictures/types",248,yPos+2,0,
           pokemon.moves[i].type*28,64,28])
        textpos.push([PBMoves.getName(pokemon.moves[i].id),316,yPos,0,
           Color.new(248,248,255),Color.new(104,104,104)])
        if pokemon.moves[i].totalpp>0
          textpos.push([_ISPRINTF("PP"),342,yPos+32,0,
             Color.new(248,248,255),Color.new(104,104,104)])
          textpos.push([sprintf("%d/%d",pokemon.moves[i].pp,pokemon.moves[i].totalpp),
             460,yPos+32,1,Color.new(248,248,255),Color.new(104,104,104)])
        end
      else
        textpos.push(["-",316,yPos,0,Color.new(248,248,255),Color.new(104,104,104)])
        textpos.push(["--",442,yPos+32,1,Color.new(248,248,255),Color.new(104,104,104)])
      end
      yPos+=64
    end
    pbDrawTextPositions(overlay,textpos)
    pbDrawImagePositions(overlay,imagepos)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
  end

  def drawSelectedMove(pokemon,moveToLearn,moveid)
    overlay=@sprites["overlay"].bitmap
    @sprites["pokemon"].visible=false if @sprites["pokemon"]
    @sprites["pokeicon"].setBitmap(pbPokemonIconFile(pokemon))
    @sprites["pokeicon"].src_rect=Rect.new(0,0,64,64)
    @sprites["pokeicon"].visible=true
    movedata=PBMoveData.new(moveid)
    basedamage=movedata.basedamage
    type=movedata.type
    category=movedata.category
    accuracy=movedata.accuracy
    drawMoveSelection(pokemon,moveToLearn)
    pbSetSystemFont(overlay)
    move=moveid
    textpos=[
       [basedamage<=1 ? basedamage==1 ? "???" : "---" : sprintf("%d",basedamage),
          216,154,1,Color.new(248,248,255),Color.new(104,104,104)],
       [accuracy==0 ? "---" : sprintf("%d",accuracy),
          216,186,1,Color.new(248,248,255),Color.new(104,104,104)]
    ]
    pbDrawTextPositions(overlay,textpos)
    imagepos=[["Graphics/Pictures/category",166,124,0,category*28,64,28]]
    pbDrawImagePositions(overlay,imagepos)
    drawTextEx(overlay,4,218,238,5,
       pbGetMessage(MessageTypes::MoveDescriptions,moveid),
       Color.new(248,248,255),Color.new(104,104,104))
  end

  def drawMoveSelection(pokemon,moveToLearn)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    @sprites["background"].setBitmap("Graphics/Pictures/summary4details")
    if moveToLearn!=0
      @sprites["background"].setBitmap("Graphics/Pictures/summary4learning")
    end
    pbSetSystemFont(overlay)
    textpos=[
       [_INTL("MOVES"),26,16,0,base,shadow],
       [_INTL("CATEGORY"),20,122,0,base,shadow],
       [_INTL("POWER"),20,154,0,base,shadow],
       [_INTL("ACCURACY"),20,186,0,base,shadow]
    ]
    type1rect=Rect.new(0,pokemon.type1*28,64,28)
    type2rect=Rect.new(0,pokemon.type2*28,64,28)
    if pokemon.type1==pokemon.type2
      overlay.blt(130,78,@typebitmap.bitmap,type1rect)
    else
      overlay.blt(96,78,@typebitmap.bitmap,type1rect)
      overlay.blt(166,78,@typebitmap.bitmap,type2rect)
    end
    imagepos=[]
    yPos=98
    yPos-=76 if moveToLearn!=0
    for i in 0...5
      moveobject=nil
      if i==4
        moveobject=PBMove.new(moveToLearn) if moveToLearn!=0
        yPos+=20
      else
        moveobject=pokemon.moves[i]
      end
      if moveobject
        if moveobject.id!=0
          imagepos.push(["Graphics/Pictures/types",248,yPos+2,0,
             moveobject.type*28,64,28])
          textpos.push([PBMoves.getName(moveobject.id),316,yPos,0,
             Color.new(248,248,255),Color.new(104,104,104)])
          if moveobject.totalpp>0
            textpos.push([_ISPRINTF("PP"),342,yPos+32,0,
              Color.new(248,248,255),Color.new(104,104,104)])
            textpos.push([sprintf("%d/%d",moveobject.pp,moveobject.totalpp),
               460,yPos+32,1,Color.new(248,248,255),Color.new(104,104,104)])
          end
        else
          textpos.push(["-",316,yPos,0,Color.new(248,248,255),Color.new(104,104,104)])
          textpos.push(["--",442,yPos+32,1,Color.new(248,248,255),Color.new(104,104,104)])
        end
      end
      yPos+=64
    end
    pbDrawTextPositions(overlay,textpos)
    pbDrawImagePositions(overlay,imagepos)
  end

  def drawPageFive(pokemon)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/Pictures/summary5")
    imagepos=[]
    if pbPokerus(pokemon)==1 || pokemon.hp==0 || @pokemon.status>0
      status=6 if pbPokerus(pokemon)==1
      status=@pokemon.status-1 if @pokemon.status>0
      status=5 if pokemon.hp==0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    if pokemon.isShiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])
    end
    if isConst?(pokemon.species,PBSpecies,:ELEKIDX)
      imagepos.push([sprintf("Graphics/Pictures/delta"),0,130,0,0,-1,-1])
    end
    if isConst?(pokemon.species,PBSpecies,:DELTASHARPEDO)
      imagepos.push([sprintf("Graphics/Pictures/delta"),0,130,0,0,-1,-1])
    end
    if pbPokerus(pokemon)==2
      imagepos.push([sprintf("Graphics/Pictures/summaryPokerus"),176,100,0,0,-1,-1])
    end
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/Pictures/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    pbSetSystemFont(overlay)
    itemname=pokemon.hasItem? ? PBItems.getName(pokemon.item) : _INTL("None")
    pokename=@pokemon.name
    textpos=[
       [_INTL("RIBBONS"),26,16,0,base,shadow],
       [pokename,46,62,0,base,shadow],
       [pokemon.level.to_s,46,92,0,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("Item"),16,320,0,base,shadow],
       [itemname,16,352,0,Color.new(248,248,255),Color.new(104,104,104)],
       [_INTL("No. of Ribbons:"),234,342,0,Color.new(64,64,64),Color.new(176,176,176)],
       [pokemon.ribbonCount.to_s,450,342,1,Color.new(64,64,64),Color.new(176,176,176)],
    ]
    if pokemon.isMale?
      textpos.push([_INTL("♂"),178,62,0,Color.new(24,112,216),Color.new(136,168,208)])
    elsif pokemon.isFemale?
      textpos.push([_INTL("♀"),178,62,0,Color.new(248,56,32),Color.new(224,152,144)])
    end
    pbDrawTextPositions(overlay,textpos)
    imagepos=[]
    coord=0
    if pokemon.ribbons
      for i in pokemon.ribbons
        ribn=i-1
        imagepos.push(["Graphics/Pictures/ribbons",236+64*(coord%4),86+80*(coord/4).floor,
           64*(ribn%8),64*(ribn/8).floor,64,64])
        coord+=1
        break if coord>=12
      end
    end
    pbDrawImagePositions(overlay,imagepos)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
  end

  def pbChooseMoveToForget(moveToLearn)
    selmove=0
    ret=0
    maxmove=(moveToLearn>0) ? 4 : 3
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B)
        ret=4
        break
      end
      if Input.trigger?(Input::C)
        break
      end
      if Input.trigger?(Input::DOWN)
        selmove+=1
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove=(moveToLearn>0) ? maxmove : 0
        end
        selmove=0 if selmove>maxmove
        @sprites["movesel"].index=selmove
        newmove=(selmove==4) ? moveToLearn : @pokemon.moves[selmove].id
        drawSelectedMove(@pokemon,moveToLearn,newmove)
        ret=selmove
      end
      if Input.trigger?(Input::UP)
        selmove-=1
        selmove=maxmove if selmove<0
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove=@pokemon.numMoves-1
        end
        @sprites["movesel"].index=selmove
        newmove=(selmove==4) ? moveToLearn : @pokemon.moves[selmove].id
        drawSelectedMove(@pokemon,moveToLearn,newmove)
        ret=selmove
      end
    end
    return (ret==4) ? -1 : ret
  end

  def pbMoveSelection
    @sprites["movesel"].visible=true
    @sprites["movesel"].index=0
    selmove=0
    oldselmove=0
    switching=false
    drawSelectedMove(@pokemon,0,@pokemon.moves[selmove].id)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["movepresel"].index==@sprites["movesel"].index
        @sprites["movepresel"].z=@sprites["movesel"].z+1
      else
        @sprites["movepresel"].z=@sprites["movesel"].z
      end
      if Input.trigger?(Input::B)
        break if !switching
        @sprites["movepresel"].visible=false
        switching=false
      end
      if Input.trigger?(Input::C)
        if selmove==4
          break if !switching
          @sprites["movepresel"].visible=false
          switching=false
        else
          if !(@pokemon.isShadow? rescue false)
            if !switching
              @sprites["movepresel"].index=selmove
              oldselmove=selmove
              @sprites["movepresel"].visible=true
              switching=true
            else
              tmpmove=@pokemon.moves[oldselmove]
              @pokemon.moves[oldselmove]=@pokemon.moves[selmove]
              @pokemon.moves[selmove]=tmpmove
              @sprites["movepresel"].visible=false
              switching=false
              drawSelectedMove(@pokemon,0,@pokemon.moves[selmove].id)
            end
          end
        end
      end
      if Input.trigger?(Input::DOWN)
        selmove+=1
        selmove=0 if selmove<4 && selmove>=@pokemon.numMoves
        selmove=0 if selmove>=4
        selmove=4 if selmove<0
        @sprites["movesel"].index=selmove
        newmove=@pokemon.moves[selmove].id
        pbPlayCursorSE()
        drawSelectedMove(@pokemon,0,newmove)
      end
      if Input.trigger?(Input::UP)
        selmove-=1
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove=@pokemon.numMoves-1
        end
        selmove=0 if selmove>=4
        selmove=@pokemon.numMoves-1 if selmove<0
        @sprites["movesel"].index=selmove
        newmove=@pokemon.moves[selmove].id
        pbPlayCursorSE()
        drawSelectedMove(@pokemon,0,newmove)
      end
    end 
    @sprites["movesel"].visible=false
  end

  def pbGoToPrevious
    if @page!=0
      newindex=@partyindex
      while newindex>0
        newindex-=1
        if @party[newindex] && !@party[newindex].isEgg?
          @partyindex=newindex
          break
        end
      end
    else
      newindex=@partyindex
      while newindex>0
        newindex-=1
        if @party[newindex]
          @partyindex=newindex
          break
        end
      end
    end
  end

  def pbGoToNext
    if @page!=0
      newindex=@partyindex
      while newindex<@party.length-1
        newindex+=1
        if @party[newindex] && !@party[newindex].isEgg?
          @partyindex=newindex
          break
        end
      end
    else
      newindex=@partyindex
      while newindex<@party.length-1
        newindex+=1
        if @party[newindex]
          @partyindex=newindex
          break
        end
      end
    end
  end

  def pbScene
    pbPlayCry(@pokemon)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B)
        break
      end
      dorefresh=false
      if Input.trigger?(Input::C)
        if @page==0
          break
        elsif @page==3
          pbMoveSelection
          dorefresh=true
          drawPageFour(@pokemon)
        end
      end
      if Input.trigger?(Input::UP) && @partyindex>0
        oldindex=@partyindex
        pbGoToPrevious
        if @partyindex!=oldindex
          @pokemon=@party[@partyindex]
          @sprites["pokemon"].setPokemonBitmap(@pokemon)
          @sprites["pokemon"].color=Color.new(0,0,0,0)
          pbPositionPokemonSprite(@sprites["pokemon"],40,144)
          dorefresh=true
          pbPlayCry(@pokemon)
        end
      end
      if Input.trigger?(Input::DOWN) && @partyindex<@party.length-1
        oldindex=@partyindex
        pbGoToNext
        if @partyindex!=oldindex
          @pokemon=@party[@partyindex]
          @sprites["pokemon"].setPokemonBitmap(@pokemon)
          @sprites["pokemon"].color=Color.new(0,0,0,0)
          pbPositionPokemonSprite(@sprites["pokemon"],40,144)
          dorefresh=true
          pbPlayCry(@pokemon)
        end
      end
      if Input.trigger?(Input::LEFT) && !@pokemon.isEgg?
        oldpage=@page
        @page-=1
        @page=3 if @page<0
        @page=0 if @page>3
        dorefresh=true
        if @page!=oldpage # Move to next page
          pbPlayCursorSE()
          dorefresh=true
        end
      end
      if Input.trigger?(Input::RIGHT) && !@pokemon.isEgg?
        oldpage=@page
        @page+=1
        @page=3 if @page<0
        @page=0 if @page>3
        if @page!=oldpage # Move to next page
          pbPlayCursorSE()
          dorefresh=true
        end
      end
      if dorefresh
        case @page
        when 0
          drawPageOne(@pokemon)
        when 1
          drawPageTwo(@pokemon)
        when 2
          drawPageThree(@pokemon)
        when 3
          drawPageFour(@pokemon)
        when 4
          drawPageFive(@pokemon)
        end
      end
    end
    return @partyindex
  end
end



class PokemonSummary
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen(party,partyindex,viewportz = 100000)
    @scene.pbStartScene(party,partyindex,viewportz)
    ret=@scene.pbScene
    @scene.pbEndScene
    return ret
  end

  def pbStartForgetScreen(party,partyindex,moveToLearn)
    ret=-1
    @scene.pbStartForgetScene(party,partyindex,moveToLearn)
    loop do
      ret=@scene.pbChooseMoveToForget(moveToLearn)
      if ret>=0 && moveToLearn!=0 && pbIsHiddenMove?(party[partyindex].moves[ret].id) && !$DEBUG
        Kernel.pbMessage(_INTL("HM moves can't be forgotten now.")){ @scene.pbUpdate }
      else
        break
      end
    end
    @scene.pbEndScene
    return ret
  end

  def pbStartChooseMoveScreen(party,partyindex,message)
    ret=-1
    @scene.pbStartForgetScene(party,partyindex,0)
    Kernel.pbMessage(message){ @scene.pbUpdate }
    loop do
      ret=@scene.pbChooseMoveToForget(0)
      if ret<0
        Kernel.pbMessage(_INTL("You must choose a move!")){ @scene.pbUpdate }
      else
        break
      end
    end
    @scene.pbEndScene
    return ret
  end
end
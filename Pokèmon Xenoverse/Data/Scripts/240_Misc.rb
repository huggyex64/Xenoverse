def pbBattleAltForm(species,level,form=0,variable=nil,canescape=true,canlose=false,skipanim=false,shinyflag=nil)
  pkmn = pbGenerateWildPokemon(species,level)
  pkmn.forcedForm=form
  pkmn.resetMoves
  if shinyflag != nil
    if pbGet(shinyflag)==-1
      pbSet(shinyflag,pkmn.isShiny? ? 1 : 0)
    else
      if pbGet(shinyflag)==1
        pkmn.makeShiny 
      else
        pkmn.makeNotShiny
      end
    end
  end
  skipanim = true if species == PBSpecies::TOKAKLE
  pbWildPokemonBattle(pkmn,variable,canescape,canlose,skipanim)
end

def pbBattleAltPokemonForm(pkmn,form=0,variable=nil,canescape=true,canlose=false,skipanim=false)
  pkmn.forcedForm=form
  pbWildPokemonBattle(pkmn,variable,canescape,canlose,skipanim) 
end

#===============================================================================
# Start a single wild Pokemon battle
#===============================================================================
def pbWildPokemonBattle(pkmn,variable=nil,canescape=true,canlose=false,skipanim=false)
  if (Input.press?(Input::CTRL) && $DEBUG) || $Trainer.pokemonCount==0
    if $Trainer.pokemonCount>0
      Kernel.pbMessage(_INTL("SKIPPING BATTLE..."))
    end
    pbSet(variable,1)
    $PokemonGlobal.nextBattleBGM=nil
    $PokemonGlobal.nextBattleME=nil
    $PokemonGlobal.nextBattleBack=nil
    return true
  end
  genwildpoke=pkmn

  handled=[nil]
  Events.onWildBattleOverride.trigger(nil,pkmn.species,pkmn.level,handled)
  if handled[0]!=nil
    return handled[0]
  end
  Events.onStartBattle.trigger(nil,genwildpoke)
  scene=pbNewBattleScene
  battle=PokeBattle_Battle.new(scene,$Trainer.party,[genwildpoke],$Trainer,nil)
  battle.internalbattle=true
  battle.cantescape=!canescape
  pbPrepareBattle(battle)
  decision=0
  pbBattleAnimation(pbGetWildBattleBGM(pkmn.species),$Trainer.id,"",skipanim) { 
     pbSceneStandby {
        decision=battle.pbStartBattle(canlose)
     }
     for i in $Trainer.party; (i.makeUnmega rescue nil); i.busted=false if i.busted; end
     if $PokemonGlobal.partner
       pbHealAll
       for i in $PokemonGlobal.partner[3]
         i.heal
				i.makeUnmega rescue nil
				i.busted=false if i.busted
       end
     end
     if decision==2 || decision==5 # if loss or draw
       if canlose
         for i in $Trainer.party; i.heal; end
         for i in 0...10
           Graphics.update
         end
       else
         $game_system.bgm_unpause
         $game_system.bgs_unpause
         Kernel.pbStartOver
       end
     end
     if decision==4
       if [PBSpecies::TRISHOUT,
           PBSpecies::SHYLEON,PBSpecies::SHULONG].include?(pkmn.species) && pkmn.forcedForm != nil
           
          pkmn.forcedForm=nil
          pkmn.setAbility(2)
       end
     end
     Events.onEndBattle.trigger(nil,decision)
  }
  Input.update
  pbSet(variable,decision)
  Events.onWildBattleEnd.trigger(nil,pkmn.species,pkmn.level,decision)
  return (decision!=2)
end

################################################################################
# New font in fullbox and richtext support misc
################################################################################
def drawNoShadowFormattedChar(bitmap,ch)
  if ch[5] # If a graphic
    graphic=Bitmap.new(ch[0])
    graphicRect=ch[15]
    bitmap.blt(ch[1], ch[2], graphic,graphicRect,ch[8].alpha)
    graphic.dispose
  else
    if bitmap.font.size!=ch[13]
      bitmap.font.size=ch[13]
    end
    if ch[0]!="\n" && ch[0]!="\r" && ch[0]!=" " && !isWaitChar(ch[0])
      if bitmap.font.bold!=ch[6]
        bitmap.font.bold=ch[6]
      end
      if bitmap.font.italic!=ch[7]
        bitmap.font.italic=ch[7]
      end
      if bitmap.font.name!=ch[12]
        bitmap.font.name=ch[12]
      end
      offset=0
      if bitmap.font.color!=ch[8]
        bitmap.font.color=ch[8]
      end
      bitmap.draw_text(ch[1]+offset,ch[2]+offset,ch[3],ch[4],ch[0])
    else
      if bitmap.font.color!=ch[8]
        bitmap.font.color=ch[8]
      end
    end
    if ch[10] # underline
      bitmap.fill_rect(ch[1],ch[2]+ch[4]-[(ch[4]-bitmap.font.size)/2,0].max-2,
         ch[3]-2,2,ch[8])
    end
    if ch[11] # strikeout
      bitmap.fill_rect(ch[1],ch[2]+(ch[4]/2),ch[3]-2,2,ch[8])
    end
  end
end

def drawNoShadowFormattedChars(bitmap,chars)
  if chars.length==0||!bitmap||bitmap.disposed?
    return
  end
  oldfont=bitmap.font.clone
  for ch in chars
    drawNoShadowFormattedChar(bitmap,ch)
  end
  bitmap.font=oldfont
end

def drawFormattedTextFullbox(bitmap,x,y,width,text,baseColor=nil)
  base=!baseColor ? Color.new(12*8,12*8,12*8) : baseColor.clone
  text="<c2="+colorToRgb16(base)+">"+text
  chars=getFormattedText(bitmap,x,y,width,-1,text,32)
  drawNoShadowFormattedChars(bitmap,chars)
end
################################################################################
# C(hange)F(orm) legendaries
################################################################################

def pbChooseCFLegendaries()
  lege = []
  for x in CF_LEGENDARIES
    lege.push(getID(PBSpecies,x))
  end
  Kernel.pbChoosePokemon(1,3,Proc.new {|pkmn| 
    lege.include?(pkmn.species)
  },false)
end

def pbChangeLegendaryForm(index)
  $Trainer.party[index].form = $Trainer.party[index].form==1 ? 0 : 1
end

################################################################################
# Location box override
################################################################################
class LocationWindow
  def initialize(name)
    @sprites = {}
    @sprites["Image"] = Sprite.new
    @sprites["Image"].z = 99999
    @sprites["overlay"]=Sprite.new
    @sprites["overlay"].bitmap=Bitmap.new(Graphics.width,Graphics.height)
    @sprites["overlay"].z=99999
    @sprites["overlay"].bitmap.font.name = "Kimberley Bl"
    #Dimensione standard 20, oltre i 
    fontsize = 20 - ($game_map.name.length>13 ? ($game_map.name.length-13)*0.5 : 0)
    @sprites["overlay"].bitmap.font.size = fontsize
    
    @overlay = @sprites["overlay"].bitmap
    @overlay.clear
    @baseColor=Color.new(248,248,248)
    
    #Map id delle città in cui viene mostrata la targhetta
    @cities = ["Ranch Spigadoro", "Balansopoli","Vetta Polare", "Campus Ariepoli",
    "Biblioteca Acero","Borgo Gemini", "Regno di Virgopoli", "Aquariopoli",
    "Cansiria", "Scorpiopoli","Stazione di Scorpiopoli", "Quasar Express", "Leopoli",
    "Aeroporto Samuel Oak", "Aeroporto MegaForza", "Ofiuchia", "Sagittopoli",
    "Tauronordia", "Saloon Torobrado","Capricornia", "Aranciopoli", "Covo Dimension", "Palestra Radice",
    "Palestra Competizione", "Palestra Zucchero", "Palestra Marea", "El purgatorio",
    "Palestra Ritmo", "Circo Sirio", "Vecchia Palestra Tuono"]
    @wroutes = ["3","4","13","14","11","15","16","17", "Isola Buconero", "Isola Pigliapesci", "Motonave Cometa", "Relitto Meteora"]
    @caves = ["Grotta Zerokelvin", "Cunicolo Gravità", "Grotta Immersione",
    "Vulcano Pulsar", "Caverna Zenit", "Grotta Cratere","Canyon Asteroide","Area Dugtrio",
    "Zona DNA","Percorso 8","Gola Steelix", "Tempio Shyleon", "Fogne di Sagittopoli",
    "Monte Zodiaco", "Nido Boreale", "Vetta Boreale", "Grotta dell'Epilogo"]
    @xenoverse = ["Mondo Xenoverse"]
    
    city = "Graphics/Maps/City_loc"
    route = "Graphics/Maps/Route_loc" # this will be relied on if nothing else matches
    cave = "Graphics/Maps/Cave_loc"
    waterRoute = "Graphics/Maps/WaterRoute_loc"
    xenoverse = "Graphics/Maps/Xenoverse_loc"
    
    
    
    if @cities.include?($game_map.name)
      @sprites["Image"].bitmap = pbBitmap(city)
      @shadowColor=Color.new(32,39,39)
    elsif @wroutes.include?($game_map.name)
      @sprites["Image"].bitmap = pbBitmap(waterRoute)
      @shadowColor=Color.new(16,42,53)
    elsif @xenoverse.include?($game_map.name)
      @sprites["Image"].bitmap = pbBitmap(xenoverse)
      @shadowColor=Color.new(38,16,52)
    elsif @caves.include?($game_map.name)
      @sprites["Image"].bitmap = pbBitmap(cave)
      @shadowColor=Color.new(52,30,17)
    else 
      @sprites["Image"].bitmap = pbBitmap(route)
      @shadowColor=Color.new(17,52,43)
    end
    @sprites["Image"].zoom_x = 0.25
    @sprites["Image"].zoom_y = 0.25
    @sprites["Image"].x = Graphics.width/2 - @sprites["Image"].bitmap.width/2 * 0.25
    @sprites["overlay"].x = @sprites["Image"].x
    @sprites["Image"].y = 0 - @sprites["Image"].bitmap.height/4
    
    @window=Window_AdvancedTextPokemon.new(name)
    @window.resizeToFit(name,Graphics.width)
    @window.x=0
    @window.y=-@window.height
    @window.z=99999
    @currentmap=$game_map.map_id
    @frames=0
    
    @overlay.clear
    textPositions=[]
    textPositions.push([_INTL("{1}", $game_map.name),@sprites["Image"].bitmap.width/2 * 0.25 + 14,0,2,@baseColor,@shadowColor])
    pbDrawOutlineText(@sprites["overlay"].bitmap,14,-4,@sprites["Image"].bitmap.width/4,@sprites["Image"].bitmap.height/4,_INTL("{1}", $game_map.name),@baseColor,@shadowColor,1)
    
  end

  def disposed?
    @window.disposed?
  end

  def dispose
    @window.dispose
    @sprites["Image"].dispose
    @overlay.dispose
  end
  
  def update
    return if @window.disposed?
    @window.update
    @sprites["overlay"].update
    if $game_temp.message_window_showing ||
       @currentmap!=$game_map.map_id
      @window.dispose
      @sprites["Image"].dispose
      @overlay.dispose
      return
    end
    if @frames>70
      @sprites["Image"].y-= ((@sprites["Image"].bitmap.height/4)/10)
      @sprites["overlay"].y = @sprites["Image"].y
      @overlay.dispose if @sprites["Image"].y+@sprites["Image"].bitmap.height<0
      @window.dispose if @sprites["Image"].y+@sprites["Image"].bitmap.height<0
      @sprites["Image"].dispose if @sprites["Image"].y+@sprites["Image"].bitmap.height<0
    else
      @sprites["Image"].y+= ((@sprites["Image"].bitmap.height/4)/10) if @sprites["Image"].y<0
      @sprites["overlay"].y = @sprites["Image"].y
      @frames+=1
    end
  end
  
end
################################################################################
# Condominio lotta
################################################################################
def pbCreateCondTrainer
  
  $oldTrainer = $Trainer
  $oldBag = $PokemonBag
  
  banlist = [PBSpecies::LUXFLON,PBSpecies::DIELEBI,PBSpecies::MEW,
  PBSpecies::HOOH,PBSpecies::LUGIA,PBSpecies::ENTEI,PBSpecies::SUICUNE,PBSpecies::RAIKOU,
  PBSpecies::CELEBI,PBSpecies::DEOXYS,PBSpecies::HEATRAN,PBSpecies::DARKRAI,
  PBSpecies::CRESSELIA,PBSpecies::GENESECT,
  PBSpecies::MELOETTA,PBSpecies::MARSHADOW,PBSpecies::MEWTWOX]
  pbFadeOutIn(99999){
     scene=PokemonScreen_Scene.new
     screen=PokemonScreen.new(scene,$Trainer.party)
     ret=screen.pbChooseMultiplePokemon(3,proc{|p| 
     return !banlist.include?(p.species)})
     
     return false if ret == nil || ret == -1
     $Trainer = PokeBattle_Trainer.new($oldTrainer.name,$oldTrainer.trainertype)
     $Trainer.party = Marshal.load(Marshal.dump(ret))
     $PokemonBag = PokemonBag.new
  }
  for poke in $Trainer.party
    poke.level = 50
    poke.calcStats
  end
  pbHealAll()
  return true
end

def pbRestoreOldTrainer
  $Trainer = $oldTrainer
  $PokemonBag = $oldBag
end

class PokemonScreen
  def pbChooseMultiplePokemon(number,validProc)
		minlength=3
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
      if realorder.length==number && addedEntry
        @scene.pbSelect(6)
      end
      @scene.pbSetHelpText(_INTL(""))
      pkmnid=@scene.pbChoosePokemon(false,true)
      addedEntry=false
      if pkmnid==6 && realorder.length>=minlength# Confirm was chosen
        ret=[]
        for i in realorder
          ret.push(@party[i])
        end
        error=[]
        break
        #if !ruleset.isValid?(ret,error)
        #  pbDisplay(error[0])
        #  ret=nil
        #else
        #  break
        #end
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

################################################################################
# Achievements
################################################################################
def pbSTP
  $achievements["Ranger"].progress=49
  $achievements["Capo"].silentProgress(49)
  $achievements["Forte"].silentProgress(49)
end

PLATS=["Stella",
	"EsplosioneScampata",
	"Pescagrossa",
	"Ragno",
	"Tiranno",
	"Fantino",
	"Grossi",
	"Melodia",
	"Finale",
	"Oscuro",
	"Radice",
	"Competizione",
	"Zucchero",
	"Marea",
	"Desolazione",
	"Ritmo",
	"Marchiatura",
	"Onore",
	"Mens",
	"Freddo",
	"Alata",
	"Annientadraghi",
	"Plus",
	"Scontro",
	"Confronto",
	"Autografo",
	"Terminator",
	"Amore",
	"Epilogo",
	"Perseum",
	"Heraclium",
	"Ikarium",
	"Kaiserum",
	"Odysseum",
	"Fashion",
	"Lotte",
	"Dejavu",
	"Spettri",
	"Mamma",
	"Giungla",
	"Fascino",
	"Chiamata",
	"Futuro",
	"Dolcetto",
	"Spaziotempo",
	"Ombre",
	"Talent",
	"Collezionista",
	"Anima",
	"Astra",
	"Fulmine",
	"Specchio",
	"Ranger",
	"Capo",
	"Forte",
	"Passi",
	"Erba",
	"Acchiappali",
	"Ultraball",
	"Ball",
	"Orchestra",
	"Frittata",
	"Passione",
	"Allevatore",
	"Fanatico",
	"Mondo",
	"Brillante",
	"Mercante",
	"Nemici",
	"Tana",
	"Hipster",
	"Leggendaria"
]

def pbCheckPlatinumAchi
	return if $achievements["Platino"].completed
	for a in PLATS
		return if !$achievements[a].completed
	end
	$achievements["Platino"].progress=1
end

def pbTSTPlatinum
	for a in PLATS
		if a!="Leggendaria"
			$achievements[a].silentProgress($achievements[a].amount) 
		else
			$achievements[a].progress=($achievements[a].amount)
		end
	end
end

def pbCheckCaughtPokemon
  return if $achievements["Acchiappali"].completed
  regionlist=ELDIWDEX#pbAllRegionalSpecies(0)
  echoln regionlist if $DEBUG
  regionlist.delete(243)
  regionlist.delete(244)
  regionlist.delete(245)
  echoln regionlist if $DEBUG
  echoln regionlist.length if $DEBUG
  #ret=false
  count = 0
  for i in regionlist
    #ret = true
    #ret=false if !$Trainer.owned[i]
    #next if !$Trainer.owned[i]
    #count+=1
		count+=1 if $Trainer.owned[i]
  end
  $achievements["Acchiappali"].silentProgress(count) if !$achievements["Acchiappali"].completed
  #$achievements["Acchiappali"].hidden = false if $achievements["Acchiappali"].progress>0
  #return if ret==false
  #$achievements["Acchiappali"].progress = 1 if ret == true && !$achievements["Acchiappali"].completed
end
	
def pbCheckCaughtPokemonX
  return if $achievements["Mondo"].completed
  regionlist=XENODEX#pbAllRegionalSpecies(0)
  echoln regionlist if $DEBUG
  regionlist.delete(PBSpecies::DITTOX)
  regionlist.delete(PBSpecies::RAICHUX)
  regionlist.delete(PBSpecies::BISHARPX)
	regionlist.delete(PBSpecies::SCOVILEX)
  regionlist.delete(PBSpecies::TYRANITARX)
  regionlist.delete(PBSpecies::TAPUKOKOX)
	regionlist.delete(PBSpecies::TAPUBULUX)
  regionlist.delete(PBSpecies::TAPUFINIX)
  regionlist.delete(PBSpecies::TAPULELEX)
  echoln regionlist if $DEBUG
  echoln regionlist.length if $DEBUG
  #ret=false
  count = 0
  for i in regionlist
    count+=1 if $Trainer.owned[i]
  end
  $achievements["Mondo"].silentProgress(count) if !$achievements["Mondo"].completed
end

def pbCheckBallsInBag
	return if !$PokemonBag || $achievements["Ball"].completed
	ballList = [:POKEBALL,:GREATBALL,:ULTRABALL,:LEVELBALL,:LUREBALL,:MOONBALL,:HEAVYBALL,:FRIENDBALL,:LOVEBALL,:FASTBALL,
		:REPEATBALL,:TIMERBALL,:NESTBALL,:NETBALL,:DIVEBALL,:LUXURYBALL,:HEALBALL,:QUICKBALL,:DUSKBALL,:XENOBALL]
	for i in ballList
		return if $PokemonBag.pbQuantity(getConst(PBItems,i))<=0
	end
	#if i'm here it means i have all the balls
	$achievements["Ball"].progress=1
end

def pbCheckBremandForms
	return if !$Trainer || $achievements["Orchestra"].completed
	ret = [false,false,false,false]
	for p in $Trainer.party
		if p.species == PBSpecies::BREMAND
			ret[p.form]=true
		end
	end
	for r in ret
		return if !r
	end
	$achievements["Orchestra"].progress=1
end

def pbEggAchievement
	return if $achievements["Allevatore"].completed
	if !$achievements["Frittata"].completed
		$achievements["Frittata"].progress=1
		$achievements["Passione"].progress=1
	elsif !$achievements["Passione"].completed
		if ($achievements["Passione"].progress+1)%10==0
			$achievements["Passione"].progress=1
		else
			$achievements["Passione"].silentProgress($achievements["Passione"].progress+1)
		end
		if $achievements["Passione"].completed
			$achievements["Allevatore"].progress=($achievements["Passione"].progress)
		end
	else
		if ($achievements["Allevatore"].progress+1)%25==0
			$achievements["Allevatore"].progress=1
		else
			$achievements["Allevatore"].silentProgress($achievements["Allevatore"].progress+1)
		end
	end
end

################################################################################
# Load screen icon class
################################################################################

class NewIconSprite < EAMSprite
  def initialize(pokemon,viewport,zoom=0.5)
    super(viewport)
    @pokemon=pokemon
    self.bitmap = evaluateIcon(@pokemon) if @pokemon!=nil
    self.zoom_x = zoom
    self.zoom_y = zoom
  end
  def evaluateIcon(pokemon)
		bitmap = Bitmap.new(75,74)
    if pokemon.isEgg?
			bmp = "Graphics/Pictures/DexNew/Icon/Egg"
			bitmap = pbBitmap(bmp).clone
			return bitmap
		end
		bmp =""
		bmp += "Graphics/Pictures/DexNew/Icon/#{pokemon.species}"
		if pokemon.gender==1 && pbResolveBitmap(bmp+"f")
			bmp+="f"
		end
		if pokemon.formNoCall != nil && (pokemon.formNoCall)>0
			if pokemon.isDelta?
				bmp+="d"
			else
				bmp+="_#{pokemon.formNoCall}"
			end
		end
    if pokemon.isDelta?
      bmp+="d"
    end
		bitmap = pbBitmap(bmp).clone
		echoln pokemon.item
		return bitmap
	end
end

def pbFormMetricsOverride(pokemon,form=0,og=0,back=false)
	if [PBSpecies::SHULONG,PBSpecies::TRISHOUT].include?(pokemon.species) && form>0
		return 30 if pokemon.species==PBSpecies::SHULONG && form==2 && back
		return 60 if pokemon.species==PBSpecies::SHULONG && form==2 && !back
		return 30 if pokemon.species==PBSpecies::SHULONG && form==3 && !back
		return 40 if pokemon.species==PBSpecies::TRISHOUT && form==2 && !back
	end
	return og
end

def pbFixLuxflon
  return if !$game_switches[611]
  return if $game_switches[1001]
  for i in $Trainer.party
    if i.boss && i.species == PBSpecies::LUXFLON
      i.boss = false
      i.calcStats
    end
  end
  for k in 0...STORAGEBOXES
    for p in 0...16
      if $PokemonStorage[k][p]!=nil && $PokemonStorage[k][p].species==PBSpecies::LUXFLON && $PokemonStorage[k][p].boss
        $PokemonStorage[k][p].boss=false
        $PokemonStorage[k][p].calcStats
      end
    end
  end
  $game_switches[1001]=true
end
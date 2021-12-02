################################################################################
#Sprite utilities
################################################################################

class SliderSprite < Sprite
    include EAM_Sprite
    
    def initialize(viewport)
      super(viewport)
    end
end

class TournamentPlane < AnimatedPlane

  def sprite
    return @__sprite
  end

  def mask(mask = nil,xpush = 0,ypush = 0) # Draw sprite on a sprite/bitmap
    echoln "NO BITMAP!" if !self.bitmap
    return false if !self.bitmap
    bitmap = self.bitmap.clone
    if mask.is_a?(Bitmap)
      mbmp = mask
    elsif mask.is_a?(Sprite)
      mbmp = mask.bitmap
    elsif mask.is_a?(String)
      mbmp = BitmapCache.load_bitmap(mask)
    else
      return false
    end
    echoln "STARTING MASK PROCESS!"
    self.bitmap = Bitmap.new(mbmp.width, mbmp.height)
    mask = mbmp.clone
    ox = (bitmap.width - mbmp.width) / 2
    oy = (bitmap.height - mbmp.height) / 2
    width = mbmp.width + ox
    height = mbmp.height + oy
    for y in oy...height
      for x in ox...width
        pixel = mask.get_pixel(x - ox, y - oy)
        color = bitmap.get_pixel(x - xpush, y - ypush)
        alpha = pixel.alpha
        alpha = color.alpha if color.alpha < pixel.alpha
        self.bitmap.set_pixel(x - ox, y - oy, Color.new(color.red, color.green,
            color.blue, alpha))
      end
    end
    return self.bitmap
  end

end

################################################################################
#   PWT Trainer method
################################################################################
def pbLoadTrainerTournament(trainerid,trainername,partyid=0)
  if trainerid.is_a?(String) || trainerid.is_a?(Symbol)
    if !hasConst?(PBTrainers,trainerid)
      raise _INTL("Trainer type does not exist ({1}, {2}, ID {3})",trainerid,trainername,partyid)
    end
    trainerid=getID(PBTrainers,trainerid)
  end
  success=false
  items=[]
  party=[]
  opponent=nil
  trainers=load_data("Data/tourtrainers.dat")
  for trainer in trainers
    name=trainer[1]
    thistrainerid=trainer[0]
    thispartyid=trainer[4]
    next if trainerid!=thistrainerid || name!=trainername || partyid!=thispartyid
    items=trainer[2].clone
    name=pbGetMessageFromHash(MessageTypes::TrainerNames,name)
    for i in RIVALNAMES
      if isConst?(trainerid,PBTrainers,i[0]) && $game_variables[i[1]]!=0
        name=$game_variables[i[1]]
      end
    end
    opponent=PokeBattle_Trainer.new(name,thistrainerid)
    opponent.setForeignID($Trainer) if $Trainer
    for poke in trainer[3]
      species=poke[TPSPECIES]
      level=poke[TPLEVEL]
      pokemon=PokeBattle_Pokemon.new(species,level,opponent)
      pokemon.form=poke[TPFORM]
      pokemon.resetMoves
      pokemon.setItem(poke[TPITEM])
      if poke[TPMOVE1]>0 || poke[TPMOVE2]>0 || poke[TPMOVE3]>0 || poke[TPMOVE4]>0
        k=0
        for move in [TPMOVE1,TPMOVE2,TPMOVE3,TPMOVE4]
          pokemon.moves[k]=PBMove.new(poke[move])
          k+=1
        end
        pokemon.moves.compact!
      end
      pokemon.setAbility(poke[TPABILITY])
      pokemon.setGender(poke[TPGENDER])
      if poke[TPSHINY]   # if this is a shiny Pokémon
        pokemon.makeShiny
      else
        pokemon.makeNotShiny
      end
      pokemon.setNature(poke[TPNATURE])
      iv=poke[TPIV]
      for i in 0...6
        pokemon.iv[i]=iv&0x1F
        pokemon.ev[i]=[85,level*3/2].min
      end
      pokemon.happiness=poke[TPHAPPINESS]
      pokemon.name=poke[TPNAME] if poke[TPNAME] && poke[TPNAME]!=""
      if poke[TPSHADOW]   # if this is a Shadow Pokémon
        pokemon.makeShadow rescue nil
        pokemon.pbUpdateShadowMoves(true) rescue nil
        pokemon.makeNotShiny
      end
      pokemon.ballused=poke[TPBALL]
      pokemon.calcStats
      party.push(pokemon)
    end
    success=true
    break
  end
  return success ? [opponent,items,party] : nil
end

def pbCompileTournament
  # Individual tournament trainers
  lines=[]
  linenos=[]
  lineno=1
  trainernames=[]
  File.open("PBS/tourtrainers.txt","rb"){|f|
     FileLineData.file="PBS/tourtrainers.txt"
     f.each_line {|line|
        if lineno==1 && line[0]==0xEF && line[1]==0xBB && line[2]==0xBF
          line=line[3,line.length-3]
        end
        line=prepline(line)
        if line!=""
          lines.push(line)
          linenos.push(lineno)
        end
        lineno+=1
     }
  }
  nameoffset=0
  trainers=[]
  trainernames.clear
  i=0; loop do break unless i<lines.length
    FileLineData.setLine(lines[i],linenos[i])
    trainername=parseTrainer(lines[i])
    FileLineData.setLine(lines[i+1],linenos[i+1])
    nameline=strsplit(lines[i+1],/\s*,\s*/)
    name=nameline[0]
    raise _INTL("Trainer name too long\r\n{1}",FileLineData.linereport) if name.length>=0x10000
    trainernames.push(name)
    partyid=0
    if nameline[1] && nameline[1]!=""
      raise _INTL("Expected a number for the trainer battle ID\r\n{1}",FileLineData.linereport) if !nameline[1][/^\d+$/]
      partyid=nameline[1].to_i
    end
    FileLineData.setLine(lines[i+2],linenos[i+2])
    items=strsplit(lines[i+2],/\s*,\s*/)
    items[0].gsub!(/^\s+/,"")   # Number of Pokémon
    raise _INTL("Expected a number for the number of Pokémon\r\n{1}",FileLineData.linereport) if !items[0][/^\d+$/]
    numpoke=items[0].to_i
    realitems=[]
    for j in 1...items.length   # Items held by Trainer
      realitems.push(parseItem(items[j])) if items[j] && items[j]!=""
    end
    pkmn=[]
    for j in 0...numpoke
      FileLineData.setLine(lines[i+j+3],linenos[i+j+3])
      poke=strsplit(lines[i+j+3],/\s*,\s*/)
      begin
        # Species
        poke[TPSPECIES]=parseSpecies(poke[TPSPECIES])
      rescue
        raise _INTL("Expected a species name: {1}\r\n{2}",poke[0],FileLineData.linereport)
      end
      # Level
      poke[TPLEVEL]=poke[TPLEVEL].to_i
      raise _INTL("Bad level: {1} (must be from 1-{2})\r\n{3}",poke[TPLEVEL],
        PBExperience::MAXLEVEL,FileLineData.linereport) if poke[TPLEVEL]<=0 || poke[TPLEVEL]>PBExperience::MAXLEVEL
      # Held item
      if !poke[TPITEM] || poke[TPITEM]==""
        poke[TPITEM]=TPDEFAULTS[TPITEM]
      else
        poke[TPITEM]=parseItem(poke[TPITEM])
      end
      # Moves
      moves=[]
      for j in [TPMOVE1,TPMOVE2,TPMOVE3,TPMOVE4]
        moves.push(parseMove(poke[j])) if poke[j] && poke[j]!=""
      end
      for j in 0...4
        index=[TPMOVE1,TPMOVE2,TPMOVE3,TPMOVE4][j]
        if moves[j] && moves[j]!=0
          poke[index]=moves[j]
        else
          poke[index]=TPDEFAULTS[index]
        end
      end
      # Ability
      if !poke[TPABILITY] || poke[TPABILITY]==""
        poke[TPABILITY]=TPDEFAULTS[TPABILITY]
      else
        poke[TPABILITY]=poke[TPABILITY].to_i
        raise _INTL("Bad abilityflag: {1} (must be 0 or 1 or 2-5)\r\n{2}",poke[TPABILITY],FileLineData.linereport) if poke[TPABILITY]<0 || poke[TPABILITY]>5
      end
      # Gender
      if !poke[TPGENDER] || poke[TPGENDER]==""
        poke[TPGENDER]=TPDEFAULTS[TPGENDER]
      else
        if poke[TPGENDER]=="M"
          poke[TPGENDER]=0
        elsif poke[TPGENDER]=="F"
          poke[TPGENDER]=1
        else
          poke[TPGENDER]=poke[TPGENDER].to_i
          raise _INTL("Bad genderflag: {1} (must be M or F, or 0 or 1)\r\n{2}",poke[TPGENDER],FileLineData.linereport) if poke[TPGENDER]<0 || poke[TPGENDER]>1
        end
      end
      # Form
      if !poke[TPFORM] || poke[TPFORM]==""
        poke[TPFORM]=TPDEFAULTS[TPFORM]
      else
        poke[TPFORM]=poke[TPFORM].to_i
        raise _INTL("Bad form: {1} (must be 0 or greater)\r\n{2}",poke[TPFORM],FileLineData.linereport) if poke[TPFORM]<0
      end
      # Shiny
      if !poke[TPSHINY] || poke[TPSHINY]==""
        poke[TPSHINY]=TPDEFAULTS[TPSHINY]
      elsif poke[TPSHINY]=="shiny"
        poke[TPSHINY]=true
      else
        poke[TPSHINY]=csvBoolean!(poke[TPSHINY].clone)
      end
      # Nature
      if !poke[TPNATURE] || poke[TPNATURE]==""
        poke[TPNATURE]=TPDEFAULTS[TPNATURE]
      else
        poke[TPNATURE]=parseNature(poke[TPNATURE])
      end
      # IVs
      if !poke[TPIV] || poke[TPIV]==""
        poke[TPIV]=TPDEFAULTS[TPIV]
      else
        poke[TPIV]=poke[TPIV].to_i
        raise _INTL("Bad IV: {1} (must be from 0-31)\r\n{2}",poke[TPIV],FileLineData.linereport) if poke[TPIV]<0 || poke[TPIV]>31
      end
      # Happiness
      if !poke[TPHAPPINESS] || poke[TPHAPPINESS]==""
        poke[TPHAPPINESS]=TPDEFAULTS[TPHAPPINESS]
      else
        poke[TPHAPPINESS]=poke[TPHAPPINESS].to_i
        raise _INTL("Bad happiness: {1} (must be from 0-255)\r\n{2}",poke[TPHAPPINESS],FileLineData.linereport) if poke[TPHAPPINESS]<0 || poke[TPHAPPINESS]>255
      end
      # Nickname
      if !poke[TPNAME] || poke[TPNAME]==""
        poke[TPNAME]=TPDEFAULTS[TPNAME]
      else
        poke[TPNAME]=poke[TPNAME].to_s
        raise _INTL("Bad nickname: {1} (must be 1-20 characters)\r\n{2}",poke[TPNAME],FileLineData.linereport) if (poke[TPNAME].to_s).length>20
      end
      # Shadow
      if !poke[TPSHADOW] || poke[TPSHADOW]==""
        poke[TPSHADOW]=TPDEFAULTS[TPSHADOW]
      else
        poke[TPSHADOW]=csvBoolean!(poke[TPSHADOW].clone)
      end
      # Ball
      if !poke[TPBALL] || poke[TPBALL]==""
        poke[TPBALL]=TPDEFAULTS[TPBALL]
      else
        poke[TPBALL]=poke[TPBALL].to_i
        raise _INTL("Bad form: {1} (must be 0 or greater)\r\n{2}",poke[TPBALL],FileLineData.linereport) if poke[TPBALL]<0
      end
      pkmn.push(poke)
    end
    i+=3+numpoke
    MessageTypes.setMessagesAsHash(MessageTypes::TrainerNames,trainernames)
    trainers.push([trainername,name,realitems,pkmn,partyid])
    nameoffset+=name.length
  end
  save_data(trainers,"Data/tourtrainers.dat")
end

#-------------------------------------------------------------------------------
# PWT battle rules
#-------------------------------------------------------------------------------
class RestrictSpecies
  
  def initialize(banlist)
    @specieslist = []
    for species in banlist
      if species.is_a?(Numeric)
        @specieslist.push(species)
        next
      elsif species.is_a?(Symbol)
        @specieslist.push(getConst(PBSpecies,species))
      end
    end
  end
  
  def isSpecies?(species,specieslist)
    for s in specieslist
      return true if species == s
    end
    return false  
  end
  
  def isValid?(pokemon)
    count = 0
    egg = pokemon.respond_to?(:egg?) ? pokemon.egg? : pokemon.isEgg?
    if isSpecies?(pokemon.species,@specieslist) && !egg
      count += 1
    end
    return count == 0
  end
end
#-------------------------------------------------------------------------------
# Extra functionality added to the Trainer class
#-------------------------------------------------------------------------------
class PokeBattle_Trainer
  attr_accessor :battle_points
  attr_accessor :pwt_wins
  attr_accessor :lobby_trainer
end

#===============================================================================
#  Tournament Script by
#     xZekro51:.
#    v.1.0
#
#===============================================================================
$rivalBattleID=0
TRAINERPOOL_basic=[  #ALMENO 8 ALLENATORI
=begin
  ["trey",PBTrainers::ALTERTREY,"Trey",_INTL("Come ho potuto perdere così?"),2],
["Alice (with Pikachu XF)",PBTrainers::ALICEFINAL,"Alice",_INTL("Ho fatto la scelta sbagliata?"),1],
["Aster",PBTrainers::ASTER,"Aster",_INTL("Cavoli, sono veramente esauto!"),2],
["motociclista",PBTrainers::BIKER,"Gale",_INTL("Che errore!"),0],
["breaker",PBTrainers::BREAKER,"Seiya",_INTL("Che errore!"),0],
["allenatore-campeggiatore",PBTrainers::CAMPEGGIATORE,"Fausto",_INTL("Che errore!"),0],
["allenatore-campeggiatrice",PBTrainers::CAMPEGGIATRICE,"Tata",_INTL("Che errore!"),0],
["allenatore-campeggiatrice",PBTrainers::CAMPEGGIATRICE,"Ginevra",_INTL("Che errore!"),0],
["allenatore-campeggiatrice",PBTrainers::CAMPEGGIATRICE,"Ermia",_INTL("Che errore!"),6],
["Karateka",PBTrainers::CINTURANERA,"Ryu",_INTL("Che errore!"),0],
["CowGirl-default",PBTrainers::COWGIRL,"Sandy",_INTL("Che errore!"),0],
["Mamma",PBTrainers::FINALMAMMA,"Edera",_INTL("Che errore!"),1],
["goldtrainer",PBTrainers::GOLD,"Gold",_INTL("Che errore!"),2],
["IndianoKid",PBTrainers::INDIANOKID,"Raico",_INTL("Che errore!"),0]
=end
]
TRAINERPOOL_hard=[]  #ALMENO 16 ALLENATORI
TRAINERPOOL_expert=[]  #ALMENO 32 ALLENATORI

SKILL_LEVELS={
  PBTrainers::ALTERTREY=>100,
}

BAN_LIST=[:LUXFLON]

REWARDPOOL=[:POTION,:GREATBALL,:POKEBALL,:ESCAPEROPE]
REWARDLOSINGPOOL=[:POTION,:ANTIDOTE]

TOURNAMENT_OPPONENT_EVENT_ID = 19
TOURNAMENT_EVENT_ID = 18


################################################################################
# Extra function to Trainer class
################################################################################
class PokeBattle_Trainer
  attr_accessor :battle_points
  attr_accessor :lobby_trainer
  attr_accessor :pw
end

$DEBUG = true

def moveStars(leftStar,rightStar)
  rightStar.oy+=2
  rightStar.borderX=-(512-310)
  rightStar.borderY=100

  leftStar.oy-=2
  leftStar.borderX=-(512-310)
  leftStar.borderY=100
end

def pbTestMas

  #Initializing graphics element as well as starting animation
  v=Viewport.new(0,0,Graphics.width,Graphics.height)
  v.z=99999

  @v=v
  @sprites={}

  Graphics.frame_rate=60

  @sprites["darken"] = EAMSprite.new(v)
  @sprites["darken"].bitmap = Bitmap.new(512,384)
  @sprites["darken"].bitmap.fill_rect(0,0,512,384,Color.new(0,0,0))
  @sprites["darken"].opacity = 0


  @sprites["leftbg"]=EAMSprite.new(v)
  @sprites["leftbg"].bitmap=pbBitmap("Graphics/Pictures/STour/leftGradient")
  @sprites["leftbg"].x=-512#512/4

  @sprites["leftStar"]=TournamentPlane.new(v)
  @sprites["leftStar"].bitmap = pbBitmap("Graphics/Pictures/STour/StarAnimBG")
  @sprites["leftStar"].sprite.angle=-17
  @sprites["leftStar"].sprite.y=-210
  
  @sprites["leftStar"].sprite.x=20
  #@sprites["leftStar"].borderX=-(512-320)
  @sprites["leftStar"].borderY=200
  @sprites["leftStar"].sprite.opacity = 0
  
  @sprites["left"]=EAMSprite.new(v)
  @sprites["left"].bitmap=pbBitmap("Graphics/Transitions/smSpecial153")
  #@sprites["left"].x=@sprites["left"].bitmap.width/4
  #@sprites["left"].ox = @sprites["left"].bitmap.width/4
  echoln "#{-@sprites["left"].bitmap.width/5} #{-@sprites["left"].bitmap.width/4}"
  @sprites["left"].mask("Graphics/Pictures/STour/leftGradient", -40)
  @sprites["left"].x=-512

  @sprites["rightbg"]=EAMSprite.new(v)
  @sprites["rightbg"].bitmap=pbBitmap("Graphics/Pictures/STour/rightGradient")
  @sprites["rightbg"].x=512+512
  @sprites["rightbg"].ox = @sprites["rightbg"].bitmap.width

  @sprites["rightStar"]=TournamentPlane.new(v)
  @sprites["rightStar"].bitmap = pbBitmap("Graphics/Pictures/STour/StarAnimBG")
  @sprites["rightStar"].sprite.angle=-17
  @sprites["rightStar"].sprite.y=-170

  @sprites["rightStar"].sprite.x=370
  #@sprites["leftStar"].borderX=-(512-320)
  @sprites["rightStar"].borderY=200
  @sprites["rightStar"].sprite.opacity = 0

  @sprites["right"]=EAMSprite.new(v)
  @sprites["right"].bitmap=pbBitmap("Graphics/Transitions/smSpecial169")
  @sprites["right"].x=512
  @sprites["right"].x=512+512
  @sprites["right"].mask("Graphics/Pictures/STour/rightGradient",40)
  @sprites["right"].ox = @sprites["right"].bitmap.width
  
  @sprites["sep"]=EAMSprite.new(v)
  @sprites["sep"].bitmap=pbBitmap("Graphics/Pictures/STour/Sep")
  @sprites["sep"].ox = @sprites["sep"].bitmap.width/2
  @sprites["sep"].oy = @sprites["sep"].bitmap.height/2
  @sprites["sep"].x = 512/2
  @sprites["sep"].y = 384/2
  @sprites["sep"].zoom_x = 2
  @sprites["sep"].zoom_y = 2
  @sprites["sep"].opacity = 0

  @sprites["vs"]=EAMSprite.new(v)
  @sprites["vs"].bitmap=pbBitmap("Graphics/VS/vs")
  @sprites["vs"].ox = @sprites["vs"].bitmap.width/2
  @sprites["vs"].oy = @sprites["vs"].bitmap.height/2
  @sprites["vs"].x = 512/2
  @sprites["vs"].y = 384/2
  @sprites["vs"].zoom_x = 2
  @sprites["vs"].zoom_y = 2
  @sprites["vs"].opacity = 0

  for i in 0...2
    @sprites["bar#{i}"] = EAMSprite.new(v)
    @sprites["bar#{i}"].bitmap=pbBitmap("Graphics/Pictures/STour/blackBar")
    @sprites["bar#{i}"].oy = i % 2 == 0 ? 0 : @sprites["bar#{i}"].bitmap.height
    @sprites["bar#{i}"].y = i % 2 == 0 ? -@sprites["bar#{i}"].bitmap.height : 384 + @sprites["bar#{i}"].bitmap.height
  end

  val=1


  @sprites["darken"].fade(150,30,:ease_in_cubic)
  20.times do 
    Graphics.update
    Input.update
    @sprites["darken"].update
    
  end

  @sprites["bar0"].move(0,0,20,:ease_in_cubic)
  @sprites["bar1"].move(0,384,20,:ease_in_cubic)
  20.times do
    Graphics.update
    Input.update
    @sprites["darken"].update
    @sprites["bar0"].update
    @sprites["bar1"].update

  end

  @sprites["sep"].fade(255,30,:ease_in_cubic)
  @sprites["sep"].zoom(1,1,30,:ease_in_cubic)

  Kernel.pbMessage("Here we go! The Sunshine Tournament is finally starting!")

  Kernel.pbMessage("Let's take a look at our contestants!")
  
  @sprites["sep"].fade(255,30,:ease_in_cubic)
  @sprites["sep"].zoom(1,1,30,:ease_in_cubic)

  @sprites["right"].move(512,0,20,:ease_in_cubic)
  @sprites["rightbg"].move(512,0,20,:ease_in_cubic)
  30.times do
    Graphics.update
    Input.update
    @sprites["right"].update
    @sprites["rightbg"].update

    @sprites["sep"].update
  end

  @sprites["right"].move(512+10,0,2)
  @sprites["rightbg"].move(512+10,0,2)
  2.times do
    Graphics.update
    Input.update
    @sprites["right"].update
    @sprites["rightbg"].update
  end
  
  @sprites["right"].move(512,0,2)
  @sprites["rightbg"].move(512,0,2)
  2.times do
    Graphics.update
    Input.update
    @sprites["right"].update
    @sprites["rightbg"].update
  end      

  Kernel.pbMessage("On the right! Our most beloved Gym leader, Enzo!")

  @sprites["left"].move(0,0,20,:ease_in_cubic)
  @sprites["leftbg"].move(0,0,20,:ease_in_cubic)
  20.times do
    Graphics.update
    Input.update
    @sprites["left"].update
    @sprites["leftbg"].update
    
  end

  @sprites["left"].move(0-10,0,2)
  @sprites["leftbg"].move(0-10,0,2)
  2.times do
    Graphics.update
    Input.update
    @sprites["left"].update
    @sprites["leftbg"].update
  end
  
  @sprites["left"].move(0,0,2)
  @sprites["leftbg"].move(0,0,2)
  2.times do
    Graphics.update
    Input.update
    @sprites["left"].update
    @sprites["leftbg"].update
  end
  

  Kernel.pbMessage("On the left! Who the hell is he?")

  Kernel.pbMessage("Well, who cares! Now, duke it out!")

  @sprites["vs"].fade(255,20,:ease_in_cubic)
  @sprites["vs"].zoom(1,1,20,:ease_in_cubic)
  20.times do
    Graphics.update
    Input.update
    @sprites["vs"].update
    @sprites["leftStar"].sprite.opacity+=120/20
    @sprites["rightStar"].sprite.opacity+=120/20
    moveStars(@sprites["leftStar"],@sprites["rightStar"])
  end

  loop do 
    Graphics.update
    Input.update

    if (Input.press?(Input::A))
      #@sprites["leftStar"].ox+=2
      @sprites["leftStar"].oy-=2
      @sprites["leftStar"].borderX=-(512-310)
      @sprites["leftStar"].borderY=100
      #@sprites["leftStar"].sprite.mask("Graphics/Pictures/STour/leftGradient")
    elsif (Input.trigger?(Input::C))
      #@sprites["left"].mask("Graphics/Transitions/rightmask")

      #Fade
      

    end

    moveStars(@sprites["leftStar"],@sprites["rightStar"])

    @sprites["vs"].x+=val
    @sprites["vs"].y-=val
    val=1 if @sprites["vs"].x<=(v.rect.width/2)-1
    val=-1 if @sprites["vs"].x>=(v.rect.width/2)+1

    if (Input.press?(Input::RIGHT))
      @sprites["left"].x+=2
      @sprites["leftbg"].x+=2
    elsif (Input.press?(Input::LEFT))
      @sprites["left"].x-=2
      @sprites["leftbg"].x-=2
    end

    if (Input.trigger?(Input::B))
      break
    end
  end
end


class PWT
  
  
  def initialize(player,difficulty,trainerpool=nil,testpool=false)
    
    if testpool
      pool = defineChart(player, difficulty)
      loop do
        Graphics.update
        Input.update
        if Input.trigger?(Input::C)
          pool = redefineChart(pool)
        end
      end
      return
    end

    @levels = []
    @party_bak = []
    @battle_type = 0
    #$rivalBattleID=pbRivalStarter
    #player.pw = 0 if !player.pw
    
    player.tournament_wins=0 if player.tournament_wins.nil?
    player.battle_points = 0 if player.battle_points.nil?
    @player = player
    # Backing up Party
    self.backupParty
    @newparty = self.choosePokemon
    if @newparty != "notEligible"
      if @newparty != nil
        $Trainer.party = @newparty
        #pbTransferWithTransition(9,16,10,:DIRECTED,6)
        echo $game_player.direction
        event = $game_map.events[4]        
        
        #Initializing the viewport
        @v=Viewport.new(0,0,Graphics.width,Graphics.height)
        @v.z=99990

        # Tournament Intro
        pbIntroTournament
        self.startTournament(player,difficulty,trainerpool)
      else
        Kernel.pbMessage(_INTL("I'm sorry, will be for next time!"))
      end
    else
      Kernel.pbMessage(_INTL("I'm sorry, will be for next time!"))
    end
  end
  
  def pbIntroTournament
    #v=Viewport.new(0,0,Graphics.width,Graphics.height)
    #v.z=99999
    #@sprites={}
    #Initializing graphics element as well as starting animation
    v = @v
    @sprites={}
    @sprites["greybgleft"]=EAMSprite.new(v)
    @sprites["greybgleft"].bitmap=Bitmap.new(256,512)
    @sprites["greybgleft"].bitmap.fill_rect(0,0,256,512,Color.new(16,16,16))
    @sprites["greybgleft"].x=-256
    
    @sprites["greybgright"]=EAMSprite.new(v)
    @sprites["greybgright"].bitmap=Bitmap.new(256,512)
    @sprites["greybgright"].bitmap.fill_rect(0,0,256,512,Color.new(16,16,16))
    @sprites["greybgright"].x=512+256
    
    @sprites["greybgright"].move(256,0,20,:ease_in_cubic)
    @sprites["greybgleft"].move(0,0,20,:ease_in_cubic)

    20.times do 
      @sprites["greybgleft"].update
      @sprites["greybgright"].update
      Graphics.update
      Input.update
    end

    @sprites["greybgright"].move(256+14,0,4)
    @sprites["greybgleft"].move(0-14,0,4)

    4.times do 
      Graphics.update
      Input.update
      @sprites["greybgleft"].update
      @sprites["greybgright"].update
    end

    @sprites["greybgright"].move(256,0,4)
    @sprites["greybgleft"].move(0,0,4)

    4.times do 
      Graphics.update
      Input.update
      @sprites["greybgleft"].update
      @sprites["greybgright"].update
    end


  end
  
  def playOpponentIntro
    if $DEBUG==true && Input.press?(Input::CTRL)
      if Kernel.pbConfirmMessage("Skip tournament?")
        @playerwon=true
        endTournament(@playerwon)
        return
      end
    end
    opponentIntro(@opponent)
    #Starting the battle
    startBattle(@pool)

    #If player won the round but not the tournament
    if @win == true && @playerwon == false
      # Continue the tournament
      @pool = redefineChart(@pool)

      @opponent = @pool[@oppIndex]
      betRounds(@pool)
      
      pbTransferWithTransition(324,9,15,:DIRECTED,6) {
        pbDisposeSpriteHash(@sprites)
      }
      #play the event
      $game_map.events[19].character_name = @opponent[0]
      $game_map.events[19].turn_left
      $game_map.events[18].start
    else
      # End the tournament
      endTournament(@playerwon)
    end
  end

  def trainerTypeName(type)   # Name of this trainer type (localized)
    return PBTrainers.getName(type) rescue _INTL("PkMn Trainer")
  end

  def opponentIntro(opponent)
    t_ext = pbResolveBitmap("Graphics/Transitions/smSpecial#{opponent[1]}") ? "Special" : "Trainer"
    bmp = pbBitmap("Graphics/Transitions/sm#{t_ext}#{opponent[1]}")

    echoln opponent


    #Initializing graphics element as well as starting animation
    v=Viewport.new(0,0,Graphics.width,Graphics.height)
    v.z=99995
  
    @v=v
    @sprites={}
  
    Graphics.frame_rate=60
  
    @sprites["darken"] = EAMSprite.new(v)
    @sprites["darken"].bitmap = Bitmap.new(512,384)
    @sprites["darken"].bitmap.fill_rect(0,0,512,384,Color.new(0,0,0))
    @sprites["darken"].opacity = 0
  
  
    @sprites["leftbg"]=EAMSprite.new(v)
    @sprites["leftbg"].bitmap=pbBitmap("Graphics/Pictures/STour/leftGradient")
    @sprites["leftbg"].x=-512#512/4
  
    @sprites["leftStar"]=TournamentPlane.new(v)
    @sprites["leftStar"].bitmap = pbBitmap("Graphics/Pictures/STour/StarAnimBG")
    @sprites["leftStar"].sprite.angle=-17
    @sprites["leftStar"].sprite.y=-210
    
    @sprites["leftStar"].sprite.x=20
    @sprites["leftStar"].borderY=200
    @sprites["leftStar"].sprite.opacity = 0
    
    @sprites["left"]=EAMSprite.new(v)
    @sprites["left"].bitmap=pbBitmap("Graphics/Transitions/smSpecial153")
    @sprites["left"].mask("Graphics/Pictures/STour/leftGradient", -40)
    @sprites["left"].x=-512
  
    @sprites["rightbg"]=EAMSprite.new(v)
    @sprites["rightbg"].bitmap=pbBitmap("Graphics/Pictures/STour/rightGradient")
    @sprites["rightbg"].x=512+512
    @sprites["rightbg"].ox = @sprites["rightbg"].bitmap.width
  
    @sprites["rightStar"]=TournamentPlane.new(v)
    @sprites["rightStar"].bitmap = pbBitmap("Graphics/Pictures/STour/StarAnimBG")
    @sprites["rightStar"].sprite.angle=-17
    @sprites["rightStar"].sprite.y=-170
  
    @sprites["rightStar"].sprite.x=370
    @sprites["rightStar"].borderY=200
    @sprites["rightStar"].sprite.opacity = 0
  
    @sprites["right"]=EAMSprite.new(v)
    @sprites["right"].bitmap=bmp#pbBitmap("Graphics/Transitions/smSpecial169")
    @sprites["right"].x=512
    @sprites["right"].x=512+512
    @sprites["right"].mask("Graphics/Pictures/STour/rightGradient",40)
    @sprites["right"].ox = @sprites["right"].bitmap.width
    
    @sprites["sep"]=EAMSprite.new(v)
    @sprites["sep"].bitmap=pbBitmap("Graphics/Pictures/STour/Sep")
    @sprites["sep"].ox = @sprites["sep"].bitmap.width/2
    @sprites["sep"].oy = @sprites["sep"].bitmap.height/2
    @sprites["sep"].x = 512/2
    @sprites["sep"].y = 384/2
    @sprites["sep"].zoom_x = 2
    @sprites["sep"].zoom_y = 2
    @sprites["sep"].opacity = 0
  
    @sprites["vs"]=EAMSprite.new(v)
    @sprites["vs"].bitmap=pbBitmap("Graphics/VS/vs")
    @sprites["vs"].ox = @sprites["vs"].bitmap.width/2
    @sprites["vs"].oy = @sprites["vs"].bitmap.height/2
    @sprites["vs"].x = 512/2
    @sprites["vs"].y = 384/2
    @sprites["vs"].zoom_x = 2
    @sprites["vs"].zoom_y = 2
    @sprites["vs"].opacity = 0
  
    for i in 0...2
      @sprites["bar#{i}"] = EAMSprite.new(v)
      @sprites["bar#{i}"].bitmap=pbBitmap("Graphics/Pictures/STour/blackBar")
      @sprites["bar#{i}"].oy = i % 2 == 0 ? 0 : @sprites["bar#{i}"].bitmap.height
      @sprites["bar#{i}"].y = i % 2 == 0 ? -@sprites["bar#{i}"].bitmap.height : 384 + @sprites["bar#{i}"].bitmap.height
    end
  
    val=1

    #HERE STARTS THE ANIMATION
  
    @sprites["darken"].fade(150,30,:ease_in_cubic)
    20.times do 
      Graphics.update
      Input.update
      @sprites["darken"].update
      
    end
  
    @sprites["bar0"].move(0,0,20,:ease_in_cubic)
    @sprites["bar1"].move(0,384,20,:ease_in_cubic)
    20.times do
      Graphics.update
      Input.update
      @sprites["darken"].update
      @sprites["bar0"].update
      @sprites["bar1"].update
  
    end
  
    @sprites["sep"].fade(255,30,:ease_in_cubic)
    @sprites["sep"].zoom(1,1,30,:ease_in_cubic)
  
    Kernel.pbMessage("Let's take a look at our contestants!")
    
    @sprites["sep"].fade(255,30,:ease_in_cubic)
    @sprites["sep"].zoom(1,1,30,:ease_in_cubic)
  
    @sprites["right"].move(512,0,20,:ease_in_cubic)
    @sprites["rightbg"].move(512,0,20,:ease_in_cubic)
    30.times do
      Graphics.update
      Input.update
      @sprites["right"].update
      @sprites["rightbg"].update
  
      @sprites["sep"].update
    end
  
    @sprites["right"].move(512+10,0,2)
    @sprites["rightbg"].move(512+10,0,2)
    2.times do
      Graphics.update
      Input.update
      @sprites["right"].update
      @sprites["rightbg"].update
    end
    
    @sprites["right"].move(512,0,2)
    @sprites["rightbg"].move(512,0,2)
    2.times do
      Graphics.update
      Input.update
      @sprites["right"].update
      @sprites["rightbg"].update
    end      
  
    Kernel.pbMessage(_INTL("On the right! {1}, {2}!", trainerTypeName(opponent[1]), opponent[2]))
  
    @sprites["left"].move(0,0,20,:ease_in_cubic)
    @sprites["leftbg"].move(0,0,20,:ease_in_cubic)
    20.times do
      Graphics.update
      Input.update
      @sprites["left"].update
      @sprites["leftbg"].update
    end
  
    @sprites["left"].move(0-10,0,2)
    @sprites["leftbg"].move(0-10,0,2)
    2.times do
      Graphics.update
      Input.update
      @sprites["left"].update
      @sprites["leftbg"].update
    end
    
    @sprites["left"].move(0,0,2)
    @sprites["leftbg"].move(0,0,2)
    2.times do
      Graphics.update
      Input.update
      @sprites["left"].update
      @sprites["leftbg"].update
    end
    
  
    Kernel.pbMessage("On the left! Who the hell is he?")
  
    Kernel.pbMessage("Well, who cares! Now, duke it out!")
  
    @sprites["vs"].fade(255,20,:ease_in_cubic)
    @sprites["vs"].zoom(1,1,20,:ease_in_cubic)
    20.times do
      Graphics.update
      Input.update
      @sprites["vs"].update
      @sprites["leftStar"].sprite.opacity+=120/20
      @sprites["rightStar"].sprite.opacity+=120/20
      moveStars(@sprites["leftStar"],@sprites["rightStar"])
    end
    
    60.times do 
      Graphics.update
      Input.update
      moveStars(@sprites["leftStar"],@sprites["rightStar"])
    end
  end
  
  #Graphical methods
  
  def loadGraphics
    v=@v
    #Loading all graphical resources
    
    pwt = "Graphics/Pictures/STour/"
    #@sprites={}
    #@sprites["bg"]=Sprite.new(v)
    #@sprites["bg"].bitmap=pbBitmap(pwt+"pwt_interscreen")
    #@sprites["bg"].bitmap=pbBitmap(pwt+"bg")
    #@sprites["bg"].x=330
    #@sprites["bg"].blur_sprite(1)
    
    @sprites["anibg"]=AnimatedPlane.new(v)
    @sprites["anibg"].bitmap=pbBitmap(pwt+"anibgPwt")
    #@sprites["anibg"].borderX=990
    @sprites["anibg"].opacity=0

    @sprites["light"]= EAMSprite.new(v)
    @sprites["light"].bitmap=pbBitmap(pwt+"Light")
    @sprites["light"].opacity = 0

    @sprites["gengar"]=EAMSprite.new(v)
    @sprites["gengar"].bitmap = pbBitmap(pwt+"GSketch")
    @sprites["gengar"].opacity = 0
    @sprites["gengar"].y = 384

  end
  
  def drawInfoBoxes(trainer,pool,oppIndex)
    
    w=Color.new(255,255,255)
    b=Color.new(44,44,44)
    pwt = "Graphics/Pictures/PWT/"
    
   # echo pool[oppIndex][0]
    
    @sprites["oleft"].bitmap.clear
    @sprites["oright"].bitmap.clear
    
    @sprites["leftBox"].bitmap=pbBitmap(pwt+"pwtLeftBox")
    @sprites["rightBox"].bitmap=pbBitmap(pwt+"pwtRightBox")
    
    @sprites["trainer"]=Sprite.new(@v)
    @sprites["trainer"].bitmap=AnimatedBitmapWrapper.new(pbPlayerSpriteFile($Trainer.trainertype)).bitmap
    @sprites["trainer"].x=12+@sprites["leftBox"].x
    @sprites["trainer"].y=278
    @sprites["trainer"].src_rect.set(0,0,196,@sprites["trainer"].bitmap.height/2)
    @sprites["overLeft"].x=@sprites["trainer"].x+12
    if oppIndex != nil
      @sprites["opp"]=Sprite.new(@v)
      @sprites["opp"].bitmap=AnimatedBitmapWrapper.new(pbTrainerSpriteFile(pool[oppIndex][0])).bitmap
      @sprites["opp"].x=542+@sprites["rightBox"].x
      @sprites["opp"].y=396
      @sprites["opp"].src_rect.set(0,0,196,@sprites["opp"].bitmap.height/2)
      @sprites["overRight"].x=@sprites["opp"].x+12
    end
    
    textpos=[[trainer.name,60,232,0,w]]
    textpos2=[[pool[oppIndex][1],444+28,498,0,w]]
    
    pbSetSystemFont(@sprites["oright"].bitmap)
    pbSetSystemFont(@sprites["oleft"].bitmap)
    pbDrawTextPositions(@sprites["oleft"].bitmap,textpos)
    pbDrawTextPositions(@sprites["oright"].bitmap,textpos2)
  end
   
  def closeGraphics
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
  end
  
  #Logical Methods start from here
  def defineChart(player,difficulty,trainerpool=nil) #Calculate the chart inside a pool of trainers
    
    if trainerpool==nil
       case difficulty
       when 0
         trainerpool=TRAINERPOOL_basic
         @rounds=3
       when 1
         trainerpool=TRAINERPOOL_hard
         @rounds=4
       when 2
         trainerpool=TRAINERPOOL_expert
         @rounds=5
       end
    end
    #defining the number of slots in the tournament
    #player will take a random spot in between
    
    if difficulty==0
      branches = 7
    elsif difficulty==1
      branches = 15
    elsif difficulty==2
      branches = 31
    else
      branches = 7
    end
    
    pool=[]
    added=[]
    for i in 0...branches
      randTrainer = trainerpool[rand(trainerpool.length)]
      #This ensures diversity between trainers
      while (added.include?(randTrainer))
        randTrainer = trainerpool[rand(trainerpool.length)]
      end
      added.push(randTrainer)
      pool.push(randTrainer)
    end
    
    m = rand(pool.length-1)    
    pool.insert(m,$Trainer)
    
    pool.each do |entry|
      id = pool.index(entry)
      echoln "Contestant #{id+1}: #{entry == $Trainer ? $Trainer.name : entry[2]}"
    end
    
    getBattlesList(pool)
    
    echo _INTL("Player is contestant number {1} and the chart is long {2} \n",@trainerIndex,pool.length)
    
    return pool
  end

  def tGraphicsUpdate
    if @sprites["anibg"]!=nil
      @sprites["anibg"].ox+=2
      @sprites["anibg"].oy+=2
    end
      
  end
  
  def startTournament(player,difficulty,trainerpool=nil) #Starts the tournament
        
    @trainerIndex=nil
    @oppIndex=nil
    
    #Global variable for checking the exp giving if the player is in a tournament
    $ISINTOURNAMENT=true
    
    @pool = defineChart(player,difficulty,trainerpool)
    pool = @pool

    @opponent = pool[@oppIndex]

    #opponentIntro(opponent)

    rounds=@rounds
    
    @playerwon=false
    
    loadGraphics()
    pbBGMPlay("pwt ost")
    #$game_system.message_position = 4
    
    # Setting party level to 50
    self.setLevel

    10.times do
      @sprites["anibg"].opacity +=15
      Graphics.update
      Input.update
      tGraphicsUpdate()
    end

    @sprites["light"].fade(150,10)
    @sprites["gengar"].fade(255,20)
    @sprites["gengar"].move(0,-10,20,:ease_in_cubic)
    20.times do
      Graphics.update
      Input.update
      tGraphicsUpdate()
      @sprites["gengar"].update
      @sprites["light"].update
    end

    @sprites["gengar"].move(0,0,4,:ease_in_cubic)
    4.times do
      Graphics.update
      Input.update
      tGraphicsUpdate()
      @sprites["gengar"].update
    end
    
    Kernel.pbMessage(_INTL("Salve a tutti e benvenuti al Torneo Apollo! Gengah-ah-ah!")) {tGraphicsUpdate()}
    
    pbSEPlay("Applause")
    pbSEPlay("CrowdSound")
    
    60.times do
      Graphics.update
      Input.update
      tGraphicsUpdate()
    end
    
    #drawInfoBoxes($Trainer,pool,@oppIndex)
    
    #Kernel.pbMessage(_INTL("A huge thanks goes to our sponsor! The Pokémon Center Co.!")) {tGraphicsUpdate()}
    Kernel.pbMessage(_INTL("Oggi ne vedremo delle belle! I contendenti sono pronti a far scintille!")) {tGraphicsUpdate()}
    
    Kernel.pbMessage(_INTL("Spero che siate pronti anche voi! Gengah-ah-ah!")) {tGraphicsUpdate()}
    
    Kernel.pbMessage(_INTL("Adesso, iniziamo!")) {tGraphicsUpdate()}
    
    #Teleport to Circo Sirio (324,9,15)

    pbTransferWithTransition(324,9,15,:DIRECTED,6) {
      pbDisposeSpriteHash(@sprites)
    }

    $game_switches[1201]=true

    $game_map.events[TOURNAMENT_OPPONENT_EVENT_ID].character_name = @opponent[0]
    $game_map.events[TOURNAMENT_OPPONENT_EVENT_ID].turn_left
    $game_map.events[TOURNAMENT_EVENT_ID].start

  end
  
  def nextRound
    @trainerIndex=nil
    @oppIndex=nil
    
    #Global variable for checking the exp giving if the player is in a tournament
    $ISINTOURNAMENT=true
    
    @pool = redefineChart(@pool)
    pool = @pool

    @opponent = pool[@oppIndex]

    #opponentIntro(opponent)

    rounds=@rounds
    
    @playerwon=false
    
    loadGraphics()
    pbBGMPlay("pwt ost")
    #$game_system.message_position = 4
    
    # Setting party level to 50
    self.setLevel

    10.times do
      @sprites["anibg"].opacity +=15
      Graphics.update
      Input.update
      tGraphicsUpdate()
    end

    @sprites["light"].fade(150,10)
    @sprites["gengar"].fade(255,20)
    @sprites["gengar"].move(0,-10,20,:ease_in_cubic)
    20.times do
      Graphics.update
      Input.update
      tGraphicsUpdate()
      @sprites["gengar"].update
      @sprites["light"].update
    end

    @sprites["gengar"].move(0,0,4,:ease_in_cubic)
    4.times do
      Graphics.update
      Input.update
      tGraphicsUpdate()
      @sprites["gengar"].update
    end
    
    Kernel.pbMessage(_INTL("Salve a tutti e benvenuti al Torneo Apollo! Gengah-ah-ah!")) {tGraphicsUpdate()}
    
    pbSEPlay("Applause")
    pbSEPlay("CrowdSound")
    
    60.times do
      Graphics.update
      Input.update
      tGraphicsUpdate()
    end
    
    #drawInfoBoxes($Trainer,pool,@oppIndex)
    
    #Kernel.pbMessage(_INTL("A huge thanks goes to our sponsor! The Pokémon Center Co.!")) {tGraphicsUpdate()}
    Kernel.pbMessage(_INTL("Oggi ne vedremo delle belle! I contendenti sono pronti a far scintille!")) {tGraphicsUpdate()}
    
    Kernel.pbMessage(_INTL("Spero che siate pronti anche voi! Gengah-ah-ah!")) {tGraphicsUpdate()}
    
    Kernel.pbMessage(_INTL("Adesso, iniziamo!")) {tGraphicsUpdate()}
    
    #Teleport to Circo Sirio (324,9,15)

    pbTransferWithTransition(324,9,15,:DIRECTED,6) {
      pbDisposeSpriteHash(@sprites)
    }

    $game_switches[1201]=true

    $game_map.events[19].character_name = @opponent[0]
    $game_map.events[19].turn_left
    $game_map.events[18].start
  end

  
  def betRounds(pool) #Between rounds
    pbIntroTournament()

    #Gengar reappears
    loadGraphics()
    pbBGMPlay("pwt ost")

    10.times do
      @sprites["anibg"].opacity +=15
      Graphics.update
      Input.update
      tGraphicsUpdate()
    end

    @sprites["light"].fade(150,10)
    @sprites["gengar"].fade(255,20)
    @sprites["gengar"].move(0,-10,20,:ease_in_cubic)
    20.times do
      Graphics.update
      Input.update
      tGraphicsUpdate()
      @sprites["gengar"].update
      @sprites["light"].update
    end

    @sprites["gengar"].move(0,0,4,:ease_in_cubic)
    4.times do
      Graphics.update
      Input.update
      tGraphicsUpdate()
      @sprites["gengar"].update
    end

    Kernel.pbMessage(_INTL("What an amazing battle! The win goes to {1}! Congrats!", $Trainer.name)) {tGraphicsUpdate()}
    #self.exitParticipants
    #self.drawInfoBoxes($Trainer,pool,@oppIndex)
    Kernel.pbMessage(_INTL("And now, let's see who got to the next round!")) {tGraphicsUpdate()}
    for c in 0...pool.length
      if pool[c]==$Trainer
         Kernel.pbMessage(_INTL("Contestant N°{1}, {2}!",@trainerIndex+1,$Trainer.name)) {tGraphicsUpdate()}
      else
         Kernel.pbMessage(_INTL("Contestant N°{1}, {2}!",c+1,pool[c][2])) {tGraphicsUpdate()}
      end
    end
    Kernel.pbMessage(_INTL("They were the winners from the last round!")) {tGraphicsUpdate()}
    
    Kernel.pbMessage(_INTL("Now, time to go on with the next one!")) {tGraphicsUpdate()}
    #self.enterParticipants
    Kernel.pbMessage(_INTL("Contestant N°{1}, {2}! Contestant N°{3}, {4}! Time to show what's your value!",@trainerIndex+1,$Trainer.name,@oppIndex+1,pool[@oppIndex][2])) {tGraphicsUpdate()}
  end
  
  
  def redefineChart(pool) #Recalculate the tournament chart
    #player Won
    newPool=[]
    #echoln pool
    if pool.length>2
      if @trainerIndex%2==0
        newtrIndex = @trainerIndex/2
      else
        newtrIndex = (@trainerIndex-1)/2
      end

      #Temporary Pool for splitting the pool two by two
      tempPool = []
      for i in 0...pool.length
        tempPool.push([pool[i],pool[i+1]]) if i%2==0
      end
      
      echoln "p:#{pool.length} tp:#{tempPool.length}"

      for c in 0...tempPool.length
        pair = tempPool[c]
        echoln "handling pair: #{pair[0] == $Trainer ? $Trainer.name : pair[0][2]} #{pair[1] == $Trainer ? $Trainer.name : pair[1][2]}"
        #if the pair contains the player
        if pair[0] == $Trainer || pair[1] == $Trainer
          newPool.push($Trainer)
        else #if it doesn't contain the player
          #echoln pair
          if pair[0][4]>pair[1][4]
            newPool.push(pair[0])
          elsif pair[0][4]<pair[1][4] # i+1's win priority is greater than i's
            newPool.push(pair[1])
          else #they have the same win priority
            r=rand(2)
            newPool.push(pair[r])
          end
        end
      end
    end
    
    while newPool.include?(nil)
      #newPool.delete_at(newPool.length-1)
      newPool.delete(nil)
    end
    #echoln newPool
    
    
    for t in 0...newPool.length#.each do |entry|
      #id = newPool.index(entry)
      echoln "Contestant #{t+1}: #{newPool[t] == $Trainer ? $Trainer.name : newPool[t][2]}"
    end

    getBattlesList(newPool)
    
    echo _INTL("Player is contestant number {1} and the chart is long {2} \n",@trainerIndex,newPool.length)
    
    return newPool
  end
  
  
  def getBattlesList(pool) #Gets the list of battles in order
    if pool != nil
      trainerIndex=nil
      opponentIndex=nil
      
      #while trainerIndex==nil
      #  for i in 0...pool.length
      #    if pool[i]==$Trainer
      #      trainerIndex = i
      #    end
      #  end
      #end
      if @trainerIndex !=nil
        trainerIndex=@trainerIndex
      end
      
      for i in 0...pool.length
        if pool[i]==$Trainer
          trainerIndex = i
        end
      end
      
      if trainerIndex%2==0 
        opponentIndex=trainerIndex+1
      else
        opponentIndex=trainerIndex-1
      end
      
      
      @trainerIndex=trainerIndex
      @oppIndex=opponentIndex
    end
    
  end
  
  
  def startBattle(pool)
    if pool.length>3
      #Kernel.pbMessage(_INTL("You were matched against trainer n°{1}",@oppIndex))
      if pbTournamentBattle(pool[@oppIndex][1],pool[@oppIndex][2],pool[@oppIndex][3],false,0,true)
        @win=true
      else
        @win=false
        Kernel.pbMessage(_INTL("Contestant {1} has lost! Too bad!",$Trainer.name))
      end
      healParty
    else
      Kernel.pbMessage(_INTL("Congrats to the costentants which reached the finals! {2} and {1}! Now it's time for you to show everyone you're the best!",pool[@oppIndex][1],$Trainer.name))
      if pbTournamentBattle(pool[@oppIndex][1],pool[@oppIndex][2],pool[@oppIndex][3],false,0,true)
        Kernel.pbMessage(_INTL("CONGRATS TO {1} FOR SHOWING OFF THIS AMAZING PERFORMANCE!",$Trainer.name))
        Kernel.pbMessage(_INTL("Remember to go to the reception to collect your winnings!"))
        @playerwon=true
        @win=true
      else
        Kernel.pbMessage(_INTL("Contestant {1} has lost! Too bad!",$Trainer.name))
        @win=false
      end
      healParty
    end
  end
  
  #End tournament section
  def endTournament(win)
    #What to do if player won    
    closeGraphics
    restoreParty
    $game_system.message_position = 2
    $ISINTOURNAMENT=false
    if win==true
      @player.tournament_wins+=1
      #pbTransferWithTransition(4,6,15,:DIRECTED,8)
      #pbCallBubStart(3)
      if @player.tournament_wins > 1
        Kernel.pbMessage(_INTL("Congrats on your win! As of now, you've won {1} tournaments!",@player.tournament_wins))
      else
        Kernel.pbMessage(_INTL("Congrats on your win! As of now, you've won {1} tournament!",@player.tournament_wins))
      end
      
      Kernel.pbMessage(_INTL("Here is your reward for winning."))
      @player.battle_points+=5
      reward = REWARDPOOL[rand(REWARDPOOL.length)]
      rewardname = getID(PBItems,reward)
     # pbCallBubStart(0)
      Kernel.pbMessage(_INTL("{1} obtained 5 Battle Points!",@player.name))
      Kernel.pbMessage(_INTL("Also..."))
      Kernel.pbMessage(_INTL("For showing an amazing performance..."))
      Kernel.pbMessage(_INTL("...{1} obtains {2}!",@player.name,PBItems.getName(rewardname)))
      Kernel.pbReceiveItem(reward)
     # pbCallBubStart(3)
      Kernel.pbMessage(_INTL("See you next time!"))
    else #what to do if player lose
      
     # pbTransferWithTransition(4,6,15,:DIRECTED,8)
     # pbCallBubStart(3)
      Kernel.pbMessage(_INTL("I'm so sorry you lost! But you stood your ground, I'm sure you can win it next time!"))
      Kernel.pbMessage(_INTL("You lost, but you still got some rewards."))
      @player.battle_points+=1
      reward = REWARDLOSINGPOOL[rand(REWARDLOSINGPOOL.length)]
      rewardname = getID(PBItems,reward)
     # pbCallBubStart(0)
      Kernel.pbMessage(_INTL("{1} obtained 1 Battle Points and {2}.",@player.name,PBItems.getName(rewardname)))
      Kernel.pbReceiveItem(reward)
     # pbCallBubStart(3)
      Kernel.pbMessage(_INTL("See you next time!"))
    end
    
    
  end
  
  #Heal Party
  def healParty
    for poke in $Trainer.party
      poke.heal
    end
  end

  def choosePokemon
    ret = false
    return "notEligible" if !self.partyEligible?
    length = [3,4,6,1][@battle_type]
    Kernel.pbMessage(_INTL("Please choose the Pokemon you would like to participate."))
    banlist = BAN_LIST
    banlist = BAN_LIST[@tournament_type] if BAN_LIST.is_a?(Hash)
    ruleset = PokemonRuleSet.new
    ruleset.addPokemonRule(RestrictSpecies.new(banlist))
    ruleset.setNumberRange(length,length)
    pbFadeOutIn(99999){
      if defined?(PokemonParty_Scene)
        scene = PokemonParty_Scene.new
        screen = PokemonPartyScreen.new(scene,$Trainer.party)
      else
        scene = PokemonScreen_Scene.new
        screen = PokemonScreen.new(scene,$Trainer.party)
      end
      #ret = screen.pbPokemonMultipleEntryScreenEx(ruleset)
      ret=screen.pbChooseMultiplePokemon(3,proc{|p|
          return ruleset.isPokemonValid?(p)
      })
    }
    return ret
  end
  
  def partyEligible?
    length = [3,4,6,1][@battle_type]
    count = 0
    banlist = BAN_LIST
    banlist = BAN_LIST[@tournament_type] if BAN_LIST.is_a?(Hash)
    return false if $Trainer.party.length < length
    echo "Checking on Party"
    for i in 0...$Trainer.party.length
      for species in banlist
        if species.is_a?(Numeric)
        elsif species.is_a?(Symbol)
          species = getConst(PBSpecies,species)
        else
          next
        end
        egg = $Trainer.party[i].respond_to?(:egg?) ? $Trainer.party[i].egg? : $Trainer.party[i].isEgg?
        count += 1 if species != $Trainer.party[i].species && !egg
      end
    end
    echo count
    echo length
    return true if count >= length
    return false
  end
  
  # Sets all Pokemon to lv 50
  def setLevel
    for poke in $Trainer.party
      poke.level = 50
      poke.calcStats
      poke.heal
    end
  end
  
  # Backs up your current party
  def backupParty
    @party_bak.clear
    @levels.clear
    for poke in $Trainer.party
      @party_bak.push(poke)
      @levels.push(poke.level)
    end
  end
  
  # Restores your party from an existing backup
  def restoreParty
    $Trainer.party.clear
    for i in 0...@party_bak.length
      poke = @party_bak[i]
      poke.level = @levels[i]
      poke.calcStats
      poke.heal
      $Trainer.party.push(poke)
    end
  end
  
end

#===============================================================================
# Additional Methods for the tournament
#
#===============================================================================
#Modification to Pokebattle_trainer module to add won tournaments counter
class PokeBattle_Trainer
  attr_accessor :battle_points
  attr_accessor :tournament_wins
end

#TOURNAMENT BATTLE METHOD
def pbTournamentBattle(trainerid,trainername,endspeech,
                    doublebattle=false,trainerparty=0,canlose=false,variable=nil)
  if $Trainer.pokemonCount==0
    Kernel.pbMessage(_INTL("SKIPPING BATTLE...")) if $DEBUG
    return false
  end
  if !$PokemonTemp.waitingTrainer && $Trainer.ablePokemonCount>1 &&
     pbMapInterpreterRunning?
    thisEvent=pbMapInterpreter.get_character(0)
    triggeredEvents=$game_player.pbTriggeredTrainerEvents([2],false)
    otherEvent=[]
    for i in triggeredEvents
      if i.id!=thisEvent.id && !$game_self_switches[[$game_map.map_id,i.id,"A"]]
        otherEvent.push(i)
      end
    end
    if otherEvent.length==1
      trainer=pbLoadTrainerTournament(trainerid,trainername,trainerparty)
      Events.onTrainerPartyLoad.trigger(nil,trainer)
      if !trainer
        pbMissingTrainer(trainerid,trainername,trainerparty)
        return false
      end
      if trainer[2].length<=6 # 3
        $PokemonTemp.waitingTrainer=[trainer,thisEvent.id,endspeech]
        return false
      end
    end
  end
  trainer=pbLoadTrainerTournament(trainerid,trainername,trainerparty)
  Events.onTrainerPartyLoad.trigger(nil,trainer)
  if !trainer
    pbMissingTrainer(trainerid,trainername,trainerparty)
    return false
  end
  if $PokemonGlobal.partner && ($PokemonTemp.waitingTrainer || doublebattle)
    othertrainer=PokeBattle_Trainer.new(
       $PokemonGlobal.partner[1],$PokemonGlobal.partner[0])
    othertrainer.id=$PokemonGlobal.partner[2]
    othertrainer.party=$PokemonGlobal.partner[3]
    playerparty=[]
    for i in 0...$Trainer.party.length
      playerparty[i]=$Trainer.party[i]
    end
    for i in 0...othertrainer.party.length
      playerparty[6+i]=othertrainer.party[i]
    end
    fullparty1=true
    playertrainer=[$Trainer,othertrainer]
    doublebattle=true
  else
    playerparty=$Trainer.party
    playertrainer=$Trainer
    fullparty1=false
  end
  if $PokemonTemp.waitingTrainer
    combinedParty=[]
    fullparty2=false
    if false
      if $PokemonTemp.waitingTrainer[0][2].length>3
        raise _INTL("Opponent 1's party has more than three Pokémon, which is not allowed")
      end
      if trainer[2].length>3
        raise _INTL("Opponent 2's party has more than three Pokémon, which is not allowed")
      end
    elsif $PokemonTemp.waitingTrainer[0][2].length>3 || trainer[2].length>3
      for i in 0...$PokemonTemp.waitingTrainer[0][2].length
        combinedParty[i]=$PokemonTemp.waitingTrainer[0][2][i]
      end
      for i in 0...trainer[2].length
        combinedParty[6+i]=trainer[2][i]
      end
      fullparty2=true
    else
      for i in 0...$PokemonTemp.waitingTrainer[0][2].length
        combinedParty[i]=$PokemonTemp.waitingTrainer[0][2][i]
      end
      for i in 0...trainer[2].length
        combinedParty[3+i]=trainer[2][i]
      end
      fullparty2=false
    end
    scene=pbNewBattleScene
    battle=PokeBattle_Battle.new(scene,playerparty,combinedParty,playertrainer,
       [$PokemonTemp.waitingTrainer[0][0],trainer[0]])
    trainerbgm=pbGetTrainerBattleBGM(
       [$PokemonTemp.waitingTrainer[0][0],trainer[0]])
    battle.fullparty1=fullparty1
    battle.fullparty2=fullparty2
    battle.doublebattle=battle.pbDoubleBattleAllowed?()
    battle.endspeech=$PokemonTemp.waitingTrainer[2]
    battle.endspeech2=endspeech
    battle.items=[$PokemonTemp.waitingTrainer[0][1],trainer[1]]
  else
    scene=pbNewBattleScene
    battle=PokeBattle_Battle.new(scene,playerparty,trainer[2],playertrainer,trainer[0])
    battle.fullparty1=fullparty1
    battle.doublebattle=doublebattle ? battle.pbDoubleBattleAllowed?() : false
    battle.endspeech=endspeech
    battle.items=trainer[1]
    trainerbgm=pbGetTrainerBattleBGM(trainer[0])
  end
  if Input.press?(Input::CTRL) && $DEBUG
    Kernel.pbMessage(_INTL("SKIPPING BATTLE..."))
    Kernel.pbMessage(_INTL("AFTER LOSING..."))
    Kernel.pbMessage(battle.endspeech)
    Kernel.pbMessage(battle.endspeech2) if battle.endspeech2
    if $PokemonTemp.waitingTrainer
      pbMapInterpreter.pbSetSelfSwitch($PokemonTemp.waitingTrainer[1],"A",true)
      $PokemonTemp.waitingTrainer=nil
    end
    return true
  end
  Events.onStartBattle.trigger(nil,nil)
  battle.internalbattle=true
  pbPrepareBattle(battle)
  restorebgm=true
  decision=0
  Audio.me_stop
  pbBattleAnimation(trainerbgm,trainer[0].trainertype,trainer[0].name) { 
     pbSceneStandby {
        decision=battle.pbStartBattle(canlose)
     }
     for i in $Trainer.party; (i.makeUnmega rescue nil); end
     if $PokemonGlobal.partner
       pbHealAll
       for i in $PokemonGlobal.partner[3]
         i.heal
         i.makeUnmega rescue nil
       end
     end
     if decision==2 || decision==5
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
     else
       Events.onEndBattle.trigger(nil,decision)
       if decision==1
         if $PokemonTemp.waitingTrainer
           pbMapInterpreter.pbSetSelfSwitch($PokemonTemp.waitingTrainer[1],"A",true)
         end
       end
     end
  }
  Input.update
  pbSet(variable,decision)
  $PokemonTemp.waitingTrainer=nil
  return (decision==1)
end

def pbTT
    $pwt = PWT.new($Trainer,0)
end

def pbt
  #Temporary Pool for splitting the pool two by two
  pool=TRAINERPOOL_basic[0...8]
  tempPool = []
  for i in 0...pool.length
    tempPool.push([i,i+1]) if i%2==0
  end
  echoln tempPool

  newPool=[]
  for j in 0...tempPool.length
    newPool.push(tempPool[j][rand(2)])
  end
  echoln newPool
end

def pbTrans(method)
  pbTransferWithTransition(10,10,10,method)
end
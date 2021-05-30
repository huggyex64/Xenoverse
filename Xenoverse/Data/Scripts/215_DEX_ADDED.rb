class PokeBattle_Trainer
	attr_accessor(:xenodex)
	
	def xenodex
		@xenodex = false if @xenodex == nil
		return @xenodex
	end
	
  def shinyseen
    @shinyseen={} if @shinyseen == nil
    return @shinyseen
  end
  
end

def Kernel.pbViewportMessageChooseNumber(viewport,message,params,&block)
  msgwindow=Kernel.pbCreateMessageWindow(viewport,params.messageSkin)
	msgwindow.z = 9999999
  ret=Kernel.pbMessageDisplay(msgwindow,message,true,
     proc {|msgwindow|
        next Kernel.pbChooseNumber(msgwindow,params,&block)
  },&block)
  Kernel.pbDisposeMessageWindow(msgwindow)
  return ret
end

class PokeBattle_Scene
	def pbShowPokedex(pokemon,register=true)
    pbFadeOutIn(999999){
			DexObtained.new(pokemon,pokemon.gender==1 ? true : false,register)
    }
  end
end

IGNORESHINOBI=[:GROWLITHE,:ARCANINE,:SEEDOT,:NUZLEAF,:SHIFTRY,:MIENFOO,
:MIENSHAO,:MAGBY,:MAGMAR,:MAGMORTAR,:TURTWIG,:GROTLE,:TORTERRA,:CHIMCHAR,:MONFERNO,:INFERNAPE,
:PIPLUP,:PRINPLUP,:EMPOLEON,:SURSKIT,:MASQUERAIN,:LOTAD,:LOMBRE,:LUDICOLO,:HORSEA,:SEADRA,
:KINGDRA,:PSYDUCK,:GOLDUCK,:WOOPER,:QUAGSIRE,:CHEWTLE,:DREDNAW]

IGNOREX = [:GRENINJAX]

MYTHDOGS = [PBSpecies::ENTEI,PBSpecies::RAIKOU,PBSpecies::SUICUNE]

def shouldIgnore?(species)
  ignore = []
  ignore = ((ignore-(ignore&IGNORESHINOBI))+IGNORESHINOBI) #this ensures there are no duplicates
  for i in ignore
    return true if isConst?(species,PBSpecies,i)
  end
  return false
end

def shouldIgnoreX?(species)
  return true if isConst?(species,PBSpecies,IGNOREX[0])
  return false
end

def getEldiwDexChecks(ignoreDogs = false)
  ret =[]
  for i in ELDIWDEX
    next if shouldIgnore?(i)
    next if ignoreDogs && MYTHDOGS.include?(i)
    ret.push(i)
  end
  return ret
end

def getXenoDexChecks
  ret =[]
  for i in XENODEX
    next if shouldIgnoreX?(i)
    ret.push(i)
  end
  return ret
end

def pbSCELDIW(seen=true,ignore=true)  
  ret = 0
  if seen
    for i in ELDIWDEX
      next if shouldIgnore?(i) && ignore
      ret+=1 if $Trainer.seen[i]
    end
  else
    for i in ELDIWDEX
      next if shouldIgnore?(i) && ignore
      ret+=1 if $Trainer.owned[i]
    end
  end
  return ret
end

def pbSCXENO(seen=true)
  ret = 0
  if seen
    for i in XENODEX
      next if shouldIgnoreX?(i)
      ret+=1 if $Trainer.seen[i]
    end
  else
    for i in XENODEX
      next if shouldIgnoreX?(i)
      ret+=1 if $Trainer.owned[i]
    end
  end
  return ret
end

def pbSCRETRO(seen=true)
  ret = 0
  if seen
    for i in RETRODEX
      ret+=1 if $Trainer.seen[i]
    end
  else
    for i in RETRODEX
      ret+=1 if $Trainer.owned[i]
    end
  end
  return ret
end

# Form description translation
$fdtr={}

def pbCreateFormDescTranslation
  f = File.open("PBS/fdtr.txt","w")
  formdesc = pbLoadFormInfos
  for k in formdesc.keys
    kind = formdesc[k].kind == nil ? "NO_KIND_SET (DO NOT REMOVE THIS LINE)" : formdesc[k].kind
    f.write(kind)
    f.write("\n")
		f.write(kind)
		f.write("\n")
		f.write(formdesc[k].description)
		f.write("\n")
		f.write(formdesc[k].description)
		f.write("\n")
	end
	f.close
end

def pbLoadFormDescTranslation
	f = File.open("PBS/fdtr.txt")
	l=0
	key=nil
	f.readlines.each do |line|
		
		if l%2==0
			$fdtr[line.gsub("\n","")]=nil
			key=line.gsub("\n","")
		else
			$fdtr[key]=line.gsub("\n","")
			key=nil
		end
		l+=1
	end
	f.close
end
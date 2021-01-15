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

def pbSCELDIW(seen=true)
  ret = 0
  if seen
    for i in ELDIWDEX
      ret+=1 if $Trainer.seen[i]
    end
  else
    for i in ELDIWDEX
      ret+=1 if $Trainer.owned[i]
    end
  end
  return ret
end

def pbSCXENO(seen=true)
  ret = 0
  if seen
    for i in XENODEX
      ret+=1 if $Trainer.seen[i]
    end
  else
    for i in XENODEX
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
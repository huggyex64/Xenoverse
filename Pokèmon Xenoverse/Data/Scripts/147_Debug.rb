class PokemonDataCopy
  attr_accessor :dataOldHash
  attr_accessor :dataNewHash
  attr_accessor :dataTime
  attr_accessor :data

  def crc32(x)
    return Zlib::crc32(x)
  end

  def readfile(filename)
    File.open(filename, "rb"){|f|
       f.read
    }
  end

  def writefile(str,filename)
    File.open(filename, "wb"){|f|
       f.write(str)
    }
  end

  def filetime(filename)
    File.open(filename, "r"){|f|
       f.mtime
    }
  end

  def initialize(data,datasave)
    @datafile=data
    @datasave=datasave
    @data=readfile(@datafile)
    @dataOldHash=crc32(@data)
    @dataTime=filetime(@datafile)
  end

  def changed?
    ts=readfile(@datafile)
    tsDate=filetime(@datafile)
    tsHash=crc32(ts)
    return tsHash!=@dataNewHash && tsHash!=@dataOldHash && tsDate > @dataTime
  end

  def save(newtilesets)
    newdata=Marshal.dump(newtilesets)
    if !changed?
      @data=newdata
      @dataNewHash=crc32(newdata)
      writefile(newdata,@datafile)
    else
      @dataOldHash=crc32(@data)
      @dataNewHash=crc32(newdata)
      @dataTime=filetime(@datafile)
      @data=newdata
      writefile(newdata,@datafile)
    end
    save_data(self,@datasave)
  end
end



class PokemonDataWrapper
  attr_reader :data

  def initialize(file,savefile,prompt)
    @savefile=savefile
    @file=file
    if pbRgssExists?(@savefile)
      @ts=load_data(@savefile)
      if !@ts.changed? || prompt.call==true
        @data=Marshal.load(StringInput.new(@ts.data))
      else
        @ts=PokemonDataCopy.new(@file,@savefile)
        @data=load_data(@file)
      end
    else
      @ts=PokemonDataCopy.new(@file,@savefile)
      @data=load_data(@file)
    end
  end

  def save
    @ts.save(@data)
  end
end



def pbMapTree
  mapinfos=pbLoadRxData("Data/MapInfos")
  maplevels=[]
  retarray=[]
  for i in mapinfos.keys
    info=mapinfos[i]
    level=-1
    while info
      info=mapinfos[info.parent_id]
      level+=1
    end
    if level>=0
      info=mapinfos[i]
      maplevels.push([i,level,info.parent_id,info.order])
    end
  end
  maplevels.sort!{|a,b|
     next a[1]<=>b[1] if a[1]!=b[1] # level
     next a[2]<=>b[2] if a[2]!=b[2] # parent ID
     next a[3]<=>b[3] # order
  }
  stack=[]
  stack.push(0,0)
  while stack.length>0
    parent = stack[stack.length-1]
    index = stack[stack.length-2]
    if index>=maplevels.length
      stack.pop
      stack.pop
      next
    end
    maplevel=maplevels[index]
    stack[stack.length-2]+=1
    if maplevel[2]!=parent
      stack.pop
      stack.pop
      next
    end
    retarray.push([maplevel[0],mapinfos[maplevel[0]].name,maplevel[1]])
    for i in index+1...maplevels.length
      if maplevels[i][2]==maplevel[0]
        stack.push(i)
        stack.push(maplevel[0])
        break
      end
    end
  end
  return retarray
end

def pbExtractText
  msgwindow=Kernel.pbCreateMessageWindow
  Kernel.pbMessageDisplay(msgwindow,_INTL("Please wait.\\wtnp[0]"))
  MessageTypes.extract("intl.txt")
  Kernel.pbMessageDisplay(msgwindow,
     _INTL("All text in the game was extracted and saved to intl.txt.\1"))
  Kernel.pbMessageDisplay(msgwindow,
     _INTL("To localize the text for a particular language, translate every second line in the file.\1"))
  Kernel.pbMessageDisplay(msgwindow,
     _INTL("After translating, choose \"Compile Text.\""))
  Kernel.pbDisposeMessageWindow(msgwindow)
end

def pbCompileTextUI
  msgwindow=Kernel.pbCreateMessageWindow
  Kernel.pbMessageDisplay(msgwindow,_INTL("Please wait.\\wtnp[0]"))
  begin
    pbCompileText
    Kernel.pbMessageDisplay(msgwindow,
       _INTL("Successfully compiled text and saved it to intl.dat."))
    Kernel.pbMessageDisplay(msgwindow,
       _INTL("To use the file in a game, place the file in the Data folder under a different name, and edit the LANGUAGES array in the Settings script."))
    rescue RuntimeError
    Kernel.pbMessageDisplay(msgwindow,
       _INTL("Failed to compile text:  {1}",$!.message))
  end
  Kernel.pbDisposeMessageWindow(msgwindow)
end



class CommandList
  def initialize
    @commandHash={}
    @commands=[]
  end

  def getCommand(index)
    for key in @commandHash.keys
      return key if @commandHash[key]==index
    end
    return nil
  end

  def add(key,value)
    @commandHash[key]=@commands.length
    @commands.push(value)
  end

  def list
    @commands.clone
  end
end



def pbDefaultMap()
  return $game_map.map_id if $game_map
  return $data_system.edit_map_id if $data_system
  return 0
end

def pbWarpToMap()
  mapid=pbListScreen(_INTL("WARP TO MAP"),MapLister.new(pbDefaultMap()))
  if mapid>0
    map=Game_Map.new
    map.setup(mapid)
    success=false
    x=0
    y=0
    100.times do
      x=rand(map.width)
      y=rand(map.height)
      next if !map.passableStrict?(x,y,$game_player)
      blocked=false
      for event in map.events.values
        if event.x == x && event.y == y && !event.through
          blocked=true if self != $game_player || event.character_name != ""
        end
      end
      next if blocked
      success=true
      break
    end
    if !success
      x=rand(map.width)
      y=rand(map.height)
    end
    return [mapid,x,y]
  end
  return nil
end

def pbDebugMenu
  viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z=99999
  sprites={}
  commands=CommandList.new
  commands.add("switches",_INTL("Switches"))
  commands.add("variables",_INTL("Variables"))
  commands.add("refreshmap",_INTL("Refresh Map"))
  commands.add("warp",_INTL("Warp to Map"))
  commands.add("healparty",_INTL("Heal Party"))
  commands.add("additem",_INTL("Add Item"))
  commands.add("fillbag",_INTL("Fill Bag"))
  commands.add("clearbag",_INTL("Empty Bag"))
  commands.add("addpokemon",_INTL("Add Pokémon"))
  commands.add("completepokedex",_INTL("Complete Pokedex"))
  commands.add("completepokedexreal",_INTL("Complete Pokedex Real"))
  commands.add("completexenodexreal",_INTL("Complete Xenodex Real"))
  commands.add("completeretrodexreal",_INTL("Complete Retrodex Real"))
  commands.add("fillboxes",_INTL("Fill Storage Boxes"))  
  commands.add("clearboxes",_INTL("Clear Storage Boxes"))
  commands.add("usepc",_INTL("Use PC"))
  commands.add("setplayer",_INTL("Set Player Character"))
  commands.add("renameplayer",_INTL("Rename Player"))
  commands.add("randomid",_INTL("Randomise Player's ID"))
  commands.add("changeoutfit",_INTL("Change Player Outfit"))
  commands.add("setmoney",_INTL("Set Money"))
  commands.add("setcoins",_INTL("Set Coins"))
  commands.add("setbadges",_INTL("Set Badges"))
  commands.add("demoparty",_INTL("Give Demo Party"))
  commands.add("toggleshoes",_INTL("Toggle Running Shoes Ownership"))
  commands.add("togglepokegear",_INTL("Toggle Pokégear Ownership"))
  commands.add("togglepokedex",_INTL("Toggle Pokédex Ownership"))
  commands.add("dexlists",_INTL("Dex List Accessibility"))
  commands.add("togglemegaring",_INTL("Toggle Mega Ring Ownership"))
  commands.add("readyrematches",_INTL("Ready Phone Rematches"))
  commands.add("mysterygift",_INTL("Manage Mystery Gifts"))
  commands.add("daycare",_INTL("Day Care Options..."))
  commands.add("quickhatch",_INTL("Quick Hatch"))
  commands.add("roamerstatus",_INTL("Roaming Pokémon Status"))
  commands.add("roam",_INTL("Advance Roaming"))
  commands.add("setencounters",_INTL("Set Encounters")) 
  commands.add("setmetadata",_INTL("Set Metadata")) 
  commands.add("terraintags",_INTL("Set Terrain Tags"))
  commands.add("trainertypes",_INTL("Edit Trainer Types"))
  commands.add("resettrainers",_INTL("Reset Trainers"))
  commands.add("testwildbattle",_INTL("Test Wild Battle"))
  commands.add("testdoublewildbattle",_INTL("Test Double Wild Battle"))
  commands.add("testtrainerbattle",_INTL("Test Trainer Battle"))
  commands.add("testdoubletrainerbattle",_INTL("Test Double Trainer Battle"))
  commands.add("relicstone",_INTL("Relic Stone"))
  commands.add("purifychamber",_INTL("Purify Chamber"))
  commands.add("extracttext",_INTL("Extract Text"))
  commands.add("compiletext",_INTL("Compile Text"))
  commands.add("compiledata",_INTL("Compile Data"))
  commands.add("mapconnections",_INTL("Map Connections"))
  commands.add("animeditor",_INTL("Animation Editor"))
  commands.add("debugconsole",_INTL("Debug Console"))
  commands.add("togglelogging",_INTL("Toggle Battle Logging"))
  sprites["cmdwindow"]=Window_CommandPokemonEx.new(commands.list)
  cmdwindow=sprites["cmdwindow"]
  cmdwindow.viewport=viewport
  cmdwindow.resizeToFit(cmdwindow.commands)
  cmdwindow.height=Graphics.height if cmdwindow.height>Graphics.height
  cmdwindow.x=0
  cmdwindow.y=0
  cmdwindow.visible=true
  pbFadeInAndShow(sprites)
  ret=-1
  loop do
    loop do
      cmdwindow.update
      Graphics.update
      Input.update
      if Input.trigger?(Input::B)
        ret=-1
        break
      end
      if Input.trigger?(Input::C)
        ret=cmdwindow.index
        break
      end
    end
    break if ret==-1
    cmd=commands.getCommand(ret)
    if cmd=="switches"
      $scene=nil
    elsif cmd=="variables"
      $scene=nil
    elsif cmd=="refreshmap"
      $scene=nil
    elsif cmd=="warp"
      $scene=nil
    elsif cmd=="healparty"
      $scene=nil
    elsif cmd=="additem"
      $scene=nil
    elsif cmd=="fillbag"
      $scene=nil
    elsif cmd=="clearbag"
      $scene=nil
    elsif cmd=="addpokemon"
      $scene=nil
    elsif cmd == "completepokedex"
      $scene=nil
    elsif cmd == "completepokedexreal"
      $scene=nil
    elsif cmd == "completexenodexreal"
      $scene=nil
    elsif cmd == "completeretrodexreal"
      $scene=nil
    elsif cmd=="fillboxes"
      $scene=nil
    elsif cmd=="clearboxes"
      $scene=nil
    elsif cmd=="usepc"
      $scene=nil
    elsif cmd=="setplayer"
      $scene=nil
    elsif cmd=="renameplayer"
      $scene=nil
    elsif cmd=="randomid"
      $scene=nil
    elsif cmd=="changeoutfit"
      $scene=nil
    elsif cmd=="setmoney"
      $scene=nil
    elsif cmd=="setcoins"
      $scene=nil
    elsif cmd=="setbadges"
      $scene=nil
    elsif cmd=="demoparty"
      $scene=nil
    elsif cmd=="toggleshoes"
      $scene=nil
    elsif cmd=="togglepokegear"
      $scene=nil
    elsif cmd=="togglepokedex"
      $scene=nil
    elsif cmd=="dexlists"
      $scene=nil
    elsif cmd=="togglemegaring"
      $scene=nil
    elsif cmd=="readyrematches"
      $scene=nil
    elsif cmd=="mysterygift"
      $scene=nil
    elsif cmd=="daycare"
      $scene=nil
    elsif cmd=="quickhatch"
      $scene=nil
    elsif cmd=="roamerstatus"
      $scene=nil
    elsif cmd=="roam"
      $scene=nil
    elsif cmd=="setencounters"
      $scene=nil
    elsif cmd=="setmetadata"
      $scene=nil
    elsif cmd=="terraintags"
      $scene=nil
    elsif cmd=="trainertypes"
      $scene=nil
    elsif cmd=="resettrainers"
      $scene=nil
    elsif cmd=="testwildbattle"
      $scene=nil
    elsif cmd=="testdoublewildbattle"
      $scene=nil
    elsif cmd=="testtrainerbattle"
      $scene=nil
    elsif cmd=="testdoubletrainerbattle"
      $scene=nil
    elsif cmd=="relicstone"
      $scene=nil
    elsif cmd=="purifychamber"
      $scene=nil
    elsif cmd=="extracttext"
      $scene=nil
    elsif cmd=="compiletext"
      $scene=nil
    elsif cmd=="compiledata"
      $scene=nil
    elsif cmd=="mapconnections"
      $scene=nil
    elsif cmd=="animeditor"
      $scene=nil
    elsif cmd=="debugconsole"
      $scene=nil
    elsif cmd=="togglelogging"
      $scene=nil
    end
  end
  pbFadeOutAndHide(sprites)
  pbDisposeSpriteHash(sprites)
  viewport.dispose
end



class SpriteWindow_DebugRight < Window_DrawableCommand
  attr_reader :mode

  def initialize
    super(0, 0, Graphics.width, Graphics.height)
  end

  def shadowtext(x,y,w,h,t,align=0)
    width=self.contents.text_size(t).width
    if align==2
      x+=(w-width)
    elsif align==1
      x+=(w/2)-(width/2)
    end
    pbDrawShadowText(self.contents,x,y,[width,w].max,h,t,
       Color.new(12*8,12*8,12*8),Color.new(26*8,26*8,25*8))
  end

  def drawItem(index,count,rect)
    pbSetNarrowFont(self.contents)
    if @mode == 0
      name = $data_system.switches[index+1]
      status = $game_switches[index+1] ? "[ON]" : "[OFF]"
    else
      name = $data_system.variables[index+1]
      status = $game_variables[index+1].to_s
    end
    if name == nil
      name = ''
    end
    id_text = sprintf("%04d:", index+1)
    width = self.contents.text_size(id_text).width
    rect=drawCursor(index,rect)
    totalWidth=rect.width
    idWidth=totalWidth*15/100
    nameWidth=totalWidth*65/100
    statusWidth=totalWidth*20/100
    self.shadowtext(rect.x, rect.y, idWidth, rect.height, id_text)
    self.shadowtext(rect.x+idWidth, rect.y, nameWidth, rect.height, name)
    self.shadowtext(rect.x+idWidth+nameWidth, rect.y, statusWidth, rect.height, status, 2)
  end

  def itemCount
    return (@mode==0) ? $data_system.switches.size-1 : $data_system.variables.size-1
  end

  def mode=(mode)
    @mode = mode
    refresh
  end
end



def pbDebugSetVariable(id,diff)
  pbPlayCursorSE()
  $game_variables[id]=0 if $game_variables[id]==nil
  if $game_variables[id].is_a?(Numeric)
    $game_variables[id]=[$game_variables[id]+diff,99999999].min
    $game_variables[id]=[$game_variables[id],-99999999].max
  end
end

def pbDebugVariableScreen(id)
  value=0
  if $game_variables[id].is_a?(Numeric)
    value=$game_variables[id]
  end
  params=ChooseNumberParams.new
  params.setDefaultValue(value)
  params.setMaxDigits(8)
  params.setNegativesAllowed(true)
  value=Kernel.pbMessageChooseNumber(_INTL("Set variable {1}.",id),params)
  $game_variables[id]=[value,99999999].min
  $game_variables[id]=[$game_variables[id],-99999999].max
end

def pbDebugScreen(mode)
  viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z=99999
  sprites={}
  sprites["right_window"] = SpriteWindow_DebugRight.new  
  right_window=sprites["right_window"]
  right_window.mode=mode
  right_window.viewport=viewport
  right_window.active=true
  right_window.index=0
  pbFadeInAndShow(sprites)
  loop do
    Graphics.update
    Input.update
    pbUpdateSpriteHash(sprites)
    if Input.trigger?(Input::B)
      pbPlayCancelSE()
      break
    end
    current_id = right_window.index+1
    if mode == 0
      if Input.trigger?(Input::C)
        pbPlayDecisionSE()
        $game_switches[current_id] = (not $game_switches[current_id])
        right_window.refresh
      end
    elsif mode == 1
      if Input.repeat?(Input::RIGHT)
        pbDebugSetVariable(current_id,1)
        right_window.refresh
      elsif Input.repeat?(Input::LEFT)
        pbDebugSetVariable(current_id,-1)
        right_window.refresh
      elsif Input.trigger?(Input::C)
        pbDebugVariableScreen(current_id)
        right_window.refresh
      end
    end
  end
  pbFadeOutAndHide(sprites)
  pbDisposeSpriteHash(sprites)
  viewport.dispose
end



class Scene_Debug
  def main
    Graphics.transition(15)
    pbDebugMenu
    $scene=Scene_Map.new
    $game_map.refresh
    Graphics.freeze
  end
end
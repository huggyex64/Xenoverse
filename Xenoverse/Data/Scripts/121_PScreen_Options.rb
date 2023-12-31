class Window_PokemonOption < Window_DrawableCommand
  attr_reader :mustUpdateOptions

  def initialize(options,x,y,width,height)
    @options=options
    @nameBaseColor=Color.new(24*8,15*8,0)
    @nameShadowColor=Color.new(31*8,22*8,10*8)
    @selBaseColor=Color.new(31*8,6*8,3*8)
    @selShadowColor=Color.new(31*8,17*8,16*8)
    @optvalues=[]
    @mustUpdateOptions=false
    for i in 0...@options.length
      @optvalues[i]=0
    end
    super(x,y,width,height)
  end

  def [](i)
    return @optvalues[i]
  end

  def []=(i,value)
    @optvalues[i]=value
    refresh
  end

  def itemCount
    return @options.length+1
  end

  def drawItem(index,count,rect)
    rect=drawCursor(index,rect)
    optionname=(index==@options.length) ? _INTL("Esci") : @options[index].name
    optionwidth=(rect.width*9/20)
    pbDrawShadowText(self.contents,rect.x,rect.y,optionwidth,rect.height,optionname,
       @nameBaseColor,@nameShadowColor)
    self.contents.draw_text(rect.x,rect.y,optionwidth,rect.height,optionname)
    return if index==@options.length
    if @options[index].is_a?(EnumOption)
      if @options[index].values.length>1
        totalwidth=0
        for value in @options[index].values
          totalwidth+=self.contents.text_size(value).width
        end
        spacing=(optionwidth-totalwidth)/(@options[index].values.length-1)
        spacing=0 if spacing<0
        xpos=optionwidth+rect.x
        ivalue=0
        for value in @options[index].values
          pbDrawShadowText(self.contents,xpos,rect.y,optionwidth,rect.height,value,
             (ivalue==self[index]) ? @selBaseColor : self.baseColor,
             (ivalue==self[index]) ? @selShadowColor : self.shadowColor
          )
          self.contents.draw_text(xpos,rect.y,optionwidth,rect.height,value)
          xpos+=self.contents.text_size(value).width
          xpos+=spacing
          ivalue+=1
        end
      else
        pbDrawShadowText(self.contents,rect.x+optionwidth,rect.y,optionwidth,rect.height,
           optionname,self.baseColor,self.shadowColor)
      end
    elsif @options[index].is_a?(NumberOption)
      value=_ISPRINTF("{1:d}",@options[index].optstart+self[index])
      xpos=optionwidth+rect.x
      pbDrawShadowText(self.contents,xpos,rect.y,optionwidth,rect.height,value,
         @selBaseColor,@selShadowColor)
    else
      value=@options[index].values[self[index]]
      xpos=optionwidth+rect.x
      pbDrawShadowText(self.contents,xpos,rect.y,optionwidth,rect.height,value,
         @selBaseColor,@selShadowColor)
      self.contents.draw_text(xpos,rect.y,optionwidth,rect.height,value)
    end
  end

  def update
    dorefresh=false
    oldindex=self.index
    @mustUpdateOptions=false
    super
    dorefresh=self.index!=oldindex
    if self.active && self.index<@options.length
      if Input.repeat?(Input::LEFT)
        self[self.index]=@options[self.index].prev(self[self.index])
        dorefresh=true
        @mustUpdateOptions=true
      elsif Input.repeat?(Input::RIGHT)
        self[self.index]=@options[self.index].next(self[self.index])
        dorefresh=true
        @mustUpdateOptions=true
      end
    end
    refresh if dorefresh
  end
end



module PropertyMixin
  def get
    @getProc ? @getProc.call() : nil
  end

  def set(value)
    @setProc.call(value) if @setProc
  end
end



class EnumOption
  include PropertyMixin
  attr_reader :values
  attr_reader :name

  def initialize(name,options,getProc,setProc)            
    @values=options
    @name=name
    @getProc=getProc
    @setProc=setProc
  end

  def next(current)
    index=current+1
    index=@values.length-1 if index>@values.length-1
    return index
  end

  def prev(current)
    index=current-1
    index=0 if index<0
    return index
  end
end



class EnumOption2
  include PropertyMixin
  attr_reader :values
  attr_reader :name

  def initialize(name,options,getProc,setProc)             
    @values=options
    @name=name
    @getProc=getProc
    @setProc=setProc
  end

  def next(current)
    index=current+1
    index=@values.length-1 if index>@values.length-1
    return index
  end

  def prev(current)
    index=current-1
    index=0 if index<0
    return index
  end
end



class NumberOption
  include PropertyMixin
  attr_reader :name
  attr_reader :optstart

  def initialize(name,format,optstart,optend,getProc,setProc)
    @name=name
    @format=format
    @optstart=optstart
    @optend=optend
    @getProc=getProc
    @setProc=setProc
  end

  def next(current)
    index=current+@optstart
    index+=1
    if index>@optend
      index=@optstart
    end
    return index-@optstart
  end

  def prev(current)
    index=current+@optstart
    index-=1
    if index<@optstart
      index=@optend
    end
    return index-@optstart
  end
end

#####################
#
#  Stores game options
# Default options are at the top of script section SpriteWindow.

$SpeechFrames=[
  MessageConfig::TextSkinName, # Default: speech hgss 1
  "speech hgss 2",
  "speech hgss 3",
  "speech hgss 4",
  "speech hgss 5",
  "speech hgss 6",
  "speech hgss 7",
  "speech hgss 8",
  "speech hgss 9",
  "speech hgss 10",
  "speech hgss 11",
  "speech hgss 12",
  "speech hgss 13",
  "speech hgss 14",
  "speech hgss 15",
  "speech hgss 16",
  "speech hgss 17",
  "speech hgss 18",
  "speech hgss 19",
  "speech hgss 20",
  "speech pl 18"
]

$TextFrames=[
  "Graphics/Windowskins/"+MessageConfig::ChoiceSkinName, # Default: choice 1
  "Graphics/Windowskins/choice 2",
  "Graphics/Windowskins/choice 3",
  "Graphics/Windowskins/choice 4",
  "Graphics/Windowskins/choice 5",
  "Graphics/Windowskins/choice 6",
  "Graphics/Windowskins/choice 7",
  "Graphics/Windowskins/choice 8",
  "Graphics/Windowskins/choice 9",
  "Graphics/Windowskins/choice 10",
  "Graphics/Windowskins/choice 11",
  "Graphics/Windowskins/choice 12",
  "Graphics/Windowskins/choice 13",
  "Graphics/Windowskins/choice 14",
  "Graphics/Windowskins/choice 15",
  "Graphics/Windowskins/choice 16",
  "Graphics/Windowskins/choice 17",
  "Graphics/Windowskins/choice 18",
  "Graphics/Windowskins/choice 19",
  "Graphics/Windowskins/choice 20",
  "Graphics/Windowskins/choice 21",
  "Graphics/Windowskins/choice 22",
  "Graphics/Windowskins/choice 23",
  "Graphics/Windowskins/choice 24",
  "Graphics/Windowskins/choice 25",
  "Graphics/Windowskins/choice 26",
  "Graphics/Windowskins/choice 27",
  "Graphics/Windowskins/choice 28"
]

$VersionStyles=[
  [MessageConfig::FontName], # Default font style - Power Green/"Pokemon Emerald"
  ["Power Red and Blue"],
  ["Power Red and Green"],
  ["Power Clear"]
]

def pbSettingToTextSpeed(speed)
  return 2 if speed==0
  return 1 if speed==1
  return -2 if speed==2
  return MessageConfig::TextSpeed if MessageConfig::TextSpeed
  return ((Graphics.frame_rate>40) ? -2 : 1)
end



module MessageConfig
  def self.pbDefaultSystemFrame
    if !$PokemonSystem
      return pbResolveBitmap("Graphics/Windowskins/"+MessageConfig::ChoiceSkinName)||""
    else
      return pbResolveBitmap($TextFrames[$PokemonSystem.frame])||""
    end
  end

  def self.pbDefaultSpeechFrame
    if !$PokemonSystem
      return pbResolveBitmap("Graphics/Windowskins/"+MessageConfig::TextSkinName)||""
    else
      return pbResolveBitmap("Graphics/Windowskins/"+$SpeechFrames[$PokemonSystem.textskin])||""
    end
  end

  def self.pbDefaultSystemFontName
    if !$PokemonSystem
      return MessageConfig.pbTryFonts(MessageConfig::FontName,"Arial Narrow","Arial")
    else
      return MessageConfig.pbTryFonts($VersionStyles[$PokemonSystem.font][0],"Arial Narrow","Arial")
    end
  end

  def self.pbDefaultTextSpeed
    return pbSettingToTextSpeed($PokemonSystem ? $PokemonSystem.textspeed : nil)
  end

  def pbGetSystemTextSpeed
    return $PokemonSystem ? $PokemonSystem.textspeed : ((Graphics.frame_rate>40) ? 2 :  3)
  end
end



class PokemonSystem
  attr_accessor :textspeed
  attr_accessor :battlescene
  attr_accessor :battlestyle
  attr_accessor :frame
  attr_accessor :textskin
  attr_accessor :font
  attr_accessor :screensize
  attr_accessor :language

  def language
    return (!@language) ? 0 : @language
  end

  def textskin
    return (!@textskin) ? 0 : @textskin
  end

  def tilemap; return MAPVIEWMODE; end

  def initialize
    @textspeed   = 1   # Text speed (0=slow, 1=mid, 2=fast)
    @battlescene = 0   # Battle scene (animations) (0=on, 1=off)
    @battlestyle = 0   # Battle style (0=shift, 1=set)
    @frame       = 0   # Default window frame (see also $TextFrames)
    @textskin    = 0   # Speech frame
    @font        = 0   # Font (see also $VersionStyles)
    @screensize  = (DEFAULTSCREENZOOM.floor).to_i # 0=half size, 1=full size, 2=double size
    @language    = 0   # Language (see also LANGUAGES in script PokemonSystem)
  end
end



class PokemonOptionScene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

 def pbStartScene
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites["title"]=Window_UnformattedTextPokemon.newWithSize(
       _INTL("Opzioni"),0,0,Graphics.width,64,@viewport)
    @sprites["textbox"]=Kernel.pbCreateMessageWindow
    @sprites["textbox"].letterbyletter=false
    @sprites["textbox"].text=_INTL("Speech frame {1}.",1+$PokemonSystem.textskin)
    # These are the different options in the game.  To add an option, define a
    # setter and a getter for that option.  To delete an option, comment it out
    # or delete it.  The game's options may be placed in any order.
    @PokemonOptions=[
       EnumOption.new(_INTL("Velocità testo"),[_INTL("Lento"),_INTL("Medio"),_INTL("Veloce")],
          proc { $PokemonSystem.textspeed },
          proc {|value|  
             $PokemonSystem.textspeed=value 
             MessageConfig.pbSetTextSpeed(pbSettingToTextSpeed(value)) 
          }
       ),
       EnumOption.new(_INTL("Scena lotta"),[_INTL("On"),_INTL("Off")],
          proc { $PokemonSystem.battlescene },
          proc {|value|  $PokemonSystem.battlescene=value }
       ),
       EnumOption.new(_INTL("Stile lotta"),[_INTL("Shift"),_INTL("Set")],
          proc { $PokemonSystem.battlestyle },
          proc {|value|  $PokemonSystem.battlestyle=value }
       ),
=begin
       NumberOption.new(_INTL("Cornice dialogo"),_INTL("Type %d"),1,$SpeechFrames.length,
          proc { $PokemonSystem.textskin },
          proc {|value|  $PokemonSystem.textskin=value;
             MessageConfig.pbSetSpeechFrame(
                "Graphics/Windowskins/"+$SpeechFrames[value]) }
       ),
       NumberOption.new(_INTL("Cornice menù"),_INTL("Type %d"),1,$TextFrames.length,
          proc { $PokemonSystem.frame },
          proc {|value|  
             $PokemonSystem.frame=value
             MessageConfig.pbSetSystemFrame($TextFrames[value]) 
          }
       ),
       EnumOption.new(_INTL("Stile font"),[_INTL("Sme"),_INTL("R/Z"),_INTL("RFVF"),_INTL("DP")],
          proc { $PokemonSystem.font },
          proc {|value|  
             $PokemonSystem.font=value
             MessageConfig.pbSetSystemFontName($VersionStyles[value])
          }
       ),
=end
# Quote this section out if you don't want to allow players to change the screen
# size.
       EnumOption.new(_INTL("Schermo"),[_INTL("Medio"),_INTL("Grande")],
          proc { $PokemonSystem.screensize },
          proc {|value|
             oldvalue=$PokemonSystem.screensize
             $PokemonSystem.screensize=value
             $ResizeOffsetX=0
             $ResizeOffsetY=0
             pbSetResizeFactor([1.0,2.0][value])
             if value!=oldvalue
               ObjectSpace.each_object(TilemapLoader){|o| next if o.disposed?; o.updateClass }
             end
          }
       )
# ------------------------------------------------------------------------------
    ]
    @sprites["option"]=Window_PokemonOption.new(@PokemonOptions,0,
       @sprites["title"].height,Graphics.width,
       Graphics.height-@sprites["title"].height-@sprites["textbox"].height)
    @sprites["option"].viewport=@viewport
    @sprites["option"].visible=true
    # Get the values of each option
    for i in 0...@PokemonOptions.length
      @sprites["option"][i]=(@PokemonOptions[i].get || 0)
    end
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbOptions
    pbActivateWindow(@sprites,"option"){
       loop do
         Graphics.update
         Input.update
         pbUpdate
         if @sprites["option"].mustUpdateOptions
           # Set the values of each option
           for i in 0...@PokemonOptions.length
             @PokemonOptions[i].set(@sprites["option"][i])
           end
           @sprites["textbox"].setSkin(MessageConfig.pbGetSpeechFrame())
           @sprites["textbox"].width=@sprites["textbox"].width  # Necessary evil
           pbSetSystemFont(@sprites["textbox"].contents)
           @sprites["textbox"].text=_INTL("Speech frame {1}.",1+$PokemonSystem.textskin)
         end
         if Input.trigger?(Input::B)
           break
         end
         if Input.trigger?(Input::C) && @sprites["option"].index==@PokemonOptions.length
           break
         end
       end
    }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    # Set the values of each option
    for i in 0...@PokemonOptions.length
      @PokemonOptions[i].set(@sprites["option"][i])
    end
    Kernel.pbDisposeMessageWindow(@sprites["textbox"])
    pbDisposeSpriteHash(@sprites)
    pbRefreshSceneMap
    @viewport.dispose
  end
end



class PokemonOption
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbOptions
    @scene.pbEndScene
  end
end
#####################################################################
# ONLINE BATTLES
#####################################################################
class OnlineLobby
  attr_accessor(:playerList)
  attr_accessor(:selectionIndex)
  attr_accessor(:buttonSelectionIndex)
  attr_accessor(:canRefresh)


  LIGHTBLUE = Color.new(131,218,230)

  MAX_VISIBLE_PLAYERS = 11

  YES = _INTL("Yes")

  FADE_TIME = 12
  HEADER_TEXT_SPEED = 20 #Higher, slower

  def initialize()
    @canRefresh = false
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 9999
    @viewport2 = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport2.z = 999999
    @sprites={}

    @shownUI = false

    @listOffset = 0

    @path = "Graphics/Pictures/Online/"

    @selectionIndex = 0

    @buttonSelectionIndex = 1
    @buttonSelectionEnabled = false
    #ID - Name - Debug - Status
    @playerList=[]
    @frame = 0
    @toggleParty = false

    @lastServerMessage = ""

    status=[:blocked,:matchmaking,:trading,:waiting,:matched]
  

  
    pbFadeOutIn(999999){
      @sprites["bg"] = Sprite.new(@viewport)
      @sprites["bg"].bitmap = pbBitmap(@path + "BG")

      @sprites["animbg"]=AnimatedPlane.new(@viewport)
      @sprites["animbg"].bitmap=pbBitmap(@path + "repeatbg")

      @sprites["refresh"] = Sprite.new(@viewport)
      @sprites["refresh"].bitmap = pbBitmap(@path + "refresh")
      @sprites["refresh"].x = 242
      @sprites["refresh"].y = 304
      @sprites["refresh"].visible = false

      @sprites["list"] = Sprite.new(@viewport)
      @sprites["list"].bitmap = pbBitmap(@path + "playerlist")
      @sprites["list"].x = 14
      @sprites["list"].y = 44
      @sprites["list"].visible = false

      @sprites["avatarbox"] = EAMSprite.new(@viewport)
      @sprites["avatarbox"].bitmap = pbBitmap(@path + "avatarbox")
      @sprites["avatarbox"].x = 348
      @sprites["avatarbox"].y = 54
      @sprites["avatarbox"].visible = false

      id = $Trainer.online_trainer_type
      echoln id
      bmp = nil
      if pbResolveBitmap(sprintf("Graphics/Transitions/smTrainer%d",id)) != nil
        bmp = pbBitmap(sprintf("Graphics/Transitions/smTrainer%d",id))
      elsif pbResolveBitmap(sprintf("Graphics/Transitions/smSpecial%d",id)) != nil
        bmp = pbBitmap(sprintf("Graphics/Transitions/smSpecial%d",id))
      elsif checkIfNewTransition(id,true)#pbResolveBitmap(sprintf("Graphics/Transitions/SunMoon/%s%d",variant,id)) != nil
        variant = getNewTransitionVariant(id)
        bmp = pbBitmap(sprintf("Graphics/Transitions/SunMoon/%s%d",variant,id))
      end
      @sprites["avatar"] = Sprite.new(@viewport)
      if bmp != nil
        resbmp = Bitmap.new(bmp.width/2,bmp.height/2)
        resbmp.stretch_blt(Rect.new(0,0,bmp.width/2,bmp.height/2),bmp,Rect.new(0,0,bmp.width,bmp.height))
        @sprites["avatar"].bitmap = resbmp
        @sprites["avatar"].bitmap = @sprites["avatar"].bitmap.mask!(@path+"avatarbox",0,@sprites["avatar"].bitmap.height/6)
      end
      @sprites["avatar"].x = 348
      @sprites["avatar"].y = 54
      @sprites["avatar"].visible = false

      #self.createUI
    }
  end

  def displayUI(state)
    @shownUI = state
    @sprites["refresh"].visible = state
    @sprites["list"].visible = state
    @sprites["avatarbox"].visible = state
    @sprites["avatar"].visible = state
    if (state && @sprites["selection"]==nil)
      self.createUI
    end
  end

  def createBattleTimer 
    @viewport3 = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport3.z = 1000000
    @counter = {}
    @counter["bg"] = Sprite.new(@viewport3)
    @counter["bg"].y = 160
    @counter["bg"].bitmap = Bitmap.new(200,24)
    @counter["bg"].bitmap.fill_rect(0,0,200,24,Color.new(0,0,0,120))
    pbSetSmallFont(@counter["bg"].bitmap)
  end

  def updateTime(text)
    @counter["bg"].bitmap = Bitmap.new(200,24)
    @counter["bg"].bitmap.fill_rect(0,0,200,24,Color.new(0,0,0,120))
    pbSetSmallFont(@counter["bg"].bitmap)

    @counter["bg"].bitmap.draw_text(6,2,200,24,text)
  end

  def deleteBattleTimer
    @viewport3.dispose
    for sprite in @counter.values
      sprite.dispose if sprite.is_a?(Sprite)
    end
  end

  def toggleOpponentParty
    if !@toggleParty
      showParty
    else
      hideParty
    end
  end

  def createUI()
    @sprites["selection"] = Sprite.new(@viewport)
    @sprites["selection"].bitmap = Bitmap.new(298,23)
    @sprites["selection"].bitmap.fill_rect(0,0,298,23,Color.new(24,24,24,75))
    @sprites["selection"].x = 4 + @sprites["list"].x
    @sprites["selection"].y = 27+23*@selectionIndex + @sprites["list"].y
    @sprites["selection"].z = 4 #this has to be shown on top of others

    @sprites["status"] = Sprite.new(@viewport)
    @sprites["status"].bitmap = Bitmap.new(Graphics.width,30)
    #@sprites["status"].bitmap.fill_rect(0,0,300,30,Color.new(0,0,0,75))
    @sprites["status"].y = Graphics.height-30
    
    @sprites["partyBar"] = Sprite.new(@viewport2)
    @sprites["partyBar"].bitmap = Bitmap.new(Graphics.width,74)
    @sprites["partyBar"].bitmap.fill_rect(0,0,Graphics.width,74,Color.new(0,0,0,75))
    @sprites["partyBar"].z = 5
    @sprites["partyBar"].visible = false

    for i in 0...6
      @sprites["party#{i}"] = Sprite.new(@viewport2)
      @sprites["party#{i}"].x = 85*i
      @sprites["party#{i}"].z = 6
      @sprites["party#{i}"].visible = false
    end

    @sprites["battleButton"] = EAMSprite.new(@viewport)
    @sprites["battleButton"].bitmap = pbBitmap(@path + "battle").clone
    @sprites["battleButton"].x = 334
    @sprites["battleButton"].y = 196
    pbSetFont(@sprites["battleButton"].bitmap, "Barlow Condensed", 26)
    @sprites["battleButton"].bitmap.font.color=Color.new(24,24,24)
    @sprites["battleButton"].bitmap.draw_text(0,0,@sprites["battleButton"].bitmap.width,@sprites["battleButton"].bitmap.height,_INTL("Battle"),1)

    @sprites["tradeButton"] = EAMSprite.new(@viewport)
    @sprites["tradeButton"].bitmap = pbBitmap(@path + "trade").clone
    @sprites["tradeButton"].x = 334
    @sprites["tradeButton"].y = 238
    pbSetFont(@sprites["tradeButton"].bitmap, "Barlow Condensed", 26)
    @sprites["tradeButton"].bitmap.font.color=Color.new(24,24,24)
    @sprites["tradeButton"].bitmap.draw_text(0,0,@sprites["tradeButton"].bitmap.width,@sprites["tradeButton"].bitmap.height,_INTL("Trade"),1)

    @sprites["settingsButton"] = EAMSprite.new(@viewport)
    @sprites["settingsButton"].bitmap = pbBitmap(@path + "settings").clone
    @sprites["settingsButton"].x = Graphics.width-@sprites["settingsButton"].bitmap.width
    @sprites["settingsButton"].y = 284
    pbSetFont(@sprites["settingsButton"].bitmap, "Barlow Condensed", 22)
    @sprites["settingsButton"].bitmap.font.color=Color.new(24,24,24)
    @sprites["settingsButton"].bitmap.draw_text(0,0,@sprites["settingsButton"].bitmap.width,@sprites["settingsButton"].bitmap.height,_INTL("Settings"),1)

    @sprites["leaveButton"] = EAMSprite.new(@viewport)
    @sprites["leaveButton"].bitmap = pbBitmap(@path + "leave").clone
    @sprites["leaveButton"].x = Graphics.width-@sprites["leaveButton"].bitmap.width
    @sprites["leaveButton"].y = 318
    pbSetFont(@sprites["leaveButton"].bitmap, "Barlow Condensed", 22)
    @sprites["leaveButton"].bitmap.font.bold = true
    @sprites["leaveButton"].bitmap.font.color=Color.new(244,244,244)
    @sprites["leaveButton"].bitmap.draw_text(0,0,@sprites["leaveButton"].bitmap.width,@sprites["leaveButton"].bitmap.height,_INTL("Leave"),1)


    @buttons = [@sprites["avatarbox"],@sprites["battleButton"],@sprites["tradeButton"],@sprites["settingsButton"],@sprites["leaveButton"]]

    for b in @buttons
      b.fade(200,FADE_TIME,:ease_out_cubic)
    end

    @sprites["header"] = EAMSprite.new(@viewport)
    @sprites["header"].bitmap = pbBitmap(@path+"Header")
    @sprites["header"].z = 20
    @sprites["header"].y = -70
    @sprites["headerText"] = EAMSprite.new(@viewport)
    @sprites["headerText"].bitmap = Bitmap.new(Graphics.width,30)
    @sprites["headerText"].z = 21
    @sprites["headerText"].y = -70+14
    pbSetFont(@sprites["headerText"].bitmap, "Power Clear", 28)

    @sprites["headerLines"] = EAMSprite.new(@viewport)
    @sprites["headerLines"].bitmap = pbBitmap(@path + "HeaderLines")
    @sprites["headerLines"].opacity = 128
    @sprites["headerLines"].y = -70+12
    @sprites["headerLines"].z = 22

  end

  def updateServerMessage(text)
    echoln "Server message: #{text}"    
    if @lastServerMessage == "" && text != "" #appear
      echoln "The server message should slide down"
      @sprites["header"].move(0,0,40,:ease_out_cubic)
      #@sprites["headerText"].moveY(14,40,:ease_out_cubic)
      #@sprites["headerLines"].move(0,12,40,:ease_out_cubic)
    elsif @lastServerMessage != "" && text == "" #disappear
      echoln "The server message should slide up"
      @sprites["header"].move(0,-70,40,:ease_in_cubic)
      #@sprites["headerText"].moveY(-70+14,40,:ease_in_cubic)
      #@sprites["headerLines"].move(0,-70+12,40,:ease_in_cubic)
    end
    if @lastServerMessage != text
      echoln "Updating message!"

      @sprites["headerText"].bitmap = Bitmap.new(11*text.length,30)
      pbSetFont(@sprites["headerText"].bitmap, "Power Clear", $MKXP ? 23 : 25) #should be 31 to be pixel perfect but too bad
      @sprites["headerText"].bitmap.font.color=Color.new(235, 134, 33)
      @sprites["headerText"].bitmap.draw_text(0,0,@sprites["headerText"].bitmap.width,@sprites["headerText"].bitmap.height,text,0)
      #place it out of sight
      @sprites["headerText"].x = Graphics.width
      @sprites["headerText"].moveX(-@sprites["headerText"].bitmap.width,HEADER_TEXT_SPEED*text.length)
      @lastServerMessage = text
    end
  end

  def setButtonSelection(state)
    @buttonSelectionEnabled = state
    if state
      @buttonSelectionIndex = 1
      for i in 0...@buttons.length
        if i != @buttonSelectionIndex
          @buttons[i].fade(128,FADE_TIME,:ease_out_cubic) 
        else
          @buttons[i].fade(255,FADE_TIME,:ease_out_cubic) 
        end
      end
    else
      for b in @buttons
        b.fade(200,FADE_TIME,:ease_out_cubic)
      end
    end
  end

  def buttonSelection(amount)
    #0: Battle 1: Trade 2: Settings 3: Leave
    old_id = @buttonSelectionIndex
    @buttonSelectionIndex+=amount
    if @buttonSelectionIndex >= @buttons.length
      @buttonSelectionIndex = 0
    end
    if @buttonSelectionIndex < 0
      @buttonSelectionIndex = @buttons.length-1
    end

    @buttons[old_id].fade(128,FADE_TIME,:ease_out_cubic) if old_id < @buttons.length
    @buttons[@buttonSelectionIndex].fade(255,FADE_TIME,:ease_out_cubic) if @buttonSelectionIndex < @buttons.length

  end

  # don't care about showing or not
  def updateParty(party)
    for i in 0...party.length
      poke = party[i]
      @sprites["party#{i}"].bitmap = evaluateIcon(poke)
    end
  end

  def displayParty(party)
    for i in 0...6
      @sprites["party#{i}"].visible =false
    end
    @toggleParty = true
    @sprites["partyBar"].visible = true
    for i in 0...party.length
      poke = party[i]
      
      @sprites["party#{i}"].bitmap = evaluateIcon(poke)
      @sprites["party#{i}"].visible = true
    end
  end

  def hideParty    
    @sprites["partyBar"].visible = false
    for i in 0...6
      @sprites["party#{i}"].visible = false
    end
    @toggleParty = false
  end

  def showParty
    @sprites["partyBar"].visible = true
    for i in 0...6
      @sprites["party#{i}"].visible = true
    end
    @toggleParty = true
  end

  def updateStatus(text)
    @sprites["status"].bitmap.clear()
    @sprites["status"].bitmap.fill_rect(0,0,Graphics.width,30,Color.new(0,0,0,75))
    pbSetFont(@sprites["status"].bitmap, "Barlow Condensed", 24)
    @sprites["status"].bitmap.draw_text(6,0,Graphics.width,30,text)
  end

  def pbDisplayAvaiblePlayerList(list,moveselector = false)
    # Updating the list every time it gets updated on screen
    if list != @playerlist
      @playerList = list
    end

    
    moveSelector(0) if moveselector
    # Disposing of old sprites
    @sprites["list"].bitmap = pbBitmap(@path + "playerlist").clone
    pbSetFont(@sprites["list"].bitmap,"Barlow Condensed",22)
    textpos = [
      ["ID",12,4,0,Color.new(232,232,232)],
      [_INTL("Name"),102,4,0,Color.new(232,232,232)],
      [_INTL("Status"),244,4,0,Color.new(232,232,232)],
    ]
    imagepos = []
    for entry in @playerList
      if @playerList.index(entry) < @listOffset
        next
      end
      if @playerList.index(entry)+1-@listOffset > MAX_VISIBLE_PLAYERS
        break
      end
      y = 4+23*(@playerList.index(entry)+1-@listOffset)
      icony = 28+23*(@playerList.index(entry)-@listOffset)
      textpos.push(["#{"%05d" % entry[0]}",70,y,1,Color.new(22,22,22)])
      textpos.push(["#{entry[1]}",102,y,0,Color.new(22,22,22)])

      ballimage=@path + entry[3].to_s
      imagepos.push([ballimage,256,icony,0,0,-1,-1])
      #@sprites["list"].bitmap.draw_text(6,6+30*list.index(entry),250,30,"#{"%05d" % entry[0]}:#{entry[1]}-#{entry[3]}")
    end
    pbDrawTextPositions(@sprites["list"].bitmap,textpos)
    pbDrawImagePositions(@sprites["list"].bitmap,imagepos)
  end

  def disableSelector
    @sprites["selection"].visible = false
  end

  def enableSelector
    @sprites["selection"].visible = true
  end

  def moveSelector(amount)
    return if @playerList.length == 0 #No player online
    @selectionIndex+=amount
    if @selectionIndex-@listOffset>=MAX_VISIBLE_PLAYERS && amount > 0
      @listOffset+=amount
      pbDisplayAvaiblePlayerList(@playerList)
    elsif @selectionIndex < @listOffset
      @listOffset+=amount
      pbDisplayAvaiblePlayerList(@playerList)
    end


    if (@selectionIndex>=@playerList.length)
      if @selectionIndex>=MAX_VISIBLE_PLAYERS && amount > 0
        @listOffset=0
        pbDisplayAvaiblePlayerList(@playerList)
      end
      @selectionIndex = 0
    elsif (@selectionIndex < 0)
      @selectionIndex = @playerList.length - 1
      if @selectionIndex>=MAX_VISIBLE_PLAYERS
        @listOffset=@playerList.length - MAX_VISIBLE_PLAYERS
        pbDisplayAvaiblePlayerList(@playerList)
      else
        @listOffset=0
        pbDisplayAvaiblePlayerList(@playerList)
      end
    end

    echoln "MOVED SELECTION TO #{@selectionIndex} => OFFSET #{@listOffset}"
  end

  def pbAvatarSelectionScreen(msgwindow)
    sprites = {}
    sprites['bg'] = Sprite.new(@viewport)
    sprites['bg'].bitmap = pbBitmap(@path + "BG")
    #sprites['bg'].bitmap = Bitmap.new(Graphics.width,Graphics.height)
    #sprites['bg'].bitmap.fill_rect(0,0,Graphics.width,Graphics.height,LIGHTBLUE)
    sprites['bg'].z = 20
    sprites['bg'].visible = false
    oldz = msgwindow.z
    msgwindow.z = 999999

    
    currentSelectedAvatar = 0
    selectedAvatar = 0
    availableAvatars = CableClub.getOnlineTrainerTypeList()

    id = getConst(PBTrainers,availableAvatars[selectedAvatar].is_a?(Array) ? availableAvatars[selectedAvatar][$Trainer.gender] : availableAvatars[selectedAvatar])

    bmp = nil
    if pbResolveBitmap(sprintf("Graphics/Transitions/smTrainer%d",id)) != nil
      bmp = pbBitmap(sprintf("Graphics/Transitions/smTrainer%d",id))
    elsif pbResolveBitmap(sprintf("Graphics/Transitions/smSpecial%d",id)) != nil
      bmp = pbBitmap(sprintf("Graphics/Transitions/smSpecial%d",id))
    elsif checkIfNewTransition(id,true)#pbResolveBitmap(sprintf("Graphics/Transitions/SunMoon/%s%d",variant,id)) != nil
      variant = getNewTransitionVariant(id)
      bmp = pbBitmap(sprintf("Graphics/Transitions/SunMoon/%s%d",variant,id))
    end

    sprites['avatar'] = Sprite.new(@viewport)
    sprites['avatar'].z = 21
    sprites['avatar'].visible = false
    sprites['avatar'].bitmap = bmp if bmp != nil
    sprites['avatar'].ox = sprites['avatar'].bitmap.width/2 if bmp != nil
    sprites['avatar'].x = Graphics.width/2

    currentSelectedAvatar = 0
    selectedAvatar = 0
    availableAvatars = CableClub.getOnlineTrainerTypeList()
    pbFadeOutIn(999999){
      sprites['bg'].visible = true
      sprites['avatar'].visible = true
    }

    loop do
      Graphics.update
      Input.update

      if selectedAvatar != currentSelectedAvatar
        
        selectedAvatar = currentSelectedAvatar
        id = getConst(PBTrainers,availableAvatars[selectedAvatar].is_a?(Array) ? availableAvatars[selectedAvatar][$Trainer.gender] : availableAvatars[selectedAvatar])

        bmp = nil
        if pbResolveBitmap(sprintf("Graphics/Transitions/smTrainer%d",id)) != nil
          bmp = pbBitmap(sprintf("Graphics/Transitions/smTrainer%d",id))
        elsif pbResolveBitmap(sprintf("Graphics/Transitions/smSpecial%d",id)) != nil
          bmp = pbBitmap(sprintf("Graphics/Transitions/smSpecial%d",id))
        elsif checkIfNewTransition(id,true)#pbResolveBitmap(sprintf("Graphics/Transitions/SunMoon/%s%d",variant,id)) != nil
          variant = getNewTransitionVariant(id)
          bmp = pbBitmap(sprintf("Graphics/Transitions/SunMoon/%s%d",variant,id))
        end

        sprites['avatar'].bitmap = bmp if bmp != nil
        echoln "Updated to selectedAvatar #{selectedAvatar}"
      end


      if Input.trigger?(Input::RIGHT)
        currentSelectedAvatar+=1
        echoln "Updated currentSelectedAvatar #{currentSelectedAvatar}"
        if (currentSelectedAvatar>=availableAvatars.length)
          currentSelectedAvatar=0
        end
      end

      if Input.trigger?(Input::LEFT)
        currentSelectedAvatar-=1
        echoln "Updated currentSelectedAvatar #{currentSelectedAvatar}"
        if (currentSelectedAvatar<0)
          currentSelectedAvatar=availableAvatars.length-1
        end
      end

      if Input.trigger?(Input::C)
        if selectedAvatar != currentSelectedAvatar
        
          selectedAvatar = currentSelectedAvatar
          id = getConst(PBTrainers,availableAvatars[selectedAvatar].is_a?(Array) ? availableAvatars[selectedAvatar][$Trainer.gender] : availableAvatars[selectedAvatar])
  
          bmp = nil
          if pbResolveBitmap(sprintf("Graphics/Transitions/smTrainer%d",id)) != nil
            bmp = pbBitmap(sprintf("Graphics/Transitions/smTrainer%d",id))
          elsif pbResolveBitmap(sprintf("Graphics/Transitions/smSpecial%d",id)) != nil
            bmp = pbBitmap(sprintf("Graphics/Transitions/smSpecial%d",id))
          elsif checkIfNewTransition(id,true)#pbResolveBitmap(sprintf("Graphics/Transitions/SunMoon/%s%d",variant,id)) != nil
            variant = getNewTransitionVariant(id)
            bmp = pbBitmap(sprintf("Graphics/Transitions/SunMoon/%s%d",variant,id))
          end
  
          sprites['avatar'].bitmap = bmp if bmp != nil
          echoln "Updated to selectedAvatar #{selectedAvatar}"
        end
        trainername=PBTrainers.getName(id)
        if ['a','e','i','o','u'].include?(trainername[0,1].downcase)
          msg=_INTL("Would you like to look like an {1}?",trainername)
        else
          msg=_INTL("Would you like to look like a {1}?",trainername)
        end
        Kernel.pbMessageDisplay(msgwindow,msg)
        if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
          #accept, thus change the avatar
          $Trainer.online_trainer_type=id
          if bmp != nil
            resbmp = Bitmap.new(bmp.width/2,bmp.height/2)
            resbmp.stretch_blt(Rect.new(0,0,bmp.width/2,bmp.height/2),bmp,Rect.new(0,0,bmp.width,bmp.height))
            @sprites["avatar"].bitmap = resbmp
            @sprites["avatar"].bitmap = @sprites["avatar"].bitmap.mask!(@path+"avatarbox",0,@sprites["avatar"].bitmap.height/6)
          end
          break
        end
      end

      if Input.trigger?(Input::B)
        Kernel.pbMessageDisplay(msgwindow,_INTL("Would you like to go back?"))
        if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
          break
        end
      end
    end

    msgwindow.z = oldz
    pbFadeOutIn(999999) { 
      Graphics.update;
      Input.update;
      sprites['bg'].visible = false
      sprites['avatar'].visible = false
     }
    
    pbDisposeSpriteHash(sprites)
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
		if pokemon.form>0
			if pokemon.isDelta?
				bmp+="d"
			else
				bmp+="_#{pokemon.form}"
			end
		end
    if pokemon.isDelta?
      bmp+="d"
    end
		bitmap = pbBitmap(bmp).clone
		if pokemon.isShiny?#item>0
			bitmap.blt(0,0,pbBitmap(BOX_PATH + "shiny"),Rect.new(0,0,31,29))
		end
		return bitmap
	end

  # This is supposed to be called with Input.update and Graphics.update inside a loop,
  # so no need to add those here
  def update
    return if !@shownUI

    #updating the selection bar position
    @sprites["selection"].y = 27+23*(@selectionIndex-@listOffset) + @sprites["list"].y


    for button in @buttons
      button.update
    end

    @sprites["header"].update
    @sprites["headerText"].update
    @sprites["headerText"].y = @sprites["header"].y + 8
    @sprites["headerLines"].y = @sprites["header"].y + 12

    if @sprites["headerText"].x == -@sprites["headerText"].bitmap.width
      @sprites["headerText"].x = Graphics.width
      @sprites["headerText"].moveX(-@sprites["headerText"].bitmap.width,HEADER_TEXT_SPEED)
    end

    @sprites["refresh"].opacity = @canRefresh ? 255 : 128

    @sprites["animbg"].oy += 1
    @sprites["animbg"].ox += 1
  end


  def dispose
    @viewport.dispose
    for sprite in @sprites.values
      sprite.dispose if sprite.is_a?(Sprite)
    end
  end
end

def pbCheckOpenProcess(processname)
  status = `tasklist | find "#{processname}"`
  if status.empty?
    #echoln "Process #{processname} is not running"
    return false
  else
    echoln "Process #{processname} is running"
    return true
  end
end

def pbCheckForCE(connection)
end


class BattleRequest
  #weedleteam
  #@@url = "https://www.weedleteam.com/request.php"

  @@url = "http://xntst.altervista.org/BattleRequest.php"

  ### MAIN UTILITY METHODS HERE
  def self.makeRequest(type, data = {})
      data["type"] = type
      return pbPostData(@@url,data)
  end

  def self.requestGift(type, code, data = {})
      data["type"] = type
      data["code"] = code
      return pbPostData(@@url,data)
  end

  def self.exists(type, code, data={})
      data["type"] = type
      data["code"] = code
      return pbPostData(@@url,data)
  end
  
  ### SHORTHANDS
  def self.getPlayerList()
    data={}
    data["type"] = "getPlayerList"
    res = pbPostData(@@url,data)
    playerlist = []
    for entry in res.split("\r\n")
      player = entry.split("</s>")
      player[-1] = player[-1].to_sym
      playerlist.push(player)
    end
    return playerlist
  end


end

def pbTOB
  roomno = rand(100000)
  res = BattleRequest.makeRequest("makeRoom",{"RoomNo"=>roomno})
  echoln res

  alive = true
  while(alive)
    #checks the room status every second. 
    pbWait(60)
    echoln BattleRequest.makeRequest("getDebug",{"RoomNo"=>roomno})

    if(Input.trigger?(Input::B))
      alive = false
    end
  end
end

def pbTO(roomno)
  alive = true
  while(alive)
    #checks the room status every second. 
    pbWait(60)
    echoln BattleRequest.makeRequest("getDebug",{"RoomNo"=>roomno})

    if(Input.trigger?(Input::B))
      alive = false
    end
  end
end
def pbOnlineLobby
  lobby = OnlineLobby.new
  if $Trainer.party.length == 0
    Kernel.pbMessage(_INTL("I'm sorry, you must have a Pokémon to enter the Cable Club."))
    lobby.dispose
    return
  end
  
  #oldParty = $Trainer.party
  msgwindow = Kernel.pbCreateMessageWindow()
  msgwindow.z = 10000
  begin
    Kernel.pbMessageDisplay(msgwindow, _INTL("Starting connection..."),false)
    pbWait(5)
    partner_trainer_id = ""
    #loop do
    #  partner_trainer_id = Kernel.pbFreeText(msgwindow, partner_trainer_id, false, 5)
    #  return if partner_trainer_id.empty?
    #  break if partner_trainer_id =~ /^[0-9]{5}$/
    #  Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} is not a trainer ID.", partner_trainer_id))
    #end

    # HINT: Startup/Cleanup required for Khaikaa's v17 for some reason.
    begin
      wsadata = "\0" * 1024 # Hope this is big enough, I don't have a compiler to sizeof(WSADATA) on...
      res = Win32API.new("ws2_32", "WSAStartup", "IP", "I").call(0x0202, wsadata)
      case res
        #Actual connection
      when 0; CableClub::enlist(msgwindow,lobby)
      else; raise Connection::Disconnected.new("winsock error")
      end
    ensure
      Win32API.new("ws2_32", "WSACleanup", "", "").call()
    end
    raise Connection::Disconnected.new("disconnected")
  rescue Connection::Disconnected => e
    msgwindow.visible = true
    lobby.dispose
    
    #$Trainer.party = oldParty
    case e.message
    when "disconnected"
      Kernel.pbMessageDisplay(msgwindow, _INTL("Thank you for using the Cable Club. We hope to see you again soon."))
      return true
    when "invalid party"
      Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, your party contains Pokémon not allowed in the Cable Club."))
      return false
    when "peer disconnected"
      Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, the other trainer has disconnected."))
      return true
    else
      Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, the Cable Club server has malfunctioned!"))
      return false
    end
  rescue Errno::ECONNREFUSED
    Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, the Cable Club server is down at the moment."))
    return false
  rescue
    pbPrintException($!)
    Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, the Cable Club has malfunctioned!"))
    return false
  ensure
    Kernel.pbDisposeMessageWindow(msgwindow)
    lobby.dispose
  end
  
end

########################################################################
# Online Features are down here
########################################################################
  
module CableClub
  HOST = "95.173.136.70" # for fun and profit
  PORT = 9999

  
  ONLINE_TRAINER_TYPE_LIST = [
    [:KAYAEROPORTO,:ALICEAEROPORTO],
   # [:POKEMONTRAINER_Red,:POKEMONTRAINER_Leaf],
   # [:PSYCHIC_M,:PSYCHIC_F],
   # [:BLACKBELT,:CRUSHGIRL],
   # [:COOLTRAINER_M,:COOLTRAINER_F]
  ]

  BATTLE_TIERS={
    :anythinggoes => Proc.new {|x| true},
    :retroonly => Proc.new {|x| RETRODEX.include?(x.species)},
  }

  BATTLE_TIERS_NAMES={
    :anythinggoes => _INTL("Anything Goes"),
    :retroonly => _INTL("Retro Only")
  }

  BATTLE_TIERS_NUMBERS={
    :anythinggoes =>{
      :single => 3,
      :double => 4
    },
    :retroonly =>{
      :single => 3,
      :double => 4
    },
  }

  def self.getOnlineTrainerTypeList()
    ret = []
    # Standard
    ret.push([:KAYAEROPORTO,:ALICEAEROPORTO])
    # Alter
    ret.push([:DARKKAYTRISHOUT,:DARKALICETRISHOUT]) 
    ret.push([:PROFESSORE,:PROFESSORESSA])
    ret.push(:GENERALEVICTOR)
    ret.push(:GOLD)
    # Cardinals
    ret.push(:CHUA)
    ret.push(:CASTALIA)
    ret.push(:PEYOTE)
    ret.push(:OLEANDRO)
    # Champ
    ret.push(:ASTER)
    ret.push(:VERSIL)
    # Tamara R34 <3
    ret.push(:TAMARAFURIA)
    # VIPs
    ret.push(:LANCETOURNAMENT)
    ret.push(:ERIKATOURNAMENT)
    ret.push(:LEOTOURNAMENT)
    ret.push(:DANTETOURNAMENT)
    return ret
  end
end

class PokeBattle_Trainer
  attr_writer :online_trainer_type
  def online_trainer_type
    return @online_trainer_type || getConst(PBTrainers,CableClub.getOnlineTrainerTypeList()[0][$Trainer.gender])#self.trainertype
  end

  attr_accessor :backupParty
end

# TODO: Automatically timeout.


def pbGetTiersNames()
  ret = []
  for t in CableClub::BATTLE_TIERS.keys
    ret.push([CableClub::BATTLE_TIERS_NAMES[t],t])
  end
  ret.sort! {|x,y| x[0]<=>y[0]}
  return ret + [[_INTL("Cancel"),-1]]
end



# Returns false if an error occurred.
def pbCableClub
  if $Trainer.party.length == 0
    Kernel.pbMessage(_INTL("I'm sorry, you must have a Pokémon to enter the Cable Club."))
    return
  end
  msgwindow = Kernel.pbCreateMessageWindow()
  begin
    Kernel.pbMessageDisplay(msgwindow, _ISPRINTF("What's the ID of the trainer you're searching for? (Your ID: {1:05d})\\^",$Trainer.publicID($Trainer.id)))
    partner_trainer_id = ""
    loop do
      partner_trainer_id = Kernel.pbFreeText(msgwindow, partner_trainer_id, false, 5)
      return if partner_trainer_id.empty?
      break if partner_trainer_id =~ /^[0-9]{5}$/
      Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} is not a trainer ID.", partner_trainer_id))
    end
    # HINT: Startup/Cleanup required for Khaikaa's v17 for some reason.
    begin
      wsadata = "\0" * 1024 # Hope this is big enough, I don't have a compiler to sizeof(WSADATA) on...
      res = Win32API.new("ws2_32", "WSAStartup", "IP", "I").call(0x0202, wsadata)
      case res
      when 0; CableClub::connect_to(msgwindow, partner_trainer_id)
      else; raise Connection::Disconnected.new("winsock error")
      end
    ensure
      Win32API.new("ws2_32", "WSACleanup", "", "").call()
    end
    raise Connection::Disconnected.new("disconnected")
  rescue Connection::Disconnected => e
    case e.message
    when "disconnected"
      Kernel.pbMessageDisplay(msgwindow, _INTL("Thank you for using the Cable Club. We hope to see you again soon."))
      return true
    when "invalid party"
      Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, your party contains Pokémon not allowed in the Cable Club."))
      return false
    when "peer disconnected"
      Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, the other trainer has disconnected."))
      return true
    else
      Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, the Cable Club server has malfunctioned!"))
      return false
    end
  rescue Errno::ECONNREFUSED
    Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, the Cable Club server is down at the moment."))
    return false
  rescue
    pbPrintException($!)
    Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, the Cable Club has malfunctioned!"))
    return false
  ensure
    Kernel.pbDisposeMessageWindow(msgwindow)
  end
end

module CableClub
  attr_accessor :timeoutCounter
  attr_reader   :maxTimeOut

  def self.timeoutCounter
    @timeoutCounter = 0 if @timeoutCounter == nil
    return @timeoutCounter
  end

  def self.timeoutCounter=(value)
    @timeoutCounter = value
    return @timeoutCounter
  end

  def self.maxTimeOut
    return 300 if @maxTimeOut == nil
    return @maxTimeOut
  end

  def self.pokemon_order(client_id)
    case client_id
    when 0; [0, 1, 2, 3]
    when 1; [1, 0, 3, 2]
    else; raise "Unknown client_id: #{client_id}"
    end
  end

  def self.pokemon_target_order(client_id)
    case client_id
    when 0..1; [1, 0, 3, 2]
    else; raise "Unknown client_id: #{client_id}"
    end
  end

  def self.resetPartner()
    @partner_uid = ""
    @partner_id = -1
    @partner_name = nil
    @partner_party = nil
  end

  def self.handle_await_server(connection,msgwindow)
    if connection.can_send?
      connection.send do |writer|
        writer.sym(:enlist)
        writer.str($Trainer.name + ":#{@md5}:#{@uid}" )
        writer.int($Trainer.id)
        #writer.int($Trainer.online_trainer_type)
        write_party(writer)
      end   
      pbFadeOutIn(999999){
        @ui.displayUI(true)
        @ui.pbDisplayAvaiblePlayerList(getPlayerList)
      }
      @state = :enlisted
    else
      pbMessageDisplayDots(msgwindow, _ISPRINTF("Your ID: {1:05d}\\nConnecting to online server",$Trainer.publicID($Trainer.id)), @frame)
    end
  end

  def self.canRefreshPlayerList?()
    return @frame / 180 > 0
  end

  def self.getPlayerList()
    ret = BattleRequest.getPlayerList()
    toremove = nil
    for entry in ret
      toremove = entry if entry[2]==@uid
    end
    ret.delete(toremove)
    return ret
  end

  def self.handle_enlist(connection,msgwindow)
    ####### Input handling for enlisted state
    # In this kind of state we want to be able to go up and down the player list, and be able to refresh it.
    @ui.hideParty

    #echoln "Handling enlist! Can refresh player list? #{canRefreshPlayerList?()}"
    if Input.trigger?(Input::F5) && canRefreshPlayerList?()
      Kernel.pbMessage("Refreshing player list...")
      @ui.pbDisplayAvaiblePlayerList(getPlayerList())
      @frame = 0
    end

    if Input.trigger?(Input::UP)
      if @navigatingPlayerList
        @ui.moveSelector(-1)
      else
        @ui.buttonSelection(-1)
      end
      @ui.update
    end
    if Input.trigger?(Input::DOWN)
      if @navigatingPlayerList
        @ui.moveSelector(1)
      else
        @ui.buttonSelection(1)
      end
      @ui.update
    end

    if Input.trigger?(Input::RIGHT) && @navigatingPlayerList
      @navigatingPlayerList = false
      @ui.disableSelector
      @ui.setButtonSelection(true)
    end

    if Input.trigger?(Input::LEFT) && !@navigatingPlayerList
      @navigatingPlayerList = true
      @ui.enableSelector
      @ui.setButtonSelection(false)
    end



    if Input.triggerex?(0x24)
      connection.send do |writer|
        writer.sym(:fwd)
        writer.str(@ui.playerList[@ui.selectionIndex][2])
        writer.sym(:message)
        writer.str(pbEnterText("Daje",0,50))
      end
      Kernel.pbMessage("Wow")
    end

    if Input.trigger?(Input::C)
      if @navigatingPlayerList
        if @ui.playerList.length>0
          msgwindow.visible = true
          Kernel.pbMessageDisplay(msgwindow, _INTL("Do you want to start a connection with {1}?",@ui.playerList[@ui.selectionIndex][1]))
          if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
            Kernel.pbMessageDisplay(msgwindow, _INTL("Vuoi inviare un messaggio a {1}?",@ui.playerList[@ui.selectionIndex][1]))
            if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
              sendMessage = pbEnterText("Messaggio da inviare?", 0, 50, _INTL("Ciao! Vuoi connetterti?"))
            else
              sendMessage = ""
            end
            connection.send do |writer|
              writer.sym(:fwd)
              writer.str(@ui.playerList[@ui.selectionIndex][2])
              writer.sym(:askAcceptInteraction)
              writer.int($Trainer.id)
              writer.str($Trainer.name)
              writer.str(@uid)
              writer.str(sendMessage)
            end
            @client_id = 0
            @partner_uid = @ui.playerList[@ui.selectionIndex][2]
            @partner_name = @ui.playerList[@ui.selectionIndex][1]
            @state = :await_interaction_accept
            @timeoutCounter = 0
            return
          else
            msgwindow.visible = false
            pbWait(8)
          end
        else
          pbPlayBuzzerSE()
        end
      else
        case @ui.buttonSelectionIndex
        when 0 #Avatar
          msgwindow.visible = true
          Kernel.pbMessageDisplay(msgwindow, _INTL("Would you like to change your avatar?"))
          if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
            # Requesting the list of available avatars
            @ui.pbAvatarSelectionScreen(msgwindow)
          else
            Kernel.pbMessageDisplay(msgwindow, _INTL("Skipped connection."))
          end
          msgwindow.visible = false
        when 1 #Battle matchmaking
          msgwindow.visible = true
          Kernel.pbMessageDisplay(msgwindow, _INTL("Would you like to enter unranked matchmaking?"),false)
          if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
            # Send unranked matchmaking info
            Kernel.pbMessageDisplay(msgwindow, _INTL("What kind of battle would you like to take part in?"))
            command = Kernel.pbShowCommands(msgwindow, [_INTL("Single Battle"), _INTL("Double Battle"), _INTL("No")], 2)
            if command != 2
              @battle_type = case command
              when 0; :single
              when 1; :double
              else; raise "Unknown battle type"
              end

              @chosenTier = chooseTier(msgwindow,@battle_type,nil)

              if (@chosenTier == nil)
                return
              end

              connection.send do |writer|
                writer.sym(:searchUnranked)
                writer.sym(@battle_type)
                writer.sym(@chosenTier)
              end
              @cancancelSelection = false
              @battleTeam = nil
              @state=:unrankedMatchmaking
              Kernel.pbMessageDisplay(msgwindow, _INTL("Matchmaking..."),false)
              return
            else
              msgwindow.visible = false
            end
          else
            Kernel.pbMessageDisplay(msgwindow, _INTL("Skipped connection."))
          end
          msgwindow.visible = false
        when 2 #wonder trade matchmaking
          msgwindow.visible = true
          if $Trainer.party.length < 2
            Kernel.pbMessageDisplay(msgwindow, _INTL("Can't enter wonder trade with less than 2 Pokémon."),false)
          else
            Kernel.pbMessageDisplay(msgwindow, _INTL("Would you like to start the WONDER trade?"),false)
            if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
              valid = false
              while !valid
                @wtchosen = choose_pokemon
                if $Trainer.party[@wtchosen].isEgg?
                  if $Trainer.party.any? { |p| 
                    p != $Trainer.party[@wtchosen] && p.hp > 0 && !p.isEgg?}
                    valid = true
                  end
                end
                if $Trainer.party[@wtchosen].hp > 0 && ![PBSpecies::SHYLEON,PBSpecies::TRISHOUT,PBSpecies::SHULONG].include?($Trainer.party[@wtchosen].species)
                  valid = true
                end
              end
              if @wtchosen >= 0
                connection.send do |writer|
                  writer.sym(:wonderTrade)
                  write_pkmn(writer,$Trainer.party[@wtchosen])
                end
                @state = :wonderTrading
                return
              end
            else
            end
          end
          msgwindow.visible = false
        when 3 # settings
          return
        when 4 # leave
          return
        end
      end
    end
    
    if Input.press?(Input::A) && false
      Kernel.pbMessageDisplay(msgwindow, _INTL("Would you like to change your avatar?"))
      if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
        # Requesting the list of available avatars
        @ui.pbAvatarSelectionScreen(msgwindow)
      else
        Kernel.pbMessageDisplay(msgwindow, _INTL("Skipped connection."))
      end
    end

    if Input.trigger?(Input::R) && false
      msgwindow.visible = true
      if $Trainer.party.length < 2
        Kernel.pbMessageDisplay(msgwindow, _INTL("Can't enter wonder trade with less than 2 Pokémon."),false)
      else
        Kernel.pbMessageDisplay(msgwindow, _INTL("Would you like to start the WONDER trade?"),false)
        if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
          valid = false
          while !valid
            @wtchosen = choose_pokemon
            if $Trainer.party[@wtchosen].isEgg?
              if $Trainer.party.any? { |p| 
                p != $Trainer.party[@wtchosen] && p.hp > 0 && !p.isEgg?}
                valid = true
              end
            end
            if $Trainer.party[@wtchosen].hp > 0 && ![PBSpecies::SHYLEON,PBSpecies::TRISHOUT,PBSpecies::SHULONG].include?($Trainer.party[@wtchosen].species)
              valid = true
            end
          end
          if @wtchosen >= 0
            connection.send do |writer|
              writer.sym(:wonderTrade)
              write_pkmn(writer,$Trainer.party[@wtchosen])
            end
            @state = :wonderTrading
            return
          end
        else
        end
      end
      msgwindow.visible = false
    end

    # tasto Q
    if Input.press?(Input::L) && false
      msgwindow.visible = true
      Kernel.pbMessageDisplay(msgwindow, _INTL("Would you like to enter unranked matchmaking?"),false)
      if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
        # Send unranked matchmaking info
        Kernel.pbMessageDisplay(msgwindow, _INTL("What kind of battle would you like to take part in?"))
        command = Kernel.pbShowCommands(msgwindow, [_INTL("Single Battle"), _INTL("Double Battle"), _INTL("No")], 2)
        if command != 2
          @battle_type = case command
          when 0; :single
          when 1; :double
          else; raise "Unknown battle type"
          end

          @chosenTier = chooseTier(msgwindow,@battle_type,nil)

          if (@chosenTier == nil)
            return
          end

          connection.send do |writer|
            writer.sym(:searchUnranked)
            writer.sym(@battle_type)
            writer.sym(@chosenTier)
          end
          @cancancelSelection = false
          @battleTeam = nil
          @state=:unrankedMatchmaking
          Kernel.pbMessageDisplay(msgwindow, _INTL("Matchmaking..."),false)
          return
        end
      else
        Kernel.pbMessageDisplay(msgwindow, _INTL("Skipped connection."))
      end
      msgwindow.visible = false
    end

    ##################################################
    ## Standard handling for the remainder
    ##################################################


    #QUESTO È IL PROBLEMA
    #pbMessageDisplayDots(msgwindow, _ISPRINTF("Your ID: {1:05d}\\nEnlisted, waiting to join lobby",$Trainer.publicID($Trainer.id)), @frame)    

    #if (@frame%60 == 0) #Requesting player list every X seconds
      #@ui.pbDisplayAvaiblePlayerList(BattleRequest.getPlayerList())
    #end

    connection.updateExp([:found,:askAcceptInteraction,:message,:serverMessage]) do |record|
      case (type = record.sym)
      when :found
        @client_id = record.int
        @partner_name = record.str
        @partner_party = parse_party(record)
        Kernel.pbMessageDisplay(msgwindow, _INTL("{1} connected!", @partner_name))
        if @client_id == 0
          @state = :choose_activity
        else
          @state = :await_choose_activity
        end
      when :askAcceptInteraction
        id = record.int
        name = record.str
        uid = record.str
        greetmessage = record.str
        msgwindow.visible = true
        if greetmessage == ""
          greetmessage = _INTL("{1} asked for connection. Do you want to start the connection?\\^",name)
        else
          greetmessage = "#{name}: #{greetmessage}"
        end  
        Kernel.pbMessageDisplay(msgwindow, greetmessage)
        command = Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2)
        # Accepted
        if command == 0
          @partner_name = name
          @partner_id = id
          @partner_uid = uid
          if connection.can_send?
            connection.send do |writer|
              writer.sym(:fwd)
              writer.str(@partner_uid)
              writer.sym(:acceptInteraction)
              writer.str($Trainer.name)
              write_party(writer)
            end
          end
          @client_id = 1
          @state = :await_partner
        else

          Kernel.pbMessageDisplay(msgwindow, _INTL("Connection refused.\\^"))
          if connection.can_send?
            connection.send do |writer|
              writer.sym(:fwd)
              writer.str(uid)
              writer.sym(:cancel)
            end
          end
          msgwindow.visible = false
        end
      when :serverMessage      
        @ui.updateServerMessage(record.str)
      when :message
        Kernel.pbMessage(record.str)
      else
        raise "Unknown message: #{type}"
      end
    end
  end

  def self.handle_wonder_trading(connection,msgwindow)
    pbMessageDisplayDots(msgwindow,_INTL("Wonder trading"),@frame)
    connection.updateExp([:wtFound]) do |record|
      case(type=record.sym)
      when :wtFound
        partner_name = record.str
        partner_pkmn = parse_pkmn(record)
        your_pkmn = $Trainer.party[@wtchosen]
        partner_speciesname = (partner_pkmn.isEgg?) ? _INTL("Egg") : PBSpecies.getName(getID(PBSpecies,partner_pkmn.species))
        your_speciesname = (your_pkmn.isEgg?) ? _INTL("Egg") : PBSpecies.getName(getID(PBSpecies,your_pkmn.species))
        # HERE THE ACTUAL TRADE IS BEING HANDLED          
        partner = PokeBattle_Trainer.new(partner_name, $Trainer.trainertype)
        do_trade(@wtchosen, partner, partner_pkmn) #trade scene
        
        @wtchosen=-1
        @state = :enlisted
      else
        raise "Unknown message: #{type}"
      end
    end
  end

  def self.handle_unranked_matchmaking(connection,msgwindow)
    connection.updateExp([:foundOpponent,:trainerData]) do |record|
      case(type = record.sym)
      when :foundOpponent
        @partner_uid = record.str
        @client_id = record.int
        echoln "FOUND OPPONENT"
        if connection.can_send?
          connection.send do |writer|
            writer.sym(:fwd)
            writer.sym(@partner_uid)
            writer.sym(:trainerData)
            writer.str($Trainer.name)
            write_party(writer)
          end
        end
      when :trainerData
        @matchmaking = true
        @partner_name = record.str
        @partner_party = parse_party(record)
        @ui.displayParty(@partner_party)
        msgwindow.visible = false          
        connection.send do |writer|
          writer.sym(:resetReady)
          writer.str(@partner_uid)
          writer.str(@uid)
        end
        connection.send do |writer|
          writer.sym(:clearRandom)
          writer.str(@client_id == 0 ? @uid + @partner_uid : @partner_uid + @uid)
        end
        
        msgwindow.visible = true
        Kernel.pbMessageDisplay(msgwindow,_INTL("Matched with {1}!",@partner_name))
        @state = :await_party_selection
      else
        raise "Unknown message: #{type}"
      end
    end

  end

  def self.handle_await_interaction_accept(connection,msgwindow)
    pbMessageDisplayDots(msgwindow, _ISPRINTF("Your ID: {1:05d}\\nAsked X for interaction",$Trainer.publicID($Trainer.id)), @frame)
    if (@frame%180 == 0) #Requesting player list every X seconds
      @ui.pbDisplayAvaiblePlayerList(self.getPlayerList())
    end
    connection.updateExp([:acceptInteraction,:cancel,:partnerDisconnected],true) do |record|
      case (type = record.sym)
      when :acceptInteraction
        #@client_id = record.int
        @partner_name = record.str
        @partner_party = parse_party(record)
        @ui.displayParty(@partner_party)
        if connection.can_send?
          connection.send do |writer|
            writer.sym(:fwd)
            writer.sym(@partner_uid)
            writer.sym(:found)
            writer.str($Trainer.name)
            write_party(writer)
          end
        end
        @cancancelSelection = false
        Kernel.pbMessageDisplay(msgwindow, _INTL("{1} connected!", @partner_name))
        if @client_id == 0
          @state = :choose_activity
        else
          @state = :await_choose_activity
        end
      when :cancel
        Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} doesn't want to interact.", @partner_name))
        @ui.hideParty
        @state = :enlisted
        resetPartner()
      when :partnerDisconnected
        # disconnect only if the partner who sent the disconnection is your current partner
        if @partner_uid == record.str
          Kernel.pbMessageDisplay(msgwindow,_INTL("Sorry, {1} disconnected.",@partner_name))
          @state = :enlisted
          return
        end
      else
        raise "Unknown message: #{type}"
      end
    end
    if @timeoutCounter > @maxTimeOut
      Kernel.pbMessageDisplay(msgwindow, _INTL("The connection timed out."))
      @ui.hideParty
      @state = :enlisted
      resetPartner()
    end
  end

  def self.handle_await_partner(connection,msgwindow)
    pbMessageDisplayDots(msgwindow, _ISPRINTF("Your ID: {1:05d}\\nSearching",$Trainer.publicID($Trainer.id)), @frame)
    connection.updateExp([:found,:partnerDisconnected],true) do |record|
      case (type = record.sym)
      when :found
        #@client_id = record.int
        @partner_name = record.str
        @partner_party = parse_party(record)
        @ui.displayParty(@partner_party)
        Kernel.pbMessageDisplay(msgwindow, _INTL("{1} connected!", @partner_name))
        @cancancelSelection = false
        if @client_id == 0
          @state = :choose_activity
        else
          Kernel.pbMessageDisplay(msgwindow,_INTL("Waiting for {1} to pick an activity...",@partner_name),false)
          @state = :await_choose_activity
        end
      when :partnerDisconnected
        # disconnect only if the partner who sent the disconnection is your current partner
        if @partner_uid == record.str
          Kernel.pbMessageDisplay(msgwindow,_INTL("Sorry, {1} disconnected.",@partner_name))
          @state = :enlisted
          return
        end
      else
        raise "Unknown message: #{type}"
      end
    end
  end

  def self.handle_choose_activity(connection,msgwindow)
    Kernel.pbMessageDisplay(msgwindow, _INTL("Choose an activity.\\^"))
    command = Kernel.pbShowCommands(msgwindow, [_INTL("Single Battle"), _INTL("Double Battle"), _INTL("Trade")], -1)
    case command
    when 0..1 # Battle
      if command == 1 && $Trainer.party.length < 2
        Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, you must have at least two Pokémon to engage in a double battle."))
      elsif command == 1 && @partner_party.length < 2
        Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, your partner must have at least two Pokémon to engage in a double battle."))
      else
        @battle_type = case command
        when 0; :single
        when 1; :double
        else; raise "Unknown battle type"
        end
        @chosenTier = chooseTier(msgwindow,@battle_type,@partner_party)

        if (@chosenTier == nil)
          return
        end
        @battleTeam = nil
        #Send battle request data
        connection.send do |writer|
          writer.sym(:fwd)
          writer.str(@partner_uid)
          writer.sym(:battle)
          @seed = rand(2**31)
          writer.int(@seed)
          writer.sym(@battle_type)
          writer.int($Trainer.online_trainer_type)
          writer.sym(@chosenTier)
        end
        @activity = :battle
        @state = :await_accept_activity
      end

      when 2 # Trade
        connection.send do |writer|
          writer.sym(:fwd)
          writer.str(@partner_uid)
          writer.sym(:trade)
        end
        @activity = :trade
        @state = :await_accept_activity

      else # Cancel
        # TODO: Confirmation box?
        Kernel.pbMessageDisplay(msgwindow, _INTL("Would you like to disconnect?"))
        if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
          connection.send do |writer|
            writer.sym(:fwd)
            writer.str(@partner_uid)
            writer.sym(:cancelInteraction)
          end
          @ui.hideParty
          @state = :enlisted
        end
        return
      end
  end

  def self.handle_await_accept_activity(connection,msgwindow)
    echoln "#{@state}: awaiting leader to choose activity"
    pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to accept", @partner_name), @frame)
    connection.updateExp([:ok,:acceptTrade,:cancel,:leaveParty,:partnerDisconnected]) do |record|
      case (type = record.sym)
      when :ok #BATTLE ONLY
          #Kernel.pbDisposeMessageWindow(msgwindow)
        case @activity
        when :battle
          msgwindow.visible = false
          
          connection.send do |writer|
            writer.sym(:resetReady)
            writer.str(@partner_uid)
            writer.str(@uid)
          end
          #do_battle(connection, @client_id, @seed, @battle_type, partner, @partner_party,[@uid,@partner_uid])
          #msgwindow.visible = true
          @state = :await_party_selection
        else
          print "Unknown activity: #{@activity}"
        end
      when :acceptTrade #TRADE ONLY
        case @activity
        when :trade
          @chosen = choose_pokemon
          if @chosen >= 0
            connection.send do |writer|
              writer.sym(:fwd)
              writer.str(@partner_uid)
              writer.sym(:chosenPokemon)
              writer.int(@chosen)
            end
            @state = :await_trade_confirm
          else
            connection.send do |writer|
              writer.sym(:fwd)
              writer.str(@partner_uid)
              writer.sym(:cancel)
            end
            connection.discard(1)
            @state = :choose_activity
          end
        else
          print "Unknown activity: #{@activity}"
        end
      when :cancel
        Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} doesn't want to #{@activity.to_s}.", @partner_name))
        @state = :choose_activity
      when :leaveParty
        # disconnect only if the partner who sent the disconnection is your current partner
        Kernel.pbMessageDisplay(msgwindow,_INTL("Sorry, {1} disconnected.",@partner_name))
        @state = :enlisted
        resetPartner()
        return
      when :partnerDisconnected
        # disconnect only if the partner who sent the disconnection is your current partner
        if @partner_uid == record.str
          Kernel.pbMessageDisplay(msgwindow,_INTL("Sorry, {1} disconnected.",@partner_name))
          @state = :enlisted
          return
        end
      else
        print "Unknown message: #{type}"
      end
    end
  end

  def self.handle_await_choose_activity(connection,msgwindow)
    #pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to pick an activity", @partner_name), @frame)
    connection.updateExp([:battle,:trade,:cancelInteraction,:partnerDisconnected]) do |record|
      case (type = record.sym)
      when :battle
        @seed = record.int
        @battle_type = record.sym
        trainertype = record.int
        @chosenTier = record.sym
        partner = PokeBattle_Trainer.new(@partner_name, trainertype)
        (partner.partyID=0) rescue nil # EBDX compat
        # Auto-reject double battles that we cannot participate in.
        if @battle_type == :double && $Trainer.party.length < 2
          connection.send do |writer|
            writer.sym(:fwd)
            writer.str(@partner_uid)
            writer.sym(:cancel)
          end
          @state = :await_choose_activity
        else
          Kernel.pbMessageDisplay(msgwindow, _INTL("{1} wants to battle at {2}! ", @partner_name, BATTLE_TIERS_NAMES[@chosenTier]))
          if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
            msgwindow.visible = false #Kernel.pbDisposeMessageWindow(msgwindow)
            @battleTeam = nil
            connection.send do |writer|
              writer.sym(:fwd)
              writer.str(@partner_uid)
              writer.sym(:ok)
            end
            # QUESTI VANNO AL SERVER
            connection.send do |writer|
              writer.sym(:clearRandom)
              writer.str(@client_id == 0 ? @uid + @partner_uid : @partner_uid + @uid)
            end
            connection.send do |writer|
              writer.sym(:resetReady)
              writer.str(@partner_uid)
              writer.str(@uid)
            end
            @state = :await_party_selection
            #do_battle(connection, @client_id, @seed, @battle_type, partner, @partner_party,battleTeam,[@uid,@partner_uid])
            #msgwindow.visible = true
          else
            connection.send do |writer|
              writer.sym(:fwd)
              writer.str(@partner_uid)
              writer.sym(:cancel)
            end
            @state = :await_choose_activity
          end
        end

      when :trade
        Kernel.pbMessageDisplay(msgwindow, _INTL("{1} wants to trade!\\^", @partner_name))
        if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
          msgwindow.visible = true #Kernel.pbDisposeMessageWindow(msgwindow)
          connection.send do |writer|
            writer.sym(:fwd)
            writer.str(@partner_uid)
            writer.sym(:acceptTrade)
          end
          @chosen = choose_pokemon
          if @chosen >= 0
            connection.send do |writer|
              writer.sym(:fwd)
              writer.str(@partner_uid)
              writer.sym(:chosenPokemon)
              writer.int(@chosen)
            end
            @state = :await_trade_confirm
          else
            connection.send do |writer|
              writer.sym(:fwd)
              writer.str(@partner_uid)
              writer.sym(:cancel)
            end
            connection.discard(1)
            @state = :await_choose_activity
          end
        else
          connection.send do |writer|
            writer.sym(:fwd)
            writer.str(@partner_uid)
            writer.sym(:cancel)
          end
          @state = :await_choose_activity
        end
      when :cancelInteraction
        # disconnect only if the partner who sent the disconnection is your current partner
        Kernel.pbMessageDisplay(msgwindow,_INTL("Sorry, {1} didn't want to interact after all.",@partner_name))
        @state = :enlisted
        return
      when :partnerDisconnected
        # disconnect only if the partner who sent the disconnection is your current partner
        if @partner_uid == record.str
          Kernel.pbMessageDisplay(msgwindow,_INTL("Sorry, {1} disconnected.",@partner_name))
          @state = :enlisted
          return
        end
      else
        raise "Unknown message: #{type}"
      end
    end
  end

  def self.handle_await_party_selection(connection,msgwindow)
    if @battleTeam == nil
      pbFadeOutIn(99999){
        scene=PokemonScreen_Scene.new
        screen=PokemonScreen.new(scene,$Trainer.party)
        ret=screen.pbChooseMultiplePokemon(BATTLE_TIERS_NUMBERS[@chosenTier][@battle_type],
           proc{|p| BATTLE_TIERS[@chosenTier].call(p)}, @battle_type==:single ? 1 : 2,@cancancelSelection) {
             if Input.trigger?(Input::F5)
                @ui.toggleOpponentParty()
             end
           }
   
        if !(ret == nil || ret == -1)
          @battleTeam = ret
        end
      }      
            
      # if I didn't choose any pokemon it's just like if i canceled
      if @battleTeam == nil
        connection.send do |writer|
          writer.sym(:fwd)
          writer.str(@partner_uid)
          writer.sym(:cancelSelection)
        end
        msgwindow.visible = true
        if !@matchmaking
          @ui.showParty
          @state = @client_id == 0 ? :choose_activity : :await_choose_activity if @state != :enlisted
        else
          @state = :enlisted
        end
        return
      end

      connection.send do |writer|
        writer.sym(:fwd)
        writer.str(@partner_uid)
        writer.sym(:party)
        writer.int($Trainer.online_trainer_type)
        write_custom_party(@battleTeam,writer)
      end

    end
    msgwindow.visible = true
    pbMessageDisplayDots(msgwindow,_INTL("Awaiting Partner Party..."),@frame)
    connection.updateExp([:party,:cancelSelection,:partnerDisconnected]) do |record|
      case (type = record.sym)
      when :party
        trainertype = record.int
        partner = PokeBattle_Trainer.new(@partner_name, trainertype)
        (partner.partyID=0) rescue nil # EBDX compat
        opp_party = parse_party(record)
        @ui.hideParty
        do_battle(connection, @client_id, @seed, @battle_type, partner, opp_party,@battleTeam,[@uid,@partner_uid],@ui)
        @battleTeam = nil
        @ui.showParty
        msgwindow.visible = true
        if !@matchmaking
          @state = @client_id == 0 ? :choose_activity : :await_choose_activity if @state != :enlisted
        else
          @state = :enlisted
        end
      when :cancelSelection
        msgwindow.visible = true
        Kernel.pbMessageDisplay(msgwindow,_INTL("Sorry, {1} canceled the selection.",@partner_name))
        if !@matchmaking
          @state = @client_id == 0 ? :choose_activity : :await_choose_activity if @state != :enlisted
        else
          @state = :enlisted
        end
      when :partnerDisconnected
        # disconnect only if the partner who sent the disconnection is your current partner
        if @partner_uid == record.str
          Kernel.pbMessageDisplay(msgwindow,_INTL("Sorry, {1} disconnected.",@partner_name))
          @state = :enlisted
          return
        end
      end
    end
  end

  def self.handle_await_trade_pokemon(connection,msgwindow)
    if @partner_confirm
      pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to resynchronize", @partner_name), @frame)
    else
      pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to confirm the trade", @partner_name), @frame)
    end

    connection.updateExp([:acceptChosenPokemon,:update,:cancel,:partnerDisconnected]) do |record|
      case (type = record.sym)
      when :acceptChosenPokemon
        partner = PokeBattle_Trainer.new(@partner_name, $Trainer.trainertype)
        pbHealAll
        @partner_party.each {|pkmn| pkmn.heal}
        pkmn = @partner_party[@partner_chosen]
        @partner_party[@partner_chosen] = $Trainer.party[@chosen]
        connection.send do |writer|
          writer.sym(:logTrade)
          writer.str(@partner_uid)
          write_pkmn(writer, $Trainer.party[@chosen])
          writer.str("@p2")
          write_pkmn(writer, pkmn)
        end
        do_trade(@chosen, partner, pkmn) #trade scene
        connection.send do |writer|
          writer.sym(:fwd)
          writer.str(@partner_uid)
          writer.sym(:update)
          write_pkmn(writer, $Trainer.party[@chosen])
        end
        @partner_confirm = true

      when :update
        @partner_party[@partner_chosen] = parse_pkmn(record)
        @partner_chosen = nil
        @partner_confirm = false
        if @client_id == 0
          @state = :choose_activity
        else
          @state = :await_choose_activity
        end
        @ui.updateParty(@partner_party)
      when :cancel
        Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} doesn't want to trade after all.", @partner_name))
        @partner_chosen = nil
        @partner_confirm = false
        if @client_id == 0
          @state = :choose_activity
        else
          @state = :await_choose_activity
        end
      when :partnerDisconnected
        # disconnect only if the partner who sent the disconnection is your current partner
        if @partner_uid == record.str
          Kernel.pbMessageDisplay(msgwindow,_INTL("Sorry, {1} disconnected.",@partner_name))
          @state = :enlisted
          return
        end
      else
        raise "Unknown message: #{type}"
      end
    end
  end

  def self.handle_await_trade_confirm(connection,msgwindow)
    if @partner_chosen.nil?
      pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to pick a Pokémon", @partner_name), @frame)
    else
      pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to confirm the trade", @partner_name), @frame)
    end

    connection.updateExp([:chosenPokemon,:cancel,:partnerDisconnected]) do |record|
      case (type = record.sym)
      when :chosenPokemon
        @partner_chosen = record.int
        pbHealAll
        @partner_party.each {|pkmn| pkmn.heal}
        partner_pkmn = @partner_party[@partner_chosen]
        your_pkmn = $Trainer.party[@chosen]
        abort=$Trainer.ablePokemonCount==1 && your_pkmn==$Trainer.ablePokemonParty[0] && partner_pkmn.isEgg?
        able_party=@partner_party.find_all { |p| p && !p.isEgg? && !p.isFainted? }
        abort|=able_party.length==1 && partner_pkmn==able_party[0] && your_pkmn.isEgg?
        unless abort
          partner_speciesname = (partner_pkmn.isEgg?) ? _INTL("Egg") : PBSpecies.getName(getID(PBSpecies,partner_pkmn.species))
          your_speciesname = (your_pkmn.isEgg?) ? _INTL("Egg") : PBSpecies.getName(getID(PBSpecies,your_pkmn.species))
          
          # HERE THE ACTUAL TRADE IS BEING HANDLED          
          loop do
            Kernel.pbMessageDisplay(msgwindow, _INTL("{1} has offered {2} ({3}) for your {4} ({5}).\\^",@partner_name,
                partner_pkmn.name,partner_speciesname,your_pkmn.name,your_speciesname))
            command = Kernel.pbShowCommands(msgwindow, [_INTL("Check {1}'s offer",@partner_name), _INTL("Check My Offer"), _INTL("Accept/Deny Trade")], -1)
            case command
            when 0
              check_pokemon(partner_pkmn)
            when 1
              check_pokemon(your_pkmn)
            when 2
              Kernel.pbMessageDisplay(msgwindow, _INTL("Confirm the trade of {1} ({2}) for your {3} ({4}).\\^",partner_pkmn.name,partner_speciesname,
                  your_pkmn.name,your_speciesname))
              if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
                connection.send do |writer|
                  writer.sym(:fwd)
                  writer.str(@partner_uid)
                  writer.sym(:acceptChosenPokemon)
                  #write_pkmn(writer, $Trainer.party[@chosen])
                end
                @state = :await_trade_pokemon
                break
              else
                connection.send do |writer|
                  writer.sym(:fwd)
                  writer.str(@partner_uid)
                  writer.sym(:cancel)
                end
                @partner_chosen = nil
                connection.discard(1)
                if @client_id == 0
                  @state = :choose_activity
                else
                  @state = :await_choose_activity
                end
                break
              end
            end
          end
        else
          Kernel.pbMessageDisplay(msgwindow, _INTL("The trade was unable to be completed."))
          @partner_chosen = nil
          if @client_id == 0
            @state = :choose_activity
          else
            @state = :await_choose_activity
          end
        end
        
      when :cancel
        Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} doesn't want to trade after all.", @partner_name))
        @partner_chosen = nil
        if @client_id == 0
          @state = :choose_activity
        else
          @state = :await_choose_activity
        end
      when :partnerDisconnected
        # disconnect only if the partner who sent the disconnection is your current partner
        if @partner_uid == record.str
          Kernel.pbMessageDisplay(msgwindow,_INTL("Sorry, {1} disconnected.",@partner_name))
          @state = :enlisted
          return
        end
      else
        raise "Unknown message: #{type}"
      end
    end  
  end

  def self.enlist(msgwindow,ui)
    #pbChangeOnlineTrainerType()
    #pbMessageDisplayDots(msgwindow, _INTL("Connecting"), 0)
    out = nil
    host = nil
    port = nil

    t = Thread.new {
      Graphics.update
      Input.update
      out = %x{Antochit.exe}#`Antochit.exe`
      return if (out == nil || out == "BANNED")
      @md5 = out.split(",")[0]
      @uid = out.split(",")[1]
      hostandport = out.split(",")[2]
      host = hostandport.split(":")[0]
      port = hostandport.split(":")[1].to_i
    }

    frames = 0
    while(out == nil)
      Graphics.update
      Input.update
      frames+=1
      pbMessageDisplayDots(msgwindow,_INTL("Loading, this may take a while"),frames)
    end

    return if host == nil || out == "BANNED"
    @ui = ui
    @handlers = {}
    # Waiting to be connected to the server.
    # Note: does nothing without a non-blocking connection.
    @handlers[:await_server] = Proc.new {|connection, msgwindow| handle_await_server(connection,msgwindow)}
    @handlers[:enlisted] = Proc.new {|connection, msgwindow| handle_enlist(connection,msgwindow)}
    # The leader is awaiting 
    @handlers[:await_interaction_accept] = Proc.new {|connection, msgwindow| handle_await_interaction_accept(connection,msgwindow)}
    # Waiting to be connected to the partner.
    @handlers[:await_partner] = Proc.new {|connection, msgwindow| handle_await_partner(connection,msgwindow)}
    # Choosing an activity (leader only).
    @handlers[:choose_activity] = Proc.new {|connection, msgwindow| handle_choose_activity(connection,msgwindow)}
    # Waiting for the partner to accept our activity (leader only).
    @handlers[:await_accept_activity] = Proc.new {|connection, msgwindow| handle_await_accept_activity(connection,msgwindow)}
    # Waiting for the partner to select an activity (follower only).
    @handlers[:await_choose_activity] = Proc.new {|connection, msgwindow| handle_await_choose_activity(connection,msgwindow)}
    # Waiting for the partner to select their party.
    @handlers[:await_party_selection] = Proc.new{|connection,msgwindow| handle_await_party_selection(connection,msgwindow)}
    # Waiting for the partner to select a Pokémon to trade.
    @handlers[:await_trade_pokemon] = Proc.new {|connection, msgwindow| handle_await_trade_pokemon(connection,msgwindow)}
    @handlers[:await_trade_confirm] = Proc.new {|connection, msgwindow| handle_await_trade_confirm(connection,msgwindow)}
    
    @handlers[:unrankedMatchmaking] = Proc.new {|connection, msgwindow| handle_unranked_matchmaking(connection,msgwindow)}
    @handlers[:wonderTrading] = Proc.new {|connection, msgwindow| handle_wonder_trading(connection,msgwindow)}

    @timeoutCounter = 0
    @maxTimeOut = 60 * 30

    connport = port+1+rand(9)

    Connection.open(host, connport) do |connection|
      @state = :await_server
      @last_state = nil
      @client_id = 0               # 0 = SENDER, 1 = RECEIVER
      @partner_uid = ""
      @partner_id = -1
      @partner_name = nil
      @partner_party = nil
      @battleTeam = nil
      @frame = 0
      @activity = nil
      @seed = nil
      @battle_type = nil
      @chosen = nil
      @partner_chosen = nil
      @partner_confirm = false
      @chosenTier = nil
      @matchmaking = false
      @navigatingPlayerList = true

      @cancancelSelection = true


      loop do
        if (@frame%20==0)
          pbCheckForCE(connection)
        end
        if @state != @last_state
          if @state == :enlisted
            @matchmaking = false
            msgwindow.visible = false
            @ui.updateStatus(_INTL("Choose a partner or start matchmaking."))
            #Kernel.pbMessageDisplay(msgwindow,_INTL("Choose a partner."),false)
            @partner_uid = nil

            #Ask for new server message if there's any
            if connection.can_send?
              connection.send do |writer|
                writer.sym(:getServerMessage)
              end
            end
          else
            msgwindow.visible = true
          end
          @last_state = @state
          @frame = 0
        else
          @frame += 1# if @frame < 180
        end

        Input.update
        Graphics.update
        @ui.canRefresh = canRefreshPlayerList?()
        @ui.update
        
        if Input.trigger?(Input::B)
          case @state
          when :unrankedMatchmaking
            msgwindow.visible = true          
            Kernel.pbMessageDisplay(msgwindow, _INTL("Do you want to exit matchmaking?"),false)
            if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
              connection.send do |writer|
                writer.sym(:forfeitMatchmaking)
              end
              @state = :enlisted
            end
            msgwindow.visible = false
          when :await_choose_activity
            msgwindow.visible = true
            Kernel.pbMessageDisplay(msgwindow, _INTL("Do you want to stop the connection with your partner?"),false)
            if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
              connection.send do |writer|
                writer.sym(:fwd)
                writer.str(@partner_uid)
                writer.sym(:leaveParty)
              end
              resetPartner()
              @state = :enlisted
              msgwindow.visible = false
              next
            end
          else
            msgwindow.visible = true
            message = case @state
              when :await_server; _INTL("Abort connection?\\^")
              when :await_partner; _INTL("Abort search?\\^")
              else; _INTL("Disconnect?\\^")
              end
            Kernel.pbMessageDisplay(msgwindow, message)
            return if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
            msgwindow.visible = false
          end
        end
        
        if @handlers.keys.include?(@state)
          @handlers[@state].call(connection,msgwindow)
        else
          raise "Unknown state: #{@state}"
        end

      end
    end
  end


  def self.pbMessageDisplayDots(msgwindow, message, frame)
    #msgwindow.text = message + "...".slice(0..(frame/8) % 3)
    Kernel.pbMessageDisplay(msgwindow, message + "...".slice(0..(frame/8) % 3) + "\\^", false)
  end

# NO !defined?(ESSENTIALSVERSION) && !defined?(ESSENTIALS_VERSION)
# NO defined?(ESSENTIALSVERSION) && ESSENTIALSVERSION =~ /^17/
# NO defined?(ESSENTIALS_VERSION) && ESSENTIALS_VERSION =~ /^18/

  # Renamed constants, yay...
  def self.do_battle(connection, client_id, seed, battle_type, partner, partner_party,own_party, uids,ui)
    #echoln "AOOOOOOOOOOO SO PARTITO IO"
    #$Trainer.backupParty = $Trainer.party.dup
    $Trainer.backupParty  = $Trainer.party.map {|x| x.clone}
    $Trainer.party = own_party
    $Trainer.party.each do |pike|
      pike.level = 50
      pike.calcStats
    end
    pbHealAll # Avoids having to transmit damaged state.
    partner_party_clone = partner_party.map {|y| y.clone}
    partner_party_clone.each {|pkmn| 
      pkmn.heal
      pkmn.level = 50
      pkmn.calcStats
    }
    scene = pbNewBattleScene
    battle = PokeBattle_CableClub.new(connection, @client_id, scene, partner_party_clone, partner, uids, ui)
    battle.fullparty1 = battle.fullparty2 = true
    battle.endspeech = ""
    battle.items = []
    battle.internalbattle = false
    case battle_type
    when :single
      battle.doublebattle = false
    when :double
      battle.doublebattle = true
    else
      raise "Unknown battle type: #{battle_type}"
    end
    trainerbgm = pbGetTrainerBattleBGM(partner)
    Events.onStartBattle.trigger(nil, nil)
    pbPrepareBattle(battle)
    exc = nil
    $onlinebattle = true
    ui.createBattleTimer
    pbBattleAnimation(trainerbgm, partner.trainertype, partner.name) {
      pbSceneStandby {
        # XXX: Hope we call rand in the same order in both clients...
        begin
          battle.pbStartBattle(true)
        rescue Connection::Disconnected
          scene.pbEndBattle(0)
          exc = $!
        ensure
          $onlinebattle = false
          $Trainer.party = $Trainer.backupParty
        end
      }
    }
    ui.deleteBattleTimer
    $onlinebattle = false
    @state = :enlisted if battle.disconnected
    $Trainer.party = $Trainer.backupParty
    raise exc if exc
  end

  def self.do_trade(index, you, your_pkmn)
    my_pkmn = $Trainer.party[index]
    your_pkmn.obtainMode = 2 # traded
    $Trainer.seen[your_pkmn.species] = true
    $Trainer.owned[your_pkmn.species] = true
    pbSeenForm(your_pkmn)
    pbFadeOutInWithMusic(99999) {
      scene = PokemonTradeScene.new
      scene.pbStartScreen(my_pkmn, your_pkmn, $Trainer.name, you.name)
      scene.pbTrade
      scene.pbEndScreen
    }
    $Trainer.party[index] = your_pkmn
  end

  def self.chooseTier(msgwindow, battleType, opp_party)
    Kernel.pbMessageDisplay(msgwindow, _INTL("Choose a tier."))
    tiers = pbGetTiersNames()
    tierNames = []
    for t in tiers
      tierNames.push(t[0])
    end
    validCommand = false
    while !validCommand
      command = Kernel.pbShowCommands(msgwindow, tierNames, -1)
      if command == -1 || command == tierNames.length-1
        command = -1
        break
      end
      vp = 0 #valid pokemons
      vopp = 0 #valid opp pokemons
      for p in $Trainer.party
        if (BATTLE_TIERS[tiers[command][1]].call(p))
          vp +=1
        end
      end

      if battleType == :single
        if vp < 1
          Kernel.pbMessageDisplay(msgwindow, _INTL("Sorry, looks like you can't enter this Tier with your current team."))
          next
        end
      elsif battleType == :double 
        if vp < 2
          Kernel.pbMessageDisplay(msgwindow, _INTL("Sorry, looks like you can't enter this Tier with your current team."))
          next
        end
      end

      if opp_party != nil
        for p in opp_party
          if (BATTLE_TIERS[tiers[command][1]].call(p))
            vopp +=1
          end
        end
        
        if battleType == :single
          if vopp < 1
            Kernel.pbMessageDisplay(msgwindow, _INTL("Sorry, looks like your opponent can't enter this Tier with the current team."))
            next
          end
        elsif battleType == :double 
          if vopp < 2
            Kernel.pbMessageDisplay(msgwindow, _INTL("Sorry, looks like your opponent can't enter this Tier with the current team."))
            next
          end
        end
      end
      validCommand = true
    end
    #command ora mi punta al simbolo che identifica il tier, POG
    if command != -1
      return tiers[command][1]
    else
      return nil
    end
  end

  def self.choose_pokemon
    chosen = -1
    pbFadeOutIn(99999) {
      scene = PokemonScreen_Scene.new
      screen = PokemonScreen.new(scene, $Trainer.party)
      screen.pbStartScene(_INTL("Choose a Pokémon."), false)
      chosen = screen.pbChoosePokemon
      screen.pbEndScene
    }
    return chosen
  end
  
  def self.check_pokemon(pkmn)
    pbFadeOutIn(99999) {
      scene = PokemonSummaryScene.new
      screen = PokemonSummary.new(scene)
      screen.pbStartScreen([pkmn],0)
    }
  end

  def self.write_party(writer)
    writer.int($Trainer.party.length)
    $Trainer.party.each do |pkmn|
      write_pkmn(writer, pkmn)
    end
  end

  def self.write_custom_party(party, writer)
    writer.int(party.length)
    party.each do |pkmn|
      write_pkmn(writer, pkmn)
    end
  end

  def self.write_pkmn_toc(pkmn)
    writer = RecordWriter.new
    write_pkmn(writer,pkmn)
    echoln writer.line!
  end

  def self.write_pkmn(writer, pkmn)
    is_v18 = defined?(ESSENTIALS_VERSION) && ESSENTIALS_VERSION =~ /^18/
    writer.int(pkmn.species)
    writer.int(pkmn.level)
    writer.int(pkmn.personalID)
    writer.int(pkmn.trainerID)
    writer.str(pkmn.ot)
    writer.int(pkmn.otgender)
    writer.int(pkmn.language)
    writer.int(pkmn.exp)
    writer.int(pkmn.form)
    writer.int(pkmn.item)
    writer.int(pkmn.moves.length)
    pkmn.moves.each do |move|
      writer.int(move.id)
      writer.int(move.ppup)
    end
    writer.int(pkmn.firstmoves.length)
    pkmn.firstmoves.each do |move|
      writer.int(move)
    end
    # in hindsight, don't really need to send the calculated values
    writer.nil_or(:int, pkmn.genderflag)
    writer.nil_or(:bool, pkmn.shinyflag)
    writer.nil_or(:int, pkmn.abilityflag)
    writer.nil_or(:int, pkmn.natureflag)
    writer.nil_or(:int, pkmn.natureOverride) if is_v18
    for i in 0...6
      writer.int(pkmn.iv[i])
      writer.nil_or(:bool, pkmn.ivMaxed[i]) if is_v18
      writer.int(pkmn.ev[i])
    end
    if (pkmn.isDelta?)
      writer.bool(true)
    else
      writer.bool(false)
    end
    writer.int(pkmn.happiness)
    writer.str(pkmn.name)
    writer.int(pkmn.ballused)
    writer.int(pkmn.eggsteps)
    writer.nil_or(:int,pkmn.pokerus)
    writer.int(pkmn.obtainMap)
    writer.nil_or(:str,pkmn.obtainText)
    writer.int(pkmn.obtainLevel)
    writer.int(pkmn.obtainMode)
    writer.int(pkmn.hatchedMap)
    writer.int(pkmn.cool)
    writer.int(pkmn.beauty)
    writer.int(pkmn.cute)
    writer.int(pkmn.smart)
    writer.int(pkmn.tough)
    writer.int(pkmn.sheen)
    writer.int(pkmn.ribbonCount)
    pkmn.ribbons.each do |ribbon|
      writer.int(ribbon)
    end
    writer.bool(!!pkmn.mail)
    if pkmn.mail
      writer.int(pkmn.mail.item)
      writer.str(pkmn.mail.message)
      writer.str(pkmn.mail.sender)
      if pkmn.mail.poke1
        #[species,gender,shininess,form,shadowness,is egg]
        writer.int(pkmn.mail.poke1[0])
        writer.int(pkmn.mail.poke1[1])
        writer.bool(pkmn.mail.poke1[2])
        writer.int(pkmn.mail.poke1[3])
        writer.bool(pkmn.mail.poke1[4])
        writer.bool(pkmn.mail.poke1[5])
      else
        writer.nil_or(:int,nil)
      end
      if pkmn.mail.poke2
        #[species,gender,shininess,form,shadowness,is egg]
        writer.int(pkmn.mail.poke2[0])
        writer.int(pkmn.mail.poke2[1])
        writer.bool(pkmn.mail.poke2[2])
        writer.int(pkmn.mail.poke2[3])
        writer.bool(pkmn.mail.poke2[4])
        writer.bool(pkmn.mail.poke2[5])
      else
        writer.nil_or(:int,nil)
      end
      if pkmn.mail.poke3
        #[species,gender,shininess,form,shadowness,is egg]
        writer.int(pkmn.mail.poke3[0])
        writer.int(pkmn.mail.poke3[1])
        writer.bool(pkmn.mail.poke3[2])
        writer.int(pkmn.mail.poke3[3])
        writer.bool(pkmn.mail.poke3[4])
        writer.bool(pkmn.mail.poke3[5])
      else
        writer.nil_or(:int,nil)
      end
    end
    writer.bool(!!pkmn.fused)
    if pkmn.fused
      write_pkmn(writer, pkmn.fused)
    end
    if defined?(EliteBattle) # EBDX compat
      # this looks so dumb I know, but the variable can be nil, false, or an int.
      writer.bool(pkmn.shiny?)
      writer.str(pkmn.superHue.to_s)
      writer.nil_or(:bool,pkmn.superVariant)
    end
  end

  def self.parse_party(record)
    party = []
    record.int.times do
      party << parse_pkmn(record)
    end
    return party
  end

  def self.parse_pkmn(record)
    is_v18 = defined?(ESSENTIALS_VERSION) && ESSENTIALS_VERSION =~ /^18/
    species = record.int
    level = record.int
    pkmn = PokeBattle_Pokemon.new(species, level, $Trainer)
    pkmn.personalID = record.int
    pkmn.trainerID = record.int
    pkmn.ot = record.str
    pkmn.otgender = record.int
    pkmn.language = record.int
    pkmn.exp = record.int
    form = record.int
    if is_v18
      pkmn.formSimple = form
    else
      pkmn.formNoCall = form
    end
    pkmn.setItem(record.int)
    pkmn.resetMoves
    for i in 0...record.int
      pkmn.moves[i] = PBMove.new(record.int)
      pkmn.moves[i].ppup = record.int
    end
    pkmn.firstmoves = []
    for i in 0...record.int
      pkmn.firstmoves.push(record.int)
    end
    pkmn.genderflag = record.nil_or(:int)
    pkmn.shinyflag = record.nil_or(:bool)
    pkmn.abilityflag = record.nil_or(:int)
    pkmn.natureflag = record.nil_or(:int)
    pkmn.natureOverride = record.nil_or(:int) if is_v18
    for i in 0...6
      pkmn.iv[i] = record.int
      pkmn.ivMaxed[i] = record.nil_or(:bool) if is_v18
      pkmn.ev[i] = record.int
    end
    if record.nil_or(:bool) == true
      pkmn.makeDelta
    end
    pkmn.happiness = record.int
    pkmn.name = record.str
    pkmn.ballused = record.int
    pkmn.eggsteps = record.int
    pkmn.pokerus = record.nil_or(:int)
    pkmn.obtainMap = record.int
    pkmn.obtainText = record.nil_or(:str)
    pkmn.obtainLevel = record.int
    pkmn.obtainMode = record.int
    pkmn.hatchedMap = record.int
    pkmn.cool = record.int
    pkmn.beauty = record.int
    pkmn.cute = record.int
    pkmn.smart = record.int
    pkmn.tough = record.int
    pkmn.sheen = record.int
    pkmn.clearAllRibbons
    for i in 0...record.int
      pkmn.giveRibbon(record.int)
    end
    if record.bool() # mail
      m_item = record.int()
      m_msg = record.str()
      m_sender = record.str()
      m_poke1 = []
      if m_species1 = record.nil_or(:int)
        #[species,gender,shininess,form,shadowness,is egg]
        m_poke1[0] = m_species1
        m_poke1[1] = record.int()
        m_poke1[2] = record.bool()
        m_poke1[3] = record.int()
        m_poke1[4] = record.bool()
        m_poke1[5] = record.bool()
      else
        m_poke1 = nil
      end
      m_poke2 = []
      if m_species2 = record.nil_or(:int)
        #[species,gender,shininess,form,shadowness,is egg]
        m_poke2[0] = m_species2
        m_poke2[1] = record.int()
        m_poke2[2] = record.bool()
        m_poke2[3] = record.int()
        m_poke2[4] = record.bool()
        m_poke2[5] = record.bool()
      else
        m_poke2 = nil
      end
      m_poke3 = []
      if m_species3 = record.nil_or(:int)
        #[species,gender,shininess,form,shadowness,is egg]
        m_poke3[0] = m_species3
        m_poke3[1] = record.int()
        m_poke3[2] = record.bool()
        m_poke3[3] = record.int()
        m_poke3[4] = record.bool()
        m_poke3[5] = record.bool()
      else
        m_poke3 = nil
      end
      pkmn.mail = PokemonMail.new(m_item,m_msg,m_sender,m_poke1,m_poke2,m_poke3)
    end
    if record.bool()# fused
      pkmn.fused = parse_pkmn(record)
    end
    if defined?(EliteBattle) # EBDX compat
      # this looks so dumb I know, but the variable can be nil, false, or an int.
      record.bool # shiny call.
      superhue = record.str
      if superhue == ""
        pkmn.superHue = nil
      elsif superhue=="false"
        pkmn.superHue = false
      else
        pkmn.superHue = superhue.to_i
      end
      pkmn.superVariant = record.nil_or(:bool)
    end
    pkmn.calcStats
    return pkmn
  end
end

class PokeBattle_Battle
  attr_reader :client_id
end

class PokeBattle_CableClub < PokeBattle_Battle
  attr_reader :connection
  def initialize(connection, client_id, scene, opponent_party, opponent, uids, ui)
    @connection = connection
    @client_id = client_id
    @uid = uids[0]
    @partner_uid = uids[1]
    @disconnected = false
    @seedset=false
    @ui = ui
    @randomCounter = 0
    @randomHistory = []

    @timer = 0
    @timerMax = 60*300

    player = PokeBattle_Trainer.new($Trainer.name, $Trainer.trainertype)
    super(scene, $Trainer.party, opponent_party, player, opponent)
    @battleAI  = PokeBattle_CableClub_AI.new(self) if defined?(ESSENTIALS_VERSION) && ESSENTIALS_VERSION =~ /^18/
  end
  
  def disconnected
    return @disconnected
  end

  def pbAwaitReadiness
    frame = 0.0
    @scene.pbShowWindow(PokeBattle_Scene::MESSAGEBOX)
    cw = @scene.sprites["messagewindow"]
    cw.letterbyletter = false
    #Here i should await for readiness
    sent = false
    awaiting = true
    sent = 0
    echoln "AWAITING READINESS #{sent}"
    while(awaiting)
      Graphics.update
      Input.update
      frame+=1.0
      cw.text = _INTL("Waiting" + "." * (1 + ((frame / 8) % 3)))
      pbCheckForCE(@connection)
      @connection.updateExp([:ready,:partnerDisconnected]) do |record|
        case (type = record.sym)
        when :ready
          awaiting = false          
          @connection.send do |writer|
            writer.sym(:ready) #Request type
            writer.str(@partner_uid)
            writer.str(@uid)
          end
        when :partnerDisconnected
          awaiting = false
          pbSEPlay("Battle flee")
          pbDisplay(_INTL("{1} disconnected!", opponent.fullname))
          @decision = 1
          @disconnected = true
          pbAbort
        end
      end
      if (((frame / 60) % 3) == 0)
        @connection.send do |writer|
          writer.sym(:ready) #Request type
          writer.str(@partner_uid)
          writer.str(@uid)
        end
        sent += 1
        echoln "AWAITING READINESS #{sent}"
      end
    end
  end

  def pbBattleWait(frames)
    frames.times do
      Graphics.update
      Input.update
      yield if block_given?
    end
  end

  def pbDisplayPaused(message)
    pbDisplayBrief(message)
    pbBattleWait(80) {
      yield if block_given?
    }
  end

  #Redefining pbStartBattleCore(canlose)
  #This one will await the readiness of each player

  def pbStartBattleCore(canlose)
    Graphics.frame_rate = 60
    
    echoln "SIIIIIIIIIIIIIIIIIIIIIIIIAA #{@opponent}"
    if !@fullparty1 && @party1.length > MAXPARTYSIZE
      raise ArgumentError.new(_INTL("Party 1 has more than {1} Pokémon.",MAXPARTYSIZE))
    end
    if !@fullparty2 && @party2.length > MAXPARTYSIZE
      raise ArgumentError.new(_INTL("Party 2 has more than {1} Pokémon.",MAXPARTYSIZE))
    end
    #$smAnim = false if ($smAnim && @doublebattle) || EBUISTYLE!=2
    $smAnim = true if $game_switches[85] && (containsNewBosses?(@party2) ? true : !@doublebattle)
    if !@opponent
    #========================
    # Initialize wild Pokémon
    #========================
      if @party2.length==1
        if @doublebattle
          raise _INTL("Only two wild Pokémon are allowed in double battles")
        end
        wildpoke=@party2[0]
        @battlers[1].pbInitialize(wildpoke,0,false)
        @peer.pbOnEnteringBattle(self,wildpoke)
        if $game_switches[DRAGALISK_UNBEATABLE]==true
          @battlers[1].stages[PBStats::EVASION] = 500
        end
        pbSetSeen(wildpoke)
        @scene.pbStartBattle(self)
        @scene.sendingOut=true
				###
				if wildpoke.boss
					pbDisplayPaused(_INTL("Prepare your anus! The Pokémon boss {1} wants to battle!",wildpoke.name))
          # GRENINJAX END SENDOUT
          if NEWBOSSES.include?($wildSpecies) && (isBoss?() ? (defined?($furiousBattle) && $furiousBattle) : false) #NEWBOSSES.include?($wildSpecies)
            @scene.newBossSequence.finish if @scene.newBossSequence
            @scene.newBossSequence.sendout if @scene.newBossSequence
          else
            @scene.vsBossSequence2_end
            @scene.vsBossSequence2_sendout
          end
        else
					pbDisplayPaused(_INTL("Wild {1} appeared!",wildpoke.name))
				end
				###
      elsif @party2.length==2
        if !@doublebattle
          raise _INTL("Only one wild Pokémon is allowed in single battles")
        end
        @battlers[1].pbInitialize(@party2[0],0,false)
        @battlers[3].pbInitialize(@party2[1],0,false)
        @peer.pbOnEnteringBattle(self,@party2[0])
        @peer.pbOnEnteringBattle(self,@party2[1])
        pbSetSeen(@party2[0])
        pbSetSeen(@party2[1])
        @scene.pbStartBattle(self)
        wildpoke=@party2[0]
        if wildpoke.boss
          if defined?($dittoxbattle) && $dittoxbattle
            pbDisplayPaused(_INTL("Prepare your anus! The Pokémon boss {1} wants to battle!","Ditto X"))
					else
            pbDisplayPaused(_INTL("Prepare your anus! The Pokémon boss {1} wants to battle!",wildpoke.name))
          end
          # GRENINJAX END SENDOUT
          if NEWBOSSES.include?($wildSpecies) && (isBoss?() ? (defined?($furiousBattle) && $furiousBattle) : false) #NEWBOSSES.include?($wildSpecies)
            @scene.newBossSequence.finish if @scene.newBossSequence
            @scene.newBossSequence.sendout if @scene.newBossSequence
          else
            @scene.vsBossSequence2_end
            @scene.vsBossSequence2_sendout
          end
        else
          pbDisplayPaused(_INTL("Wild {1} and\r\n{2} appeared!",
            @party2[0].name,@party2[1].name))
        end
      else
        raise _INTL("Only one or two wild Pokémon are allowed")
      end
    elsif @doublebattle
    #=======================================
    # Initialize opponents in double battles
    #=======================================
      if @opponent.is_a?(Array)
        if @opponent.length==1
          @opponent=@opponent[0]
        elsif @opponent.length!=2
          raise _INTL("Opponents with zero or more than two people are not allowed")
        end
      end
      if @player.is_a?(Array)
        if @player.length==1
          @player=@player[0]
        elsif @player.length!=2
          raise _INTL("Player trainers with zero or more than two people are not allowed")
        end
      end
      @scene.pbStartBattle(self)
      @scene.sendingOut=true
      echoln "SIIIIIIIIIIIIIIIIIIIIIIIIAA"
      if @opponent.is_a?(Array)
        pbDisplayPaused(_INTL("{1} and {2} want to battle!",@opponent[0].fullname,@opponent[1].fullname))
        sendout1=pbFindNextUnfainted(@party2,0,pbSecondPartyBegin(1))
        raise _INTL("Opponent 1 has no unfainted Pokémon") if sendout1 < 0
        sendout2=pbFindNextUnfainted(@party2,pbSecondPartyBegin(1))
        raise _INTL("Opponent 2 has no unfainted Pokémon") if sendout2 < 0
        @scene.vsSequenceSM_end if $smAnim && !@scene.smTrainerSequence
        @battlers[1].pbInitialize(@party2[sendout1],sendout1,false)
        @battlers[3].pbInitialize(@party2[sendout2],sendout2,false)
        @scene.smTrainerSequence.finish if @scene.smTrainerSequence
        pbDisplayBrief(_INTL("{1} sent\r out {2}! {3} sent\r out {4}!",@opponent[0].fullname,getBattlerPokemon(@battlers[1]).name,@opponent[1].fullname,getBattlerPokemon(@battlers[3]).name))
        pbSendOutInitial(@doublebattle,1,@party2[sendout1],3,@party2[sendout2])
      else
        echoln "NOOOOOOOOOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        pbDisplayPaused(_INTL("{1}\r\nvuole combattere!",@opponent.fullname)){
          @scene.smTrainerSequence.update if @scene.smTrainerSequence
        }
        sendout1=pbFindNextUnfainted(@party2,0)
        sendout2=pbFindNextUnfainted(@party2,sendout1+1)
        
        if @party2[sendout1].species == getID(PBSpecies,:PAWNIARDAB)
          @party2[sendout1].totalHp=9999999
          @party2[sendout1].hp=9999999
					@party2[sendout1].attack=90000
        end
        
        if @party2[sendout2].species == getID(PBSpecies,:PAWNIARDAB)
          @party2[sendout2].totalHp=9999999 
          @party2[sendout2].hp=9999999
					@party2[sendout2].attack=90000
        end
        
        if sendout1 < 0 || sendout2 < 0
          raise _INTL("Opponent doesn't have two unfainted Pokémon")
        end
        @scene.vsSequenceSM_end if $smAnim && !@scene.smTrainerSequence
        @battlers[1].pbInitialize(@party2[sendout1],sendout1,false)
        @battlers[3].pbInitialize(@party2[sendout2],sendout2,false)
        @scene.smTrainerSequence.finish if @scene.smTrainerSequence
        pbDisplayBrief(_INTL("{1} sent\r out {2} and {3}!",
           @opponent.fullname,getBattlerPokemon(@battlers[1]).name,getBattlerPokemon(@battlers[3]).name))
        pbSendOutInitial(@doublebattle,1,@party2[sendout1],3,@party2[sendout2])
      end
    else
    #======================================
    # Initialize opponent in single battles
    #======================================
      sendout=pbFindNextUnfainted(@party2,0)
      raise _INTL("Trainer has no unfainted Pokémon") if sendout < 0
      if @opponent.is_a?(Array)
        raise _INTL("Opponent trainer must be only one person in single battles") if @opponent.length!=1
        @opponent=@opponent[0]
      end
      if @player.is_a?(Array)
        raise _INTL("Player trainer must be only one person in single battles") if @player.length!=1
        @player=@player[0]
      end
      trainerpoke=@party2[0]
      @battlers[1].pbInitialize(trainerpoke,sendout,false)
      @scene.pbStartBattle(self)
      @scene.sendingOut=true
      pbDisplayPaused(_INTL("{1}\r\nvuole combattere!",@opponent.fullname)){
        @scene.smTrainerSequence.update if @scene.smTrainerSequence
      }
      @scene.vsSequenceSM_end if $smAnim && !@scene.smTrainerSequence
      @scene.smTrainerSequence.finish if @scene.smTrainerSequence
      pbDisplayBrief(_INTL("{1} sent\r out {2}!",@opponent.fullname,getBattlerPokemon(@battlers[1]).name))
      pbSendOutInitial(@doublebattle,1,trainerpoke)
    end
    #=====================================
    # Initialize players in double battles
    #=====================================
    if @doublebattle
      @scene.sendingOut=true
      if @player.is_a?(Array)
        sendout1=pbFindNextUnfainted(@party1,0,pbSecondPartyBegin(0))
        raise _INTL("Player 1 has no unfainted Pokémon") if sendout1 < 0
        sendout2=pbFindNextUnfainted(@party1,pbSecondPartyBegin(0))
        raise _INTL("Player 2 has no unfainted Pokémon") if sendout2 < 0
        @battlers[0].pbInitialize(@party1[sendout1],sendout1,false)
        @battlers[2].pbInitialize(@party1[sendout2],sendout2,false)
        pbDisplayBrief(_INTL("{1} sent\r\nout {2}!  Go! {3}!",
           @player[1].fullname,getBattlerPokemon(@battlers[2]).name,getBattlerPokemon(@battlers[0]).name))
        pbSetSeen(@party1[sendout1])
        pbSetSeen(@party1[sendout2])
      else
        sendout1=pbFindNextUnfainted(@party1,0)
        sendout2=pbFindNextUnfainted(@party1,sendout1+1)
        if sendout1 < 0 || sendout2 < 0
          raise _INTL("Player doesn't have two unfainted Pokémon")
        end
        @battlers[0].pbInitialize(@party1[sendout1],sendout1,false)
        @battlers[2].pbInitialize(@party1[sendout2],sendout2,false)
        pbDisplayBrief(_INTL("Go! {1} and {2}!",getBattlerPokemon(@battlers[0]).name,getBattlerPokemon(@battlers[2]).name))
      end
      pbSendOutInitial(@doublebattle,0,@party1[sendout1],2,@party1[sendout2])
    else
    #====================================
    # Initialize player in single battles
    #====================================
      @scene.sendingOut=true
      sendout=pbFindNextUnfainted(@party1,0)
      if sendout < 0
        raise _INTL("Player has no unfainted Pokémon")
      end
      playerpoke=@party1[sendout]
      @battlers[0].pbInitialize(playerpoke,sendout,false)
      pbDisplayBrief(_INTL("Go! {1}!",getBattlerPokemon(@battlers[0]).name))
      pbSendOutInitial(@doublebattle,0,playerpoke)
    end
    #====================================
    # Displays a message for notifying stat increase
    #====================================
    if wildpoke != nil && wildpoke.boss
      pbDisplay(_INTL("Le statistiche del Pokémon nemico sono più elevate!"))
    end
    #==================
    # Initialize battle
    #==================
    if @weather==PBWeather::SUNNYDAY
      pbDisplay(_INTL("The sunlight is strong."))
    elsif @weather==PBWeather::RAINDANCE
      pbDisplay(_INTL("It is raining."))
    elsif @weather==PBWeather::SANDSTORM
      pbDisplay(_INTL("A sandstorm is raging."))
    elsif @weather==PBWeather::HAIL
      pbDisplay(_INTL("Hail is falling."))
    elsif PBWeather.const_defined?(:HEAVYRAIN) && @weather==PBWeather::HEAVYRAIN
      pbDisplay(_INTL("It is raining heavily."))
    elsif PBWeather.const_defined?(:HARSHSUN) && @weather==PBWeather::HARSHSUN
      pbDisplay(_INTL("The sunlight is extremely harsh."))
    elsif PBWeather.const_defined?(:STRONGWINDS) && @weather==PBWeather::STRONGWINDS
      pbDisplay(_INTL("The wind is strong."))
    end
    pbAwaitReadiness

    #Qui viene chiamato random
    pbOnActiveAll   # Abilities
    @turncount=0

    loop do   # Now begin the battle loop
      PBDebug.log("***Round #{@turncount+1}***") if $INTERNAL
      if @debug && @turncount >=100
        @decision=pbDecisionOnTime()
        PBDebug.log("***[Undecided after 100 rounds]")
        pbAbort
        break
      end
      PBDebug.logonerr{
         pbCommandPhase
      }
      break if @decision > 0
      PBDebug.logonerr{
         pbAttackPhase
      }
      break if @decision > 0
      @scene.clearMessageWindow
      PBDebug.logonerr{
         pbEndOfRoundPhase
      }
      break if @decision > 0
      @turncount+=1
			
			break if @turncount == DRAGALISK_BATTLE_MAXTURNS && $game_switches[DRAGALISK_UNBEATABLE]==true
    end
    return pbEndOfBattle(canlose)
  end



  def pbRandom(x)
    @connection.send do |writer|
      writer.sym(:random) #Request type
      writer.int(x) #Max range for random
      writer.int(@randomCounter) #Random counter
      writer.int(@client_id == 0 ? @uid + @partner_uid : @partner_uid + @uid)
    end
    @randomCounter += 1
    ret = nil
    while (ret==nil)
      Graphics.update
      Input.update
      raise Connection::Disconnected.new("disconnected") if Input.trigger?(Input::B) && Kernel.pbConfirmMessageSerious("Would you like to disconnect?")
      @connection.updateExp([:random,:partnerDisconnected]) do |record|
        case (type = record.sym)
        when :random
          ret = record.int
          
        when :partnerDisconnected
          pbSEPlay("Battle flee")
          pbDisplay(_INTL("{1} disconnected!", opponent.fullname))
          @decision = 1
          @disconnected = true
          pbAbort
        else
          print "Unknown message: #{type}"
        end
      end
    end
    echoln "Called the fucking NET random! Counter at #{@randomCounter}, Rand is #{ret}"
    return ret
  end

  # Added optional args to not make v18 break.
  def pbSwitchInBetween(index, lax=false, cancancel=false)
    if pbOwnedByPlayer?(index)
      choice = super(index, lax, cancancel) {yield if block_given?}
      # bug fix for the unknown type :switch. cause: going into the pokemon menu then backing out and attacking, which sends the switch symbol regardless.
      if !cancancel # forced switches do not allow canceling, and both sides would expect a response.
        pbAwaitReadiness
        
        @connection.send do |writer|
          writer.sym(:fwd)
          writer.str(@partner_uid)
          writer.sym(:switch)
          writer.int(choice)
        end
      end
      return choice
    else
      frame = 0
      # So much renamed stuff...
      if defined?(ESSENTIALS_VERSION) && ESSENTIALS_VERSION =~ /^18/
        cbox = PokeBattle_Scene::MESSAGE_BOX
        hbox = "messageWindow"
        opponent = @opponent[0]
      else
        cbox = PokeBattle_Scene::MESSAGEBOX
        hbox = "messagewindow"
        opponent = @opponent
      end
      @scene.pbShowWindow(cbox)
      cw = @scene.sprites[hbox]
      cw.letterbyletter = false
      begin
        pbAwaitReadiness
        
        loop do
          frame += 1
          cw.text = _INTL("Waiting" + "." * (1 + ((frame / 8) % 3)))
          @scene.pbFrameUpdate(cw)
          Graphics.update
          Input.update
          raise Connection::Disconnected.new("disconnected") if Input.trigger?(Input::B) && Kernel.pbConfirmMessageSerious("Would you like to disconnect?")
          @connection.updateExp([:forfeit,:switch,:partnerDisconnected]) do |record|
            case (type = record.sym)
            when :forfeit
              pbSEPlay("Battle flee")
              pbDisplay(_INTL("{1} forfeited the match!", opponent.fullname))
              @decision = 1
              pbAbort
            when :partnerDisconnected
              pbSEPlay("Battle flee")
              pbDisplay(_INTL("{1} disconnected!", opponent.fullname))
              @decision = 1
              pbAbort
            when :switch
              return record.int

            else
              raise "Unknown message: #{type}"
            end
          end
        end
      ensure
        cw.letterbyletter = false
      end
    end
  end

  def pbRun(idxPokemon, duringBattle=false)
    ret = super(idxPokemon, duringBattle)
    if ret == 1
      @connection.send do |writer|
        writer.sym(:fwd)
        writer.str(@partner_uid)
        writer.sym(:forfeit)
      end
      @connection.discard(1)
    end
    return ret
  end

  def pbSwitch(favorDraws=false)
    if !favorDraws
      return if @decision>0
    else
      return if @decision==5
    end
    pbJudge()
    return if @decision>0
    switched=[]
    for index in CableClub::pokemon_order(@client_id)
      next if !@doublebattle && pbIsDoubleBattler?(index)
      next if @battlers[index] && !@battlers[index].isFainted?
      next if !pbCanChooseNonActive?(index)
      if !pbOwnedByPlayer?(index)
        if !pbIsOpposing?(index) || (@opponent && pbIsOpposing?(index))
          newenemy=pbSwitchInBetween(index,false,false) {yield if block_given?}
          newenemyname=newenemy
          if newenemy>=0 && isConst?(pbParty(index)[newenemy].ability,PBAbilities,:ILLUSION)
            newenemyname=pbGetLastPokeInTeam(index)
          end
          opponent=pbGetOwner(index)
          pbRecallAndReplace(index,newenemy)
          switched.push(index)
        end
      else
        newpoke=pbSwitchInBetween(index,true,false) {yield if block_given?}
        newpokename=newpoke
        if isConst?(@party1[newpoke].ability,PBAbilities,:ILLUSION)
          newpokename=pbGetLastPokeInTeam(index)
        end
        pbRecallAndReplace(index,newpoke,newpokename)
        switched.push(index)
      end
    end
    if switched.length>0
      priority=pbPriority
      for i in priority
        i.pbAbilitiesOnSwitchIn(true) if switched.include?(i.index)
      end
    end
  end
    
  # This is horrific. Basically, we need to force Essentials to look for
  # the RHS foe's move in all circumstances, otherwise we won't transmit
  # any moves for this turn and the battle will hang.
  def pbCanShowCommands?(index)
    super(index) || (index == 3 && Kernel.caller(1) =~ /pbCanShowCommands/)
  end
  
  def pbUpdateTurnTimer()
    @timer+=1
    @ui.updateTime("Time: #{(@timerMax-@timer)/60}")
  end

  def pbCommandPhase
		@scene.pbBeginCommandPhase
		@scene.pbResetCommandIndices
		for i in 0...4   # Reset choices if commands can be shown
			if pbCanShowCommands?(i) || @battlers[i].isFainted?
        echoln "Resetting choice for #{@battlers[i].species} #{i}"
				@choices[i][0]=0
				@choices[i][1]=0
				@choices[i][2]=nil
				@choices[i][3]=-1
			else
				battler=@battlers[i]
				unless !@doublebattle && pbIsDoubleBattler?(i)
					PBDebug.log("[Reusing commands for #{battler.pbThis(true)}]")
				end
			end
		end
		# Reset choices to perform Mega Evolution if it wasn't done somehow
		for i in 0..1
			for j in 0...@megaEvolution[i].length
				@megaEvolution[i][j]=-1 if @megaEvolution[i][j]>=0
			end
		end    
    our_indices = @doublebattle ? [0, 2] : [0]
    their_indices = @doublebattle ? [1, 3] : [1]
		for i in 0...4
      
      @timer=0
      @ui.updateTime("Time: #{(@timerMax-@timer)/60}")
			break if @decision!=0
      echoln "Battler #{i}:#{pbOwnedByPlayer?(i)}:#{PBSpecies.getName(@battlers[i].species)}:#{@choices[i][0]}"
      if i == their_indices.last && @choices[i][0]!=0
        target_order = CableClub::pokemon_target_order(@client_id)
        for our_index in our_indices
          echoln "SENT CHOICE #{@choices[our_index][0]}:#{@choices[our_index][1]}"
          @connection.send do |writer|
            pkmn = @battlers[our_index]
            writer.sym(:fwd)
            writer.str(@partner_uid)
            writer.sym(:choice)
            writer.int(@choices[our_index][0])
            writer.int(@choices[our_index][1])
            move = @choices[our_index][2] && pkmn.moves.index(@choices[our_index][2])
            echoln "#{pkmn.moves} #{@choices[our_index][2].name} #{@choices[our_index][2].id}"
            echoln "FORCE MOVE SEND INFO: #{move}  #{@choices[our_index][2]} #{pkmn.moves.index(@choices[our_index][2])}  #{@choices[our_index][2] && pkmn.moves.index(@choices[our_index][2])}"
            writer.nil_or(:int, move)
            # -1 invokes the RNG, out of order (somehow?!) which causes desync.
            # But this is a single battle, so the only possible choice is the foe.
            if !@doublebattle && @choices[our_index][3] == -1
              @choices[our_index][3] = their_indices[0]
            end
            # Target from their POV.
            our_target = @choices[our_index][3]
            their_target = target_order[our_target] rescue our_target
            writer.int(their_target)
            mega=@megaEvolution[0][0]
            mega^=1 if mega>=0
            writer.int(mega) # mega fix?
            Log.i("INFO","SENT BATTLE CHOICES for MONSTER AT INDEX #{i}")
          end
        end
      end
			next if @choices[i][0]!=0
      echoln "Evaluating action for #{PBSpecies.getName(@battlers[i].species)}"
			if !pbOwnedByPlayer?(i) || @controlPlayer
				#if !@battlers[i].isFainted? && pbCanShowCommands?(i)
				@scene.pbChooseEnemyCommand(i)
				#end
			else
				commandDone=false
				commandEnd=false
				if pbCanShowCommands?(i)
					loop do
						cmd=pbCommandMenu(i) {
              pbUpdateTurnTimer()
            }
						if cmd==0 # Fight
							if pbCanShowFightMenu?(i)
								commandDone=true if pbAutoFightMenu(i)
								until commandDone
									index=@scene.pbFightMenu(i) {
                    pbUpdateTurnTimer()
                  }
									if index<0
										side=(pbIsOpposing?(i)) ? 1 : 0
										owner=pbGetOwnerIndex(i)
										if @megaEvolution[side][owner]==i
											@megaEvolution[side][owner]=-1
										end
										break
									end
									next if !pbRegisterMove(i,index)
									if @doublebattle
										thismove=@battlers[i].moves[index]
										target=@battlers[i].pbTarget(thismove)
										if target==PBTargets::SingleNonUser # single non-user
											target=@scene.pbChooseTarget(i)
											next if target<0
											pbRegisterTarget(i,target)
										elsif target==PBTargets::UserOrPartner # Acupressure
											target=@scene.pbChooseTarget(i)
											next if target<0 || (target&1)==1
											pbRegisterTarget(i,target)
										end
									end
									commandDone=true
								end
							else
								pbAutoChooseMove(i)
								commandDone=true
							end
						elsif cmd==1 # Bag
							if !@internalbattle || $ISINTOURNAMENT
								if pbOwnedByPlayer?(i)
									pbDisplay(_INTL("Items can't be used here."))
								end
							elsif $trainerbossbattle
								pbDisplay(_INTL("La forte pressione non ti permette di usare strumenti!"))
							else
								item=pbItemMenu(i, @battlers[1]) {
                  pbUpdateTurnTimer()
                }
								if pbIsPokeBall?(item[0]) && !@opponent
									if item[0] == PBItems::XENOBALL && isXSpecies?(@battlers[1].species)
										pbConsumeItemInBattle($PokemonBag, item[0])
									elsif item[0] == PBItems::XENOBALL && !isXSpecies?(@battlers[1].species) ||
										item[0] != PBItems::XENOBALL && isXSpecies?(@battlers[1].species)
										pbDisplay(_INTL("Non puoi usare questa ball per catturare il\nPokémon!"))
										item[0]=-1
										#return
									elsif item[0] != PBItems::XENOBALL && !isXSpecies?(@battlers[1].species)
										pbConsumeItemInBattle($PokemonBag, item[0])
									elsif item[0] == PBItems::XENOBALL && isXSpecies?(@battlers[1].species) ||
										item[0] != PBItems::XENOBALL && isXSpecies?(@battlers[1].species)
										pbDisplay(_INTL("Non puoi usare questa ball per catturare il\nPokémon!"))
										item[0]=-1
										#return
									end
								end
								if item[0]>0
									if pbRegisterItem(i,item[0],item[1])
										commandDone=true
									end
								end
							end
						elsif cmd==2 # Pokémon
							pkmn=pbSwitchPlayer(i,false,true) {
                pbUpdateTurnTimer()
              }
							if pkmn>=0
								commandDone=true if pbRegisterSwitch(i,pkmn)
							end
						elsif cmd==3   # Run
							run=pbRun(i) 
							if run>0
								commandDone=true
								return
							elsif run<0
								commandDone=true
								side=(pbIsOpposing?(i)) ? 1 : 0
								owner=pbGetOwnerIndex(i)
								if @megaEvolution[side][owner]==i
									@megaEvolution[side][owner]=-1
								end
							end
						elsif cmd==4   # Call
							thispkmn=@battlers[i]
							@choices[i][0]=4   # "Call Pokémon"
							@choices[i][1]=0
							@choices[i][2]=nil
							side=(pbIsOpposing?(i)) ? 1 : 0
							owner=pbGetOwnerIndex(i)
							if @megaEvolution[side][owner]==i
								@megaEvolution[side][owner]=-1
							end
							commandDone=true
						elsif cmd==-1   # Go back to first battler's choice
							@megaEvolution[0][0]=-1 if @megaEvolution[0][0]>=0
							@megaEvolution[1][0]=-1 if @megaEvolution[1][0]>=0
							# Restore the item the player's first Pokémon was due to use
							if @choices[0][0]==3 && $PokemonBag && $PokemonBag.pbCanStore?(@choices[0][1])
								$PokemonBag.pbStoreItem(@choices[0][1])
							end
							pbCommandPhase
							return
						end
						break if commandDone
					end
				end
			end
		end
	end

  def pbDefaultChooseEnemyCommand(index)
    our_indices = @doublebattle ? [0, 2] : [0]
    their_indices = @doublebattle ? [1, 3] : [1]
    Log.i("FAINT INFORMATION", "0:#{@battlers[0].isFainted?} 1:#{@battlers[1].isFainted?} 2:#{@battlers[2].isFainted?} 3:#{@battlers[3].isFainted?}")
    # Sends our choices after they have all been locked in.
    if index == their_indices.last
      target_order = CableClub::pokemon_target_order(@client_id)
      for our_index in our_indices
        echoln "SENT CHOICE #{@choices[our_index][0]}:#{@choices[our_index][1]}"
        @connection.send do |writer|
          pkmn = @battlers[our_index]
          writer.sym(:fwd)
          writer.str(@partner_uid)
          writer.sym(:choice)
          writer.int(@choices[our_index][0])
          writer.int(@choices[our_index][1])
          move = @choices[our_index][2] && pkmn.moves.index(@choices[our_index][2])
          echoln "#{pkmn.moves} #{@choices[our_index][2].name} #{@choices[our_index][2].id}"
          echoln "MOVE SEND INFO: #{move}  #{@choices[our_index][2]} #{pkmn.moves.index(@choices[our_index][2])}  #{@choices[our_index][2] && pkmn.moves.index(@choices[our_index][2])}"
          writer.nil_or(:int, move)
          # -1 invokes the RNG, out of order (somehow?!) which causes desync.
          # But this is a single battle, so the only possible choice is the foe.
          if !@doublebattle && @choices[our_index][3] == -1
            @choices[our_index][3] = their_indices[0]
          end
          # Target from their POV.
          our_target = @choices[our_index][3]
          their_target = target_order[our_target] rescue our_target
          writer.int(their_target)
          mega=@megaEvolution[0][0]
          mega^=1 if mega>=0
          writer.int(mega) # mega fix?
          Log.i("INFO","SENT BATTLE CHOICES for MONSTER AT INDEX #{index}")
        end
      end
      frame = 0
      @scene.pbShowWindow(PokeBattle_Scene::MESSAGEBOX)
      cw = @scene.sprites["messagewindow"]
      cw.letterbyletter = false
      begin
        loop do
          frame += 1
          cw.text = _INTL("Waiting" + "." * (1 + ((frame / 8) % 3)))
          @scene.pbFrameUpdate(cw)
          Graphics.update
          Input.update
          raise Connection::Disconnected.new("disconnected") if Input.trigger?(Input::B) && Kernel.pbConfirmMessageSerious("Would you like to disconnect?")
          @connection.updateExp([:forfeit,:sneed,:seed,:choice,:partnerDisconnected],true,
            Proc.new {|time, max| @ui.updateTime("#{max - time}")}) do |record|
            case (type = record.sym)
            when :forfeit
              pbSEPlay("Battle flee")
              pbDisplay(_INTL("{1} forfeited the match!", @opponent.fullname))
              @decision = 1
              pbAbort
            when :sneed
              print("MA CHE OOOOOOOO")
            
            when :seed
              seed=record.int()
              srand(seed) if @client_id==1

            when :choice
              their_index = their_indices.shift
              partner_pkmn = @battlers[their_index]
              @choices[their_index][0] = record.int
              @choices[their_index][1] = record.int
              move = record.nil_or(:int)
              echoln "MOVE RECEIVE INFO: #{move}  #{partner_pkmn.moves[move]}  #{move && partner_pkmn.moves[move]}"
              @choices[their_index][2] = move && partner_pkmn.moves[move]
              @choices[their_index][3] = record.int
              @megaEvolution[1][0] = record.int # mega fix?
              return if their_indices.empty?
            
            when :partnerDisconnected
              pbSEPlay("Battle flee")
              pbDisplay(_INTL("{1} disconnected!", opponent.fullname))
              @decision = 1
              @disconnected = true
              pbAbort
            else
              raise "Unknown message: #{type}"
            end
          end
        end
      ensure
        cw.letterbyletter = true
      end
    end
  end

  def pbDefaultChooseNewEnemy(index, party)
    raise "Expected this to be unused."
  end
end

class PokeBattle_Battler
  alias old_pbFindUser pbFindUser if !defined?(old_pbFindUser)

  # This ensures the targets are processed in the same order.
  def pbFindUser(choice, targets)
    ret = old_pbFindUser(choice, targets)
    if !@battle.client_id.nil?
      order = CableClub::pokemon_order(@battle.client_id)
      targets.sort! {|a, b| order[a.index] <=> order[b.index]}
    end
    return ret
  end
end

class Socket
  def recv_up_to(maxlen, flags = 0)
    retString=""
    buf = "\0" * maxlen
    retval=Winsock.recv(@fd, buf, buf.size, flags)
    SocketError.check if retval == -1
    retString+=buf[0,retval]
    return retString
  end

  def write_ready?
    SocketError.check if (ret = Winsock.select(1, 0, [1, @fd].pack("ll"), 0, [0, 0].pack("ll"))) == -1
    return ret != 0
  end
end

class Connection
  class Disconnected < Exception; end
  class ProtocolError < StandardError; end

  def self.open(host, port)
    # XXX: Non-blocking connect.
    TCPSocket.open(host, port) do |socket|
      connection = Connection.new(socket)
      yield connection
    end
  end

  def initialize(socket)
    @socket = socket
    @recv_parser = Parser.new
    @recv_records = []
    @discard_records = 0
  end

  def update
    if @socket.ready?
      recvd = @socket.recv_up_to(4096, 0)
      raise Disconnected.new("server disconnected") if recvd.empty?
      @recv_parser.parse(recvd) {|record| @recv_records << record}
    end
    # Process at most one record so that any control flow in the block doesn't cause us to lose records.
    if !@recv_records.empty?
      echoln @recv_records
      record = @recv_records.shift
      if record.disconnect?
        reason = record.str() rescue "unknown error"
        raise Disconnected.new(reason)
      end
      if @discard_records == 0
        begin
          yield record
        else
          print ProtocolError.new("Unconsumed input: #{record}") if !record.empty?
        end
      else
        @discard_records -= 1
      end
    end
  end

  def updateExp(expected, timeoutCheck = false, counterProc = nil)
    if timeoutCheck
      CableClub.timeoutCounter += 1
      if (CableClub.timeoutCounter % 300 == 0)
        echoln "Increasing timeout timer... #{CableClub.timeoutCounter / 300}"
      end
      if counterProc != nil
        counterProc.call(CableClub.timeoutCounter,CableClub.maxTimeOut)
      end
    end
    if @socket.ready?
      recvd = @socket.recv_up_to(4096, 0)
      raise Disconnected.new("server disconnected") if recvd.empty?
      @recv_parser.parse(recvd) {|record| @recv_records << record}
    end
    # Process at most one record so that any control flow in the block doesn't cause us to lose records.
    if !@recv_records.empty?
      recv_clone = @recv_records.clone
      recv_clone = recv_clone.shift
      record = @recv_records.shift
      if record.disconnect?
        reason = record.str() rescue "unknown error"
        raise Disconnected.new(reason)
      end
      if @discard_records == 0
        ignored = false;
        begin
          if (!expected.include?(recv_clone.fields.last.to_sym))
            ignored = true
            Log.i("INFO-IGNORED","Ignored message with sym field #{record.fields.last.to_sym}")
          else 
            yield record
          end
        else
          print ProtocolError.new("Unconsumed input: #{record}") if !record.empty? && ignored == false
        end
      else
        @discard_records -= 1
      end
    end
  end

  def can_send?
    return @socket.write_ready?
  end

  def send
    # XXX: Non-blocking send.
    # but note we don't update often so we need some sort of drained?
    # for the send buffer so that we can delay starting the battle.
    writer = RecordWriter.new
    yield writer
    begin 
      @socket.send(writer.line!)
    rescue Errno::ECONNABORTED
      print "FUCK YOU BITCH"
    end
  end

  def discard(n)
    raise "Cannot discard #{n} messages." if n < 0
    @discard_records += n
  end
end

class Parser
  def initialize
    @buffer = ""
  end

  def parse(data)
    return if data.empty?
    lines = data.split("\n", -1)
    lines[0].insert(0, @buffer)
    @buffer = lines.pop
    lines.each do |line|
      yield RecordParser.new(line) if !line.empty?
    end
  end
end

class RecordParser
  attr_accessor :fields

  def initialize(data)
    @fields = []
    field = ""
    escape = false
    # each_char and chars don't exist.
    for i in (0...data.length)
      char = data[i].chr
      if char == "," && !escape
        @fields << field
        field = ""
      elsif char == "\\" && !escape
        escape = true
      else
        field += char
        escape = false
      end
    end
    @fields << field
    @fields.reverse!
  end

  def empty?; return @fields.empty? end

  def disconnect?
    if @fields.last == "disconnect"
      @fields.pop
      return true
    else
      return false
    end
  end

  def nil_or(t)
    raise Connection::ProtocolError.new("Expected nil or #{t}, got EOL") if @fields.empty?
    if @fields.last.empty?
      @fields.pop
      return nil
    else
      return self.send(t)
    end
  end

  def bool
    raise Connection::ProtocolError.new("Expected bool, got EOL") if @fields.empty?
    field = @fields.pop
    if field == "true"
      return true
    elsif field == "false"
      return false
    else
      raise Connection::ProtocolError.new("Expected bool, got #{field}")
    end
  end

  def int
    raise Connection::ProtocolError.new("Expected int, got EOL") if @fields.empty?
    field = @fields.pop
    begin
      return Integer(field)
    rescue
      raise Connection::ProtocolError.new("Expected int, got #{field}")
    end
  end

  def str
    raise Connection::ProtocolError.new("Expected str, got EOL") if @fields.empty?
    @fields.pop
  end

  def sym
    raise Connection::ProtocolError.new("Expected sym, got EOL") if @fields.empty?
    @fields.pop.to_sym
  end

  def to_s; @fields.reverse.join(", ") end
end

class RecordWriter
  def initialize
    @fields = []
  end

  def line!
    line = @fields.map {|field| escape!(field)}.join(",")
    line += "\n"
    @fields = []
    return line
  end

  def escape!(s)
    s.gsub!("\\", "\\\\")
    s.gsub!(",", "\,")
    return s
  end

  def nil_or(t, o)
    if o.nil?
      @fields << ""
    else
      self.send(t, o)
    end
  end

  def bool(b); @fields << b.to_s end
  def int(i); @fields << i.to_s end
  def str(s) @fields << s end
  def sym(s); @fields << s.to_s end
end

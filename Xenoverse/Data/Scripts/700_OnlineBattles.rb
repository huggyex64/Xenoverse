#####################################################################
# ONLINE BATTLES
#####################################################################
class OnlineLobby
  attr_accessor(:playerList)

  def initialize()
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites={}
    #ID - Name - Debug - Status
    @playerList=[]
  end

  def pbDisplayAvaiblePlayerList(list)
    # Updating the list every time it gets updated on screen
    if list != @playerlist
      @playerList = list
    end
    # Disposing of old sprites
    if @sprites["list"] != nil
      @sprites["list"].dispose
    end
    @sprites["list"] = Sprite.new(@viewport)
    @sprites["list"].bitmap = Bitmap.new(256,300)
    @sprites["list"].bitmap.fill_rect(0,0,256,200,Color.new(30,30,30,200))
    for entry in list
      @sprites["list"].bitmap.draw_text(6,6+30*list.index(entry),250,30,"#{"%05d" % entry[0]}:#{entry[1]}-#{entry[3]}")
    end
  end

  def dispose
    @viewport.dispose
    for sprite in @sprites.values
      sprite.dispose
    end
  end
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
      playerlist.push(entry.split("</s>"))
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
=begin
def pbRandom(x)
  @connection.send do |writer|
    writer.sym(:random) #Request type
    writer.int(x) #Max range for random
    writer.int(@randomCounter) #Random counter
  end
  @randomCounter += 1
  ret = nil
  while (ret==nil)
    Graphics.update
    Input.update
    raise Connection::Disconnected.new("disconnected") if Input.trigger?(Input::B) && Kernel.pbConfirmMessageSerious("Would you like to disconnect?")
    @connection.update do |record|
      case (type = record.sym)
      when :random
        ret = record.int
      else
        raise "Unknown message: #{type}"
      end
    end
  end
  echoln "Called the fucking NET random! Counter at #{@randomCounter}, Rand is #{ret}"
  return ret
end
=end
def pbOnlineLobby
  echoln srand(1234)
  echoln rand(3**6)
  echoln rand(3**6)
  echoln rand(3**6)
  echoln rand(3**6)
  echoln srand(1234)
  echoln rand(3**6)
  echoln rand(3**6)
  echoln rand(3**6)
  echoln rand(3**6)

  srand


  lobby = OnlineLobby.new
  if $Trainer.party.length == 0
    Kernel.pbMessage(_INTL("I'm sorry, you must have a Pokémon to enter the Cable Club."))
    lobby.dispose
    return
  end
  
  #oldParty = $Trainer.party
  $Trainer.party.each do |pkmn|
    pkmn.level=50
    pkmn.calcStats
  end
  msgwindow = Kernel.pbCreateMessageWindow()
  begin
    Kernel.pbMessageDisplay(msgwindow, _INTL("Connecting to online server..."))
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
  HOST = "94.176.239.231"
  PORT = 9999
end

# TODO: Automatically timeout.

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

  def self.connect_to(msgwindow, partner_trainer_id)
    pbMessageDisplayDots(msgwindow, _INTL("Connecting"), 0)
    Connection.open(HOST, PORT) do |connection|
      state = :await_server
      last_state = nil
      client_id = 0
      partner_name = nil
      partner_party = nil
      frame = 0
      activity = nil
      seed = nil
      battle_type = nil
      chosen = nil
      partner_chosen = nil
      partner_confirm = false

      loop do
        if state != last_state
          last_state = state
          frame = 0
        else
          frame += 1
        end

        Graphics.update
        Input.update
        if Input.trigger?(Input::B)
          message = case state
            when :await_server; _INTL("Abort connection?\\^")
            when :await_partner; _INTL("Abort search?\\^")
            else; _INTL("Disconnect?\\^")
            end
          Kernel.pbMessageDisplay(msgwindow, message)
          return if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
        end

        case state
        # Waiting to be connected to the server.
        # Note: does nothing without a non-blocking connection.
        when :await_server
          if connection.can_send?
            connection.send do |writer|
              writer.sym(:find)
              writer.int(partner_trainer_id)
              writer.str($Trainer.name)
              writer.int($Trainer.id)
              write_party(writer)
            end
            state = :await_partner
          else
            pbMessageDisplayDots(msgwindow, _ISPRINTF("Your ID: {1:05d}\\nConnecting",$Trainer.publicID($Trainer.id)), frame)
          end

        # Waiting to be connected to the partner.
        when :await_partner
          pbMessageDisplayDots(msgwindow, _ISPRINTF("Your ID: {1:05d}\\nSearching",$Trainer.publicID($Trainer.id)), frame)
          connection.update do |record|
            case (type = record.sym)
            when :found
              client_id = record.int
              partner_name = record.str
              partner_party = parse_party(record)
              Kernel.pbMessageDisplay(msgwindow, _INTL("{1} connected!", partner_name))
              if client_id == 0
                state = :choose_activity
              else
                state = :await_choose_activity
              end

            else
              raise "Unknown message: #{type}"
            end
          end

        # Choosing an activity (leader only).
        when :choose_activity
          Kernel.pbMessageDisplay(msgwindow, _INTL("Choose an activity.\\^"))
          command = Kernel.pbShowCommands(msgwindow, [_INTL("Single Battle"), _INTL("Double Battle"), _INTL("Trade")], -1)
          case command
          when 0..1 # Battle
            if command == 1 && $Trainer.party.length < 2
              Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, you must have at least two Pokémon to engage in a double battle."))
            elsif command == 1 && partner_party.length < 2
              Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, your partner must have at least two Pokémon to engage in a double battle."))
            else
              connection.send do |writer|
                writer.sym(:battle)
                seed = rand(2**31)
                writer.int(seed)
                battle_type = case command
                  when 0; :single
                  when 1; :double
                  else; raise "Unknown battle type"
                  end
                writer.sym(battle_type)
                writer.int($Trainer.trainertype)
              end
              activity = :battle
              state = :await_accept_activity
            end

            when 2 # Trade
              connection.send do |writer|
                writer.sym(:trade)
              end
              activity = :trade
              state = :await_accept_activity

            else # Cancel
              # TODO: Confirmation box?
              return
            end

        # Waiting for the partner to accept our activity (leader only).
        when :await_accept_activity
          pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to accept", partner_name), frame)
          connection.update do |record|
            case (type = record.sym)
            when :ok
              case activity
              when :battle
                trainertype = record.int
                partner = PokeBattle_Trainer.new(partner_name, trainertype)
                (partner.partyID=0) rescue nil # EBDX compat
                do_battle(connection, client_id, seed, battle_type, partner, partner_party)
                state = :choose_activity

              when :trade
                chosen = choose_pokemon
                if chosen >= 0
                  connection.send do |writer|
                    writer.sym(:ok)
                    writer.int(chosen)
                  end
                  state = :await_trade_confirm
                else
                  connection.send do |writer|
                    writer.sym(:cancel)
                  end
                  connection.discard(1)
                  state = :choose_activity
                end

              else
                raise "Unknown activity: #{activity}"
              end

            when :cancel
              Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} doesn't want to #{activity.to_s}.", partner_name))
              state = :choose_activity

            else
              raise "Unknown message: #{type}"
            end
          end

        # Waiting for the partner to select an activity (follower only).
        when :await_choose_activity
          pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to pick an activity", partner_name), frame)
          connection.update do |record|
            case (type = record.sym)
            when :battle
              seed = record.int
              battle_type = record.sym
              trainertype = record.int
              partner = PokeBattle_Trainer.new(partner_name, trainertype)
              (partner.partyID=0) rescue nil # EBDX compat
              # Auto-reject double battles that we cannot participate in.
              if battle_type == :double && $Trainer.party.length < 2
                connection.send do |writer|
                  writer.sym(:cancel)
                end
                state = :await_choose_activity
              else
                Kernel.pbMessageDisplay(msgwindow, _INTL("{1} wants to battle!\\^", partner_name))
                if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
                  connection.send do |writer|
                    writer.sym(:ok)
                    writer.int($Trainer.trainertype)
                  end
                  do_battle(connection, client_id, seed, battle_type, partner, partner_party)
                else
                  connection.send do |writer|
                    writer.sym(:cancel)
                  end
                  state = :await_choose_activity
                end
              end

            when :trade
              Kernel.pbMessageDisplay(msgwindow, _INTL("{1} wants to trade!\\^", partner_name))
              if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
                connection.send do |writer|
                  writer.sym(:ok)
                end
                chosen = choose_pokemon
                if chosen >= 0
                  connection.send do |writer|
                    writer.sym(:ok)
                    writer.int(chosen)
                  end
                  state = :await_trade_confirm
                else
                  connection.send do |writer|
                    writer.sym(:cancel)
                  end
                  connection.discard(1)
                  state = :await_choose_activity
                end
              else
                connection.send do |writer|
                  writer.sym(:cancel)
                end
                state = :await_choose_activity
              end

            else
              raise "Unknown message: #{type}"
            end
          end

        # Waiting for the partner to select a Pokémon to trade.
        when :await_trade_pokemon
          if partner_confirm
            pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to resynchronize", partner_name), frame)
          else
            pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to confirm the trade", partner_name), frame)
          end

          connection.update do |record|
            case (type = record.sym)
            when :ok
              partner = PokeBattle_Trainer.new(partner_name, $Trainer.trainertype)
              pbHealAll
              partner_party.each {|pkmn| pkmn.heal}
              pkmn = partner_party[partner_chosen]
              partner_party[partner_chosen] = $Trainer.party[chosen]
              do_trade(chosen, partner, pkmn)
              connection.send do |writer|
                writer.sym(:update)
                write_pkmn(writer, $Trainer.party[chosen])
              end
              partner_confirm = true

            when :update
              partner_party[partner_chosen] = parse_pkmn(record)
              partner_chosen = nil
              partner_confirm = false
              if client_id == 0
                state = :choose_activity
              else
                state = :await_choose_activity
              end

            when :cancel
              Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} doesn't want to trade after all.", partner_name))
              partner_chosen = nil
              partner_confirm = false
              if client_id == 0
                state = :choose_activity
              else
                state = :await_choose_activity
              end

            else
              raise "Unknown message: #{type}"
            end
          end

        when :await_trade_confirm
          if partner_chosen.nil?
            pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to pick a Pokémon", partner_name), frame)
          else
            pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to confirm the trade", partner_name), frame)
          end

          connection.update do |record|
            case (type = record.sym)
            when :ok
              partner_chosen = record.int
              pbHealAll
              partner_party.each {|pkmn| pkmn.heal}
              partner_pkmn = partner_party[partner_chosen]
              your_pkmn = $Trainer.party[chosen]
              abort=$Trainer.ablePokemonCount==1 && your_pkmn==$Trainer.ablePokemonParty[0] && partner_pkmn.isEgg?
              able_party=partner_party.find_all { |p| p && !p.isEgg? && !p.isFainted? }
              abort|=able_party.length==1 && partner_pkmn==able_party[0] && your_pkmn.isEgg?
              unless abort
                partner_speciesname = (partner_pkmn.isEgg?) ? _INTL("Egg") : PBSpecies.getName(getID(PBSpecies,partner_pkmn.species))
                your_speciesname = (your_pkmn.isEgg?) ? _INTL("Egg") : PBSpecies.getName(getID(PBSpecies,your_pkmn.species))
                loop do
                  Kernel.pbMessageDisplay(msgwindow, _INTL("{1} has offered {2} ({3}) for your {4} ({5}).\\^",partner_name,
                      partner_pkmn.name,partner_speciesname,your_pkmn.name,your_speciesname))
                  command = Kernel.pbShowCommands(msgwindow, [_INTL("Check {1}'s offer",partner_name), _INTL("Check My Offer"), _INTL("Accept/Deny Trade")], -1)
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
                        writer.sym(:ok)
                      end
                      state = :await_trade_pokemon
                      break
                    else
                      connection.send do |writer|
                        writer.sym(:cancel)
                      end
                      partner_chosen = nil
                      connection.discard(1)
                      if client_id == 0
                        state = :choose_activity
                      else
                        state = :await_choose_activity
                      end
                      break
                    end
                  end
                end
              else
                Kernel.pbMessageDisplay(msgwindow, _INTL("The trade was unable to be completed."))
                partner_chosen = nil
                if client_id == 0
                  state = :choose_activity
                else
                  state = :await_choose_activity
                end
              end
              
            when :cancel
              Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} doesn't want to trade after all.", partner_name))
              partner_chosen = nil
              if client_id == 0
                state = :choose_activity
              else
                state = :await_choose_activity
              end

            else
              raise "Unknown message: #{type}"
            end
          end  
        else
          raise "Unknown state: #{state}"
        end
      end
    end
  end

  def self.enlist(msgwindow,ui)
    pbMessageDisplayDots(msgwindow, _INTL("Connecting"), 0)
    Connection.open(HOST, PORT) do |connection|
      state = :await_server
      last_state = nil
      client_id = 0
      partner_name = nil
      partner_party = nil
      frame = 0
      activity = nil
      seed = nil
      battle_type = nil
      chosen = nil
      partner_chosen = nil
      partner_confirm = false

      loop do
        if state != last_state
          last_state = state
          frame = 0
        else
          frame += 1
        end

        Graphics.update
        Input.update
        if Input.trigger?(Input::B)
          message = case state
            when :await_server; _INTL("Abort connection?\\^")
            when :await_partner; _INTL("Abort search?\\^")
            else; _INTL("Disconnect?\\^")
            end
          Kernel.pbMessageDisplay(msgwindow, message)
          return if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
        end

        if Input.trigger?(Input::A)
          case state
          when :enlisted
            Kernel.pbMessageDisplay(msgwindow, _INTL("Do you want to start a connection?"))
            if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
              # Requesting the list of connected players
              options = []
              optionsDict = {}
              for player in ui.playerList
                if player[3]=="WAITING" && player[0].to_i != $Trainer.publicID($Trainer.id) #CHECKING IF IT'S WAITING AND IT'S NOT SELF
                  
                  options.push("#{player[0]} - #{player[1]}")
                  optionsDict["#{player[0]} - #{player[1]}"]=player[0].to_i
                end
              end
              ret = Kernel.pbShowCommands(msgwindow,options,-1)
              if ret>0
                if connection.can_send?
                  connection.send do |writer|
                    writer.sym(:askinteraction)
                    writer.str($Trainer.name)
                    writer.int($Trainer.id)
                    writer.int(optionsDict[options[ret]]) #Here i'm sending the request to the one i wanna connect to
                  end
                  state = :await_interaction_accept
                end
              else
                Kernel.pbMessageDisplay(msgwindow, _INTL("Skipped connection."))
              end
            end
          end
        end

        case state
        # Waiting to be connected to the server.
        # Note: does nothing without a non-blocking connection.
        when :await_server
          if connection.can_send?
            connection.send do |writer|
              writer.sym(:enlist)
              writer.str($Trainer.name)
              writer.int($Trainer.id)
              write_party(writer)
            end
            state = :enlisted
          else
            pbMessageDisplayDots(msgwindow, _ISPRINTF("Your ID: {1:05d}\\nConnecting",$Trainer.publicID($Trainer.id)), frame)
          end
        when :enlisted
          pbMessageDisplayDots(msgwindow, _ISPRINTF("Your ID: {1:05d}\\nEnlisted, waiting to join lobby",$Trainer.publicID($Trainer.id)), frame)
          if (frame%60 == 0) #Requesting player list every X seconds
            ui.pbDisplayAvaiblePlayerList(BattleRequest.getPlayerList())
          end
          connection.updateExp([:found,:askAcceptInteraction]) do |record|
            case (type = record.sym)
            when :found
              client_id = record.int
              partner_name = record.str
              partner_party = parse_party(record)
              Kernel.pbMessageDisplay(msgwindow, _INTL("{1} connected!", partner_name))
              if client_id == 0
                state = :choose_activity
              else
                state = :await_choose_activity
              end
            when :askAcceptInteraction
              req = record.int
              Kernel.pbMessageDisplay(msgwindow, _INTL("{1} asked for connection. Do you want to start the connection?\\^",req))
              command = Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2)
              # Accepted
              if command == 0
                if connection.can_send?
                  connection.send do |writer|
                    writer.sym(:acceptInteraction)
                    writer.int(req)
                  end
                end
              else
                Kernel.pbMessageDisplay(msgwindow, _INTL("Connection refused.\\^"))
              end
            else
              raise "Unknown message: #{type}"
            end
          end
        # The leader is awaiting 
        when :await_interaction_accept
          pbMessageDisplayDots(msgwindow, _ISPRINTF("Your ID: {1:05d}\\nAsked X for interaction",$Trainer.publicID($Trainer.id)), frame)
          if (frame%60 == 0) #Requesting player list every X seconds
            ui.pbDisplayAvaiblePlayerList(BattleRequest.getPlayerList())
          end
          connection.update do |record|
            case (type = record.sym)
            when :found
              client_id = record.int
              partner_name = record.str
              partner_party = parse_party(record)
              Kernel.pbMessageDisplay(msgwindow, _INTL("{1} connected!", partner_name))
              if client_id == 0
                state = :choose_activity
              else
                state = :await_choose_activity
              end
            when :ok
              client_id = record.int
              partner_name = record.str
              partner_party = parse_party(record)
              Kernel.pbMessageDisplay(msgwindow, _INTL("{1} connected!", partner_name))
              if client_id == 0
                state = :choose_activity
              else
                state = :await_choose_activity
              end

            when :cancel
              Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} doesn't want to interact.", partner_name))
              state = :enlisted

            else
              raise "Unknown message: #{type}"
            end
          end
        
        # Waiting to be connected to the partner.
        when :await_partner
          pbMessageDisplayDots(msgwindow, _ISPRINTF("Your ID: {1:05d}\\nSearching",$Trainer.publicID($Trainer.id)), frame)
          connection.update do |record|
            case (type = record.sym)
            when :found
              client_id = record.int
              partner_name = record.str
              partner_party = parse_party(record)
              Kernel.pbMessageDisplay(msgwindow, _INTL("{1} connected!", partner_name))
              if client_id == 0
                state = :choose_activity
              else
                state = :await_choose_activity
              end

            else
              raise "Unknown message: #{type}"
            end
          end

        # Choosing an activity (leader only).
        when :choose_activity
          Kernel.pbMessageDisplay(msgwindow, _INTL("Choose an activity.\\^"))
          command = Kernel.pbShowCommands(msgwindow, [_INTL("Single Battle"), _INTL("Double Battle"), _INTL("Trade")], -1)
          case command
          when 0..1 # Battle
            if command == 1 && $Trainer.party.length < 2
              Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, you must have at least two Pokémon to engage in a double battle."))
            elsif command == 1 && partner_party.length < 2
              Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, your partner must have at least two Pokémon to engage in a double battle."))
            else
              connection.send do |writer|
                writer.sym(:battle)
                seed = rand(2**31)
                writer.int(seed)
                battle_type = case command
                  when 0; :single
                  when 1; :double
                  else; raise "Unknown battle type"
                  end
                writer.sym(battle_type)
                writer.int($Trainer.trainertype)
              end
              activity = :battle
              state = :await_accept_activity
            end

            when 2 # Trade
              connection.send do |writer|
                writer.sym(:trade)
              end
              activity = :trade
              state = :await_accept_activity

            else # Cancel
              # TODO: Confirmation box?
              return
            end

        # Waiting for the partner to accept our activity (leader only).
        when :await_accept_activity
          echoln "#{state}: awaiting leader to choose activity"
          pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to accept", partner_name), frame)
          connection.update do |record|
            case (type = record.sym)
            when :ok
               #Kernel.pbDisposeMessageWindow(msgwindow)
              case activity
              when :battle
                msgwindow.visible = false
                trainertype = record.int
                partner = PokeBattle_Trainer.new(partner_name, trainertype)
                (partner.partyID=0) rescue nil # EBDX compat
                do_battle(connection, client_id, seed, battle_type, partner, partner_party)
                msgwindow.visible = true
                state = :choose_activity

              when :trade
                chosen = choose_pokemon
                if chosen >= 0
                  connection.send do |writer|
                    writer.sym(:ok)
                    writer.int(chosen)
                  end
                  state = :await_trade_confirm
                else
                  connection.send do |writer|
                    writer.sym(:cancel)
                  end
                  connection.discard(1)
                  state = :choose_activity
                end

              else
                print "Unknown activity: #{activity}"
              end

            when :cancel
              Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} doesn't want to #{activity.to_s}.", partner_name))
              state = :choose_activity

            else
              print "Unknown message: #{type}"
            end
          end

        # Waiting for the partner to select an activity (follower only).
        when :await_choose_activity
          pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to pick an activity", partner_name), frame)
          connection.update do |record|
            case (type = record.sym)
            when :battle
              seed = record.int
              battle_type = record.sym
              trainertype = record.int
              partner = PokeBattle_Trainer.new(partner_name, trainertype)
              (partner.partyID=0) rescue nil # EBDX compat
              # Auto-reject double battles that we cannot participate in.
              if battle_type == :double && $Trainer.party.length < 2
                connection.send do |writer|
                  writer.sym(:cancel)
                end
                state = :await_choose_activity
              else
                Kernel.pbMessageDisplay(msgwindow, _INTL("{1} wants to battle!\\^", partner_name))
                if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
                  msgwindow.visible = false #Kernel.pbDisposeMessageWindow(msgwindow)
                  connection.send do |writer|
                    writer.sym(:ok)
                    writer.int($Trainer.trainertype)
                  end
                  do_battle(connection, client_id, seed, battle_type, partner, partner_party)
                  msgwindow.visible = true
                else
                  connection.send do |writer|
                    writer.sym(:cancel)
                  end
                  state = :await_choose_activity
                end
              end

            when :trade
              Kernel.pbMessageDisplay(msgwindow, _INTL("{1} wants to trade!\\^", partner_name))
              if Kernel.pbShowCommands(msgwindow, [_INTL("Yes"), _INTL("No")], 2) == 0
                msgwindow.visible = true #Kernel.pbDisposeMessageWindow(msgwindow)
                connection.send do |writer|
                  writer.sym(:ok)
                end
                chosen = choose_pokemon
                if chosen >= 0
                  connection.send do |writer|
                    writer.sym(:ok)
                    writer.int(chosen)
                  end
                  state = :await_trade_confirm
                else
                  connection.send do |writer|
                    writer.sym(:cancel)
                  end
                  connection.discard(1)
                  state = :await_choose_activity
                end
              else
                connection.send do |writer|
                  writer.sym(:cancel)
                end
                state = :await_choose_activity
              end

            else
              raise "Unknown message: #{type}"
            end
          end

        # Waiting for the partner to select a Pokémon to trade.
        when :await_trade_pokemon
          if partner_confirm
            pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to resynchronize", partner_name), frame)
          else
            pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to confirm the trade", partner_name), frame)
          end

          connection.update do |record|
            case (type = record.sym)
            when :ok
              partner = PokeBattle_Trainer.new(partner_name, $Trainer.trainertype)
              pbHealAll
              partner_party.each {|pkmn| pkmn.heal}
              pkmn = partner_party[partner_chosen]
              partner_party[partner_chosen] = $Trainer.party[chosen]
              do_trade(chosen, partner, pkmn)
              connection.send do |writer|
                writer.sym(:update)
                write_pkmn(writer, $Trainer.party[chosen])
              end
              partner_confirm = true

            when :update
              partner_party[partner_chosen] = parse_pkmn(record)
              partner_chosen = nil
              partner_confirm = false
              if client_id == 0
                state = :choose_activity
              else
                state = :await_choose_activity
              end

            when :cancel
              Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} doesn't want to trade after all.", partner_name))
              partner_chosen = nil
              partner_confirm = false
              if client_id == 0
                state = :choose_activity
              else
                state = :await_choose_activity
              end

            else
              raise "Unknown message: #{type}"
            end
          end

        when :await_trade_confirm
          if partner_chosen.nil?
            pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to pick a Pokémon", partner_name), frame)
          else
            pbMessageDisplayDots(msgwindow, _INTL("Waiting for {1} to confirm the trade", partner_name), frame)
          end

          connection.update do |record|
            case (type = record.sym)
            when :ok
              partner_chosen = record.int
              pbHealAll
              partner_party.each {|pkmn| pkmn.heal}
              partner_pkmn = partner_party[partner_chosen]
              your_pkmn = $Trainer.party[chosen]
              abort=$Trainer.ablePokemonCount==1 && your_pkmn==$Trainer.ablePokemonParty[0] && partner_pkmn.isEgg?
              able_party=partner_party.find_all { |p| p && !p.isEgg? && !p.isFainted? }
              abort|=able_party.length==1 && partner_pkmn==able_party[0] && your_pkmn.isEgg?
              unless abort
                partner_speciesname = (partner_pkmn.isEgg?) ? _INTL("Egg") : PBSpecies.getName(getID(PBSpecies,partner_pkmn.species))
                your_speciesname = (your_pkmn.isEgg?) ? _INTL("Egg") : PBSpecies.getName(getID(PBSpecies,your_pkmn.species))
                loop do
                  Kernel.pbMessageDisplay(msgwindow, _INTL("{1} has offered {2} ({3}) for your {4} ({5}).\\^",partner_name,
                      partner_pkmn.name,partner_speciesname,your_pkmn.name,your_speciesname))
                  command = Kernel.pbShowCommands(msgwindow, [_INTL("Check {1}'s offer",partner_name), _INTL("Check My Offer"), _INTL("Accept/Deny Trade")], -1)
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
                        writer.sym(:ok)
                      end
                      state = :await_trade_pokemon
                      break
                    else
                      connection.send do |writer|
                        writer.sym(:cancel)
                      end
                      partner_chosen = nil
                      connection.discard(1)
                      if client_id == 0
                        state = :choose_activity
                      else
                        state = :await_choose_activity
                      end
                      break
                    end
                  end
                end
              else
                Kernel.pbMessageDisplay(msgwindow, _INTL("The trade was unable to be completed."))
                partner_chosen = nil
                if client_id == 0
                  state = :choose_activity
                else
                  state = :await_choose_activity
                end
              end
              
            when :cancel
              Kernel.pbMessageDisplay(msgwindow, _INTL("I'm sorry, {1} doesn't want to trade after all.", partner_name))
              partner_chosen = nil
              if client_id == 0
                state = :choose_activity
              else
                state = :await_choose_activity
              end

            else
              raise "Unknown message: #{type}"
            end
          end  
        else
          raise "Unknown state: #{state}"
        end
      end
    end
  end


  def self.pbMessageDisplayDots(msgwindow, message, frame)
    Kernel.pbMessageDisplay(msgwindow, message + "...".slice(0..(frame/8) % 3) + "\\^", false)
  end

# NO !defined?(ESSENTIALSVERSION) && !defined?(ESSENTIALS_VERSION)
# NO defined?(ESSENTIALSVERSION) && ESSENTIALSVERSION =~ /^17/
# NO defined?(ESSENTIALS_VERSION) && ESSENTIALS_VERSION =~ /^18/

  # Renamed constants, yay...
  def self.do_battle(connection, client_id, seed, battle_type, partner, partner_party)
    echoln "AOOOOOOOOOOO SO PARTITO IO"
    pbHealAll # Avoids having to transmit damaged state.
    partner_party.each {|pkmn| pkmn.heal}
    scene = pbNewBattleScene
    battle = PokeBattle_CableClub.new(connection, client_id, scene, partner_party, partner)
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
    pbBattleAnimation(trainerbgm, partner.trainertype, partner.name) {
      pbSceneStandby {
        # XXX: Hope we call rand in the same order in both clients...
        srand(seed)
        begin
          battle.pbStartBattle(true)
        rescue Connection::Disconnected
          scene.pbEndBattle(0)
          exc = $!
        end
      }
    }
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
  def initialize(connection, client_id, scene, opponent_party, opponent)
    @connection = connection
    @client_id = client_id
    @seedset=false
    @randomCounter = 0
    @randomHistory = []
    player = PokeBattle_Trainer.new($Trainer.name, $Trainer.trainertype)
    super(scene, $Trainer.party, opponent_party, player, opponent)
    @battleAI  = PokeBattle_CableClub_AI.new(self) if defined?(ESSENTIALS_VERSION) && ESSENTIALS_VERSION =~ /^18/
  end
  
  def pbRandom(x)
    @connection.send do |writer|
      writer.sym(:random) #Request type
      writer.int(x) #Max range for random
      writer.int(@randomCounter) #Random counter
    end
    @randomCounter += 1
    ret = nil
    while (ret==nil)
      Graphics.update
      Input.update
      raise Connection::Disconnected.new("disconnected") if Input.trigger?(Input::B) && Kernel.pbConfirmMessageSerious("Would you like to disconnect?")
      @connection.update do |record|
        case (type = record.sym)
        when :random
          ret = record.int
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
      choice = super(index, lax, cancancel)
      # bug fix for the unknown type :switch. cause: going into the pokemon menu then backing out and attacking, which sends the switch symbol regardless.
      if !cancancel # forced switches do not allow canceling, and both sides would expect a response.
        @connection.send do |writer|
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
        loop do
          frame += 1
          cw.text = _INTL("Waiting" + "." * (1 + ((frame / 8) % 3)))
          @scene.pbFrameUpdate(cw)
          Graphics.update
          Input.update
          raise Connection::Disconnected.new("disconnected") if Input.trigger?(Input::B) && Kernel.pbConfirmMessageSerious("Would you like to disconnect?")
          @connection.update do |record|
            case (type = record.sym)
            when :forfeit
              pbSEPlay("Battle flee")
              pbDisplay(_INTL("{1} forfeited the match!", opponent.fullname))
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
          newenemy=pbSwitchInBetween(index,false,false)
          newenemyname=newenemy
          if newenemy>=0 && isConst?(pbParty(index)[newenemy].ability,PBAbilities,:ILLUSION)
            newenemyname=pbGetLastPokeInTeam(index)
          end
          opponent=pbGetOwner(index)
          pbRecallAndReplace(index,newenemy)
          switched.push(index)
        end
      else
        newpoke=pbSwitchInBetween(index,true,false)
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
    
=begin
doesn't seem to work in tests, so commented it out.
seems to work when commented. for some reason...
    def pbPriority(*args)
      begin
        battlers = @battlers.dup
        order = CableClub::pokemon_order(@client_id)
        for i in 0..3
          @battlers[i] = battlers[order[i]]
        end
        return super(*args)
      ensure
        @battlers = battlers
      end
    end
=end
    
  # This is horrific. Basically, we need to force Essentials to look for
  # the RHS foe's move in all circumstances, otherwise we won't transmit
  # any moves for this turn and the battle will hang.
  def pbCanShowCommands?(index)
    super(index) || (index == 3 && Kernel.caller(1) =~ /pbCanShowCommands/)
  end
  
  def pbDefaultChooseEnemyCommand(index)
    our_indices = @doublebattle ? [0, 2] : [0]
    their_indices = @doublebattle ? [1, 3] : [1]
    # Sends our choices after they have all been locked in.
    if index == their_indices.last
      @connection.send do |writer|
        cur_seed=srand
        srand(cur_seed)
        writer.sym(:seed)
        writer.int(cur_seed)
      end
      target_order = CableClub::pokemon_target_order(@client_id)
      for our_index in our_indices
        @connection.send do |writer|
          pkmn = @battlers[our_index]
          writer.sym(:choice)
          writer.int(@choices[our_index][0])
          writer.int(@choices[our_index][1])
          move = @choices[our_index][2] && pkmn.moves.index(@choices[our_index][2])
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
          @connection.update do |record|
            case (type = record.sym)
            when :forfeit
              pbSEPlay("Battle flee")
              pbDisplay(_INTL("{1} forfeited the match!", @opponent.fullname))
              @decision = 1
              pbAbort
              
            when :seed
              seed=record.int()
              srand(seed) if @client_id==1

            when :choice
              their_index = their_indices.shift
              partner_pkmn = @battlers[their_index]
              @choices[their_index][0] = record.int
              @choices[their_index][1] = record.int
              move = record.nil_or(:int)
              @choices[their_index][2] = move && partner_pkmn.moves[move]
              @choices[their_index][3] = record.int
              @megaEvolution[1][0] = record.int # mega fix?
              return if their_indices.empty?

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

  def updateExp(expected)
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
          if (!expected.include?(recv_clone.sym))
            ignored = true
            Log.i("INFO-IGNORED","Ignored message with sym field #{record.fields[0].to_sym}")
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

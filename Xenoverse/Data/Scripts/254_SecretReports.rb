class SecretReports
    attr_accessor :pages
    attr_accessor :no
    attr_accessor :unlocked

    DATA={}

    def self.register(hash)
        DATA[hash[:id]] = DATA[hash[:id_number]] = hash
    end

    def self.get(id)
        return DATA[id] if DATA.has_key?(id)
    end
end
#Additions to trainer class to save the page progress
class PokeBattle_Trainer
    attr_accessor :pages

    def pages
        @pages = {} if @pages==nil
        return @pages
    end

    def obtainPage(id, page)
        echoln "obtained #{id} #{page}"
        @pages={} if (@pages == nil)
        @pages[id]={} if @pages[id] == nil
        @pages[id][page]=true
        
    end
end

SecretReports.register({
    :id => :TamaraReports,
    :id_number => 0,
    :title => "Diario di ???",
    :pageno => 12,
    :bg => "Graphics/Pictures/reportsbg",
    :pages =>[
        "???: Ho deciso di tenere un diario per ricordare le numerose esperienze che farò! "+
        "Proprio oggi mi sono unita al Team Dimension, e nonostante io sia solo una recluta, "+
        "mi sento già legata alla causa! Spero di poter aiutare il più possibile.",

        "???: C’è molto lavoro da fare qui! Sembra stiano progettando dei robot da utilizzare insieme alle altre reclute, "+ 
        "per smaltire più in fretta il lavoro. Nel frattempo, sono stata promossa a Sergente! "+
        "A quanto pare la mia motivazione ha fatto colpo sui ranghi alti e hanno deciso di promuovermi. Buon per me!",

        "???: Ormai è passato tantissimo tempo da quando mi sono unita al Team Dimension. 
        Sono stata addirittura promossa a Colonnello! Durante la promozione ho conosciuto il Generale, 
        che uomo affascinante! Credo di essermi innamorata! Mi è stata assegnata una missione 
        riguardante la cattura di una specie X nel Canyon Asteroide. Spero di non dover fargli del male, ma se fosse necessario..."
    ]
})

def pbTestReport
    $Trainer.obtainPage(:TamaraReports,1)
    SecretReportScreen.new(SecretReports.get(:TamaraReports))
end

class SecretReportScreen

    def initialize(reports)
        @reports = reports
        @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
        @viewport.z = 99999
        @sprites={}

        setUpScreen()

        pbFadeInAndShow(@sprites)
        #input handling
        inputLoop()
    end

    def setUpScreen
        @sprites["bg"] = Sprite.new(@viewport)
        @sprites["bg"].bitmap = pbBitmap(@reports[:bg] == nil ? "Graphics/Pictures/reportsbg" : @reports[:bg])#Bitmap.new(512,384)
        #@sprites["bg"].bitmap.fill_rect(0,0,512,384,Color.new(40,40,80))
        
        id = @reports[:id]
        commands=CommandList.new
        for i in 0...@reports[:pageno]
            pageno = "%03d" % (i+1)
            commands.add("page#{i}", $Trainer.pages.has_key?(id) && $Trainer.pages[id].has_key?(i) ? _INTL("#{pageno}: Page Number #{i+1}") : "#{pageno}: ???")
        end

        @sprites["cmdwindow"]=Window_CommandPokemonEx.new(commands.list)
        cmdwindow=@sprites["cmdwindow"]
        cmdwindow.viewport=@viewport
        cmdwindow.resizeToFit(cmdwindow.commands)
        cmdwindow.height=250
        cmdwindow.x=12
        cmdwindow.y=48
        cmdwindow.windowskin=nil
        cmdwindow.visible=true
        cmdwindow.baseColor = Color.new(48,48,48)
        cmdwindow.shadowColor = nil
        

        @sprites["rightOverlay"] = BitmapSprite.new(256,Graphics.height, @viewport)
        @sprites["rightOverlay"].x = 256
        @sprites["rightOverlay"].bitmap.clear
        pbSetFont(@sprites["rightOverlay"].bitmap,"Barlow Condensed",27)

        textpos = [[_INTL(@reports[:title]),128,80,2,Color.new(48,48,48)],
                   [_INTL("Collected Pages: {1}",$Trainer.pages.has_key?(id) ? "#{$Trainer.pages[id].keys.length}" : "0"),128,110,2,Color.new(48,48,48)],
                   [_INTL("Total Pages: {1}", @reports[:pageno]),128,140,2,Color.new(48,48,48)]]

        pbDrawTextPositions(@sprites["rightOverlay"].bitmap,textpos)


    end


    def inputLoop
        loop do
            Graphics.update
            Input.update
            #this handles basic page selection
            @sprites["cmdwindow"].update

            if Input.trigger?(Input::C) && $Trainer.pages[@reports[:id]]!=nil && $Trainer.pages[@reports[:id]][@sprites["cmdwindow"].index]
                readPage(@sprites["cmdwindow"].index)
            end


            if (Input.trigger?(Input::B))
                break
            end
        end
        endScreen()
    end

    def readPage(id)
        Kernel.pbMessage(@reports[:pages][id])
    end

    def endScreen()
        pbFadeOutAndHide(@sprites)
        pbDisposeSpriteHash(@sprites)
    end
end
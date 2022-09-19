package features;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.FlxSprite;
#if android
import com.player03.android6.Permissions;
#end

using StringTools;

class PermissionsPrompt extends MusicBeatState
{
    var bg:FlxSprite;
    var prompts:FlxTypedGroup<Prompt>;

    override function create()
    {
		PlayerSettings.init();

        FlxG.save.bind('funkin', 'ninjamuffin99');
		ClientPrefs.loadPrefs();

        #if (!FEATURE_STORAGE_ACCESS) //send to title state if none of the features are enabled
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        MusicBeatState.switchState(new TitleState());
        #end

        #if (FEATURE_STORAGE_ACCESS) //do the griddy if some feature was found enabled
        if(!ClientPrefs.answeredReq)
        {
            bg = new FlxSprite().loadGraphic(Paths.image("menuDesat"), false, FlxG.width, FlxG.height);
            bg.screenCenter();
            bg.antialiasing = ClientPrefs.globalAntialiasing;
            add(bg);
    
            prompts = new FlxTypedGroup<Prompt>();
            add(prompts);
    
            #if FEATURE_ONLINE_SONGS
            var prompt = new Prompt
            ({
                header: 'Online fetching',
                info: ['Do you want to allow', 'fetching songs from an', 'online server? (Hosted by me)', 'Can be offline sometimes', 'Note: needs a good', 'internet connection :('],
                hfontSize: 25,
                ifontSize: 20,
                settingVar: "allowOnlineFetch"
            });
            prompt.screenCenter();
            #if FEATURE_STORAGE_ACCESS
            prompt.x -= 220;
            #end
            prompts.add(prompt);
            #end
    
            #if FEATURE_STORAGE_ACCESS
            var prompt = new Prompt
            ({
                header: 'FileSystem Access',
                info: ["Do you want to allow", "access to the file system?"],
                hfontSize: 23,
                ifontSize: 20,
                settingVar: 'allowFileSys'
            });
            prompt.screenCenter();
            #if FEATURE_ONLINE_SONGS
            prompt.x += 220;
            #end
            prompts.add(prompt);
            #end

            #if android
            Permissions.onPermissionsGranted.add(_onPermsGrantedEvent);
            Permissions.onPermissionsDenied.add(_onPermsDeniedEvent);
            #end
        }
        else
        {
            FlxTransitionableState.skipNextTransIn = true;
            FlxTransitionableState.skipNextTransOut = true;
            MusicBeatState.switchState(new TitleState());
        }
        #end

        super.create();
    }

    override function update(elapsed:Float)
    {
        prompts.forEach(function(prompt:Prompt)
        {
            #if (windows || web)
            //clicky clicky
            if(FlxG.mouse.overlaps(prompt) && FlxG.mouse.justPressed && (FlxG.mouse.overlaps(prompt.okButtonReg) || FlxG.mouse.overlaps(prompt.cancelButtonReg)))
            {
                //DUDE IM SO FUCKING SMART HOLY SHITTTTT
                Reflect.setProperty(ClientPrefs, prompt.props.settingVar, (FlxG.mouse.overlaps(prompt.okButtonReg) ? true : false));
                //dawg???
                FlxTween.tween(prompt, {alpha: 0}, 0.5, 
                {
                    onComplete: function(twn:FlxTween)
                    {
                        //hardcoded, sorry lol
                        var moveTo:Float = 0;
                        if(prompt.x == 675)
                        {
                            moveTo = prompt.x - 220;
                        }
                        else if(prompt.x == 235)
                        {
                            moveTo = prompt.x + 220;
                        }
                        prompt.kill();
                        prompt.destroy();
                        prompts.remove(prompt, true);

                        if(prompts.members.length == 1)
                        {
                            FlxTween.tween(prompts.members[0], {x: moveTo}, 1, { ease: FlxEase.smoothStepInOut });
                        }

                        if(prompts.members.length == 0)
                        {
                            ClientPrefs.answeredReq = true;
                            ClientPrefs.saveSettings();
                            MusicBeatState.switchState(new TitleState());
                        }
                    }
                });
            }
            #end

            //same shit as above but for android lol
            #if (android)
            for(touch in FlxG.touches.list)
            {
                if(touch.overlaps(prompt) && touch.justReleased && (touch.overlaps(prompt.okButtonReg) || touch.overlaps(prompt.cancelButtonReg)))
                {
                    if(prompt.props.header == 'FileSystem Access'){ Permissions.requestPermissions([Permissions.READ_EXTERNAL_STORAGE, Permissions.WRITE_EXTERNAL_STORAGE]); }
                    Reflect.setProperty(ClientPrefs, prompt.props.settingVar, (touch.overlaps(prompt.okButtonReg) ? true : false));
                    FlxTween.tween(prompt, {alpha: 0}, 0.5, 
                    {
                        onComplete: function(twn:FlxTween)
                        {
                            //hardcoded, sorry lol
                            var moveTo:Float = 0;
                            if(prompt.x == 675)
                            {
                                moveTo = prompt.x - 220;
                            }
                            else if(prompt.x == 235)
                            {
                                moveTo = prompt.x + 220;
                            }
                            prompt.kill();
                            prompt.destroy();
                            prompts.remove(prompt, true);

                            if(prompts.members.length == 1)
                            {
                                FlxTween.tween(prompts.members[0], {x: moveTo}, 1, { ease: FlxEase.smoothStepInOut });
                            }

                            if(prompts.members.length == 0)
                            {
                                ClientPrefs.answeredReq = true;
                                ClientPrefs.saveSettings();
                                MusicBeatState.switchState(new TitleState());
                            }
                        }
                    });
                }
            }
            #end
        });

        super.update(elapsed);
    }

    #if android
    static function _onPermsGrantedEvent(args:Array<String>):Void
    {
        trace("perms granted");
        ClientPrefs.allowFileSys = true;
    }

    static function _onPermsDeniedEvent(args:Array<String>):Void
    {
        trace("perms denied");
        ClientPrefs.allowFileSys = true;
    }
    #end
}

class Prompt extends FlxSpriteGroup
{
    var bg:FlxSprite;
    var buttons:FlxSprite;
    public var okButtonReg:FlxSprite;
    public var cancelButtonReg:FlxSprite;
    public var props:PromptProperties;

    public function new(properties:PromptProperties = null)
    {
        super();

        if(properties == null)
            properties = 
            {
                header: "Placeholder",
                info: ["This is a prompt placeholder", "modify this in the code"],
                hfontSize: 25,
                ifontSize: 20,
                settingVar: null
            }

        props = properties;

        bg = new FlxSprite().loadGraphic(Paths.image("ui/promptbg"));
        bg.antialiasing = ClientPrefs.globalAntialiasing;
        add(bg);

        var text = new FlxText(bg.x + 105, bg.y + 30, 0, properties.header, properties.hfontSize);
        text.setFormat(Paths.font("vcr.ttf"), properties.hfontSize, FlxColor.BLACK, LEFT);
        text.antialiasing = ClientPrefs.globalAntialiasing;
        add(text);

        //shit couldnt afford an \n
        var prevText:FlxText = null;
        for(i in 0...properties.info.length)
        {
            var text = new FlxText(bg.x + 12, (prevText == null ? text.y + 50 : prevText.y + 20), 0, properties.info[i], properties.ifontSize);
            text.setFormat(Paths.font("vcr.ttf"), properties.ifontSize, FlxColor.BLACK, LEFT);
            text.antialiasing = ClientPrefs.globalAntialiasing;
            add(text);
            prevText = text;
        }

        //im so fucking smart
        buttons = new FlxSprite(bg.x + 15, bg.y + 260);
        buttons.frames = Paths.getSparrowAtlas('ui/prompt_buttons');
        buttons.animation.addByIndices('but0', 'buttons', [0], '', 0);
        buttons.animation.addByIndices('but1', 'buttons', [1], '', 0);
        buttons.animation.play('but0', true);
        add(buttons);

        //used for mouse operations
        okButtonReg = new FlxSprite(buttons.x, buttons.y).makeGraphic(Std.int(buttons.width / 2), Std.int(buttons.height), FlxColor.TRANSPARENT);
        add(okButtonReg);

        cancelButtonReg = new FlxSprite(buttons.x + (buttons.width / 2), buttons.y).makeGraphic(Std.int(buttons.width / 2), Std.int(buttons.height), FlxColor.TRANSPARENT);
        add(cancelButtonReg);
    }

    //handle button sfx, anims and shit
    override function update(elapsed:Float)
    {
        //IM FUCKING BECOMING SMARTER EVERY FUCKING DAYYYYYYY
        #if (windows || web)
        if(FlxG.mouse.overlaps(okButtonReg) && buttons.animation.curAnim.name == "but1")
            changeAnim("but0");

        if(FlxG.mouse.overlaps(cancelButtonReg) && buttons.animation.curAnim.name == "but0")
            changeAnim("but1");

        if(FlxG.mouse.justPressed && (FlxG.mouse.overlaps(okButtonReg) || FlxG.mouse.overlaps(cancelButtonReg)))
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
        }
        #end

        //same logic as above
        #if (android)
        for(touch in FlxG.touches.list)
        {
            if(touch.overlaps(okButtonReg) && buttons.animation.curAnim.name == "but1")
                changeAnim("but0");

            if(touch.overlaps(cancelButtonReg) && buttons.animation.curAnim.name == "but0")
                changeAnim("but1");

            if(touch.justReleased && (touch.overlaps(okButtonReg) || touch.overlaps(cancelButtonReg)))
            {
                FlxG.sound.play(Paths.sound('cancelMenu'));
            }
        }
        #end

        super.update(elapsed);
    }

    function changeAnim(newAnim:String)
    {
        buttons.animation.play(newAnim, true);
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
}

typedef PromptProperties =
{
    //the header of the prompt
    var header:String;
    //the info shit of the prompt
    var info:Array<String>;
    //the header font size
    var hfontSize:Int;
    //the info font size
    var ifontSize:Int;
    var settingVar:String;
}
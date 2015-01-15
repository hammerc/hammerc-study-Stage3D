package tests 
{
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.getTimer;
	
	import scorpio3D.actor.GameActor;
	import scorpio3D.actor.GameActorPool;
	import scorpio3D.actor.GameLevelParser;
	import scorpio3D.input.GameInput;
	import scorpio3D.object3D.Entity;
	import scorpio3D.particle.Particle;
	import scorpio3D.particle.ParticleSystem;
	import scorpio3D.utils.GameTimer;
	import scorpio3D.utils.Utils;
	
	/**
	 * 星球大战.
	 * @author wizardc
	 */
	public class SpaceWar extends Sprite
	{
		private const VERSION_STRING:String = "Version: 1.10";
		
		private const STATE_TITLESCREEN:int = 0;
		private const STATE_PLAYING:int = 1;
		
		private var gameState:int = STATE_TITLESCREEN;
		private var titlescreenTf:TextField;
		
		private var gametimer:GameTimer;
		
		private var introOverlayEndTime:int = 0;
		private var nextShootTime:uint = 0;
		private var shootDelay:uint = 200;
		private var invulnerabilityTimeLeft:int = 0;
		private var invulnerabilityMsWhenHit:int = 3000;
		private var screenShakes:int = 0;
		private var screenShakeCameraAngle:Number = 0;
		
		private var gameinput:GameInput;
		
		//跟随相机的最佳位置
		private var chaseCameraXangle:Number = -5;
		private var chaseCameraDistance:Number = 4;
		private var chaseCameraHeight:Number = 2;
		
		//每秒向前移动的速度
		private var flySpeed:Number = 1;
		//每毫上下左右移动的速度
		private const moveSpeed:Number = 0.02;
		//每毫秒转动的角度
		private const asteroidRotationSpeed:Number = 0.002;
		
		//限制飞船的移动范围
		private var playerMaxx:Number = 32;
		private var playerMaxy:Number = 32;
		private var playerMaxz:Number = 0;
		private var playerMinx:Number = -32;
		private var playerMiny:Number = 0.1;
		private var playerMinz:Number = 0;
		private var levelCompletePlayerMinz:Boolean = true;
		
		//所有 3D 实体对象
		private var chaseCamera:Entity
		private var props:Vector.<Entity>;
		private var player:GameActor;
		private var enemies:GameActorPool;
		private var playerBullets:GameActorPool;
		private var enemyBullets:GameActorPool;
		private var explo:Particle;
		private var particleSystem:ParticleSystem;
		
		//重用的实体指针
		private var asteroids1:Entity;
		private var asteroids2:Entity;
		private var asteroids3:Entity;
		private var asteroids4:Entity;
		private var engineGlow:Entity;
		private var sky:Entity;
		private var entity:Entity;
		private var actor:GameActor;
		
		//GUI
		private var fpsLast:uint = getTimer();
		private var fpsTicks:uint = 0;
		private var fpsTf:TextField;
		private var gpuTf:TextField;
		private var scoreTf:TextField;
		private var healthTf:TextField;
		private var score:uint = 0;
		private var combo:uint = 0;
		private var comboBest:uint = 0;
		private var scenePolycount:uint = 0;
		
		private var healthText_0:String = '';
		private var healthText_1:String = '|  |  |  |  |';
		private var healthText_2:String = '|  |  |  |  |  |  |  |  |  |  |';
		private var healthText_3:String = '|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |';
		
		private var context3D:Context3D;
		private var shaderProgram1:Program3D;
		private var shaderWithLight:Program3D;
		private var dynamicLightShader:Program3D;
		
		//透视矩阵
		private var projectionmatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
		//摄像机矩阵
		private var viewmatrix:Matrix3D = new Matrix3D();
		
		[Embed (source = "../../assets/player.jpg")]
		private var playerTextureBitmap:Class;
		private var playerTextureData:Bitmap = new playerTextureBitmap();
		[Embed (source = "../../assets/terrain_texture.jpg")]
		private var terrainTextureBitmap:Class;
		private var terrainTextureData:Bitmap = new terrainTextureBitmap();
		[Embed (source = "../../assets/craters.jpg")]
		private var cratersTextureBitmap:Class;
		private var cratersTextureData:Bitmap = new cratersTextureBitmap();
		[Embed (source = "../../assets/sky.jpg")]
		private var skyTextureBitmap:Class;
		private var skyTextureData:Bitmap = new skyTextureBitmap();
		[Embed (source = "../../assets/engine.jpg")]
		private var puffTextureBitmap:Class;
		private var puffTextureData:Bitmap = new puffTextureBitmap();
		[Embed (source = "../../assets/particle1.jpg")]
		private var particle1data:Class;
		private var particle1bitmap:Bitmap = new particle1data();
		[Embed (source = "../../assets/particle2.jpg")]
		private var particle2data:Class;
		private var particle2bitmap:Bitmap = new particle2data();
		[Embed (source = "../../assets/particle3.jpg")]
		private var particle3data:Class;
		private var particle3bitmap:Bitmap = new particle3data();
		[Embed (source = "../../assets/particle4.jpg")]
		private var particle4data:Class;
		private var particle4bitmap:Bitmap = new particle4data();
		
		[Embed (source = "../../assets/badguys.jpg")]
		private var badguyTextureData:Class;
		private var badguyTextureBitmap:Bitmap = new badguyTextureData();
		[Embed (source = "../../assets/hulltech.jpg")]
		private var techTextureData:Class;
		private var techTextureBitmap:Bitmap = new techTextureData();
		[Embed (source = "../../assets/title_screen.png")]
		private var titleScreenData:Class;
		private var titleScreen:Bitmap = new titleScreenData();
		[Embed (source = "../../assets/hud_overlay.png")]
		private var hudOverlayData:Class;
		private var hudOverlay:Bitmap = new hudOverlayData();
		[Embed (source = "../../assets/intro.png")] 
		private var introOverlayData:Class;
		private var introOverlay:Bitmap = new introOverlayData();
		
		[Embed (source = "../../assets/level_key.gif")] 
		private static const LEVELKEYDATA:Class;
		private var levelKey:Bitmap = new LEVELKEYDATA();
		[Embed (source = "../../assets/level_00.gif")] 
		private static const LEVELDATA:Class;
		private var levelData:Bitmap = new LEVELDATA();
		
		[Embed (source = "../../assets/gui_font.ttf", embedAsCFF = 'false', fontFamily = 'guiFont', mimeType = 'application/x-font-truetype', unicodeRange='U+0020-U+002F, U+0030-U+0039, U+003A-U+0040, U+0041-U+005A, U+005B-U+0060, U+0061-U+007A, U+007B-U+007E')]
		private const GUI_FONT:Class;
		[Embed (source = "../../assets/sfxmusic.mp3")]
		public var introMp3:Class;
		[Embed (source = "../../assets/sfxblast.mp3")]
		public var blastMp3:Class;
		[Embed (source = "../../assets/sfxexplode.mp3")]
		public var explodeMp3:Class;
		[Embed (source = "../../assets/sfxgun.mp3")]
		public var gunMp3:Class;
		
		[Embed (source = "../../assets/spaceship_funky.obj", mimeType = "application/octet-stream")]
		private var myObjData5:Class;
		[Embed (source = "../../assets/puff.obj", mimeType = "application/octet-stream")] 
		private var puffObjData:Class;
		[Embed (source = "../../assets/terrain.obj", mimeType = "application/octet-stream")] 
		private var terrainObjData:Class;
		[Embed (source = "../../assets/asteroids.obj", mimeType = "application/octet-stream")] 
		private var asteroidsObjData:Class;
		[Embed (source = "../../assets/sky.obj", mimeType = "application/octet-stream")] 
		private var skyObjData:Class;
		[Embed (source = "../../assets/explosion1.obj", mimeType = "application/octet-stream")] 
		private var explosion1_data:Class;
		[Embed (source = "../../assets/explosion2.obj", mimeType = "application/octet-stream")] 
		private var explosion2_data:Class;
		[Embed (source = "../../assets/explosionfat.obj", mimeType = "application/octet-stream")] 
		private var explosionfat_data:Class;
		[Embed (source = "../../assets/bullet.obj", mimeType = "application/octet-stream")] 
		private var bulletData:Class;
		[Embed (source = "../../assets/sentrygun01.obj", mimeType = "application/octet-stream")] 
		private var sentrygun01_data:Class;
		[Embed (source = "../../assets/sentrygun02.obj", mimeType = "application/octet-stream")] 
		private var sentrygun02_data:Class;
		[Embed (source = "../../assets/sentrygun03.obj", mimeType = "application/octet-stream")] 
		private var sentrygun03_data:Class;
		[Embed (source = "../../assets/sentrygun04.obj", mimeType = "application/octet-stream")] 
		private var sentrygun04_data:Class;
		[Embed (source = "../../assets/fueltank01.obj", mimeType = "application/octet-stream")] 
		private var fueltank01_data:Class;
		[Embed (source = "../../assets/fueltank02.obj", mimeType = "application/octet-stream")] 
		private var fueltank02_data:Class;
		[Embed (source = "../../assets/boss.obj", mimeType = "application/octet-stream")] 
		private var bossData:Class;
		[Embed (source = "../../assets/astro_tunnel.obj", mimeType = "application/octet-stream")] 
		private var astroTunnelData:Class;
		[Embed (source = "../../assets/asteroid_00.obj", mimeType = "application/octet-stream")] 
		private var asteroid_00_data:Class;
		[Embed (source = "../../assets/asteroid_01.obj", mimeType = "application/octet-stream")] 
		private var asteroid_01_data:Class;
		[Embed (source = "../../assets/asteroid_02.obj", mimeType = "application/octet-stream")] 
		private var asteroid_02_data:Class;
		[Embed (source = "../../assets/island.obj", mimeType = "application/octet-stream")] 
		private var islandData:Class;
		[Embed (source = "../../assets/slab01.obj", mimeType = "application/octet-stream")] 
		private var slab01_data:Class;
		[Embed (source = "../../assets/slab02.obj", mimeType = "application/octet-stream")] 
		private var slab02_data:Class;
		[Embed (source = "../../assets/slab03.obj", mimeType = "application/octet-stream")] 
		private var slab03_data:Class;
		[Embed (source = "../../assets/slab04.obj", mimeType = "application/octet-stream")] 
		private var slab04_data:Class;
		[Embed (source = "../../assets/station01.obj", mimeType = "application/octet-stream")] 
		private var station01_data:Class;
		[Embed (source = "../../assets/station02.obj", mimeType = "application/octet-stream")] 
		private var station02_data:Class;
		[Embed (source = "../../assets/station03.obj", mimeType = "application/octet-stream")] 
		private var station03_data:Class;
		[Embed (source = "../../assets/station04.obj", mimeType = "application/octet-stream")] 
		private var station04_data:Class;
		[Embed (source = "../../assets/station05.obj", mimeType = "application/octet-stream")] 
		private var station05_data:Class;
		[Embed (source = "../../assets/station06.obj", mimeType = "application/octet-stream")] 
		private var station06_data:Class;
		[Embed (source = "../../assets/station07.obj", mimeType = "application/octet-stream")] 
		private var station07_data:Class;
		[Embed (source = "../../assets/station08.obj", mimeType = "application/octet-stream")] 
		private var station08_data:Class;
		[Embed (source = "../../assets/station09.obj", mimeType = "application/octet-stream")] 
		private var station09_data:Class;
		[Embed (source = "../../assets/station10.obj", mimeType = "application/octet-stream")] 
		private var station10_data:Class;
		[Embed (source = "../../assets/wormhole.obj", mimeType = "application/octet-stream")] 
		private var wormholeData:Class;
		
		//贴图对象
		private var playerTexture:Texture;
		private var terrainTexture:Texture;
		private var cratersTexture:Texture;
		private var skyTexture:Texture;
		private var puffTexture:Texture;
		private var particle1texture:Texture;
		private var particle2texture:Texture;
		private var particle3texture:Texture;
		private var particle4texture:Texture;
		private var badguytexture:Texture;
		private var techtexture:Texture;
		
		//音效对象
		public var introSound:Sound = (new introMp3) as Sound;
		public var blastSound:Sound = (new blastMp3) as Sound;
		public var explodeSound:Sound = (new explodeMp3) as Sound;
		public var gunSound:Sound = (new gunMp3) as Sound;
		public var musicChannel:SoundChannel;
		
		public function SpaceWar() 
		{
			if (stage != null) 
				init();
			else 
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			if (hasEventListener(Event.ADDED_TO_STAGE))
				removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			initGUI();
			
			var stage3DAvailable:Boolean = ApplicationDomain.currentDomain.hasDefinition("flash.display.Stage3D");
			if (stage3DAvailable)
			{
				gametimer = new GameTimer(heartbeat,3333);
				gameinput = new GameInput(stage, gamestart);
				
				props = new Vector.<Entity>();
				
				stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
				stage.stage3Ds[0].addEventListener(ErrorEvent.ERROR, onStage3DError);
				
				stage.stage3Ds[0].requestContext3D();
			}
			else
			{
				trace("stage3DAvailable is false!");
				titlescreenTf.text = 'Flash 11 Required.\n' +
					'Your version: ' + Capabilities.version +
					'\nThis game uses Stage3D.\n' +
					'Please upgrade to Flash 11\n' +
					'so you can play 3d games!';
			}
		}
		
		private function onStage3DError(e:ErrorEvent):void
		{
			trace("onStage3DError!");
			titlescreenTf.text = 'Your Flash 11 settings\n' +
				'have 3D turned OFF.\n' +
				'Ensure that you use\n' +
				'wmode=direct\n' +
				'in your html file.';
		}
		
		private function onContext3DCreate(event:Event):void 
		{
			if (hasEventListener(Event.ENTER_FRAME))
				removeEventListener(Event.ENTER_FRAME,enterFrame);
			
			//获取 context3D
			var mystage3D:Stage3D = event.target as Stage3D;
			context3D = mystage3D.context3D;
			
			if (context3D == null)
			{
				trace('ERROR: no context3D - video driver problem?');
				return;
			}
			
			//检测是否使用软渲染
			if ((context3D.driverInfo == Context3DRenderMode.SOFTWARE) || (context3D.driverInfo.indexOf('oftware') > -1))
			{
				//Context3DRenderMode.AUTO
				trace("Software mode detected!");
				titlescreenTf.text = 'Your Flash 11 settings\n' +
					'have 3D turned OFF.\n' +
					'Ensure that you are\n' +
					'using a shader 2.0\n' +
					'compatible 3d card.';
			}
			
			gpuTf.text = 'Flash Version: ' + Capabilities.version + 
				' - Game ' + VERSION_STRING + 
				' - 3D mode: ' + context3D.driverInfo;
			
			// set the size of the 3d view to fill the stage
			//context3D.width = stage.width;
			//context3D.height = stage.height;
			
			//是否检测异常
			context3D.enableErrorChecking = false;
			
			//配置后台缓冲区
			context3D.configureBackBuffer(stage.width, stage.height, 2, true);
			
			//编译着色器
			initShaders();
			
			//初始化贴图
			playerTexture = initTexture(playerTextureData);
			terrainTexture = initTexture(terrainTextureData);
			cratersTexture = initTexture(cratersTextureData);
			puffTexture = initTexture(puffTextureData);
			skyTexture = initTexture(skyTextureData);
			particle1texture = initTexture(particle1bitmap);
			particle2texture = initTexture(particle2bitmap);
			particle3texture = initTexture(particle3bitmap);
			particle4texture = initTexture(particle4bitmap);
			badguytexture = initTexture(badguyTextureBitmap);
			techtexture = initTexture(techTextureBitmap);
			
			//初始化网格数据
			initData();
			
			//重置透视矩阵
			projectionmatrix.identity();
			//设定透视矩阵
			projectionmatrix.perspectiveFieldOfViewRH(45, stage.width / stage.height, 0.01, 150000);
			
			//主循环
			addEventListener(Event.ENTER_FRAME, enterFrame);
		}
		
		private function initGUI():void
		{
			// titlescreen
			addChild(titleScreen);
			
			var myFont:Font = new GUI_FONT();
			
			// add a title screen "game over" notice
			var gameoverFormat:TextFormat = new TextFormat();  
			gameoverFormat.color = 0x000000;
			gameoverFormat.size = 24;
			gameoverFormat.font = myFont.fontName;
			gameoverFormat.align = TextFormatAlign.CENTER;
			titlescreenTf = new TextField();
			titlescreenTf.embedFonts = true;
			titlescreenTf.x = 0;
			titlescreenTf.y = 180;
			titlescreenTf.width = 640;
			titlescreenTf.height = 300;
			titlescreenTf.autoSize = TextFieldAutoSize.NONE;
			titlescreenTf.selectable = false;
			titlescreenTf.defaultTextFormat = gameoverFormat;
			titlescreenTf.filters = [new GlowFilter(0xFF0000, 1, 2, 2, 2, 2), new GlowFilter(0xFFFFFF, 1, 16, 16, 2, 2)];
			titlescreenTf.text = "CLICK TO PLAY\n\n"
				+ "Your objective:\n"
				+ "reach the wormhole!";
			addChild(titlescreenTf);
			
			// heads-up-display overlay
			addChild(hudOverlay);
			
			// a text format descriptor used by all gui labels
			var myFormat:TextFormat = new TextFormat();  
			myFormat.color = 0xFFFFAA;
			myFormat.size = 16;
			myFormat.font = myFont.fontName;
			
			// create an FPSCounter that displays the framerate on screen
			fpsTf = new TextField();
			fpsTf.embedFonts = true;
			fpsTf.x = 0;
			fpsTf.y = 0;
			fpsTf.selectable = false;
			fpsTf.autoSize = TextFieldAutoSize.LEFT;
			fpsTf.defaultTextFormat = myFormat;
			fpsTf.filters = [new GlowFilter(0x000000, 1, 2, 2, 2, 2)];
			fpsTf.text = "Initializing Stage3d...";
			addChild(fpsTf);
			
			// create a score display
			scoreTf = new TextField();
			scoreTf.embedFonts = true;
			scoreTf.x = 540;
			scoreTf.y = 0;
			scoreTf.selectable = false;
			scoreTf.autoSize = TextFieldAutoSize.LEFT;
			scoreTf.defaultTextFormat = myFormat;
			scoreTf.filters = [new GlowFilter(0xFF0000, 1, 2, 2, 2, 2)];
			scoreTf.text = VERSION_STRING;
			addChild(scoreTf);
			
			// debug info: list the video card details
			var gpuFormat:TextFormat = new TextFormat();  
			gpuFormat.color = 0xFFFFFF;
			gpuFormat.size = 10;
			gpuFormat.font = myFont.fontName;
			gpuFormat.align = TextFormatAlign.CENTER;
			gpuTf = new TextField();
			gpuTf.embedFonts = true;
			gpuTf.x = 0;
			gpuTf.y = stage.height - 16;
			gpuTf.selectable = false;
			gpuTf.width = stage.width-4;
			gpuTf.autoSize = TextFieldAutoSize.NONE;
			gpuTf.defaultTextFormat = gpuFormat;
			gpuTf.text = "Flash Version: " + Capabilities.version + " - Game " + VERSION_STRING;
			addChild(gpuTf);
			
			// add a health meter
			healthTf = new TextField();
			healthTf.embedFonts = true;
			healthTf.x = 232;
			healthTf.y = 3;
			healthTf.selectable = false;
			healthTf.autoSize = TextFieldAutoSize.LEFT;
			healthTf.defaultTextFormat = myFormat;
			healthTf.filters = [new GlowFilter(0xFFFFFF, 1, 4, 4, 4, 2)];
			healthTf.text = healthText_3;
			addChild(healthTf);
		}
		
		private function initTexture(bmp:Bitmap):Texture
		{
			var tex:Texture;
			tex = context3D.createTexture(bmp.width, bmp.height, Context3DTextureFormat.BGRA, false);
			Utils.uploadTextureWithMipmaps(tex, bmp.bitmapData);
			return tex;
		}
		
		private function initShaders():void
		{
			trace("initShaders...");
			//简单的 3D 顶点变换着色器
			var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexShaderAssembler.assemble
			( 
				Context3DProgramType.VERTEX,
				// 4x4 matrix multiply to get camera angle
				"m44 op, va0, vc0\n" +
				// tell fragment shader about XYZ
				"mov v0, va0\n" +
				// tell fragment shader about UV
				"mov v1, va1\n" +
				// tell fragment shader about RGBA
				"mov v2, va2\n" +
				// v2 tell fragment shader about normals
				"mov v3, va3"
			);
			
			// textured using UV coordinates
			var fragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler.assemble
			( 
				Context3DProgramType.FRAGMENT,
				// grab the texture color from texture 0 
				// and uv coordinates from varying register 1
				// and store the interpolated value in ft0
				"tex ft0, v1, fs0 <2d,linear,repeat,miplinear>\n"+
				// move this value to the output color
				"mov oc, ft0\n"
			);
			
			// combine shaders into a program which we then upload to the GPU
			shaderProgram1 = context3D.createProgram();
			shaderProgram1.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);
			
			trace("Shader 1 uploaded.");
			
			//带有动态光照的着色器
			trace("Compiling lit vertex program...");
			var litVertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			litVertexShaderAssembler.assemble
			( 
				Context3DProgramType.VERTEX,
				// 4x4 matrix multiply to get camera angle
				"m44 vt0, va0, vc0\n" +
				// output position
				"mov op, vt0 \n"+ 
				// tell fragment shader about XYZ
				"mov v0, va0\n" +
				// tell fragment shader about UV
				"mov v1, va1\n" +
				// tell fragment shader about RGBA
				"mov v2, va2\n" +
				// tell fragment shader about normals
				// without regard to camera angle:
				// for simplistic lighting
				"mov v3, va3"
			);
			
			// textured using UV coordinates and LIT with a static light
			trace("Compiling lit fragment program...");
			var litFragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			litFragmentShaderAssembler.assemble
			(
				Context3DProgramType.FRAGMENT,
				// grab the texture color from texture 0 
				// and uv coordinates from varying register 1
				// and store the interpolated value in ft0
				"tex ft0, v1, fs0 <2d,linear,repeat,miplinear>\n"+
				// calculate dotproduct of vert normal and light normal
				// fc15 = light normal
				"dp3 ft1 fc15 v3\n" +
				// add the ambient light (fc16)
				"add ft1 ft1 fc16\n" +
				// multiply texture color by light value
				"mul ft0 ft0 ft1\n" +
				// move this value to the output color
				"mov oc, ft0\n"
			);
			trace("Uploading lit shader...");
			shaderWithLight = context3D.createProgram();
			shaderWithLight.upload(litVertexShaderAssembler.agalcode, litFragmentShaderAssembler.agalcode);
			
			trace("Setting lit shader constants...");
			
			// for simplicity, the light position never changes
			// so we can set it here once rather than every frame
			var lightDirection:Vector3D = new Vector3D(1.5, 1, -2, 0);
			lightDirection.normalize();
			var lightvector:Vector.<Number> = new Vector.<Number>();
			lightvector[0] = lightDirection.x;
			lightvector[1] = lightDirection.y;
			lightvector[2] = lightDirection.z;
			lightvector[3] = lightDirection.w;
			trace("Light normal will be: " + lightvector);
			// fc15 = [light normal]
			context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 15, lightvector);
			// fc16 = ambient light
			var lightambient:Vector.<Number> = new Vector.<Number>();
			lightambient[0] = 0.2;
			lightambient[1] = 0.2;
			lightambient[2] = 0.2;
			lightambient[3] = 0.2;
			context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 16, lightambient);
		}
		
		private function initPlayerModel():void 
		{
			// create the player model
			trace("Creating the player entity...");
			player = new GameActor(myObjData5, context3D, shaderWithLight, playerTexture);
			// allow lighting
			player.shaderUsesNormals = true;
			// start far back
			player.z = 0;
			player.particles = particleSystem;
			// collision detection
			player.collides = true;
			player.radius = 1;
			player.name = "player1";
			player.classname = "player";
			player.health = 3;
			
			trace("Parsing the engine glow...");
			engineGlow = new Entity(puffObjData, context3D, shaderProgram1, puffTexture);
			// follow the player's ship
			engineGlow.follow(player);
			// draw as a transparent particle
			engineGlow.blendSrc = Context3DBlendFactor.ONE;
			engineGlow.blendDst = Context3DBlendFactor.ONE;
			engineGlow.depthTest = true;
			engineGlow.depthTestMode = Context3DCompareMode.ALWAYS;
			engineGlow.cullingMode = Context3DTriangleFace.NONE;
			engineGlow.y = -0.6;
			engineGlow.scaleXYZ = 0.00001;
			props.push(engineGlow);	// a prop, not a particle
		}
		
		private function initData():void 
		{
			// create object pools
			particleSystem = new ParticleSystem();
			enemies = new GameActorPool();
			playerBullets = new GameActorPool();
			enemyBullets = new GameActorPool();
			// create the camera entity
			chaseCamera = new Entity();
			// the player spaceship and engine glow
			initPlayerModel();
			// non interactive terrain, asteroid field, sky 
			initTerrain();
			// evil spaceships, sentry guns, fuel tanks
			initEnemies();
			// good and evil bullets
			initBullets();
			// various shootable asteroids
			initAsteroids();
			// space stations and slabs of "tech"
			initSpaceStations();
			// explosions, sparks, debris
			initParticleModels();
		}
		
		private function initTerrain():void 
		{
			trace("Parsing the sky...");
			sky = new Entity(skyObjData, context3D, shaderProgram1, skyTexture);
			sky.depthTest = false;
			sky.depthTestMode = Context3DCompareMode.LESS;
			sky.cullingMode = Context3DTriangleFace.NONE;
			sky.depthDraw = false;
			sky.z = -10000;
			sky.scaleX = 20;
			sky.scaleY = 10;
			sky.scaleZ = 20;
			sky.rotationDegreesY = -90;
			sky.rotationDegreesX = -90;
			props.push(sky);
			
			// add some terrain to the props list
			trace("Parsing the terrain...");
			var terrain:Entity = new Entity(terrainObjData, context3D, shaderProgram1, terrainTexture, 0.5);
			terrain.rotationDegreesZ = 90;
			terrain.y = -50;
			props.push(terrain);
			
			// add an asteroid field to the props list
			trace("Parsing the asteroid field...");
			asteroids1 = new Entity(asteroidsObjData, context3D, shaderWithLight, cratersTexture);
			asteroids1.rotationDegreesZ = 90;
			asteroids1.scaleXYZ = 200;
			asteroids1.y = 500;
			asteroids1.z = -1100;
			props.push(asteroids1);
			trace("Cloning the asteroid field...");
			
			// use the same mesh in multiple locations
			asteroids2 = asteroids1.clone();
			asteroids2.z = -1500;
			props.push(asteroids2);	
			asteroids3 = asteroids1.clone();
			asteroids3.z = -1900;
			props.push(asteroids3);	
			asteroids4 = asteroids1.clone();
			asteroids4.z = -1900;
			asteroids4.y = -500;
			props.push(asteroids4);	
			
			trace("Parsing the asteroid tunnel...");
			actor = new GameActor(astroTunnelData, context3D, shaderWithLight, cratersTexture);
			actor.collides = false;
			actor.radius = 620;
			enemies.defineActor("astroTunnel", actor);
			
			actor = new GameActor(islandData, context3D, shaderWithLight, cratersTexture, 1, false);
			actor.shaderUsesNormals	= true;
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("island", actor);
			
			actor = new GameActor(wormholeData, context3D, shaderProgram1, particle1texture, 0.1);
			actor.collides = false;
			actor.radius = 128;
			actor.blendSrc = Context3DBlendFactor.ONE;
			actor.blendDst = Context3DBlendFactor.ONE;
			actor.cullingMode = Context3DTriangleFace.NONE;
			actor.depthTestMode = Context3DCompareMode.LESS;
			actor.depthDraw = false;
			actor.depthTest = false;
			actor.rotVelocity = new Vector3D(0, 0, -120); // spinning
			enemies.defineActor("wormhole", actor);
		}
		
		private function initEnemies():void 
		{
			// create enemies
			actor = new GameActor(myObjData5, context3D, shaderWithLight, badguytexture, 4);
			actor.collides = true;
			actor.radius = 2;
			actor.particles = particleSystem;
			actor.bullets = enemyBullets;
			actor.shootName = 'evilbolt';
			actor.shootDelay = 500;
			actor.shootRandomDelay = 1500;
			actor.shootDist = 250;
			actor.shootVelocity = 35;
			actor.shootAt = player;
			actor.posVelocity = new Vector3D(0, 0, 20); // fly towards us
			actor.rotVelocity = new Vector3D(0, 0, 40); // spinning
			enemies.defineActor("enemyCruiser", actor);
			
			// a big boss that flies backwards and shoots a lot
			actor = new GameActor(bossData, context3D, shaderWithLight, badguytexture, 32); // scaled up
			actor.collides = true;
			actor.radius = 16;
			actor.posVelocity = new Vector3D(0, 0.5, -20);
			actor.particles = particleSystem;
			actor.bullets = enemyBullets;
			actor.shootName = 'evilbolt';
			actor.shootDelay = 250;
			actor.shootRandomDelay = 250;
			actor.shootDist = 250;
			actor.shootVelocity = 30; // bullets move slowish
			actor.shootAt = player;
			actor.points = 1111; // reward for victory
			actor.health = 20; // #hits to destroy
			enemies.defineActor("enemyBoss", actor);
			
			// sentry guns
			actor = new GameActor(sentrygun01_data, context3D, shaderWithLight, badguytexture, 4);
			actor.collides = true;
			actor.radius = 2;
			actor.particles = particleSystem;
			actor.bullets = enemyBullets;
			actor.shootName = 'evilbolt';
			actor.shootDelay = 500;
			actor.shootRandomDelay = 1500;
			actor.shootDist = 250;
			actor.shootVelocity = 25;
			actor.shootAt = player;
			enemies.defineActor("sentrygun01", actor);
			
			actor = new GameActor(sentrygun02_data, context3D, shaderWithLight, badguytexture, 4);
			actor.collides = true;
			actor.radius = 2;
			actor.particles = particleSystem;
			actor.bullets = enemyBullets;
			actor.shootName = 'evilbolt';
			actor.shootDelay = 500;
			actor.shootRandomDelay = 1500;
			actor.shootDist = 250;
			actor.shootVelocity = 25;
			actor.shootAt = player;
			enemies.defineActor("sentrygun02", actor);
			
			actor = new GameActor(sentrygun03_data, context3D, shaderWithLight, badguytexture, 4);
			actor.collides = true;
			actor.radius = 2;
			actor.particles = particleSystem;
			actor.bullets = enemyBullets;
			actor.shootName = 'evilbolt';
			actor.shootDelay = 500;
			actor.shootRandomDelay = 1500;
			actor.shootDist = 250;
			actor.shootVelocity = 25;
			actor.shootAt = player;
			enemies.defineActor("sentrygun03", actor);
			
			actor = new GameActor(sentrygun04_data, context3D, shaderWithLight, badguytexture, 4);
			actor.collides = true;
			actor.radius = 2;
			actor.particles = particleSystem;
			actor.bullets = enemyBullets;
			actor.shootName = 'evilbolt';
			actor.shootDelay = 500;
			actor.shootRandomDelay = 1500;
			actor.shootDist = 250;
			actor.shootVelocity = 25;
			actor.shootAt = player;
			enemies.defineActor("sentrygun04", actor);
			
			// destroyable fuel tanks
			actor = new GameActor(fueltank01_data, context3D, shaderWithLight, badguytexture, 4);
			actor.collides = true;
			actor.radius = 2;
			enemies.defineActor("fueltank01", actor);
			
			actor = new GameActor(fueltank02_data, context3D, shaderWithLight, badguytexture, 4);
			actor.collides = true;
			actor.radius = 2;
			enemies.defineActor("fueltank02", actor);
		}
		
		private function initBullets():void 
		{
			actor = new GameActor(bulletData, context3D, shaderProgram1, particle1texture);
			actor.collides = true;
			actor.radius = 1;
			actor.ageMax = 5000;
			actor.particles = particleSystem;
			actor.spawnWhenNoHealth = "sparks";
			actor.spawnWhenMaxAge = "sparks";
			actor.spawnWhenCreated = "sparks";
			actor.blendSrc = Context3DBlendFactor.ONE;
			actor.blendDst = Context3DBlendFactor.ONE;
			actor.cullingMode = Context3DTriangleFace.NONE;
			actor.depthTestMode = Context3DCompareMode.LESS;
			actor.depthDraw = false;
			actor.depthTest = false;
			actor.posVelocity = new Vector3D(0, 0, -100);
			actor.runWhenMaxAge = resetCombo;
			actor.shaderUsesNormals = false;
			playerBullets.defineActor("bolt", actor);
			
			actor = new GameActor(bulletData, context3D, shaderProgram1, particle2texture);
			actor.collides = true;
			actor.radius = 1;
			actor.ageMax = 5000;
			actor.particles = particleSystem;
			actor.spawnWhenNoHealth = "sparks";
			actor.spawnWhenMaxAge = "sparks";
			actor.spawnWhenCreated = "sparks";
			actor.blendSrc = Context3DBlendFactor.ONE;
			actor.blendDst = Context3DBlendFactor.ONE;
			actor.cullingMode = Context3DTriangleFace.NONE;
			actor.depthTestMode = Context3DCompareMode.LESS;
			actor.depthDraw = false;
			actor.depthTest = false;
			actor.posVelocity = new Vector3D(0, 0, 25);
			actor.shaderUsesNormals = false;
			enemyBullets.defineActor("evilbolt", actor);
		}
		
		private function initAsteroids():void 
		{
			 // need to hit them 3 times to destroy
			 actor = new GameActor(asteroid_00_data, context3D, shaderWithLight, cratersTexture, 0.5);
			actor.collides = true;
			actor.radius = 6;
			actor.health = 3;
			actor.spawnWhenNoHealth = 'debris01,debris02,debris03';
			actor.particles = particleSystem;
			enemies.defineActor("asteroid_00", actor);
			
			actor = new GameActor(asteroid_01_data, context3D, shaderWithLight, cratersTexture, 0.5);
			actor.collides = true;
			actor.radius = 6;
			actor.health = 3;
			actor.spawnWhenNoHealth = 'debris01,debris02,debris03';
			actor.particles = particleSystem;
			enemies.defineActor("asteroid_01", actor);
			
			actor = new GameActor(asteroid_02_data, context3D, shaderWithLight, cratersTexture, 0.5);
			actor.collides = true;
			actor.radius = 6;
			actor.health = 3;
			actor.spawnWhenNoHealth = 'debris01,debris02,debris03';
			actor.particles = particleSystem;
			enemies.defineActor("asteroid_02", actor);
		}
		
		private function initSpaceStations():void 
		{
			actor = new GameActor(slab01_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("slab01", actor);
			actor = new GameActor(slab02_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("slab02", actor);
			actor = new GameActor(slab03_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("slab03", actor);
			actor = new GameActor(slab04_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("slab04", actor);
			actor = new GameActor(station01_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("station01", actor);
			actor = new GameActor(station02_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("station02", actor);
			actor = new GameActor(station03_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("station03", actor);
			actor = new GameActor(station04_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("station04", actor);
			actor = new GameActor(station05_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("station05", actor);
			actor = new GameActor(station06_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("station06", actor);
			actor = new GameActor(station07_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("station07", actor);
			actor = new GameActor(station08_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("station08", actor);
			actor = new GameActor(station09_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("station09", actor);
			actor = new GameActor(station10_data, context3D, shaderWithLight, techtexture, 1, false);
			actor.collides = false;
			actor.radius = 64;
			enemies.defineActor("station10", actor);
		}
		
		private function initParticleModels():void 
		{
			trace("Creating particle system models...");
			// define the types of particles
			particleSystem.defineParticle("explosion", new Particle(explosion1_data, context3D, puffTexture, explosionfat_data));
			particleSystem.defineParticle("bluebolt", new Particle(explosion1_data, context3D, particle1texture, explosion2_data));
			particleSystem.defineParticle("greenpuff", new Particle(explosion1_data, context3D, particle2texture, explosion2_data));
			particleSystem.defineParticle("ringfire", new Particle(explosion1_data, context3D, particle3texture, explosion2_data));
			particleSystem.defineParticle("sparks", new Particle(explosion1_data, context3D, particle4texture, explosion2_data));
			// debris from destroyed asteroids
			var party:Particle;
			party = new Particle(asteroid_00_data, context3D, cratersTexture);
			party.blendSrc = Context3DBlendFactor.ONE;
			party.blendDst = Context3DBlendFactor.ZERO;
			party.cullingMode = Context3DTriangleFace.FRONT;
			party.depthTestMode = Context3DCompareMode.LESS;
			party.depthTest = true;
			party.depthDraw = true;
			particleSystem.defineParticle("debris01", party);
			party = new Particle(asteroid_01_data, context3D, cratersTexture);
			party.blendSrc = Context3DBlendFactor.ONE;
			party.blendDst = Context3DBlendFactor.ZERO;
			party.cullingMode = Context3DTriangleFace.FRONT;
			party.depthTestMode = Context3DCompareMode.LESS;
			party.depthTest = true;
			party.depthDraw = true;
			particleSystem.defineParticle("debris02", party);
			party = new Particle(asteroid_02_data, context3D, cratersTexture);
			party.blendSrc = Context3DBlendFactor.ONE;
			party.blendDst = Context3DBlendFactor.ZERO;
			party.cullingMode = Context3DTriangleFace.FRONT;
			party.depthTestMode = Context3DCompareMode.LESS;
			party.depthTest = true;
			party.depthDraw = true;
			particleSystem.defineParticle("debris03", party);
		}
		
		//创建关卡
		private function spawnTheLevel():void
		{
			// create a level using
			// our map images as the blueprint
			trace("Spawning the game level parser...");
			var level:GameLevelParser = new GameLevelParser();
			
			// how far ahead of the player is the first actor
			var levelStartDistance:Number = 350;
			
			// list of entities that we want spawned in a spiral map
			var enemyNames:Array = ["enemyCruiser", "asteroid_00", "asteroid_01", "asteroid_02"];
			
			// spiral enemy formation - works great
			level.spawnActors(
				levelKey.bitmapData,
				levelData.bitmapData,
				enemyNames,
				enemies,
				0, 16, 
				player.z - levelData.height * 16 - levelStartDistance, 
				4, 16, 0, 8);
			
			// list of entities that we want spawned in a flat map
			var rockNames:Array = 
				[null,null,null,null, // skip the types used above
				"sentrygun01","sentrygun02","sentrygun03","sentrygun04",
				"fueltank01","fueltank02","enemyBoss","island",
				"slab01","slab02","slab03","slab04",
				"station01","station02","station03","station04",
				"station05","station06","station07","station08",
				"station09", "station10", "wormhole", "astroTunnel"];
			
			// flat enemy formation
			var gameLevelLength:Number;
			gameLevelLength = level.spawnActors(
				levelKey.bitmapData,
				levelData.bitmapData,
				rockNames,
				enemies,
				-8, 0, 
				player.z - levelData.height * 8 - levelStartDistance, 
				2, 8, 0, 0);
			
			// now that we know how long the map is
			// remember what z coord is the "finish line"
			playerMinz = player.z - gameLevelLength - levelStartDistance;
		}
		
		private function renderScene():void 
		{
			scenePolycount = 0;
			
			viewmatrix.identity();
			// look at the player
			viewmatrix.append(chaseCamera.transform);
			viewmatrix.invert();
			// tilt down a little
			viewmatrix.appendRotation(15, Vector3D.X_AXIS);
			// if mouselook is on:
			viewmatrix.appendRotation(gameinput.cameraAngleX, Vector3D.X_AXIS);
			viewmatrix.appendRotation(gameinput.cameraAngleY, Vector3D.Y_AXIS);
			viewmatrix.appendRotation(gameinput.cameraAngleZ, Vector3D.Z_AXIS);
			//玩家被击中时抖动屏幕
			viewmatrix.appendRotation(screenShakeCameraAngle, Vector3D.X_AXIS);
			
			// render the player mesh from the current camera angle
			player.render(viewmatrix, projectionmatrix);
			scenePolycount += player.polycount;
			
			// loop through all known entities and render them
			for each (entity in props)
			{
				entity.render(viewmatrix, projectionmatrix);
				scenePolycount += entity.polycount;
			}
			
			// hide enemies that are far away OR behind us
			// these distances are scaled by the entity's radius
			// so that big meshes are visible from
			// farther away to prevent "pop-in"
			enemies.hideDistant(player.position, 150, 2);
			playerBullets.hideDistant(player.position, 150, 2);
			enemyBullets.hideDistant(player.position, 150, 2);
			
			enemies.render(viewmatrix, projectionmatrix);
			scenePolycount += enemies.totalpolycount;
			
			playerBullets.render(viewmatrix, projectionmatrix);
			scenePolycount += playerBullets.totalpolycount;
			
			enemyBullets.render(viewmatrix, projectionmatrix);
			scenePolycount += enemyBullets.totalpolycount;
			
			particleSystem.render(viewmatrix, projectionmatrix);
			scenePolycount += particleSystem.totalpolycount;
			
			//震动屏幕
			if (screenShakes > 0)
			{
				screenShakes--;
				if (screenShakes > 0)
				{
					if (screenShakes % 2) // alternate
					{
						this.y += screenShakes / 2;
					}
					else
					{
						this.y -= screenShakes / 2;
					}
					screenShakeCameraAngle = this.y / 2;
				}
				else
				{
					// we are done shaking: reset
					this.x = 0;
					this.y = 0;
					screenShakeCameraAngle = 0;
				}
			}
		}
		
		private function gamestart():void
		{
			if (gameState == STATE_TITLESCREEN)
			{
				
				trace('GAME START!');
				
				// stop any previously playing music
				if (musicChannel)
					musicChannel.stop();
				// start the background music
				musicChannel = introSound.play(); 
				
				// clear the title screen
				if (contains(titleScreen))
					removeChild(titleScreen);
				if (contains(titlescreenTf))
					removeChild(titlescreenTf);
				
				// the intro "cinematic"
				addChild(introOverlay); 
				// it will be removed in about 7s
				introOverlayEndTime = 7000;
				
				// reset game state and player
				gameState = STATE_PLAYING;
				score = 0;
				combo = 0;
				comboBest = 0;
				player.health = 3;
				healthTf.text = healthText_3;
				player.x = 0;
				player.y = 8; // slightly above the "ground"
				player.z = 0;
				player.active = true;
				player.visible = true;
				player.collides = true;
				nextShootTime = 0;
				invulnerabilityTimeLeft = 0;
				player.spawnConstantly = '';
				player.spawnConstantlyDelay = 0;
				player.updateTransformFromValues();
				// reset any mouse look camera angles
				gameinput.cameraAngleX = 0;
				gameinput.cameraAngleY = 0;
				
				// reset all the enemy positions
				// from the possible previous game
				enemies.destroyAll();
				enemyBullets.destroyAll();
				playerBullets.destroyAll();
			
				// create all enemies, etc.
				spawnTheLevel();
				
				// reset the game timer
				gametimer.gameElapsedTime = 0;
				gametimer.gameStartTime = 
				gametimer.lastFrameTime = 
				gametimer.currentFrameTime = getTimer();
				
				// now is a good time to release temporary
				// variables from memory
				System.gc();
			}
		}
		
		private function gameover(beatTheGame:Boolean = false):void
		{
			if (gameState != STATE_TITLESCREEN)
			{
				trace('GAME OVER!');
				gameState = STATE_TITLESCREEN;
				if (contains(introOverlay))
					removeChild(introOverlay);
				addChild(titleScreen);
				if (beatTheGame)
				{
					titlescreenTf.text = "VICTORY!\n"
					+ "You reached the wormhole\nin " + Math.round(
						gametimer.gameElapsedTime / 1000) + " seconds\n"
					+ "Your score: " + score + "\n"
					+ "Highest combo: " + comboBest + "x\n";
				}
				else // player was destroyed
				{
					titlescreenTf.text = "GAME OVER\n"
					+ "You were destroyed\nafter " + Math.round(
						gametimer.gameElapsedTime / 1000) + " seconds\n"
					+ "Your score: " + score + "\n"
					+ "Highest combo: " + comboBest + "x\n";
				}
				
				// turn off the engines
				engineGlow.scaleXYZ = 0.00001;
				
				// make the gameover text visible
				addChild(titlescreenTf);
			}
			
			// release some temporary variables from memory
			System.gc();
		}
		
		private var combocomment:String = '';
		
		private function updateScore():void
		{
			if (combo < 10) combocomment = combo + "x combo";
			else if (combo < 20) combocomment = 
				combo + "x combo\nNot bad!";
			else if (combo < 30) combocomment = 
				combo + "x combo\nGreat!";
			else if (combo < 40) combocomment = 
				combo + "x combo\nSkilled!";
			else if (combo < 50) combocomment = 
				combo + "x combo\nIncredible!";
			else if (combo < 60) combocomment = 
				combo + "x combo\nAmazing!";
			else if (combo < 70) combocomment = 
				combo + "x combo\nUnbelievable!";
			else if (combo < 80) combocomment = 
				combo + "x combo\nInsane!";
			else if (combo < 90) combocomment = 
				combo + "x combo\nFantastic!";
			else if (combo < 100) combocomment = 
				combo + "x combo\nHeroic!";
			else combocomment = combo + "x combo\nLegendary!";
			if (combo > comboBest)
				comboBest = combo;
			
			// padded with zeroes
			if (score < 10) scoreTf.text = 
				'Score: 00000' + score + "\n" + combocomment;
			else if (score < 100) scoreTf.text = 
				'Score: 0000' + score + "\n" + combocomment;
			else if (score < 1000) scoreTf.text = 
				'Score: 000' + score + "\n" + combocomment;
			else if (score < 10000) scoreTf.text = 
				'Score: 00' + score + "\n" + combocomment;
			else if (score < 100000) scoreTf.text = 
				'Score: 0' + score + "\n" + combocomment;
			else scoreTf.text = 'Score: ' + score + "\n" + combocomment;
		}
		
		private function updateFPS():void
		{
			// update the FPS display
			fpsTicks++;
			var now:uint = getTimer();
			var delta:uint = now - fpsLast;
			// only update the display once a second
			if (delta >= 1000) 
			{
				// also track ram usage
				var mem:Number = Number((System.totalMemory * 0.000000954).toFixed(1));
				var fps:Number = fpsTicks / delta * 1000;
				fpsTf.text = fps.toFixed(1) + 
					" fps"
					+ " (" + scenePolycount + " polies)\n" 
					+ "Memory used: " + mem + " MB";
					//+ enemies.totalrendered + " enemies\n" 
					//+ (enemyBullets.totalrendered 
					//+ playerBullets.totalrendered) + " bullets\n" 
					//+ "[step=" + (profilingEnd - profilingStart) + "ms]"
					;
				fpsTicks = 0;
				fpsLast = now;
			}
		}
		
		private function resetCombo():void
		{
			trace("Player bullet missed: resetting combo.");
			combo = 0;
		}
		
		private function hitAnEnemy(culprit:GameActor, victim:GameActor):void 
		{
			trace(culprit.name 
				+ " at " + culprit.posString()
				+ " hitAnEnemy " + victim.name 
				+ " at " + victim.posString());
			blastSound.play();
			victim.health--;
			if (victim.health <= 0)
			{
				particleSystem.spawn("explosion", victim.transform);
				score += victim.points;
				// ensure that die(), sounds, particles are triggered:
				victim.step(0); 
			}
			particleSystem.spawn("sparks", culprit.transform);
			culprit.die();
			combo++;
		}
		
		private function playerGotHit(culprit:GameActor, victim:GameActor):void 
		{
			trace("Player got hit!");
			screenShakes = 30;
			particleSystem.spawn("explosion", victim.transform);
			particleSystem.spawn("sparks", culprit.transform);
			culprit.die();
			explodeSound.play();
			player.health--;
			trace("Player health = " + player.health);
			invulnerabilityTimeLeft = invulnerabilityMsWhenHit;
			if (player.health == 3)
			{
				healthTf.text = healthText_3;
			}
			if (player.health == 2)
			{
				healthTf.text = healthText_2;
			}
			if (player.health == 1)
			{
				trace("Player is almost dead!");
				player.spawnConstantly = 'explosion';
				player.spawnConstantlyDelay = 100;
				player.spawnConstantlyNext = 0;
				healthTf.text = healthText_1;
			}
			if (player.health <= 0)
			{
				trace("Player's health is zero!");
				healthTf.text = healthText_0;
				gameover();
			}
		}
		
		private function handlePlayerInput(frameMs:uint):void 
		{
			// handle player input
			var moveAmount:Number = moveSpeed * frameMs;
			
			// in our game we are always flying forward
			// while moving up/down/left/right to dodge
			
			// EXAMPLE: a simple way to slide around - it works,
			// but assumes you are always facing down the z axis
			// if (gameinput.pressing.up) player.y += moveAmount;
			// if (gameinput.pressing.down) player.y -= moveAmount;
			// if (gameinput.pressing.left) player.x -= moveAmount;
			// if (gameinput.pressing.right) player.x += moveAmount;
			
			// this method does the same thing but would also 
			// work if we were facing other directions
			// because the motion is relative to our angles
			if (gameinput.pressing.up) 
				player.moveUp(moveAmount);
			if (gameinput.pressing.down) 
				player.moveDown(moveAmount);
			if (gameinput.pressing.left) 
				player.moveLeft(moveAmount);
			if (gameinput.pressing.right) 
				player.moveRight(moveAmount);
			
			// EXAMPLE: turning the ship via euler angles
			// will break due to gimbal lock at 180..-180
			// do not rotate things using this technique:
			// if (gameinput.pressing.left) 
			// 	player.rotationDegreesY += moveAmount*4;
			// if (gameinput.pressing.right) 
			// 	player.rotationDegreesY -= moveAmount*4;
			// if (gameinput.pressing.up) 
			// 	player.rotationDegreesX -= moveAmount*4;
			// if (gameinput.pressing.down) 
			// 	player.rotationDegreesX += moveAmount*4;
			
			// EXAMPLE: FPS style 6DOF rotation
			// avoids gimbal lock by using quaternion rotation
			// which is a way of rotating using a single axis
			// if (gameinput.pressing.left) 
			// 	player.transform.prependRotation(moveAmount * 4, 
			// 	Vector3D.Y_AXIS);
			// if (gameinput.pressing.right) 
			// 	player.transform.prependRotation(-moveAmount * 4, 
			// 	Vector3D.Y_AXIS);
			// if (gameinput.pressing.up) 
			// 	player.transform.prependRotation(-moveAmount * 4, 
			// 	Vector3D.X_AXIS);
			// if (gameinput.pressing.down) 
			// 	player.transform.prependRotation(moveAmount * 4, 
			// 	Vector3D.X_AXIS);
			
			// EXAMPLE: slide forward and backward
			// and "strafe" sliding side to side
			// good for walking such as in an FPS game
			// if (gameinput.pressing.up) 
			// 	player.moveForward(moveAmount);
			// if (gameinput.pressing.down) 
			// 	player.moveBackward(moveAmount);
			// if (gameinput.pressing.strafeLeft) 
			// 	player.moveLeft(moveAmount);
			// if (gameinput.pressing.strafeRight) 
			// 	player.moveRight(moveAmount);
			
			// keep moving forward: in our flying game
			// we constantly move and use arrow keys to dodge
			player.moveForward(flySpeed);
			
			if (gameinput.pressing.fire)
			{
				if (gametimer.gameElapsedTime >= nextShootTime)
				{
					//trace("Fire!");
					nextShootTime = gametimer.gameElapsedTime + shootDelay;
						
					// shoot a bullet
					actor = playerBullets.spawn("bolt", player.transform);
					actor.updateValuesFromTransform();
					actor.rotationDegreesY = 90;
					// we don't want to be able to shoot ourselves
					actor.owner = player;
					gunSound.play();
				}
			}
			
			// force the player to stay within bounds
			if ((playerMaxx != 0) && (player.x > playerMaxx))
				player.x = playerMaxx;
			if ((playerMaxy != 0) && (player.y > playerMaxy))
				player.y = playerMaxy;
			if ((playerMaxz != 0) && (player.z > playerMaxz))
				player.z = playerMaxz;
			if ((playerMinx != 0) && (player.x < playerMinx))
				player.x = playerMinx;
			if ((playerMiny != 0) && (player.y < playerMiny))
				player.y = playerMiny;
			if ((playerMinz != 0) && (player.z < playerMinz))
			{
				player.z = playerMinz;
				if (levelCompletePlayerMinz)
				{
					// we got to the "finish line"
					trace('LEVEL COMPLETE!');
					gameover(true)
				}
			}
		}
		
		private var profilingStart:uint = 0;
		private var profilingEnd:uint = 0;
		
		private function gameStep(frameMs:uint):void 
		{
			// time how long this function takes
			profilingStart = getTimer();
			
			// if we are at the title screen, don't move the player
			if (gameState == STATE_PLAYING)
			{
				handlePlayerInput(frameMs);
				// intro "cinematic" pans the camera for a few sec
				if (gametimer.gameElapsedTime < introOverlayEndTime)
				{
					screenShakeCameraAngle = 45 * (1 - 
					(gametimer.gameElapsedTime / introOverlayEndTime));
				}
			}
			
			// follow behind the player
			// no matter what direction it is facing
			chaseCamera.x = player.x;
			chaseCamera.y = player.y;
			chaseCamera.z = player.z;
			chaseCamera.rotationDegreesY = player.rotationDegreesY;
			chaseCamera.rotationDegreesX = chaseCameraXangle;
			chaseCamera.moveBackward(chaseCameraDistance);
			chaseCamera.moveUp(chaseCameraHeight);
			
			// during the title screen, add some camera wobble
			if (gameState != STATE_PLAYING)
			{
				var wobbleSize:Number = 8;
				var wobbleMs:Number = 1000;
				chaseCamera.moveUp(
					Math.cos(gametimer.gameElapsedTime / wobbleMs) 
					/ Math.PI * wobbleSize);
				chaseCamera.moveLeft(
					Math.sin(gametimer.gameElapsedTime / wobbleMs) 
					/ Math.PI * wobbleSize);
				chaseCamera.moveForward(
					Math.sin(-1 * gametimer.gameElapsedTime / wobbleMs) 
					/ (Math.PI * wobbleSize * 5) - (wobbleSize / 2));
				
				// force some swivelling as well	
				gameinput.cameraAngleX = 
					Math.sin(gametimer.gameElapsedTime / wobbleMs) 
					/ Math.PI * 60;
				gameinput.cameraAngleY = 
					Math.sin(gametimer.gameElapsedTime / wobbleMs / 3) 
					/ Math.PI * 90;
			}
			
			// animate the asteroids in the background
			asteroids1.rotationDegreesX += asteroidRotationSpeed * frameMs;
			asteroids2.rotationDegreesX -= asteroidRotationSpeed * frameMs;
			asteroids3.rotationDegreesX += asteroidRotationSpeed * frameMs;
			asteroids4.rotationDegreesX -= asteroidRotationSpeed * frameMs;
			
			// advance all particles based on time
			particleSystem.step(frameMs);
			
			// don't process any more if we are at the title screen
			if (gameState != STATE_PLAYING) return;
			
			// animate the engine glow - spin fast and pulsate slowly
			engineGlow.rotationDegreesZ += 10 * frameMs;
			engineGlow.scaleXYZ = Math.cos(gametimer.gameElapsedTime / 66) / 20 + 0.75;
			
			playerBullets.step(frameMs, enemies.colliding, hitAnEnemy);
			
			// when the player gets damaged, they become
			// invulnerable for a short perod of time
			if (invulnerabilityTimeLeft > 0)
			{
				invulnerabilityTimeLeft -= frameMs;
				if (invulnerabilityTimeLeft <= 0)
				{
					trace("Invulnerability wore off.");
				}
			}
			
			// check for collisions with the player
			// between enemy ships and player ship
			// unless we are invulnerable
			if (invulnerabilityTimeLeft <= 0)
			{
				// step enemy bullets and check for collisions
				enemyBullets.step(frameMs, player.colliding, playerGotHit);
				
				// step enemies and check to see if we collided with one
				enemies.step(frameMs, player.colliding, playerGotHit);
			}
			else
			{
				// player is invulnerable:
				// step bullets but don't check collisions
				enemyBullets.step(frameMs);
				// setp enemies but don't check collisions
				enemies.step(frameMs);
			}
			
			// allow the player to update things like particles
			player.step(frameMs);
			
			// time how long this function takes
			profilingEnd = getTimer();
		}
		
		// for efficiency, this function only runs occasionally
		// ideal for calculations that don't need to be run every frame
		// such as pathfinding, complex AI, streaming downloads, etc.
		private function heartbeat():void
		{
			trace('heartbeat at ' + gametimer.gameElapsedTime + 'ms');
			trace('player pos ' + player.posString());
			trace('player rot ' + player.rotString());
			trace('camera ' + chaseCamera.posString());
			trace('particles active: ' + particleSystem.particlesActive);
			trace('particles total: ' + particleSystem.particlesCreated);
			trace('particles polies: ' + particleSystem.totalpolycount);
			if (gameState == STATE_PLAYING)
				trace('step: ' + (profilingEnd - profilingStart) + 'ms');
			
			// time to remove the intro "cinematic"?
			if (gametimer.gameElapsedTime > introOverlayEndTime)
			{
				if (contains(introOverlay))
					removeChild(introOverlay);
				screenShakeCameraAngle = 0;
			}
		}
		
		private function enterFrame(e:Event):void 
		{
			// clear scene before rendering is mandatory
			context3D.clear(0,0,0); 
			
			// count frames, measure elapsed time
			gametimer.tick();
			
			// update all entities positions, etc
			gameStep(gametimer.frameMs);
			
			// render everything
			renderScene();
			
			// present/flip back buffer
			// now that all meshes have been drawn
			context3D.present();
			
			// update the GUI
			if (gameState == STATE_PLAYING)
			{
				updateScore();
			}
			
			updateFPS();
		}
	}
}

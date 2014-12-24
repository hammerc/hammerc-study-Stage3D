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
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	
	import scorpio3D.input.GameInput;
	import scorpio3D.object3D.Entity;
	import scorpio3D.particle.Particle;
	import scorpio3D.particle.ParticleSystem;
	import scorpio3D.utils.GameTimer;
	import scorpio3D.utils.Utils;
	
	/**
	 * 粒子特效测试.
	 * @author wizardc
	 */
	public class ParticleTest extends Sprite
	{
		private var gametimer:GameTimer;
		private var gameinput:GameInput;
		
		//所有 3D 实体对象
		private var chaseCamera:Entity;
		private var player:Entity;
		private var props:Vector.<Entity>;
		private var enemies:Vector.<Entity>;
		private var bullets:Vector.<Entity>;
		private var particles:Vector.<Entity>;
		
		//重用的实体指针
		private var entity:Entity;
		private var asteroids1:Entity;
		private var asteroids2:Entity;
		private var asteroids3:Entity;
		private var asteroids4:Entity;
		private var engineGlow:Entity;
		private var sky:Entity;
		
		//每毫秒移动的距离
		private const moveSpeed:Number = 1.0;
		//每毫秒转动的角度
		private const asteroidRotationSpeed:Number = 0.001;
		
		//GUI
		private var fpsLast:uint = getTimer();
		private var fpsTicks:uint = 0;
		private var fpsTf:TextField;
		private var scoreTf:TextField;
		private var score:uint = 0;
		
		private var context3D:Context3D;
		private var shaderProgram1:Program3D;
		
		//透视矩阵
		private var projectionmatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
		//摄像机矩阵
		private var viewmatrix:Matrix3D = new Matrix3D();
		
		//粒子系统使用
		private var nextShootTime:uint = 0;
		private var shootDelay:uint = 0;
		private var explo:Particle;
		private var particleSystem:ParticleSystem;
		private var scenePolycount:uint = 0;
		
		[Embed (source = "../../assets/spaceship_texture.jpg")] 
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
		[Embed (source = "../../assets/hud_overlay.png")] 
		private var hudOverlayData:Class;
		private var hudOverlay:Bitmap = new hudOverlayData();
		
		private var playerTexture:Texture;
		private var terrainTexture:Texture;
		private var cratersTexture:Texture;
		private var skyTexture:Texture;
		private var puffTexture:Texture;
		
		//粒子贴图
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
		
		private var particle1texture:Texture;
		private var particle2texture:Texture;
		private var particle3texture:Texture;
		private var particle4texture:Texture;
		
		// the player
		[Embed (source = "../../assets/spaceship.obj", mimeType = "application/octet-stream")] 
		private var myObjData5:Class;
		
		// the engine glow
		[Embed (source = "../../assets/puff.obj", mimeType = "application/octet-stream")] 
		private var puffObjData:Class;
		
		// The terrain mesh data
		[Embed (source = "../../assets/terrain.obj", mimeType = "application/octet-stream")] 
		private var terrainObjData:Class;
		
		// an asteroid field
		[Embed (source = "../../assets/asteroids.obj", mimeType = "application/octet-stream")] 
		private var asteroidsObjData:Class;
		
		// the sky
		[Embed (source = "../../assets/sphere.obj", mimeType = "application/octet-stream")] 
		private var skyObjData:Class;
		
		// explosion start - 336 polygons
		[Embed (source = "../../assets/explosion1.obj", mimeType = "application/octet-stream")] 
		private var explosion1_data:Class;

		// explosion end - 336 polygons
		[Embed (source = "../../assets/explosion2.obj", mimeType = "application/octet-stream")] 
		private var explosion2_data:Class;
		
		public function ParticleTest() 
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
			
			gametimer = new GameTimer(heartbeat);
			gameinput = new GameInput(stage);
			
			props = new Vector.<Entity>();
			enemies = new Vector.<Entity>();
			bullets = new Vector.<Entity>();
			particles = new Vector.<Entity>();
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			initGUI();
			
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
			stage.stage3Ds[0].requestContext3D();
		}
		
		private function updateScore():void
		{
			score++;
			
			if (score < 10) scoreTf.text = 'Score: 00000' + score;
			else if (score < 100) scoreTf.text = 'Score: 0000' + score;
			else if (score < 1000) scoreTf.text = 'Score: 000' + score;
			else if (score < 10000) scoreTf.text = 'Score: 00' + score;
			else if (score < 100000) scoreTf.text = 'Score: 0' + score;
			else scoreTf.text = 'Score: ' + score;
		}
		
		private function initGUI():void
		{
			addChild(hudOverlay);
			
			var myFormat:TextFormat = new TextFormat();  
			myFormat.color = 0xFFFFAA;
			myFormat.size = 16;
			
			fpsTf = new TextField();
			fpsTf.x = 4;
			fpsTf.y = 0;
			fpsTf.selectable = false;
			fpsTf.autoSize = TextFieldAutoSize.LEFT;
			fpsTf.defaultTextFormat = myFormat;
			fpsTf.text = "Initializing Stage3d...";
			addChild(fpsTf);
			
			scoreTf = new TextField();
			scoreTf.x = 540;
			scoreTf.y = 0;
			scoreTf.selectable = false;
			scoreTf.autoSize = TextFieldAutoSize.LEFT;
			scoreTf.defaultTextFormat = myFormat;
			addChild(scoreTf);
		}
		
		private function initShaders():void
		{
			var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexShaderAssembler.assemble
			( 
				Context3DProgramType.VERTEX,
				//将顶点坐标乘与最终的 mvp 矩阵
				"m44 op, va0, vc0\n" +
				//传递 XYZ 到片段着色器
				"mov v0, va0\n" +
				//传递 UV 到片段着色器
				"mov v1, va1\n" +
				//传递 RGBA 到片段着色器
				"mov v2, va2"
			);
			
			var fragmentShaderAssembler1:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler1.assemble
			( 
				Context3DProgramType.FRAGMENT,
				//对 fs0 的纹理使用 v1 的数据进行取样, 结果存放到 ft0
				"tex ft0, v1, fs0 <2d,linear,repeat,miplinear>\n" +
				//输出取样的颜色
				"mov oc, ft0\n"
			);
			
			//提交着色器到 GPU
			shaderProgram1 = context3D.createProgram();
			shaderProgram1.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler1.agalcode);
		}
		
		private function onContext3DCreate(event:Event):void 
		{
			if (hasEventListener(Event.ENTER_FRAME))
				removeEventListener(Event.ENTER_FRAME,enterFrame);
			
			var t:Stage3D = event.target as Stage3D;
			context3D = t.context3D;
			
			if (context3D == null) 
			{
				trace('ERROR: no context3D - video driver problem?');
				return;
			}
			
			context3D.enableErrorChecking = true;
			
			//后台缓冲
			context3D.configureBackBuffer(stage.width, stage.height, 2, true);
			
			//初始化着色器并上传到 GPU
			initShaders();
			
			playerTexture = context3D.createTexture(playerTextureData.width, playerTextureData.height, Context3DTextureFormat.BGRA, false);
			Utils.uploadTextureWithMipmaps(playerTexture, playerTextureData.bitmapData);
			
			terrainTexture = context3D.createTexture(terrainTextureData.width, terrainTextureData.height, Context3DTextureFormat.BGRA, false);
			Utils.uploadTextureWithMipmaps(terrainTexture, terrainTextureData.bitmapData);
			
			cratersTexture = context3D.createTexture(cratersTextureData.width, cratersTextureData.height, Context3DTextureFormat.BGRA, false);
			Utils.uploadTextureWithMipmaps(cratersTexture, cratersTextureData.bitmapData);
			
			puffTexture = context3D.createTexture(puffTextureData.width, puffTextureData.height, Context3DTextureFormat.BGRA, false);
			Utils.uploadTextureWithMipmaps(puffTexture, puffTextureData.bitmapData);
			
			skyTexture = context3D.createTexture(skyTextureData.width, skyTextureData.height, Context3DTextureFormat.BGRA, false);
			Utils.uploadTextureWithMipmaps(skyTexture, skyTextureData.bitmapData);
			
			//粒子贴图
			particle1texture = context3D.createTexture(particle1bitmap.width, particle1bitmap.height, Context3DTextureFormat.BGRA, false);
			Utils.uploadTextureWithMipmaps(particle1texture, particle1bitmap.bitmapData);
			
			particle2texture = context3D.createTexture(particle2bitmap.width, particle2bitmap.height, Context3DTextureFormat.BGRA, false);
			Utils.uploadTextureWithMipmaps(particle2texture, particle2bitmap.bitmapData);
			
			particle3texture = context3D.createTexture(particle3bitmap.width, particle3bitmap.height, Context3DTextureFormat.BGRA, false);
			Utils.uploadTextureWithMipmaps(particle3texture, particle3bitmap.bitmapData);
			
			particle4texture = context3D.createTexture(particle4bitmap.width, particle4bitmap.height, Context3DTextureFormat.BGRA, false);
			Utils.uploadTextureWithMipmaps(particle4texture, particle4bitmap.bitmapData);
			
			//初始化数据
			initData();
			
			//重置透视矩阵
			projectionmatrix.identity();
			//设置透视矩阵
			projectionmatrix.perspectiveFieldOfViewRH(45, stage.width / stage.height, 0.01, 150000.0);
			
			//游戏主循环
			addEventListener(Event.ENTER_FRAME,enterFrame);
		}
		
		private function initData():void 
		{
			//摄像机实体
			trace("Creating the camera entity...");
			chaseCamera = new Entity();
			
			// create the player model
			trace("Creating the player entity...");
			player = new Entity(myObjData5, context3D, shaderProgram1, playerTexture);
			// rotate to face forward
			player.rotationDegreesX = -90;
			player.z = 2100;
			
			trace("Parsing the terrain...");
			// add some terrain to the props list
			var terrain:Entity = new Entity(terrainObjData, context3D, shaderProgram1, terrainTexture);
			terrain.rotationDegreesZ = 90;
			terrain.y = -50;
			props.push(terrain);
			
			trace("Cloning the terrain...");
			// use the same mesh in another location
			var terrain2:Entity = terrain.clone();
			terrain2.z = -4000;
			props.push(terrain2);
			
			trace("Parsing the asteroid field...");
			// add an asteroid field to the props list
			asteroids1 = new Entity(asteroidsObjData, context3D, shaderProgram1, cratersTexture);
			asteroids1.rotationDegreesZ = 90;
			asteroids1.scaleXYZ = 200;
			asteroids1.y = 500;
			asteroids1.z = -1000;
			props.push(asteroids1);
			
			trace("Cloning the asteroid field...");
			// use the same mesh in multiple locations
			asteroids2 = asteroids1.clone();
			asteroids2.z = -5000;
			props.push(asteroids2);
			
			asteroids3 = asteroids1.clone();
			asteroids3.z = -9000;
			props.push(asteroids3);
			asteroids4 = asteroids1.clone();
			asteroids4.z = -9000;
			asteroids4.y = -500;
			props.push(asteroids4);
			
			trace("Parsing the engine glow...");
			engineGlow = new Entity(puffObjData, context3D, shaderProgram1, puffTexture);
			//设置跟随
			engineGlow.follow(player);
			//设定渲染模式为粒子效果
			engineGlow.blendSrc = Context3DBlendFactor.ONE;
			engineGlow.blendDst = Context3DBlendFactor.ONE;
			engineGlow.depthTest = false;
			engineGlow.cullingMode = Context3DTriangleFace.NONE;
			engineGlow.y = -1.0;
			engineGlow.scaleXYZ = 0.5;
			particles.push(engineGlow);
			
			trace("Parsing the sky...");
			sky = new Entity(skyObjData, context3D, shaderProgram1, skyTexture);
			//天空也跟随飞船, 因为飞船不应该飞出天空
			sky.follow(player);
			sky.depthTest = false;
			sky.depthTestMode = Context3DCompareMode.LESS;
			sky.cullingMode = Context3DTriangleFace.NONE;
			sky.z = 2000.0;
			sky.scaleX = 40000;
			sky.scaleY = 40000;
			sky.scaleZ = 10000;
			sky.rotationDegreesX = 30;
			props.push(sky);
			
			//创建粒子系统
			particleSystem = new ParticleSystem();
			
			//定义多个粒子源
			trace("Creating an explosion particle system...");
			particleSystem.defineParticle("explosion", new Particle(explosion1_data, context3D, puffTexture, explosion2_data));
			particleSystem.defineParticle("bluebolt", new Particle(explosion1_data, context3D, particle1texture, explosion2_data));
			particleSystem.defineParticle("greenpuff", new Particle(explosion1_data, context3D, particle2texture, explosion2_data));
			particleSystem.defineParticle("ringfire", new Particle(explosion1_data, context3D, particle3texture, explosion2_data));
			particleSystem.defineParticle("sparks", new Particle(explosion1_data, context3D, particle4texture, explosion2_data));
		}
		
		private function renderScene():void
		{
			viewmatrix.identity();
			//看着玩家
			viewmatrix.append(chaseCamera.transform);
			viewmatrix.invert();
			//向下倾斜一点
			viewmatrix.appendRotation(15, Vector3D.X_AXIS);
			//添加鼠标观察的数据
			viewmatrix.appendRotation(gameinput.cameraAngleX, Vector3D.X_AXIS);
			viewmatrix.appendRotation(gameinput.cameraAngleY, Vector3D.Y_AXIS);
			viewmatrix.appendRotation(gameinput.cameraAngleZ, Vector3D.Z_AXIS);
			
			//使用当前的摄像机角度渲染玩家
			player.render(viewmatrix, projectionmatrix);
			
			//遍历所有对象并进行渲染
			for each (entity in props) 
				entity.render(viewmatrix, projectionmatrix);
			for each (entity in enemies) 
				entity.render(viewmatrix, projectionmatrix);
			for each (entity in bullets) 
				entity.render(viewmatrix, projectionmatrix);
			for each (entity in particles) 
				entity.render(viewmatrix, projectionmatrix);
			
			//渲染粒子特效, 深度测试为 false 所以粒子会在最前方
			particleSystem.render(viewmatrix, projectionmatrix);
			//记录粒子三角形的数量
			scenePolycount += particleSystem.totalpolycount;
		}
		
		private function gameStep(frameMs:uint):void 
		{
			//处理玩家输入
			var moveAmount:Number = moveSpeed * frameMs;
			if (gameinput.pressing.up) player.z -= moveAmount;
			if (gameinput.pressing.down) player.z += moveAmount;
			if (gameinput.pressing.left) player.x -= moveAmount;
			if (gameinput.pressing.right) player.x += moveAmount;
			//开火
			if (gameinput.pressing.fire)
			{
				//可以开火
				if (gametimer.gameElapsedTime >= nextShootTime)
				{
					//trace("Fire!");
					nextShootTime = gametimer.gameElapsedTime + shootDelay;
					
					//获取玩家前方的任意位置
					var groundzero:Matrix3D = new Matrix3D;
					groundzero.prependTranslation(player.x + Math.random() * 200 - 100, player.y + Math.random() * 100 - 50, player.z + Math.random() * -1000 - 250);
					
					//获取任意的一个粒子
					switch (gametimer.frameCount % 5)
					{
						case 0:
							particleSystem.spawn("explosion", groundzero, 2000);
						break;
						case 1:
							particleSystem.spawn("bluebolt", groundzero, 2000);
						break;
						case 2:
							particleSystem.spawn("greenpuff", groundzero, 2000);
						break;
						case 3:
							particleSystem.spawn("ringfire", groundzero, 2000);
						break;
						case 4:
							particleSystem.spawn("sparks", groundzero, 2000);
						break;
					}
				}
			}
			
			//摄像机跟随玩家
			chaseCamera.x = player.x;
			chaseCamera.y = player.y + 1.5; // above
			chaseCamera.z = player.z + 3; // behind
			
			//小行星的移动
			asteroids1.rotationDegreesX += asteroidRotationSpeed * frameMs;
			asteroids2.rotationDegreesX -= asteroidRotationSpeed * frameMs;
			asteroids3.rotationDegreesX += asteroidRotationSpeed * frameMs;
			asteroids4.rotationDegreesX -= asteroidRotationSpeed * frameMs;
			
			//引擎动画效果
			engineGlow.rotationDegreesZ += 10 * frameMs;
			engineGlow.scaleXYZ = Math.cos(gametimer.gameElapsedTime / 66) / 20 + 0.5;
			
			//更新粒子特效
			particleSystem.step(frameMs);
		}
		
		//心跳方法
		private function heartbeat():void
		{
			trace('heartbeat at ' + gametimer.gameElapsedTime + 'ms');
			trace('player ' + player.posString());
			trace('camera ' + chaseCamera.posString());
			trace('particles active: ' + particleSystem.particlesActive);
			trace('particles total: ' + particleSystem.particlesCreated);
			trace('particles polies: ' + particleSystem.totalpolycount);
		}
		
		private function enterFrame(e:Event):void 
		{
			context3D.clear(0,0,0); 
			
			//计时器调用
			gametimer.tick();
			
			//处理游戏逻辑
			gameStep(gametimer.frameMs);
			
			//渲染场景
			renderScene();
			
			context3D.present();
			
			//更新状态显示
			fpsTicks++;
			var now:uint = getTimer();
			var delta:uint = now - fpsLast;
			if (delta >= 1000) 
			{
				var fps:Number = fpsTicks / delta * 1000;
				fpsTf.text = fps.toFixed(1) + " fps (" + scenePolycount + " polies)";
				fpsTicks = 0;
				fpsLast = now;
			}
			
			//更新分数
			updateScore();
		}
	}
}

package
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.entities.Sprite3D;
	import away3d.lights.PointLight;
	import away3d.loaders.parsers.Parsers;
	import away3d.materials.ColorMaterial;
	import away3d.materials.TextureMaterial;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterData;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.methods.CompositeDiffuseMethod;
	import away3d.materials.methods.CompositeSpecularMethod;
	import away3d.materials.methods.FresnelSpecularMethod;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.methods.PhongSpecularMethod;
	import away3d.primitives.SkyBox;
	import away3d.primitives.SphereGeometry;
	import away3d.textures.BitmapCubeTexture;
	import away3d.textures.BitmapTexture;
	import away3d.utils.Cast;
	
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	use namespace arcane;
	
	/**
	 * 地球示例.
	 */
	[SWF(backgroundColor="#000000", frameRate=60)]
	public class Intermediate_Globe extends Sprite
	{
		//夜晚的地球贴图
		[Embed(source="/../embeds/globe/land_lights_16384.jpg")]
		public static var EarthNight:Class;
		
		//白天的地球贴图
		[Embed(source="/../embeds/globe/land_ocean_ice_2048_match.jpg")]
		public static var EarthDiffuse:Class;
		
		//地球法线贴图
		[Embed(source="/../embeds/globe/EarthNormal.png")]
		public static var EarthNormals:Class;
		
		//地球反射贴图
		[Embed(source="/../embeds/globe/earth_specular_2048.jpg")]
		public static var EarthSpecular:Class;
		
		//地球的云层贴图
		[Embed(source="/../embeds/globe/cloud_combined_2048.jpg")]
		public static var SkyDiffuse:Class;
		
		//太空天空盒子的贴图
		[Embed(source="/../embeds/skybox/space_posX.jpg")]
		private var PosX:Class;
		[Embed(source="/../embeds/skybox/space_negX.jpg")]
		private var NegX:Class;
		[Embed(source="/../embeds/skybox/space_posY.jpg")]
		private var PosY:Class;
		[Embed(source="/../embeds/skybox/space_negY.jpg")]
		private var NegY:Class;
		[Embed(source="/../embeds/skybox/space_posZ.jpg")]
		private var PosZ:Class;
		[Embed(source="/../embeds/skybox/space_negZ.jpg")]
		private var NegZ:Class;
		
		//光晕贴图
		[Embed(source="/../embeds/lensflare/flare0.jpg")]
		private var Flare0:Class;
		[Embed(source="/../embeds/lensflare/flare1.jpg")]
		private var Flare1:Class;
		[Embed(source="/../embeds/lensflare/flare2.jpg")]
		private var Flare2:Class;
		[Embed(source="/../embeds/lensflare/flare3.jpg")]
		private var Flare3:Class;
		[Embed(source="/../embeds/lensflare/flare4.jpg")]
		private var Flare4:Class;
		[Embed(source="/../embeds/lensflare/flare5.jpg")]
		private var Flare5:Class;
		[Embed(source="/../embeds/lensflare/flare6.jpg")]
		private var Flare6:Class;
		[Embed(source="/../embeds/lensflare/flare7.jpg")]
		private var Flare7:Class;
		[Embed(source="/../embeds/lensflare/flare8.jpg")]
		private var Flare8:Class;
		[Embed(source="/../embeds/lensflare/flare9.jpg")]
		private var Flare9:Class;
		[Embed(source="/../embeds/lensflare/flare10.jpg")]
		private var Flare10:Class;
		[Embed(source="/../embeds/lensflare/flare11.jpg")]
		private var Flare11:Class;
		[Embed(source="/../embeds/lensflare/flare12.jpg")]
		private var Flare12:Class;
		
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:HoverController;
		private var awayStats:AwayStats;
		
		private var sunMaterial:TextureMaterial;
		private var groundMaterial:TextureMaterial;
		private var cloudMaterial:TextureMaterial;
		private var atmosphereMaterial:ColorMaterial;
		private var atmosphereDiffuseMethod:BasicDiffuseMethod;
		private var atmosphereSpecularMethod:BasicSpecularMethod;
		private var cubeTexture:BitmapCubeTexture;
		
		private var sun:Sprite3D;
		private var earth:Mesh;
		private var clouds:Mesh;
		private var atmosphere:Mesh;
		private var tiltContainer:ObjectContainer3D;
		private var orbitContainer:ObjectContainer3D;
		private var skyBox:SkyBox;
		
		private var light:PointLight;
		private var lightPicker:StaticLightPicker;
		//光晕
		private var flares:Vector.<FlareObject> = new Vector.<FlareObject>();
		
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var mouseLockX:Number = 0;
		private var mouseLockY:Number = 0;
		private var mouseLocked:Boolean;
		private var flareVisible:Boolean;
		
		public function Intermediate_Globe()
		{
			initEngine();
			initText();
			initLights();
			initLensFlare();
			initMaterials();
			initObjects();
			initListeners();
		}
		
		private function initEngine():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			scene = new Scene3D();
			
			//为天空盒设置为最佳渲染
			camera = new Camera3D();
			camera.lens.far = 100000;
			
			view = new View3D();
			view.scene = scene;
			view.camera = camera;
			
			cameraController = new HoverController(camera, null, 0, 0, 600, -90, 90);
			//使 y 轴的拖动略慢于 x 轴的拖动, 默认为 2
			cameraController.yFactor = 1;
			
			Parsers.enableAllBundled();
			
			addChild(view);
			
			addChild(awayStats = new AwayStats(view));
			
			stage.quality = StageQuality.BEST;
		}
		
		private function initText():void
		{
			var text:TextField = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
			text.antiAliasType = AntiAliasType.ADVANCED;
			text.gridFitType = GridFitType.PIXEL;
			text.width = 240;
			text.height = 100;
			text.selectable = false;
			text.mouseEnabled = false;
			text.text = "MOUSE:\n" +
					"\t windowed: click and drag - rotate\n" +
					"\t fullscreen: mouse move - rotate\n" +
					"SCROLL_WHEEL - zoom\n" +
					"SPACE - enables fullscreen mode";
			
			text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
			
			addChild(text);
		}
		
		private function initLights():void
		{
			light = new PointLight();
			light.x = 10000;
			light.ambient = 1;
			light.diffuse = 2;
			
			lightPicker = new StaticLightPicker([light]);
		}
		
		private function initLensFlare():void
		{
			//创建所有的光晕
			flares.push(new FlareObject(new Flare10(),  3.2, -0.01, 147.9));
			flares.push(new FlareObject(new Flare11(),  6,    0,     30.6));
			flares.push(new FlareObject(new Flare7(),   2,    0,     25.5));
			flares.push(new FlareObject(new Flare7(),   4,    0,     17.85));
			flares.push(new FlareObject(new Flare12(),  0.4,  0.32,  22.95));
			flares.push(new FlareObject(new Flare6(),   1,    0.68,  20.4));
			flares.push(new FlareObject(new Flare2(),   1.25, 1.1,   48.45));
			flares.push(new FlareObject(new Flare3(),   1.75, 1.37,   7.65));
			flares.push(new FlareObject(new Flare4(),   2.75, 1.85,  12.75));
			flares.push(new FlareObject(new Flare8(),   0.5,  2.21,  33.15));
			flares.push(new FlareObject(new Flare6(),   4,    2.5,   10.4));
			flares.push(new FlareObject(new Flare7(),   10,   2.66,  50));
		}
		
		private function initMaterials():void
		{
			cubeTexture = new BitmapCubeTexture(Cast.bitmapData(PosX), Cast.bitmapData(NegX), Cast.bitmapData(PosY), Cast.bitmapData(NegY), Cast.bitmapData(PosZ), Cast.bitmapData(NegZ));
			
			//校正反射贴图
			var specBitmap:BitmapData = Cast.bitmapData(EarthSpecular);
			specBitmap.colorTransform(specBitmap.rect, new ColorTransform(1, 1, 1, 1, 64, 64, 64));
			
			//创建反射方法
			var specular:FresnelSpecularMethod = new FresnelSpecularMethod(true, new PhongSpecularMethod());
			specular.fresnelPower = 1;
			specular.normalReflectance = 0.1;
			
			sunMaterial = new TextureMaterial(Cast.bitmapTexture(Flare10));
			sunMaterial.blendMode = BlendMode.ADD;
			
			groundMaterial = new TextureMaterial(Cast.bitmapTexture(EarthDiffuse));
			groundMaterial.specularMethod = specular;
			groundMaterial.specularMap = new BitmapTexture(specBitmap);
			groundMaterial.normalMap = Cast.bitmapTexture(EarthNormals);
			groundMaterial.ambientTexture = Cast.bitmapTexture(EarthNight);
			groundMaterial.lightPicker = lightPicker;
			groundMaterial.gloss = 5;
			groundMaterial.specular = 1;
			groundMaterial.ambientColor = 0xFFFFFF;
			groundMaterial.ambient = 1;
			
			var skyBitmap:BitmapData = new BitmapData(2048, 1024, true, 0xFFFFFFFF);
			skyBitmap.copyChannel(Cast.bitmapData(SkyDiffuse), skyBitmap.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
			
			cloudMaterial = new TextureMaterial(new BitmapTexture(skyBitmap));
			cloudMaterial.alphaBlending = true;
			cloudMaterial.lightPicker = lightPicker;
			cloudMaterial.specular = 0;
			cloudMaterial.ambientColor = 0x1b2048;
			cloudMaterial.ambient = 1;
			
			atmosphereDiffuseMethod =  new CompositeDiffuseMethod(modulateDiffuseMethod);
			atmosphereSpecularMethod =  new CompositeSpecularMethod(modulateSpecularMethod, new PhongSpecularMethod());
			
			atmosphereMaterial = new ColorMaterial(0x1671cc);
			atmosphereMaterial.diffuseMethod = atmosphereDiffuseMethod;
			atmosphereMaterial.specularMethod = atmosphereSpecularMethod;
			atmosphereMaterial.blendMode = BlendMode.ADD;
			atmosphereMaterial.lightPicker = lightPicker;
			atmosphereMaterial.specular = 0.5;
			atmosphereMaterial.gloss = 5;
			atmosphereMaterial.ambientColor = 0x0;
			atmosphereMaterial.ambient = 1;
		}
		
		private function modulateDiffuseMethod(vo:MethodVO, t:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			vo = vo;
			regCache = regCache;
			sharedRegisters = sharedRegisters;
			
			var viewDirFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.sharedRegisters.viewDirFragment;
			var normalFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.sharedRegisters.normalFragment;
			
			var code:String = "dp3 " + t + ".w, " + viewDirFragmentReg + ".xyz, " + normalFragmentReg + ".xyz\n" +
					"mul " + t + ".w, " + t + ".w, " + t + ".w\n";
			
			return code;
		}
		
		private function modulateSpecularMethod(vo:MethodVO, t:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			vo = vo;
			regCache = regCache;
			sharedRegisters = sharedRegisters;
			
			var viewDirFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.sharedRegisters.viewDirFragment;
			var normalFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.sharedRegisters.normalFragment;
			var temp:ShaderRegisterElement = regCache.getFreeFragmentSingleTemp();
			regCache.addFragmentTempUsages(temp, 1);
			
			var code:String = "dp3 " + temp + ", " + viewDirFragmentReg + ".xyz, " + normalFragmentReg + ".xyz\n" +
					"neg" + temp + ", " + temp + "\n" +
					"mul " + t + ".w, " + t + ".w, " + temp + "\n";
			
			regCache.removeFragmentTempUsage(temp);
			
			return code;
		}
		
		private function initObjects():void
		{
			orbitContainer = new ObjectContainer3D();
			orbitContainer.addChild(light);
			scene.addChild(orbitContainer);
			
			sun = new Sprite3D(sunMaterial, 3000, 3000);
			sun.x = 10000;
			orbitContainer.addChild(sun);
			
			earth = new Mesh(new SphereGeometry(200, 200, 100), groundMaterial);
			
			clouds = new Mesh(new SphereGeometry(202, 200, 100), cloudMaterial);
			
			atmosphere = new Mesh(new SphereGeometry(210, 200, 100), atmosphereMaterial);
			atmosphere.scaleX = -1;
			
			tiltContainer = new ObjectContainer3D();
			tiltContainer.rotationX = -23;
			tiltContainer.addChild(earth);
			tiltContainer.addChild(clouds);
			tiltContainer.addChild(atmosphere);
			
			scene.addChild(tiltContainer);
			
			cameraController.lookAtObject = tiltContainer;
			
			//创建天空盒子
			skyBox = new SkyBox(cubeTexture);
			scene.addChild(skyBox);
		}
		
		private function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		private function onEnterFrame(e:Event):void
		{
			earth.rotationY += 0.2;
			clouds.rotationY += 0.21;
			orbitContainer.rotationY += 0.02;
			
			if(stage.mouseLock)
			{
				cameraController.panAngle = 0.3 * mouseLockX;
				cameraController.tiltAngle = 0.3 * mouseLockY;
			}
			else if(move)
			{
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			
			view.render();
			
			updateFlares();
		}
		
		private function updateFlares():void
		{
			var flareVisibleOld:Boolean = flareVisible;
			
			var sunScreenPosition:Vector3D = view.project(sun.scenePosition);
			var xOffset:Number = sunScreenPosition.x - stage.stageWidth/2;
			var yOffset:Number = sunScreenPosition.y - stage.stageHeight/2;
			
			var earthScreenPosition:Vector3D = view.project(earth.scenePosition);
			var earthRadius:Number = 190*stage.stageHeight/earthScreenPosition.z;
			var flareObject:FlareObject;
			
			flareVisible = (sunScreenPosition.x > 0 && sunScreenPosition.x < stage.stageWidth && sunScreenPosition.y > 0 && sunScreenPosition.y  < stage.stageHeight && sunScreenPosition.z > 0 && Math.sqrt(xOffset*xOffset + yOffset*yOffset) > earthRadius)? true:false;
			
			//更新光晕是否可见
			if(flareVisible != flareVisibleOld)
			{
				for each(flareObject in flares)
				{
					if(flareVisible)
						addChild(flareObject.sprite);
					else
						removeChild(flareObject.sprite);
				}
			}
			
			//更新光晕的位置
			if(flareVisible)
			{
				var flareDirection:Point = new Point(xOffset, yOffset);
				for each(flareObject in flares)
				{
					flareObject.sprite.x = sunScreenPosition.x - flareDirection.x*flareObject.position - flareObject.sprite.width / 2;
					flareObject.sprite.y = sunScreenPosition.y - flareDirection.y*flareObject.position - flareObject.sprite.height / 2;
				}
			}
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onMouseUp(e:MouseEvent):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onMouseMove(e:MouseEvent):void
		{
			if(stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				if(mouseLocked && (lastMouseX != 0 || lastMouseY != 0))
				{
					e.movementX += lastMouseX;
					e.movementY += lastMouseY;
					lastMouseX = 0;
					lastMouseY = 0;
				}
				
				mouseLockX += e.movementX;
				mouseLockY += e.movementY;
				
				if(!stage.mouseLock)
				{
					stage.mouseLock = true;
					lastMouseX = stage.mouseX - stage.stageWidth/2;
					lastMouseY = stage.mouseY - stage.stageHeight/2;
				}
				else if(!mouseLocked)
				{
					mouseLocked = true;
				}
				
				if(mouseLockY > cameraController.maxTiltAngle / 0.3)
					mouseLockY = cameraController.maxTiltAngle / 0.3;
				else if(mouseLockY < cameraController.minTiltAngle / 0.3)
					mouseLockY = cameraController.minTiltAngle / 0.3;
			}
		}
		
		private function onStageMouseLeave(event:Event):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onMouseWheel(event:MouseEvent):void
		{
			cameraController.distance -= event.delta*5;
			
			if(cameraController.distance < 400)
				cameraController.distance = 400;
			else if(cameraController.distance > 10000)
				cameraController.distance = 10000;
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			switch(event.keyCode)
			{
				case Keyboard.SPACE:
					if(stage.displayState == StageDisplayState.FULL_SCREEN)
					{
						stage.displayState = StageDisplayState.NORMAL;
					}
					else
					{
						stage.displayState = StageDisplayState.FULL_SCREEN;
						
						mouseLocked = false;
						mouseLockX = cameraController.panAngle / 0.3;
						mouseLockY = cameraController.tiltAngle / 0.3;
					}
					break;
			}
		}
		
		private function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			awayStats.x = stage.stageWidth - awayStats.width;
		}
	}
}

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.geom.Point;

/**
 * 光晕对象.
 */
class FlareObject
{
	private var flareSize:Number = 144;
	
	public var sprite:Bitmap;
	
	public var size:Number;
	
	public var position:Number;
	
	public var opacity:Number;
	
	public function FlareObject(sprite:Bitmap, size:Number, position:Number, opacity:Number)
	{
		this.sprite = new Bitmap(new BitmapData(sprite.bitmapData.width, sprite.bitmapData.height, true, 0xFFFFFFFF));
		this.sprite.bitmapData.copyChannel(sprite.bitmapData, sprite.bitmapData.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
		this.sprite.alpha = opacity/100;
		this.sprite.smoothing = true;
		this.sprite.scaleX = this.sprite.scaleY = size*flareSize/sprite.width;
		this.size = size;
		this.position = position;
		this.opacity = opacity;
	}
}

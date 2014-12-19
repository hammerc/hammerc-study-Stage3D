package
{
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.lights.DirectionalLight;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.SphereGeometry;
	import away3d.primitives.TorusGeometry;
	import away3d.textures.BitmapTexture;
	import away3d.utils.Cast;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	/**
	 * 明暗应用.
	 */
	[SWF(backgroundColor="#000000", frameRate=60)]
	public class Basic_Shading extends Sprite
	{
		[Embed(source="/../embeds/trinket_diffuse.jpg")]
		public static var TrinketDiffuse:Class;
		[Embed(source="/../embeds/trinket_specular.jpg")]
		public static var TrinketSpecular:Class;
		[Embed(source="/../embeds/trinket_normal.jpg")]
		public static var TrinketNormals:Class;
		
		[Embed(source="/../embeds/beachball_diffuse.jpg")]
		public static var BeachBallDiffuse:Class;
		[Embed(source="/../embeds/beachball_specular.jpg")]
		public static var BeachBallSpecular:Class;
		
		[Embed(source="/../embeds/weave_diffuse.jpg")]
		public static var WeaveDiffuse:Class;
		[Embed(source="/../embeds/weave_normal.jpg")]
		public static var WeaveNormals:Class;
		
		[Embed(source="/../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;
		[Embed(source="/../embeds/floor_specular.jpg")]
		public static var FloorSpecular:Class;
		[Embed(source="/../embeds/floor_normal.jpg")]
		public static var FloorNormals:Class;
		
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:HoverController;
		
		private var planeMaterial:TextureMaterial;
		private var sphereMaterial:TextureMaterial;
		private var cubeMaterial:TextureMaterial;
		private var torusMaterial:TextureMaterial;
		
		private var light1:DirectionalLight;
		private var light2:DirectionalLight;
		private var lightPicker:StaticLightPicker;
		
		private var plane:Mesh;
		private var sphere:Mesh;
		private var cube:Mesh;
		private var torus:Mesh;
		
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		
		public function Basic_Shading()
		{
			initEngine();
			initLights();
			initMaterials();
			initObjects();
			initListeners();
		}
		
		private function initEngine():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			scene = new Scene3D();
			
			camera = new Camera3D();
			
			view = new View3D();
			view.antiAlias = 4;
			view.scene = scene;
			view.camera = camera;
			
			cameraController = new HoverController(camera);
			cameraController.distance = 1000;
			cameraController.minTiltAngle = 0;
			cameraController.maxTiltAngle = 90;
			cameraController.panAngle = 45;
			cameraController.tiltAngle = 20;
			
			addChild(view);
			
			addChild(new AwayStats(view));
		}
		
		private function initLights():void
		{
			light1 = new DirectionalLight();
			light1.direction = new Vector3D(0, -1, 0);
			light1.ambient = 0.1;
			light1.diffuse = 0.7;
			
			scene.addChild(light1);
			
			light2 = new DirectionalLight();
			light2.direction = new Vector3D(0, -1, 0);
			//light2.color = 0x00FFFF;
			light2.ambient = 0.1;
			light2.diffuse = 0.7;
			
			scene.addChild(light2);
			
			lightPicker = new StaticLightPicker([light1, light2]);
		}
		
		private function initMaterials():void
		{
			planeMaterial = new TextureMaterial(Cast.bitmapTexture(FloorDiffuse));
			//设定高光贴图
			planeMaterial.specularMap = Cast.bitmapTexture(FloorSpecular);
			//设定法线贴图
			planeMaterial.normalMap = Cast.bitmapTexture(FloorNormals);
			planeMaterial.lightPicker = lightPicker;
			planeMaterial.repeat = true;
			planeMaterial.mipmap = false;
			
			sphereMaterial = new TextureMaterial(Cast.bitmapTexture(BeachBallDiffuse));
			//设定高光贴图
			sphereMaterial.specularMap = Cast.bitmapTexture(BeachBallSpecular);
			sphereMaterial.lightPicker = lightPicker;
			
			cubeMaterial = new TextureMaterial(Cast.bitmapTexture(TrinketDiffuse));
			//设定高光贴图
			cubeMaterial.specularMap = Cast.bitmapTexture(TrinketSpecular);
			//设定法线贴图
			cubeMaterial.normalMap = Cast.bitmapTexture(TrinketNormals);
			cubeMaterial.lightPicker = lightPicker;
			cubeMaterial.mipmap = false;
			
			var weaveDiffuseTexture:BitmapTexture = Cast.bitmapTexture(WeaveDiffuse);
			torusMaterial = new TextureMaterial(weaveDiffuseTexture);
			//设定高光贴图
			torusMaterial.specularMap = weaveDiffuseTexture;
			//设定法线贴图
			torusMaterial.normalMap = Cast.bitmapTexture(WeaveNormals);
			torusMaterial.lightPicker = lightPicker;
			torusMaterial.repeat = true;
		}
		
		private function initObjects():void
		{
			plane = new Mesh(new PlaneGeometry(1000, 1000), planeMaterial);
			plane.geometry.scaleUV(2, 2);
			plane.y = -20;
			
			scene.addChild(plane);
			
			sphere = new Mesh(new SphereGeometry(150, 40, 20), sphereMaterial);
			sphere.x = 300;
			sphere.y = 160;
			sphere.z = 300;
			
			scene.addChild(sphere);
			
			cube = new Mesh(new CubeGeometry(200, 200, 200, 1, 1, 1, false), cubeMaterial);
			cube.x = 300;
			cube.y = 160;
			cube.z = -250;
			
			scene.addChild(cube);
			
			torus = new Mesh(new TorusGeometry(150, 60, 40, 20), torusMaterial);
			torus.geometry.scaleUV(10, 5);
			torus.x = -250;
			torus.y = 160;
			torus.z = -250;
			
			scene.addChild(torus);
		}
		
		private function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		private function onEnterFrame(event:Event):void
		{
			if(move)
			{
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			
			light1.direction = new Vector3D(Math.sin(getTimer() / 10000) * 150000, 1000, Math.cos(getTimer() / 10000) * 150000);
			
			view.render();
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
		
		private function onMouseUp(event:MouseEvent):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onStageMouseLeave(event:Event):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
		}
	}
}

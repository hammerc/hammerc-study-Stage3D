package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.utils.getTimer;
	
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.library.AssetLibrary;
	import away3d.library.assets.AssetType;
	import away3d.lights.PointLight;
	import away3d.loaders.parsers.Parsers;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.methods.FresnelSpecularMethod;
	import away3d.materials.methods.SubsurfaceScatteringDiffuseMethod;
	import away3d.utils.Cast;
	
	/**
	 * 模型渲染.
	 */
	[SWF(backgroundColor="#000000", frameRate=60)]
	public class Intermediate_Head extends Sprite
	{
		[Embed(source="/../embeds/head.obj", mimeType="application/octet-stream")]
		private var HeadModel:Class;
		
		[Embed(source="/../embeds/head_diffuse.jpg")]
		private var Diffuse:Class;
		
		[Embed(source="/../embeds/head_specular.jpg")]
		private var Specular:Class;
		
		[Embed(source="/../embeds/head_normals.jpg")]
		private var Normal:Class;
		
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:HoverController;
		
		private var headMaterial:TextureMaterial;
		//高级渲染方法
		private var subsurfaceMethod:SubsurfaceScatteringDiffuseMethod;
		private var fresnelMethod:FresnelSpecularMethod;
		//基础渲染方法
		private var diffuseMethod:BasicDiffuseMethod;
		private var specularMethod:BasicSpecularMethod;
		
		private var light:PointLight;
		private var lightPicker:StaticLightPicker;
		private var headModel:Mesh;
		private var advancedMethod:Boolean = true;
		
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		
		public function Intermediate_Head()
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
			
			cameraController = new HoverController(camera, null, 45, 10, 800);
			
			addChild(view);
			
			addChild(new AwayStats(view));
		}
		
		private function initLights():void
		{
			light = new PointLight();
			light.x = 15000;
			light.z = 15000;
			light.color = 0xffddbb;
			light.ambient = 1;
			lightPicker = new StaticLightPicker([light]);
			
			scene.addChild(light);
		}
		
		private function initMaterials():void
		{
			//模型纹理
			headMaterial = new TextureMaterial(Cast.bitmapTexture(Diffuse));
			headMaterial.normalMap = Cast.bitmapTexture(Normal);
			headMaterial.specularMap = Cast.bitmapTexture(Specular);
			headMaterial.lightPicker = lightPicker;
			headMaterial.gloss = 10;
			headMaterial.specular = 3;
			headMaterial.ambientColor = 0x303040;
			headMaterial.ambient = 1;
			
			//高级反射方法
			subsurfaceMethod = new SubsurfaceScatteringDiffuseMethod(2048, 2);
			subsurfaceMethod.scatterColor = 0xff7733;
			subsurfaceMethod.scattering = 0.05;
			subsurfaceMethod.translucency = 4;
			headMaterial.diffuseMethod = subsurfaceMethod;
			
			//高级高光方法
			fresnelMethod = new FresnelSpecularMethod(true);
			headMaterial.specularMethod = fresnelMethod;
			
			//普通反射方法
			diffuseMethod = new BasicDiffuseMethod();
			
			//普通高光方法
			specularMethod = new BasicSpecularMethod();
		}
		
		private function initObjects():void
		{
			Parsers.enableAllBundled();
			
			//加载模型
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			AssetLibrary.loadData(new HeadModel());
		}
		
		private function initListeners():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
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
			
			light.x = Math.sin(getTimer() / 10000) * 15000;
			light.y = 1000;
			light.z = Math.cos(getTimer() / 10000) * 15000;
			
			view.render();
		}
		
		private function onAssetComplete(event:AssetEvent):void
		{
			if (event.asset.assetType == AssetType.MESH)
			{
				headModel = event.asset as Mesh;
				headModel.geometry.scale(100); //TODO scale cannot be performed on mesh when using sub-surface diffuse method
				headModel.y = -50;
				headModel.rotationY = 180;
				headModel.material = headMaterial;
				
				scene.addChild(headModel);
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
		
		private function onMouseUp(event:MouseEvent):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onKeyUp(event:KeyboardEvent):void
		{
			advancedMethod = !advancedMethod;
			
			headMaterial.gloss = (advancedMethod)? 10 : 50;
			headMaterial.specular = (advancedMethod)? 3 : 1;
			headMaterial.diffuseMethod = (advancedMethod)? subsurfaceMethod : diffuseMethod;
			headMaterial.specularMethod = (advancedMethod)? fresnelMethod : specularMethod;
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

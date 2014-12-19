package
{
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.library.assets.AssetType;
	import away3d.lights.DirectionalLight;
	import away3d.loaders.Loader3D;
	import away3d.loaders.misc.AssetLoaderContext;
	import away3d.loaders.parsers.Max3DSParser;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.FilteredShadowMapMethod;
	import away3d.primitives.PlaneGeometry;
	import away3d.utils.Cast;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	/**
	 * 3ds 文件加载示例.
	 */
	[SWF(backgroundColor="#000000", frameRate=60)]
	public class Basic_Load3DS extends Sprite
	{
		[Embed(source="/../embeds/soldier_ant.3ds", mimeType="application/octet-stream")]
		public static var AntModel:Class;
		
		[Embed(source="/../embeds/soldier_ant.jpg")]
		public static var AntTexture:Class;
		
		[Embed(source="/../embeds/CoarseRedSand.jpg")]
		public static var SandTexture:Class;
		
		private var _view:View3D;
		private var _cameraController:HoverController;
		
		private var _light:DirectionalLight;
		private var _lightPicker:StaticLightPicker;
		private var _direction:Vector3D;
		
		private var _groundMaterial:TextureMaterial;
		
		private var _loader:Loader3D;
		private var _ground:Mesh;
		
		private var _move:Boolean = false;
		private var _lastPanAngle:Number;
		private var _lastTiltAngle:Number;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;
		
		public function Basic_Load3DS()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			_view = new View3D();
			addChild(_view);
			
			//设置为最佳的影子渲染
			_view.camera.lens.far = 2100;
			
			_cameraController = new HoverController(_view.camera, null, 45, 20, 1000, 10);
			
			_light = new DirectionalLight(-1, -1, 1);
			_direction = new Vector3D(-1, -1, 1);
			_lightPicker = new StaticLightPicker([_light]);
			_view.scene.addChild(_light);
			
			var assetLoaderContext:AssetLoaderContext = new AssetLoaderContext();
			//映射模型文件中的贴图路径信息为实际的贴图数据
			assetLoaderContext.mapUrlToData("texture.jpg", new AntTexture());
			
			//创建地板
			_groundMaterial = new TextureMaterial(Cast.bitmapTexture(SandTexture));
			//添加阴影效果
			_groundMaterial.shadowMethod = new FilteredShadowMapMethod(_light);
			_groundMaterial.shadowMethod.epsilon = 0.2;
			_groundMaterial.lightPicker = _lightPicker;
			_groundMaterial.specular = 0;
			_ground = new Mesh(new PlaneGeometry(1000, 1000), _groundMaterial);
			_view.scene.addChild(_ground);
			
			//使用 Loader3D 对象加载模型文件
			_loader = new Loader3D();
			_loader.scale(300);
			_loader.z = -200;
			_loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			_loader.loadData(new AntModel(), assetLoaderContext, null, new Max3DSParser(false));
			_view.scene.addChild(_loader);
			
			//统计窗口
			addChild(new AwayStats(_view));
			
			//事件侦听
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		private function onEnterFrame(event:Event):void
		{
			//摄像机控制类
			if(_move)
			{
				_cameraController.panAngle = 0.3 * (stage.mouseX - _lastMouseX) + _lastPanAngle;
				_cameraController.tiltAngle = 0.3 * (stage.mouseY - _lastMouseY) + _lastTiltAngle;
			}
			//光源方向调整
			_direction.x = -Math.sin(getTimer() / 4000);
			_direction.z = -Math.cos(getTimer() / 4000);
			_light.direction = _direction;
			//渲染
			_view.render();
		}
		
		private function onAssetComplete(event:AssetEvent):void
		{
			if(event.asset.assetType == AssetType.MESH)
			{
				var mesh:Mesh = event.asset as Mesh;
				//使网格可以投射阴影
				mesh.castsShadows = true;
			}
			else if(event.asset.assetType == AssetType.MATERIAL)
			{
				var material:TextureMaterial = event.asset as TextureMaterial;
				//添加阴影效果
				material.shadowMethod = new FilteredShadowMapMethod(_light);
				material.lightPicker = _lightPicker;
				material.gloss = 30;
				material.specular = 1;
				material.ambientColor = 0x303040;
				material.ambient = 1;
			}
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			_lastPanAngle = _cameraController.panAngle;
			_lastTiltAngle = _cameraController.tiltAngle;
			_lastMouseX = stage.mouseX;
			_lastMouseY = stage.mouseY;
			_move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onMouseUp(event:MouseEvent):void
		{
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onStageMouseLeave(event:Event):void
		{
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onResize(event:Event = null):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
		}
	}
}

package
{
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.containers.View3D;
	import away3d.entities.Mesh;
	import away3d.materials.ColorMaterial;
	import away3d.materials.methods.EnvMapMethod;
	import away3d.primitives.SkyBox;
	import away3d.primitives.TorusGeometry;
	import away3d.textures.BitmapCubeTexture;
	import away3d.utils.Cast;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	/**
	 * 天空盒子.
	 */
	[SWF(backgroundColor="#000000", frameRate=60)]
	public class Basic_SkyBox extends Sprite
	{
		[Embed(source="../embeds/skybox/snow_positive_x.jpg")]
		private var EnvPosX:Class;
		[Embed(source="../embeds/skybox/snow_positive_y.jpg")]
		private var EnvPosY:Class;
		[Embed(source="../embeds/skybox/snow_positive_z.jpg")]
		private var EnvPosZ:Class;
		[Embed(source="../embeds/skybox/snow_negative_x.jpg")]
		private var EnvNegX:Class;
		[Embed(source="../embeds/skybox/snow_negative_y.jpg")]
		private var EnvNegY:Class;
		[Embed(source="../embeds/skybox/snow_negative_z.jpg")]
		private var EnvNegZ:Class;
		
		private var _view:View3D;
		
		private var _skyBox:SkyBox;
		private var _torus:Mesh;
		
		public function Basic_SkyBox()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			_view = new View3D();
			addChild(_view);
			
			_view.camera.z = -600;
			_view.camera.y = 0;
			_view.camera.lookAt(new Vector3D());
			//设置视野
			_view.camera.lens = new PerspectiveLens(90);
			
			//立方体贴图对象
			var cubeTexture:BitmapCubeTexture = new BitmapCubeTexture(Cast.bitmapData(EnvPosX), Cast.bitmapData(EnvNegX), Cast.bitmapData(EnvPosY), Cast.bitmapData(EnvNegY), Cast.bitmapData(EnvPosZ), Cast.bitmapData(EnvNegZ));
			
			//环境映射纹理
			var material:ColorMaterial = new ColorMaterial(0xFFFFFF, 1);
			material.specular = 0.5;
			material.ambient = 0.25;
			material.ambientColor = 0x111199;
			material.ambient = 1;
			//添加环境映射效果
			material.addMethod(new EnvMapMethod(cubeTexture, 1));
			
			//添加圆环网格, 应用环境映射纹理
			_torus = new Mesh(new TorusGeometry(150, 60, 40, 20), material);
			_view.scene.addChild(_torus);
			
			//创建和添加天空盒子
			_skyBox = new SkyBox(cubeTexture);
			_view.scene.addChild(_skyBox);
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		private function onEnterFrame(e:Event):void
		{
			_torus.rotationX += 2;
			_torus.rotationY += 1;
			
			_view.camera.position = new Vector3D();
			_view.camera.rotationY += 0.5 * (stage.mouseX - stage.stageWidth / 2) / 800;
			_view.camera.moveBackward(600);
			
			_view.render();
		}
		
		private function onResize(event:Event = null):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
		}
	}
}

package
{
	import away3d.containers.View3D;
	import away3d.entities.Mesh;
	import away3d.entities.TextureProjector;
	import away3d.materials.TextureMaterial;
	import away3d.materials.methods.ProjectiveTextureMethod;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.SkyBox;
	import away3d.textures.BitmapCubeTexture;
	import away3d.utils.Cast;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	/**
	 * TextureProjector 示例.
	 */
	[SWF(backgroundColor="#000000", frameRate=60)]
	public class Basic_TextureProjector extends Sprite
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
		
		[Embed(source="/../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;
		
		[Embed(source="../embeds/wheel.png")]
		public static var MyWheel:Class;
		
		private var _view:View3D;
		private var _skyBox:SkyBox;
		private var _plane:Mesh;
		
		public function Basic_TextureProjector()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			_view = new View3D();
			addChild(_view);
			
			_view.camera.z = -600;
			_view.camera.y = 500;
			_view.camera.lookAt(new Vector3D());
			
			var cubeTexture:BitmapCubeTexture = new BitmapCubeTexture(Cast.bitmapData(EnvPosX), Cast.bitmapData(EnvNegX), Cast.bitmapData(EnvPosY), Cast.bitmapData(EnvNegY), Cast.bitmapData(EnvPosZ), Cast.bitmapData(EnvNegZ));
			_skyBox = new SkyBox(cubeTexture);
			_view.scene.addChild(_skyBox);
			
			_plane = new Mesh(new PlaneGeometry(700, 700), new TextureMaterial(Cast.bitmapTexture(FloorDiffuse)));
			_view.scene.addChild(_plane);
			
			//创建 TextureProjector 对象
			var projector:TextureProjector = new TextureProjector(Cast.bitmapTexture(MyWheel));
			//调整位置
			projector.position = new Vector3D(0, 1000, 0);
			//调整视域
			projector.fieldOfView = 90;
			//应用到纹理
			TextureMaterial(_plane.material).addMethod(new ProjectiveTextureMethod(projector));
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		private function onEnterFrame(e:Event):void
		{
			_view.camera.position = new Vector3D();
			_view.camera.rotationY += 0.5 * (stage.mouseX - stage.stageWidth / 2) / 800;
			_view.camera.moveBackward(600);
			
			_plane.rotationY += 1;
			
			_view.render();
		}
		
		private function onResize(event:Event = null):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
		}
	}
}

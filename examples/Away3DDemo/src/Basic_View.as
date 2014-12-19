package
{
	import away3d.containers.View3D;
	import away3d.entities.Mesh;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.PlaneGeometry;
	import away3d.utils.Cast;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	/**
	 * 基础测试.
	 */
	[SWF(backgroundColor="#000000", frameRate=60)]
	public class Basic_View extends Sprite
	{
		[Embed(source="/../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;
		
		private var _view:View3D;
		private var _plane:Mesh;
		
		public function Basic_View()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			_view = new View3D();
			addChild(_view);
			
			//默认使用透视镜头
			_view.camera.z = -600;
			_view.camera.y = 500;
			_view.camera.lookAt(new Vector3D());
			
			_plane = new Mesh(new PlaneGeometry(700, 700), new TextureMaterial(Cast.bitmapTexture(FloorDiffuse)));
			_view.scene.addChild(_plane);
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		private function onEnterFrame(e:Event):void
		{
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

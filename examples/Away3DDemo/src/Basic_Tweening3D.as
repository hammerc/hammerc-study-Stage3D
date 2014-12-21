package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	import away3d.containers.View3D;
	import away3d.core.pick.PickingColliderType;
	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.PlaneGeometry;
	import away3d.utils.Cast;
	
	import caurina.transitions.Tweener;
	import caurina.transitions.properties.CurveModifiers;
	
	/**
	 * 点击及缓动.
	 */
	[SWF(backgroundColor="#000000", frameRate=60)]
	public class Basic_Tweening3D extends Sprite
	{
		[Embed(source="/../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;
		
		[Embed(source="/../embeds/trinket_diffuse.jpg")]
		public static var TrinketDiffuse:Class;
		
		private var _view:View3D;
		
		private var _plane:Mesh;
		private var _cube:Mesh;
		
		public function Basic_Tweening3D()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			_view = new View3D();
			addChild(_view);
			
			_view.camera.z = -600;
			_view.camera.y = 500;
			_view.camera.lookAt(new Vector3D());
			
			_cube = new Mesh(new CubeGeometry(100, 100, 100, 1, 1, 1, false), new TextureMaterial(Cast.bitmapTexture(TrinketDiffuse)));
			_cube.y = 50;
			_view.scene.addChild(_cube);
			
			_plane = new Mesh(new PlaneGeometry(700, 700), new TextureMaterial(Cast.bitmapTexture(FloorDiffuse)));
			_plane.pickingCollider = PickingColliderType.AS3_FIRST_ENCOUNTERED;
			_plane.mouseEnabled = true;
			_view.scene.addChild(_plane);
			
			_plane.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUp);
			
			CurveModifiers.init();
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		private function onEnterFrame(e:Event):void
		{
			_view.render();
		}
		
		private function onMouseUp(ev:MouseEvent3D) : void
		{
			Tweener.addTween(_cube, {time:0.5, x:ev.scenePosition.x, z:ev.scenePosition.z, _bezier:{x:_cube.x, z:ev.scenePosition.z} });
		}
		
		private function onResize(event:Event = null):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
		}
	}
}

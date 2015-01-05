package  
{
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.SphereGeometry;
	
	import awayphysics.collision.dispatch.AWPCollisionObject;
	import awayphysics.collision.shapes.*;
	import awayphysics.debug.AWPDebugDraw;
	import awayphysics.dynamics.*;
	import awayphysics.events.AWPEvent;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	
	/**
	 * 碰撞测试.
	 */
	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class CollisionEventTest extends Sprite
	{
		private var _view:View3D;
		private var _light:PointLight;
		private var _lightPicker:StaticLightPicker;
		private var _orginalMaterial:ColorMaterial;
		private var _bodiesMaterial:Vector.<ColorMaterial>;
		
		private var _physicsWorld:AWPDynamicsWorld;
		private var _sphereBody:AWPCollisionObject;
		private var _boxes:Vector.<AWPCollisionObject>;
		
		private var _sRotation:Number = 0;
		private var _sDirection:Vector3D = new Vector3D(0, 0, 10);
		
		private var _timeStep:Number = 1 / 60;
		
		private var _keyRight:Boolean = false;
		private var _keyLeft:Boolean = false;
		private var _keyForward:Boolean = false;
		private var _keyReverse:Boolean = false;
		
		private var _debugDraw:AWPDebugDraw;
		
		public function CollisionEventTest() 
		{
			if(stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			_view = new View3D();
			this.addChild(_view);
			this.addChild(new AwayStats(_view));
			
			_light = new PointLight();
			_light.y = 2500;
			_light.z = -4000;
			_view.scene.addChild(_light);
			
			_lightPicker = new StaticLightPicker([_light]);
			
			_view.camera.lens.far = 10000;
			_view.camera.y = _light.y;
			_view.camera.z = _light.z;
			_view.camera.rotationX = 25;
			
			//初始化物理世界
			_physicsWorld = AWPDynamicsWorld.getInstance();
			_physicsWorld.initWithDbvtBroadphase();
			//开启碰撞侦听, AWPEvent.COLLISION_ADDED 事件被启用
			_physicsWorld.collisionCallbackOn = true;
			
			_debugDraw = new AWPDebugDraw(_view, _physicsWorld); 
			_debugDraw.debugMode |= AWPDebugDraw.DBG_DrawRay;
			
			_orginalMaterial = new ColorMaterial(0xffff00, 0.6);
			_orginalMaterial.lightPicker = _lightPicker;
			_bodiesMaterial = new Vector.<ColorMaterial>();
			_bodiesMaterial[0] = new ColorMaterial(0x0000ff, 0.6);
			_bodiesMaterial[0].lightPicker = _lightPicker;
			_bodiesMaterial[1] = new ColorMaterial(0x00ffff, 0.6);
			_bodiesMaterial[1].lightPicker = _lightPicker;
			_bodiesMaterial[2] = new ColorMaterial(0xff00ff, 0.6);
			_bodiesMaterial[2].lightPicker = _lightPicker;
			
			var mesh:Mesh;
			var shape:AWPCollisionShape;
			var body:AWPCollisionObject;
			_boxes = new Vector.<AWPCollisionObject>();
			for(var i:int = 0; i < 3; i++)
			{
				mesh = new Mesh(new CubeGeometry(600, 600, 600),_orginalMaterial);
				_view.scene.addChild(mesh);
				shape = new AWPBoxShape(600, 600, 600);
				body = new AWPCollisionObject(shape, mesh);
				body.position = new Vector3D( -1200 + (i * 1000), 500, 0);
				_physicsWorld.addCollisionObject(body);
				_boxes.push(body);
			}
			
			//创建可移动的球体
			var material:ColorMaterial = new ColorMaterial(0xff0000, 0.6);
			material.lightPicker = _lightPicker;
			mesh = new Mesh(new SphereGeometry(200),material);
			_view.scene.addChild(mesh);
			shape = new AWPSphereShape(200);
			_sphereBody = new AWPCollisionObject(shape, mesh);
			_sphereBody.position = new Vector3D( 0, 500, -1200);
			_sphereBody.rotationY = -10;
			_physicsWorld.addCollisionObject(_sphereBody);
			
			//添加射线
			_sphereBody.addRay(new Vector3D(), new Vector3D(500, 0, 0));
			_sphereBody.addRay(new Vector3D(), new Vector3D(-500, 0, 0));
			_sphereBody.addRay(new Vector3D(), new Vector3D(0, 0, 800));
			
			//添加刚体碰撞侦听
			_sphereBody.addEventListener(AWPEvent.COLLISION_ADDED, sphereCollisionAdded);
			//添加射线碰撞侦听
			_sphereBody.addEventListener(AWPEvent.RAY_CAST, sphereRayCast);
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}
		
		private function sphereCollisionAdded(event:AWPEvent):void
		{
			for(var i:int = 0; i < _boxes.length; i++)
			{
				var mesh:Mesh = Mesh(_boxes[i].skin);
				if(event.collisionObject == _boxes[i])
				{
					mesh.material = _bodiesMaterial[i];
				}
			}
		}
		
		private function sphereRayCast(event:AWPEvent):void
		{
			//trace("collision point in world space: "+event.collisionObject.worldTransform.transform.transformVector(event.manifoldPoint.localPointB));
			//trace("collision normal in world space: "+event.manifoldPoint.normalWorldOnB);
			var mesh:Mesh = Mesh(event.collisionObject.skin);
			mesh.material = Mesh(_sphereBody.skin).material;
		}
		
		private function keyDownHandler(event:KeyboardEvent):void
		{
			switch(event.keyCode)
			{
				case Keyboard.UP:
					_keyForward = true;
					_keyReverse = false;
					break;
				case Keyboard.DOWN:
					_keyReverse = true;
					_keyForward = false;
					break;
				case Keyboard.LEFT:
					_keyLeft = true;
					_keyRight = false;
					break;
				case Keyboard.RIGHT:
					_keyRight = true;
					_keyLeft = false;
					break;
			}
		}
		
		private function keyUpHandler(event:KeyboardEvent):void
		{
			switch(event.keyCode)
			{
				case Keyboard.UP:
					_keyForward = false;
					break;
				case Keyboard.DOWN:
					_keyReverse = false;
					break;
				case Keyboard.LEFT:
					_keyLeft = false;
					break;
				case Keyboard.RIGHT:
					_keyRight = false;
					break;
			}
		}
		
		private function handleEnterFrame(e:Event):void
		{
			if(_keyLeft)
			{
				_sRotation -= 3;
				_sphereBody.rotation = new Vector3D(0, _sRotation, 0);
			}
			if(_keyRight)
			{
				_sRotation += 3;
				_sphereBody.rotation = new Vector3D(0, _sRotation, 0);
			}
			if(_keyForward)
			{
				_sphereBody.position = _sphereBody.position.add(_sphereBody.worldTransform.rotationWithMatrix.transformVector(_sDirection));
			}
			if(_keyReverse)
			{
				_sphereBody.position = _sphereBody.position.subtract(_sphereBody.worldTransform.rotationWithMatrix.transformVector(_sDirection));
			}
			
			for each(var body:AWPCollisionObject in _boxes)
			{
				var mesh:Mesh = Mesh(body.skin);
				mesh.material = _orginalMaterial;
			}
			
			_physicsWorld.step(_timeStep);
			_debugDraw.debugDrawWorld();
			_view.render();
		}
	}
}

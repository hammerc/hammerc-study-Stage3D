package
{
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.ConeGeometry;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.CylinderGeometry;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.SphereGeometry;
	
	import awayphysics.collision.shapes.AWPBoxShape;
	import awayphysics.collision.shapes.AWPCollisionShape;
	import awayphysics.collision.shapes.AWPConeShape;
	import awayphysics.collision.shapes.AWPCylinderShape;
	import awayphysics.collision.shapes.AWPSphereShape;
	import awayphysics.collision.shapes.AWPStaticPlaneShape;
	import awayphysics.debug.AWPDebugDraw;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.dynamics.AWPRigidBody;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	
	/**
	 * 刚体碰撞过滤.
	 */
	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class CollisionFilterTest extends Sprite
	{
		//定义碰撞组
		private const collsionGround:int = 1;
		private const collsionBox:int = 2;
		private const collsionCylinder:int = 4;
		private const collsionCone:int = 8;
		private const collsionSphere:int = 16;
		private const collisionAll:int = -1;
		
		private var _view:View3D;
		private var _light:PointLight;
		private var _lightPicker:StaticLightPicker;
		private var _physicsWorld:AWPDynamicsWorld;
		private var _sphereBody:AWPRigidBody;
		private var _timeStep:Number = 1 / 60;
		
		private var _keyRight:Boolean = false;
		private var _keyLeft:Boolean = false;
		private var _keyForward:Boolean = false;
		private var _keyReverse:Boolean = false;
		
		private var _debugDraw:AWPDebugDraw;
		
		public function CollisionFilterTest()
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
			
			_debugDraw = new AWPDebugDraw(_view, _physicsWorld);
			//debugDraw.debugMode = AWPDebugDraw.DBG_NoDebug;
			
			//创建地面网格
			var material:ColorMaterial = new ColorMaterial(0x252525);
			material.lightPicker = _lightPicker;
			var mesh:Mesh = new Mesh(new PlaneGeometry(50000, 50000),material);
			_view.scene.addChild(mesh);
			
			//创建地面形状及刚体
			var groundShape:AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 1, 0));
			var groundRigidbody:AWPRigidBody = new AWPRigidBody(groundShape, mesh, 0);
			//添加刚体的同时进行分组, 允许和所有的物体进行碰撞
			_physicsWorld.addRigidBodyWithGroup(groundRigidbody, collsionGround, collisionAll);
			
			material = new ColorMaterial(0xfc6a11);
			material.lightPicker = _lightPicker;
			
			var shape:AWPCollisionShape;
			var body:AWPRigidBody;
			
			//创建盒子
			mesh = new Mesh(new CubeGeometry(600, 600, 600), material);
			_view.scene.addChild(mesh);
			shape = new AWPBoxShape(600, 600, 600);
			body = new AWPRigidBody(shape, mesh, 1);
			body.friction = .9;
			body.position = new Vector3D(-1000, 300, 0);
			//允许盒子和所有的组进行碰撞
			_physicsWorld.addRigidBodyWithGroup(body, collsionBox, collisionAll);
			
			//创建圆柱
			mesh = new Mesh(new CylinderGeometry(400, 400, 600),material);
			_view.scene.addChild(mesh);
			shape = new AWPCylinderShape(400, 600);
			body = new AWPRigidBody(shape, mesh, 1);
			body.friction = .9;
			body.position = new Vector3D(0, 300, 0);
			//允许圆柱和地面与盒子进行碰撞
			_physicsWorld.addRigidBodyWithGroup(body, collsionCylinder, collsionGround | collsionBox);
			
			//创建圆锥
			mesh = new Mesh(new ConeGeometry(400, 600),material);
			_view.scene.addChild(mesh);
			shape = new AWPConeShape(400, 600);
			body = new AWPRigidBody(shape, mesh, 1);
			body.friction = .9;
			body.position = new Vector3D(1000, 300, 0);
			//允许圆锥和地面与盒子进行碰撞
			_physicsWorld.addRigidBodyWithGroup(body, collsionCone, collsionGround | collsionBox);
			
			material = new ColorMaterial(0xb35b11);
			material.lightPicker = _lightPicker;
			
			//创建球体
			mesh = new Mesh(new SphereGeometry(200),material);
			_view.scene.addChild(mesh);
			shape = new AWPSphereShape(200);
			_sphereBody = new AWPRigidBody(shape, mesh, 1);
			_sphereBody.position = new Vector3D(0, 300, -1000);
			//允许球体和地面与盒子进行碰撞
			_physicsWorld.addRigidBodyWithGroup(_sphereBody, collsionSphere, collsionGround | collsionBox);
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
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
				_sphereBody.applyCentralForce(new Vector3D(-50, 0, 0));
			}
			if(_keyRight)
			{
				_sphereBody.applyCentralForce(new Vector3D(50, 0, 0));
			}
			if(_keyForward)
			{
				_sphereBody.applyCentralForce(new Vector3D(0, 0, 50));
			}
			if(_keyReverse)
			{
				_sphereBody.applyCentralForce(new Vector3D(0, 0, -50));
			}
			
			_physicsWorld.step(_timeStep);
			
			_debugDraw.debugDrawWorld();
			
			_view.render();
		}
	}
}

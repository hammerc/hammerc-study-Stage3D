package
{
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.ConeGeometry;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.CylinderGeometry;
	import away3d.primitives.PlaneGeometry;
	
	import awayphysics.collision.shapes.AWPBoxShape;
	import awayphysics.collision.shapes.AWPConeShape;
	import awayphysics.collision.shapes.AWPCylinderShape;
	import awayphysics.collision.shapes.AWPStaticPlaneShape;
	import awayphysics.debug.AWPDebugDraw;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.dynamics.AWPRigidBody;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	/**
	 * 重力测试.
	 */
	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class GravityTest extends Sprite
	{
		private var _view:View3D;
		private var _light:PointLight;
		private var _lightPicker:StaticLightPicker;
		private var _physicsWorld:AWPDynamicsWorld;
		private var _timeStep:Number = 1 / 60;
		private var _isMouseDown:Boolean;
		private var _currMousePos:Vector3D;
		
		private var _debugDraw:AWPDebugDraw;
		
		public function GravityTest()
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
			_light.y = 0;
			_light.z = -3000;
			_view.scene.addChild(_light);
			
			_lightPicker = new StaticLightPicker([_light]);
			
			_view.camera.lens.far = 10000;
			_view.camera.y = _light.y;
			_view.camera.z = _light.z;
			
			//初始化物理世界
			_physicsWorld = AWPDynamicsWorld.getInstance();
			_physicsWorld.initWithDbvtBroadphase();
			_physicsWorld.gravity = new Vector3D(0, 0, 20);
			
			_debugDraw = new AWPDebugDraw(_view, _physicsWorld);
			_debugDraw.debugMode = AWPDebugDraw.DBG_NoDebug;
			
			//创建地形模型
			var material:ColorMaterial = new ColorMaterial(0x252525);
			material.lightPicker = _lightPicker;
			var ground :Mesh = new Mesh(new PlaneGeometry(50000, 50000), material);
			ground.mouseEnabled = true;
			ground.addEventListener(MouseEvent3D.MOUSE_DOWN, onMouseDown);
			ground.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUp);
			ground.addEventListener(MouseEvent3D.MOUSE_MOVE, onMouseMove);
			_view.scene.addChild(ground);
			
			//创建地形刚体
			var groundShape:AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 1, 0));
			var groundRigidbody:AWPRigidBody = new AWPRigidBody(groundShape, ground, 0);
			_physicsWorld.addRigidBody(groundRigidbody);
			
			groundRigidbody.rotation = new Vector3D(-90, 0, 0);
			
			material = new ColorMaterial(0xe28313);
			material.lightPicker = _lightPicker;
			
			//创建多种可重复使用的形状
			var boxShape:AWPBoxShape = new AWPBoxShape(100, 100, 100);
			var cylinderShape:AWPCylinderShape = new AWPCylinderShape(50, 100);
			var coneShape:AWPConeShape = new AWPConeShape(50, 100);
			
			//创建多个刚体
			var mesh:Mesh;
			var body:AWPRigidBody;
			for(var i:int = 0; i < 20; i++)
			{
				//创建盒子
				mesh = new Mesh(new CubeGeometry(100, 100, 100), material);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(boxShape, mesh, 1);
				body.friction = .9;
				body.linearDamping = .5;
				body.position = new Vector3D(-1000 + 2000 * Math.random(), -1000 + 2000 * Math.random(), -1000 - 2000 * Math.random());
				_physicsWorld.addRigidBody(body);
				
				//创建圆柱
				mesh = new Mesh(new CylinderGeometry(50, 50, 100) ,material);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(cylinderShape, mesh, 1);
				body.friction = .9;
				body.linearDamping = .5;
				body.position = new Vector3D(-1000 + 2000 * Math.random(), -1000 + 2000 * Math.random(), -1000 - 2000 * Math.random());
				_physicsWorld.addRigidBody(body);
				
				//创建圆锥
				mesh = new Mesh(new ConeGeometry(50, 100),material);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(coneShape, mesh, 1);
				body.friction = .9;
				body.linearDamping = .5;
				body.position = new Vector3D(-1000 + 2000 * Math.random(), -1000 + 2000 * Math.random(), -1000 - 2000 * Math.random());
				_physicsWorld.addRigidBody(body);
			}
			
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}
		
		private function onMouseDown(event:MouseEvent3D):void
		{
			_isMouseDown = true;
			_currMousePos = new Vector3D(event.localPosition.x, event.localPosition.z, -600);
			
			this.addEventListener(Event.ENTER_FRAME, handleGravity);
		}
		
		private function onMouseUp(event:MouseEvent3D):void
		{
			_isMouseDown = false;
			
			//获取中心点
			var pos:Vector3D = new Vector3D();
			for each(var body:AWPRigidBody in _physicsWorld.nonStaticRigidBodies)
			{
				pos = pos.add(body.position);
			}
			pos.scaleBy(1 / _physicsWorld.nonStaticRigidBodies.length);
			
			//给所有的非静态物体一个离心的缓冲
			var impulse:Vector3D;
			for each(body in _physicsWorld.nonStaticRigidBodies)
			{
				impulse = body.position.subtract(pos);
				impulse.scaleBy(5000 / impulse.lengthSquared);
				body.applyCentralImpulse(impulse);
			}
			
			//设置重力
			_physicsWorld.gravity = new Vector3D(0, 0, 20);
			
			this.removeEventListener(Event.ENTER_FRAME, handleGravity);
		}
		
		private function onMouseMove(event:MouseEvent3D):void
		{
			if(_isMouseDown)
			{
				_currMousePos = new Vector3D(event.localPosition.x, event.localPosition.z, -600);
			}
		}
		
		private function handleGravity(e:Event):void
		{
			var gravity:Vector3D;
			for each(var body:AWPRigidBody in _physicsWorld.nonStaticRigidBodies)
			{
				gravity = _currMousePos.subtract(body.position);
				gravity.normalize();
				gravity.scaleBy(100);
				
				body.gravity = gravity;
			}
		}
		
		private function handleEnterFrame(e:Event):void
		{
			_physicsWorld.step(_timeStep);
			
			_debugDraw.debugDrawWorld();
			
			_view.render();
		}
	}
}

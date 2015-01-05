package
{
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.SphereGeometry;
	
	import awayphysics.collision.shapes.AWPBoxShape;
	import awayphysics.collision.shapes.AWPSphereShape;
	import awayphysics.collision.shapes.AWPStaticPlaneShape;
	import awayphysics.debug.AWPDebugDraw;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.dynamics.AWPRigidBody;
	import awayphysics.dynamics.constraintsolver.AWPConeTwistConstraint;
	import awayphysics.dynamics.constraintsolver.AWPGeneric6DofConstraint;
	import awayphysics.dynamics.constraintsolver.AWPHingeConstraint;
	import awayphysics.dynamics.constraintsolver.AWPPoint2PointConstraint;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Vector3D;
	import flash.utils.Timer;
	
	/**
	 * 刚体约束测试.
	 * 注意我们看到的是 AWPDebugDraw 绘制的图像, 实际的 3D 对象没有添加到 View3D 中.
	 */
	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class ConstraintTest extends Sprite
	{
		private var _view:View3D;
		private var _light:PointLight;
		private var _lightPicker:StaticLightPicker;
		private var _physicsWorld:AWPDynamicsWorld;
		private var _sphereShape:AWPSphereShape;
		private var _timeStep:Number = 1 / 60;
		private var _generic6Dof:AWPGeneric6DofConstraint;
		
		private var _debugDraw:AWPDebugDraw;
		
		public function ConstraintTest()
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
			_light.z = -3000;
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
			_debugDraw.debugMode |= AWPDebugDraw.DBG_DrawConstraints | AWPDebugDraw.DBG_DrawConstraintLimits;
			
			//创建地面模型
			var material:ColorMaterial = new ColorMaterial(0x252525);
			material.lightPicker = _lightPicker;
			var ground:Mesh = new Mesh(new PlaneGeometry(50000, 50000),material);
			ground.mouseEnabled = true;
			ground.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUp);
			_view.scene.addChild(ground);
			
			//创建地面刚体
			var groundShape:AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 1, 0));
			var groundRigidbody:AWPRigidBody = new AWPRigidBody(groundShape, ground, 0);
			_physicsWorld.addRigidBody(groundRigidbody);
			
			material = new ColorMaterial(0xfc6a11);
			material.lightPicker = _lightPicker;
			
			//创建用于发射的小球形状
			_sphereShape = new AWPSphereShape(100);
			
			var mesh:Mesh;
			var currBody:AWPRigidBody = null;
			var prevBody:AWPRigidBody = null;
			
			//使用 AWPPoint2PointConstraint 对象创建连接点将多个刚体连接起来, 只能使用一个连接点
			var boxShape:AWPBoxShape = new AWPBoxShape(200, 200, 200);
			var p2p:AWPPoint2PointConstraint;
			for(var i:int = 0; i < 6; i++ )
			{
				mesh = new Mesh(new SphereGeometry(100),material);
				//_view.scene.addChild(mesh);
				prevBody = currBody;
				currBody = new AWPRigidBody(_sphereShape, mesh, 2);
				currBody.position = new Vector3D(-1500 - (200 * i), 1500, 0);
				_physicsWorld.addRigidBody(currBody);
				if(i == 0)
				{
					p2p = new AWPPoint2PointConstraint(currBody, new Vector3D(100, 100, 0));
					_physicsWorld.addConstraint(p2p);
				}
				else
				{
					p2p = new AWPPoint2PointConstraint(prevBody, new Vector3D(-100, 0, 0), currBody, new Vector3D(100, 0, 0));
					_physicsWorld.addConstraint(p2p);
				}
			}
			
			//使用 AWPHingeConstraint 对象创建连接点将多个刚体连接起来, 可以使用两个连接点
			boxShape = new AWPBoxShape(400, 80, 300);
			var hinge:AWPHingeConstraint;
			for(i = 0; i < 5; i++ )
			{
				mesh = new Mesh(new CubeGeometry(400, 80, 300),material);
				//_view.scene.addChild(mesh);
				prevBody = currBody;
				currBody = new AWPRigidBody(boxShape, mesh, 2);
				currBody.position = new Vector3D(-500, 2000, (310 * i));
				_physicsWorld.addRigidBody(currBody);
				if(i == 0)
				{
					hinge = new AWPHingeConstraint(currBody, new Vector3D(0, 0, -155), new Vector3D(1, 0, 0));
					_physicsWorld.addConstraint(hinge);
				}
				else
				{
					hinge = new AWPHingeConstraint(prevBody, new Vector3D(0, 0, 155), new Vector3D(1, 0, 0), currBody, new Vector3D(0, 0, -155), new Vector3D(1, 0, 0));
					_physicsWorld.addConstraint(hinge);
				}
			}
			
			//使用 AWPHingeConstraint 创建一个门
			boxShape = new AWPBoxShape(500, 700, 80);
			mesh = new Mesh(new CubeGeometry(500, 700, 80),material);
			//_view.scene.addChild(mesh);
			
			currBody = new AWPRigidBody(boxShape, mesh, 1);
			currBody.position = new Vector3D(0, 1000, 0);
			_physicsWorld.addRigidBody(currBody);
			
			var doorHinge:AWPHingeConstraint = new AWPHingeConstraint(currBody, new Vector3D(-250, 0, 0), new Vector3D(0, 1, 0));
			doorHinge.setLimit(-Math.PI / 4, Math.PI / 4);
			//doorHinge.setAngularMotor(true, 10, 20);
			_physicsWorld.addConstraint(doorHinge);
			
			//使用 AWPGeneric6DofConstraint 创建一个滑块
			boxShape = new AWPBoxShape(300, 300, 600);
			mesh = new Mesh(new CubeGeometry(300, 300, 600),material);
			//_view.scene.addChild(mesh);
			
			prevBody = new AWPRigidBody(boxShape, mesh, 10);
			prevBody.friction = 0.9;
			prevBody.position = new Vector3D(600, 200, 400);
			_physicsWorld.addRigidBody(prevBody);
			
			boxShape = new AWPBoxShape(200, 200, 600);
			mesh = new Mesh(new CubeGeometry(200, 200, 600),material);
			//_view.scene.addChild(mesh);
			
			currBody = new AWPRigidBody(boxShape, mesh, 2);
			currBody.position = new Vector3D(600, 200, -400);
			_physicsWorld.addRigidBody(currBody);
			
			_generic6Dof = new AWPGeneric6DofConstraint(prevBody, new Vector3D(0, 0, -300), new Vector3D(), currBody, new Vector3D(0, 0, 300), new Vector3D());
			_generic6Dof.setLinearLimit(new Vector3D(0, 0, 0), new Vector3D(0, 0, 400));
			_generic6Dof.setAngularLimit(new Vector3D(0, 0, 0), new Vector3D(0, 0, 0));
			_generic6Dof.getTranslationalLimitMotor().enableMotorZ = true;
			_generic6Dof.getTranslationalLimitMotor().targetVelocity = new Vector3D(0, 0, 10);
			_generic6Dof.getTranslationalLimitMotor().maxMotorForce = new Vector3D(0, 0, 5);
			_physicsWorld.addConstraint(_generic6Dof, true);
			
			var timer:Timer = new Timer(1000);
			timer.addEventListener(TimerEvent.TIMER, onTimer);
			timer.start();
			
			//创建圆锥约束
			boxShape = new AWPBoxShape(200, 600, 200);
			mesh = new Mesh(new CubeGeometry(200, 600, 200),material);
			//_view.scene.addChild(mesh);
			
			prevBody = new AWPRigidBody(boxShape, mesh, 5);
			prevBody.position = new Vector3D(1000, 1000, 0);
			_physicsWorld.addRigidBody(prevBody);
			
			mesh = new Mesh(new CubeGeometry(200, 600, 200),material);
			//_view.scene.addChild(mesh);
			
			currBody = new AWPRigidBody(boxShape, mesh, 5);
			currBody.position = new Vector3D(1000, 400, 0);
			_physicsWorld.addRigidBody(currBody);
			
			p2p = new AWPPoint2PointConstraint(prevBody, new Vector3D(0, 300, 0));
			_physicsWorld.addConstraint(p2p);
			
			var coneTwist:AWPConeTwistConstraint = new AWPConeTwistConstraint(prevBody, new Vector3D(0, -300, 0), new Vector3D(), currBody, new Vector3D(0, 300, 0), new Vector3D());
			coneTwist.setLimit(Math.PI / 3, 0, Math.PI / 3);
			_physicsWorld.addConstraint(coneTwist, true);
			
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}
		
		private function onTimer(e:TimerEvent):void
		{
			var vec:Number = _generic6Dof.getTranslationalLimitMotor().targetVelocity.z;
			_generic6Dof.getTranslationalLimitMotor().targetVelocity = new Vector3D(0, 0, -vec);
		}
		
		private function onMouseUp(event:MouseEvent3D):void
		{
			var pos:Vector3D = _view.camera.position;
			var mpos:Vector3D = new Vector3D(event.localPosition.x, event.localPosition.y, event.localPosition.z);
			
			var impulse:Vector3D = mpos.subtract(pos);
			impulse.normalize();
			impulse.scaleBy(200);
			
			//发射小球
			var material:ColorMaterial = new ColorMaterial(0xb35b11);
			material.lightPicker = _lightPicker;
			
			var sphere:Mesh = new Mesh(new SphereGeometry(100),material);
			//_view.scene.addChild(sphere);
			
			var body:AWPRigidBody = new AWPRigidBody(_sphereShape, sphere, 2);
			body.position = pos;
			_physicsWorld.addRigidBody(body);
			
			body.applyCentralImpulse(impulse);
		}
		
		private function handleEnterFrame(e:Event):void
		{
			_physicsWorld.step(_timeStep);
			
			_debugDraw.debugDrawWorld();
			
			_view.render();
		}
	}
}

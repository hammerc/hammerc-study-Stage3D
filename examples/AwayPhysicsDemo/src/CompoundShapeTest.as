package
{
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.containers.ObjectContainer3D;
	import away3d.events.MouseEvent3D;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.SphereGeometry;
	
	import awayphysics.collision.shapes.AWPBoxShape;
	import awayphysics.collision.shapes.AWPCompoundShape;
	import awayphysics.collision.shapes.AWPSphereShape;
	import awayphysics.collision.shapes.AWPStaticPlaneShape;
	import awayphysics.debug.AWPDebugDraw;
	import awayphysics.dynamics.AWPDynamicsWorld;
	import awayphysics.dynamics.AWPRigidBody;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	/**
	 * 自定义形状的刚体测试.
	 */
	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class CompoundShapeTest extends Sprite
	{
		private var _view:View3D;
		private var _light:PointLight;
		private var _lightPicker:StaticLightPicker;
		private var _physicsWorld:AWPDynamicsWorld;
		private var _sphereShape:AWPSphereShape;
		private var _timeStep:Number = 1 / 60;
		
		private var _debugDraw:AWPDebugDraw;
		
		public function CompoundShapeTest()
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
			_light.y = 3000;
			_light.z = -5000;
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
			_debugDraw.debugMode = AWPDebugDraw.DBG_NoDebug;
			
			//创建地面模型
			var material:ColorMaterial = new ColorMaterial(0x252525);
			material.lightPicker = _lightPicker;
			var ground:Mesh = new Mesh(new PlaneGeometry(50000, 50000),material);
			ground.mouseEnabled = true;
			ground.addEventListener(MouseEvent3D.MOUSE_UP, onMouseUp);
			_view.scene.addChild(ground);
			
			//创建地形刚体
			var groundShape:AWPStaticPlaneShape = new AWPStaticPlaneShape(new Vector3D(0, 1, 0));
			var groundRigidbody:AWPRigidBody = new AWPRigidBody(groundShape, ground, 0);
			_physicsWorld.addRigidBody(groundRigidbody);
			
			//创建墙面
			var wall:Mesh = new Mesh(new CubeGeometry(20000, 5000, 100), material);
			_view.scene.addChild(wall);
			
			var wallShape:AWPBoxShape = new AWPBoxShape(20000, 5000, 100);
			var wallRigidbody:AWPRigidBody = new AWPRigidBody(wallShape, wall, 0);
			_physicsWorld.addRigidBody(wallRigidbody);
			
			wallRigidbody.position = new Vector3D(0, 2500, 2000);
			
			//创建球体形状
			_sphereShape = new AWPSphereShape(100);
			
			//创建自定义的椅子形状
			var chairShape:AWPCompoundShape = createChairShape();
			material = new ColorMaterial(0xe28313);
			material.lightPicker = _lightPicker;
			
			//创建 10 个椅子对象
			var mesh:ObjectContainer3D;
			var body:AWPRigidBody;
			for(var i:int = 0; i < 10; i++)
			{
				mesh = createChairMesh(material);
				_view.scene.addChild(mesh);
				body = new AWPRigidBody(chairShape, mesh, 1);
				body.friction = .9;
				body.position = new Vector3D(0, 500 + 1000 * i, 0);
				_physicsWorld.addRigidBody(body);
			}
			
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}
		
		private function createChairMesh(material:ColorMaterial):ObjectContainer3D
		{
			var mesh:ObjectContainer3D = new ObjectContainer3D();
			
			var child1:Mesh = new Mesh(new CubeGeometry(460, 60, 500),material);
			var child2:Mesh = new Mesh(new CubeGeometry(60, 400, 60),material);
			var child3:Mesh = new Mesh(new CubeGeometry(60, 400, 60),material);
			var child4:Mesh = new Mesh(new CubeGeometry(60, 400, 60),material);
			var child5:Mesh = new Mesh(new CubeGeometry(60, 400, 60),material);
			var child6:Mesh = new Mesh(new CubeGeometry(400, 500, 60),material);
			child2.position = new Vector3D(-180, -220, -200);
			child3.position = new Vector3D(180, -220, -200);
			child4.position = new Vector3D(180, -220, 200);
			child5.position = new Vector3D(-180, -220, 200);
			child6.position = new Vector3D(0, 250, 250);
			child6.rotate(new Vector3D(1, 0, 0), 20);
			mesh.addChild(child1);
			mesh.addChild(child2);
			mesh.addChild(child3);
			mesh.addChild(child4);
			mesh.addChild(child5);
			mesh.addChild(child6);
			return mesh;
		}
		
		private function createChairShape():AWPCompoundShape
		{
			var boxShape1:AWPBoxShape = new AWPBoxShape(460, 60, 500);
			var boxShape2:AWPBoxShape = new AWPBoxShape(60, 400, 60);
			var boxShape3:AWPBoxShape = new AWPBoxShape(400, 500, 60);
			
			var chairShape:AWPCompoundShape = new AWPCompoundShape();
			chairShape.addChildShape(boxShape1, new Vector3D(0, 0, 0), new Vector3D());
			chairShape.addChildShape(boxShape2, new Vector3D(-180, -220, -200), new Vector3D());
			chairShape.addChildShape(boxShape2, new Vector3D(180, -220, -200), new Vector3D());
			chairShape.addChildShape(boxShape2, new Vector3D(180, -220, 200), new Vector3D());
			chairShape.addChildShape(boxShape2, new Vector3D(-180, -220, 200), new Vector3D());
			
			chairShape.addChildShape(boxShape3, new Vector3D(0, 250, 250), new Vector3D(20, 0, 0));
			
			return chairShape;
		}
		
		private function onMouseUp(event:MouseEvent3D):void
		{
			var pos:Vector3D = _view.camera.position;
			var mpos:Vector3D = new Vector3D(event.localPosition.x, event.localPosition.y, event.localPosition.z);
			
			var impulse:Vector3D = mpos.subtract(pos);
			impulse.normalize();
			impulse.scaleBy(200);
			
			//发射小球
			var material:ColorMaterial = new ColorMaterial(0xfc6a11);
			material.lightPicker = _lightPicker;
			
			var sphere:Mesh = new Mesh(new SphereGeometry(100),material);
			_view.scene.addChild(sphere);
			
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

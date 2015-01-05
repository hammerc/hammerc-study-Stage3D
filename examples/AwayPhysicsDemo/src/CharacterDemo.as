package
{
	import away3d.animators.*;
	import away3d.animators.data.Skeleton;
	import away3d.animators.nodes.SkeletonClipNode;
	import away3d.animators.transitions.CrossfadeTransition;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.library.AssetLibrary;
	import away3d.library.assets.AssetType;
	import away3d.lights.PointLight;
	import away3d.loaders.Loader3D;
	import away3d.loaders.parsers.MD5AnimParser;
	import away3d.loaders.parsers.MD5MeshParser;
	import away3d.loaders.parsers.Parsers;
	import away3d.materials.ColorMaterial;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.*;
	import away3d.primitives.CapsuleGeometry;
	import away3d.primitives.CubeGeometry;
	import away3d.textures.BitmapTexture;
	
	import awayphysics.collision.dispatch.AWPGhostObject;
	import awayphysics.collision.shapes.*;
	import awayphysics.data.AWPCollisionFlags;
	import awayphysics.debug.AWPDebugDraw;
	import awayphysics.dynamics.*;
	import awayphysics.dynamics.character.AWPKinematicCharacterController;
	import awayphysics.events.AWPEvent;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	
	/**
	 * 角色测试.
	 */
	[SWF(backgroundColor="#000000", frameRate="60", width="1024", height="768")]
	public class CharacterDemo extends Sprite
	{
		[Embed(source="../embeds/hellknight/hellknight_diffuse.jpg")]
		private var Skin:Class;
		[Embed(source="../embeds/hellknight/hellknight_specular.png")]
		private var Spec:Class;
		[Embed(source="../embeds/hellknight/hellknight_normals.png")]
		private var Norm:Class;
		
		private var _view:View3D;
		private var _light:PointLight;
		private var _lightPicker:StaticLightPicker;
		private var _animationController:SkeletonAnimator;
		private var _animationSet:SkeletonAnimationSet;
		private var _stateTransition:CrossfadeTransition = new CrossfadeTransition(0.5);
		private var _skeleton:Skeleton;
		private var _characterMesh:Mesh;
		
		private var _physicsWorld:AWPDynamicsWorld;
		private var _character:AWPKinematicCharacterController;
		private var _timeStep:Number = 1 / 60;
		private var _keyRight:Boolean = false;
		private var _keyLeft:Boolean = false;
		private var _keyForward:Boolean = false;
		private var _keyReverse:Boolean = false;
		private var _keyUp:Boolean = false;
		private var _walkDirection:Vector3D = new Vector3D();
		private var _walkSpeed:Number = 0.1;
		private var _chRotation:Number = 0;
		
		private var _debugDraw:AWPDebugDraw;
		
		public function CharacterDemo()
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
			_light.y = 5000;
			_view.scene.addChild(_light);
			
			_lightPicker = new StaticLightPicker([_light]);
			
			_view.camera.lens.far = 20000;
			_view.camera.y = _light.y;
			_view.camera.z = _light.z;
			_view.camera.rotationX = 25;
			
			//初始化物理引擎
			_physicsWorld = AWPDynamicsWorld.getInstance();
			_physicsWorld.initWithDbvtBroadphase();
			_physicsWorld.collisionCallbackOn = true;
			
			_debugDraw = new AWPDebugDraw(_view, _physicsWorld);
			_debugDraw.debugMode = AWPDebugDraw.DBG_NoDebug;
			
			Parsers.enableAllBundled();
			
			//加载场景模型
			var _loader:Loader3D = new Loader3D();
			_loader.load(new URLRequest('../assets/scene.obj'));
			_loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onSceneResourceComplete);
			
			//加载角色模型
			AssetLibrary.enableParser(MD5MeshParser);
			AssetLibrary.enableParser(MD5AnimParser);
			_loader = new Loader3D();
			_loader.addEventListener(AssetEvent.ASSET_COMPLETE, onMeshComplete);
			_loader.load(new URLRequest("../embeds/hellknight/hellknight.md5mesh"));
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
		}
		
		private function onSceneResourceComplete(event:LoaderEvent):void
		{
			//添加场景模型
			var container:ObjectContainer3D = ObjectContainer3D(event.target);
			_view.scene.addChild(container);
			
			//设定材质
			var materia:ColorMaterial = new ColorMaterial(0xfa6c16);
			materia.lightPicker = _lightPicker;
			var sceneMesh:Mesh = Mesh(container.getChildAt(0));
			sceneMesh.geometry.scale(1000);
			sceneMesh.material = materia;
			
			//设定三角形网格形状
			var sceneShape:AWPBvhTriangleMeshShape = new AWPBvhTriangleMeshShape(sceneMesh.geometry);
			//设定对应的刚体
			var sceneBody:AWPRigidBody = new AWPRigidBody(sceneShape, sceneMesh, 0);
			_physicsWorld.addRigidBody(sceneBody);
			
			//创建用于撞击的盒子
			var material:ColorMaterial = new ColorMaterial(0x252525);
			material.lightPicker = _lightPicker;
			
			var boxShape:AWPBoxShape = new AWPBoxShape(400, 400, 400);
			
			var mesh:Mesh;
			var body:AWPRigidBody;
			var numx:int = 6;
			var numy:int = 4;
			var numz:int = 1;
			for(var i:int = 0; i < numx; i++ )
			{
				for(var j:int = 0; j < numz; j++ )
				{
					for(var k:int = 0; k < numy; k++ )
					{
						mesh = new Mesh(new CubeGeometry(400, 400, 400),material);
						_view.scene.addChild(mesh);
						body = new AWPRigidBody(boxShape, mesh, 1);
						body.friction = .9;
						body.position = new Vector3D(-1500 + i * 400, 400 + k * 400, 1000 + j * 400);
						_physicsWorld.addRigidBody(body);
					}
				}
			}
		}
		
		private function onMeshComplete(event:AssetEvent):void
		{
			if(event.asset.assetType == AssetType.MESH)
			{
				//设置模型
				_characterMesh = event.asset as Mesh;
				_characterMesh.scale(6);
				_characterMesh.y = -400;
				
				//设置纹理
				var material:TextureMaterial = new TextureMaterial(new BitmapTexture(new Skin().bitmapData));
				material.lightPicker = _lightPicker;
				material.normalMap = new BitmapTexture(new Norm().bitmapData);
				material.specularMap = new BitmapTexture(new Spec().bitmapData);
				_characterMesh.material = material;
				
				//添加容器
				var container:ObjectContainer3D = new ObjectContainer3D();
				container.addChild(_characterMesh);
				_view.scene.addChild(container);
				
				//添加测试用的碰撞盒子
				var color:ColorMaterial = new ColorMaterial(0xffff00, 0.4);
				color.lightPicker = _lightPicker;
				var testMesh:Mesh = new Mesh(new CapsuleGeometry(300, 500), color);
				container.addChild(testMesh);
				
				//添加胶囊形状
				var shape:AWPCapsuleShape = new AWPCapsuleShape(300, 500);
				//添加精灵对象并绑定形状和显示对象
				var ghostObject:AWPGhostObject = new AWPGhostObject(shape, container);
				//设置碰撞标志
				ghostObject.collisionFlags = AWPCollisionFlags.CF_CHARACTER_OBJECT;
				//添加碰撞事件
				ghostObject.addEventListener(AWPEvent.COLLISION_ADDED, characterCollisionAdded);
				
				//创建角色控制器
				_character = new AWPKinematicCharacterController(ghostObject, 0.1);
				_physicsWorld.addCharacter(_character);
				
				_character.warp(new Vector3D(0, 500, -1000));
			}
			else if(event.asset.assetType == AssetType.SKELETON)
			{
				//骨骼对象
				_skeleton = event.asset as Skeleton;
			}
			else if(event.asset.assetType == AssetType.ANIMATION_SET)
			{
				//加载动画
				_animationSet = event.asset as SkeletonAnimationSet;
				_animationController = new SkeletonAnimator(_animationSet,_skeleton);
				//不要更新位置, 否则人物会走远
				_animationController.updatePosition = false;
				
				_characterMesh.animator = _animationController;
				
				AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAnimationComplete);
				AssetLibrary.load(new URLRequest("../embeds/hellknight/idle2.md5anim"), null, "idle");
				AssetLibrary.load(new URLRequest("../embeds/hellknight/walk7.md5anim"), null, "walk");
			}
		}
		
		private function onAnimationComplete(event:AssetEvent):void
		{
			if(event.asset.assetType == AssetType.ANIMATION_NODE)
			{
				var animationState:SkeletonClipNode = event.asset as SkeletonClipNode;
				var name:String = event.asset.assetNamespace;
				animationState.name = name;
				_animationSet.addAnimation(animationState);
				
				if (animationState.assetNamespace == "idle")
				{
					_animationController.playbackSpeed = 1;
					_animationController.play("idle", _stateTransition);
				}
			}
		}
		
		private function characterCollisionAdded(event:AWPEvent):void
		{
			//碰撞到其它物体时
			if(!(event.collisionObject.collisionFlags & AWPCollisionFlags.CF_STATIC_OBJECT))
			{
				var body:AWPRigidBody = AWPRigidBody(event.collisionObject);
				var force:Vector3D = event.manifoldPoint.normalWorldOnB.clone();
				force.scaleBy( -30);
				body.applyForce(force, event.manifoldPoint.localPointB);
			}
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
				case Keyboard.SPACE:
					_keyUp = true;
					break;
			}
		}
		
		private function keyUpHandler(event:KeyboardEvent):void
		{
			switch(event.keyCode)
			{
				case Keyboard.UP:
					_keyForward = false;
					_walkDirection.scaleBy(0);
					_character.setWalkDirection(_walkDirection);
					_animationController.playbackSpeed = 1;
					_animationController.play("idle", _stateTransition);
					break;
				case Keyboard.DOWN:
					_keyReverse = false;
					_walkDirection.scaleBy(0);
					_character.setWalkDirection(_walkDirection);
					_animationController.playbackSpeed = 1;
					_animationController.play("idle", _stateTransition);
					break;
				case Keyboard.LEFT:
					_keyLeft = false;
					break;
				case Keyboard.RIGHT:
					_keyRight = false;
					break;
				case Keyboard.SPACE:
					_keyUp = false;
					break;
			}
		}
		
		private function handleEnterFrame(e:Event):void
		{
			_physicsWorld.step(_timeStep);
			
			if(_character)
			{
				if(_keyLeft && _character.onGround())
				{
					_chRotation -= 3;
					_character.ghostObject.rotation = new Vector3D(0, _chRotation, 0);
				}
				if(_keyRight && _character.onGround())
				{
					_chRotation += 3;
					_character.ghostObject.rotation = new Vector3D(0, _chRotation, 0);
				}
				if(_keyForward)
				{
					if(_walkDirection.length == 0)
					{
						_animationController.play("walk", _stateTransition);
						_animationController.playbackSpeed = 1;
					}
					_walkDirection = _character.ghostObject.front;
					_walkDirection.scaleBy(_walkSpeed);
					_character.setWalkDirection(_walkDirection);
				}
				if(_keyReverse)
				{
					if(_walkDirection.length == 0)
					{
						_animationController.play("walk", _stateTransition);
						_animationController.playbackSpeed = -1;
					}
					_walkDirection = _character.ghostObject.front;
					_walkDirection.scaleBy(-_walkSpeed);
					_character.setWalkDirection(_walkDirection);
				}
				if(_keyUp && _character.onGround())
				{
					_character.jump();
				}
				_view.camera.position = _character.ghostObject.position.add(new Vector3D(0, 2000, -2500));
				_view.camera.lookAt(_character.ghostObject.position);
			}
			
			_debugDraw.debugDrawWorld();
			
			_view.render();
		}
	}
}

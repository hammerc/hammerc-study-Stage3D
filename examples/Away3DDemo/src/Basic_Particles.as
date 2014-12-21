package
{
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.ParticleAnimator;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.nodes.ParticleBillboardNode;
	import away3d.animators.nodes.ParticleVelocityNode;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.core.base.Geometry;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.PlaneGeometry;
	import away3d.tools.helpers.ParticleGeometryHelper;
	import away3d.utils.Cast;
	
	/**
	 * 例子特效.
	 */
	[SWF(backgroundColor="#000000", frameRate=60)]
	public class Basic_Particles extends Sprite
	{
		[Embed(source="/../embeds/blue.png")]
		private var ParticleImg:Class;
		
		private var _view:View3D;
		private var _cameraController:HoverController;
		
		private var _particleAnimationSet:ParticleAnimationSet;
		private var _particleMesh:Mesh;
		private var _particleAnimator:ParticleAnimator;
		
		private var _move:Boolean = false;
		private var _lastPanAngle:Number;
		private var _lastTiltAngle:Number;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;
		
		public function Basic_Particles()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			_view = new View3D();
			addChild(_view);
			
			_cameraController = new HoverController(_view.camera, null, 45, 20, 1000);
			
			addChild(new AwayStats(_view));
			
			var plane:Geometry = new PlaneGeometry(10, 10, 1, 1, false);
			var geometrySet:Vector.<Geometry> = new Vector.<Geometry>();
			//注意这里添加的都是同一个几何对象
			for(var i:int = 0; i < 20000; i++)
				geometrySet.push(plane);
			
			_particleAnimationSet = new ParticleAnimationSet(true, true);
			//添加动画: 始终面向摄像机的公告版
			_particleAnimationSet.addAnimation(new ParticleBillboardNode());
			//添加动画: 加速运动
			_particleAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.LOCAL_STATIC));
			//初始化粒子方法
			_particleAnimationSet.initParticleFunc = initParticleFunc;
			
			//粒子纹理对象
			var material:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(ParticleImg));
			material.blendMode = BlendMode.ADD;
			
			//创建动画对象
			_particleAnimator = new ParticleAnimator(_particleAnimationSet);
			//创建 Mesh 对象
			_particleMesh = new Mesh(ParticleGeometryHelper.generateGeometry(geometrySet), material);
			_particleMesh.animator = _particleAnimator;
			_view.scene.addChild(_particleMesh);
			
			//开始播放粒子动画
			_particleAnimator.start();
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		private function initParticleFunc(prop:ParticleProperties):void
		{
			prop.startTime = Math.random() * 5 - 5;
			prop.duration = 5;
			var degree1:Number = Math.random() * Math.PI;
			var degree2:Number = Math.random() * Math.PI * 2;
			var r:Number = Math.random() * 50 + 400;
			prop[ParticleVelocityNode.VELOCITY_VECTOR3D] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2));
		}
		
		private function onEnterFrame(event:Event):void
		{
			if(_move)
			{
				_cameraController.panAngle = 0.3 * (stage.mouseX - _lastMouseX) + _lastPanAngle;
				_cameraController.tiltAngle = 0.3 * (stage.mouseY - _lastMouseY) + _lastTiltAngle;
			}
			_view.render();
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			_lastPanAngle = _cameraController.panAngle;
			_lastTiltAngle = _cameraController.tiltAngle;
			_lastMouseX = stage.mouseX;
			_lastMouseY = stage.mouseY;
			_move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onMouseUp(event:MouseEvent):void
		{
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onStageMouseLeave(event:Event):void
		{
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		private function onResize(event:Event = null):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
		}
	}
}

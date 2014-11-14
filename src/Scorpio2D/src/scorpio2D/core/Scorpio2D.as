// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio2D.core
{
	import flash.display.Stage;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Program3D;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import scorpio2D.display.DisplayObject2D;
	
	import scorpio2D.display.Image2D;
	import scorpio2D.display.Quad2D;
	
	import scorpio2D.display.Stage2D;
	import scorpio2D.events.ResizeEvent2D;
	
	/**
	 * 框架的核心类, 要使用 Scorpio2D 框架必须实例化一个本类.
	 * @author wizardc
	 */
	public class Scorpio2D
	{
		private static var _current:Scorpio2D;
		
		/**
		 * 获取当前正在使用的 Scorpio2D 实例.
		 */
		public static function get current():Scorpio2D
		{
			return _current;
		}
		
		/**
		 * 获取当前正在使用实例的渲染上下文.
		 */
		public static function get context():Context3D
		{
			return _current.context;
		}
		
		private var _stage3D:Stage3D;
		private var _stage:Stage;
		private var _context:Context3D;
		private var _programs:Dictionary;
		
		private var _stage2D:Stage2D;
		private var _rootClass:Class;
		private var _started:Boolean;
		private var _support:RenderSupport;
		private var _antiAliasing:int;
		private var _enableErrorChecking:Boolean;
		private var _viewPort:Rectangle;
		private var _lastFrameTimestamp:Number;
		
		/**
		 * 构造函数.
		 * @param rootClass 文档类, 初始化完毕的时候, 就会创建这个类的实例, 并作为的 stage 的第一个子显示对象添加.
		 * @param stage 舞台.
		 * @param viewPort 矩形表示的, 被渲染的内容的显示区域.
		 * @param stage3D 渲染内容所需的 Stage3D 对象.
		 * @param renderMode 传递 "software" 可以强制模拟软解的情况.
		 */
		public function Scorpio2D(rootClass:Class, stage:Stage, viewPort:Rectangle = null, stage3D:Stage3D = null, renderMode:String = "auto")
		{
			if(stage == null)
			{
				throw new ArgumentError("Stage must not be null");
			}
			if(rootClass == null)
			{
				throw new ArgumentError("Root class must not be null");
			}
			if(viewPort == null)
			{
				viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
			}
			if(stage3D == null)
			{
				stage3D = stage.stage3Ds[0];
			}
			_rootClass = rootClass;
			_viewPort = viewPort;
			_stage3D = stage3D;
			_stage2D = new Stage2D(viewPort.width, viewPort.height, stage.color);
			_stage = stage;
			_antiAliasing = 0;
			_enableErrorChecking = false;
			_programs = new Dictionary();
			_support = new RenderSupport();
			if(_current == null)
			{
				this.makeCurrent();
			}
			//监听原生事件
			stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			stage.addEventListener(Event.RESIZE, resizeHandler, false, 0, true);
			//侦听 Stage3D 事件
			_stage3D.addEventListener(Event.CONTEXT3D_CREATE, contextCreatedHandler, false, 0, true);
			_stage3D.addEventListener(ErrorEvent.ERROR, stage3DErrorHandler, false, 0, true);
			//请求 Stage3D
			try
			{
				_stage3D.requestContext3D(renderMode);
			}
			catch(e:Error)
			{
				showFatalError("Context3D error: " + e.message);
			}
		}
		
		/**
		 * 获取渲染上下文.
		 */
		public function get context():Context3D
		{
			return _context;
		}
		
		/**
		 * 获取是否已经启动.
		 */
		public function get isStarted():Boolean
		{
			return _started;
		}
		
		/**
		 * 设置或获取是否开启错误检查.
		 */
		public function set enableErrorChecking(value:Boolean):void
		{
			_enableErrorChecking = value;
			if(_context)
			{
				_context.enableErrorChecking = value;
			}
		}
		public function get enableErrorChecking():Boolean
		{
			return _enableErrorChecking;
		}
		
		/**
		 * 设置或获取抗锯齿水平.
		 */
		public function set antiAliasing(value:int):void
		{
			_antiAliasing = value;
			updateViewPort();
		}
		public function get antiAliasing():int
		{
			return _antiAliasing;
		}
		
		/**
		 * 设置或获取呈现区域.
		 */
		public function set viewPort(value:Rectangle):void
		{
			_viewPort = value.clone();
			updateViewPort();
		}
		public function get viewPort():Rectangle
		{
			return _viewPort.clone();
		}
		
		/**
		 * 将这个 Scorpio2D 实例设置到 Scorpio2D.current.
		 */
		public function makeCurrent():void
		{
			_current = this;
		}
		
		private function enterFrameHandler(event:Event):void
		{
			if(_started)
			{
				render();
			}
		}
		
		private function resizeHandler(event:Event):void
		{
			_stage2D.dispatchEvent(new ResizeEvent2D(ResizeEvent2D.RESIZE, _stage.stageWidth, _stage.stageHeight));
		}
		
		private function contextCreatedHandler(event:Event):void
		{
			initializeGraphicsAPI();
			initializePrograms();
			initializeRoot();
		}
		
		private function initializeGraphicsAPI():void
		{
			if(_context != null)
			{
				return;
			}
			_context = _stage3D.context3D;
			_context.enableErrorChecking = _enableErrorChecking;
			updateViewPort();
			trace("[Scorpio2D] Initialization complete.");
			trace("[Scorpio2D] Display Driver:" + _context.driverInfo);
		}
		
		private function initializePrograms():void
		{
			Quad2D.registerPrograms(this);
			Image2D.registerPrograms(this);
		}
		
		private function initializeRoot():void
		{
			if(_stage2D.numChildren > 0)
			{
				return;
			}
			var rootObject:DisplayObject2D = new _rootClass();
			if(rootObject == null)
			{
				throw new Error("Invalid root class: " + _rootClass);
			}
			_stage2D.addChild(rootObject);
		}
		
		private function updateViewPort():void
		{
			if(_context != null)
			{
				_context.configureBackBuffer(_viewPort.width, _viewPort.height, _antiAliasing, false);
			}
			_stage3D.x = _viewPort.x;
			_stage3D.y = _viewPort.y;
		}
		
		private function stage3DErrorHandler(event:ErrorEvent):void
		{
			showFatalError("This application is not correctly embedded (wrong wmode value)");
		}
		
		private function showFatalError(error:String):void
		{
			var textField:TextField = new TextField();
			var textFormat:TextFormat = new TextFormat("Verdana", 12, 0xFFFFFF);
			textFormat.align = TextFormatAlign.CENTER;
			textField.defaultTextFormat = textFormat;
			textField.wordWrap = true;
			textField.width = _stage.stageWidth * 0.75;
			textField.autoSize = TextFieldAutoSize.CENTER;
			textField.text = error;
			textField.x = (_stage.stageWidth - textField.width) / 2;
			textField.y = (_stage.stageHeight - textField.height) / 2;
			textField.background = true;
			textField.backgroundColor = 0x440000;
			_stage.addChild(textField);
		}
		
		private function render():void
		{
			if(_context == null)
			{
				return;
			}
			var now:Number = getTimer() / 1000;
			var passedTime:Number = now - _lastFrameTimestamp;
			_lastFrameTimestamp = now;
			
			//子对象播放进入帧事件
			_stage2D.advanceTime(passedTime);
			
			//设置正交矩阵
			_support.setOrthographicProjection(_stage2D.stageWidth, _stage2D.stageHeight);
			//设置默认的混合因子
			_support.setDefaultBlendFactors(true);
			//清除画布
			_support.clear(_stage2D.color, 1);
			//开始渲染所有子对象
			_stage2D.render(_support, 1);
			//将缓冲中的图像显示到屏幕
			_context.present();
			//重置渲染辅助矩阵
			_support.resetMatrix();
		}
		
		/**
		 * 启动框架渲染.
		 */
		public function start():void
		{
			_lastFrameTimestamp = getTimer() / 1000;
			_started = true;
		}
		
		/**
		 * 停止框架渲染.
		 */
		public function stop():void
		{
			_started = false;
		}
		
		/**
		 * 注册渲染器.
		 * @param name 名称.
		 * @param vertexProgram 顶点着色器.
		 * @param fragmentProgram 像素着色器.
		 */
		public function registerProgram(name:String, vertexProgram:ByteArray, fragmentProgram:ByteArray):void
		{
			if(_programs.hasOwnProperty(name))
			{
				throw new Error("Another program with this name is already registered");
			}
			var program:Program3D = _context.createProgram();
			program.upload(vertexProgram, fragmentProgram);
			_programs[name] = program;
		}
		
		/**
		 * 获取着色器.
		 * @param name 名称.
		 * @return 着色器.
		 */
		public function getProgram(name:String):Program3D
		{
			return _programs[name] as Program3D;
		}
		
		/**
		 * 销毁着色器.
		 * @param name 名称.
		 */
		public function deleteProgram(name:String):void
		{
			var program:Program3D = this.getProgram(name);
			if(program != null)
			{
				program.dispose();
				delete _programs[name];
			}
		}
	}
}

// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio2D.display
{
	import scorpio2D.core.scorpio2D_internal;
	import scorpio2D.events.EnterFrameEvent2D;
	
	use namespace scorpio2D_internal;
	
	/**
	 * 3D 显示列表中的顶级显示对象, 只有添加该该类的子项才会被渲染.
	 * 注意该类应由框架内部创建, 不要自己进行创建.
	 * @author wizardc
	 */
	public class Stage2D extends DisplayObjectContainer2D
	{
		private var _width:int;
		private var _height:int;
		private var _color:uint;
		
		/**
		 * 构造函数.
		 * @param width 舞台宽度.
		 * @param height 舞台高度.
		 * @param color 舞台背景色.
		 */
		public function Stage2D(width:int, height:int, color:uint = 0)
		{
			_width = width;
			_height = height;
			_color = color;
		}
		
		/**
		 * 设置或获取舞台背景色.
		 */
		public function set color(value:uint):void
		{
			_color = value;
		}
		public function get color():uint
		{
			return _color;
		}
		
		/**
		 * 设置或获取舞台宽度.
		 */
		public function set stageWidth(value:int):void
		{
			_width = value;
		}
		public function get stageWidth():int
		{
			return _width;
		}
		
		/**
		 * 设置或获取舞台高度.
		 */
		public function set stageHeight(value:int):void
		{
			_height = value;
		}
		public function get stageHeight():int
		{
			return _height;
		}
		
		/**
		 * @inheritDoc
		 */
		public override function set x(value:Number):void
		{
			throw new Error("Cannot set x-coordinate of stage");
		}
		
		/**
		 * @inheritDoc
		 */
		public override function set y(value:Number):void
		{
			throw new Error("Cannot set y-coordinate of stage");
		}
		
		/**
		 * @inheritDoc
		 */
		public override function set scaleX(value:Number):void
		{
			throw new Error("Cannot scale stage");
		}
		
		/**
		 * @inheritDoc
		 */
		public override function set scaleY(value:Number):void
		{
			throw new Error("Cannot scale stage");
		}
		
		/**
		 * @inheritDoc
		 */
		public override function set rotation(value:Number):void
		{
			throw new Error("Cannot rotate stage");
		}
		
		/**
		 * 每帧会调用该方法.
		 * @param passedTime 每帧经过的时间, 单位秒.
		 */
		public function advanceTime(passedTime:Number):void
		{
			//所有子项都统一抛出 ENTER_FRAME 事件
			this.dispatchEventOnChildren(new EnterFrameEvent2D(EnterFrameEvent2D.ENTER_FRAME, passedTime));
		}
	}
}

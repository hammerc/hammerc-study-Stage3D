// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio2D.events
{
	/**
	 * 场景层次更改时的事件类.
	 * @author wizardc
	 */
	public class ResizeEvent2D extends Event2D
	{
		/**
		 * 舞台尺寸改变时抛出.
		 */
		public static const RESIZE:String = "resize";
		
		private var _width:int;
		private var _height:int;
		
		/**
		 * 构造函数.
		 * @param type 事件类型.
		 * @param width 场景宽度.
		 * @param height 场景高度.
		 * @param bubbles 是否冒泡.
		 */
		public function ResizeEvent2D(type:String, width:int, height:int, bubbles:Boolean = false)
		{
			super(type, bubbles);
			_width = width;
			_height = height;
		}
		
		/**
		 * 获取场景宽度.
		 */
		public function get width():int
		{
			return _width;
		}
		
		/**
		 * 获取场景高度.
		 */
		public function get height():int
		{
			return _height;
		}
	}
}

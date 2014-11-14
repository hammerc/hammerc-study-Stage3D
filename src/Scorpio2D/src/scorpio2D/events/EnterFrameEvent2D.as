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
	 * 进入帧事件类, 包含每帧经过的秒数.
	 * @author wizardc
	 */
	public class EnterFrameEvent2D extends Event2D
	{
		/**
		 * 进入新的一帧时抛出.
		 */
		public static const ENTER_FRAME:String = "enterFrame";
		
		private var _passedTime:Number;
		
		/**
		 * 构造函数.
		 * @param type 事件类型.
		 * @param passedTime 每帧经过的秒数.
		 * @param bubbles 是否冒泡.
		 */
		public function EnterFrameEvent2D(type:String, passedTime:Number, bubbles:Boolean = false)
		{
			super(type, bubbles);
			_passedTime = passedTime;
		}
		
		/**
		 * 获取每帧经过的秒数.
		 */
		public function get passedTime():Number
		{
			return _passedTime;
		}
	}
}

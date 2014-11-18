// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio2D.animation
{
	/**
	 * 动画接口.
	 * @author wizardc
	 */
	public interface IAnimatable
	{
		/**
		 * 获取播放是否完成.
		 */
		function get isComplete():Boolean;
		
		/**
		 * 每帧会调用该方法.
		 * @param time 已经流逝的时间 (秒).
		 */
		function advanceTime(time:Number):void;
	}
}

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
	import scorpio2D.core.scorpio2D_internal;
	
	use namespace scorpio2D_internal;
	
	/**
	 * 用于 3D 显示列表的事件类.
	 * @author wizardc
	 */
	public class Event2D
	{
		/**
		 * 添加到容器中时抛出.
		 */
		public static const ADDED:String = "added";
		
		/**
		 * 添加到舞台上时抛出.
		 */
		public static const ADDED_TO_STAGE:String = "addedToStage";
		
		/**
		 * 从容器中移除时抛出.
		 */
		public static const REMOVED:String = "removed";
		
		/**
		 * 从舞台上移除时抛出.
		 */
		public static const REMOVED_FROM_STAGE:String = "removedFromStage";
		
		/**
		 * 完成某项功能时抛出.
		 */
		public static const COMPLETE:String = "complete";
		
		/**
		 * 上下文对象创建时抛出.
		 */
		public static const CONTEXT3D_CREATE:String = "context3DCreate";
		
		/**
		 * 文档类对象创建时抛出.
		 */
		public static const ROOT_CREATED:String = "rootCreated";
		
		/**
		 * 从动画管理器被移除时抛出.
		 */
		public static const REMOVE_FROM_JUGGLER:String = "removeFromJuggler";
		
		/**
		 * 使用平面化时抛出.
		 */
		public static const FLATTEN:String = "flatten";
		
		private var _target:EventDispatcher2D;
		private var _currentTarget:EventDispatcher2D;
		private var _type:String;
		private var _bubbles:Boolean;
		private var _stopsPropagation:Boolean;
		private var _stopsImmediatePropagation:Boolean;
		
		/**
		 * 构造函数.
		 * @param type 事件类型.
		 * @param bubbles 是否冒泡.
		 */
		public function Event2D(type:String, bubbles:Boolean = false)
		{
			_type = type;
			_bubbles = bubbles;
		}
		
		/**
		 * 获取事件类型.
		 */
		public function get type():String
		{
			return _type;
		}
		
		/**
		 * 获取是否冒泡.
		 */
		public function get bubbles():Boolean
		{
			return _bubbles;
		}
		
		/**
		 * 获取目标对象.
		 */
		public function get target():EventDispatcher2D
		{
			return _target;
		}
		
		/**
		 * 获取当前目标对象.
		 */
		public function get currentTarget():EventDispatcher2D
		{
			return _currentTarget;
		}
		
		/**
		 * 设置目标对象.
		 * @param target 目标对象.
		 */
		scorpio2D_internal function setTarget(target:EventDispatcher2D):void
		{
			_target = target;
		}
		
		/**
		 * 设置当前目标对象.
		 * @param currentTarget 当前目标对象.
		 */
		scorpio2D_internal function setCurrentTarget(currentTarget:EventDispatcher2D):void
		{
			_currentTarget = currentTarget;
		}
		
		/**
		 * 获取是否要停止事件冒泡.
		 */
		scorpio2D_internal function get stopsPropagation():Boolean
		{
			return _stopsPropagation;
		}
		
		/**
		 * 获取是否要停止事件冒泡, 同时同级别的事件侦听也一起停止.
		 */
		scorpio2D_internal function get stopsImmediatePropagation():Boolean
		{
			return _stopsImmediatePropagation;
		}
		
		/**
		 * 停止事件冒泡.
		 */
		public function stopPropagation():void
		{
			_stopsPropagation = true;
		}
		
		/**
		 * 停止事件冒泡, 同时同级别的事件侦听也一起停止.
		 */
		public function stopImmediatePropagation():void
		{
			_stopsPropagation = true;
			_stopsImmediatePropagation = true;
		}
	}
}

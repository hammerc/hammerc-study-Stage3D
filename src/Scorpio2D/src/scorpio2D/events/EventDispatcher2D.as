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
	import flash.utils.Dictionary;
	
	import scorpio2D.core.scorpio2D_internal;
	import scorpio2D.display.DisplayObject2D;
	
	use namespace scorpio2D_internal;
	
	/**
	 * 用于 3D 显示列表的事件发送类.
	 * @author wizardc
	 */
	public class EventDispatcher2D
	{
		private var _eventListeners:Dictionary;
		
		/**
		 * 构造函数.
		 */
		public function EventDispatcher2D()
		{
			super();
		}
		
		/**
		 * 抛出事件.
		 * @param event 事件.
		 */
		public function dispatchEvent(event:Event2D):void
		{
			var listeners:Vector.<Function> = _eventListeners ? _eventListeners[event.type] : null;
			//如果当前没有任何侦听同时事件不需要冒泡则可以停止执行
			if(listeners == null && !event.bubbles)
			{
				return;
			}
			//记录下当前的事件目标对象
			var previousTarget:EventDispatcher2D = event.target;
			//如果没有事件目标对象或当前目标对象存在则设置当前对象为事件目标对象, 注意最后会对目标对象进行还原
			if(previousTarget == null || event.currentTarget != null)
			{
				event.setTarget(this);
			}
			//抛出侦听的事件
			var stopImmediatePropagation:Boolean = false;
			var numListeners:int = listeners == null ? 0 : listeners.length;
			if(numListeners != 0)
			{
				//设置当前目标对象
				event.setCurrentTarget(this);
				//抛出事件
				for(var i:int = 0; i < numListeners; ++i)
				{
					listeners[i](event);
					//如果事件被立即终止则跳出循环
					if(event.stopsImmediatePropagation)
					{
						stopImmediatePropagation = true;
						break;
					}
				}
			}
			//判断事件是否可向上进行冒泡
			if(!stopImmediatePropagation && event.bubbles && !event.stopsPropagation && this is DisplayObject2D)
			{
				var targetDisplayObject:DisplayObject2D = this as DisplayObject2D;
				if(targetDisplayObject.parent != null)
				{
					//设置当前目标对象为空
					event.setCurrentTarget(null);
					//事件冒泡
					targetDisplayObject.parent.dispatchEvent(event);
				}
			}
			//还原为第一个抛出的事件目标对象
			if(previousTarget != null)
			{
				event.setTarget(previousTarget);
			}
		}
		
		/**
		 * 添加事件侦听.
		 * @param type 事件类型.
		 * @param listener 侦听方法.
		 */
		public function addEventListener(type:String, listener:Function):void
		{
			if(_eventListeners == null)
			{
				_eventListeners = new Dictionary();
			}
			var listeners:Vector.<Function> = _eventListeners[type] as Vector.<Function>;
			if(listeners == null)
			{
				_eventListeners[type] = new <Function>[listener];
			}
			else
			{
				listeners.push(listener);
			}
		}
		
		/**
		 * 获取是否存在事件侦听.
		 * @param type 事件类型.
		 * @return 是否存在事件侦听.
		 */
		public function hasEventListener(type:String):Boolean
		{
			return _eventListeners != null && type in _eventListeners;
		}
		
		/**
		 * 移除事件侦听.
		 * @param type 事件类型.
		 * @param listener 侦听方法.
		 */
		public function removeEventListener(type:String, listener:Function):void
		{
			if(_eventListeners != null)
			{
				var listeners:Vector.<Function> = _eventListeners[type] as Vector.<Function>;
				listeners = listeners.filter(
						function(item:Function, ...rest):Boolean
						{
							return item != listener;
						}
				);
				if(listeners.length == 0)
				{
					delete _eventListeners[type];
				}
				else
				{
					_eventListeners[type] = listeners;
				}
			}
		}
		
		/**
		 * 移除指定类型的所有事件侦听.
		 * @param type 事件类型, 为空则表示移除全部侦听.
		 */
		public function removeEventListeners(type:String = null):void
		{
			if(type && _eventListeners != null)
			{
				delete _eventListeners[type];
			}
			else
			{
				_eventListeners = null;
			}
		}
	}
}

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
	 * 动画控制器类.
	 * @author wizardc
	 */
	public class Juggler implements IAnimatable
	{
		private var _objects:Array;
		private var _elapsedTime:Number;
		
		/**
		 * 构造函数.
		 */
		public function Juggler()
		{
			_elapsedTime = 0;
			_objects = [];
		}
		
		/**
		 * 获取截止到目前的存活时间累计.
		 */
		public function get elapsedTime():Number
		{
			return _elapsedTime;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get isComplete():Boolean
		{
			return false;
		}
		
		/**
		 * 添加一个动画对象.
		 * @param object 动画对象.
		 */
		public function add(object:IAnimatable):void
		{
			if(object != null)
			{
				_objects.push(object);
			}
		}
		
		/**
		 * 移除一个动画对象.
		 * @param object 动画对象.
		 */
		public function remove(object:IAnimatable):void
		{
			_objects = _objects.filter(
				function(currentObject:Object, index:int, array:Array):Boolean
				{
					return object != currentObject;
				}
			);
		}
		
		/**
		 * 一次性删除所有的对象.
		 */
		public function purge():void
		{
			_objects = [];
		}
		
		/**
		 * @inheritDoc
		 */
		public function advanceTime(time:Number):void
		{
			_elapsedTime += time;
			var objectCopy:Array = _objects.concat();
			for each(var currentObject:IAnimatable in objectCopy)
			{
				currentObject.advanceTime(time);
			}
			_objects = _objects.filter(
				function(object:IAnimatable, index:int, array:Array):Boolean
				{
					return !object.isComplete;
				}
			);
		}
	}
}

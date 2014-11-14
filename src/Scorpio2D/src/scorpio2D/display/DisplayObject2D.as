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
	import flash.utils.getQualifiedClassName;
	
	import scorpio2D.core.RenderSupport;
	import scorpio2D.core.scorpio2D_internal;
	import scorpio2D.events.Event2D;
	import scorpio2D.events.EventDispatcher2D;
	
	use namespace scorpio2D_internal;
	
	/**
	 * 显示对象抽象基类.
	 * @author wizardc
	 */
	public class DisplayObject2D extends EventDispatcher2D
	{
		private var _name:String;
		private var _parent:DisplayObjectContainer2D;
		
		private var _x:Number = 0;
		private var _y:Number = 0;
		private var _pivotX:Number = 0;
		private var _pivotY:Number = 0;
		private var _scaleX:Number = 1;
		private var _scaleY:Number = 1;
		private var _rotation:Number = 0;
		private var _alpha:Number = 1;
		private var _visible:Boolean = true;
		
		/**
		 * 构造函数.
		 */
		public function DisplayObject2D()
		{
			if(getQualifiedClassName(this) == "scorpio2D.display::DisplayObject2D")
			{
				throw new Error("DisplayObject2D is a abstract class");
			}
		}
		
		/**
		 * 获取父层对象.
		 */
		public function get parent():DisplayObjectContainer2D
		{
			return _parent;
		}
		
		/**
		 * 获取可以遍历到的最顶级的显示对象.
		 */
		public function get root():DisplayObject2D
		{
			var currentObject:DisplayObject2D = this;
			while(currentObject.parent != null)
			{
				currentObject = currentObject.parent;
			}
			return currentObject;
		}
		
		/**
		 * 获取当前 Stage2D 对象, 可能为空.
		 */
		public function get stage():Stage2D
		{
			return this.root as Stage2D;
		}
		
		/**
		 * 设置或获取显示对象的名称.
		 */
		public function set name(value:String):void
		{
			_name = value;
		}
		public function get name():String
		{
			return _name;
		}
		
		/**
		 * 设置或获取这个对象相对于它的父级的局部坐标系的 x 坐标值.
		 */
		public function set x(value:Number):void
		{
			_x = value;
		}
		public function get x():Number
		{
			return _x;
		}
		
		/**
		 * 设置或获取这个对象相对于它的父级的局部坐标系的 y 坐标值.
		 */
		public function set y(value:Number):void
		{
			_y = value;
		}
		public function get y():Number
		{
			return _y;
		}
		
		/**
		 * 设置或获取对象在自己的坐标系的起始 x 坐标点.
		 */
		public function set pivotX(value:Number):void
		{
			_pivotX = value;
		}
		public function get pivotX():Number
		{
			return _pivotX;
		}
		
		/**
		 * 设置或获取对象在自己的坐标系的起始 y 坐标点.
		 */
		public function set pivotY(value:Number):void
		{
			_pivotY = value;
		}
		public function get pivotY():Number
		{
			return _pivotY;
		}
		
		/**
		 * 设置或获取横向缩放参数.
		 */
		public function set scaleX(value:Number):void
		{
			_scaleX = value;
		}
		public function get scaleX():Number
		{
			return _scaleX;
		}
		
		/**
		 * 设置或获取垂直缩放参数.
		 */
		public function set scaleY(value:Number):void
		{
			_scaleY = value;
		}
		public function get scaleY():Number
		{
			return _scaleY;
		}
		
		/**
		 * 设置或获取旋转弧度, 特别注意的是角度值都是用弧度值来表示的.
		 */
		public function set rotation(value:Number):void
		{
			while(value < -Math.PI)
			{
				value += Math.PI * 2;
			}
			while(value > Math.PI)
			{
				value -= Math.PI * 2;
			}
			_rotation = value;
		}
		public function get rotation():Number
		{
			return _rotation;
		}
		
		/**
		 * 设置或获取透明度.
		 */
		public function set alpha(value:Number):void
		{
			_alpha = Math.max(0.0, Math.min(1.0, value));
		}
		public function get alpha():Number
		{
			return _alpha;
		}
		
		/**
		 * 设置或获取可见性.
		 */
		public function set visible(value:Boolean):void
		{
			_visible = value;
		}
		public function get visible():Boolean
		{
			return _visible;
		}
		
		/**
		 * 设置父层对象.
		 * @param value 父层对象.
		 */
		scorpio2D_internal function setParent(value:DisplayObjectContainer2D):void
		{
			_parent = value;
		}
		
		/**
		 * 所有的子项 (包括自身) 都抛出指定的事件.
		 * @param event 事件对象.
		 */
		scorpio2D_internal function dispatchEventOnChildren(event:Event2D):void
		{
			this.dispatchEvent(event);
		}
		
		/**
		 * 从这个对象的父级删除这个对象, 如果父级存在.
		 * @param dispose 是否销毁.
		 */
		public function removeFromParent(dispose:Boolean = false):void
		{
			if(_parent != null)
			{
				_parent.removeChild(this);
			}
			if(dispose)
			{
				this.dispose();
			}
		}
		
		/**
		 * 渲染本对象.
		 * 永远不要直接调用这个方法，除非是从另一个渲染方法调用的.
		 * @param support 为渲染提供实用功能.
		 * @param alpha 从这个对象的父级到 stage 的透明度累加值.
		 */
		public function render(support:RenderSupport, alpha:Number):void
		{
			throw new Error("render is a abstract function");
		}
		
		/**
		 * 销毁显示对象的所有资源, 释放显卡缓存, 删除事件侦听.
		 */
		public function dispose():void
		{
			this.removeEventListeners();
		}
	}
}

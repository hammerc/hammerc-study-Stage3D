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
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
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
		 * 设置或获取宽度.
		 */
		public function set width(value:Number):void
		{
			_scaleX = 1.0;
			var actualWidth:Number = this.width;
			if(actualWidth != 0)
			{
				this.scaleX = value / actualWidth;
			}
			else
			{
				this.scaleX = 1;
			}
		}
		public function get width():Number
		{
			return this.getBounds(_parent).width;
		}
		
		/**
		 * 设置或获取高度.
		 */
		public function set height(value:Number):void
		{
			_scaleY = 1;
			var actualHeight:Number = this.height;
			if(actualHeight != 0)
			{
				this.scaleY = value / actualHeight;
			}
			else
			{
				this.scaleY = 1;
			}
		}
		public function get height():Number
		{
			return this.getBounds(_parent).height;
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
		 * 获取这个对象相对于它的父级的变换矩阵.
		 */
		public function get transformationMatrix():Matrix
		{
			var matrix:Matrix = new Matrix();
			if(_pivotX != 0 || _pivotY != 0)
			{
				matrix.translate(-_pivotX, -_pivotY);
			}
			if(_scaleX != 1 || _scaleY != 1)
			{
				matrix.scale(_scaleX, _scaleY);
			}
			if(_rotation != 0)
			{
				matrix.rotate(_rotation);
			}
			if(_x != 0 || _y != 0)
			{
				matrix.translate(_x, _y);
			}
			return matrix;
		}
		
		/**
		 * 获取这个对象相对于它的父级坐标系的矩形区域.
		 */
		public function get bounds():Rectangle
		{
			return this.getBounds(_parent);
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
		 * 获取从一个局部坐标系到另一个坐标系的转换.
		 * @param targetSpace 目标.
		 * @return 一个局部坐标系到另一个坐标系的转换.
		 */
		public function getTransformationMatrix(targetSpace:DisplayObject2D):Matrix
		{
			var rootMatrix:Matrix;
			var targetMatrix:Matrix;
			if(targetSpace == this)
			{
				return new Matrix();
			}
			else if(targetSpace == null)
			{
				//为空则遍历到 root
				rootMatrix = new Matrix();
				currentObject = this;
				while(currentObject != null)
				{
					rootMatrix.concat(currentObject.transformationMatrix);
					currentObject = currentObject.parent;
				}
				return rootMatrix;
			}
			else if(targetSpace._parent == this)//如果目标是子项可以优化, 反转矩阵即可
			{
				targetMatrix = targetSpace.transformationMatrix;
				targetMatrix.invert();
				return targetMatrix;
			}
			else if(targetSpace == _parent)//如果目标是父级也可以优化
			{
				return this.transformationMatrix;
			}
			//1.寻找当前对象和目标对象的共同父级对象
			var ancestors:Vector.<DisplayObject2D> = new <DisplayObject2D>[];
			var commonParent:DisplayObject2D = null;
			var currentObject:DisplayObject2D = this;
			while(currentObject != null)
			{
				ancestors.push(currentObject);
				currentObject = currentObject.parent;
			}
			currentObject = targetSpace;
			while(currentObject != null && ancestors.indexOf(currentObject) == -1)
			{
				currentObject = currentObject.parent;
			}
			if(currentObject == null)
			{
				throw new ArgumentError("Object not connected to target");
			}
			else
			{
				commonParent = currentObject;
			}
			//2.获取当前对象到父级对象的转换矩阵
			rootMatrix = new Matrix();
			currentObject = this;
			while(currentObject != commonParent)
			{
				rootMatrix.concat(currentObject.transformationMatrix);
				currentObject = currentObject.parent;
			}
			//3.获取目标对象到父级对象的转换矩阵
			targetMatrix = new Matrix();
			currentObject = targetSpace;
			while(currentObject != commonParent)
			{
				targetMatrix.concat(currentObject.transformationMatrix);
				currentObject = currentObject.parent;
			}
			//4.合并矩阵获得最终结果
			targetMatrix.invert();//targetMatrix矩阵是从下到上遍历的需要反转
			rootMatrix.concat(targetMatrix);
			return rootMatrix;
		}
		
		/**
		 * 将一个坐标点从局部坐标系转换到全局 (stage) 坐标系.
		 * @param localPoint 坐标点.
		 * @return 坐标点.
		 */
		public function localToGlobal(localPoint:Point):Point
		{
			var transformationMatrix:Matrix = new Matrix();
			var currentObject:DisplayObject2D = this;
			while(currentObject != null)
			{
				transformationMatrix.concat(currentObject.transformationMatrix);
				currentObject = currentObject.parent;
			}
			return transformationMatrix.transformPoint(localPoint);
		}
		
		/**
		 * 将一个坐标点从全局 (stage) 坐标系转换到局部坐标系.
		 * @param globalPoint 坐标点.
		 * @return 坐标点.
		 */
		public function globalToLocal(globalPoint:Point):Point
		{
			var transformationMatrix:Matrix = new Matrix();
			var currentObject:DisplayObject2D = this;
			while(currentObject != null)
			{
				transformationMatrix.concat(currentObject.transformationMatrix);
				currentObject = currentObject.parent;
			}
			//矩阵是从下到上遍历的所以需要反转
			transformationMatrix.invert();
			return transformationMatrix.transformPoint(globalPoint);
		}
		
		/**
		 * 如果一个对象出现在其它坐标系, 需要用这个方法返回围绕这个对象的一个四边形的区域.
		 * @param targetSpace 目标.
		 * @return 这个对象的一个四边形的区域.
		 */
		public function getBounds(targetSpace:DisplayObject2D):Rectangle
		{
			throw new Error("getBounds is a abstract function");
			return null;
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

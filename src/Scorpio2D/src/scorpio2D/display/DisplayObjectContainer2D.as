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
	
	use namespace scorpio2D_internal;
	
	/**
	 * 显示容器抽象基类.
	 * @author wizardc
	 */
	public class DisplayObjectContainer2D extends DisplayObject2D
	{
		private var _children:Vector.<DisplayObject2D>;
		
		/**
		 * 构造函数.
		 */
		public function DisplayObjectContainer2D()
		{
			if(getQualifiedClassName(this) == "scorpio2D.display::DisplayObjectContainer2D")
			{
				throw new Error("DisplayObjectContainer2D is a abstract class");
			}
			_children = new <DisplayObject2D>[];
		}
		
		/**
		 * 获取子项数量.
		 */
		public function get numChildren():int
		{
			return _children.length;
		}
		
		/**
		 * 添加一个对象到容器, 它将处于顶层.
		 * @param child 要添加的子项.
		 */
		public function addChild(child:DisplayObject2D):void
		{
			this.addChildAt(child, this.numChildren);
		}
		
		/**
		 * 根据一个索引值添加一个对象到容器.
		 * @param child 要添加的子项.
		 * @param index 索引.
		 */
		public function addChildAt(child:DisplayObject2D, index:int):void
		{
			if(index >= 0 && index <= this.numChildren)
			{
				child.removeFromParent();
				_children.splice(index, 0, child);
				child.setParent(this);
				child.dispatchEvent(new Event2D(Event2D.ADDED));
				if(this.stage != null)
				{
					child.dispatchEventOnChildren(new Event2D(Event2D.ADDED_TO_STAGE));
				}
			}
			else
			{
				throw new RangeError("Invalid child index");
			}
		}
		
		/**
		 * 根据指定的索引返回一个子级显示对象.
		 * @param index 索引.
		 * @return 子级显示对象.
		 */
		public function getChildAt(index:int):DisplayObject2D
		{
			if(index >= 0 && index < numChildren)
			{
				return _children[index];
			}
			else
			{
				throw new RangeError("Invalid child index");
			}
		}
		
		/**
		 * 根据一个指定的名称(非递归)返回一个子级显示对象.
		 * @param name 指定的名称.
		 * @return 子级显示对象.
		 */
		public function getChildByName(name:String):DisplayObject2D
		{
			for each(var currentChild:DisplayObject2D in _children)
			{
				if(currentChild.name == name)
				{
					return currentChild;
				}
			}
			return null;
		}
		
		/**
		 * 判断是否包含指定的显示对象, 会处理所有子项以及子项的子项.
		 * @param child 子级显示对象.
		 * @return 是否存在.
		 */
		public function contains(child:DisplayObject2D):Boolean
		{
			if(child == this)
			{
				return true;
			}
			for each(var currentChild:DisplayObject2D in _children)
			{
				if(currentChild is DisplayObjectContainer2D)
				{
					if((currentChild as DisplayObjectContainer2D).contains(child))
					{
						return true;
					}
				}
				else
				{
					if(currentChild == child)
					{
						return true;
					}
				}
			}
			return false;
		}
		
		/**
		 * 获取一个子级在它的容器中的索引, 如果没找到, 返回 -1.
		 * @param child 子级显示对象.
		 * @return 索引.
		 */
		public function getChildIndex(child:DisplayObject2D):int
		{
			return _children.indexOf(child);
		}
		
		/**
		 * 移动一个子级到指定的索引.
		 * @param child 子级显示对象.
		 * @param index 索引.
		 */
		public function setChildIndex(child:DisplayObject2D, index:int):void
		{
			var oldIndex:int = this.getChildIndex(child);
			if(oldIndex == -1)
			{
				throw new ArgumentError("Not a child of this container");
			}
			_children.splice(oldIndex, 1);
			_children.splice(index, 0, child);
		}
		
		/**
		 * 互换两个子级的索引.
		 * @param child1 子级显示对象1.
		 * @param child2 子级显示对象2.
		 */
		public function swapChildren(child1:DisplayObject2D, child2:DisplayObject2D):void
		{
			var index1:int = this.getChildIndex(child1);
			var index2:int = this.getChildIndex(child2);
			if(index1 == -1 || index2 == -1)
			{
				throw new ArgumentError("Not a child of this container");
			}
			this.swapChildrenAt(index1, index2);
		}
		
		/**
		 * 互换两个子级的索引.
		 * @param index1 索引1.
		 * @param index2 索引2.
		 */
		public function swapChildrenAt(index1:int, index2:int):void
		{
			var child1:DisplayObject2D = this.getChildAt(index1);
			var child2:DisplayObject2D = this.getChildAt(index2);
			_children[index1] = child2;
			_children[index2] = child1;
		}
		
		/**
		 * 从容器中删除一个子级.
		 * @param child 子级显示对象.
		 * @param dispose 是否释放子级的资源.
		 */
		public function removeChild(child:DisplayObject2D, dispose:Boolean = false):void
		{
			var childIndex:int = this.getChildIndex(child);
			if(childIndex != -1)
			{
				this.removeChildAt(childIndex, dispose);
			}
		}
		
		/**
		 * 根据特定的索引值, 删除一个子级.
		 * @param index 索引.
		 * @param dispose 是否释放子级的资源.
		 */
		public function removeChildAt(index:int, dispose:Boolean = false):void
		{
			if(index >= 0 && index < this.numChildren)
			{
				var child:DisplayObject2D = _children[index];
				child.dispatchEvent(new Event2D(Event2D.REMOVED));
				if(this.stage != null)
				{
					child.dispatchEventOnChildren(new Event2D(Event2D.REMOVED_FROM_STAGE));
				}
				child.setParent(null);
				_children.splice(index, 1);
				if(dispose)
				{
					child.dispose();
				}
			}
			else
			{
				throw new RangeError("Invalid child index");
			}
		}
		
		/**
		 * 根据选定的范围删除容器中的一组子级 (包含结束索引). 如果没有传递参数, 则所有的子级都会被删除.
		 * @param beginIndex 起始索引.
		 * @param endIndex 结束索引.
		 * @param dispose 是否释放子级的资源.
		 */
		public function removeChildren(beginIndex:int = 0, endIndex:int = -1, dispose:Boolean = false):void
		{
			if(endIndex < 0 || endIndex >= this.numChildren)
			{
				endIndex = this.numChildren - 1;
			}
			for(var i:int = beginIndex; i <= endIndex; ++i)
			{
				this.removeChildAt(beginIndex, dispose);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override scorpio2D_internal function dispatchEventOnChildren(event:Event2D):void
		{
			var listeners:Vector.<DisplayObject2D> = new <DisplayObject2D>[];
			//获取所有子项 (递归获取) 注册了指定类型的显示对象
			getChildEventListeners(this, event.type, listeners);
			//抛出事件
			for each(var listener:DisplayObject2D in listeners)
			{
				listener.dispatchEvent(event);
			}
		}
		
		private function getChildEventListeners(object:DisplayObject2D, eventType:String, listeners:Vector.<DisplayObject2D>):void
		{
			var container:DisplayObjectContainer2D = object as DisplayObjectContainer2D;
			if(object.hasEventListener(eventType))
			{
				listeners.push(object);
			}
			if(container != null)
			{
				for each(var child:DisplayObject2D in container._children)
				{
					getChildEventListeners(child, eventType, listeners);
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function render(support:RenderSupport, alpha:Number):void
		{
			//上层的透明度和当前的透明度相乘
			alpha *= this.alpha;
			//处理所有子项
			for each(var child:DisplayObject2D in _children)
			{
				//如果该子项需要进行渲染
				if(child.alpha != 0 && child.visible && child.scaleX != 0 && child.scaleY != 0)
				{
					//保存当前的矩阵信息, 留给其它子项使用
					support.pushMatrix();
					//转换矩阵, 获得添加了子项的矩阵信息
					support.transformMatrix(child);
					//渲染子项
					child.render(support, alpha);
					//还原矩阵信息为处理子项之前
					support.popMatrix();
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public override function dispose():void
		{
			for each(var child:DisplayObject2D in _children)
			{
				child.dispose();
			}
			super.dispose();
		}
	}
}

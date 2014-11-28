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
	import flash.geom.Matrix3D;
	
	import scorpio2D.core.RenderSupport;
	import scorpio2D.core.Scorpio2D;
	import scorpio2D.core.scorpio2D_internal;
	import scorpio2D.events.Event2D;
	
	use namespace scorpio2D_internal;
	
	/**
	 * 最轻量级的容器类.
	 * @author wizardc
	 */
	public class Sprite2D extends DisplayObjectContainer2D
	{
		private var _flattenedContents:Vector.<QuadBatch>;
		
		/**
		 * 构造函数.
		 */
		public function Sprite2D()
		{
			super();
		}
		
		/**
		 * 获取是不是扁平化.
		 */
		public function get isFlattened():Boolean
		{
			return _flattenedContents != null;
		}
		
		/**
		 * 优化得到最佳的渲染性能.
		 * 一个被扁平化的 Sprite, 如果改变它的子级, 是不会有任何的显示更新的.
		 */
		public function flatten():void
		{
			this.dispatchEventOnChildren(new Event2D(Event2D.FLATTEN));
			if(_flattenedContents == null)
			{
				_flattenedContents = new <QuadBatch>[];
				Scorpio2D.current.addEventListener(Event2D.CONTEXT3D_CREATE, onContextCreated);
			}
			QuadBatch.compile(this, _flattenedContents);
		}
		
		/**
		 * 取消对这个扁平化的 Sprite 的渲染优化.
		 * 这个时候再改变 Sprite 的子级, 就会有直接的显示变化了.
		 */
		public function unflatten():void
		{
			if(_flattenedContents != null)
			{
				Scorpio2D.current.removeEventListener(Event2D.CONTEXT3D_CREATE, onContextCreated);
				var numBatches:int = _flattenedContents.length;
				for (var i:int = 0; i < numBatches; ++i)
				{
					_flattenedContents[i].dispose();
				}
				_flattenedContents = null;
			}
		}
		
		private function onContextCreated(event:Event2D):void
		{
			if (_flattenedContents)
			{
				_flattenedContents = new <QuadBatch>[];
				this.flatten();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			if(_flattenedContents != null)
			{
				support.finishQuadBatch();
				var alpha:Number = parentAlpha * this.alpha;
				var numBatches:int = _flattenedContents.length;
				var mvpMatrix:Matrix3D = support.mvpMatrix;
				for(var i:int = 0; i < numBatches; ++i)
				{
					var quadBatch:QuadBatch = _flattenedContents[i];
					var blendMode:String = quadBatch.blendMode == BlendMode2D.AUTO ? support.blendMode : quadBatch.blendMode;
					quadBatch.renderCustom(mvpMatrix, alpha, blendMode);
				}
			}
			else
			{
				super.render(support, parentAlpha);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public override function dispose():void
		{
			this.unflatten();
			super.dispose();
		}
	}
}

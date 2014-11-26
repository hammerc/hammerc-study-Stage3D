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
	import flash.geom.Vector3D;
	
	import scorpio2D.core.RenderSupport;
	import scorpio2D.core.scorpio2D_internal;
	import scorpio2D.utils.VertexData;
	
	use namespace scorpio2D_internal;
	
	/**
	 * 一个四边形(Quad)代表了一个单一颜色或渐变颜色的矩形.
	 * 您可以设置每一个顶点的颜色.
	 * 顶点位置是这样安排的:
	 * <pre>
	 * 0 - 1
	 * | / |
	 * 2 - 3
	 * </pre>
	 * @author wizardc
	 */
	public class Quad2D extends DisplayObject2D
	{
		private static var _helperVector:Vector3D = new Vector3D();
		
		//顶点数据
		protected var _vertexData:VertexData;
		//true 表示顶点即不是白色也不是透明
		private var _tinted:Boolean;
		
		/**
		 * 构造函数.
		 * @param width 高度.
		 * @param height 宽度.
		 * @param color 颜色.
		 * @param premultipliedAlpha 是否预乘透明度.
		 */
		public function Quad2D(width:Number, height:Number, color:uint = 0xffffff, premultipliedAlpha:Boolean = true)
		{
			_vertexData = new VertexData(4, premultipliedAlpha);
			_vertexData.setPosition(0, 0.0, 0.0);
			_vertexData.setPosition(1, width, 0.0);
			_vertexData.setPosition(2, 0.0, height);
			_vertexData.setPosition(3, width, height);
			_vertexData.setUniformColor(color);
			_tinted = color != 0xffffff;
			this.onVertexDataChanged();
		}
		
		/**
		 * 获取顶点数据.
		 */
		public function get vertexData():VertexData
		{
			return _vertexData.clone();
		}
		
		/**
		 * 设置或获取颜色.
		 */
		public function set color(value:uint):void
		{
			for(var i:int = 0; i < 4; ++i)
			{
				this.setVertexColor(i, value);
			}
			if(this.color != 0xffffff)
			{
				_tinted = true;
			}
			else
			{
				_tinted = _vertexData.tinted;
			}
		}
		public function get color():uint
		{
			return _vertexData.getColor(0);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set alpha(value:Number):void
		{
			super.alpha = value;
			if(this.alpha != 1)
			{
				_tinted = true;
			}
			else
			{
				_tinted = _vertexData.tinted;
			}
		}
		
		/**
		 * 获取顶点是否不为白色或不透明.
		 */
		scorpio2D_internal function get tinted():Boolean
		{
			return _tinted;
		}
		
		/**
		 * 设置指定顶点的颜色.
		 * @param vertexID 顶点索引.
		 * @param color 颜色.
		 */
		public function setVertexColor(vertexID:int, color:uint):void
		{
			_vertexData.setColor(vertexID, color);
			this.onVertexDataChanged();
			if(color != 0xffffff)
			{
				_tinted = true;
			}
			else
			{
				_tinted = _vertexData.tinted;
			}
		}
		
		/**
		 * 获取指定顶点的颜色.
		 * @param vertexID 顶点索引.
		 * @return 颜色.
		 */
		public function getVertexColor(vertexID:int):uint
		{
			return _vertexData.getColor(vertexID);
		}
		
		/**
		 * 设置指定顶点的透明度.
		 * @param vertexID 顶点索引.
		 * @param alpha 透明度.
		 */
		public function setVertexAlpha(vertexID:int, alpha:Number):void
		{
			_vertexData.setAlpha(vertexID, alpha);
			this.onVertexDataChanged();
			if(alpha != 1)
			{
				_tinted = true;
			}
			else
			{
				_tinted = _vertexData.tinted;
			}
		}
		
		/**
		 * 获取指定顶点的透明度.
		 * @param vertexID 顶点索引.
		 * @return 透明度.
		 */
		public function getVertexAlpha(vertexID:int):Number
		{
			return _vertexData.getAlpha(vertexID);
		}
		
		/**
		 * 顶点数据改变时回调该方法.
		 */
		protected function onVertexDataChanged():void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		override public function render(support:RenderSupport, alpha:Number):void
		{
			support.batchQuad(this, alpha);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function getBounds(targetSpace:DisplayObject2D):Rectangle
		{
			var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
			var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
			var i:int;
			if(targetSpace == this)
			{
				for(i = 0; i < 4; ++i)
				{
					_vertexData.getPosition(i, _helperVector);
					minX = Math.min(minX, _helperVector.x);
					maxX = Math.max(maxX, _helperVector.x);
					minY = Math.min(minY, _helperVector.y);
					maxY = Math.max(maxY, _helperVector.y);
				}
			}
			else
			{
				var transformationMatrix:Matrix = this.getTransformationMatrix(targetSpace);
				var point:Point = new Point();
				for(i = 0; i < 4; ++i)
				{
					_vertexData.getPosition(i, _helperVector);
					point.x = _helperVector.x;
					point.y = _helperVector.y;
					var transformedPoint:Point = transformationMatrix.transformPoint(point);
					minX = Math.min(minX, transformedPoint.x);
					maxX = Math.max(maxX, transformedPoint.x);
					minY = Math.min(minY, transformedPoint.y);
					maxY = Math.max(maxY, transformedPoint.y);
				}
			}
			return new Rectangle(minX, minY, maxX - minX, maxY - minY);
		}
		
		/**
		 * 拷贝顶点数据到一个新的顶点数据实例.
		 * @param targetData 目标对象.
		 * @param targetVertexID 索引.
		 */
		public function copyVertexDataTo(targetData:VertexData, targetVertexID:int = 0):void
		{
			_vertexData.copyTo(targetData, targetVertexID);
		}
	}
}

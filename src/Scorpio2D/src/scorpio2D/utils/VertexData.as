// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio2D.utils
{
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	/**
	 * 包含多个顶点数据的管理类.
	 * 该类管理的顶点数据格式是为 2D 框架特别设计的.
	 * 顶点格式如下：
	 * x, y, z, r, g, b, a, u, v
	 * @author wizardc
	 */
	public class VertexData
	{
		/**
		 * 每个顶点存储的数据数量.
		 */
		public static const ELEMENTS_PER_VERTEX:int = 9;
		
		/**
		 * 位置数据的偏移量.
		 */
		public static const POSITION_OFFSET:int = 0;
		
		/**
		 * 颜色数据的偏移量.
		 */
		public static const COLOR_OFFSET:int = 3;
		
		/**
		 * 纹理坐标的偏移量.
		 */
		public static const TEXCOORD_OFFSET:int = 7;
		
		private var _data:Vector.<Number>;
		private var _premultipliedAlpha:Boolean;
		
		/**
		 * 构造函数.
		 * @param numVertices 包含顶点的数量.
		 * @param premultipliedAlpha 是否预乘透明度.
		 */
		public function VertexData(numVertices:int, premultipliedAlpha:Boolean = false)
		{
			_data = new Vector.<Number>(numVertices * ELEMENTS_PER_VERTEX, true);
			_premultipliedAlpha = premultipliedAlpha;
		}
		
		/**
		 * 获取最终的顶点数据.
		 */
		public function get data():Vector.<Number>
		{
			return _data;
		}
		
		/**
		 * 获取当前存储的顶点数量.
		 */
		public function get numVertices():int
		{
			return _data.length / ELEMENTS_PER_VERTEX;
		}
		
		/**
		 * 设置或获取是否预乘透明度.
		 * 该属性影响顶点中的 rgb 3个颜色值, 设置为 true 表示将这 3 个颜色值分别乘于 (透明度 / 255) 的值.
		 */
		public function set premultipliedAlpha(value:Boolean):void
		{
			if(_premultipliedAlpha == value)
			{
				return;
			}
			var dataLength:int = _data.length;
			for(var i:int = COLOR_OFFSET; i < dataLength; i += ELEMENTS_PER_VERTEX)
			{
				var alpha:Number = _data[i + 3];
				var divisor:Number = _premultipliedAlpha ? alpha : 1;
				var multiplier:Number = value ? alpha : 1;
				if(divisor != 0)
				{
					_data[i] = _data[i] / divisor * multiplier;
					_data[i + 1] = _data[i + 1] / divisor * multiplier;
					_data[i + 2] = _data[i + 2] / divisor * multiplier;
				}
			}
			_premultipliedAlpha = value;
		}
		public function get premultipliedAlpha():Boolean
		{
			return _premultipliedAlpha;
		}
		
		/**
		 * 设置坐标.
		 * @param vertexID 顶点索引.
		 * @param x x.
		 * @param y y.
		 * @param z x.
		 */
		public function setPosition(vertexID:int, x:Number, y:Number, z:Number = 0):void
		{
			setValues(getOffset(vertexID) + POSITION_OFFSET, x, y, z);
		}
		
		/**
		 * 获取坐标.
		 * @param vertexID 顶点索引.
		 * @return 坐标数据.
		 */
		public function getPosition(vertexID:int):Vector3D
		{
			var offset:int = getOffset(vertexID) + POSITION_OFFSET;
			return new Vector3D(_data[offset], _data[offset + 1], _data[offset + 2]);
		}
		
		/**
		 * 设置颜色.
		 * @param vertexID 顶点索引.
		 * @param color 颜色.
		 * @param alpha 透明度.
		 */
		public function setColor(vertexID:int, color:uint, alpha:Number = 1):void
		{
			var multiplier:Number = _premultipliedAlpha ? alpha : 1;
			setValues(getOffset(vertexID) + COLOR_OFFSET, Color.getRed(color) / 255 * multiplier, Color.getGreen(color) / 255 * multiplier, Color.getBlue(color) / 255 * multiplier, alpha);
		}
		
		/**
		 * 获取颜色.
		 * @param vertexID 顶点索引.
		 * @return 颜色值, 不包含 alpha.
		 */
		public function getColor(vertexID:int):uint
		{
			var offset:int = getOffset(vertexID) + COLOR_OFFSET;
			var divisor:Number = _premultipliedAlpha ? _data[offset + 3] : 1;
			if(divisor == 0)
			{
				return 0;
			}
			else
			{
				var red:Number = _data[offset] / divisor;
				var green:Number = _data[offset + 1] / divisor;
				var blue:Number = _data[offset + 2] / divisor;
				return Color.rgb(red * 255, green * 255, blue * 255);
			}
		}
		
		/**
		 * 设置透明度.
		 * @param vertexID 顶点索引.
		 * @param alpha 透明度.
		 */
		public function setAlpha(vertexID:int, alpha:Number):void
		{
			if(_premultipliedAlpha)
			{
				setColor(vertexID, getColor(vertexID), alpha);
			}
			else
			{
				var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
				_data[offset] = alpha;
			}
		}
		
		/**
		 * 获取透明度.
		 * @param vertexID 顶点索引.
		 * @return 透明度.
		 */
		public function getAlpha(vertexID:int):Number
		{
			var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
			return _data[offset];
		}
		
		/**
		 * 设置纹理坐标.
		 * @param vertexID 顶点索引.
		 * @param u u.
		 * @param v v.
		 */
		public function setTexCoords(vertexID:int, u:Number, v:Number):void
		{
			setValues(getOffset(vertexID) + TEXCOORD_OFFSET, u, v);
		}
		
		/**
		 * 获取纹理坐标.
		 * @param vertexID 顶点索引.
		 * @return 纹理坐标.
		 */
		public function getTexCoords(vertexID:int):Point
		{
			var offset:int = getOffset(vertexID) + TEXCOORD_OFFSET;
			return new Point(_data[offset], _data[offset + 1]);
		}
		
		/**
		 * 偏移顶点位置.
		 * @param vertexID 顶点索引.
		 * @param deltaX 添加的 x.
		 * @param deltaY 添加的 y.
		 * @param deltaZ 添加的 z.
		 */
		public function translateVertex(vertexID:int, deltaX:Number, deltaY:Number, deltaZ:Number = 0):void
		{
			var offset:int = getOffset(vertexID) + POSITION_OFFSET;
			_data[offset] += deltaX;
			_data[offset + 1] += deltaY;
			_data[offset + 2] += deltaZ;
		}
		
		/**
		 * 和转换矩阵相乘, 转换顶点数据.
		 * @param vertexID 顶点索引.
		 * @param matrix 转换矩阵.
		 */
		public function transformVertex(vertexID:int, matrix:Matrix3D = null):void
		{
			var position:Vector3D = getPosition(vertexID);
			if(matrix != null)
			{
				var transPosition:Vector3D = matrix.transformVector(position);
				setPosition(vertexID, transPosition.x, transPosition.y, transPosition.z);
			}
		}
		
		/**
		 * 统一所有顶点数据的颜色值.
		 * @param color 颜色.
		 * @param alpha 透明度.
		 */
		public function setUniformColor(color:uint, alpha:Number = 1):void
		{
			for(var i:int = 0; i < numVertices; ++i)
			{
				setColor(i, color, alpha);
			}
		}
		
		/**
		 * 透明度值和一个增量相乘.
		 * @param vertexID 顶点索引.
		 * @param alpha 相乘的增量.
		 */
		public function scaleAlpha(vertexID:int, alpha:Number):void
		{
			if(_premultipliedAlpha)
			{
				setAlpha(vertexID, getAlpha(vertexID) * alpha);
			}
			else
			{
				var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
				_data[offset] *= alpha;
			}
		}
		
		private function setValues(offset:int, ...values):void
		{
			var numValues:int = values.length;
			for(var i:int = 0; i < numValues; ++i)
			{
				_data[offset + i] = values[i];
			}
		}
		
		private function getOffset(vertexID:int):int
		{
			return vertexID * ELEMENTS_PER_VERTEX;
		}
		
		/**
		 * 添加顶点数据.
		 * @param data 要添加的顶点数据.
		 */
		public function append(data:VertexData):void
		{
			_data.fixed = false;
			for each(var element:Number in data._data)
			{
				_data.push(element);
			}
			_data.fixed = true;
		}
		
		/**
		 * 克隆当前的副本.
		 * @return 克隆后的副本.
		 */
		public function clone():VertexData
		{
			var clone:VertexData = new VertexData(0, _premultipliedAlpha);
			clone._data = _data.concat();
			clone._data.fixed = true;
			return clone;
		}
	}
}

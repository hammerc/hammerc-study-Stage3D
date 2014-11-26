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
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
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
		
		private static var _positions:Vector.<Number> = new Vector.<Number>(12);
		private static var _helperPoint:Point = new Point();
		
		private var _rawData:Vector.<Number>;
		private var _premultipliedAlpha:Boolean;
		private var _numVertices:int;
		
		/**
		 * 构造函数.
		 * @param numVertices 包含顶点的数量.
		 * @param premultipliedAlpha 是否预乘透明度.
		 */
		public function VertexData(numVertices:int, premultipliedAlpha:Boolean = false)
		{
			_rawData = new <Number>[];
			_premultipliedAlpha = premultipliedAlpha;
			this.numVertices = numVertices;
		}
		
		/**
		 * 获取最终的顶点数据.
		 */
		public function get rawData():Vector.<Number>
		{
			return _rawData;
		}
		
		/**
		 * 设置或获取当前存储的顶点数量.
		 */
		public function set numVertices(value:int):void
		{
			_rawData.fixed = false;
			var i:int;
			var delta:int = value - _numVertices;
			for(i = 0; i < delta; ++i)
			{
				_rawData.push(0, 0, 0, 0, 0, 0, 1, 0, 0);
			}
			for(i = 0; i < -(delta * ELEMENTS_PER_VERTEX); ++i)
			{
				_rawData.pop();
			}
			_numVertices = value;
			_rawData.fixed = true;
		}
		public function get numVertices():int
		{
			return _numVertices;
		}
		
		/**
		 * 获取是否预乘透明度.
		 */
		public function get premultipliedAlpha():Boolean
		{
			return _premultipliedAlpha;
		}
		
		/**
		 * 获取所有顶点是否非白或完全透明.
		 */
		public function get tinted():Boolean
		{
			var offset:int = COLOR_OFFSET;
			for(var i:int=0; i < _numVertices; ++i)
			{
				for(var j:int = 0; j < 4; ++j)
				{
					if(_rawData[int(offset + j)] != 1)
					{
						return true;
					}
				}
				offset += ELEMENTS_PER_VERTEX;
			}
			return false;
		}
		
		/**
		 * 设置是否预乘透明度.
		 * 该属性影响顶点中的 rgb 3个颜色值, 设置为 true 表示将这 3 个颜色值分别乘于 (透明度 / 255) 的值.
		 * @param value 是否预乘.
		 * @param updateData 是否更新数据.
		 */
		public function setPremultipliedAlpha(value:Boolean, updateData:Boolean = true):void
		{
			if(value == _premultipliedAlpha)
			{
				return;
			}
			if(updateData)
			{
				var dataLength:int = _numVertices * ELEMENTS_PER_VERTEX;
				for(var i:int = COLOR_OFFSET; i < dataLength; i += ELEMENTS_PER_VERTEX)
				{
					var alpha:Number = _rawData[i + 3];
					var divisor:Number = _premultipliedAlpha ? alpha : 1;
					var multiplier:Number = value ? alpha : 1;
					if(divisor != 0)
					{
						_rawData[i] = _rawData[i] / divisor * multiplier;
						_rawData[int(i + 1)] = _rawData[int(i + 1)] / divisor * multiplier;
						_rawData[int(i + 2)] = _rawData[int(i + 2)] / divisor * multiplier;
					}
				}
			}
			_premultipliedAlpha = value;
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
			var offset:int = getOffset(vertexID) + POSITION_OFFSET;
			_rawData[offset] = x;
			_rawData[int(offset + 1)] = y;
			_rawData[int(offset + 2)] = z;
		}
		
		/**
		 * 获取坐标.
		 * @param vertexID 顶点索引.
		 * @param position 坐标数据.
		 */
		public function getPosition(vertexID:int, position:Vector3D):void
		{
			var offset:int = getOffset(vertexID) + POSITION_OFFSET;
			position.x = _rawData[offset];
			position.y = _rawData[int(offset + 1)];
			position.z = _rawData[int(offset + 2)];
		}
		
		/**
		 * 设置颜色.
		 * @param vertexID 顶点索引.
		 * @param color 颜色.
		 * @param alpha 透明度.
		 */
		public function setColor(vertexID:int, color:uint, alpha:Number = 1):void
		{
			var offset:int = getOffset(vertexID) + COLOR_OFFSET;
			var multiplier:Number = _premultipliedAlpha ? _rawData[int(offset + 3)] : 1;
			_rawData[offset] = ((color >> 16) & 0xff) / 255 * multiplier;
			_rawData[int(offset + 1)] = ((color >> 8) & 0xff) / 255 * multiplier;
			_rawData[int(offset + 2)] = ( color & 0xff) / 255 * multiplier;
		}
		
		/**
		 * 获取颜色.
		 * @param vertexID 顶点索引.
		 * @return 颜色值, 不包含 alpha.
		 */
		public function getColor(vertexID:int):uint
		{
			var offset:int = getOffset(vertexID) + COLOR_OFFSET;
			var divisor:Number = _premultipliedAlpha ? _rawData[offset + 3] : 1;
			if(divisor == 0)
			{
				return 0;
			}
			else
			{
				var red:Number = _rawData[offset] / divisor;
				var green:Number = _rawData[offset + 1] / divisor;
				var blue:Number = _rawData[offset + 2] / divisor;
				return (int(red * 255) << 16) | (int(green * 255) << 8) | int(blue * 255);
			}
		}
		
		/**
		 * 设置透明度.
		 * @param vertexID 顶点索引.
		 * @param alpha 透明度.
		 */
		public function setAlpha(vertexID:int, alpha:Number):void
		{
			var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
			if(_premultipliedAlpha)
			{
				if(alpha < 0.001)
				{
					alpha = 0.001;
				}
				var color:uint = this.getColor(vertexID);
				_rawData[offset] = alpha;
				this.setColor(vertexID, color);
			}
			else
			{
				_rawData[offset] = alpha;
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
			return _rawData[offset];
		}
		
		/**
		 * 设置纹理坐标.
		 * @param vertexID 顶点索引.
		 * @param u u.
		 * @param v v.
		 */
		public function setTexCoords(vertexID:int, u:Number, v:Number):void
		{
			var offset:int = getOffset(vertexID) + TEXCOORD_OFFSET;
			_rawData[offset]= u;
			_rawData[int(offset + 1)] = v;
		}
		
		/**
		 * 获取纹理坐标.
		 * @param vertexID 顶点索引.
		 * @param texCoords 纹理坐标.
		 */
		public function getTexCoords(vertexID:int, texCoords:Point):void
		{
			var offset:int = getOffset(vertexID) + TEXCOORD_OFFSET;
			texCoords.x = _rawData[offset];
			texCoords.y = _rawData[int(offset + 1)];
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
			_rawData[offset] += deltaX;
			_rawData[offset + 1] += deltaY;
			_rawData[offset + 2] += deltaZ;
		}
		
		/**
		 * 和转换矩阵相乘, 转换顶点数据.
		 * @param vertexID 顶点索引.
		 * @param matrix 转换矩阵.
		 * @param numVertices 顶点数量.
		 */
		public function transformVertex(vertexID:int, matrix:Matrix3D, numVertices:int = 1):void
		{
			if(numVertices < 0 || vertexID + numVertices > _numVertices)
			{
				numVertices = _numVertices - vertexID;
			}
			var i:int;
			var offset:int = getOffset(vertexID) + POSITION_OFFSET;
			for(i = 0; i < numVertices; ++i)
			{
				_positions[int(3 * i)] = _rawData[offset];
				_positions[int(3 * i + 1)] = _rawData[int(offset + 1)];
				_positions[int(3 * i + 2)] = _rawData[int(offset + 2)];
				offset += ELEMENTS_PER_VERTEX;
			}
			matrix.transformVectors(_positions, _positions);
			offset -= ELEMENTS_PER_VERTEX * numVertices;
			for(i = 0; i < numVertices; ++i)
			{
				_rawData[offset] = _positions[int(3 * i)];
				_rawData[int(offset + 1)] = _positions[int(3 * i + 1)];
				_rawData[int(offset + 2)] = _positions[int(3 * i + 2)];
				offset += ELEMENTS_PER_VERTEX;
			}
		}
		
		/**
		 * 统一所有顶点数据的颜色值.
		 * @param color 颜色.
		 */
		public function setUniformColor(color:uint):void
		{
			for(var i:int = 0; i < _numVertices; ++i)
			{
				this.setColor(i, color);
			}
		}
		
		/**
		 * 统一所有顶点数据的透明度.
		 * @param alpha 透明度.
		 */
		public function setUniformAlpha(alpha:Number):void
		{
			for(var i:int = 0; i < _numVertices; ++i)
			{
				this.setAlpha(i, alpha);
			}
		}
		
		/**
		 * 透明度值和一个增量相乘.
		 * @param vertexID 顶点索引.
		 * @param alpha 相乘的增量.
		 * @param numVertices 顶点数量.
		 */
		public function scaleAlpha(vertexID:int, alpha:Number, numVertices:int = 1):void
		{
			if(numVertices < 0 || vertexID + numVertices > _numVertices)
			{
				numVertices = _numVertices - vertexID;
			}
			var i:int;
			if(alpha == 1)
			{
				return;
			}
			else if(_premultipliedAlpha)
			{
				for(i = 0; i < numVertices; ++i)
				{
					this.setAlpha(vertexID + i, this.getAlpha(vertexID + i) * alpha);
				}
			}
			else
			{
				var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
				for(i = 0; i < numVertices; ++i)
				{
					_rawData[int(offset + i * ELEMENTS_PER_VERTEX)] *= alpha;
				}
			}
		}
		
		private function getOffset(vertexID:int):int
		{
			return vertexID * ELEMENTS_PER_VERTEX;
		}
		
		/**
		 * 
		 * @param transformationMatrix
		 * @param vertexID
		 * @param numVertices
		 * @param resultRect
		 * @return
		 */
		public function getBounds(transformationMatrix:Matrix = null, vertexID:int = 0, numVertices:int = -1, resultRect:Rectangle = null):Rectangle
		{
			if(resultRect == null)
			{
				resultRect = new Rectangle();
			}
			if(numVertices < 0 || vertexID + numVertices > _numVertices)
			{
				numVertices = _numVertices - vertexID;
			}
			var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
			var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
			var offset:int = getOffset(vertexID) + POSITION_OFFSET;
			var x:Number, y:Number, i:int;
			if(transformationMatrix == null)
			{
				for(i = vertexID; i < numVertices; ++i)
				{
					x = _rawData[offset];
					y = _rawData[int(offset + 1)];
					offset += ELEMENTS_PER_VERTEX;
					minX = minX < x ? minX : x;
					maxX = maxX > x ? maxX : x;
					minY = minY < y ? minY : y;
					maxY = maxY > y ? maxY : y;
				}
			}
			else
			{
				for(i = vertexID; i < numVertices; ++i)
				{
					x = _rawData[offset];
					y = _rawData[int(offset + 1)];
					offset += ELEMENTS_PER_VERTEX;
					transformCoords(transformationMatrix, x, y, _helperPoint);
					minX = minX < _helperPoint.x ? minX : _helperPoint.x;
					maxX = maxX > _helperPoint.x ? maxX : _helperPoint.x;
					minY = minY < _helperPoint.y ? minY : _helperPoint.y;
					maxY = maxY > _helperPoint.y ? maxY : _helperPoint.y;
				}
			}
			resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
			return resultRect;
		}
		
		/**
		 * 添加顶点数据.
		 * @param data 要添加的顶点数据.
		 */
		public function append(data:VertexData):void
		{
			_rawData.fixed = false;
			var rawData:Vector.<Number> = data._rawData;
			var rawDataLength:int = rawData.length;
			for(var i:int = 0; i < rawDataLength; ++i)
			{
				_rawData.push(rawData[i]);
			}
			_numVertices += data.numVertices;
			_rawData.fixed = true;
		}
		
		/**
		 * 从指定的索引开始, 将此实例的顶点数据复制到另一个顶点的数据对象.
		 * @param targetData 目标对象.
		 * @param targetVertexID 目标对象的索引.
		 */
		public function copyTo(targetData:VertexData, targetVertexID:int = 0):void
		{
			var targetRawData:Vector.<Number> = targetData._rawData;
			var dataLength:int = _numVertices * ELEMENTS_PER_VERTEX;
			var targetStartIndex:int = targetVertexID * ELEMENTS_PER_VERTEX;
			for(var i:int = 0; i < dataLength; ++i)
			{
				targetRawData[int(targetStartIndex + i)] = _rawData[i];
			}
		}
		
		/**
		 * 克隆当前的副本.
		 * @param vertexID 开始克隆的顶点索引.
		 * @param numVertices 克隆的顶点数量.
		 * @return 克隆后的副本.
		 */
		public function clone(vertexID:int = 0, numVertices:int = -1):VertexData
		{
			if(numVertices < 0 || vertexID + numVertices > _numVertices)
			{
				numVertices = _numVertices - vertexID;
			}
			var clone:VertexData = new VertexData(0, _premultipliedAlpha);
			clone._numVertices = numVertices;
			clone._rawData = _rawData.slice(vertexID * ELEMENTS_PER_VERTEX, numVertices * ELEMENTS_PER_VERTEX);
			clone._rawData.fixed = true;
			return clone;
		}
	}
}

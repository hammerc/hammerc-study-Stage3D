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
	import flash.geom.Point;
	
	/**
	 * 使用一个矩阵, 将 2D 坐标转换到另一个空间.
	 * @param matrix 矩阵.
	 * @param x x.
	 * @param y y.
	 * @param resultPoint 如果您传递一个 'resultPoint', 就不会创建新对象, 而是将返回结果存储在这个对象上.
	 * @return 结果.
	 */
	public function transformCoords(matrix:Matrix, x:Number, y:Number, resultPoint:Point = null):Point
	{
		if(resultPoint == null)
		{
			resultPoint = new Point();
		}
		resultPoint.x = matrix.a * x + matrix.c * y + matrix.tx;
		resultPoint.y = matrix.d * y + matrix.b * x + matrix.ty;
		return resultPoint;
	}
}

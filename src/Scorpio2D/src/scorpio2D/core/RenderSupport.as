// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio2D.core
{
	import flash.display3D.Context3DBlendFactor;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import scorpio2D.display.DisplayObject2D;
	import scorpio2D.utils.Color;
	
	/**
	 * 渲染辅助类.
	 * @author wizardc
	 */
	public class RenderSupport
	{
		/**
		 * 为自定义矩阵的一个对象提前准备坐标换算, 缩放和旋转.
		 * @param matrix 矩阵.
		 * @param object 显示对象.
		 */
		public static function transformMatrixForObject(matrix:Matrix3D, object:DisplayObject2D):void
		{
			matrix.prependTranslation(object.x, object.y, 0);
			matrix.prependRotation(object.rotation / Math.PI * 180, Vector3D.Z_AXIS);
			matrix.prependScale(object.scaleX, object.scaleY, 1);
			matrix.prependTranslation(-object.pivotX, -object.pivotY, 0);
		}
		
		//正交矩阵
		private var _projectionMatrix:Matrix3D;
		//当前处理的显示对象的转换矩阵
		private var _modelViewMatrix:Matrix3D;
		//按层级关系存储的转换矩阵栈
		private var _matrixStack:Vector.<Matrix3D>;
		
		/**
		 * 构造函数.
		 */
		public function RenderSupport()
		{
			_matrixStack = new <Matrix3D>[];
			_projectionMatrix = new Matrix3D();
			_modelViewMatrix = new Matrix3D();
			this.loadIdentity();
			this.setOrthographicProjection(400, 300);
		}
		
		/**
		 * 计算由模型视图和投影矩阵产生的对象.
		 */
		public function get mvpMatrix():Matrix3D
		{
			var mvpMatrix:Matrix3D = new Matrix3D();
			mvpMatrix.append(_modelViewMatrix);
			mvpMatrix.append(_projectionMatrix);
			return mvpMatrix;
		}
		
		/**
		 * 设置为 2D 屏幕渲染准备的投影矩阵.
		 * @param width 宽度.
		 * @param height 高度.
		 * @param near 近截面.
		 * @param far 远截面.
		 */
		public function setOrthographicProjection(width:Number, height:Number, near:Number = -1, far:Number = 1):void
		{
			//设置正交矩阵数据, 这个公式记死即可
			var coords:Vector.<Number> = new <Number>
					[
						2 / width, 0, 0, 0,
						0, -2 / height, 0, 0,
						0, 0, -2 / (far - near), 0,
						-1, 1, -(far + near) / (far - near), 1
					];
			_projectionMatrix.copyRawDataFrom(coords);
		}
		
		/**
		 * 将模型视图矩阵改变为恒等矩阵.
		 */
		public function loadIdentity():void
		{
			_modelViewMatrix.identity();
		}
		
		/**
		 * 为模型视图矩阵提前准备增量平移.
		 * @param dx
		 * @param dy
		 * @param dz
		 */
		public function translateMatrix(dx:Number, dy:Number, dz:Number = 0):void
		{
			_modelViewMatrix.prependTranslation(dx, dy, dz);
		}
		
		/**
		 * 为模型视图矩阵提前准备一个旋转弧度
		 * @param angle
		 * @param axis
		 */
		public function rotateMatrix(angle:Number, axis:Vector3D = null):void
		{
			_modelViewMatrix.prependRotation(angle / Math.PI * 180.0, axis == null ? Vector3D.Z_AXIS : axis);
		}
		
		/**
		 * 为模型视图矩阵提前准备一个增量的缩放变化
		 * @param sx
		 * @param sy
		 * @param sz
		 */
		public function scaleMatrix(sx:Number, sy:Number, sz:Number = 1):void
		{
			_modelViewMatrix.prependScale(sx, sy, sz);
		}
		
		/**
		 * 为模型视图矩阵的一个对象提前准备矩阵换算, 缩放和旋转.
		 * @param object
		 */
		public function transformMatrix(object:DisplayObject2D):void
		{
			transformMatrixForObject(_modelViewMatrix, object);
		}
		
		/**
		 * 将当前的模型视图矩阵推入到一个它可以快速恢复的堆栈.
		 */
		public function pushMatrix():void
		{
			_matrixStack.push(_modelViewMatrix.clone());
		}
		
		/**
		 * 将最后一个推入堆栈的模型视图矩阵从堆栈移除并设置为当前模型视图矩阵.
		 */
		public function popMatrix():void
		{
			_modelViewMatrix = _matrixStack.pop();
		}
		
		/**
		 * 将矩阵堆栈置空, 重置当前的模型视图矩阵为标示的矩阵.
		 */
		public function resetMatrix():void
		{
			if(_matrixStack.length != 0)
			{
				_matrixStack = new <Matrix3D>[];
			}
			this.loadIdentity();
		}
		
		/**
		 * 设置默认的混合因子.
		 * @param premultipliedAlpha 是否预乘透明度.
		 */
		public function setDefaultBlendFactors(premultipliedAlpha:Boolean):void
		{
			var destFactor:String = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
			var sourceFactor:String = premultipliedAlpha ? Context3DBlendFactor.ONE : Context3DBlendFactor.SOURCE_ALPHA;
			Scorpio2D.context.setBlendFactors(sourceFactor, destFactor);
		}
		
		/**
		 * 根据特定的颜色和透明度, 清理渲染上下文.
		 * @param rgb 颜色.
		 * @param alpha 透明度.
		 */
		public function clear(rgb:uint = 0, alpha:Number = 0):void
		{
			Scorpio2D.context.clear(Color.getRed(rgb) / 255, Color.getGreen(rgb) / 255, Color.getBlue(rgb) / 255, alpha);
		}
	}
}

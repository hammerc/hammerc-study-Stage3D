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
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import scorpio2D.display.BlendMode2D;
	import scorpio2D.display.DisplayObject2D;
	import scorpio2D.display.Quad2D;
	import scorpio2D.display.QuadBatch;
	import scorpio2D.textures.Texture2D;
	import scorpio2D.utils.Color;
	
	/**
	 * 渲染辅助类.
	 * @author wizardc
	 */
	public class RenderSupport
	{
		private static var _matrixCoords:Vector.<Number> = new Vector.<Number>(16, true);
		
		/**
		 * 根据一定的混合模式, 设置相应的混合因素.
		 * @param premultipliedAlpha 是否相乘透明度.
		 * @param blendMode 混合模式.
		 */
		public static function setBlendFactors(premultipliedAlpha:Boolean, blendMode:String = "normal"):void
		{
			var blendFactors:Array = BlendMode2D.getBlendFactors(blendMode, premultipliedAlpha);
			Scorpio2D.context.setBlendFactors(blendFactors[0], blendFactors[1]);
		}
		
		/**
		 * 根据特定的颜色和透明度, 清理渲染上下文.
		 * @param rgb 颜色.
		 * @param alpha 透明度.
		 */
		public static function clear(rgb:uint = 0, alpha:Number = 0):void
		{
			Scorpio2D.context.clear(Color.getRed(rgb) / 255, Color.getGreen(rgb) / 255, Color.getBlue(rgb) / 255, alpha);
		}
		
		/**
		 * 为自定义矩阵的一个对象提前准备坐标换算, 缩放和旋转.
		 * @param matrix 矩阵.
		 * @param object 显示对象.
		 */
		public static function transformMatrixForObject(matrix:Matrix3D, object:DisplayObject2D):void
		{
			var x:Number = object.x;
			var y:Number = object.y;
			var rotation:Number = object.rotation;
			var scaleX:Number = object.scaleX;
			var scaleY:Number = object.scaleY;
			var pivotX:Number = object.pivotX;
			var pivotY:Number = object.pivotY;
			if(x != 0 || y != 0)
			{
				matrix.prependTranslation(x, y, 0);
			}
			if(rotation != 0)
			{
				matrix.prependRotation(rotation / Math.PI * 180, Vector3D.Z_AXIS);
			}
			if(scaleX != 1 || scaleY != 1)
			{
				matrix.prependScale(scaleX, scaleY, 1);
			}
			if(pivotX != 0 || pivotY != 0)
			{
				matrix.prependTranslation(-pivotX, -pivotY, 0);
			}
		}
		
		//正交矩阵
		private var _projectionMatrix:Matrix3D;
		//当前处理的显示对象的转换矩阵
		private var _modelViewMatrix:Matrix3D;
		//用于返回到每个具体模型使用的矩阵
		private var _mvpMatrix:Matrix3D;
		
		//矩阵栈当前索引
		private var _matrixStackSize:int;
		//按层级关系存储的转换矩阵栈
		private var _matrixStack:Vector.<Matrix3D>;
		//混合模式
		private var _blendMode:String;
		private var _blendModeStack:Vector.<String>;
		//批处理
		private var _currentQuadBatchID:int;
		private var _quadBatches:Vector.<QuadBatch>;
		
		/**
		 * 构造函数.
		 */
		public function RenderSupport()
		{
			_matrixStack = new <Matrix3D>[];
			_projectionMatrix = new Matrix3D();
			_modelViewMatrix = new Matrix3D();
			_mvpMatrix = new Matrix3D();
			_matrixStackSize = 0;
			_blendMode = BlendMode2D.NORMAL;
			_blendModeStack = new <String>[];
			_currentQuadBatchID = 0;
			_quadBatches = new <QuadBatch>[new QuadBatch()];
			this.loadIdentity();
			this.setOrthographicProjection(400, 300);
		}
		
		/**
		 * 设置或获取当前使用的混合模式.
		 */
		public function set blendMode(value:String):void
		{
			if(value != BlendMode2D.AUTO)//自动表示使用之前的混合模式, 所以不进行设置
			{
				_blendMode = value;
			}
		}
		public function get blendMode():String
		{
			return _blendMode;
		}
		
		/**
		 * 计算由模型视图和投影矩阵产生的对象.
		 */
		public function get mvpMatrix():Matrix3D
		{
			_mvpMatrix.copyFrom(_modelViewMatrix);
			_mvpMatrix.append(_projectionMatrix);
			return _mvpMatrix;
		}
		
		/**
		 * 获取当前的批处理对象.
		 */
		private function get currentQuadBatch():QuadBatch
		{
			return _quadBatches[_currentQuadBatchID];
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
			_matrixCoords[0] = 2 / width;
			_matrixCoords[1] = _matrixCoords[2] = _matrixCoords[3] = _matrixCoords[4] = 0;
			_matrixCoords[5] = -2 / height;
			_matrixCoords[6] = _matrixCoords[7] = _matrixCoords[8] = _matrixCoords[9] = 0;
			_matrixCoords[10] = -2 / (far - near);
			_matrixCoords[11] = 0;
			_matrixCoords[12] = -1;
			_matrixCoords[13] = 1;
			_matrixCoords[14] = -(far + near) / (far - near);
			_matrixCoords[15] = 1;
			_projectionMatrix.copyRawDataFrom(_matrixCoords);
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
		 * @param dx x.
		 * @param dy y.
		 * @param dz z.
		 */
		public function translateMatrix(dx:Number, dy:Number, dz:Number = 0):void
		{
			_modelViewMatrix.prependTranslation(dx, dy, dz);
		}
		
		/**
		 * 为模型视图矩阵提前准备一个旋转弧度
		 * @param angle 弧度.
		 * @param axis 平面.
		 */
		public function rotateMatrix(angle:Number, axis:Vector3D = null):void
		{
			_modelViewMatrix.prependRotation(angle / Math.PI * 180, axis == null ? Vector3D.Z_AXIS : axis);
		}
		
		/**
		 * 为模型视图矩阵提前准备一个增量的缩放变化
		 * @param sx x.
		 * @param sy y.
		 * @param sz z.
		 */
		public function scaleMatrix(sx:Number, sy:Number, sz:Number = 1):void
		{
			_modelViewMatrix.prependScale(sx, sy, sz);
		}
		
		/**
		 * 为模型视图矩阵的一个对象提前准备矩阵换算, 缩放和旋转.
		 * @param object 显示对象.
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
			if(_matrixStack.length < _matrixStackSize + 1)
			{
				_matrixStack.push(new Matrix3D());
			}
			_matrixStack[_matrixStackSize++].copyFrom(_modelViewMatrix);
		}
		
		/**
		 * 将最后一个推入堆栈的模型视图矩阵从堆栈移除并设置为当前模型视图矩阵.
		 */
		public function popMatrix():void
		{
			_modelViewMatrix.copyFrom(_matrixStack[--_matrixStackSize]);
		}
		
		/**
		 * 将矩阵堆栈置空, 重置当前的模型视图矩阵为标示的矩阵.
		 */
		public function resetMatrix():void
		{
			_matrixStackSize = 0;
			this.loadIdentity();
		}
		
		/**
		 * 将当前的混合模式推入到一个它可以快速恢复的堆栈.
		 */
		public function pushBlendMode():void
		{
			_blendModeStack.push(_blendMode);
		}
		
		/**
		 * 将最后一个推入堆栈的混合模式从堆栈移除并设置为当前混合模式.
		 */
		public function popBlendMode():void
		{
			_blendMode = _blendModeStack.pop();
		}
		
		/**
		 * 清除混合模式堆栈, 并设置当前模式为 NORMAL 状态.
		 */
		public function resetBlendMode():void
		{
			_blendModeStack.length = 0;
			_blendMode = BlendMode2D.NORMAL;
		}
		
		/**
		 * 在当前的渲染上下文上激活相应的混合因素.
		 * @param premultipliedAlpha 是否相乘透明度.
		 */
		public function applyBlendMode(premultipliedAlpha:Boolean):void
		{
			setBlendFactors(premultipliedAlpha, _blendMode);
		}
		
		/**
		 * 添加一个四边形到当前未渲染的四边形批次.
		 * 如果这是一个状态变更, 那么所有之前的四边形会进行一次统一渲染, 并重置当前批次.
		 * @param quad Quad 实例.
		 * @param parentAlpha 透明度.
		 * @param texture 纹理.
		 * @param smoothing 平滑度.
		 */
		public function batchQuad(quad:Quad2D, parentAlpha:Number, texture:Texture2D = null, smoothing:String = null):void
		{
			if(currentQuadBatch.isStateChange(quad, parentAlpha, texture, smoothing, _blendMode))
			{
				this.finishQuadBatch();
			}
			currentQuadBatch.addQuad(quad, parentAlpha, texture, smoothing, _modelViewMatrix, _blendMode);
		}
		
		/**
		 * 渲染并重置当前的四边形批次.
		 */
		public function finishQuadBatch():void
		{
			currentQuadBatch.renderCustom(_projectionMatrix);
			currentQuadBatch.reset();
			++_currentQuadBatchID;
			if(_quadBatches.length <= _currentQuadBatchID)
			{
				_quadBatches.push(new QuadBatch());
			}
		}
		
		/**
		 * 重置矩阵和混合模式堆栈, 以及四边形批次的索引, 为下一帧使用做准备.
		 */
		public function nextFrame():void
		{
			this.resetMatrix();
			this.resetBlendMode();
			_currentQuadBatchID = 0;
		}
		
		/**
		 * 释放所有的四边形批次.
		 */
		public function dispose():void
		{
			for each(var quadBatch:QuadBatch in _quadBatches)
			{
				quadBatch.dispose();
			}
		}
	}
}

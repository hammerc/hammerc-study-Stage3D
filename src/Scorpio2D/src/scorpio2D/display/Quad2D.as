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
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	
	import scorpio2D.core.RenderSupport;
	import scorpio2D.core.Scorpio2D;
	import scorpio2D.utils.VertexData;
	
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
		/**
		 * 着色器名称.
		 */
		public static const PROGRAM_NAME:String = "quad";
		
		/**
		 * 注册着色器, 该方法会创建 1 个顶点着色器和 1 个像素着色器对象.
		 * @param target Scorpio2D 实例对象.
		 */
		public static function registerPrograms(target:Scorpio2D):void
		{
			var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexProgramAssembler.assemble(Context3DProgramType.VERTEX,
					"m44 op, va0, vc0  \n" +  // 4x4 matrix transform to output clipspace
					"mov v0, va1       \n"    // pass color to fragment program 
			);
			var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT,
					"mul ft0, v0, fc0  \n" +  // multiply alpha (fc0) by color (v0)
					"mov oc, ft0       \n"    // output color
			);
			target.registerProgram(PROGRAM_NAME, vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
		}
		
		//顶点数据
		protected var mVertexData:VertexData;
		//顶点缓冲
		protected var mVertexBuffer:VertexBuffer3D;
		//索引缓冲
		protected var mIndexBuffer:IndexBuffer3D;
		
		/**
		 * 构造函数.
		 * @param width 高度.
		 * @param height 宽度.
		 * @param color 颜色.
		 */
		public function Quad2D(width:Number, height:Number, color:uint = 0xffffff)
		{
			mVertexData = new VertexData(4, true);
			mVertexData.setPosition(0, 0.0, 0.0);
			mVertexData.setPosition(1, width, 0.0);
			mVertexData.setPosition(2, 0.0, height);
			mVertexData.setPosition(3, width, height);
			mVertexData.setUniformColor(color);
		}
		
		/**
		 * 获取顶点数据.
		 */
		public function get vertexData():VertexData
		{
			return mVertexData.clone();
		}
		
		/**
		 * 设置或获取颜色.
		 */
		public function set color(value:uint):void
		{
			mVertexData.setUniformColor(value);
			if(mVertexBuffer != null)
			{
				this.createVertexBuffer();
			}
		}
		public function get color():uint
		{
			return mVertexData.getColor(0);
		}
		
		/**
		 * 设置指定顶点的颜色.
		 * @param vertexID 顶点索引.
		 * @param color 颜色.
		 */
		public function setVertexColor(vertexID:int, color:uint):void
		{
			mVertexData.setColor(vertexID, color);
			if(mVertexBuffer != null)
			{
				this.createVertexBuffer();
			}
		}
		
		/**
		 * 获取指定顶点的颜色.
		 * @param vertexID 顶点索引.
		 * @return 颜色.
		 */
		public function getVertexColor(vertexID:int):uint
		{
			return mVertexData.getColor(vertexID);
		}
		
		/**
		 * 设置指定顶点的透明度.
		 * @param vertexID 顶点索引.
		 * @param alpha 透明度.
		 */
		public function setVertexAlpha(vertexID:int, alpha:Number):void
		{
			mVertexData.setAlpha(vertexID, alpha);
			if(mVertexBuffer != null)
			{
				this.createVertexBuffer();
			}
		}
		
		/**
		 * 获取指定顶点的透明度.
		 * @param vertexID 顶点索引.
		 * @return 透明度.
		 */
		public function getVertexAlpha(vertexID:int):Number
		{
			return mVertexData.getAlpha(vertexID);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function render(support:RenderSupport, alpha:Number):void
		{
			//根据上层的透明度获取最终会使用的透明度
			alpha *= this.alpha;
			//透明度常量
			var alphaVector:Vector.<Number> = new <Number>[alpha, alpha, alpha, alpha];
			var context:Context3D = Scorpio2D.context;
			//创建缓冲对象
			if(context == null)
			{
				throw new Error("Context3D object is required but not available");
			}
			if(mVertexBuffer == null)
			{
				this.createVertexBuffer();
			}
			if(mIndexBuffer == null)
			{
				this.createIndexBuffer();
			}
			//设置默认的混合因子
			support.setDefaultBlendFactors(true);
			//绘制当前图像
			context.setProgram(Scorpio2D.current.getProgram(PROGRAM_NAME));
			context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix, true);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, alphaVector, 1);
			context.drawTriangles(mIndexBuffer, 0, 2);
			//清除顶点数据映射
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
		}
		
		/**
		 * 创建顶点缓冲并上传至 GPU.
		 */
		protected function createVertexBuffer():void
		{
			if(mVertexBuffer == null)
			{
				mVertexBuffer = Scorpio2D.context.createVertexBuffer(4, VertexData.ELEMENTS_PER_VERTEX);
			}
			mVertexBuffer.uploadFromVector(this.vertexData.data, 0, 4);
		}
		
		/**
		 * 创建索引缓冲并上传至 GPU.
		 */
		protected function createIndexBuffer():void
		{
			if(mIndexBuffer == null)
			{
				mIndexBuffer = Scorpio2D.context.createIndexBuffer(6);
			}
			mIndexBuffer.uploadFromVector(Vector.<uint>([0, 1, 2, 1, 3, 2]), 0, 6);
		}
		
		/**
		 * @inheritDoc
		 */
		public override function getBounds(targetSpace:DisplayObject2D):Rectangle
		{
			var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
			var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
			var position:Vector3D;
			var i:int;
			if(targetSpace == this)
			{
				for(i = 0; i < 4; ++i)
				{
					position = mVertexData.getPosition(i);
					minX = Math.min(minX, position.x);
					maxX = Math.max(maxX, position.x);
					minY = Math.min(minY, position.y);
					maxY = Math.max(maxY, position.y);
				}
			}
			else
			{
				var transformationMatrix:Matrix = this.getTransformationMatrix(targetSpace);
				var point:Point = new Point();
				for(i = 0; i < 4; ++i)
				{
					position = mVertexData.getPosition(i);
					point.x = position.x;
					point.y = position.y;
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
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			if(mVertexBuffer != null)
			{
				mVertexBuffer.dispose();
			}
			if(mIndexBuffer != null)
			{
				mIndexBuffer.dispose();
			}
			super.dispose();
		}
	}
}

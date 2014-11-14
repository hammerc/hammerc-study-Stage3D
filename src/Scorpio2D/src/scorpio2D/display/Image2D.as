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
	
	import flash.display.Bitmap;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import scorpio2D.core.RenderSupport;
	import scorpio2D.core.Scorpio2D;
	import scorpio2D.textures.Texture2D;
	import scorpio2D.textures.TextureSmoothing;
	import scorpio2D.utils.VertexData;
	
	/**
	 * 可以映射一个纹理进行绘制类.
	 * @author wizardc
	 */
	public class Image2D extends Quad2D
	{
		/**
		 * 注册着色器, 更具参数的不同, 该方法会创建 1 个顶点着色器和 16 个像素着色器对象.
		 * @param target Scorpio2D 实例对象.
		 */
		public static function registerPrograms(target:Scorpio2D):void
		{
			// create vertex and fragment programs - from assembly.
			// each combination of repeat/mipmap/smoothing has its own fragment shader.
			var vertexProgramCode:String =
					"m44 op, va0, vc0  \n" +  // 4x4 matrix transform to output clipspace
					"mov v0, va1       \n" +  // pass color to fragment program
					"mov v1, va2       \n";   // pass texture coordinates to fragment program
			var fragmentProgramCode:String =
					"tex ft1, v1, fs1 <???> \n" +  // sample texture 1
					"mul ft2, ft1, v0       \n" +  // multiply color with texel color
					"mul oc, ft2, fc0       \n";   // multiply color with alpha
			var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode);
			var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			var smoothingTypes:Array = [TextureSmoothing.NONE, TextureSmoothing.BILINEAR, TextureSmoothing.TRILINEAR];
			for each(var repeat:Boolean in [true, false])
			{
				for each(var mipmap:Boolean in [true, false])
				{
					for each(var smoothing:String in smoothingTypes)
					{
						var options:Array = ["2d", repeat ? "repeat" : "clamp"];
						if(smoothing == TextureSmoothing.NONE)
						{
							options.push("nearest", mipmap ? "mipnearest" : "mipnone");
						}
						else if(smoothing == TextureSmoothing.BILINEAR)
						{
							options.push("linear", mipmap ? "mipnearest" : "mipnone");
						}
						else
						{
							options.push("linear", mipmap ? "miplinear" : "mipnone");
						}
						fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentProgramCode.replace("???", options.join()));
						target.registerProgram(getProgramName(mipmap, repeat, smoothing), vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
					}
				}
			}
		}
		
		/**
		 * 获取指定着色器的名称.
		 * @param mipMap 是否使用 MIPMAP.
		 * @param repeat 是否平铺.
		 * @param smoothing 平滑度.
		 * @return 指定着色器的名称.
		 */
		public static function getProgramName(mipMap:Boolean = true, repeat:Boolean = false, smoothing:String = "bilinear"):String
		{
			// this method is called very often, so it should return quickly when called with 
			// the default parameters (no-repeat, mipmap, bilinear)
			var name:String = "image|";
			if(!mipMap)
			{
				name += "N";
			}
			if(repeat)
			{
				name += "R";
			}
			if(smoothing != TextureSmoothing.BILINEAR)
			{
				name += smoothing.charAt(0);
			}
			return name;
		}
		
		/**
		 * 根据传入的位图对象创建一个包含纹理的 Image2D 对象.
		 * @param bitmap 位图对象.
		 * @return Image2D 对象.
		 */
		public static function fromBitmap(bitmap:Bitmap):Image2D
		{
			return new Image2D(Texture2D.fromBitmap(bitmap));
		}
		
		private var _texture:Texture2D;
		private var _smoothing:String;
		
		/**
		 * 构造函数.
		 * @param texture 纹理.
		 */
		public function Image2D(texture:Texture2D)
		{
			if(texture != null)
			{
				var frame:Rectangle = texture.frame;
				var width:Number = frame ? frame.width : texture.width;
				var height:Number = frame ? frame.height : texture.height;
				super(width, height);
				mVertexData.premultipliedAlpha = texture.premultipliedAlpha;
				mVertexData.setTexCoords(0, 0, 0);
				mVertexData.setTexCoords(1, 1, 0);
				mVertexData.setTexCoords(2, 0, 1);
				mVertexData.setTexCoords(3, 1, 1);
				_texture = texture;
				_smoothing = TextureSmoothing.BILINEAR;
			}
			else
			{
				throw new ArgumentError("Texture cannot be null");
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get vertexData():VertexData
		{
			return _texture.adjustVertexData(mVertexData);
		}
		
		/**
		 * 设置或获取纹理对象.
		 */
		public function set texture(value:Texture2D):void
		{
			if(value == null)
			{
				throw new ArgumentError("Texture cannot be null");
			}
			else if(value != _texture)
			{
				_texture = value;
				mVertexData.premultipliedAlpha = _texture.premultipliedAlpha;
				if(mVertexBuffer != null)
				{
					this.createVertexBuffer();
				}
			}
		}
		public function get texture():Texture2D
		{
			return _texture;
		}
		
		/**
		 * 设置或获取平滑处理.
		 */
		public function set smoothing(value:String):void
		{
			if(TextureSmoothing.isValid(value))
			{
				_smoothing = value;
			}
			else
			{
				throw new ArgumentError("Invalid smoothing mode: " + smoothing);
			}
		}
		public function get smoothing():String
		{
			return _smoothing;
		}
		
		/**
		 * 设置一个顶点的纹理坐标.
		 * @param vertexID 顶点索引.
		 * @param coords 纹理坐标.
		 */
		public function setTexCoords(vertexID:int, coords:Point):void
		{
			mVertexData.setTexCoords(vertexID, coords.x, coords.y);
			if(mVertexBuffer != null)
			{
				this.createVertexBuffer();
			}
		}
		
		/**
		 * 获取一个顶点的纹理坐标.
		 * @param vertexID 顶点索引.
		 * @return 纹理坐标.
		 */
		public function getTexCoords(vertexID:int):Point
		{
			return mVertexData.getTexCoords(vertexID);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function render(support:RenderSupport, alpha:Number):void
		{
			//根据上层的透明度获取最终会使用的透明度
			alpha *= this.alpha;
			//是否预乘透明度
			var pma:Boolean = _texture.premultipliedAlpha;
			//获取需要的着色器
			var programName:String = getProgramName(_texture.mipMapping, _texture.repeat, _smoothing);
			//创建缓冲对象
			var context:Context3D = Scorpio2D.context;
			if(context == null)
			{
				throw new Error();
			}
			if(mVertexBuffer == null)
			{
				this.createVertexBuffer();
			}
			if(mIndexBuffer  == null)
			{
				this.createIndexBuffer();
			}
			//透明度常量
			var alphaVector:Vector.<Number> = pma ? new <Number>[alpha, alpha, alpha, alpha] : new <Number>[1.0, 1.0, 1.0, alpha];
			//设置默认的混合因子
			support.setDefaultBlendFactors(pma);
			//设置着色器
			context.setProgram(Scorpio2D.current.getProgram(programName));
			//设置纹理, 纹理创建时已经提交到 GPU 显存
			context.setTextureAt(1, _texture.base);
			//绘制当前图像
			context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4);
			context.setVertexBufferAt(2, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix, true);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, alphaVector, 1);
			context.drawTriangles(mIndexBuffer, 0, 2);
			//清除顶点, 纹理数据映射
			context.setTextureAt(1, null);
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(2, null);
		}
	}
}

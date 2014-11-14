// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio2D.textures
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	import scorpio2D.core.Scorpio2D;
	import scorpio2D.utils.VertexData;
	import scorpio2D.utils.getNextPowerOfTwo;
	
	/**
	 * 纹理抽象基类, 一个纹理存储了显示一个图像所需的信息.
	 * 它不能被直接添加到显示列表, 应该将它映射到一个显示对象.
	 * @author wizardc
	 */
	public class Texture2D
	{
		/**
		 * 从一个位图对象来创建一个纹理.
		 * @param data 位图对象.
		 * @param generateMipMaps 是否生成MIP映射.
		 * @param optimizeForRenderTexture 优化渲染纹理.
		 * @return 纹理对象.
		 */
		public static function fromBitmap(data:Bitmap, generateMipMaps:Boolean = true, optimizeForRenderTexture:Boolean = false):Texture2D
		{
			return fromBitmapData(data.bitmapData, generateMipMaps, optimizeForRenderTexture);
		}
		
		/**
		 * 从一个位图数据对象来创建一个纹理.
		 * @param data 位图数据对象.
		 * @param generateMipMaps 是否生成MIP映射.
		 * @param optimizeForRenderTexture 优化渲染纹理.
		 * @return 纹理对象.
		 */
		public static function fromBitmapData(data:BitmapData, generateMipMaps:Boolean = true, optimizeForRenderTexture:Boolean = false):Texture2D
		{
			var origWidth:int = data.width;
			var origHeight:int = data.height;
			var legalWidth:int  = getNextPowerOfTwo(data.width);
			var legalHeight:int = getNextPowerOfTwo(data.height);
			var format:String = Context3DTextureFormat.BGRA;
			var nativeTexture:Texture = Scorpio2D.context.createTexture(legalWidth, legalHeight, format, optimizeForRenderTexture);
			if(legalWidth > origWidth || legalHeight > origHeight)
			{
				var potData:BitmapData = new BitmapData(legalWidth, legalHeight, true, 0);
				potData.copyPixels(data, data.rect, new Point(0, 0));
				uploadTexture(potData, nativeTexture, generateMipMaps);
				potData.dispose();
			}
			else
			{
				uploadTexture(data, nativeTexture, generateMipMaps);
			}
			var concreteTexture:Texture2D = new ConcreteTexture2D(nativeTexture, legalWidth, legalHeight, generateMipMaps, true);
			return fromTexture(concreteTexture, new Rectangle(0, 0, origWidth, origHeight));
		}
		
		/**
		 * 从压缩的 ATF 格式来创建一个纹理.
		 * @param data ATF 的字节数组.
		 * @return 纹理对象.
		 */
		public static function fromAtfData(data:ByteArray):Texture2D
		{
			var signature:String = String.fromCharCode(data[0], data[1], data[2]);
			if(signature != "ATF")
			{
				throw new ArgumentError("Invalid ATF data");
			}
			var format:String = data[6] == 2 ? Context3DTextureFormat.COMPRESSED : Context3DTextureFormat.BGRA;
			var width:int = Math.pow(2, data[7]);
			var height:int = Math.pow(2, data[8]);
			var textureCount:int = data[9];
			var nativeTexture:Texture = Scorpio2D.context.createTexture(width, height, format, false);
			nativeTexture.uploadCompressedTextureFromByteArray(data, 0);
			return new ConcreteTexture2D(nativeTexture, width, height, textureCount > 1, false);
		}
		
		/**
		 * 根据另一个纹理的像素数据来创建一个新的纹理.
		 * @param texture 纹理.
		 * @param region 区域.
		 * @return 纹理对象.
		 */
		public static function fromTexture(texture:Texture2D, region:Rectangle):Texture2D
		{
			if(region.x == 0 && region.y == 0 && region.width == texture.width && region.height == texture.height)
			{
				return texture;
			}
			else
			{
				return new SubTexture2D(texture, region);
			}
		}
		
		/**
		 * 根据指定的尺寸和颜色创建一个空的纹理.
		 * @param width 宽度.
		 * @param height 高度.
		 * @param color 颜色.
		 * @param optimizeForRenderTexture 优化渲染纹理.
		 * @return 纹理对象.
		 */
		public static function empty(width:int = 64, height:int = 64, color:uint = 0xffffffff, optimizeForRenderTexture:Boolean = false):Texture2D
		{
			var bitmapData:BitmapData = new BitmapData(width, height, true, color);
			var texture:Texture2D = fromBitmapData(bitmapData, false, optimizeForRenderTexture);
			bitmapData.dispose();
			return texture;
		}
		
		private static function uploadTexture(data:BitmapData, texture:Texture, generateMipmaps:Boolean):void
		{
			texture.uploadFromBitmapData(data);
			if(generateMipmaps)
			{
				var currentWidth:int = data.width >> 1;
				var currentHeight:int = data.height >> 1;
				var level:int = 1;
				var canvas:BitmapData = new BitmapData(currentWidth, currentHeight, true, 0);
				var transform:Matrix = new Matrix(0.5, 0, 0, 0.5);
				while(currentWidth >= 1 || currentHeight >= 1)
				{
					canvas.fillRect(new Rectangle(0, 0, currentWidth, currentHeight), 0);
					canvas.draw(data, transform, null, null, null, true);
					texture.uploadFromBitmapData(canvas, level++);
					transform.scale(0.5, 0.5);
					currentWidth = currentWidth >> 1;
					currentHeight = currentHeight >> 1;
				}
				canvas.dispose();
			}
		}
		
		private var _frame:Rectangle;
		private var _repeat:Boolean;
		
		/**
		 * 构造函数.
		 */
		public function Texture2D()
		{
			if(getQualifiedClassName(this) == "scorpio2D.textures::Texture2D")
			{
				throw new Error("Texture2D is a abstract class");
			}
			_repeat = false;
		}
		
		/**
		 * 获取基于的 Stage3D 的 TextureBase 纹理对象.
		 */
		public function get base():TextureBase
		{
			return null;
		}
		
		/**
		 * 获取纹理是否具备 MIP 映射.
		 */
		public function get mipMapping():Boolean
		{
			return false;
		}
		
		/**
		 * 获取是否预乘 alpha 值到 RGB 值.
		 */
		public function get premultipliedAlpha():Boolean
		{
			return false;
		}
		
		/**
		 * 设置或获取纹理框架. 该属性允许只使用纹理的一部分.
		 */
		public function set frame(value:Rectangle):void
		{
			_frame = value ? value.clone() : null;
		}
		public function get frame():Rectangle
		{
			return _frame;
		}
		
		/**
		 * 设置或获取是否平铺显示.
		 */
		public function set repeat(value:Boolean):void
		{
			_repeat = value;
		}
		public function get repeat():Boolean
		{
			return _repeat;
		}
		
		/**
		 * 获取纹理宽度.
		 */
		public function get width():Number
		{
			return 0;
		}
		
		/**
		 * 获取纹理高度.
		 */
		public function get height():Number
		{
			return 0;
		}
		
		/**
		 * 转换纹理坐标和原始顶点数据的顶点位置到渲染所需的格式.
		 * @param vertexData 顶点数据.
		 * @return 顶点数据.
		 */
		public function adjustVertexData(vertexData:VertexData):VertexData
		{
			var clone:VertexData = vertexData.clone();
			if(this.frame != null)
			{
				var deltaRight:Number = _frame.width + _frame.x - width;
				var deltaBottom:Number = _frame.height + _frame.y - height;
				clone.translateVertex(0, -_frame.x, -_frame.y);
				clone.translateVertex(1, -deltaRight, -_frame.y);
				clone.translateVertex(2, -_frame.x, -deltaBottom);
				clone.translateVertex(3, -deltaRight, -deltaBottom);
			}
			return clone;
		}
		
		/**
		 * 销毁纹理对象.
		 */
		public function dispose():void
		{
			throw new Error("dispose is a abstract function");
		}
	}
}

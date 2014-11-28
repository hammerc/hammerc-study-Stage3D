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
	import flash.display.Bitmap;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import scorpio2D.core.RenderSupport;
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
		
		private var _vertexDataCache:VertexData;
		private var _vertexDataCacheInvalid:Boolean;
		
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
				var pma:Boolean = texture.premultipliedAlpha;
				super(width, height, 0xffffff, pma);
				_vertexData.setTexCoords(0, 0, 0);
				_vertexData.setTexCoords(1, 1, 0);
				_vertexData.setTexCoords(2, 0, 1);
				_vertexData.setTexCoords(3, 1, 1);
				_texture = texture;
				_smoothing = TextureSmoothing.BILINEAR;
				_vertexDataCache = new VertexData(4, pma);
				_vertexDataCacheInvalid = true;
			}
			else
			{
				throw new ArgumentError("Texture cannot be null");
			}
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
				_vertexData.setPremultipliedAlpha(_texture.premultipliedAlpha);
				this.onVertexDataChanged();
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
				throw new ArgumentError("Invalid smoothing mode: " + value);
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
			_vertexData.setTexCoords(vertexID, coords.x, coords.y);
			this.onVertexDataChanged();
		}
		
		/**
		 * 获取一个顶点的纹理坐标.
		 * @param vertexID 顶点索引.
		 * @return 纹理坐标.
		 */
		public function getTexCoords(vertexID:int):Point
		{
			var coords:Point = new Point();
			_vertexData.getTexCoords(vertexID, coords);
			return coords;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function render(support:RenderSupport, alpha:Number):void
		{
			support.batchQuad(this, alpha, _texture, _smoothing);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function copyVertexDataTo(targetData:VertexData, targetVertexID:int = 0):void
		{
			if(_vertexDataCacheInvalid)
			{
				_vertexDataCacheInvalid = false;
				_vertexData.copyTo(_vertexDataCache);
				_texture.adjustVertexData(_vertexDataCache, 0, 4);
			}
			_vertexDataCache.copyTo(targetData, targetVertexID);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function onVertexDataChanged():void
		{
			_vertexDataCacheInvalid = true;
		}
		
		/**
		 * 根据当前的纹理重新调整图像的尺寸.
		 * 当为图像设置了一个不同尺寸的纹理后, 需要调用这个方法来同步图像和纹理的尺寸.
		 */
		public function readjustSize():void
		{
			var frame:Rectangle = this.texture.frame;
			var width:Number  = frame ? frame.width  : this.texture.width;
			var height:Number = frame ? frame.height : this.texture.height;
			_vertexData.setPosition(0, 0.0, 0.0);
			_vertexData.setPosition(1, width, 0.0);
			_vertexData.setPosition(2, 0.0, height);
			_vertexData.setPosition(3, width, height);
			this.onVertexDataChanged();
		}
	}
}

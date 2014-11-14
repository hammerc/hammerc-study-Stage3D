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
	import flash.display3D.textures.TextureBase;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import scorpio2D.utils.VertexData;
	
	/**
	 * 一个子级纹理, 代表另一个纹理的一部分.
	 * 注: 从子级纹理再创建子级纹理也是允许的.
	 * @author wizardc
	 */
	public class SubTexture2D extends Texture2D
	{
		private var _parent:Texture2D;
		private var _clipping:Rectangle;
		private var _rootClipping:Rectangle;
		
		/**
		 * 构造函数.
		 * @param parentTexture 父级纹理.
		 * @param region 区域.
		 */
		public function SubTexture2D(parentTexture:Texture2D, region:Rectangle)
		{
			_parent = parentTexture;
			this.clipping = new Rectangle(region.x / parentTexture.width, region.y / parentTexture.height, region.width / parentTexture.width, region.height / parentTexture.height);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get base():TextureBase
		{
			return _parent.base;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get width():Number
		{
			return _parent.width * _clipping.width;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get height():Number
		{
			return _parent.height * _clipping.height;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get mipMapping():Boolean
		{
			return _parent.mipMapping;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get premultipliedAlpha():Boolean
		{
			return _parent.premultipliedAlpha;
		}
		
		/**
		 * 获取父级对象.
		 */
		public function get parent():Texture2D
		{
			return _parent;
		}
		
		/**
		 * 裁剪矩形.
		 */
		public function set clipping(value:Rectangle):void
		{
			_clipping = value.clone();
			_rootClipping = value.clone();
			var parentTexture:SubTexture2D = _parent as SubTexture2D;
			while(parentTexture != null)
			{
				var parentClipping:Rectangle = parentTexture._clipping;
				_rootClipping.x = parentClipping.x + _rootClipping.x * parentClipping.width;
				_rootClipping.y = parentClipping.y + _rootClipping.y * parentClipping.height;
				_rootClipping.width  *= parentClipping.width;
				_rootClipping.height *= parentClipping.height;
				parentTexture = parentTexture._parent as SubTexture2D;
			}
		}
		public function get clipping():Rectangle
		{
			return _clipping.clone();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function adjustVertexData(vertexData:VertexData):VertexData
		{
			var newData:VertexData = super.adjustVertexData(vertexData);
			var numVertices:int = vertexData.numVertices;
			var clipX:Number = _rootClipping.x;
			var clipY:Number = _rootClipping.y;
			var clipWidth:Number = _rootClipping.width;
			var clipHeight:Number = _rootClipping.height;
			for(var i:int = 0; i < numVertices; ++i)
			{
				var texCoords:Point = vertexData.getTexCoords(i);
				newData.setTexCoords(i, clipX + texCoords.x * clipWidth, clipY + texCoords.y * clipHeight);
			}
			return newData;
		}
	}
}

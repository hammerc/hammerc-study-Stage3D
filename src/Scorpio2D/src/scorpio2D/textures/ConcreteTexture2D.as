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
	
	/**
	 * 简单纹理实现类.
	 * @author wizardc
	 */
	public class ConcreteTexture2D extends Texture2D
	{
		private var _base:TextureBase;
		private var _width:int;
		private var _height:int;
		private var _mipMapping:Boolean;
		private var _premultipliedAlpha:Boolean;
		
		/**
		 * 构造函数.
		 * @param base 原生纹理对象.
		 * @param width 宽度.
		 * @param height 高度.
		 * @param mipMapping MIP 映射信息.
		 * @param premultipliedAlpha 是否预乘透明度.
		 */
		public function ConcreteTexture2D(base:TextureBase, width:int, height:int,mipMapping:Boolean, premultipliedAlpha:Boolean)
		{
			_base = base;
			_width = width;
			_height = height;
			_mipMapping = mipMapping;
			_premultipliedAlpha = premultipliedAlpha;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get base():TextureBase
		{
			return _base;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get width():Number
		{
			return _width;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get height():Number
		{
			return _height;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get mipMapping():Boolean
		{
			return _mipMapping;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get premultipliedAlpha():Boolean
		{
			return _premultipliedAlpha;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			if(_base != null)
			{
				_base.dispose();
			}
			super.dispose();
		}
	}
}

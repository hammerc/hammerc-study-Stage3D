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
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	/**
	 * 纹理图集是一个将许多小的纹理整合到一张大图的集合.
	 * 这个类是用来从一个纹理图集中存取纹理.
	 * @author wizardc
	 */
	public class TextureAtlas
	{
		private var mAtlasTexture:Texture2D;
		private var mTextureRegions:Dictionary;
		private var mTextureFrames:Dictionary;
		
		/**
		 * 构造函数.
		 * @param texture 纹理对象.
		 * @param atlasXml XML 数据.
		 */
		public function TextureAtlas(texture:Texture2D, atlasXml:XML = null)
		{
			mTextureRegions = new Dictionary();
			mTextureFrames = new Dictionary();
			mAtlasTexture = texture;
			if(atlasXml != null)
			{
				parseAtlasXml(atlasXml);
			}
		}
		
		private function parseAtlasXml(atlasXml:XML):void
		{
			for each(var subTexture:XML in atlasXml.SubTexture)
			{
				var name:String = subTexture.attribute("name");
				var x:Number = parseFloat(subTexture.attribute("x"));
				var y:Number = parseFloat(subTexture.attribute("y"));
				var width:Number = parseFloat(subTexture.attribute("width"));
				var height:Number = parseFloat(subTexture.attribute("height"));
				var frameX:Number = parseFloat(subTexture.attribute("frameX"));
				var frameY:Number = parseFloat(subTexture.attribute("frameY"));
				var frameWidth:Number = parseFloat(subTexture.attribute("frameWidth"));
				var frameHeight:Number = parseFloat(subTexture.attribute("frameHeight"));
				var region:Rectangle = new Rectangle(x, y, width, height);
				var frame:Rectangle  = frameWidth > 0 && frameHeight > 0 ? new Rectangle(frameX, frameY, frameWidth, frameHeight) : null;
				this.addRegion(name, region, frame);
			}
		}
		
		/**
		 * 根据名称返回一个子级纹理.
		 * @param name 名称.
		 * @return 子级纹理.
		 */
		public function getTexture(name:String):Texture2D
		{
			var region:Rectangle = mTextureRegions[name];
			if(region == null)
			{
				return null;
			}
			else
			{
				var texture:Texture2D = Texture2D.fromTexture(mAtlasTexture, region);
				texture.frame = mTextureFrames[name];
				return texture;
			}
		}
		
		/**
		 * 返回从指定的一个字符串开始的, 按字母排序的所有纹理 (对于 "电影剪辑" 来说非常有用).
		 * @param prefix 前缀名称.
		 * @return 纹理列表.
		 */
		public function getTextures(prefix:String = ""):Vector.<Texture2D>
		{
			var textures:Vector.<Texture2D> = new <Texture2D>[];
			var names:Vector.<String> = new <String>[];
			var name:String;
			for(name in mTextureRegions)
			{
				if(name.indexOf(prefix) == 0)
				{
					names.push(name);
				}
			}
			names.sort(Array.CASEINSENSITIVE);
			for each(name in names)
			{
				textures.push(getTexture(name));
			}
			return textures;
		}
		
		/**
		 * 创建一个 subtexture 区域.
		 * @param name 名称.
		 * @param region 区域.
		 * @param frame 框架区域.
		 */
		public function addRegion(name:String, region:Rectangle, frame:Rectangle = null):void
		{
			mTextureRegions[name] = region;
			if(frame != null)
			{
				mTextureFrames[name] = frame;
			}
		}
		
		/**
		 * 移除一个 subtexture 区域.
		 * @param name 名称.
		 */
		public function removeRegion(name:String):void
		{
			delete mTextureRegions[name];
		}
		
		/**
		 * 销毁纹理对象.
		 */
		public function dispose():void
		{
			mAtlasTexture.dispose();
		}
	}
}

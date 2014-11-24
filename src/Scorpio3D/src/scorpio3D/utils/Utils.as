// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio3D.utils 
{
	import flash.display.BitmapData;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix;
	
	/**
	 * 工具类.
	 * @author wizardc
	 */
	public class Utils
	{
		/**
		 * 创建 Mipmap 纹理并将 src 位图对象并通过 dest 对象上传到显卡.
		 * @param dest 纹理对象.
		 * @param src 位图数据.
		 */
		public static function uploadTextureWithMipmaps(dest:Texture, src:BitmapData):void
		{
			var ws:int = src.width;
			var hs:int = src.height;
			var level:int = 0;
			var tmp:BitmapData;
			var transform:Matrix = new Matrix();
			var tmp2:BitmapData;
			tmp = new BitmapData(src.width, src.height, true, 0x00000000);
			while(ws >= 1 && hs >= 1)
			{
				tmp.draw(src, transform, null, null, null, true);
				dest.uploadFromBitmapData(tmp, level);
				transform.scale(0.5, 0.5);
				level++;
				ws >>= 1;
				hs >>= 1;
				if(hs && ws)
				 {
					tmp.dispose();
					tmp = new BitmapData(ws, hs, true, 0x00000000);
				}
			}
			tmp.dispose();
		}
	}
}

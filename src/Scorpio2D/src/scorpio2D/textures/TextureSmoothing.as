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
	/**
	 * 判断平滑值是否是有效的.
	 * @author wizardc
	 */
	public class TextureSmoothing
	{
		/**
		 * 不具备平滑.
		 */
		public static const NONE:String = "none";
		
		/**
		 * 双线性过滤. 创建像素之间的平稳过渡.
		 */
		public static const BILINEAR:String = "bilinear";
		
		/**
		 * 三线性过滤. 考虑到未来在MIP贴图中使用最高级别的渲染质量.
		 */
		public static const TRILINEAR:String = "trilinear";
		
		/**
		 * 判断平滑值是否是有效的.
		 * @param smoothing 平滑值.
		 * @return 平滑值是否是有效的.
		 */
		public static function isValid(smoothing:String):Boolean
		{
			return smoothing == NONE || smoothing == BILINEAR || smoothing == TRILINEAR;
		}
	}
}

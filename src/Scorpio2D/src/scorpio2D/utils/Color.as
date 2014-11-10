// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio2D.utils
{
	/**
	 * 颜色处理类.
	 * @author wizardc
	 */
	public class Color
	{
		public static const WHITE:uint = 0xffffff;
		
		public static const SILVER:uint = 0xc0c0c0;
		
		public static const GRAY:uint = 0x808080;
		
		public static const BLACK:uint = 0x000000;
		
		public static const RED:uint = 0xff0000;
		
		public static const MAROON:uint = 0x800000;
		
		public static const YELLOW:uint = 0xffff00;
		
		public static const OLIVE:uint = 0x808000;
		
		public static const LIME:uint = 0x00ff00;
		
		public static const GREEN:uint = 0x008000;
		
		public static const AQUA:uint = 0x00ffff;
		
		public static const TEAL:uint = 0x008080;
		
		public static const BLUE:uint = 0x0000ff;
		
		public static const NAVY:uint = 0x000080;
		
		public static const FUCHSIA:uint = 0xff00ff;
		
		public static const PURPLE:uint = 0x800080;
		
		/**
		 * 获取颜色值.
		 * @param red 红.
		 * @param green 绿.
		 * @param blue 蓝.
		 * @return 颜色值.
		 */
		public static function rgb(red:int, green:int, blue:int):uint
		{
			return (red << 16) | (green << 8) | blue;
		}
		
		/**
		 * 获取颜色值.
		 * @param alpha 透明.
		 * @param red 红.
		 * @param green 绿.
		 * @param blue 蓝.
		 * @return 颜色值.
		 */
		public static function argb(alpha:int, red:int, green:int, blue:int):uint
		{
			return (alpha << 24) | (red << 16) | (green << 8) | blue;
		}
		
		/**
		 * 获取颜色值里的分量.
		 * @param color 颜色值.
		 * @return 透明度分量.
		 */
		public static function getAlpha(color:uint):int
		{
			return (color >> 24) & 0xff;
		}
		
		/**
		 * 获取颜色值里的分量.
		 * @param color 颜色值.
		 * @return 红色分量.
		 */
		public static function getRed(color:uint):int
		{
			return (color >> 16) & 0xff;
		}
		
		/**
		 * 获取颜色值里的分量.
		 * @param color 颜色值.
		 * @return 绿色分量.
		 */
		public static function getGreen(color:uint):int
		{
			return (color >> 8) & 0xff;
		}
		
		/**
		 * 获取颜色值里的分量.
		 * @param color 颜色值.
		 * @return 蓝色分量.
		 */
		public static function getBlue(color:uint):int
		{
			return  color & 0xff;
		}
	}
}

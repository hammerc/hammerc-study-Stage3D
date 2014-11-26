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
	import flash.display3D.Context3DBlendFactor;
	
	/**
	 * 混合模式.
	 * 
	 * 一个混合模式，总是被两个"Context3DBlendFactor"值来定义。一个混合因素代表一个特定的四个数值的数组， 这个数组是根据源和目标颜色用
	 * 混合公式计算的。这个公式是：
	 * 
	 * result = source × sourceFactor + destination × destinationFactor
	 * 
	 * 在这个公式里面，源颜色是像素着色器的输出颜色。目标颜色是在上一次清理和绘制操作之后，颜色缓冲区中的目前存在的颜色。
	 * 
	 * 要注意的是，由于不同的纹理类型，混合因素会产生不同的输出。纹理可能包含'预乘透明度'(PMA)， 意思就是他们的RGB色值是根据他们的颜色值分
	 * 别相乘而得到的(以节省计算时间)。基于'BitmapData'的纹理，会拥有预乘透明度值，还有ATF纹理也有这个值。 基于这个原因，一个混合模式可能
	 * 根据PMA值拥有不同的因素。
	 * @author wizardc
	 */
	public class BlendMode2D
	{
		private static var _blendFactors:Array = [
			//不预乘透明通道
			{
				"none"     : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO ],
				"normal"   : [ Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
				"add"      : [ Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.DESTINATION_ALPHA ],
				"multiply" : [ Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ZERO ],
				"screen"   : [ Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE ],
				"erase"    : [ Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ]
			},
			//预乘透明通道
			{
				"none"     : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO ],
				"normal"   : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
				"add"      : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ONE ],
				"multiply" : [ Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
				"screen"   : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR ],
				"erase"    : [ Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ]
			}
		];
		
		/**
		 * 继承这个显示对象的父级的混合模式.
		 */
		public static const AUTO:String = "auto";
		
		/**
		 * 停用混合, 即禁止任何透明度.
		 */
		public static const NONE:String = "none";
		
		/**
		 * 把对象显示在背景的前面.
		 */
		public static const NORMAL:String = "normal";
		
		/**
		 * 添加这个显示对象的颜色值到它的背景色值.
		 */
		public static const ADD:String = "add";
		
		/**
		 * 把这个显示对象的颜色和它的背景色值相乘.
		 */
		public static const MULTIPLY:String = "multiply";
		
		/**
		 * 将显示对象颜色的补码 (反) 与背景颜色的补码相乘, 会产生漂白效果.
		 */
		public static const SCREEN:String = "screen";
		
		/**
		 * 当绘制渲染纹理的时候擦除背景.
		 */
		public static const ERASE:String = "erase";
		
		/**
		 * 根据特定的名称和特定的预乘透明度 (PMA) 注册一个混合模式.
		 * 如果一个用了其他 PMA 值的模式尚未注册, 则两个PMA的设置都会应用这些因素.
		 * @param name 名称.
		 * @param sourceFactor 源因素.
		 * @param destFactor 目的因素.
		 * @param premultipliedAlpha 预乘透明度.
		 */
		public static function register(name:String, sourceFactor:String, destFactor:String, premultipliedAlpha:Boolean = true):void
		{
			var modes:Object = _blendFactors[int(premultipliedAlpha)];
			modes[name] = [sourceFactor, destFactor];
			var otherModes:Object = _blendFactors[int(!premultipliedAlpha)];
			if(!(name in otherModes))
			{
				otherModes[name] = [sourceFactor, destFactor];
			}
		}
		
		/**
		 * 根据指定的模式名称和预乘透明度返回混合因素.
		 * @param mode 模式.
		 * @param premultipliedAlpha 预乘透明度.
		 * @return 混合因素.
		 */
		public static function getBlendFactors(mode:String, premultipliedAlpha:Boolean = true):Array
		{
			var modes:Object = _blendFactors[int(premultipliedAlpha)];
			if(mode in modes)
			{
				return modes[mode];
			}
			else
			{
				throw new ArgumentError("Invalid blend mode");
			}
		}
	}
}

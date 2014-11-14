// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package scorpio2D.utils
{
	/**
	 * 角度转换为弧度.
	 * @param deg 角度.
	 * @return 弧度.
	 */
	public function deg2rad(deg:Number):Number
	{
		return deg / 180 * Math.PI;
	}
}

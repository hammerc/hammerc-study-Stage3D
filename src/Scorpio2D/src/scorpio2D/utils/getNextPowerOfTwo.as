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
	 * 返回下一个等于或大于当前数字的 2 的幂数.
	 * @param number 数.
	 * @return 下一个等于或大于当前数字的 2 的幂数.
	 */
	public function getNextPowerOfTwo(number:int):int
	{
		var result:int = 1;
		while(result < number)
		{
			result *= 2;
		}
		return result;
	}
}

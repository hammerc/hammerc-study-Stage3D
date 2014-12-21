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
	import flash.utils.getTimer;
	
	/**
	 * 游戏计时器类.
	 * @author wizardc
	 */
	public class GameTimer 
	{
		//开始的时间
		public var gameStartTime:Number = 0.0; 
		//上一帧的时间
		public var lastFrameTime:Number = 0.0; 
		//当前的时间
		public var currentFrameTime:Number = 0.0; 
		//距离上一帧经过了多少时间
		public var frameMs:Number = 0.0; 
		//经过了多少帧
		public var frameCount:uint = 0; 
		//下一次心跳的时间
		public var nextHeartbeatTime:uint = 0; 
		//经过的时间
		public var gameElapsedTime:uint = 0; 
		//心跳间隔
		public var heartbeatIntervalMs:uint = 1000; 
		//心跳函数
		public var heartbeatFunction:Function; 
		
		public function GameTimer(heartbeatFunc:Function = null, heartbeatMs:uint = 1000)
		{
			if(heartbeatFunc != null)
			{
				heartbeatFunction = heartbeatFunc;
			}
			heartbeatIntervalMs = heartbeatMs;
		}
		
		public function tick():void
		{
			currentFrameTime = getTimer();
			if(frameCount == 0)
			{
				gameStartTime = currentFrameTime;
				trace("First frame happened after " + gameStartTime + "ms");
				frameMs = 0;
				gameElapsedTime = 0;
			}
			else
			{
				frameMs = currentFrameTime - lastFrameTime;
				gameElapsedTime += frameMs;
			}
			
			if(heartbeatFunction != null)
			{
				if (currentFrameTime >= nextHeartbeatTime)
				{
					heartbeatFunction();
					nextHeartbeatTime = currentFrameTime + heartbeatIntervalMs;
				}
			}
			
			lastFrameTime = currentFrameTime;
			frameCount++;
		}
	}
}

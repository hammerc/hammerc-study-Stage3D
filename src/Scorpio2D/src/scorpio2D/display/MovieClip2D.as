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
	import flash.media.Sound;
	
	import scorpio2D.animation.IAnimatable;
	import scorpio2D.events.Event2D;
	import scorpio2D.textures.Texture2D;
	
	/**
	 * 动画剪辑类, 注意我们这里的动画剪辑对象已经不是一个容器对象了, 根据一个纹理集合显示动画.
	 * 根据传入的纹理集合以及帧频创建一个电影剪辑, 电影剪辑会根据第一帧来确定自己的尺寸.
	 * @author wizardc
	 */
	public class MovieClip2D extends Image2D implements IAnimatable
	{
		private var _textures:Vector.<Texture2D>;
		private var _sounds:Vector.<Sound>;
		private var _durations:Vector.<Number>;
		
		private var _defaultFrameDuration:Number;
		private var _totalTime:Number;
		private var _currentTime:Number;
		private var _currentFrame:int;
		private var _loop:Boolean;
		private var _playing:Boolean;
		
		/**
		 * 构造函数.
		 * @param textures 纹理集合.
		 * @param fps 帧频.
		 */
		public function MovieClip2D(textures:Vector.<Texture2D>, fps:Number = 12)
		{
			if(textures.length > 0)
			{
				super(textures[0]);
				_defaultFrameDuration = 1 / fps;
				_loop = true;
				_playing = true;
				_totalTime = 0;
				_currentTime = 0;
				_currentFrame = 0;
				_textures = new <Texture2D>[];
				_sounds = new <Sound>[];
				_durations = new <Number>[];
				for each(var texture:Texture2D in textures)
				{
					this.addFrame(texture);
				}
			}
			else
			{
				throw new ArgumentError("Empty texture array");
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function get isComplete():Boolean
		{
			return false;
		}
		
		/**
		 * 获取播放总时间.
		 */
		public function get totalTime():Number
		{
			return _totalTime;
		}
		
		/**
		 * 获取播放总帧数.
		 */
		public function get numFrames():int
		{
			return _textures.length;
		}
		
		/**
		 * 设置或获取是否循环播放.
		 */
		public function set loop(value:Boolean):void
		{
			_loop = value;
		}
		public function get loop():Boolean
		{
			return _loop;
		}
		
		/**
		 * 设置或获取当前帧.
		 */
		public function set currentFrame(value:int):void
		{
			_currentFrame = value;
			_currentTime = 0;
			for(var i:int = 0; i < value; ++i)
			{
				_currentTime += this.getFrameDuration(i);
			}
			this.updateCurrentFrame();
		}
		public function get currentFrame():int
		{
			return _currentFrame;
		}
		
		/**
		 * 设置或获取帧率.
		 */
		public function set fps(value:Number):void
		{
			var newFrameDuration:Number = value == 0 ? Number.MAX_VALUE : 1 / value;
			var acceleration:Number = newFrameDuration / _defaultFrameDuration;
			_currentTime *= acceleration;
			_defaultFrameDuration = newFrameDuration;
			for(var i:int = 0; i < numFrames; ++i)
			{
				this.setFrameDuration(i, this.getFrameDuration(i) * acceleration);
			}
		}
		public function get fps():Number
		{
			return 1 / _defaultFrameDuration;
		}
		
		/**
		 * 获取当前是否正在播放.
		 */
		public function get isPlaying():Boolean
		{
			if(_playing)
			{
				return _loop || _currentTime < _totalTime;
			}
			else
			{
				return false;
			}
		}
		
		/**
		 * 为电影剪辑添加一帧.
		 * @param texture 纹理.
		 * @param sound 声音.
		 * @param duration 持续时间.
		 */
		public function addFrame(texture:Texture2D, sound:Sound = null, duration:Number = -1):void
		{
			this.addFrameAt(this.numFrames, texture, sound, duration);
		}
		
		/**
		 * 根据指定的索引添加一帧.
		 * @param frameID 索引.
		 * @param texture 纹理.
		 * @param sound 声音.
		 * @param duration 持续时间.
		 */
		public function addFrameAt(frameID:int, texture:Texture2D, sound:Sound = null, duration:Number = -1):void
		{
			if(frameID < 0 || frameID > this.numFrames)
			{
				throw new ArgumentError("Invalid frame id");
			}
			if(duration < 0)
			{
				duration = _defaultFrameDuration;
			}
			_textures.splice(frameID, 0, texture);
			_sounds.splice(frameID, 0, sound);
			_durations.splice(frameID, 0, duration);
			_totalTime += duration;
		}
		
		/**
		 * 移除指定帧.
		 * @param frameID 索引.
		 */
		public function removeFrameAt(frameID:int):void
		{
			if(frameID < 0 || frameID >= this.numFrames)
			{
				throw new ArgumentError("Invalid frame id");
			}
			_totalTime -= this.getFrameDuration(frameID);
			_textures.splice(frameID, 1);
			_sounds.splice(frameID, 1);
			_durations.splice(frameID, 1);
		}
		
		/**
		 * 设置指定帧的纹理.
		 * @param frameID 索引.
		 * @param texture 纹理.
		 */
		public function setFrameTexture(frameID:int, texture:Texture2D):void
		{
			if(frameID < 0 || frameID >= this.numFrames)
			{
				throw new ArgumentError("Invalid frame id");
			}
			_textures[frameID] = texture;
		}
		
		/**
		 * 获取指定帧的纹理.
		 * @param frameID 索引.
		 * @return 纹理.
		 */
		public function getFrameTexture(frameID:int):Texture2D
		{
			if(frameID < 0 || frameID >= this.numFrames)
			{
				throw new ArgumentError("Invalid frame id");
			}
			return _textures[frameID];
		}
		
		/**
		 * 设置指定帧的声音.
		 * @param frameID 索引.
		 * @param sound 声音.
		 */
		public function setFrameSound(frameID:int, sound:Sound):void
		{
			if(frameID < 0 || frameID >= this.numFrames)
			{
				throw new ArgumentError("Invalid frame id");
			}
			_sounds[frameID] = sound;
		}
		
		/**
		 * 获取指定帧的声音.
		 * @param frameID 索引.
		 * @return 声音.
		 */
		public function getFrameSound(frameID:int):Sound
		{
			if(frameID < 0 || frameID >= this.numFrames)
			{
				throw new ArgumentError("Invalid frame id");
			}
			return _sounds[frameID];
		}
		
		/**
		 * 设置某个特定的帧的执行时长.
		 * @param frameID 索引.
		 * @param duration 执行时长.
		 */
		public function setFrameDuration(frameID:int, duration:Number):void
		{
			if(frameID < 0 || frameID >= this.numFrames)
			{
				throw new ArgumentError("Invalid frame id");
			}
			_totalTime -= this.getFrameDuration(frameID);
			_totalTime += duration;
			_durations[frameID] = duration;
		}
		
		/**
		 * 获取某个特定的帧的执行时长.
		 * @param frameID 索引.
		 * @return 执行时长.
		 */
		public function getFrameDuration(frameID:int):Number
		{
			if(frameID < 0 || frameID >= this.numFrames)
			{
				throw new ArgumentError("Invalid frame id");
			}
			return _durations[frameID];
		}
		
		private function updateCurrentFrame():void
		{
			this.texture = _textures[_currentFrame];
		}
		
		private function playCurrentSound():void
		{
			var sound:Sound = _sounds[_currentFrame];
			if(sound != null)
			{
				sound.play();
			}
		}
		
		/**
		 * 播放.
		 */
		public function play():void
		{
			_playing = true;
		}
		
		/**
		 * 暂停.
		 */
		public function pause():void
		{
			_playing = false;
		}
		
		/**
		 * 停止.
		 */
		public function stop():void
		{
			_playing = false;
			this.currentFrame = 0;
		}
		
		/**
		 * @inheritDoc
		 */
		public function advanceTime(passedTime:Number):void
		{
			if(_loop && _currentTime == _totalTime)
			{
				_currentTime = 0;
			}
			if(!_playing || passedTime == 0 || _currentTime == _totalTime)
			{
				return;
			}
			var i:int = 0;
			var durationSum:Number = 0;
			var previousTime:Number = _currentTime;
			var restTime:Number = _totalTime - _currentTime;
			var carryOverTime:Number = passedTime > restTime ? passedTime - restTime : 0;
			_currentTime = Math.min(_totalTime, _currentTime + passedTime);
			for each(var duration:Number in _durations)
			{
				if(durationSum + duration >= _currentTime)
				{
					if(_currentFrame != i)
					{
						_currentFrame = i;
						this.updateCurrentFrame();
						this.playCurrentSound();
					}
					break;
				}
				++i;
				durationSum += duration;
			}
			if(previousTime < _totalTime && _currentTime == _totalTime && this.hasEventListener(Event2D.COMPLETE))
			{
				this.dispatchEvent(new Event2D(Event2D.COMPLETE));
			}
			this.advanceTime(carryOverTime);
		}
	}
}

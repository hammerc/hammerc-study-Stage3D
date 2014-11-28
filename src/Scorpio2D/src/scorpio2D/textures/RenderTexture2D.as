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
import flash.display3D.Context3D;
import flash.display3D.textures.TextureBase;
	import flash.geom.Rectangle;
	
	import scorpio2D.core.RenderSupport;
	import scorpio2D.core.Scorpio2D;
	import scorpio2D.display.DisplayObject2D;
	import scorpio2D.display.Image2D;
	import scorpio2D.utils.VertexData;
	import scorpio2D.utils.getNextPowerOfTwo;
	
	/**
	 * 动态纹理, 可以用来绘制任何的显示对象 (3D 绘制的对象非传统显示列表对象).
	 * @author wizardc
	 */
	public class RenderTexture2D extends Texture2D
	{
		private var _activeTexture:Texture2D;
		private var _bufferTexture:Texture2D;
		private var _helperImage:Image2D;
		private var _drawing:Boolean;
		private var _nativeWidth:int;
		private var _nativeHeight:int;
		private var _support:RenderSupport;
		
		/**
		 * 构造函数.
		 * @param width 宽度.
		 * @param height 高度.
		 * @param persistent 是否持续.
		 */
		public function RenderTexture2D(width:int, height:int, persistent:Boolean = true)
		{
			_support = new RenderSupport();
			_nativeWidth = getNextPowerOfTwo(width);
			_nativeHeight = getNextPowerOfTwo(height);
			_activeTexture = Texture2D.empty(width, height, 0, true);
			if(persistent)
			{
				_bufferTexture = Texture2D.empty(width, height, 0, true);
				_helperImage = new Image2D(_bufferTexture);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get base():TextureBase
		{
			return _activeTexture.base;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get width():Number
		{
			return _activeTexture.width;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get height():Number
		{
			return _activeTexture.height;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get premultipliedAlpha():Boolean
		{
			return _activeTexture.premultipliedAlpha;
		}
		
		/**
		 * 获取纹理是否是可以持续多次绘制的.
		 */
		public function get isPersistent():Boolean
		{
			return _bufferTexture != null;
		}
		
		/**
		 * 绘制一个显示对象到纹理, 包括它的位置, 缩放值, 角度和透明度.
		 * @param object 显示对象.
		 * @param antiAliasing 抗锯齿程度.
		 */
		public function draw(object:DisplayObject2D, antiAliasing:int = 0):void
		{
			if(object == null)
			{
				return;
			}
			if(_drawing)
			{
				render();
			}
			else
			{
				drawBundled(render, antiAliasing);
			}
			function render():void
			{
				_support.pushMatrix();
				_support.pushBlendMode();
				_support.blendMode = object.blendMode;
				_support.transformMatrix(object);
				object.render(_support, 1.0);
				_support.popMatrix();
				_support.popBlendMode();
			}
		}
		
		/**
		 * 将多次的绘制操作汇集在一个区块.
		 * 这样可以避免反复开关缓冲区, 让您可以绘制多个对象到一个非持久性的纹理.
		 * @param drawingBlock 区块.
		 * @param antiAliasing 抗锯齿程度.
		 */
		public function drawBundled(drawingBlock:Function, antiAliasing:int = 0):void
		{
			var context:Context3D = Scorpio2D.context;
			if(context == null)
			{
				throw new Error();
			}
			context.setScissorRectangle(new Rectangle(0, 0, _activeTexture.width, _activeTexture.height));
			if(isPersistent)
			{
				var tmpTexture:Texture2D = _activeTexture;
				_activeTexture = _bufferTexture;
				_bufferTexture = tmpTexture;
				_helperImage.texture = _bufferTexture;
			}
			context.setRenderToTexture(_activeTexture.base, false, antiAliasing);
			RenderSupport.clear();
			_support.setOrthographicProjection(_nativeWidth, _nativeHeight);
			_support.applyBlendMode(true);
			if(isPersistent)
			{
				_helperImage.render(_support, 1);
			}
			try
			{
				_drawing = true;
				if(drawingBlock != null)
				{
					drawingBlock();
				}
			}
			finally
			{
				_drawing = false;
				_support.finishQuadBatch();
				_support.nextFrame();
				context.setScissorRectangle(null);
				context.setRenderToBackBuffer();
			}
		}
		
		/**
		 * 清除纹理 (恢复完全透明).
		 */
		public function clear():void
		{
			var context:Context3D = Scorpio2D.context;
			if(context == null)
			{
				throw new Error();
			}
			context.setRenderToTexture(_activeTexture.base);
			RenderSupport.clear();
			if(isPersistent)
			{
				context.setRenderToTexture(_activeTexture.base);
				RenderSupport.clear();
			}
			context.setRenderToBackBuffer();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			_activeTexture.dispose();
			if(isPersistent)
			{
				_bufferTexture.dispose();
				_helperImage.dispose();
			}
			super.dispose();
		}
	}
}

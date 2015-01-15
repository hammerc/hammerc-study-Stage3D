// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio3D.input 
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	/**
	 * 游戏输入控制类.
	 * @author wizardc
	 */
	public class GameInput
	{
		//当前的鼠标状态
		public var mouseIsDown:Boolean = false;
		public var mouseClickX:int = 0;
		public var mouseClickY:int = 0;
		public var mouseX:int = 0;
		public var mouseY:int = 0;
		
		//当前的键盘状态
		public var pressing:Object = { up:0, down:0, left:0, right:0, fire:0, strafeLeft:0, strafeRight:0, key0:0, key1:0, key2:0, key3:0, key4:0, key5:0, key6:0, key7:0, key8:0, key9:0 };
		
		//摄像机偏移角度
		public var cameraAngleX:Number = 0;
		public var cameraAngleY:Number = 0;
		public var cameraAngleZ:Number = 0;
		
		//鼠标是否可以控制摄像机偏移
		public var mouseLookMode:Boolean = true;
		
		public var stage:Stage;
		
		//点击时会调用的方法
		private var _clickfunc:Function = null;
		
		public function GameInput(theStage:Stage, clickfunc:Function = null)
		{
			stage = theStage;
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased);
			stage.addEventListener(Event.DEACTIVATE, lostFocus);
			stage.addEventListener(Event.ACTIVATE, gainFocus);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			
			_clickfunc = clickfunc;
		}
		
		private function mouseMove(e:MouseEvent):void
		{
			mouseX = e.stageX;
			mouseY = e.stageY;
			if(mouseIsDown && mouseLookMode)
			{
				cameraAngleY = 90 * ((mouseX - mouseClickX) / stage.width);
				cameraAngleX = 90 * ((mouseY - mouseClickY) / stage.height);
			}
		}
		
		private function mouseDown(e:MouseEvent):void
		{   
			trace('mouseDown at ' + e.stageX + ',' + e.stageY);
			mouseClickX = e.stageX;
			mouseClickY = e.stageY;
			mouseIsDown = true;
			if(_clickfunc != null)
				_clickfunc();
		}
		
		private function mouseUp(e:MouseEvent):void
		{   
			trace('mouseUp at ' + e.stageX + ',' + e.stageY + ' drag distance:' + (e.stageX - mouseClickX) + ',' + (e.stageY - mouseClickY));
			mouseIsDown = false;
			if(mouseLookMode)
			{
				//重置摄像机角度
				cameraAngleX = cameraAngleY = cameraAngleZ = 0;
			}
		}
		
		private function keyPressed(event:KeyboardEvent):void 
		{
			// qwer 81 87 69 82
			// asdf 65 83 68 70
			// left right 37 39
			// up down 38 40
			// 0123456789 = 48 to 57
			// zxcv = 90 88 67 86
			
			//trace("keyPressed " + event.keyCode);
			
			switch(event.keyCode)
			{
				case Keyboard.UP:
				case 87:
				case 90:
					pressing.up = true;
					break;
				case Keyboard.DOWN:
				case 83:
					pressing.down = true;
					break;
				case Keyboard.LEFT:
				case 65:
				case 81:
					pressing.left = true;
					break;
				case Keyboard.RIGHT:
				case 68:
					pressing.right = true;
					break;
				case Keyboard.SPACE:
				case Keyboard.SHIFT:
				case Keyboard.CONTROL:
				case Keyboard.ENTER:
				case 88:
				case 67:
					pressing.fire = true;
					break;
				
				case 48:
					pressing.key0 = true;
					break;
				case 49:
					pressing.key1 = true;
					break;
				case 50:
					pressing.key2 = true;
					break;
				case 51:
					pressing.key3 = true;
					break;
				case 52:
					pressing.key4 = true;
					break;
				case 53:
					pressing.key5 = true;
					break;
				case 54:
					pressing.key6 = true;
					break;
				case 55:
					pressing.key7 = true;
					break;
				case 56:
					pressing.key8 = true;
					break;
				case 57:
					pressing.key9 = true;
					break;
			}
		}
		
		private function gainFocus(event:Event):void 
		{
			trace("Game received keyboard focus.");
		}
		
		//失去焦点时要还原按键状态
		private function lostFocus(event:Event):void 
		{
			trace("Game lost keyboard focus.");
			pressing.up = false;
			pressing.down = false;
			pressing.left = false;
			pressing.right = false;
			pressing.strafeLeft = false;
			pressing.strafeRight = false;
			pressing.fire = false;
			pressing.key0 = false;
			pressing.key1 = false;
			pressing.key2 = false;
			pressing.key3 = false;
			pressing.key4 = false;
			pressing.key5 = false;
			pressing.key6 = false;
			pressing.key7 = false;
			pressing.key8 = false;
			pressing.key9 = false;
		}
		
		private function keyReleased(event:KeyboardEvent):void 
		{
			switch(event.keyCode)
			{
				case Keyboard.UP:
				case 87:
				case 90:
					pressing.up = false;
					break;
				case Keyboard.DOWN:
				case 83:
					pressing.down = false;
					break;
				case Keyboard.LEFT:
				case 65:
				case 81:
					pressing.left = false;
					break;
				case Keyboard.RIGHT:
				case 68:
					pressing.right = false;
					break;
				case Keyboard.SPACE:
				case Keyboard.SHIFT:
				case Keyboard.CONTROL:
				case Keyboard.ENTER:
				case 88:
				case 67:
					pressing.fire = false;
					break;
				
				case 48:
					pressing.key0 = false;
					break;
				case 49:
					pressing.key1 = false;
					break;
				case 50:
					pressing.key2 = false;
					break;
				case 51:
					pressing.key3 = false;
					break;
				case 52:
					pressing.key4 = false;
					break;
				case 53:
					pressing.key5 = false;
					break;
				case 54:
					pressing.key6 = false;
					break;
				case 55:
					pressing.key7 = false;
					break;
				case 56:
					pressing.key8 = false;
					break;
				case 57:
					pressing.key9 = false;
					break;
			}
		}
	}
}

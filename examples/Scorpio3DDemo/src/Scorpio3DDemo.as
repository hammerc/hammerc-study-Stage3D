package
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	import tests.*;
	
	[SWF(width=640, height=480, frameRate=60, backgroundColor="#000000")]
	public class Scorpio3DDemo extends Sprite
	{
		public function Scorpio3DDemo()
		{
			if(stage)
				addedToStageHandler();
			else
				addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		private function addedToStageHandler(event:Event = null):void
		{
			var test:Sprite = new SpaceWarTest();
			addChild(test);
		}
	}
}

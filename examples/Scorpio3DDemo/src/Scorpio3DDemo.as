package
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	import tests.*;
	
	[SWF(width=550, height=400, backgroundColor="#808080", frameRate=60)]
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
			var test:Sprite = new TextureEffectTest();
			addChild(test);
		}
	}
}

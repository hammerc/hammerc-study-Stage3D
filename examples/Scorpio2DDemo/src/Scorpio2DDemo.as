package
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	import scorpio2D.core.Scorpio2D;
	
	import tests.*;
	
	[SWF(width=550, height=400, backgroundColor="#808080", frameRate=60)]
	public class Scorpio2DDemo extends Sprite
	{
		public function Scorpio2DDemo()
		{
			if(stage)
				addedToStageHandler();
			else
				addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		private function addedToStageHandler(event:Event = null):void
		{
			var scorpio2D:Scorpio2D = new Scorpio2D(MovieClipTest, stage);
			scorpio2D.antiAliasing = 4;
			scorpio2D.start();
		}
	}
}

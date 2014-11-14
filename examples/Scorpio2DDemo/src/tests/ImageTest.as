package tests
{
	import scorpio2D.display.Image2D;
	import scorpio2D.display.Sprite2D;
	import scorpio2D.events.EnterFrameEvent2D;
	import scorpio2D.events.Event2D;
	import scorpio2D.textures.Texture2D;
	
	public class ImageTest extends Sprite2D
	{
		[Embed(source="../../assets/img.png")]
		private var IMG_CLASS:Class;
		
		private var _image:Image2D;
		
		public function ImageTest()
		{
			addEventListener(Event2D.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		private function addedToStageHandler(event:Event2D):void
		{
			_image = new Image2D(Texture2D.fromBitmap(new IMG_CLASS()));
			_image.pivotX = 64;
			_image.pivotY = 64;
			_image.x = stage.stageWidth / 2;
			_image.y = stage.stageHeight / 2;
			addChild(_image);
			
			_image.addEventListener(EnterFrameEvent2D.ENTER_FRAME, enterFrameHandler);
		}
		
		private function enterFrameHandler(event:EnterFrameEvent2D):void
		{
			_image.rotation += Math.PI / 180;
		}
	}
}

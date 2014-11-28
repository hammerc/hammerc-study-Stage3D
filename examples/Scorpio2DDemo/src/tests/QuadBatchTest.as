package tests
{
	import scorpio2D.core.Scorpio2D;
	import scorpio2D.display.MovieClip2D;
	import scorpio2D.display.Sprite2D;
	import scorpio2D.events.Event2D;
	import scorpio2D.textures.Texture2D;
	import scorpio2D.textures.TextureAtlas;
	
	public class QuadBatchTest extends Sprite2D
	{
		[Embed(source="../../assets/atlas.png")]
		private var TEX_CLASS:Class;
		
		[Embed(source="../../assets/atlas.xml", mimeType="application/octet-stream")]
		private var XML_CLASS:Class;
		
		public function QuadBatchTest()
		{
			addEventListener(Event2D.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		private function addedToStageHandler(event:Event2D):void
		{
			var textureAtlas:TextureAtlas = new TextureAtlas(Texture2D.fromBitmap(new TEX_CLASS(), false), new XML(new XML_CLASS));
			var names:Array = ["mole/bobbing", "mole/digging", "mole/surfacing"];
			
			for(var i:int = 0; i < 250; i++)
			{
				var textures:Vector.<Texture2D> = textureAtlas.getTextures(names[int(Math.random() * names.length)]);
				
				var movieClip:MovieClip2D = new MovieClip2D(textures, 15);
				movieClip.x = Math.random() * stage.stageWidth;
				movieClip.y = Math.random() * stage.stageHeight;
				movieClip.scaleX = movieClip.scaleY = Math.random() * 0.4 + 0.3;
				Scorpio2D.current.juggler.add(movieClip);
				addChild(movieClip);
			}
		}
	}
}

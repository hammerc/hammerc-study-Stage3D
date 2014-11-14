package tests
{
	import scorpio2D.display.Quad2D;
	import scorpio2D.display.Sprite2D;
	import scorpio2D.events.Event2D;
	
	public class QuadTest extends Sprite2D
	{
		public function QuadTest()
		{
			addEventListener(Event2D.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		private function addedToStageHandler(event:Event2D):void
		{
			//容器测试
			var sprite:Sprite2D = new Sprite2D();
			sprite.x = 50;
			sprite.y = 25;
			sprite.alpha = 0.5;
			sprite.rotation = Math.PI / 16;
			addChild(sprite);
			
			//方块测试
			var quad:Quad2D = new Quad2D(100, 100, 0xffffff);
			quad.x = 50;
			quad.y = 50;
			sprite.addChild(quad);
			
			//为每个顶点上色
			quad = new Quad2D(100, 100);
			quad.x = 200;
			quad.y = 50;
			quad.setVertexColor(0, 0xff0000);
			quad.setVertexColor(1, 0x00ff00);
			quad.setVertexColor(2, 0x0000ff);
			quad.setVertexColor(3, 0xffff00);
			sprite.addChild(quad);
		}
	}
}

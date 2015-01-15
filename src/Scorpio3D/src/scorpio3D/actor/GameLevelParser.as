// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio3D.actor 
{
	import flash.display.BitmapData;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.geom.Point;
	
	/**
	 * 游戏场景解析类.
	 * @author wizardc
	 */
	public class GameLevelParser 
	{
		//创建一个关卡内容数组避免再次查看地图像素, 我们的游戏中不会使用到它
		public var leveldata:Array = [];
		
		public function GameLevelParser() 
		{
			trace("Created a new level parser.");
		}
		
		/**
		 * 根据位图创建对应的对象到场景.
		 * @param keyImage 颜色键值表.
		 * @param mapImage 关卡编辑位图.
		 * @param thecast 实体名称列表.
		 * @param pool 游戏角色创建池.
		 * @param offsetX x 偏移量.
		 * @param offsetY y 偏移量.
		 * @param offsetZ z 偏移量.
		 * @param tileW 每个像素在世界单位上的尺寸.
		 * @param tileH 每个像素在世界单位上的尺寸.
		 * @param trenchlike U形么？表示方向.
		 * @param spiral 螺旋形么？表示螺旋数.
		 * @return 地图的长度.
		 */
		public function spawnActors(keyImage:BitmapData, mapImage:BitmapData, thecast:Array, pool:GameActorPool, offsetX:Number = 0, offsetY:Number = 0, offsetZ:Number = 0, tileW:int = 1, tileH:int = 1, trenchlike:Number = 0, spiral:Number = 0):Number
		{
			trace("Spawning level entities...");
			trace("Actor List length = " + thecast.length);
			trace("keyImage is ", keyImage.width, "x", keyImage.height);
			trace("mapImage is ", mapImage.width, "x", mapImage.height);
			trace("Tile size is ", tileW, "x", tileH);
			trace("Total level size will be ", mapImage.width * tileW, "x", mapImage.height * tileH);
			
			var pos:Matrix3D = new Matrix3D();
			var mapPixel:uint;
			var keyPixel:uint;
			var whichtile:int;
			var ang:Number;
			var degreesToRadians:Number = Math.PI / 180;
			
			//遍历编辑位图上的所有像素并生成对应的对象
			for(var y:int = 0; y < mapImage.height; y++)
			{
				leveldata[y] = [];
				
				for(var x:int = 0; x < mapImage.width; x++)
				{
					mapPixel = mapImage.getPixel(x, y);
					for(var keyY:int = 0; keyY < keyImage.height; keyY++)
					{
						for(var keyX:int = 0; keyX < keyImage.width; keyX++)
						{
							keyPixel = keyImage.getPixel(keyX, keyY);
							if(mapPixel == keyPixel)
							{
								whichtile = keyY * keyImage.width + keyX;
								if(whichtile != 0)
								{
									pos.identity();
									
									//面向摄像机
									pos.appendRotation(180, Vector3D.Y_AXIS);
									//设置位置
									pos.appendTranslation((x * tileW), 0, (y * tileH));
									
									if(trenchlike != 0)
									{
										//U形编队
										ang = x / mapImage.width * 360;
										pos.appendTranslation(0, trenchlike * Math.cos(ang * degreesToRadians) / Math.PI * mapImage.width * tileW, 0);
									}
									
									if(spiral != 0)
									{
										//螺旋形编队
										ang = (((y / mapImage.height * spiral) * 360) - 180);
										pos.appendRotation(-ang, Vector3D.Z_AXIS);
									}
									
									pos.appendTranslation(offsetX, offsetY, offsetZ);
									
									//获取名称是否在列表中
									if(thecast[whichtile - 1])
										//创建对象
										pool.spawn(thecast[whichtile-1], pos);
									
									//将索引进行保存
									leveldata[y][x] = whichtile;
								}
								break;
							}
						}
					}
				}
			}
			
			//获取长度, 告诉游戏终点线在哪里
			return mapImage.height * tileH; 
		}
	}
}

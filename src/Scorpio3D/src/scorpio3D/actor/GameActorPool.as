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
	import flash.utils.Dictionary;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	/**
	 * 游戏角色对象池类.
	 * @author wizardc
	 */
	public class GameActorPool 
	{
		//每个已知种类的名称列表
		private var allNames:Vector.<String>;
		//每个种类的源角色对象
		private var allKinds:Dictionary;
		//包含了每个种类的副本对象
		private var allActors:Dictionary;
		//临时变量
		private var actor:GameActor;
		private var actorList:Vector.<GameActor>;
		//用于统计
		public var actorsCreated:uint = 0;
		public var actorsActive:uint = 0;
		public var totalpolycount:uint = 0;
		public var totalrendered:uint = 0;
		//可用来暂停所有角色的变量
		public var active:Boolean = true;
		//可以按要求隐藏部分地图
		public var visible:Boolean = true;
		
		public function GameActorPool() 
		{
			trace("Actor pool created.");
			allKinds = new Dictionary();
			allActors = new Dictionary();
			allNames = new Vector.<String>();
		}
		
		//定义一个种类
		public function defineActor(name:String, cloneSource:GameActor):void
		{
			trace("New actor type defined: " + name);
			allKinds[name] = cloneSource;
			allNames.push(name);
		}
		
		public function step(ms:uint, collisionDetection:Function = null, collisionReaction:Function = null):void
		{
			//暂停时不要处理
			if (!active) return;
			
			actorsActive = 0;
			for each (actorList in allActors)
			{
				for each (actor in actorList) 
				{
					if (actor.active) 
					{
						actorsActive++;
						actor.step(ms);
						
						//发生碰撞时可以回调的方法
						if (actor.collides && (collisionDetection != null))
						{
							actor.touching = collisionDetection(actor);
							if (actor.touching && (collisionReaction != null))
								collisionReaction(actor, actor.touching);
						}
					}
				}
			}
		}
		
		//渲染
		public function render(view:Matrix3D, projection:Matrix3D):void
		{
			//不可见时不要渲染
			if (!visible) return;
			
			totalpolycount = 0;
			totalrendered = 0;
			var stateChange:Boolean = true;
			for each (actorList in allActors)
			{
				stateChange = true;
				for each (actor in actorList) 
				{
					if (actor.active && actor.visible)
					{
						totalpolycount += actor.polycount;
						totalrendered++;
						actor.render(view, projection, stateChange);
					}
				}
			}
		}
		
		//重用对象池获得新对象
		public function spawn(name:String, pos:Matrix3D = null):GameActor
		{
			var spawned:GameActor = null;
			var reused:Boolean = false;
			if (allKinds[name])
			{
				if (allActors[name])
				{
					for each (actor in allActors[name]) 
					{
						if (!actor.active)
						{
							//trace("A " + name + " was reused.");
							actor.respawn(pos);
							spawned = actor;
							reused = true;
							return spawned;
						}
					}
				}
				else
				{
					//trace("This is the first " + name + " actor.");
					allActors[name] = new Vector.<GameActor>();
				}
				if (!reused) //没有可重用的对象就复制一个新对象出来
				{
					actorsCreated++;
					//trace("Creating a new " + name);
					//trace("Total actors: " + actorsCreated);
					spawned = allKinds[name].cloneactor();
					spawned.classname = name;
					spawned.name = name + actorsCreated;
					spawned.respawn(pos);
					allActors[name].push(spawned);
					//trace("Total " + name + "s: " 
					//+ allActors[name].length);
					return spawned;
				}
			}
			else
			{
				trace("ERROR: unknown actor type: " + name);
			}
			return spawned;
		}
		
		//对角色进行碰撞检测的方法
		public function colliding(checkthis:GameActor):GameActor
		{
			if (!checkthis.visible) return null;
			if (!checkthis.active) return null;
			var hit:GameActor;
			var str:String;
			for each (str in allNames)
			{
				for each (hit in allActors[str]) 
				{
					if (hit.visible && hit.active && checkthis.colliding(hit))
					{
						//trace(checkthis.name + " is colliding with " + hit.name);
						return hit;
					}
					else
					{
						//trace(checkthis.name + " is NOT colliding with " + hit.name);
					}
				}
			}
			return null;
		}
		
		//场景优化：使太远或包围盒以外的角色不可见
		public function hideDistant(pos:Vector3D, maxdist:Number = 500, maxz:Number = 0, minz:Number = 0, maxy:Number = 0, miny:Number = 0, maxx:Number = 0, minx:Number = 0):void
		{
			for each (actorList in allActors)
			{
				for each (actor in actorList) 
				{
					if (actor.active)
					{
						//通过变量场景中的所有物件和 pos 进行距离对比, 太远的对象或者不在包围盒里的对象就不显示
						if ((Vector3D.distance(actor.position, pos) 
							>= (maxdist * actor.radius)) ||
							//非 0 则判断包围盒
							(maxx != 0 && ((pos.x + maxx) < 
								(actor.position.x - actor.radius))) ||
							(maxy != 0 && ((pos.y + maxy) < 
								(actor.position.y - actor.radius))) ||
							(maxz != 0 && ((pos.z + maxz) < 
								(actor.position.z - actor.radius))) ||
							(minx != 0 && ((pos.x + minx) > 
								(actor.position.x + actor.radius))) ||
							(miny != 0 && ((pos.y + miny) > 
								(actor.position.y + actor.radius))) ||
							(minz != 0 && ((pos.z + minz) > 
								(actor.position.z + actor.radius)))
							)
						{
							actor.visible = false;
						}
						else
						{
							actor.visible = true;
						}
					}
				}
			}
		}
		
		//销毁场景中的所有对象，注意没有实际的进行销毁，对象仍在内存中方便下个关卡使用
		public function destroyAll():void
		{
			for each (actorList in allActors)
			{
				for each (actor in actorList) 
				{
					// ready to be respawned
					actor.active = false;
					actor.visible = false;
				}
			}
		}
	}
}

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
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.display3D.Context3D;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.media.Sound;
	
	import scorpio3D.object3D.Entity;
	import scorpio3D.particle.ParticleSystem;
	
	/**
	 * 游戏角色类.
	 * @author wizardc
	 */
	public class GameActor extends Entity 
	{
		//游戏相关的数据
		public var name:String = ''; //唯一
		public var classname:String = ''; //不唯一
		public var owner:GameActor; //不能射击自己
		public var touching:GameActor; //最近的碰撞检测
		public var active:Boolean = true; //是否活动
		public var visible:Boolean = true; //是否渲染
		public var health:Number = 1; //为0时死亡
		public var damage:Number = 250; //攻击力
		public var points:Number = 25; //被摧毁的分数
		public var collides:Boolean = false; //是否检测碰撞
		public var collidemode:uint = 0; //0=球体, 1=AABB
		public var radius:Number = 1; //用于球体碰撞
		public var aabbMin:Vector3D = new Vector3D(1, 1, 1, 1);
		public var aabbMax:Vector3D = new Vector3D(1, 1, 1, 1);
		//回调方法
		public var runConstantly:Function;
		public var runConstantlyDelay:uint = 1000;
		public var runWhenNoHealth:Function;
		public var runWhenMaxAge:Function;
		public var runWhenCreated:Function;
		//时间相关的变量
		public var age:uint = 0;
		public var ageMax:uint = 0;
		public var stepCounter:uint = 0;
		//以秒为单位的动画变量
		public var posVelocity:Vector3D;
		public var rotVelocity:Vector3D;
		public var scaleVelocity:Vector3D;
		public var tintVelocity:Vector3D;
		//接近敌人时自动射击
		public var bullets:GameActorPool;
		public var shootName:String = '';
		public var shootDelay:uint = 4000;
		public var shootNext:uint = 0;
		public var shootRandomDelay:Number = 2000;
		public var shootDist:Number = 100;
		public var shootAt:GameActor = null;
		public var shootVelocity:Number = 50;
		public var shootSound:Sound;
		//产生粒子
		public var particles:ParticleSystem;
		public var spawnConstantly:String = '';
		public var spawnConstantlyDelay:uint = 0;
		public var spawnConstantlyNext:uint = 0;
		public var spawnWhenNoHealth:String = '';
		public var spawnWhenMaxAge:String = '';
		public var spawnWhenCreated:String = '';
		//声音
		public var soundConstantlyDelay:uint = 1000;
		public var soundConstantlyNext:uint = 0;
		public var soundConstantly:Sound;
		public var soundWhenNoHealth:Sound;
		public var soundWhenMaxAge:Sound;
		public var soundWhenCreated:Sound;
		
		public function GameActor(mydata:Class = null, mycontext:Context3D = null, myshader:Program3D = null, mytexture:Texture = null, modelscale:Number = 1, flipAxis:Boolean = true, flipTexture:Boolean = true) 
		{
			super(mydata, mycontext, myshader, mytexture, modelscale, flipAxis, flipTexture);
		}
		
		public function step(ms:uint):void
		{
			if (!active) return;
			
			age += ms;
			stepCounter++;
			
			if (health <= 0)
			{
				//trace(name + " out of health.");
				if (particles && spawnWhenNoHealth)
				{
					trace(name + " exploding into " + spawnWhenNoHealth);
					//在角色的当前位置产生角色死亡时的特效
					var spawnxform:Matrix3D = new Matrix3D();
					spawnxform.position = position.clone();
					//particles.spawn(spawnWhenNoHealth,transform);
					particles.spawn(spawnWhenNoHealth,spawnxform,5555,0,10);
				}
				if (soundWhenNoHealth)
					soundWhenNoHealth.play();
				if (runWhenNoHealth != null)
					runWhenNoHealth();
				die();
				return;
			}
			
			//到达寿命终点时
			if ((ageMax != 0) && (age >= ageMax))
			{
				//trace(name + " old age.");
				if (particles && spawnWhenMaxAge)
					particles.spawn(spawnWhenMaxAge, transform);
				if (soundWhenMaxAge)
					soundWhenMaxAge.play();
				if (runWhenMaxAge != null)
					runWhenMaxAge();
				die();
				return;
			}
			
			//每帧都会调整的数据
			if (posVelocity)
			{
				x += posVelocity.x * (ms / 1000);
				y += posVelocity.y * (ms / 1000);
				z += posVelocity.z * (ms / 1000);
			}
			if (rotVelocity)
			{
				rotationDegreesX += rotVelocity.x * (ms / 1000);
				rotationDegreesY += rotVelocity.y * (ms / 1000);
				rotationDegreesZ += rotVelocity.z * (ms / 1000);
			}
			if (scaleVelocity)
			{
				scaleX += scaleVelocity.x * (ms / 1000);
				scaleY += scaleVelocity.y * (ms / 1000);
				scaleZ += scaleVelocity.z * (ms / 1000);
			}
			
			//间隔特定的时间产生新的粒子
			if (visible && particles && spawnConstantlyDelay > 0)
			{
				if (spawnConstantly != '')
				{
					if (age >= spawnConstantlyNext)
					{
						//trace("actor spawn " + spawnConstantly);
						spawnConstantlyNext = age + spawnConstantlyDelay;
						particles.spawn(spawnConstantly, transform);
					}
				}
			}
			
			//间隔特定的时间播放声音
			if (visible && soundConstantlyDelay > 0)
			{
				if (soundConstantly)
				{
					if (age >= soundConstantlyNext)
					{
						soundConstantlyNext = age + soundConstantlyDelay;
						soundConstantly.play();
					}
				}
			}
			
			//进行射击
			if (visible && bullets && (shootName != ''))
			{
				var shouldShoot:Boolean = false;
				if (age >= shootNext)
				{
					//计算下一次射击的时间
					shootNext = age + shootDelay + (Math.random() * shootRandomDelay);
					
					//判断射击距离是否需要进行射击
					if (shootDist < 0) 
						shouldShoot = true;
					else if (shootAt && (shootDist > 0) && (Vector3D.distance(position, shootAt.position) <= shootDist))
					{
						shouldShoot = true;
					}
					
					//是否需要进行射击
					if (shouldShoot)
					{
						//创建新的子弹
						var b:GameActor = bullets.spawn(shootName, transform);
						
						//重新设置子弹的发射者
						b.owner = this;
						
						//子弹存在目标敌人
						if (shootAt)
						{
							b.transform.pointAt(shootAt.transform.position);
							b.rotationDegreesY -= 90;
							
							b.posVelocity = b.transform.position.subtract(shootAt.transform.position);
							b.posVelocity.normalize();
							b.posVelocity.negate();
							b.posVelocity.scaleBy(shootVelocity);
						}
						//子弹没有目标敌人就按子弹自身初始化时的方向发射
						
						if (shootSound) 
							shootSound.play();
					}
				}
			}
		}
		
		public function die():void
		{
			//trace(name + " dies!");
			active = false;
			visible = false;
		}
		
		public function respawn(pos:Matrix3D = null):void
		{
			age = 0;
			stepCounter = 0;
			active = true;
			visible = true;
			
			//不要立刻就进行射击
			shootNext = Math.random() * shootRandomDelay;
			
			if (pos)
			{	
				transform = pos.clone();
			}
			
			if (soundWhenCreated)
				soundWhenCreated.play();
			
			if (runWhenCreated != null)
				runWhenCreated();
			
			if (particles && spawnWhenCreated)
				particles.spawn(spawnWhenCreated, transform);
			
			//trace("Respawned " + name + " at " + posString());
		}
		
		//在 GameActorpool 中进行调用的碰撞检测方法
		public function colliding(checkme:GameActor):GameActor
		{
			if (collidemode == 0)
			{
				if (isCollidingSphere(checkme))
					return checkme;
				else
					return null;
			}
			else
			{
				if (isCollidingAabb(checkme))
					return checkme;
				else
					return null;
			}
		}
		
		//简单的球体碰撞检测
		public function isCollidingSphere(checkme:GameActor):Boolean
		{
			//不和自己进行碰撞
			if (this == checkme) return false;
			//只检测可碰撞的物体
			if (!collides || !checkme.collides) return false;
			//不检测自己发送的子弹
			if (checkme.owner == this) return false;
			//不检测没有半径的物体
			if (radius == 0 || checkme.radius == 0) return false;
			
			//获取距离
			var dist:Number = Vector3D.distance(position, checkme.position);
			
			//距离小于两个物体的半径和则认为进行了碰撞
			if (dist <= (radius+checkme.radius))
			{
				// trace("Collision detected at distance="+dist);
				touching = checkme; //记录谁碰撞了我
				return true;
			}
			
			//没有碰撞
			// trace("No collision. Dist = "+dist);
			return false;
		}
		
		//AABB 包围盒碰撞检测, AABB 包围盒使用两个点表示为一个不会进行旋转的轴对齐盒子区域
		//我们的示例中没有使用这个方法
		private function aabbCollision(min1:Vector3D, max1:Vector3D, min2:Vector3D, max2:Vector3D):Boolean
		{
			if (min1.x > max2.x || min1.y > max2.y || min1.z > max2.z || max1.x < min2.x || max1.y < min2.y || max1.z < min2.z)
			{
				return false;
			}	
			return true;
		}
		
		public function isCollidingAabb(checkme:GameActor):Boolean
		{
			//不和自己进行碰撞
			if (this == checkme) return false;
			//只检测可碰撞的物体
			if (!collides || !checkme.collides) return false;
			//不检测自己发送的子弹
			if (checkme.owner == this) return false;
			//没有 AABB 数据不进行检测
			if (aabbMin == null || aabbMax == null || checkme.aabbMin == null || checkme.aabbMax == null) 
				return false;
			
			//判断是否进行了碰撞
			if (aabbCollision(position + aabbMin, position + aabbMax, checkme.position + checkme.aabbMin, checkme.position + checkme.aabbMax))
			{
				touching = checkme; // remember who hit us
				return true;
			}
			
			// trace("No collision.");
			return false;
		}
		
		public function cloneactor():GameActor
		{
			var myclone:GameActor = new GameActor();
			updateTransformFromValues();
			myclone.transform = this.transform.clone();
			myclone.updateValuesFromTransform();
			myclone.mesh = this.mesh;
			myclone.texture = this.texture;
			myclone.shader = this.shader;
			myclone.vertexBuffer = this.vertexBuffer;
			myclone.indexBuffer = this.indexBuffer;
			myclone.context = this.context;
			myclone.polycount = this.polycount;
			myclone.blendSrc = this.blendSrc;
			myclone.blendDst = this.blendDst;
			myclone.cullingMode = this.cullingMode;
			myclone.depthTestMode = this.depthTestMode;
			myclone.depthTest = this.depthTest;
			myclone.depthDraw = this.depthDraw;
			// game-related stats
			myclone.name = this.name;
			myclone.classname = this.classname;
			myclone.owner = this.owner;
			myclone.active = this.active;
			myclone.visible = this.visible;
			myclone.health = this.health;
			myclone.damage = this.damage;
			myclone.points = this.points;
			myclone.collides = this.collides;
			myclone.collidemode = this.collidemode;
			myclone.radius = this.radius;
			myclone.aabbMin = this.aabbMin.clone();
			myclone.aabbMax = this.aabbMax.clone();
			// callback functions
			myclone.runConstantly = this.runConstantly;
			myclone.runConstantlyDelay = this.runConstantlyDelay;
			myclone.runWhenNoHealth = this.runWhenNoHealth;
			myclone.runWhenMaxAge = this.runWhenMaxAge;
			myclone.runWhenCreated = this.runWhenCreated;
			// time-related vars
			myclone.age = this.age;
			myclone.ageMax = this.ageMax;
			myclone.stepCounter = this.stepCounter;
			// animation-related vars - per ms
			myclone.posVelocity = this.posVelocity;
			myclone.rotVelocity = this.rotVelocity;
			myclone.scaleVelocity = this.scaleVelocity;
			myclone.tintVelocity = this.tintVelocity;
			// bullets
			myclone.bullets = this.bullets;
			myclone.shootName = this.shootName;
			myclone.shootDelay = this.shootDelay;
			myclone.shootNext = this.shootNext;
			myclone.shootRandomDelay = this.shootRandomDelay;
			myclone.shootDist = this.shootDist;
			myclone.shootAt = this.shootAt;
			myclone.shootVelocity = this.shootVelocity;
			myclone.shootSound = this.shootSound;
			// spawnable particles
			myclone.particles = this.particles;
			myclone.spawnConstantly = this.spawnConstantly;
			myclone.spawnConstantlyDelay = this.spawnConstantlyDelay;
			myclone.spawnConstantlyNext = this.spawnConstantlyNext;
			myclone.spawnWhenNoHealth = this.spawnWhenNoHealth;
			myclone.spawnWhenMaxAge = this.spawnWhenMaxAge;
			myclone.spawnWhenCreated = this.spawnWhenCreated;
			// sound effects
			myclone.soundConstantlyDelay = this.soundConstantlyDelay;
			myclone.soundConstantlyNext = this.soundConstantlyNext;
			myclone.soundConstantly = this.soundConstantly;
			myclone.soundWhenNoHealth = this.soundWhenNoHealth;
			myclone.soundWhenMaxAge = this.soundWhenMaxAge;
			myclone.soundWhenCreated = this.soundWhenCreated;
			myclone.active = true;
			myclone.visible = true;
			return myclone;
		}
	}
}

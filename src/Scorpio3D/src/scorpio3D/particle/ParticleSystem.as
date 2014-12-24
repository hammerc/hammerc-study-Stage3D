// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio3D.particle 
{
	import flash.utils.Dictionary;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	/**
	 * 粒子系统管理类.
	 * @author wizardc
	 */
	public class ParticleSystem
	{
		//用于复制大量粒子的源对象, 这些对象不会进行渲染, 只是作为一个源用来拷贝真正用于渲染的对象的
		private var allKinds:Dictionary;
		//实际被复制出的粒子副本对象, 这里的粒子会进行渲染
		private var allParticles:Dictionary;
		//临时变量
		private var particleList:Vector.<Particle>;
		private var particle:Particle;
		//只用于统计
		public var particlesCreated:uint = 0;
		public var particlesActive:uint = 0;
		public var totalpolycount:uint = 0;
		
		public function ParticleSystem() 
		{
			trace("Particle system created.");
			allKinds = new Dictionary();
			allParticles = new Dictionary();
		}
		
		/**
		 * 定义一个特定名称的粒子类型.
		 */
		public function defineParticle(name:String, cloneSource:Particle):void
		{
			trace("New particle type defined: " + name);
			allKinds[name] = cloneSource;
		}
		
		/**
		 * 更新所有的粒子对象.
		 */
		public function step(ms:uint):void
		{
			particlesActive = 0;
			for each (particleList in allParticles)
			{
				for each (particle in particleList) 
				{
					if (particle.active) 
					{
						particlesActive++;
						particle.step(ms);
					}
				}
			}
		}
		
		/**
		 * 渲染所有的粒子.
		 */
		public function render(view:Matrix3D, projection:Matrix3D):void
		{
			totalpolycount = 0;
			for each (particleList in allParticles)
			{
				for each (particle in particleList) 
				{
					if (particle.active)
					{
						totalpolycount += particle.polycount;
						particle.render(view, projection);
					}
				}
			}
		}
		
		/**
		 * 创建一个新的粒子. 如果可以重用则使用已经存在的粒子.
		 */
		public function spawn(name:String, pos:Matrix3D, maxage:Number = 1000, scale1:Number = 1, scale2:Number = 50):void
		{
			var reused:Boolean = false;
			if (allKinds[name])
			{
				if (allParticles[name])
				{
					for each (particle in allParticles[name]) 
					{
						if (!particle.active)
						{
							//trace("A " + name + " was reused.");
							particle.respawn(pos, maxage, scale1, scale2);
							particle.updateValuesFromTransform();
							reused = true;
							return;
						}
					}
				}
				else
				{
					trace("This is the first " + name + " particle.");
					allParticles[name] = new Vector.<Particle>;
				}
				if (!reused) //没有可以使用的就重新创建一个
				{
					particlesCreated++;
					trace("Creating a new " + name);
					trace("Total particles: " + particlesCreated);
					var newParticle:Particle = allKinds[name].cloneparticle();
					newParticle.respawn(pos, maxage, scale1, scale2);
					newParticle.updateValuesFromTransform();
					allParticles[name].push(newParticle);
				}
			}
			else
			{
				trace("ERROR: unknown particle type: " + name);
			}
		}
	}
}

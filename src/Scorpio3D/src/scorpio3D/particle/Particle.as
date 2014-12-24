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
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	
	import scorpio3D.object3D.Entity;
	import scorpio3D.parsers.ObjParser;
	
	/**
	 * 粒子特效类.
	 * @author wizardc
	 */
	public class Particle extends Entity
	{
		private static const TWO_PI:Number = 2 * Math.PI;
		
		public var active:Boolean = true;
		public var age:uint = 0;
		public var ageMax:uint = 1000;
		public var stepCounter:uint = 0;
		
		private var _mesh2:ObjParser;
		private var _ageScale:Vector.<Number> = new Vector.<Number>([1, 0, 1, 1]);
		private var _rgbaScale:Vector.<Number> = new Vector.<Number>([1, 1, 1, 1]);
		private var _startSize:Number = 0;
		private var _endSize:Number = 1;
		
		private var _rendermatrix:Matrix3D = new Matrix3D();
		
		public function Particle(mydata:Class = null, mycontext:Context3D = null, mytexture:Texture = null, mydata2:Class = null) 
		{
			transform = new Matrix3D();
			context = mycontext;
			texture = mytexture;
			
			//为粒子特别设计的着色器
			//存在第二个网格的话则随时间从一个网格向另一个进行插值
			if (context && mydata2) initParticleShader(true);
			//只有一个网格则使用简单的着色器
			else if (context) initParticleShader(false);
			
			if (mydata && context)
			{
				mesh = new ObjParser(mydata, context, 1, true, true);
				polycount = mesh.indexBufferCount;
				trace("Mesh has " + polycount + " polygons.");
			}
			
			//解析第二个网格
			if (mydata2 && context)
				_mesh2 = new ObjParser(mydata2, context, 1, true, true);
			
			//默认的粒子渲染模式
			blendSrc = Context3DBlendFactor.ONE;
			blendDst = Context3DBlendFactor.ONE;
			cullingMode = Context3DTriangleFace.NONE;
			depthTestMode = Context3DCompareMode.ALWAYS;
			depthTest = false;
		}
		
		private function initParticleShader(twomodels:Boolean = false):void
		{
			var vertexShader:AGALMiniAssembler = new AGALMiniAssembler();
			var fragmentShader:AGALMiniAssembler = new AGALMiniAssembler();
			
			if (twomodels)
			{
				trace("Compiling the TWO FRAME particle shader...");
				vertexShader.assemble
				(
					Context3DProgramType.VERTEX,
					//换算起始坐标
					"mul vt0, va0, vc4.xxxx\n" + 
					//换算终止坐标
					"mul vt1, va2, vc4.yyyy\n" + 
					//在两个坐标里进行插值
					"add vt2, vt0, vt1\n" + 
					//和 mvp 矩阵进行 4x4 运算
					"m44 op, vt2, vc0\n" +
					//将 uv 数据传递到片段着色器
					"mov v1, va1"
				);
			}
			else
			{
				trace("Compiling the ONE FRAME particle shader...");
				vertexShader.assemble
				(
					Context3DProgramType.VERTEX,
					//和 mvp 矩阵进行 4x4 运算
					"m44 op, va0, vc0\n" +
					//将 uv 数据传递到片段着色器
					"mov v1, va1"
				);
			}
			
			fragmentShader.assemble
			( 
				Context3DProgramType.FRAGMENT,
				//对纹理进行取样
				"tex ft0, v1, fs0 <2d,linear,repeat,miplinear>\n" +
				//乘以淡入淡出矩阵
				"mul ft0, ft0, fc0\n" + 
				//输出颜色
				"mov oc, ft0\n"
			);
			
			shader = context.createProgram();
			shader.upload(vertexShader.agalcode, fragmentShader.agalcode);
		}
		
		public function step(ms:uint):void
		{
			stepCounter++;
			age += ms;
			//粒子结束
			if (age >= ageMax)
			{
				//trace("Particle died (" + age + "ms)");
				active = false;
				return;
			}
			//根据时间改变起始位置的比例 (1 到 0)
			_ageScale[0] = 1 - (age / ageMax);
			//根据时间改变结束位置的比例 (0 到 1)
			_ageScale[1] = age / ageMax;
			//根据时间获得 0 - 1 - 0 之间的数
			_ageScale[2] = wobble010(age);
			//确保在有效范围内
			if (_ageScale[0] < 0) _ageScale[0] = 0;
			if (_ageScale[0] > 1) _ageScale[0] = 1;
			if (_ageScale[1] < 0) _ageScale[1] = 0;
			if (_ageScale[1] > 1) _ageScale[1] = 1;
			if (_ageScale[2] < 0) _ageScale[2] = 0;
			if (_ageScale[2] > 1) _ageScale[2] = 1;
			//使 Alpha 淡入淡出
			_rgbaScale[0] = _ageScale[0];
			_rgbaScale[1] = _ageScale[0];
			_rgbaScale[2] = _ageScale[0];
			_rgbaScale[3] = _ageScale[2];
		}
		
		/**
		 * 返回每秒之间在 -amp 到 amp 之间来回摇摆的数字.
		 */
		private function wobble(ms:Number = 0, amp:Number = 1, spd:Number = 1):Number
		{
			var val:Number;
			val = amp * Math.sin((ms / 1000) * spd * TWO_PI);
			return val;
		}
		
		/**
		 * 返回每秒之间在 0 - 1 - 0 之间来回摇摆的数字.
		 */
		private function wobble010(ms:Number):Number 
		{
			var retval:Number;
			retval = wobble(ms - 250, 0.5, 1.0) + 0.5;
			return retval;
		}
		
		override public function render(view:Matrix3D, projection:Matrix3D, statechanged:Boolean = true):void
		{
			//关键数据被设置后才能进行渲染
			if (!active) return;
			if (!mesh) return;
			if (!_mesh2) return;
			if (!context) return;
			if (!shader) return;
			if (!texture) return;
			
			//随时间变大
			scaleXYZ = _startSize + ((_endSize - _startSize) * _ageScale[1]);
			
			//重置矩阵
			_rendermatrix.identity();
			_rendermatrix.append(transform);
			if (following)
				_rendermatrix.append(following.transform);
			_rendermatrix.append(view);
			_rendermatrix.append(projection);
			
			//设置 vc0 为 mvp 矩阵
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _rendermatrix, true);
			
			//设置 vc4 为随时间不同进行不同顶点位置插值的 _ageScale 数据
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _ageScale);
			
			//设置 fc0 为随时间不同进行不同透明度插值的 _rgbaScale 数据
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _rgbaScale);
			
			context.setProgram(shader);
			//设置 fs0
			context.setTextureAt(0, texture);
			//开始位置 va0
			context.setVertexBufferAt(0, mesh.positionsBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			//uv坐标 va1
			context.setVertexBufferAt(1, mesh.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			//最终位置 va2
			if (_mesh2)
			{
				context.setVertexBufferAt(2, _mesh2.positionsBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			}
			
			//设置渲染模式
			context.setBlendFactors(blendSrc, blendDst);
			context.setDepthTest(depthTest,depthTestMode);
			context.setCulling(cullingMode);
			
			//绘制
			context.drawTriangles(mesh.indexBuffer, 0, mesh.indexBufferCount);
		}
		
		/**
		 * 重置当前粒子, 用于粒子对象池中.
		 */
		public function respawn(pos:Matrix3D, maxage:uint = 1000, scale1:Number = 0, scale2:Number = 50):void
		{
			age = 0;
			stepCounter = 0;
			ageMax = maxage;
			transform = pos.clone();
			updateValuesFromTransform();
			rotationDegreesX = 180; //朝下
			//初始化随机发现
			rotationDegreesY = Math.random() * 360 - 180;
			updateTransformFromValues();
			_ageScale[0] = 1;
			_ageScale[1] = 0;
			_ageScale[2] = 0;
			_ageScale[3] = 1;
			_rgbaScale[0] = 1;
			_rgbaScale[1] = 1;
			_rgbaScale[2] = 1;
			_rgbaScale[3] = 1;
			_startSize = scale1;
			_endSize = scale2;
			active = true;
			//trace("Respawned particle at " + posString());
		}
		
		/**
		 * 创建当前对象的一个副本, 同时重用同一个 ObjParser 对象, 避免多次解析和减小内存使用.
		 * @return 当前对象的副本.
		 */
		public function cloneparticle():Particle
		{
			var myclone:Particle = new Particle();
			updateTransformFromValues();
			myclone.transform = this.transform.clone();
			myclone.mesh = this.mesh;
			myclone.texture = this.texture;
			myclone.shader = this.shader;
			myclone.vertexBuffer = this.vertexBuffer;
			myclone.indexBuffer = this.indexBuffer;
			myclone.context = this.context;
			myclone.updateValuesFromTransform();
			myclone._mesh2 = this._mesh2;
			myclone._startSize = this._startSize;
			myclone._endSize = this._endSize;
			myclone.polycount = this.polycount;
			return myclone;
		}
	}
}

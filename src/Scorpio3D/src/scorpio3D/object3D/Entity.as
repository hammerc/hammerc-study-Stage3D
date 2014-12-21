// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio3D.object3D
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import scorpio3D.parsers.ObjParser;
	
	/**
	 * 3D 对象实体类.
	 * @author wizardc
	 */
	public class Entity
	{
		private const RAD_TO_DEG:Number = 180 / Math.PI;
		
		//将下面的向量定义为常量, 避免每帧进行创建
		private static const vecft:Vector3D = new Vector3D(0, 0, 1);
		private static const vecbk:Vector3D = new Vector3D(0, 0, -1);
		private static const veclf:Vector3D = new Vector3D(-1, 0, 0);
		private static const vecrt:Vector3D = new Vector3D(1, 0, 0);
		private static const vecup:Vector3D = new Vector3D(0, 1, 0);
		private static const vecdn:Vector3D = new Vector3D(0, -1, 0);
		
		//矩阵变量, 位置和旋转等
		private var _transform:Matrix3D;
		private var _inverseTransform:Matrix3D;
		private var _transformNeedsUpdate:Boolean;
		private var _valuesNeedUpdate:Boolean;
		private var _x:Number = 0;
		private var _y:Number = 0;
		private var _z:Number = 0;
		private var _rotationDegreesX:Number = 0;
		private var _rotationDegreesY:Number = 0;
		private var _rotationDegreesZ:Number = 0;
		private var _scaleX:Number = 1;
		private var _scaleY:Number = 1;
		private var _scaleZ:Number = 1;
		
		//用于 stage3d 绘制的对象
		public var context:Context3D;
		public var vertexBuffer:VertexBuffer3D;
		public var indexBuffer:IndexBuffer3D;
		public var shader:Program3D;
		public var texture:Texture;
		public var mesh:ObjParser;
		
		//渲染模式
		public var cullingMode:String = Context3DTriangleFace.FRONT;
		public var blendSrc:String = Context3DBlendFactor.ONE;
		public var blendDst:String = Context3DBlendFactor.ZERO;
		public var depthTestMode:String = Context3DCompareMode.LESS;
		public var depthTest:Boolean = true;
		public var depthDraw:Boolean = true;
		
		//三角形数量
		public var polycount:uint = 0;
		
		//记录当前实体对象是否跟随另一个实体对象
		public var following:Entity;
		
		//根据着色器要求, 优化我们需要送入 stage3d 的数据
		public var shaderUsesUV:Boolean = true;
		public var shaderUsesRgba:Boolean = true;
		public var shaderUsesNormals:Boolean = false;
		
		//辅助对象, 避免大量创建新对象
		private var _posvec:Vector3D = new Vector3D();
		private var _scalevec:Vector3D = new Vector3D();
		
		//渲染中用于每帧重用的临时变量
		private var _rendermatrix:Matrix3D = new Matrix3D();
		
		public function Entity(mydata:Class = null, mycontext:Context3D = null, myshader:Program3D = null, mytexture:Texture = null, modelscale:Number = 1, flipAxis:Boolean = true, flipTexture:Boolean = true) 
		{
			_transform = new Matrix3D();
			context = mycontext;
			shader = myshader;
			texture = mytexture;
			if(mydata && context)
			{
				//解析数据
				mesh = new ObjParser(mydata, context, modelscale, flipAxis, flipTexture);
				polycount = mesh.indexBufferCount;
				trace("Mesh has " + polycount + " polygons.");
			}
		}
		
		/**
		 * 设置或获取转换矩阵.
		 */
		public function set transform(value:Matrix3D):void
		{
			_transform = value;
			_transformNeedsUpdate = false;
			_valuesNeedUpdate = true;
		}
		public function get transform():Matrix3D
		{
			if(_transformNeedsUpdate)
				updateTransformFromValues();
			return _transform;
		}
		
		/**
		 * 设置或获取位置.
		 */
		public function set position(value:Vector3D):void
		{
			_x = value.x;
			_y = value.y;
			_z = value.z;
			_transformNeedsUpdate = true;
		}
		public function get position():Vector3D
		{
			if(_valuesNeedUpdate)
				updateValuesFromTransform();
			//优化, 不创建新对象
			// e.g. return new Vector3D(_x, _y, _z);
			_posvec.setTo(_x, _y, _z);
			return _posvec;
		}
		
		/**
		 * 设置或获取 x.
		 */
		public function set x(value:Number):void
		{
			_x = value;
			_transformNeedsUpdate = true;
		}
		public function get x():Number
		{
			if(_valuesNeedUpdate)
				updateValuesFromTransform();
			return _x;
		}
		
		/**
		 * 设置或获取 y.
		 */
		public function set y(value:Number):void
		{
			_y = value;
			_transformNeedsUpdate = true;
		}
		public function get y():Number
		{
			if(_valuesNeedUpdate)
				updateValuesFromTransform();
			return _y;
		}
		
		/**
		 * 设置或获取 z.
		 */
		public function set z(value:Number):void
		{
			_z = value;
			_transformNeedsUpdate = true;
		}
		public function get z():Number
		{
			if(_valuesNeedUpdate)
				updateValuesFromTransform();
			return _z;
		}
		
		/**
		 * 设置或获取 x 轴的角度.
		 */
		public function set rotationDegreesX(value:Number):void
		{
			_rotationDegreesX = value;
			_transformNeedsUpdate = true;
		}
		public function get rotationDegreesX():Number
		{
			if(_valuesNeedUpdate)
				updateValuesFromTransform();
			return _rotationDegreesX;
		}
		
		/**
		 * 设置或获取 y 轴的角度.
		 */
		public function set rotationDegreesY(value:Number):void
		{
			_rotationDegreesY = value;
			_transformNeedsUpdate = true;
		}
		public function get rotationDegreesY():Number
		{
			if(_valuesNeedUpdate)
				updateValuesFromTransform();
			return _rotationDegreesY;
		}
		
		/**
		 * 设置或获取 z 轴的角度.
		 */
		public function set rotationDegreesZ(value:Number):void
		{
			_rotationDegreesZ = value;
			_transformNeedsUpdate = true;
		}
		public function get rotationDegreesZ():Number
		{
			if(_valuesNeedUpdate)
				updateValuesFromTransform();
			return _rotationDegreesZ;
		}
		
		/**
		 * 设置或获取缩放.
		 */
		public function set scale(vec:Vector3D):void
		{
			_scaleX = vec.x;
			_scaleY = vec.y;
			_scaleZ = vec.z;
			_transformNeedsUpdate = true;
		}
		public function get scale():Vector3D
		{
			if(_valuesNeedUpdate)
				updateValuesFromTransform();
			//优化, 不创建新对象
			//return new Vector3D(_scaleX, _scaleY, _scaleZ, 1.0);
			_scalevec.setTo(_scaleX, _scaleX, _scaleZ);
			_scalevec.w = 1.0;
			return _scalevec;
		}
		
		/**
		 * 统一设置或获取缩放.
		 */
		public function set scaleXYZ(value:Number):void
		{
			_scaleX = value;
			_scaleY = value;
			_scaleZ = value;
			_transformNeedsUpdate = true;
		}
		public function get scaleXYZ():Number
		{
			if(_valuesNeedUpdate)
				updateValuesFromTransform();
			return _scaleX; //可能是错误的返回值
			_transformNeedsUpdate = true;
		}
		
		/**
		 * 设置或获取 x 轴缩放.
		 */
		public function set scaleX(value:Number):void
		{
			_scaleX = value;
			_transformNeedsUpdate = true;
		}
		public function get scaleX():Number
		{
			if(_valuesNeedUpdate)
				updateValuesFromTransform();
			return _scaleX;
		}
		
		/**
		 * 设置或获取 y 轴缩放.
		 */
		public function set scaleY(value:Number):void
		{
			_scaleY = value;
			_transformNeedsUpdate = true;
		}
		public function get scaleY():Number
		{
			if(_valuesNeedUpdate)
				updateValuesFromTransform();
			return _scaleY;
		}
		
		/**
		 * 设置或获取 z 轴缩放.
		 */
		public function set scaleZ(value:Number):void
		{
			_scaleZ = value;
			_transformNeedsUpdate = true;
		}
		public function get scaleZ():Number
		{
			if(_valuesNeedUpdate)
				updateValuesFromTransform();
			return _scaleZ;
		}
		
		/**
		 * 更新转换矩阵.
		 */
		public function updateTransformFromValues():void
		{
			_transform.identity();
			
			_transform.appendRotation(_rotationDegreesX, Vector3D.X_AXIS);
			_transform.appendRotation(_rotationDegreesY, Vector3D.Y_AXIS);
			_transform.appendRotation(_rotationDegreesZ, Vector3D.Z_AXIS);
			
			//避免缩放系数不能为 0 的报错
			if (_scaleX == 0) _scaleX = 0.0000001;
			if (_scaleY == 0) _scaleY = 0.0000001;
			if (_scaleZ == 0) _scaleZ = 0.0000001;
			_transform.appendScale(_scaleX, _scaleY, _scaleZ);
			
			_transform.appendTranslation(_x, _y, _z);
			
			_transformNeedsUpdate = false;
		}
		
		/**
		 * 从转换矩阵更新数据到各个变量.
		 */
		public function updateValuesFromTransform():void
		{
			var d:Vector.<Vector3D> = _transform.decompose();
			
			var position:Vector3D = d[0];
			_x = position.x;
			_y = position.y;
			_z = position.z;
			
			var rotation:Vector3D = d[1];
			_rotationDegreesX = rotation.x * RAD_TO_DEG;
			_rotationDegreesY = rotation.y * RAD_TO_DEG;
			_rotationDegreesZ = rotation.z * RAD_TO_DEG;
			
			var scale:Vector3D = d[2];
			_scaleX = scale.x;
			_scaleY = scale.y;
			_scaleZ = scale.z;
			
			_valuesNeedUpdate = false;
		}
		
		/**
		 * 向前移动.
		 * @param amt 移动量.
		 */
		public function moveForward(amt:Number):void
		{
			if (_transformNeedsUpdate) 
				updateTransformFromValues();
			var v:Vector3D = frontvector;
			v.scaleBy(-amt)
			transform.appendTranslation(v.x, v.y, v.z);
			_valuesNeedUpdate = true;
		}
		
		/**
		 * 向后移动.
		 * @param amt 移动量.
		 */
		public function moveBackward(amt:Number):void
		{
			if (_transformNeedsUpdate) 
				updateTransformFromValues();
			var v:Vector3D = backvector;
			v.scaleBy(-amt)
			transform.appendTranslation(v.x, v.y, v.z);
			_valuesNeedUpdate = true;
		}
		
		/**
		 * 向上移动.
		 * @param amt 移动量.
		 */
		public function moveUp(amt:Number):void
		{
			if (_transformNeedsUpdate) 
				updateTransformFromValues();
			var v:Vector3D = upvector;
			v.scaleBy(amt)
			transform.appendTranslation(v.x, v.y, v.z);
			_valuesNeedUpdate = true;
		}
		
		/**
		 * 向下移动.
		 * @param amt 移动量.
		 */
		public function moveDown(amt:Number):void
		{
			if (_transformNeedsUpdate) 
				updateTransformFromValues();
			var v:Vector3D = downvector;
			v.scaleBy(amt)
			transform.appendTranslation(v.x, v.y, v.z);
			_valuesNeedUpdate = true;
		}
		
		/**
		 * 向左移动.
		 * @param amt 移动量.
		 */
		public function moveLeft(amt:Number):void
		{
			if (_transformNeedsUpdate) 
				updateTransformFromValues();
			var v:Vector3D = leftvector;
			v.scaleBy(amt)
			transform.appendTranslation(v.x, v.y, v.z);
			_valuesNeedUpdate = true;
		}
		
		/**
		 * 向右移动.
		 * @param amt 移动量.
		 */
		public function moveRight(amt:Number):void
		{
			if (_transformNeedsUpdate) 
				updateTransformFromValues();
			var v:Vector3D = rightvector;
			v.scaleBy(amt)
			transform.appendTranslation(v.x, v.y, v.z);
			_valuesNeedUpdate = true;
		}
		
		/**
		 * 获取基于当前转换矩阵的对应的向前的单位向量.
		 * 例: 如果我们的飞船向正在向上飞行时, 就不能使用添加 (0, 0, 1) 向量来达到目的, 这个向量是基于没有进行过转换的坐标系的.
		 */
		public function get frontvector():Vector3D
		{
			if(_transformNeedsUpdate)
				updateTransformFromValues();
			return transform.deltaTransformVector(vecft);
		}
		
		/**
		 * 同 frontvector 方法.
		 */
		public function get backvector():Vector3D
		{
			if(_transformNeedsUpdate)
				updateTransformFromValues();
			return transform.deltaTransformVector(vecbk);
		}
		
		/**
		 * 同 frontvector 方法.
		 */
		public function get leftvector():Vector3D
		{
			if(_transformNeedsUpdate)
				updateTransformFromValues();
			return transform.deltaTransformVector(veclf);
		}
		
		/**
		 * 同 frontvector 方法.
		 */
		public function get rightvector():Vector3D
		{
			if(_transformNeedsUpdate)
				updateTransformFromValues();
			return transform.deltaTransformVector(vecrt);
		}
		
		/**
		 * 同 frontvector 方法.
		 */
		public function get upvector():Vector3D
		{
			if(_transformNeedsUpdate)
				updateTransformFromValues();
			return transform.deltaTransformVector(vecup);
		}
		
		/**
		 * 同 frontvector 方法.
		 */
		public function get downvector():Vector3D
		{
			if(_transformNeedsUpdate)
				updateTransformFromValues();
			return transform.deltaTransformVector(vecdn);
		}
		
		/**
		 * 获取旋转矩阵.
		 */
		public function get rotationTransform():Matrix3D
		{
			var d:Vector.<Vector3D> = transform.decompose();
			d[0] = new Vector3D();
			d[1] = new Vector3D(1, 1, 1);
			var t:Matrix3D = new Matrix3D();
			t.recompose(d);
			return t;
		}
		
		/**
		 * 获取去掉平移信息的矩阵.
		 */
		public function get reducedTransform():Matrix3D
		{
			var raw:Vector.<Number> = transform.rawData;
			raw[3] = 0; //去掉平移
			raw[7] = 0;
			raw[11] = 0;
			raw[15] = 1;
			raw[12] = 0;
			raw[13] = 0;
			raw[14] = 0;
			var reducedTransform:Matrix3D = new Matrix3D();
			reducedTransform.copyRawDataFrom(raw);
			return reducedTransform;
		}
		
		/**
		 * 获取反转后的旋转矩阵.
		 */
		public function get invRotationTransform():Matrix3D
		{
			var t:Matrix3D = rotationTransform;
			t.invert();
			return t;
		}
		
		/**
		 * 获取位置向量.
		 */
		public function get positionVector():Vector.<Number>
		{
			return Vector.<Number>([_x, _y, _z, 1.0]);
		}
		
		/**
		 * 获取反转矩阵.
		 */
		public function get inverseTransform():Matrix3D
		{
			_inverseTransform = transform.clone();
			_inverseTransform.invert();
			
			return _inverseTransform;
		}
		
		/**
		 * 获取当前的位置.
		 * @return 当前的位置.
		 */
		public function posString():String
		{
			if (_valuesNeedUpdate)
				updateValuesFromTransform();
			
			return _x.toFixed(2) + ',' + _y.toFixed(2) + ',' + _z.toFixed(2);
		}
		
		/**
		 * 获取当前的旋转信息.
		 * @return 当前的旋转信息.
		 */
		public function rotString():String
		{
			if (_valuesNeedUpdate)
				updateValuesFromTransform();
			
			return _rotationDegreesX.toFixed(2) + ',' + _rotationDegreesY.toFixed(2) + ',' + _rotationDegreesZ.toFixed(2);
		}
		
		/**
		 * 设置跟随实体对象.
		 * 例: 如果当前对象是一门炮弹发射器, 那么应该跟随一个装载该发射器的飞船对象. 本对象的矩阵会添加上其跟随的对象的矩阵实现跟随效果.
		 * @param thisentity 本实体对象会跟随的另一个实体对象.
		 */
		public function follow(thisentity:Entity):void
		{
			following = thisentity;
		}
		
		/**
		 * 渲染当前的实体对象.
		 * @param view 摄像机的视图矩阵.
		 * @param projection 透视矩阵.
		 * @param statechanged 状态是否改变, 如果状态没有改变则不需要重新上传数据到 GPU, 直接调用 drawTriangles 方法进行绘制, 提高渲染效率.
		 */
		public function render(view:Matrix3D, projection:Matrix3D, statechanged:Boolean = true):void
		{
			//用于调试
			if (!mesh) trace("Missing mesh!");
			if (!context) trace("Missing context!");
			if (!shader) trace("Missing shader!");
			
			//没有设置关键数据不进行渲染
			if (!mesh) return;
			if (!context) return;
			if (!shader) return;
			
			//重置我们最终使用的矩阵
			_rendermatrix.identity();
			_rendermatrix.append(transform);
			//是否跟随另一个实体对象
			if (following) _rendermatrix.append(following.transform);
			
			/*
			// for lighting, we may need to transform the vertex
			// normals based on the orientation of the mesh only = vc1
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, _rendermatrix, false);
			*/
			
			_rendermatrix.append(view);
			_rendermatrix.append(projection);
			
			//将我们的转换矩阵设置到顶点着色器的 vc0 寄存器中
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _rendermatrix, true);
			
			//批处理优化, 如果状态没有改变就不需要重新提交数据和设置着色器等操作, 提高渲染效率
			if(statechanged)
			{
				//设置着色器
				context.setProgram(shader);
				
				//设置贴图
				if (texture) context.setTextureAt(0,texture);
				
				//提交顶点位置
				context.setVertexBufferAt(0, mesh.positionsBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
				//提交 uv 坐标
				if (shaderUsesUV)
					context.setVertexBufferAt(1, mesh.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
				//提交顶点颜色信息
				if (shaderUsesRgba)
					context.setVertexBufferAt(2, mesh.colorsBuffer, 0, Context3DVertexBufferFormat.FLOAT_4);
				//提交法线信息
				if (shaderUsesNormals)
					context.setVertexBufferAt(3, mesh.normalsBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
				
				//设置渲染状态
				context.setBlendFactors(blendSrc, blendDst);
				context.setDepthTest(depthTest,depthTestMode);
				context.setCulling(cullingMode);
				context.setColorMask(true, true, true, depthDraw);
			}
			
			//渲染本对象
			context.drawTriangles(mesh.indexBuffer, 0, mesh.indexBufferCount);
		}
		
		/**
		 * 创建当前对象的一个副本, 同时重用同一个 ObjParser 对象, 避免多次解析和减小内存使用.
		 * @return 当前对象的副本.
		 */
		public function clone():Entity
		{
			if(_transformNeedsUpdate)
				updateTransformFromValues();
			
			var myclone:Entity = new Entity();
			myclone.transform = this.transform.clone();
			myclone.mesh = this.mesh;
			myclone.texture = this.texture;
			myclone.shader = this.shader;
			myclone.vertexBuffer = this.vertexBuffer;
			myclone.indexBuffer = this.indexBuffer;
			myclone.context = this.context;
			myclone.polycount = this.polycount;
			myclone.shaderUsesNormals = this.shaderUsesNormals;
			myclone.shaderUsesRgba = this.shaderUsesRgba;
			myclone.shaderUsesUV = this.shaderUsesUV;
			myclone.updateValuesFromTransform();
			return myclone;
		}
	}
}

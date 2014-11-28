// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio2D.display
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.utils.getQualifiedClassName;
	
	import scorpio2D.core.RenderSupport;
	import scorpio2D.core.Scorpio2D;
	import scorpio2D.core.scorpio2D_internal;
	import scorpio2D.events.Event2D;
	import scorpio2D.textures.Texture2D;
	import scorpio2D.textures.TextureSmoothing;
	import scorpio2D.utils.VertexData;
	
	use namespace scorpio2D_internal;
	
	/**
	 * 批处理优化类.
	 * 
	 * Starling大多数渲染的对象都是四边形。实际上，Starling的所有的默认叶子节点都是四边形（Image和Quad类）。 如果所有的具备相同状态的
	 * 四边形（比如相同的纹理，相同的平滑度和mipmapping设置）可以只用一次请求发送给GPU， 那么对于提升渲染这些四边形的执行效率将产生非常
	 * 大的作用。这就是QuadBatch类要完成的使命。
	 * 
	 * 这个类继承了DisplayObject，但是您可以使用它，即使它没有被添加到显示列表树。只需要从另一个Render方法呼叫'renderCustom'方法， 并
	 * 传递合适的值，包括变换矩阵，透明度和混合模式。
	 * @author wizardc
	 */
	public class QuadBatch extends DisplayObject2D
	{
		private static const QUAD_PROGRAM_NAME:String = "QB_q";
		
		private static var _helperMatrix3D:Matrix3D = new Matrix3D();
		private static var _renderAlpha:Vector.<Number> = new <Number>[1, 1, 1, 1];
		
		/**
		 * 注册着色器.
		 */
		private static function registerPrograms():void
		{
			var target:Scorpio2D = Scorpio2D.current;
			if(target.hasProgram(QUAD_PROGRAM_NAME))
			{
				return;
			}
			// create vertex and fragment programs from assembly
			var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			var vertexProgramCode:String;
			var fragmentProgramCode:String;
			// this is the input data we'll pass to the shaders:
			// 
			// va0 -> position
			// va1 -> color
			// va2 -> texCoords
			// vc0 -> alpha
			// vc1 -> mvpMatrix
			// fs0 -> texture
			
			// Quad2D:
			vertexProgramCode =
					"m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
					"mul v0, va1, vc0 \n";  // multiply alpha (vc0) with color (va1)
			fragmentProgramCode =
					"mov oc, v0       \n";  // output color
			vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode);
			fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentProgramCode);
			target.registerProgram(QUAD_PROGRAM_NAME, vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
			
			// Image2D:
			// Each combination of tinted/repeat/mipmap/smoothing has its own fragment shader.
			for each(var tinted:Boolean in [true, false])
			{
				vertexProgramCode = tinted ?
						"m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
						"mul v0, va1, vc0 \n" + // multiply alpha (vc0) with color (va1)
						"mov v1, va2      \n"   // pass texture coordinates to fragment program
						:
						"m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
						"mov v1, va2      \n";  // pass texture coordinates to fragment program
				vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode);
				fragmentProgramCode = tinted ?
						"tex ft1,  v1, fs0 <???> \n" + // sample texture 0
						"mul  oc, ft1,  v0       \n"   // multiply color with texel color
						:
						"tex  oc,  v1, fs0 <???> \n";  // sample texture 0
				var smoothingTypes:Array = [TextureSmoothing.NONE, TextureSmoothing.BILINEAR, TextureSmoothing.TRILINEAR];
				for each(var repeat:Boolean in [true, false])
				{
					for each(var mipmap:Boolean in [true, false])
					{
						for each(var smoothing:String in smoothingTypes)
						{
							var options:Array = ["2d", repeat ? "repeat" : "clamp"];
							if(smoothing == TextureSmoothing.NONE)
							{
								options.push("nearest", mipmap ? "mipnearest" : "mipnone");
							}
							else if(smoothing == TextureSmoothing.BILINEAR)
							{
								options.push("linear", mipmap ? "mipnearest" : "mipnone");
							}
							else
							{
								options.push("linear", mipmap ? "miplinear" : "mipnone");
							}
							fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentProgramCode.replace("???", options.join()));
							target.registerProgram(getImage2DProgramName(tinted, mipmap, repeat, smoothing), vertexProgramAssembler.agalcode, fragmentProgramAssembler.agalcode);
						}
					}
				}
			}
		}
		
		private static function getImage2DProgramName(tinted:Boolean, mipMap:Boolean = true, repeat:Boolean = false, smoothing:String = "bilinear"):String
		{
			// this method is designed to return most quickly when called with
			// the default parameters (no-repeat, mipmap, bilinear)
			var name:String = tinted ? "QB_i*" : "QB_i'";
			if(!mipMap)
			{
				name += "N";
			}
			if(repeat)
			{
				name += "R";
			}
			if(smoothing != TextureSmoothing.BILINEAR)
			{
				name += smoothing.charAt(0);
			}
			return name;
		}
		
		/**
		 * 分析一个容器对象, 判断它是一个特定的四边形 (还是其他容器), 并且创建一个矢量数组 (元素类型是 QuadBatch) 来代替容器.
		 * 这可以非常快的渲染容器. Sprite 类的 'flatten' 方法就是使用了这个方法.
		 * @param container 容器对象.
		 * @param quadBatches 矢量数组.
		 */
		public static function compile(container:DisplayObjectContainer2D, quadBatches:Vector.<QuadBatch>):void
		{
			compileObject(container, quadBatches, -1, new Matrix3D());
		}
		
		private static function compileObject(object:DisplayObject2D, quadBatches:Vector.<QuadBatch>, quadBatchID:int, transformationMatrix:Matrix3D, alpha:Number = 1, blendMode:String = null):int
		{
			var i:int;
			var quadBatch:QuadBatch;
			var isRootObject:Boolean = false;
			var objectAlpha:Number = object.alpha;
			if(quadBatchID == -1)
			{
				isRootObject = true;
				quadBatchID = 0;
				objectAlpha = 1;
				blendMode = object.blendMode;
				if(quadBatches.length == 0)
				{
					quadBatches.push(new QuadBatch());
				}
				else
				{
					quadBatches[0].reset();
				}
			}
			if(object is DisplayObjectContainer2D)
			{
				var container:DisplayObjectContainer2D = object as DisplayObjectContainer2D;
				var numChildren:int = container.numChildren;
				var childMatrix:Matrix3D = new Matrix3D();
				for(i = 0; i < numChildren; ++i)
				{
					var child:DisplayObject2D = container.getChildAt(i);
					var childVisible:Boolean = child.alpha != 0 && child.visible && child.scaleX != 0 && child.scaleY != 0;
					if(childVisible)
					{
						var childBlendMode:String = child.blendMode == BlendMode2D.AUTO ? blendMode : child.blendMode;
						childMatrix.copyFrom(transformationMatrix);
						RenderSupport.transformMatrixForObject(childMatrix, child);
						quadBatchID = compileObject(child, quadBatches, quadBatchID, childMatrix, alpha * objectAlpha, childBlendMode);
					}
				}
			}
			else if(object is Quad2D)
			{
				var quad:Quad2D = object as Quad2D;
				var image:Image2D = quad as Image2D;
				var texture:Texture2D = image ? image.texture : null;
				var smoothing:String = image ? image.smoothing : null;
				quadBatch = quadBatches[quadBatchID];
				if(quadBatch.isStateChange(quad, alpha*objectAlpha, texture, smoothing, blendMode))
				{
					quadBatchID++;
					if(quadBatches.length <= quadBatchID)
					{
						quadBatches.push(new QuadBatch());
					}
					quadBatch = quadBatches[quadBatchID];
					quadBatch.reset();
				}
				quadBatch.addQuad(quad, alpha, texture, smoothing, transformationMatrix, blendMode);
			}
			else if(object is QuadBatch)
			{
				if(quadBatches[quadBatchID]._numQuad2Ds > 0)
				{
					quadBatchID++;
				}
				quadBatch = (object as QuadBatch).clone();
				quadBatch.blendMode = blendMode;
				quadBatch._vertexData.transformVertex(0, transformationMatrix, -1);
				quadBatches.splice(quadBatchID, 0, quadBatch);
			}
			else
			{
				throw new Error("Unsupported display object: " + getQualifiedClassName(object));
			}
			if(isRootObject)
			{
				// remove unused batches
				for(i = quadBatches.length - 1; i > quadBatchID; --i)
				{
					quadBatches.pop().dispose();
				}
				// last quadbatch could be empty
				if(quadBatches[quadBatches.length - 1]._numQuad2Ds == 0)
				{
					quadBatches.pop().dispose();
				}
			}
			return quadBatchID;
		}
		
		private var _numQuad2Ds:int;
		private var _syncRequired:Boolean;
		
		private var _tinted:Boolean;
		private var _texture2D:Texture2D;
		private var _smoothing:String;
		
		private var _vertexData:VertexData;
		private var _vertexBuffer:VertexBuffer3D;
		private var _indexData:Vector.<uint>;
		private var _indexBuffer:IndexBuffer3D;
		
		/**
		 * 构造函数.
		 */
		public function QuadBatch()
		{
			_vertexData = new VertexData(0, true);
			_indexData = new <uint>[];
			_numQuad2Ds = 0;
			_tinted = false;
			_syncRequired = false;
			Scorpio2D.current.addEventListener(Event2D.CONTEXT3D_CREATE, onContextCreated);
		}
		
		private function onContextCreated(event:Event2D):void
		{
			createBuffers();
			registerPrograms();
		}
		
		/**
		 * 获取四边形的数量.
		 */
		public function get numQuad2Ds():int
		{
			return _numQuad2Ds;
		}
		
		private function expand():void
		{
			var oldCapacity:int = _vertexData.numVertices / 4;
			var newCapacity:int = oldCapacity == 0 ? 16 : oldCapacity * 2;
			_vertexData.numVertices = newCapacity * 4;
			for(var i:int = oldCapacity; i < newCapacity; ++i)
			{
				_indexData[int(i*6  )] = i*4;
				_indexData[int(i*6+1)] = i*4 + 1;
				_indexData[int(i*6+2)] = i*4 + 2;
				_indexData[int(i*6+3)] = i*4 + 1;
				_indexData[int(i*6+4)] = i*4 + 3;
				_indexData[int(i*6+5)] = i*4 + 2;
			}
			createBuffers();
			registerPrograms();
		}
		
		private function createBuffers():void
		{
			var numVertices:int = _vertexData.numVertices;
			var numIndices:int = _indexData.length;
			var context:Context3D = Scorpio2D.context;
			if(_vertexBuffer != null)
			{
				_vertexBuffer.dispose();
			}
			if(_indexBuffer != null)
			{
				_indexBuffer.dispose();
			}
			if(_numQuad2Ds == 0)
			{
				return;
			}
			if(context == null)
			{
				throw new Error("Context3D object is required but not available");
			}
			_vertexBuffer = context.createVertexBuffer(numVertices, VertexData.ELEMENTS_PER_VERTEX);
			_vertexBuffer.uploadFromVector(_vertexData.rawData, 0, numVertices);
			_indexBuffer = context.createIndexBuffer(numIndices);
			_indexBuffer.uploadFromVector(_indexData, 0, numIndices);
			_syncRequired = false;
		}
		
		private function syncBuffers():void
		{
			if(_vertexBuffer == null)
			{
				createBuffers();
			}
			else
			{
				// as 3rd parameter, we could also use '_numQuad2Ds * 4', but on some GPU hardware (iOS!),
				// this is slower than updating the complete buffer.
				_vertexBuffer.uploadFromVector(_vertexData.rawData, 0, _vertexData.numVertices);
				_syncRequired = false;
			}
		}
		
		/**
		 * 向当前批次增加一个图像.
		 * @param image 图像.
		 * @param parentAlpha 透明度.
		 * @param modelViewMatrix 模型视图矩阵.
		 * @param blendMode 混合模式.
		 */
		public function addImage(image:Image2D, parentAlpha:Number = 1, modelViewMatrix:Matrix3D = null, blendMode:String = null):void
		{
			this.addQuad(image, parentAlpha, image.texture, image.smoothing, modelViewMatrix, blendMode);
		}
		
		/**
		 * 增加一个四边形到当前批次.
		 * @param quad Quad2D.
		 * @param parentAlpha 透明度.
		 * @param texture 纹理.
		 * @param smoothing 平滑度.
		 * @param modelViewMatrix 模型视图矩阵.
		 * @param blendMode 混合模式.
		 */
		public function addQuad(quad:Quad2D, parentAlpha:Number = 1, texture:Texture2D = null, smoothing:String = null, modelViewMatrix:Matrix3D = null, blendMode:String = null):void
		{
			if(modelViewMatrix == null)
			{
				modelViewMatrix = _helperMatrix3D;
				modelViewMatrix.identity();
				RenderSupport.transformMatrixForObject(modelViewMatrix, quad);
			}
			var tinted:Boolean = texture ? (quad.tinted || parentAlpha != 1) : false;
			var alpha:Number = parentAlpha * quad.alpha;
			var vertexID:int = _numQuad2Ds * 4;
			if(_numQuad2Ds + 1 > _vertexData.numVertices / 4)
			{
				expand();
			}
			if(_numQuad2Ds == 0)
			{
				this.blendMode = blendMode ? blendMode : quad.blendMode;
				_texture2D = texture;
				_tinted = tinted;
				_smoothing = smoothing;
				_vertexData.setPremultipliedAlpha(texture ? texture.premultipliedAlpha : true, false);
			}
			quad.copyVertexDataTo(_vertexData, vertexID);
			if(alpha != 1)
			{
				_vertexData.scaleAlpha(vertexID, alpha, 4);
			}
			_vertexData.transformVertex(vertexID, modelViewMatrix, 4);
			_syncRequired = true;
			_numQuad2Ds++;
		}
		
		/**
		 * 判断如果一个四边形可以被添加到批次, 是否会引起状态值的变化.
		 * @param quad Quad2D.
		 * @param parentAlpha 透明度.
		 * @param texture 纹理.
		 * @param smoothing 平滑度.
		 * @param blendMode 混合模式.
		 * @return 是否会引起状态值的变化.
		 */
		public function isStateChange(quad:Quad2D, parentAlpha:Number, texture:Texture2D, smoothing:String, blendMode:String):Boolean
		{
			if(_numQuad2Ds == 0)
			{
				return false;
			}
			else if(_numQuad2Ds == 8192) // maximum buffer size
			{
				return true;
			}
			else if(_texture2D == null && texture == null)
			{
				return false;
			}
			else if(_texture2D != null && texture != null)
			{
				return  _texture2D.base != texture.base ||
						_texture2D.repeat != texture.repeat ||
						_smoothing != smoothing ||
						_tinted != (quad.tinted || parentAlpha != 1.0) ||
						this.blendMode != blendMode;
			}
			else
			{
				return true;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getBounds(targetSpace:DisplayObject2D):Rectangle
		{
			var transformationMatrix:Matrix = targetSpace == this ? null : this.getTransformationMatrix(targetSpace);
			return _vertexData.getBounds(transformationMatrix, 0, _numQuad2Ds * 4, null);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function render(support:RenderSupport, parentAlpha:Number):void
		{
			support.finishQuadBatch();
			this.renderCustom(support.mvpMatrix, alpha * parentAlpha, support.blendMode);
		}
		
		/**
		 * 结合对模型-视图-投影矩阵, 透明度和混合模式的自定义设置来呈现当前批次.
		 * 这样就使得渲染那些不在显示列表的批次成为可能.
		 * @param mvpMatrix 模型-视图-投影矩阵.
		 * @param parentAlpha 透明度.
		 * @param blendMode 混合模式.
		 */
		public function renderCustom(mvpMatrix:Matrix3D, parentAlpha:Number = 1, blendMode:String = null):void
		{
			if(_numQuad2Ds == 0)
			{
				return;
			}
			if(_syncRequired)
			{
				syncBuffers();
			}
			var pma:Boolean = _vertexData.premultipliedAlpha;
			var context:Context3D = Scorpio2D.context;
			var tinted:Boolean = _tinted || (parentAlpha != 1);
			var programName:String = _texture2D ? getImage2DProgramName(tinted, _texture2D.mipMapping, _texture2D.repeat, _smoothing) : QUAD_PROGRAM_NAME;
			_renderAlpha[0] = _renderAlpha[1] = _renderAlpha[2] = pma ? parentAlpha : 1.0;
			_renderAlpha[3] = parentAlpha;
			RenderSupport.setBlendFactors(pma, blendMode ? blendMode : this.blendMode);
			context.setProgram(Scorpio2D.current.getProgram(programName));
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _renderAlpha, 1);
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, mvpMatrix, true);
			context.setVertexBufferAt(0, _vertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_3);
			if(_texture2D == null || tinted)
			{
				context.setVertexBufferAt(1, _vertexBuffer, VertexData.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4);
			}
			if(_texture2D)
			{
				context.setTextureAt(0, _texture2D.base);
				context.setVertexBufferAt(2, _vertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
			}
			context.drawTriangles(_indexBuffer, 0, _numQuad2Ds * 2);
			if(_texture2D)
			{
				context.setTextureAt(0, null);
				context.setVertexBufferAt(2, null);
			}
			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(0, null);
		}
		
		/**
		 * 重置当前批次.
		 * 但顶点和索引缓冲区仍会保持它们的大小, 使它们能够很快被重用.
		 */
		public function reset():void
		{
			_numQuad2Ds = 0;
			_texture2D = null;
			_smoothing = null;
			_syncRequired = true;
		}
		
		/**
		 * 复制当前对象.
		 * @return 副本.
		 */
		public function clone():QuadBatch
		{
			var clone:QuadBatch = new QuadBatch();
			clone._vertexData = _vertexData.clone(0, _numQuad2Ds * 4);
			clone._indexData = _indexData.slice(0, _numQuad2Ds * 6);
			clone._numQuad2Ds = _numQuad2Ds;
			clone._tinted = _tinted;
			clone._texture2D = _texture2D;
			clone._smoothing = _smoothing;
			clone._syncRequired = true;
			clone.blendMode = this.blendMode;
			return clone;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			Scorpio2D.current.removeEventListener(Event2D.CONTEXT3D_CREATE, onContextCreated);
			if(_vertexBuffer != null)
			{
				_vertexBuffer.dispose();
			}
			if(_indexBuffer != null)
			{
				_indexBuffer.dispose();
			}
			super.dispose();
		}
	}
}

package tests
{
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProfile;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	public class PerspectiveTest extends Sprite
	{
		[Embed(source="../../assets/texture.jpg")]
		private const TEXTURE_DATA:Class;
		
		private var _stage3D:Stage3D;
		private var _context3D:Context3D;
		private var _vertexBuffer3D:VertexBuffer3D;
		private var _indexBuffer3D:IndexBuffer3D;
		private var _shaderProgram:Program3D;
		private var _texture:Texture;
		
		//透视矩阵
		private var _perspectiveMatrix3D:PerspectiveMatrix3D = new PerspectiveMatrix3D();
		//模型转换矩阵
		private var _modelMatrix:Matrix3D = new Matrix3D();
		//摄像机矩阵
		private var _cameraMatrix:Matrix3D = new Matrix3D();
		//model view projection, 模型最终使用的转换矩阵
		private var _mvpMatrix:Matrix3D = new Matrix3D();
		
		private var _t:Number = 0;
		
		public function PerspectiveTest()
		{
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		private function addedToStageHandler(event:Event):void
		{
			_stage3D = stage.stage3Ds[0];
			_stage3D.addEventListener(Event.CONTEXT3D_CREATE, context3DCreateHandler);
			_stage3D.requestContext3D(Context3DRenderMode.AUTO, Context3DProfile.BASELINE);
		}
		
		private function context3DCreateHandler(event:Event):void
		{
			initContext3D();
			initPerspectiveProjection();
			initBuffer();
			initTexture();
			initProgram();
			
			//为了看到网格将相机后移
			_cameraMatrix.appendTranslation(0, 0, -4);
			
			addEventListener(Event.ENTER_FRAME, render);
		}
		
		private function initContext3D():void
		{
			_context3D = _stage3D.context3D;
			//启用错误检查, 禁用可提高执行效率
			_context3D.enableErrorChecking = true;
			//设定 3D 后备缓冲区的尺寸
			_context3D.configureBackBuffer(stage.stageWidth, stage.stageHeight, 0, true, false);
		}
		
		private function initPerspectiveProjection():void
		{
			//45度视角, 长宽比, 0.1 近裁剪面, 100 远裁剪面
			_perspectiveMatrix3D.perspectiveFieldOfViewRH(45, stage.stageWidth / stage.stageHeight, .01, 100);
		}
		
		private function initBuffer():void
		{
			//顶点数据
			var meshVertexData:Vector.<Number> = Vector.<Number>(
			[
				// x,  y,  z,    u,  v,
				  -1, -1,  1,    0,  0,
				   1, -1,  1,    1,  0,
				   1,  1,  1,    1,  1,
				  -1,  1,  1,    0,  1
			]);
			_vertexBuffer3D = _context3D.createVertexBuffer(meshVertexData.length / 5, 5);
			_vertexBuffer3D.uploadFromVector(meshVertexData, 0, meshVertexData.length / 5);
			//索引数据
			var meshIndexData:Vector.<uint> = Vector.<uint>(
			[
				0, 1, 2,
				0, 2, 3
			]);
			_indexBuffer3D = _context3D.createIndexBuffer(meshIndexData.length);
			_indexBuffer3D.uploadFromVector(meshIndexData, 0, meshIndexData.length);
		}
		
		private function initTexture():void
		{
			var textureData:Bitmap = new TEXTURE_DATA() as Bitmap;
			var ws:int = textureData.bitmapData.width;
			var hs:int = textureData.bitmapData.height;
			_texture = _context3D.createTexture(ws, hs, Context3DTextureFormat.BGRA, false, 0);
			//生成 MIP 映射
			var level:int = 0;
			var temp:BitmapData;
			var transform:Matrix = new Matrix();
			temp = new BitmapData(ws, hs, true, 0x00000000);
			while (ws >= 1 && hs >= 1)
			{
				temp.draw(textureData.bitmapData, transform, null, null, null, true);
				_texture.uploadFromBitmapData(temp, level);
				transform.scale(.5, .5);
				level++;
				ws >>= 1;
				hs >>= 1;
				if (ws != 0 && hs != 0)
				{
					temp.dispose();
					temp = new BitmapData(ws, hs, true, 0x00000000);
				}
			}
			temp.dispose();
		}
		
		private function initProgram():void
		{
			//创建顶点着色器, 实现 3D 变换
			var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			vertexShaderAssembler.assemble
				(
					Context3DProgramType.VERTEX, 
					// 4 x 4 矩阵乘以相机角度
					"m44 op, va0, vc0\n" + 
					//告诉着色器 x, y, z 的值
					"mov v0, va0\n" + 
					//告诉着色器 u, v 的值
					"mov v1, va1\n"
				);
			//创建片段着色器, 使用顶点实现纹理
			var fragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler.assemble
				(
					Context3DProgramType.FRAGMENT, 
					//使用存于 v1 中的纹理坐标, 从纹理 fs0 中获取纹理颜色
					"tex ft0, v1, fs0 <2d,repeat,miplinear>\n" + 
					//将结果输出
					"mov oc, ft0\n"
				);
			//将两者混合成着色器, 上传到 GPU
			_shaderProgram = _context3D.createProgram();
			_shaderProgram.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);
		}
		
		private function render(event:Event):void
		{
			//模型矩阵改变
			_modelMatrix.identity();
			_modelMatrix.appendRotation(_t * .7, Vector3D.Y_AXIS);
			_modelMatrix.appendRotation(_t * .6, Vector3D.X_AXIS);
			_modelMatrix.appendRotation(_t * 1, Vector3D.Y_AXIS);
			_modelMatrix.appendTranslation(0, 0, 0);
			_modelMatrix.appendRotation(90, Vector3D.X_AXIS);
			//下一帧转移多一点
			_t += 2;
			
			//获取模型最终绘制时的转换矩阵
			_mvpMatrix.identity();
			_mvpMatrix.append(_modelMatrix);
			_mvpMatrix.append(_cameraMatrix);
			_mvpMatrix.append(_perspectiveMatrix3D);
			
			//渲染 3D 图像到屏幕
			_context3D.clear();
			_context3D.setProgram(_shaderProgram);
			_context3D.setVertexBufferAt(0, _vertexBuffer3D, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setVertexBufferAt(1, _vertexBuffer3D, 3, Context3DVertexBufferFormat.FLOAT_2);
			_context3D.setTextureAt(0, _texture);
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _mvpMatrix, true);
			_context3D.drawTriangles(_indexBuffer3D, 0, 2);
			_context3D.present();
		}
	}
}

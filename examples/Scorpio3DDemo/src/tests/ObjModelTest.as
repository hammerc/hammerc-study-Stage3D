package tests 
{
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProfile;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import scorpio3D.parsers.ObjParser;
	import scorpio3D.utils.Utils;
	
	public class ObjModelTest extends Sprite
	{
		[Embed(source="../../assets/spaceship.obj", mimeType="application/octet-stream")]
		private const MODEL_DATA:Class;
		
		[Embed(source="../../assets/spaceship_texture.jpg")]
		private const TEXTURE_DATA:Class;
		
		private var _stage3D:Stage3D;
		private var _context3D:Context3D;
		private var _shaderProgram:Program3D;
		private var _objParser:ObjParser;
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
		
		public function ObjModelTest() 
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
			initObjModelData();
			initTexture();
			initProgram();
			
			//为了看到网格将相机后移
			_cameraMatrix.appendTranslation(0, 0, -3);
			
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
		
		private function initObjModelData():void
		{
			_objParser = new ObjParser(MODEL_DATA, _context3D, 1, true, true);
		}
		
		private function initTexture():void
		{
			var textureData:Bitmap = new TEXTURE_DATA() as Bitmap;
			_texture = _context3D.createTexture(textureData.width, textureData.height, Context3DTextureFormat.BGRA, false);
			Utils.uploadTextureWithMipmaps(_texture, textureData.bitmapData);
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
					//告诉片段着色器 u, v 的值
					"mov v0, va1\n"
				);
			//创建片段着色器, 使用顶点实现纹理
			var fragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShaderAssembler.assemble
				(
					Context3DProgramType.FRAGMENT, 
					//使用存于 v0 中的纹理坐标, 从纹理 fs0 中获取纹理颜色
					"tex ft0, v0, fs0 <2d,repeat,miplinear>\n" + 
					//将结果输出
					"mov oc, ft0\n"
				);
			//将两者混合成着色器, 上传到 GPU
			_shaderProgram = _context3D.createProgram();
			_shaderProgram.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);
		}
		
		private function render(event:Event):void
		{
			//创建变换矩阵
			_modelMatrix.identity();
			_modelMatrix.appendRotation(-75, Vector3D.X_AXIS);
			_modelMatrix.appendRotation(_t, Vector3D.Y_AXIS);
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
			_context3D.setVertexBufferAt(0, _objParser.positionsBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setVertexBufferAt(1, _objParser.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			_context3D.setTextureAt(0, _texture);
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _mvpMatrix, true);
			_context3D.drawTriangles(_objParser.indexBuffer, 0, _objParser.indexBufferCount);
			_context3D.present();
		}
	}
}

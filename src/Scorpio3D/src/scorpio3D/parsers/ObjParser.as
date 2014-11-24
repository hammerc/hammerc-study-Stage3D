// =================================================================================================
//
//	Hammerc Framework
//	Copyright 2014 hammerc.org All Rights Reserved.
//
//	See LICENSE for full license information.
//
// =================================================================================================

package scorpio3D.parsers
{
	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	/**
	 * obj 文件解析类.
	 * @author wizardc
	 */
	public class ObjParser 
	{
		//是否为老版 3DS Max 使用的顶点顺序
		private var _vertexDataIsZxy:Boolean = false;
		//是否导出了映像 u, v 坐标
		private var _mirrorUv:Boolean = false;
		//obj 文件不包含顶点颜色, 需要我们自己生成, 是否随机生成顶点颜色, false 则都使用白色
		private var _randomVertexColors:Boolean = true;
		
		//解析文件时使用的常量
		private const LINE_FEED:String = String.fromCharCode(10);
		private const SPACE:String = String.fromCharCode(32);
		private const SLASH:String = "/";
		private const VERTEX:String = "v";
		private const NORMAL:String = "vn";
		private const UV:String = "vt";
		private const INDEX_DATA:String = "f";
		
		//临时变量
		private var _scale:Number;
		private var _faceIndex:uint;
		private var _vertices:Vector.<Number>;
		private var _normals:Vector.<Number>;
		private var _uvs:Vector.<Number>;
		private var _cachedRawNormalsBuffer:Vector.<Number>;
		
		//原始数据
		protected var _rawIndexBuffer:Vector.<uint>;
		protected var _rawPositionsBuffer:Vector.<Number>;
		protected var _rawUvBuffer:Vector.<Number>;
		protected var _rawNormalsBuffer:Vector.<Number>;
		protected var _rawColorsBuffer:Vector.<Number>;
		
		//最终数据
		protected var _indexBuffer:IndexBuffer3D;
		protected var _positionsBuffer:VertexBuffer3D;
		protected var _uvBuffer:VertexBuffer3D;
		protected var _normalsBuffer:VertexBuffer3D;
		protected var _colorsBuffer:VertexBuffer3D;
		
		//缓冲会上传到的 Context3D 对象
		private var _context3d:Context3D;
		
		/**
		 * 构造函数.
		 * @param objfile obj 文件内容.
		 * @param context 缓冲会上传到的 Context3D 对象.
		 * @param scale 整体缩放系数.
		 * @param dataIsZxy 是否使用老版 3DS Max 使用的顶点顺序.
		 * @param textureFlip 是否导出了映像 u, v 坐标.
		 * @param randomVertexColors obj 文件不包含顶点颜色, 需要我们自己生成, 是否随机生成顶点颜色, false 则都使用白色.
		 */
		public function ObjParser(objfile:*, context:Context3D, scale:Number = 1, dataIsZxy:Boolean = false, textureFlip:Boolean = false, randomVertexColors:Boolean = true) 
		{
			_vertexDataIsZxy = dataIsZxy;
			_mirrorUv = textureFlip;
			_randomVertexColors = randomVertexColors;
			
			_rawColorsBuffer = new Vector.<Number>();
			_rawIndexBuffer = new Vector.<uint>();
			_rawPositionsBuffer = new Vector.<Number>();
			_rawUvBuffer = new Vector.<Number>();
			_rawNormalsBuffer = new Vector.<Number>();
			_scale = scale;
			_context3d = context;
			
			//初始化临时容器
			_vertices = new Vector.<Number>();
			_normals = new Vector.<Number>();
			_uvs = new Vector.<Number>();
			
			if (objfile is Class)
			{
				objfile = readClass(objfile);
			}
			
			//逐行解析
			var lines:Array = objfile.split(LINE_FEED);
			var loop:uint = lines.length;
			for(var i:uint = 0; i < loop; ++i)
				parseLine(lines[i]);
		}
		
		private function readClass(f:Class):String
		{
			var bytes:ByteArray = new f();
			return bytes.readUTFBytes(bytes.bytesAvailable);
		}
		
		private function parseLine(line:String):void
		{
			//按空格分隔
			var words:Array = line.split(SPACE);
			
			//准备行数据
			if (words.length > 0)
				var data:Array = words.slice(1);
			else
				return;
			
			//检查第一个单词
			var firstWord:String = words[0];
			switch (firstWord)
			{
				case VERTEX:
					parseVertex(data);
					break;
				case NORMAL:
					parseNormal(data);
					break;
				case UV:
					parseUV(data);
					break;
				case INDEX_DATA:
					parseIndex(data);
					break;
			}
		}
		
		private function parseVertex(data:Array):void
		{
			if ((data[0] == '') || (data[0] == ' ')) 
				data = data.slice(1);
			if (_vertexDataIsZxy) //老版: z,x,y
			{
				_vertices.push(Number(data[1]) * _scale);
				_vertices.push(Number(data[2]) * _scale);
				_vertices.push(Number(data[0]) * _scale);
			}
			else //标准: x,y,z
			{
				//if (!_vertices.length) trace('parseVertex: ' + data);
				var loop:uint = data.length;
				if (loop > 3) loop = 3;
				for (var i:uint = 0; i < loop; ++i)
				{
					var element:String = data[i];
					_vertices.push(Number(element) * _scale);
				}
			}
		}
		
		private function parseNormal(data:Array):void
		{
			if ((data[0] == '') || (data[0] == ' ')) 
				data = data.slice(1);
			var loop:uint = data.length;
			if (loop > 3) loop = 3;
			for (var i:uint = 0; i < loop; ++i)
			{
				var element:String = data[i];
				if (element != null) //处理 3DS Max 的额外空白
					_normals.push(Number(element));
			}
		}
		
		private function parseUV(data:Array):void
		{
			if ((data[0] == '') || (data[0] == ' ')) 
				data = data.slice(1);
			var loop:uint = data.length;
			if (loop > 2) loop = 2;
			for (var i:uint = 0; i < loop; ++i)
			{
				var element:String = data[i];
				_uvs.push(Number(element));
			}
		}
		
		private function parseIndex(data:Array):void
		{
			var triplet:String;
			var subdata:Array;
			var vertexIndex:int;
			var uvIndex:int;
			var normalIndex:int;
			var index:uint;
			
			//处理元素
			var i:uint;
			var loop:uint = data.length;
			var starthere:uint = 0;
			while ((data[starthere] == '') || (data[starthere] == ' ')) 
				starthere++;
			
			loop = starthere + 3;
			
			//顶点索引, uv 索引, 法线索引
			for(i = starthere; i < loop; ++i)
			{
				triplet = data[i]; 
				subdata = triplet.split(SLASH);
				vertexIndex = int(subdata[0]) - 1;
				uvIndex     = int(subdata[1]) - 1;
				normalIndex = int(subdata[2]) - 1;
				
				//安全检测
				if(vertexIndex < 0) vertexIndex = 0;
				if(uvIndex < 0) uvIndex = 0;
				if (normalIndex < 0) normalIndex = 0;
				
				//将解析的数据提取到网格原始数据中
				
				//顶点 x, y, z
				index = 3*vertexIndex;
				_rawPositionsBuffer.push(_vertices[index + 0], _vertices[index + 1], _vertices[index + 2]);
				
				//颜色 r, g, b, a
				if (_randomVertexColors)
					_rawColorsBuffer.push(Math.random(), Math.random(), Math.random(), 1);
				else
					_rawColorsBuffer.push(1, 1, 1, 1);
				
				//法线 nx, ny, nz
				if (_normals.length)
				{
					index = 3 * normalIndex;
					_rawNormalsBuffer.push(_normals[index + 0], _normals[index + 1], _normals[index + 2]);
				}
				
				//纹理 u, v
				index = 2 * uvIndex;
				if (_mirrorUv)
					_rawUvBuffer.push(_uvs[index + 0], 1 - _uvs[index + 1]);
				else
					_rawUvBuffer.push(1 - _uvs[index + 0], 1 - _uvs[index + 1]);
			}
			
			//创建顶点缓冲
			_rawIndexBuffer.push(_faceIndex + 0, _faceIndex + 1, _faceIndex + 2);
			_faceIndex += 3;
		}
		
		public function get colorsBuffer():VertexBuffer3D
		{
			if(!_colorsBuffer)
				updateColorsBuffer();
			return _colorsBuffer;
		}
		
		public function get positionsBuffer():VertexBuffer3D
		{
			if(!_positionsBuffer)
				updateVertexBuffer();
			return _positionsBuffer;
		}
		
		public function get indexBuffer():IndexBuffer3D
		{
			if(!_indexBuffer)
				updateIndexBuffer();
			return _indexBuffer;
		}
		
		public function get indexBufferCount():int
		{
			return _rawIndexBuffer.length / 3;
		}
		
		public function get uvBuffer():VertexBuffer3D
		{
			if(!_uvBuffer)
				updateUvBuffer();
			return _uvBuffer;
		}
		
		public function get normalsBuffer():VertexBuffer3D
		{
			if(!_normalsBuffer)
				updateNormalsBuffer();
			return _normalsBuffer;
		}
		
		public function updateColorsBuffer():void
		{
			if(_rawColorsBuffer.length == 0) 
				throw new Error("Raw Color buffer is empty");
			var colorsCount:uint = _rawColorsBuffer.length/4; // 4=rgba
			_colorsBuffer = _context3d.createVertexBuffer(colorsCount, 4);
			_colorsBuffer.uploadFromVector(_rawColorsBuffer, 0, colorsCount);
		}
		
		public function updateNormalsBuffer():void
		{
			//如果没有法线信息则自动生成法线
			if (_rawNormalsBuffer.length == 0)
				forceNormals();
			if(_rawNormalsBuffer.length == 0)
				throw new Error("Raw Normal buffer is empty");
			var normalsCount:uint = _rawNormalsBuffer.length/3;
			_normalsBuffer = _context3d.createVertexBuffer(normalsCount, 3);
			_normalsBuffer.uploadFromVector(_rawNormalsBuffer, 0, normalsCount);
		}
		
		public function updateVertexBuffer():void
		{
			if(_rawPositionsBuffer.length == 0)
				throw new Error("Raw Vertex buffer is empty");
			var vertexCount:uint = _rawPositionsBuffer.length/3;
			_positionsBuffer = _context3d.createVertexBuffer(vertexCount, 3);
			_positionsBuffer.uploadFromVector(_rawPositionsBuffer, 0, vertexCount);
		}
		
		public function updateUvBuffer():void
		{
			if(_rawUvBuffer.length == 0)
				throw new Error("Raw UV buffer is empty");
			var uvsCount:uint = _rawUvBuffer.length/2;
			_uvBuffer = _context3d.createVertexBuffer(uvsCount, 2);
			_uvBuffer.uploadFromVector(_rawUvBuffer, 0, uvsCount);
		}
		
		public function updateIndexBuffer():void
		{
			if(_rawIndexBuffer.length == 0)
				throw new Error("Raw Index buffer is empty");
			_indexBuffer = _context3d.createIndexBuffer(_rawIndexBuffer.length);
			_indexBuffer.uploadFromVector(_rawIndexBuffer, 0, _rawIndexBuffer.length);
		}
		
		public function restoreNormals():void
		{
			_rawNormalsBuffer = _cachedRawNormalsBuffer.concat();
		}
		
		/**
		 * 根据 3 个点计算法线
		 */
		public function get3PointNormal(p0:Vector3D, p1:Vector3D, p2:Vector3D):Vector3D
		{
			var p0p1:Vector3D = p1.subtract(p0);
			var p0p2:Vector3D = p2.subtract(p0);
			var normal:Vector3D = p0p1.crossProduct(p0p2);
			normal.normalize();
			return normal;
		}
		
		public function forceNormals():void
		{
			_cachedRawNormalsBuffer = _rawNormalsBuffer.concat();
			var i:uint, index:uint;
			//将顶点转为向量
			var loop:uint = _rawPositionsBuffer.length/3;
			var vertices:Vector.<Vector3D> = new Vector.<Vector3D>();
			var vertex:Vector3D;
			for(i = 0; i < loop; ++i)
			{
				index = 3*i;
				vertex = new Vector3D(_rawPositionsBuffer[index],
					_rawPositionsBuffer[index + 1], 
					_rawPositionsBuffer[index + 2]);
				vertices.push(vertex);
			}
			//计算法线
			loop = vertices.length;
			var p0:Vector3D, p1:Vector3D, p2:Vector3D, normal:Vector3D;
			_rawNormalsBuffer = new Vector.<Number>();
			for(i = 0; i < loop; i += 3)
			{
				p0 = vertices[i];
				p1 = vertices[i + 1];
				p2 = vertices[i + 2];
				normal = get3PointNormal(p0, p1, p2);
				_rawNormalsBuffer.push(normal.x, normal.y, normal.z);
				_rawNormalsBuffer.push(normal.x, normal.y, normal.z);
				_rawNormalsBuffer.push(normal.x, normal.y, normal.z);
			}
		}
		
		public function dataDumpTrace():void
		{
			trace(dataDumpString());
		}
		
		public function dataDumpString():String
		{
			var str:String;
			str = "// Stage3d Model Data begins\n\n";
			
			str += "private var _Index:Vector.<uint> ";
			str += "= new Vector.<uint>([";
			str += _rawIndexBuffer.toString();
			str += "]);\n\n";
			
			str += "private var _Positions:Vector.<Number> ";
			str += "= new Vector.<Number>([";
			str += _rawPositionsBuffer.toString();
			str += "]);\n\n";
			
			str += "private var _UVs:Vector.<Number> = ";
			str += "new Vector.<Number>([";
			str += _rawUvBuffer.toString();
			str += "]);\n\n";
			
			str += "private var _Normals:Vector.<Number> = ";
			str += "new Vector.<Number>([";
			str += _rawNormalsBuffer.toString();
			str += "]);\n\n";
			
			str += "private var _Colors:Vector.<Number> = ";
			str += "new Vector.<Number>([";
			str += _rawColorsBuffer.toString();
			str += "]);\n\n";
			
			str += "// Stage3d Model Data ends\n";
			return str;
		}
	}
}

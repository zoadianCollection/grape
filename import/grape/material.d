module grape.material;

import derelict.opengl3.gl3;
import std.variant;
import std.stdio;
import grape.shader;

class Material {
  alias ParamType = Algebraic!(int[], bool, string, int);

  public:
    this(T...)(T params) {
      init();
      set_param(params);
    }

    @property {
      ShaderProgram program() {
        return _program;
      }

      ParamType[string] params() {
        return _params;
      }
    }

  protected:
    void init() {
      // TODO
      _params["vertexShader"] = "Set user's vertexShaderSource here";
      _params["fragmentShader"] = "Set user's fragmentShaderSource here";
    }

    void set_param(T...)(T params) {
      static if (params.length) {
        static assert(params.length % 2 == 0, "The number of material's parameter must be an even number.");
        auto key = params[0];
        static assert(is(typeof(key) : string), "The material parameter's key must be string.");
        assert(key in _params, "Wrong material parameter's key named \"" ~ key ~ "\"");
        auto value = params[1];

        _params[key] = value;
        set_param(params[2..$]);
      }
    }

    void create_program(in string vertexShaderSource, in string fragmentShaderSource) {
      Shader vs = new Shader(ShaderType.Vertex, vertexShaderSource);
      Shader fs = new Shader(ShaderType.Fragment, fragmentShaderSource);
      _program = new ShaderProgram(vs, fs);
    }

    ParamType[string] _params;
    ShaderProgram _program;
}

class ColorMaterial : Material {
  public:
    this(T...)(T params) {
      super(params);
      create_program(vertexShaderSource, fragmentShaderSource);
    }

  protected:
    override void init() {
      _params["color"] = [ 255, 255, 255 ];
      _params["wireframe"] = false;
    }

  private:
    static immutable vertexShaderSource = q{
      attribute vec3 position;
      attribute vec4 color;
      uniform mat4 pvmMatrix;
      varying vec4 vColor;

      void main() {
        vColor = color;
        gl_Position = pvmMatrix * vec4(position, 1.0);
      }
    };

    static immutable fragmentShaderSource = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
}

class DiffuseMaterial : Material {
  public:
    this(T...)(T params) {
      super(params);
      create_program(vertexShaderSource, fragmentShaderSource);
    }

  protected:
    override void init() {
      _params["color"] = [ 255, 255, 255 ];
      _params["wireframe"] = false;
    }

  private:
    static immutable vertexShaderSource = q{
      attribute vec3 position;
      attribute vec3 normal;
      attribute vec4 color;

      uniform vec3 lightPosition;

      uniform mat4 pvmMatrix;
      uniform mat4 invMatrix;

      varying vec4 vColor;
      
      void main() {
        vec3 invLight = normalize(invMatrix * vec4(lightPosition, 0.0));
        float diffuse = clamp(dot(normal, invLight), 0.1, 1.0);
        vColor = color * vec4(vec3(diffuse), 1.0);
        gl_Position = pvmMatrix * vec4(position, 1.0); 
      }
    };

    static immutable fragmentShaderSource = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
}

class EmissiveMaterial : Material {
  public:
    this(T...)(T params) {
      super(params);
      create_program(vertexShaderSource, fragmentShaderSource);
    }

  protected:
    override void init() {
      //_params["color"] = [ 255, 255, 255 ];
      //_params["wireframe"] = false;
      _params["intensity"] = 50;
    }

  private:
    static immutable vertexShaderSource = q{
      attribute vec3 position;
      attribute vec4 color;
      uniform mat4 pvmMatrix;
      varying vec4 vColor;

      void main() {
        vColor = color;
        gl_Position = pvmMatrix * vec4(position, 1.0);
      }
    };

    static immutable fragmentShaderSource = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
}


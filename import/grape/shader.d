/**
 * このモジュールをユーザーが直接使用することはありません。
 */

module grape.shader;

import derelict.opengl3.gl3;

import std.exception : enforce;
import std.stdio;
import std.traits : EnumMembers;

enum ShaderType {
  Vertex = GL_VERTEX_SHADER,
  Fragment = GL_FRAGMENT_SHADER 
}

enum ShaderProgramType {
  ClassicNormal = 0,
  ClassicTexture = 1,
  Font = 2,
  Normal = 3,
  Texture = 4,
  Diffuse = 5,
  ADS = 6,
  GaussianX = 7,
  GaussianY = 8,
}

mixin template ClassicNormalShaderSource() {
  void delegate(out string, out string) ClassicNormalShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec3 pos;
      attribute vec4 color;
      varying vec4 vColor;

      void main() {
        vColor = color;
        gl_Position = vec4(pos, 1.0);
      }
    };

    fShader = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
  };
}

mixin template ClassicTextureShaderSource() {
  void delegate(out string, out string) ClassicTextureShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec3 pos;
      attribute vec4 color;
      attribute vec2 texCoord;
      varying vec4 vColor;
      varying vec2 vTexCoord;

      void main() {
        vColor = color;
        vTexCoord = texCoord;
        gl_Position = vec4(pos, 1.0);
      }
    };

    fShader = q{
      uniform sampler2D tex;
      varying vec4 vColor;
      varying vec2 vTexCoord;

      void main() {
        vec4 smpColor = texture(tex, vTexCoord);
        // vec4 smpColor = texture(tex, vTexCoord);
        gl_FragColor = smpColor;
        //gl_FragColor = vColor * smpColor;
      }
    };
  };
}

// pvmMatrixの設定をしていないのでデフォルト座標から見ている...はず
// eye: (0, 0, 0);
// center: (0, 0, -1);
// up: (0, 1, 0);
mixin template FontShaderSource() {
  void delegate(out string, out string) FontShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec3 pos;
      attribute vec2 texCoord;
      varying vec2 vTexCoord;

      void main() {
        vTexCoord = texCoord;
        gl_Position = vec4(pos, 1.0);
      }
    };

    fShader = q{
      uniform sampler2D tex;
      varying vec2 vTexCoord;

      void main() {
        vec4 smpColor = texture(tex, vTexCoord);
        gl_FragColor = smpColor;
      }
    };
  };
}

mixin template NormalShaderSource() {
  void delegate(out string, out string) NormalShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec3 pos;
      attribute vec4 color;
      uniform mat4 pvmMatrix;
      varying vec4 vColor;

      void main() {
        vColor = color;
        gl_Position = pvmMatrix * vec4(pos, 1.0);
      }
    };

    fShader = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
  };
}

mixin template TextureShaderSource() {
  void delegate(out string, out string) TextureShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec3 pos;
      attribute vec2 texCoord;
      varying vec2 vTexCoord;
      uniform mat4 pvmMatrix;
      //attribute vec4 color;
      //varying vec4 vColor;

      void main() {
        //vColor = color;
        vTexCoord = texCoord;
        gl_Position = pvmMatrix * vec4(pos, 1.0); 
      }
    };

    fShader = q{
      uniform sampler2D tex;
      varying vec2 vTexCoord;
      //varying vec4 vColor;

      void main() {
        vec4 smpColor = texture(tex, vTexCoord);
        //gl_FragColor = smpColor + vec4(1.0, 1.0, 1.0, 0.0);;
        gl_FragColor = smpColor;
        //gl_FragColor = smpColor + vec4(0.2, 0.2, 0.2, 0.0);
        //gl_FragColor = vec4(0.2, 0.2, 0.2, 0.3);
        /*
        if (smpColor.a < 0.5) {
          discard;
        } else {
          gl_FragColor = smpColor;
        }
        */
        //gl_FragColor = vColor;
        //gl_FragColor = smpColor + vColor;
        //gl_FragColor = vec4(smpColor.rgb, vColor.a * smpColor.a);
      }
    };
  };
}

mixin template DiffuseShaderSource() {
  void delegate(out string, out string) DiffuseShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec3 pos;
      attribute vec3 normal;
      attribute vec4 color;

      uniform vec3 lightPos;

      uniform mat4 pvmMatrix;
      uniform mat4 invMatrix;

      varying vec4 vColor;
      
      void main() {
        vec3 invLight = normalize(invMatrix * vec4(lightPos, 0.0));
        float diffuse = clamp(dot(normal, invLight), 0.1, 1.0);
        vColor = color * vec4(vec3(diffuse), 1.0);
        gl_Position = pvmMatrix * vec4(pos, 1.0); 
      }
    };

    fShader = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
  };
}

mixin template ADSShaderSource() {
  void delegate(out string, out string) ADSShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec3 pos;
      attribute vec3 normal;
      attribute vec4 color;

      uniform vec3 lightPos;
      uniform vec3 eyePos;
      uniform vec4 ambientColor;

      uniform mat4 pvmMatrix;
      uniform mat4 invMatrix;

      varying vec4 vColor;
      
      void main() {
        vec3 invLight = normalize(invMatrix * vec4(lightPos, 0.0));
        vec3 invEye = normalize(invMatrix * vec4(eyePos, 0.0));
        vec3 halfLE = normalize(invLight + invEye);
        float diffuse = clamp(dot(normal, invLight), 0.0, 1.0);
        float specular = pow(clamp(dot(normal, halfLE), 0.0, 1.0), 50.0);
        vec4 light = color * vec4(vec3(diffuse), 1.0) + vec4(vec3(specular), 1.0);
        vColor = light + ambientColor;
        gl_Position = pvmMatrix * vec4(pos, 1.0); 
      }
    };

    fShader = q{
      varying vec4 vColor;

      void main() {
        gl_FragColor = vColor;
      }
    };
  };
}

mixin template GaussianShaderSource() {
  void delegate(out string, out string) GaussianShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec2 pos;
      attribute vec2 texCoord;
      varying vec2 vTexCoord;

      void main() {
        gl_Position = vec4(pos, 0.0, 1.0); 
        vTexCoord = texCoord;
      }
    };

    fShader = q{
      uniform sampler2D tex;
      uniform float weight[8];
      uniform int type;
      uniform vec2 resolution;
      varying vec2 vTexCoord;

      void main() {
        vec2 t = vec2(1.0) / resolution;
        vec4 color = texture(tex, vTexCoord) * weight[0];

        if (type == 0) {
          for (int i=1; i<weight.length(); ++i) {
            color += texture(tex, (gl_FragCoord.xy + vec2(-1.0*i, 0.0)) * t) * weight[i];
            color += texture(tex, (gl_FragCoord.xy + vec2(1.0*i, 0.0)) * t) * weight[i];
          }
        } else if (type == 1) {
          for (int i=1; i<weight.length(); ++i) {
            color += texture(tex, (gl_FragCoord.xy + vec2(0.0, -1.0*i)) * t) * weight[i];
            color += texture(tex, (gl_FragCoord.xy + vec2(0.0, 1.0*i)) * t) * weight[i];
          }
        }

        gl_FragColor = color;
      }
    };
  };
}

mixin template FilterShaderSource() {
  void delegate(out string, out string) FilterShader = (out string vShader, out string fShader) {
    vShader = q{
      attribute vec3 pos;
      attribute vec2 texCoord;
      varying vec2 vTexCoord;
      //uniform mat4 pvmMatrix;

      void main() {
        //gl_Position = pvmMatrix * vec4(pos, 0.0, 1.0); 
        gl_Position = vec4(pos, 1.0); 
        vTexCoord = texCoord;
      }
    };

    fShader = q{
      uniform sampler2D tex;
      varying vec2 vTexCoord;

      void main() {
        vec4 smpColor = texture(tex, vTexCoord);
        gl_FragColor = smpColor;
        //gl_FragColor = (smpColor.rgb, 0.2);
        //gl_FragColor = smpColor + vec4(0.2, 0.0, 0.0, 1.0);
      }
    };
  };
}

class Shader {
  public:
    this(in ShaderType type) {
      generate(type);
    };

    this(in ShaderType type, in string shaderCode) {
      this(type);
      compile(shaderCode);
    }

    ~this() {
      eliminate();
    }

    void compile(in string shaderCode) {
      auto fst = &shaderCode[0];
      int len = cast(int)shaderCode.length; // TODO
      glShaderSource(_shader, 1, &fst, &len);
      glCompileShader(_shader);

      GLint result;
      glGetShaderiv(_shader, GL_COMPILE_STATUS, &result);
      enforce(result != GL_FALSE, "glCompileShader() faild");
    }

    alias _shader this; // TODO

  private:
    void generate(in ShaderType type) {
      _shader = glCreateShader(type);
      enforce(_shader, "glCreateShader() faild");
    }

    void eliminate() {
      glDeleteShader(_shader); 
    }

    GLuint _shader;
}

class ShaderProgram {
  public:
    this() {
      generate();
    }

    this(Shader vs, Shader fs) {
      this();
      attach(vs, fs);
    }

    ~this() {
      eliminate();
    }

    void attach(T)(in T vs, in T fs) {
      glAttachShader(_program, vs);
      glAttachShader(_program, fs);
      glLinkProgram(_program);

      int linked;
      glGetProgramiv(_program, GL_LINK_STATUS, &linked);
      enforce(linked != GL_FALSE, "glLinkProgram() faild");
    }

    void use() {
      glUseProgram(_program);
    }

    alias _program this;
    GLuint _program;

  private:
    void generate() {
      _program = glCreateProgram();
      enforce(_program, "glCreateProgram() faild");
    }

    void eliminate() {
      glDeleteProgram(_program);
    }
}


module orange.font;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import std.exception : enforce;
import orange.buffer;
import orange.shader;
import orange.window;
import orange.surface;
import orange.renderer;
import opengl.glew;

import std.stdio;

// TODO 複数扱う
// FIXME 短時間にscene切り替えしすぎるTTF_OpenFont() failedになる
class Font {
  public:
    this(string file) {
      foreach (size; sizeList) {
        _list[size] = TTF_OpenFont(cast(char*)file, size);
        enforce(_list[size] != null, "TTF_OpenFont() failed");
      }
    }

    static ~this() {
      debug(tor) writeln("Font dtor");
      foreach (font; _list)
        TTF_CloseFont(font);
    }

    static immutable auto sizeList = [ 6, 7, 8, 9, 10, 11, 12, 13, 14, // TODO immutableにする
                                       15, 16, 17, 18, 20, 22, 24, 26,
                                       28, 32, 36, 40, 48, 56, 64, 72 ];
    alias _list this;
    static TTF_Font*[int] _list;
}

class FontHdr {
  public:
    this(GLuint program) { //TODO program受け取らない
      _vboHdr = new VBOHdr(2, program);
      _texHdr = new TexHdr(program);
      _ibo = new IBO;
      _ibo.create([0, 1, 2, 2, 3, 0]);
      _surf = new Surface;

      _drawMode = DrawMode.Triangles;

      _tex = [ 0.0, 0.0,
               1.0, 0.0,
               1.0, 1.0,
               0.0, 1.0 ];        
      _locNames = ["pos", "texCoord"];
      _strides = [ 3, 2 ]; 

      //debug(tor) writeln("FontHdr ctor");
    }

    ~this() {
      debug(tor) writeln("FontHdr dtor");
    }

    void load(string file) { //TODO コンストラクタでも受け取るようにするか？
      _font = new Font(file);
    }

    void set_color(ubyte r, ubyte g, ubyte b) {
      _color = SDL_Color(r, g, b);
    }

    //void draw(float x, float y, string text, int size = _font.keys[0]) { // TODO
    void draw(float x, float y, string text, int size) {
      enforce(size in _font, "font size error. you call wrong size of the font which is not loaded");

      _surf.create_ttf(_font, size, text, _color);
      _surf.convert();

      float[12] pos = set_pos(x, y, _surf);
      _vboHdr.create_vbo(pos, _tex);
      _vboHdr.enable_vbo(_locNames, _strides);

      _texHdr.create(_surf, "tex");
      _texHdr.enable();
      _ibo.draw(_drawMode);
      _texHdr.disable();
    }

  private:
    float[12] set_pos(float x, float y, Surface surf) {
      auto startX = x / (WINDOW_X/2.0);
      auto startY = y / (WINDOW_Y/2.0);
      auto w = surf.w / (WINDOW_X/2.0);
      auto h = surf.h / (WINDOW_Y/2.0);

      return [ startX, startY, 0.0,
               startX+w, startY, 0.0,
               startX+w, startY-h, 0.0,
               startX, startY-h, 0.0 ];
    }

    Surface _surf;
    //Font[int] _font;
    Font _font;
    SDL_Color _color;

    float[8] _tex;
    string[2] _locNames;
    int[2] _strides;

    VBOHdr _vboHdr;
    IBO _ibo;
    TexHdr _texHdr;
    DrawMode _drawMode;
}

/*
class FontRenderer : Renderer {
  public:
    this() {
      string[] locNames = [ "pos", "texCoord" ];
      int[] strides = [ 3, 2 ];
      mixin FontShaderSource;
      init(FontShader, 2, locNames, strides, DrawMode.Triangles);

      _program.use();
      init_vbo();
      init_ibo();
    }

    void load(string file, int[] sizeList...) {
      if (sizeList.length == 0) {
        sizeList = [ 6, 7, 8, 9, 10, 11, 12, 13, 14, // TODO immutableにする
                     15, 16, 17, 18, 20, 22, 24, 26,
                     28, 32, 36, 40, 48, 56, 64, 72 ];
      }

      foreach (size; sizeList)
        _font[size] = new Font(file, size);
    }

    override void render() {
      _program.use();
      _ibo.draw(_drawMode);
    }

  private:
    void init_vbo() {
      _mesh = [ -1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, -1.0, 0.0, -1.0, -1.0, 0.0 ];
      _texCoord = [ 0.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0 ];
    }

    void init_ibo() {
      int[] index = [ 0, 1, 2, 0, 2, 3 ];
      _ibo = new IBO;
      _ibo.create(index);
    }

    float[12] set_pos(float x, float y, Surface surf) {
      auto startX = x / (WINDOW_X/2.0);
      auto startY = y / (WINDOW_Y/2.0);
      auto w = surf.w / (WINDOW_X/2.0);
      auto h = surf.h / (WINDOW_Y/2.0);

      return [ startX, startY, 0.0,
               startX+w, startY, 0.0,
               startX+w, startY-h, 0.0,
               startX, startY-h, 0.0 ];
    }

    IBO _ibo;
    float[] _mesh;
    float[] _texCoord;

    Surface _surf;
    Font[int] _font;
    SDL_Color _color;
}
*/

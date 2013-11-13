module grape.window;

import std.exception : enforce;
import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

import std.stdio;

shared int WINDOW_X;
shared int WINDOW_Y;

enum WindowFlags {
  FullScreen = SDL_WINDOW_FULLSCREEN,
  FullScreenDesktop = SDL_WINDOW_FULLSCREEN_DESKTOP,
  OpenGL = SDL_WINDOW_OPENGL,
  Shown = SDL_WINDOW_SHOWN,
  Hidden = SDL_WINDOW_HIDDEN,
  Borderless = SDL_WINDOW_BORDERLESS,
  Resizable = SDL_WINDOW_RESIZABLE,
  Minimized = SDL_WINDOW_MINIMIZED,
  Maximized = SDL_WINDOW_MAXIMIZED,
  Grabbed = SDL_WINDOW_INPUT_GRABBED,
  InputFocus = SDL_WINDOW_INPUT_FOCUS,
  MouseFocus = SDL_WINDOW_MOUSE_FOCUS,
  Foreign = SDL_WINDOW_FOREIGN
}

private final class WindowUnit {
  public:
    this(in string name, in int x, in int y, in int w, in int h, in WindowFlags flag) {
      _flag = flag;
      _window = SDL_CreateWindow(cast(char*)name, x, y, w, h, flag);
      if (_flag == WindowFlags.OpenGL) {
        _context = SDL_GL_CreateContext(_window);
        load_opengl();
      }
      enforce(_window, "create_window() faild");
    }

    ~this() {
      debug(tor) writeln("WindowsUnit dtor");
      if (_flag == WindowFlags.OpenGL)
        SDL_GL_DeleteContext(_context); 
      SDL_DestroyWindow(_window);
    }

    void swap() {
      SDL_GL_SwapWindow(_window);
    }

    // TODO 関数追加

  private:
    void load_opengl() {
      // TODO 必要なときだけglを読み込む
      import derelict.opengl3.gl;
      import derelict.opengl3.gl3;

      DerelictGL.load();
      DerelictGL.reload(); // You must create OpenGL Context before calling this function
      DerelictGL3.load();
      DerelictGL3.reload(); // You must create OpenGL Context before calling this function
    }

    SDL_Window* _window;
    SDL_GLContext _context;
    WindowFlags _flag;
}

class Window {
  public:
    this(in int w, in int h) {
      this("grape", 0, 0, w, h, WindowFlags.OpenGL);
    }

    this(in string name, in int w, in int h) {
      this(name, 0, 0, w, h, WindowFlags.OpenGL);
    }

    this(in string name, in int x, in int y, in int w, in int h) {
      this(name, x, y, w, h, WindowFlags.OpenGL);
    }

    this(in string name, in int x, in int y, in int w, in int h, in WindowFlags flag) {
      if (!_initialized) {
        _initialized = true;
        DerelictSDL2.load();

        if (SDL_InitSubSystem(SDL_INIT_VIDEO) != 0)
          throw new Exception("SDL_InitSubSystem(SDL_INIT_VIDEO) failed");
      }

      WINDOW_X = w;
      WINDOW_Y = h;
      _window = new WindowUnit(name, x, y, w, h, flag);

      _instance ~= this;
    }

    ~this() {
      debug(tor) writeln("Windows dtor");
      destroy(_window);
    }

    static ~this() {
      debug(tor) writeln("Windows static dtor");
      if (_initialized) {
        foreach (v; _instance) destroy(v);
        SDL_QuitSubSystem(SDL_INIT_VIDEO);
      }
    }
    
    void update() {
      _window.swap();
      // other
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }

  private:
    static Window[] _instance;
    WindowUnit _window;
    static bool _initialized = false;
}

/*
class Window {
  public:
    this(string name, int x, int y, int w, int h) {
      create(name, x, y, w, h);
      WINDOW_X = w;
      WINDOW_Y = h;
    }

    ~this() {
      debug(tor) writeln("Windows dtor");
      SDL_GL_DeleteContext(_context); 
      SDL_DestroyWindow(_window);
    }
    
    void update() {
      SDL_GL_SwapWindow(_window);
      // other
      glClear(GL_COLOR_BUFFER_BIT);
      glClear(GL_DEPTH_BUFFER_BIT);
    }

    void should_close() {
      _flag = false;
    }

    @property {
      const bool is_open() {
        return _flag;
      }
    }

    alias _window this;
    SDL_Window* _window;

  private:
    void create(string name, int x, int y, int w, int h) {
      _flag = true;
      // check last args
      _window = SDL_CreateWindow(cast(char*)name, x, y, w, h, SDL_WINDOW_OPENGL);
      _context = SDL_GL_CreateContext(_window);
      enforce(_window, "create_window() faild");
    }

    bool _flag;
    SDL_GLContext _context;
}
*/

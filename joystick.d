module orange.joystick;

import derelict.sdl2.sdl;
import std.exception : enforce;
import std.stdio;

enum {
  MAX_AXIS_STATE = 32767.0
}

enum {
  PLAYER_1 = 0,
  PLAYER_2 = 1,  
  PLAYER_3 = 2,  
  PLAYER_4 = 3  
}

private final class JoystickUnit {
  public:
    this(int deviceIndex) {
      _joystick = SDL_JoystickOpen(deviceIndex);
      enforce(_joystick != null, "SDL_JoystickOpen() failed");
    }

    ~this() {
      debug(tor) writeln("JoystickUnit dtor");
      if (SDL_JoystickGetAttached(_joystick))
        SDL_JoystickClose(_joystick);
    }

    float getAxis(int axis) {
      return SDL_JoystickGetAxis(_joystick, axis) / MAX_AXIS_STATE;
    }

    int getButton(int button) {
      return SDL_JoystickGetButton(_joystick, button);
    }

    /*
    int getBall(int ball) {
      return SDL_JoystickGetBall(_joystick, ball);
    }
    */

    int getHat(int hat) {
      return SDL_JoystickGetHat(_joystick, hat);
    }

    int numAxes() {
      return SDL_JoystickNumAxes(_joystick);
    }

    int numButtons() {
      return SDL_JoystickNumButtons(_joystick);
    }

    int numBalls() {
      return SDL_JoystickNumHats(_joystick);
    }

    int numHats() {
      return SDL_JoystickNumBalls(_joystick);
    }

  private:
    SDL_Joystick* _joystick;
}

class Joystick {
  public:
    this(int deviceIndex) {
      if (!_initialized) {
        _initialized = true;
        DerelictSDL2.load();

        if (SDL_InitSubSystem(SDL_INIT_JOYSTICK) != 0)
          throw new Exception("SDL_InitSubSystem(SDL_INIT_JOYSTICK) failed");
      }

      _joystick = new JoystickUnit(deviceIndex);
      set_num();
      _instance ~= this;
    }

    ~this() {
      debug(tor) writeln("Joystick dtor");
      destroy(_joystick);
    }

    static ~this() {
      debug(tor) writeln("Joystick static dtor");
      if (_initialized) {
        foreach (v; _instance) destroy(v);      
        SDL_QuitSubSystem(SDL_INIT_JOYSTICK);
      }
    }

    float getAxis(int axis) 
      in {
        assert(0 <= axis && axis <= _numAxes);
      }
        
      body {
        return _joystick.getAxis(axis);
      }

    int getButton(int button) 
      in {
        assert(0 <= button && button <= _numButtons);
      }

      body {
        return _joystick.getButton(button);
      }

      /*
    int getBall(int ball)
      in {
        assert(0 <= ball && ball <= _numBalls);
      }

      body {
        return _joystick.getBall(ball);
      }
      */

    int getHat(int hat)
      in {
        assert(0 <= hat && hat <= _numHats);
      }

      body {
        return _joystick.getHat(hat);
      }

    // rename show_info("num")etc...
    void show_info() {
      writef("axes:%d buttons:%d balls:%d hats:%d \n", _numAxes, _numButtons, _numBalls, _numHats);
      // writefln
    }

    @property {
      int numAxes() {
        return _numAxes;
      }

      int numButtons() {
        return _numButtons;
      }

      int numBalls() {
        return _numBalls;
      }

      int numHats() {
        return _numHats;
      }
    }

  private:
    void set_num() {
      _numAxes = _joystick.numAxes();
      _numButtons = _joystick.numButtons();
      _numBalls = _joystick.numHats();
      _numHats= _joystick.numBalls();
    }

    JoystickUnit _joystick;
    static Joystick[] _instance;
    int _numAxes, _numButtons, _numBalls, _numHats;
    static bool _initialized = false;
}

/*
class Joystick {
  public:
    this(in int num) {
      _joystick = SDL_JoystickOpen(num);
      enforce(_joystick != null, "SDL_JoystickOpen() failed");

      set_num();
    }

    ~this() {
      debug(tor) writeln("Joystick dtor");
      if (SDL_JoystickGetAttached(_joystick))
        SDL_JoystickClose(_joystick);
    }

    float getAxis(in int axis) 
      in {
        assert(0 <= axis && axis <= _numAxes);
      }
        
      body {
        return SDL_JoystickGetAxis(_joystick, axis) / MAX_AXIS_STATE;
      }

    int getButton(in int button) 
      in {
        assert(0 <= button && button <= _numButtons);
      }

      body {
        return SDL_JoystickGetButton(_joystick, button);
      }

    // int getBall()

    int getHat(in int hat)
      in {
        assert(0 <= hat && hat <= _numHats);
      }

      body {
        return SDL_JoystickGetHat(_joystick, hat);
      }

    // rename show_info("num")etc...
    void show_info() {
      writef("axes:%d buttons:%d balls:%d hats:%d \n", _numAxes, _numButtons, _numBalls, _numHats);
      // writefln
    }

    @property {
      int numAxes() {
        return _numAxes;
      }

      int numButtons() {
        return _numButtons;
      }

      int numBalls() {
        return _numBalls;
      }

      int numHats() {
        return _numHats;
      }
    }
  private:
    void set_num() {
      _numAxes = SDL_JoystickNumAxes(_joystick);
      _numButtons = SDL_JoystickNumButtons(_joystick);
      _numBalls = SDL_JoystickNumBalls(_joystick);
      _numHats= SDL_JoystickNumHats(_joystick);
    }

    SDL_Joystick* _joystick;
    int _numAxes, _numButtons, _numBalls, _numHats;
}
*/

using System;
using System.Collections.Generic;

namespace AeroPointAgent.Input
{
    public enum MouseButton
    {
        Left,
        Right
    }

    public enum KeyboardKey
    {
        Enter,
        Escape,
        Tab,
        Delete,
        ArrowUp,
        ArrowDown,
        ArrowLeft,
        ArrowRight,
        Space
    }

    public enum KeyboardModifier
    {
        Command,
        Option,
        Control,
        Shift
    }

    public interface IInputInjector
    {
        void MoveMouse(double dx, double dy);
        void ClickMouse(MouseButton button);
        void SetMouseButton(MouseButton button, bool down);
        void ScrollMouse(double dx, double dy);
        void TypeText(string text);
        void PressKey(KeyboardKey key, List<KeyboardModifier> modifiers);
    }
}

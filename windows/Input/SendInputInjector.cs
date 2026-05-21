using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace AeroPointAgent.Input
{
    public sealed class SendInputInjector : IInputInjector
    {
        private readonly double _maxDelta;

        public SendInputInjector(double maxDelta = 200)
        {
            _maxDelta = maxDelta;
            Console.WriteLine($"[Injector] SendInputInjector created. MaxDelta={_maxDelta}");
        }

        public void MoveMouse(double dx, double dy)
        {
            double clampedDx = Clamp(dx);
            double clampedDy = Clamp(dy);

            Console.WriteLine($"[Injector] MoveMouse dx={dx:F1} dy={dy:F1} (clamped: {clampedDx:F1}, {clampedDy:F1})");

            var inputs = new INPUT[1];
            inputs[0] = new INPUT
            {
                type = INPUT_MOUSE,
                U = new InputUnion
                {
                    mi = new MOUSEINPUT
                    {
                        dx = (int)clampedDx,
                        dy = (int)clampedDy,
                        mouseData = 0,
                        dwFlags = MOUSEEVENTF_MOVE,
                        time = 0,
                        dwExtraInfo = IntPtr.Zero
                    }
                }
            };

            SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT)));
        }

        public void ClickMouse(MouseButton button)
        {
            Console.WriteLine($"[Injector] ClickMouse {button}");

            uint downFlag = button == MouseButton.Left ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_RIGHTDOWN;
            uint upFlag = button == MouseButton.Left ? MOUSEEVENTF_LEFTUP : MOUSEEVENTF_RIGHTUP;

            var inputs = new INPUT[2];
            inputs[0] = new INPUT
            {
                type = INPUT_MOUSE,
                U = new InputUnion
                {
                    mi = new MOUSEINPUT
                    {
                        dx = 0,
                        dy = 0,
                        mouseData = 0,
                        dwFlags = downFlag,
                        time = 0,
                        dwExtraInfo = IntPtr.Zero
                    }
                }
            };

            inputs[1] = new INPUT
            {
                type = INPUT_MOUSE,
                U = new InputUnion
                {
                    mi = new MOUSEINPUT
                    {
                        dx = 0,
                        dy = 0,
                        mouseData = 0,
                        dwFlags = upFlag,
                        time = 0,
                        dwExtraInfo = IntPtr.Zero
                    }
                }
            };

            SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT)));
        }

        public void ScrollMouse(double dx, double dy)
        {
            Console.WriteLine($"[Injector] ScrollMouse dx={dx:F1} dy={dy:F1}");

            // On Windows, vertical scroll is MOUSEEVENTF_WHEEL and horizontal is MOUSEEVENTF_HWHEEL.
            // One scroll tick/notch is 120 (WHEEL_DELTA). The iOS client sends pixel-like values.
            // We scale it so it scrolls smoothly (e.g. multiplying by 4 to map to Windows expectations).
            var inputsList = new List<INPUT>();

            if (Math.Abs(dy) > 0.01)
            {
                int scrollValue = (int)(dy * 4);
                inputsList.Add(new INPUT
                {
                    type = INPUT_MOUSE,
                    U = new InputUnion
                    {
                        mi = new MOUSEINPUT
                        {
                            dx = 0,
                            dy = 0,
                            mouseData = (uint)scrollValue,
                            dwFlags = MOUSEEVENTF_WHEEL,
                            time = 0,
                            dwExtraInfo = IntPtr.Zero
                        }
                    }
                });
            }

            if (Math.Abs(dx) > 0.01)
            {
                int scrollValue = (int)(dx * 4);
                inputsList.Add(new INPUT
                {
                    type = INPUT_MOUSE,
                    U = new InputUnion
                    {
                        mi = new MOUSEINPUT
                        {
                            dx = 0,
                            dy = 0,
                            mouseData = (uint)scrollValue,
                            dwFlags = MOUSEEVENTF_HWHEEL,
                            time = 0,
                            dwExtraInfo = IntPtr.Zero
                        }
                    }
                });
            }

            if (inputsList.Count > 0)
            {
                var inputs = inputsList.ToArray();
                SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT)));
            }
        }

        public void TypeText(string text)
        {
            Console.WriteLine($"[Injector] TypeText: {text}");

            // Send each UTF-16 code unit using KEYEVENTF_UNICODE
            var inputs = new INPUT[text.Length * 2];
            for (int i = 0; i < text.Length; i++)
            {
                char c = text[i];
                inputs[i * 2] = new INPUT
                {
                    type = INPUT_KEYBOARD,
                    U = new InputUnion
                    {
                        ki = new KEYBDINPUT
                        {
                            wVk = 0,
                            wScan = c,
                            dwFlags = KEYEVENTF_UNICODE,
                            time = 0,
                            dwExtraInfo = IntPtr.Zero
                        }
                    }
                };
                inputs[i * 2 + 1] = new INPUT
                {
                    type = INPUT_KEYBOARD,
                    U = new InputUnion
                    {
                        ki = new KEYBDINPUT
                        {
                            wVk = 0,
                            wScan = c,
                            dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP,
                            time = 0,
                            dwExtraInfo = IntPtr.Zero
                        }
                    }
                };
            }

            SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT)));
        }

        public void PressKey(KeyboardKey key, List<KeyboardModifier> modifiers)
        {
            Console.WriteLine($"[Injector] PressKey {key} modifiers=[{string.Join(", ", modifiers)}]");

            ushort vk = GetVirtualKeyCode(key);
            if (vk == 0)
            {
                Console.WriteLine($"[Injector] Unknown virtual key code for key: {key}");
                return;
            }

            var inputs = new List<INPUT>();

            // Press modifiers
            foreach (var mod in modifiers)
            {
                ushort modVk = GetModifierKeyCode(mod);
                if (modVk != 0)
                {
                    inputs.Add(CreateKeyInput(modVk, keyDown: true));
                }
            }

            // Press key
            inputs.Add(CreateKeyInput(vk, keyDown: true));

            // Release key
            inputs.Add(CreateKeyInput(vk, keyDown: false));

            // Release modifiers (in reverse order)
            for (int i = modifiers.Count - 1; i >= 0; i--)
            {
                ushort modVk = GetModifierKeyCode(modifiers[i]);
                if (modVk != 0)
                {
                    inputs.Add(CreateKeyInput(modVk, keyDown: false));
                }
            }

            SendInput((uint)inputs.Count, inputs.ToArray(), Marshal.SizeOf(typeof(INPUT)));
        }

        private INPUT CreateKeyInput(ushort vk, bool keyDown)
        {
            uint flags = keyDown ? 0 : KEYEVENTF_KEYUP;
            // Some keys require the extended key flag (like arrow keys)
            if (IsExtendedKey(vk))
            {
                flags |= KEYEVENTF_EXTENDEDKEY;
            }

            return new INPUT
            {
                type = INPUT_KEYBOARD,
                U = new InputUnion
                {
                    ki = new KEYBDINPUT
                    {
                        wVk = vk,
                        wScan = 0,
                        dwFlags = flags,
                        time = 0,
                        dwExtraInfo = IntPtr.Zero
                    }
                }
            };
        }

        private ushort GetVirtualKeyCode(KeyboardKey key)
        {
            return key switch
            {
                KeyboardKey.Enter => VK_RETURN,
                KeyboardKey.Escape => VK_ESCAPE,
                KeyboardKey.Tab => VK_TAB,
                KeyboardKey.Delete => VK_BACK, // Maps macOS backspace/delete behavior
                KeyboardKey.ArrowUp => VK_UP,
                KeyboardKey.ArrowDown => VK_DOWN,
                KeyboardKey.ArrowLeft => VK_LEFT,
                KeyboardKey.ArrowRight => VK_RIGHT,
                KeyboardKey.Space => VK_SPACE,
                _ => 0
            };
        }

        private ushort GetModifierKeyCode(KeyboardModifier modifier)
        {
            return modifier switch
            {
                KeyboardModifier.Command => VK_LCONTROL, // Map Cmd to Ctrl for copy/paste/shortcuts on Windows
                KeyboardModifier.Control => VK_LCONTROL,
                KeyboardModifier.Option => VK_LMENU,     // Alt
                KeyboardModifier.Shift => VK_LSHIFT,
                _ => 0
            };
        }

        private bool IsExtendedKey(ushort vk)
        {
            return vk == VK_UP || vk == VK_DOWN || vk == VK_LEFT || vk == VK_RIGHT;
        }

        private double Clamp(double value)
        {
            return Math.Min(Math.Max(value, -_maxDelta), _maxDelta);
        }

        // P/Invoke structures and definitions
        private const int INPUT_MOUSE = 0;
        private const int INPUT_KEYBOARD = 1;

        private const uint MOUSEEVENTF_MOVE = 0x0001;
        private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        private const uint MOUSEEVENTF_LEFTUP = 0x0004;
        private const uint MOUSEEVENTF_RIGHTDOWN = 0x0008;
        private const uint MOUSEEVENTF_RIGHTUP = 0x0010;
        private const uint MOUSEEVENTF_WHEEL = 0x0800;
        private const uint MOUSEEVENTF_HWHEEL = 0x01000;

        private const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
        private const uint KEYEVENTF_KEYUP = 0x0002;
        private const uint KEYEVENTF_UNICODE = 0x0004;

        private const ushort VK_RETURN = 0x0D;
        private const ushort VK_ESCAPE = 0x1B;
        private const ushort VK_TAB = 0x09;
        private const ushort VK_BACK = 0x08;
        private const ushort VK_SPACE = 0x20;
        private const ushort VK_LEFT = 0x25;
        private const ushort VK_UP = 0x26;
        private const ushort VK_RIGHT = 0x27;
        private const ushort VK_DOWN = 0x28;

        private const ushort VK_LSHIFT = 0xA0;
        private const ushort VK_LCONTROL = 0xA2;
        private const ushort VK_LMENU = 0xA4;

        [StructLayout(LayoutKind.Sequential)]
        private struct INPUT
        {
            public int type;
            public InputUnion U;
        }

        [StructLayout(LayoutKind.Explicit)]
        private struct InputUnion
        {
            [FieldOffset(0)]
            public MOUSEINPUT mi;
            [FieldOffset(0)]
            public KEYBDINPUT ki;
            [FieldOffset(0)]
            public HARDWAREINPUT hi;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct MOUSEINPUT
        {
            public int dx;
            public int dy;
            public uint mouseData;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct KEYBDINPUT
        {
            public ushort wVk;
            public ushort wScan;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct HARDWAREINPUT
        {
            public uint uMsg;
            public ushort wParamL;
            public ushort wParamH;
        }

        [DllImport("user32.dll", SetLastError = true)]
        private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);
    }
}

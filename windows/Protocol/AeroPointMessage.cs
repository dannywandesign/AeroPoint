using System;
using System.Collections.Generic;
using AeroPointAgent.Input;

namespace AeroPointAgent.Protocol
{
    public class MessageValidationError : Exception
    {
        public string Code { get; }
        
        public MessageValidationError(string code, string message) : base(message)
        {
            Code = code;
        }
    }

    public abstract class AeroPointMessage
    {
        public int Sequence { get; }

        protected AeroPointMessage(int sequence)
        {
            Sequence = sequence;
        }
    }

    public sealed class MouseMoveMessage : AeroPointMessage
    {
        public double Dx { get; }
        public double Dy { get; }

        public MouseMoveMessage(int sequence, double dx, double dy) : base(sequence)
        {
            Dx = dx;
            Dy = dy;
        }
    }

    public sealed class MouseClickMessage : AeroPointMessage
    {
        public MouseButton Button { get; }

        public MouseClickMessage(int sequence, MouseButton button) : base(sequence)
        {
            Button = button;
        }
    }

    public sealed class MouseScrollMessage : AeroPointMessage
    {
        public double Dx { get; }
        public double Dy { get; }

        public MouseScrollMessage(int sequence, double dx, double dy) : base(sequence)
        {
            Dx = dx;
            Dy = dy;
        }
    }

    public sealed class KeyboardTextMessage : AeroPointMessage
    {
        public string Text { get; }

        public KeyboardTextMessage(int sequence, string text) : base(sequence)
        {
            Text = text;
        }
    }

    public sealed class KeyboardKeyMessage : AeroPointMessage
    {
        public KeyboardKey Key { get; }
        public List<KeyboardModifier> Modifiers { get; }

        public KeyboardKeyMessage(int sequence, KeyboardKey key, List<KeyboardModifier> modifiers) : base(sequence)
        {
            Key = key;
            Modifiers = modifiers;
        }
    }
}

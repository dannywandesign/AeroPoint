using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using AeroPointAgent.Pairing;
using AeroPointAgent.Storage;
using QRCoder;

namespace AeroPointAgent.UI
{
    public final class PairingForm : Form
    {
        private readonly PairingService _pairingService;
        private readonly IPairingTokenStore _tokenStore;
        private readonly Action _onUnpair;

        private PictureBox _qrPictureBox = null!;
        private Label _titleLabel = null!;
        private Label _addressLabel = null!;
        private Label _nonceLabel = null!;
        private Label _statusLabel = null!;
        private Button _unpairButton = null!;
        private Button _closeButton = null!;

        public PairingForm(PairingService pairingService, IPairingTokenStore tokenStore, Action onUnpair)
        {
            _pairingService = pairingService;
            _tokenStore = tokenStore;
            _onUnpair = onUnpair;

            InitializeComponent();
            GenerateAndDisplayQR();
        }

        private void InitializeComponent()
        {
            // Set up form properties (sleek, dark-mode styling)
            this.Size = new Size(380, 520);
            this.FormBorderStyle = FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.Text = "AeroPoint Pairing";
            this.BackColor = Color.FromArgb(18, 18, 18); // Dark background
            this.ForeColor = Color.FromArgb(244, 244, 245); // Zn-50 white

            // Set up font
            var mainFont = new Font("Segoe UI", 10F, FontStyle.Regular);
            var titleFont = new Font("Segoe UI Semibold", 14F, FontStyle.Bold);

            // Title Label
            _titleLabel = new Label
            {
                Text = "Scan to Pair",
                Font = titleFont,
                ForeColor = Color.FromArgb(244, 244, 245),
                TextAlign = ContentAlignment.MiddleCenter,
                Location = new Point(20, 20),
                Size = new Size(340, 30)
            };
            this.Controls.Add(_titleLabel);

            // QR Code PictureBox
            _qrPictureBox = new PictureBox
            {
                Location = new Point(65, 70),
                Size = new Size(250, 250),
                SizeMode = PictureBoxSizeMode.Zoom,
                BackColor = Color.White,
                Padding = new Padding(10)
            };
            // Soft rounded border styling for PictureBox
            this.Controls.Add(_qrPictureBox);

            // Local Address Label
            _addressLabel = new Label
            {
                Text = "Address: Detecting...",
                Font = mainFont,
                ForeColor = Color.FromArgb(161, 161, 170), // Slate gray
                TextAlign = ContentAlignment.MiddleCenter,
                Location = new Point(20, 335),
                Size = new Size(340, 20)
            };
            this.Controls.Add(_addressLabel);

            // Pairing Nonce Label
            _nonceLabel = new Label
            {
                Text = "Nonce: --",
                Font = mainFont,
                ForeColor = Color.FromArgb(161, 161, 170),
                TextAlign = ContentAlignment.MiddleCenter,
                Location = new Point(20, 360),
                Size = new Size(340, 20)
            };
            this.Controls.Add(_nonceLabel);

            // Connection Status Label
            _statusLabel = new Label
            {
                Text = "Status: Disconnected",
                Font = new Font("Segoe UI Semibold", 10F, FontStyle.Bold),
                ForeColor = Color.FromArgb(239, 68, 68), // Red
                TextAlign = ContentAlignment.MiddleCenter,
                Location = new Point(20, 385),
                Size = new Size(340, 25)
            };
            this.Controls.Add(_statusLabel);

            // Unpair Button (Flat premium style)
            _unpairButton = new Button
            {
                Text = "Forget Devices",
                Font = new Font("Segoe UI", 9.5F, FontStyle.Regular),
                BackColor = Color.FromArgb(39, 39, 42), // Dark gray
                ForeColor = Color.FromArgb(244, 244, 245),
                FlatStyle = FlatStyle.Flat,
                Location = new Point(45, 430),
                Size = new Size(130, 35)
            };
            _unpairButton.FlatAppearance.BorderSize = 0;
            _unpairButton.Click += UnpairButton_Click;
            this.Controls.Add(_unpairButton);

            // Close Button
            _closeButton = new Button
            {
                Text = "Close",
                Font = new Font("Segoe UI", 9.5F, FontStyle.Regular),
                BackColor = Color.FromArgb(39, 39, 42),
                ForeColor = Color.FromArgb(244, 244, 245),
                FlatStyle = FlatStyle.Flat,
                Location = new Point(205, 430),
                Size = new Size(130, 35)
            };
            _closeButton.FlatAppearance.BorderSize = 0;
            _closeButton.Click += (s, e) => this.Close();
            this.Controls.Add(_closeButton);
        }

        private void GenerateAndDisplayQR()
        {
            try
            {
                var session = _pairingService.StartPairing();
                _nonceLabel.Text = $"Nonce: {session.Nonce}";

                // Extract address info from payload
                var uri = new Uri(session.Payload);
                var queryParams = System.Web.HttpUtility.ParseQueryString(uri.Query);
                string host = queryParams["host"] ?? "0.0.0.0";
                string port = queryParams["port"] ?? "41074";
                _addressLabel.Text = $"Address: {host}:{port}";

                // Generate QR Code bitmap
                using (var qrGenerator = new QRCodeGenerator())
                using (var qrCodeData = qrGenerator.CreateQrCode(session.Payload, QRCodeGenerator.ECCLevel.Q))
                using (var qrCode = new QRCode(qrCodeData))
                {
                    Bitmap qrImage = qrCode.GetGraphic(8, Color.FromArgb(18, 18, 18), Color.White, true);
                    _qrPictureBox.Image = qrImage;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[UI] Error generating QR code: {ex.Message}");
                _addressLabel.Text = "Error generating pairing session";
            }
        }

        public void UpdateStatus(string status, bool connected)
        {
            if (this.InvokeRequired)
            {
                this.Invoke(new Action(() => UpdateStatus(status, connected)));
                return;
            }

            _statusLabel.Text = $"Status: {status}";
            if (connected)
            {
                _statusLabel.ForeColor = Color.FromArgb(34, 197, 94); // Premium Green
                _qrPictureBox.Visible = false; // Hide QR code when connected
                _titleLabel.Text = "Connected ✓";
            }
            else
            {
                _statusLabel.ForeColor = Color.FromArgb(239, 68, 68); // Soft Red
                _qrPictureBox.Visible = true;
                _titleLabel.Text = "Scan to Pair";
            }
        }

        private void UnpairButton_Click(object? sender, EventArgs e)
        {
            var result = MessageBox.Show(
                "Are you sure you want to unpair and clear all stored iPhone access tokens?",
                "Forget Devices",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question
            );

            if (result == DialogResult.Yes)
            {
                _onUnpair();
                GenerateAndDisplayQR();
                UpdateStatus("Disconnected (Cleared)", false);
            }
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            
            // Draw a subtle border inside the form to look sleek
            using (var pen = new Pen(Color.FromArgb(39, 39, 42), 2))
            {
                e.Graphics.DrawRectangle(pen, 1, 1, this.ClientSize.Width - 2, this.ClientSize.Height - 2);
            }
        }
    }
}

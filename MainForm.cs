using System;
using System.IO;
using System.Diagnostics;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;
using Emgu.CV;
using Emgu.CV.Structure;
using Emgu.CV.CvEnum;


namespace facialrecon
{
    public partial class FrmPrincipal:Form
    {
        Image<Bgr, Byte> Frame;
        Capture capture;    
        HaarCascade face;
        MCvFont font = new MCvFont(FONT.CV_FONT_HERSHEY_TRIPLEX, 0.5d, 0.5d);
        Image<Gray, byte> result;
        Image<Gray, byte> grayFrame = null;
        int t;


        public FrmPrincipal() {
            InitializeComponent();
            face = new HaarCascade("haarcascade_frontalface_default.xml");
        }


        private void button1_Click(object sender, EventArgs e)
        {
            capture = new Capture();
            capture.QueryFrame();
            Application.Idle += new EventHandler(FrameCapture);
            //disable the button after clicking
            button1.Enabled = false;
        }
        void FrameCapture(object sender, EventArgs e)
        {
            label2.Text = "0";

            Frame = capture.QueryFrame().Resize(320, 240, Emgu.CV.CvEnum.INTER.CV_INTER_CUBIC);

            //Convert image to gray scale
            grayFrame = Frame.Convert<Gray, Byte>();

            //Detect All Faces
            MCvAvgComp[][] faces = grayFrame.DetectHaarCascade(face, 1.2, 10,Emgu.CV.CvEnum.HAAR_DETECTION_TYPE.DO_CANNY_PRUNING, new Size(20, 20));

                    //Action for each element detected
            foreach (MCvAvgComp f in faces[0])
            {
                t = t + 1;
                result = Frame.Copy(f.rect).Convert<Gray, byte>().Resize(100, 100, Emgu.CV.CvEnum.INTER.CV_INTER_CUBIC);

                //Draw a rectangle on face detected
                Frame.Draw(f.rect, new Bgr(Color.Red), 2);
                label2.Text = faces[0].Length.ToString();

            }
            t = 0; 
            imageBoxFrameCapture.Image = Frame;

        }

        
        private void textBox1_TextChanged(object sender, EventArgs e)
        {

        }

        private void groupBox2_Enter(object sender, EventArgs e)
        {

        }

        private void label2_Click(object sender, EventArgs e)
        {

        }

    }
}
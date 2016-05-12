using System;
using System.Diagnostics;
using Emgu.CV.Structure;

namespace Emgu.CV
{
 
   public class EigenObjectRecognizer
   {
      private string[] mainLabels;
      private Image<Gray, Single>[] storedImages;
      private Image<Gray, Single> newImage;
      private Matrix<float>[] eigenVals;
      private double _eigenDistanceThreshold;
     
      public Image<Gray, Single>[] EigenImages {
         get { return storedImages; }
         set { storedImages = value; }
      }

    
      public String[] Labels {
         get { return mainLabels; }
         set { mainLabels = value; }
      }

      public double EigenDistanceThreshold {
         get { return _eigenDistanceThreshold; }
         set { _eigenDistanceThreshold = value; }
      }

      //Get the average Image. 
      public Image<Gray, Single> AverageImage {
         get { return newImage; }
         set { newImage = value; }
      }

      // Get the eigen values of each of the images
      public Matrix<float>[] EigenValues
      {
         get { return eigenVals; }
         set { eigenVals = value; }
      }


      // build the object recognizer to return the most similar object 
      public EigenObjectRecognizer(Image<Gray, Byte>[] images, ref MCvTermCriteria termCrit) : this(images, GenerateLabels(images.Length), ref termCrit) { }

      public EigenObjectRecognizer(Image<Gray, Byte>[] images, String[] labels, ref MCvTermCriteria termCrit) : this(images, labels, 0, ref termCrit) { }

      private static String[] GenerateLabels(int size) {
         String[] labels = new string[size];
         for (int i = 0; i < size; i++)   labels[i] = i.ToString();
         return labels;
      }

      /// Create an object recognizer 
      public EigenObjectRecognizer(Image<Gray, Byte>[] images, String[] labels, double eigenDistanceThreshold, ref MCvTermCriteria termCrit)  {
         Debug.Assert(images.Length == labels.Length);
         Debug.Assert(eigenDistanceThreshold>=0.0);

         FindEigens(images, ref termCrit, out storedImages, out newImage);

         eigenVals = Array.ConvertAll<Image<Gray, Byte>, Matrix<float>>(images,
             delegate(Image<Gray, Byte> img)
             {
                return new Matrix<float>(DecomEigens(img, storedImages, newImage));
             });

         mainLabels = labels;
         _eigenDistanceThreshold = eigenDistanceThreshold;
      }

    
      // calculate eigen images 
      public static void FindEigens(Image<Gray, Byte>[] trainingImages, ref MCvTermCriteria termCrit, out Image<Gray, Single>[] eigenImages, out Image<Gray, Single> avg) {
         int width = trainingImages[0].Width;
         int height = trainingImages[0].Height;

         IntPtr[] inObjs = Array.ConvertAll<Image<Gray, Byte>, IntPtr>(trainingImages, delegate(Image<Gray, Byte> img) { return img.Ptr; });

         if (termCrit.max_iter <= 0 || termCrit.max_iter > trainingImages.Length)
            termCrit.max_iter = trainingImages.Length;
         
         int maxEigenObjs = termCrit.max_iter;

        
         eigenImages = new Image<Gray, float>[maxEigenObjs];
         for (int i=0; i< eigenImages.Length; i++)
            eigenImages[i] = new Image<Gray, float>(width, height);
         IntPtr[] eigObjs = Array.ConvertAll<Image<Gray, Single>, IntPtr>(eigenImages, delegate(Image<Gray, Single> img) { return img.Ptr; });
         

         avg = new Image<Gray, Single>(width, height);

         CvInvoke.cvCalcEigenObjects(
             inObjs,
             ref termCrit,
             eigObjs,
             null,
             avg.Ptr);
      }

      
      /// Decompose the image into eigen values
    
      public static float[] DecomEigens(Image<Gray, Byte> src, Image<Gray, Single>[] eigenImages, Image<Gray, Single> avg)  {
         return CvInvoke.cvEigenDecomposite(  src.Ptr,  Array.ConvertAll<Image<Gray, Single>, IntPtr>(eigenImages, delegate(Image<Gray, Single> img) { return img.Ptr; }),avg.Ptr);
      }
    
      /// Given the eigen value, reconstruct the projected image
      public Image<Gray, Byte> EigenProjection(float[] eigenValue)   {
         Image<Gray, Byte> res = new Image<Gray, byte>(newImage.Width, newImage.Height);
         CvInvoke.cvEigenProjection(
             Array.ConvertAll<Image<Gray, Single>, IntPtr>(storedImages, delegate(Image<Gray, Single> img) { return img.Ptr; }),
             eigenValue,
             newImage.Ptr,
             res.Ptr);
         return res;
      }


      public float[] GetEigenDistances(Image<Gray, Byte> image)  {
         using (Matrix<float> eigenValue = new Matrix<float>(DecomEigens(image, storedImages, newImage)))
            return Array.ConvertAll<Matrix<float>, float>(eigenVals,
                delegate(Matrix<float> eigenValueI)
                {
                   return (float)CvInvoke.cvNorm(eigenValue.Ptr, eigenValueI.Ptr, Emgu.CV.CvEnum.NORM_TYPE.CV_L2, IntPtr.Zero);
                });
      }

      
      public void find(Image<Gray, Byte> image, out int index, out float eigenDistance, out String label)   {
         float[] dist = GetEigenDistances(image);

         index= 0;
         eigenDistance = dist[0];
         for (int i = 1; i < dist.Length; i++)
         {
            if (dist[i] < eigenDistance)
            {
               index = i;
               eigenDistance = dist[i];
            }
         }
         label = Labels[index];
      }

       // return the label of the image
      public String Recognize(Image<Gray, Byte> image) {
         int i;
         float eigenDistance;
         String label;
         find(image, out i, out eigenDistance, out label);
         return (_eigenDistanceThreshold<= 0 || eigenDistance < _eigenDistanceThreshold )  ? mainLabels[index] : String.Empty;
      }
   }
}

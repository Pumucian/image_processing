import java.lang.*;
import processing.video.*;
import cvimage.*;
import org.opencv.core.*;
import org.opencv.imgproc.Imgproc;

Capture cam;
CVImage img, auximg;
int effect;
final int numEffects = 4;
boolean grad;
final String colorString = "Press C to change color", gradientString = "Press G to change filter";

void setup() {
  size(1280, 480);
  
  effect = 0;
  grad = false;
  
  cam = new Capture(this, width/2, height);
  cam.start(); 
  
  System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
  img = new CVImage(cam.width, cam.height);
  auximg=new CVImage(cam.width, cam.height);
  
  textAlign(CENTER, TOP);
  textSize(14);
}

void keyPressed(){
  if (key == 'c') {
    effect++;
    if (effect == numEffects) effect = 0;
  } else if (key == 'g') grad = !grad;
}

void draw() {  
  if (cam.available()) {
    processImage();
    setText();
  }
}

void setText(){
  text(colorString, width/2, 0);
  text(gradientString, width/2, 15);
}

void gradient(Mat gris){
  int ddepth = CvType.CV_16S;
  Mat grad_x = new Mat();
  Mat grad_y = new Mat();
  Mat abs_grad_x = new Mat();
  Mat abs_grad_y = new Mat();

  // Gradiente X
  Imgproc.Sobel(gris, grad_x, ddepth, 1, 0);
  Core.convertScaleAbs(grad_x, abs_grad_x);

  // Gradiente Y
  Imgproc.Sobel(gris, grad_y, ddepth, 0, 1);
  Core.convertScaleAbs(grad_y, abs_grad_y);

  // Gradiente total aproximado
  Core.addWeighted(abs_grad_x, 0.5, abs_grad_y, 0.5, 0, gris);
}

void processImage(){
  background(0);
  cam.read();
  
  //Obtiene la imagen de la cámara
  img.copy(cam, 0, 0, cam.width, cam.height, 
  0, 0, img.width, img.height);
  img.copyTo();
  
  //Imagen de grises
  Mat gris = img.getGrey();
  
  if (grad) gradient(gris);
  
  //Copia de Mat a CVImage
  cpMat2CVImage(gris,auximg);
  
  //Visualiza ambas imágenes
  image(img,0,0);
  image(auximg,width/2,0);
  
  //Libera
  gris.release();
}

color selectColor(int val){
  if (effect == 0) return color(val);
  if (effect == 1) return color(val, 0, 0);
  if (effect == 2) return color(0, 0, val);
  else return color(0, val, 0);
}

//Copia unsigned byte Mat a color CVImage
void  cpMat2CVImage(Mat in_mat,CVImage out_img)
{    
  byte[] data8 = new byte[cam.width*cam.height];
  
  out_img.loadPixels();
  in_mat.get(0, 0, data8);
  
  // Cada columna
  for (int x = 0; x < cam.width; x++) {
    // Cada fila
    for (int y = 0; y < cam.height; y++) {
      // Posición en el vector 1D
      int loc = x + y * cam.width;
      //Conversión del valor a unsigned basado en 
      //https://stackoverflow.com/questions/4266756/can-we-make-unsigned-byte-in-java
      int val = data8[loc] & 0xFF;
      //Copia a CVImage
      out_img.pixels[loc] = selectColor(val);
    }
  }
  out_img.updatePixels();
}

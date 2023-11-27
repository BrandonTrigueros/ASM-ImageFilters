#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

// Funcioón en ensamblador que aplica un filtro a una imagen, produce un
// archivo copia.bmp
extern "C" void crearCopia(char* path, int filter);
// Función en C++ que crea una copia de un archivo. Se usa para crear copias de
// cada filtro a partir de copia.bmp
void crearCopiaC(
    const std::string& sourceFilename, const std::string& destFilename);

int main() {
  char* path = new char[1000];
  const char* command = "xdg-open";

  std::cout << "Ingrese la ruta de la imagen: ";
  std::cin >> path;

  // Mostar la imagen original
  std::string fullCommand = std::string(command) + " " + path;
  int result = std::system(fullCommand.c_str());

  // Crear las coopias y mostrarlas en pantalla
  for (int filter = 0; filter < 4; filter++) {
    std::stringstream ss;
    ss << "copia" << filter << ".bmp";
    const std::string copiaDeCopia = ss.str();
    crearCopia(path, filter);
    crearCopiaC("copia.bmp", copiaDeCopia);
    fullCommand = std::string(command) + " " + copiaDeCopia;
    result = std::system(fullCommand.c_str());
  }

  delete[] path;
  return 0;
}

void crearCopiaC(
    const std::string& sourceFilename, const std::string& destFilename) {
  std::ifstream sourceFile(sourceFilename, std::ios::binary);
  std::ofstream destFile(destFilename, std::ios::binary);
  destFile << sourceFile.rdbuf();
  sourceFile.close();
  destFile.close();
}
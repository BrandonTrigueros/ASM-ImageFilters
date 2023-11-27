#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#include <iostream>
#include <SDL2/SDL.h>

extern "C" void crearCopia(char* path, int filter);

unsigned char* cargarImagen(const char* path, int& width, int& height, int& channels);
void iniciarSDL(int width, int height, SDL_Window*& window, SDL_Renderer*& renderer, SDL_Texture*& texture, unsigned char* imageData);
void renderizarImagen(SDL_Renderer* renderer, SDL_Texture* texture);
void limpiarRecursos(SDL_Window* window, SDL_Renderer* renderer, SDL_Texture* texture, unsigned char* imageData);

int main() {
  char* path = new char[1000];
  const char* copyPath = "copia.bmp";
  std::cout << "Ingrese la ruta de la imagen: ";
  std::cin >> path;
  
  for (int filter = 0; filter < 5; filter++) {
    int width, height, channels;
    unsigned char* imageData;
    if (filter == 0) {
      imageData = cargarImagen(path, width, height, channels);  // Muestra imagen original
    } else {
      crearCopia(path, filter - 1);
      // Muestra imagen con el filtro i
      imageData = cargarImagen(copyPath, width, height, channels);
    }

    if (imageData == nullptr) {
        std::cout << "No se pudo cargar la imagen." << std::endl;
        return -1;
    }

    SDL_Window* window;
    SDL_Renderer* renderer;
    SDL_Texture* texture;

    iniciarSDL(width, height, window, renderer, texture, imageData);
    renderizarImagen(renderer, texture);
    limpiarRecursos(window, renderer, texture, imageData);

  }
  return 0;
}

unsigned char* cargarImagen(const char* path, int& width, int& height, int& channels) {
  return stbi_load(path, &width, &height, &channels, STBI_rgb);
}

void iniciarSDL(int width, int height, SDL_Window*& window, SDL_Renderer*& renderer, SDL_Texture*& texture, unsigned char* imageData) {
  SDL_Init(SDL_INIT_VIDEO);
  window = SDL_CreateWindow("Imagen BMP con SDL", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, 0);
  renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, width, height);
  SDL_UpdateTexture(texture, nullptr, imageData, width * 3); // 3 bytes por píxel para RGB
}

void renderizarImagen(SDL_Renderer* renderer, SDL_Texture* texture) {
  bool running = true;
  while (running) {
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
      if (event.type == SDL_QUIT) {
          running = false;
      }
    }

    SDL_RenderClear(renderer);
    SDL_RenderCopy(renderer, texture, nullptr, nullptr);
    SDL_RenderPresent(renderer);
  }
}

void limpiarRecursos(SDL_Window* window, SDL_Renderer* renderer, SDL_Texture* texture, unsigned char* imageData) {
  SDL_DestroyTexture(texture);
  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  stbi_image_free(imageData);
  SDL_Quit();
}

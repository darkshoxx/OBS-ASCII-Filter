#include "ascii_filter.h"
#include <iostream>

extern "C" {
    #include "image.h"
    #include "print_image.h"
}
#include <vector>
#include <cstdlib> // for malloc/free

#define DEFAULT_MAX_WIDTH 64
#define DEFAULT_MAX_HEIGHT 48
#define DEFAULT_CHARACTER_RATIO 2.0
#define DEFAULT_EDGE_THRESHOLD 4.0

void test_function() {
    
    std::cout << "[INFO] Loading Puffin image..." << std::endl;
    image_t puffin_test = load_image("ascii-view/examples/puffin.jpg");
    std::cout << "[INFO] Resizing image!" << std::endl;
    image_t puffin_resized = make_resized(&puffin_test, DEFAULT_MAX_WIDTH, DEFAULT_MAX_HEIGHT, DEFAULT_CHARACTER_RATIO);
    std::cout << "[INFO] Calling print_image() from C code..." << std::endl;



    // Call print_image
    print_image(&puffin_resized, 0.5);
    std::cout << "[INFO] Successfully called C function print_image()" << std::endl;
    // Clean up
    free_image(&puffin_test);
    free_image(&puffin_resized);
    std::cout << "[INFO] freed image memory" << std::endl;
}

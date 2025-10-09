#include "ascii_filter.h"
#include <iostream>

extern "C" {
    #include "image.h"
    #include "print_image.h"
}
#include <vector>
#include <cstdlib> // for malloc/free

void test_function() {
    std::cout << "[INFO] Calling print_image() from C code..." << std::endl;

    image_t dummy_image;
    dummy_image.width = 2;
    dummy_image.height = 1;
    dummy_image.channels = 3; // RGB
    dummy_image.data = (double*)malloc(sizeof(double) * dummy_image.width * dummy_image.height * dummy_image.channels);

    // Fill with zeros (black)
    for (size_t i = 0; i < dummy_image.width * dummy_image.height * dummy_image.channels; i++) {
        dummy_image.data[i] = 0.0;
    }

    // Call print_image
    print_image(&dummy_image, 0.5);
    std::cout << "[INFO] Successfully called C function" << std::endl;
    // Clean up
    free(dummy_image.data);
}
